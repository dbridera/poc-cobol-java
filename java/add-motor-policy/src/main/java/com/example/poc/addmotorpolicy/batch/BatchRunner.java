package com.example.poc.addmotorpolicy.batch;

import com.example.poc.addmotorpolicy.domain.MotorEntity;
import com.example.poc.addmotorpolicy.domain.MotorPolicyRequest;
import com.example.poc.addmotorpolicy.domain.PolicyEntity;
import com.example.poc.addmotorpolicy.service.MotorPremiumCalculator;
import com.example.poc.addmotorpolicy.service.PremiumOverflowException;
import com.example.poc.addmotorpolicy.service.RequestValidator;
import com.example.poc.addmotorpolicy.service.RequestValidator.ValidationFailure;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Optional;

/**
 * Mirror of MAIN-LOGIC + HANDLE-ONE-REQUEST in ADDMPOL.cbl:158-198.
 *
 * <p>Reads {@code requests.dat}, calls validator + calculator, writes
 * {@code policy.dat}, {@code motor.dat}, {@code error.log} in the byte-exact
 * COBOL format and prints OK/ERR/SUMMARY lines to stdout.
 *
 * <p>Files are opened with TRUNCATE — matching {@code OPEN OUTPUT}.
 */
@Component
public class BatchRunner {

    private final RecordCodec codec;
    private final RequestValidator validator;
    private final MotorPremiumCalculator calculator;

    public BatchRunner(RecordCodec codec,
                       RequestValidator validator,
                       MotorPremiumCalculator calculator) {
        this.codec = codec;
        this.validator = validator;
        this.calculator = calculator;
    }

    public int run(Path requestsFile, Path outDir) {
        Path policyOut = outDir.resolve("policy.dat");
        Path motorOut  = outDir.resolve("motor.dat");
        Path errorOut  = outDir.resolve("error.log");

        try {
            Files.createDirectories(outDir);
        } catch (IOException e) {
            System.err.println("FATAL: cannot create output dir " + outDir + ": " + e);
            return 90;
        }

        try (BufferedReader in = Files.newBufferedReader(requestsFile, StandardCharsets.US_ASCII);
             BufferedWriter polW = Files.newBufferedWriter(policyOut, StandardCharsets.US_ASCII,
                     StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
             BufferedWriter motW = Files.newBufferedWriter(motorOut, StandardCharsets.US_ASCII,
                     StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
             BufferedWriter errW = Files.newBufferedWriter(errorOut, StandardCharsets.US_ASCII,
                     StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE)) {

            int processed = 0, inserted = 0, rejected = 0;
            BigDecimal nextPolicyNum = BigDecimal.ONE;

            String line;
            while ((line = in.readLine()) != null) {
                processed++;
                MotorPolicyRequest req;
                try {
                    req = codec.parseRequest(line);
                } catch (RuntimeException e) {
                    rejected++;
                    writeErr(errW, BigDecimal.ZERO, 90, "parse error: " + e.getMessage());
                    System.out.println(formatErr(BigDecimal.ZERO, 90, "parse error: " + e.getMessage()));
                    continue;
                }

                // Validate (mirrors CHECK-REQUEST-ID + VALIDATE-REQUEST short-circuit).
                Optional<ValidationFailure> v = validator.validate(req);
                if (v.isPresent()) {
                    rejected++;
                    ValidationFailure f = v.get();
                    writeErr(errW, req.customerNum(), f.returnCode(), f.reason());
                    System.out.println(formatErr(req.customerNum(), f.returnCode(), f.reason()));
                    continue;
                }

                // Calculate premium (mirrors CALC-MOTOR-PREMIUM with ON SIZE ERROR).
                BigDecimal premium;
                try {
                    premium = calculator.calculate(req.cc(), req.value(), req.accidents());
                } catch (PremiumOverflowException e) {
                    rejected++;
                    writeErr(errW, req.customerNum(), 11, e.getMessage());
                    System.out.println(formatErr(req.customerNum(), 11, e.getMessage()));
                    continue;
                }

                // Build entities (mirrors INSERT-POLICY + INSERT-MOTOR).
                PolicyEntity policy = new PolicyEntity(
                        nextPolicyNum, req.customerNum(), "M",
                        req.issueDate(), req.expiryDate(),
                        req.brokerId(), req.brokersRef(), req.payment());
                MotorEntity motor = new MotorEntity(
                        nextPolicyNum, req.make(), req.model(), req.value(),
                        req.regnumber(), req.colour(), req.cc(),
                        req.manufactured(), premium, req.accidents());

                // Write parent then child (no transaction in module zero — see spec §8).
                try {
                    polW.write(codec.encodePolicy(policy));
                    polW.newLine();
                    motW.write(codec.encodeMotor(motor));
                    motW.newLine();
                } catch (IOException e) {
                    rejected++;
                    writeErr(errW, req.customerNum(), 90, "write failed: " + e.getMessage());
                    System.out.println(formatErr(req.customerNum(), 90, "write failed: " + e.getMessage()));
                    continue;
                }

                inserted++;
                System.out.println(formatOk(req.customerNum(), nextPolicyNum, premium));
                nextPolicyNum = nextPolicyNum.add(BigDecimal.ONE);
            }

            System.out.println(String.format(
                    "SUMMARY processed=%06d inserted=%06d rejected=%06d",
                    processed, inserted, rejected));
            return 0;

        } catch (IOException e) {
            System.err.println("FATAL: cannot open input: " + e);
            return 90;
        }
    }

    // ---- formatters (must be byte-exact; see spec §6.1) ----

    static String formatOk(BigDecimal customer, BigDecimal policy, BigDecimal premium) {
        // "OK  CUST=NNNNNNNNNN POL=NNNNNNNNNN PREM=NNNNNN"   (two spaces after OK)
        return "OK  CUST=" + RecordCodec.num(customer, 10)
             + " POL=" + RecordCodec.num(policy, 10)
             + " PREM=" + RecordCodec.num(premium, 6);
    }

    static String formatErr(BigDecimal customer, int rc, String reason) {
        // "ERR CUST=NNNNNNNNNN RC=NN <reason padded with spaces to 106 chars>"
        return "ERR CUST=" + RecordCodec.num(customer, 10)
             + " RC=" + String.format("%02d", rc)
             + " " + RecordCodec.padRight(reason, 106);
    }

    static void writeErr(BufferedWriter errW, BigDecimal customer, int rc, String reason) throws IOException {
        // error.log is LINE SEQUENTIAL: trailing spaces stripped on WRITE.
        String line = RecordCodec.num(customer, 10) + " "
                    + String.format("%02d", rc) + " "
                    + reason;
        errW.write(line.stripTrailing());
        errW.newLine();
    }
}
