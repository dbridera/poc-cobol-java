package com.example.poc.cciaccountconverter.batch;

import com.example.poc.cciaccountconverter.domain.Commarea;
import com.example.poc.cciaccountconverter.service.BctitscvService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Mirror of the {@code DRIVER-BCTITSCV} outer program in
 * [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:14-86].
 *
 * <p>Read each line from {@code requests.dat}, parse 6 whitespace-separated
 * tokens into a fresh {@link Commarea}, invoke {@link BctitscvService},
 * then emit a deterministic stdout block. Output format is the
 * byte-exact equivalence contract — see spec §7 for the line shape.
 *
 * <p>Invoked by {@code tools/run-java.sh} as
 * {@code java -jar <jar> requests.dat <outDir>}. This module writes no
 * output files, so {@code outDir} is unused.
 */
// COBOL: BCTITSCV-RUN.cbl:31-73
@Component
public class BatchRunner implements CommandLineRunner {

    private final BctitscvService service;

    public BatchRunner(BctitscvService service) {
        this.service = service;
    }

    @Override
    public void run(String... args) throws Exception {
        Path requestsFile = Path.of(args.length > 0 ? args[0] : "requests.dat");

        try (BufferedReader in = Files.newBufferedReader(requestsFile, StandardCharsets.US_ASCII)) {
            String line;
            while ((line = in.readLine()) != null) {
                if (line.isBlank()) continue;
                Commarea c = parseRequest(line);
                service.run(c);
                displayResult(c);
            }
        }
    }

    /**
     * Mirror of the driver's {@code UNSTRING WS-INPUT-LINE DELIMITED BY ALL
     * SPACES INTO ...} (BCTITSCV-RUN.cbl:55-63).
     *
     * <p>Token order: {@code IND-CONV COD-INTFZ BSC-COD-FAM BSC-COD-PRO
     * BSC-COD-SPR COD-CTA-CCI}.
     */
    // COBOL: BCTITSCV-RUN.cbl:50-63
    static Commarea parseRequest(String line) {
        Commarea c = new Commarea(); // initial state == MOVE SPACES (every field space-padded)
        String[] toks = line.trim().split("\\s+");
        if (toks.length < 6) {
            throw new IllegalArgumentException(
                "expected 6 whitespace-separated tokens, got " + toks.length + " in: " + line);
        }
        c.setIndConv(toks[0]);
        c.setCodIntfz(toks[1]);
        c.setBscCodFam(toks[2]);
        c.setBscCodPro(toks[3]);
        c.setBscCodSpr(toks[4]);
        c.setCodCtaCci(toks[5]);
        return c;
    }

    /**
     * Mirror of {@code DISPLAY-RESULT} (BCTITSCV-RUN.cbl:66-73).
     *
     * <p>Format:
     * <pre>
     *   RC: &lt;2 chars&gt;
     *   MSG: &lt;trimmed, may be empty&gt;
     *   FAM-RET: &lt;3 chars, space-padded&gt;
     *   BCP-EDIT: &lt;20 chars&gt;
     *   CUENTA-ITE: &lt;20 chars&gt;
     *   ---
     * </pre>
     *
     * <p>Fields are emitted at full PIC width (space-padded right). MSG is
     * the only field that's trimmed — mirrors COBOL {@code FUNCTION TRIM}
     * in the driver.
     */
    // COBOL: BCTITSCV-RUN.cbl:66-73
    static void displayResult(Commarea c) {
        // COBOL DISPLAY appends a newline; the literal includes the trailing
        // space after the colon (verbatim from the COBOL string literal).
        System.out.println("RC: "         + c.getCodReturn());
        System.out.println("MSG: "        + c.getMsgReturn().stripTrailing());
        System.out.println("FAM-RET: "    + c.getBscCodFamRet());
        System.out.println("BCP-EDIT: "   + c.getBcpEditIm());
        System.out.println("CUENTA-ITE: " + c.getCuentaIteEdit());
        System.out.println("---");
    }
}
