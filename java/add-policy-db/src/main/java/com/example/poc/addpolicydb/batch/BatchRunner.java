package com.example.poc.addpolicydb.batch;

import com.example.poc.addpolicydb.domain.PolicyEntity;
import com.example.poc.addpolicydb.domain.PolicyRepository;
import com.example.poc.addpolicydb.service.PolicyInsertService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Comparator;
import java.util.List;

/**
 * Mirror of MAIN paragraph in [cobol/add-policy-db/src/ADDPOLDB.cbl:71-117]:
 * read requests.dat, insert each via PolicyInsertService, count, then dump
 * the POLICY table to out/policy.csv for byte-exact diff against the COBOL
 * side's dump (which is written by libcob_sqlite.cob_sqlite_dump).
 *
 * <p>stdout format must match the COBOL DISPLAY statements verbatim:
 * <pre>
 *   OK   POLNUM=NNNNNNNNNN
 *   ERR  POLNUM=NNNNNNNNNN RC=+NNNNNNNNNN
 *   PROCESSED=NNNNNN INSERTED=NNNNNN REJECTED=NNNNNN
 * </pre>
 */
@Component
public class BatchRunner implements CommandLineRunner {

    private final RecordCodec codec;
    private final PolicyInsertService inserter;
    private final PolicyRepository repository;

    public BatchRunner(RecordCodec codec, PolicyInsertService inserter, PolicyRepository repository) {
        this.codec = codec;
        this.inserter = inserter;
        this.repository = repository;
    }

    @Override
    public void run(String... args) throws Exception {
        // Matches run-java.sh invocation: `<jar> requests.dat <outDir>`.
        // The dumped POLICY table goes to <outDir>/policy.csv so the
        // diff harness picks it up alongside stdout/exit_code.
        Path requestsFile = Path.of(args.length > 0 ? args[0] : "requests.dat");
        Path outDir       = Path.of(args.length > 1 ? args[1] : ".");
        Path dumpFile     = outDir.resolve("policy.csv");

        int processed = 0, inserted = 0, rejected = 0;
        try (BufferedReader in = Files.newBufferedReader(requestsFile, StandardCharsets.US_ASCII)) {
            String line;
            while ((line = in.readLine()) != null) {
                processed++;
                PolicyEntity entity = codec.parseRequest(line);
                try {
                    inserter.insert(entity);
                    inserted++;
                    System.out.println("OK   POLNUM=" + pad10(entity.getPolicyNumber()));
                } catch (RuntimeException e) {
                    // COBOL: shim returns RC=1 on any SQLite error (UNIQUE,
                    // FK, NOT NULL). WS-RC is PIC S9(9) COMP-5 → "+0000000001".
                    // We catch RuntimeException because Hibernate's
                    // ConstraintViolationException isn't auto-translated to
                    // Spring's DataAccessException when using EntityManager
                    // directly (no @Repository proxy on PolicyInsertService).
                    rejected++;
                    System.out.println("ERR  POLNUM=" + pad10(entity.getPolicyNumber())
                            + " RC=" + signed10(1));
                }
            }
        }

        // Dump POLICY table to a deterministic text file. Order by primary key
        // so both sides produce the same byte stream.
        List<PolicyEntity> all = repository.findAll();
        all.sort(Comparator.comparing(PolicyEntity::getPolicyNumber));

        Files.createDirectories(outDir);
        try (BufferedWriter w = Files.newBufferedWriter(dumpFile, StandardCharsets.US_ASCII,
                StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE)) {
            for (PolicyEntity p : all) {
                w.write(String.valueOf(p.getPolicyNumber())); w.write('|');
                w.write(String.valueOf(p.getCustomerNumber())); w.write('|');
                w.write(p.getIssueDate());        w.write('|');
                w.write(p.getExpiryDate());       w.write('|');
                w.write(p.getPolicyType());       w.write('|');
                w.write(p.getLastChanged());      w.write('|');
                w.write(String.valueOf(p.getBrokerId())); w.write('|');
                w.write(p.getBrokersReference()); w.write('|');
                w.write(String.valueOf(p.getPayment()));
                w.newLine();
            }
        }

        System.out.println("PROCESSED=" + pad6(processed)
                + " INSERTED=" + pad6(inserted)
                + " REJECTED=" + pad6(rejected));
    }

    /** PIC 9(10) DISPLAY format: 10-char zero-padded. */
    static String pad10(long v) { return String.format("%010d", v); }

    /** PIC 9(6) DISPLAY format: 6-char zero-padded. */
    static String pad6(int v) { return String.format("%06d", v); }

    /** PIC S9(9) COMP-5 DISPLAY format: sign + 10-char zero-padded. */
    static String signed10(long v) {
        return (v >= 0 ? "+" : "-") + String.format("%010d", Math.abs(v));
    }
}
