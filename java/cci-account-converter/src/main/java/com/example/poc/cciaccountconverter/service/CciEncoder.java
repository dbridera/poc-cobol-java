package com.example.poc.cciaccountconverter.service;

import com.example.poc.cciaccountconverter.domain.Commarea;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Mirror of {@code 1500-CALCULA-CHEQUEO-INT THRU 1500-FININT} in
 * [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:247-270].
 *
 * <p>Commercial-account → CCI encoder. Builds the 20-byte
 * {@code CUENTA-ITE-EDIT} in two parts: the body (bytes 1-18) is copied
 * from the commarea's BCP-EDIT view, then {@link CheckDigitCalculator}
 * fills the two trailing check-digit bytes (19-20).
 *
 * <p>Note the hard-coded bank ID {@code "002"} for BCP — flagged in the
 * spec §11 SME checklist.
 */
// COBOL: BCTITSCV-RUN.cbl:247-270
@Service
public class CciEncoder {

    private static final String BCP_BANK_ID = "002";

    private final CheckDigitCalculator checkDigit;

    public CciEncoder(CheckDigitCalculator checkDigit) {
        this.checkDigit = checkDigit;
    }

    // COBOL: BCTITSCV-RUN.cbl:247-270
    public void encode(Commarea c) {
        // Bytes 1-3: BCO-ITE — always BCP.
        // COBOL: BCTITSCV-RUN.cbl:248
        String bcoIte = BCP_BANK_ID;

        // Bytes 4-6 (OFI-ITE), byte 7 (PRO-ITE), bytes 8-15 (NUM-ITE),
        // byte 16 (MON-ITE), bytes 17-18 (DIG-INT).
        String ofiIte;
        String proIte;
        String numIte;
        String monIte;
        String digInt;

        // COBOL: BCTITSCV-RUN.cbl:249-258 (IF TI-YRCV-BSC-COD-FAM-IM)
        if (c.isFamilyIm()) {
            proIte = "0";
            ofiIte = c.getOfiBcpIm();
            // STRING '0' DELIMITED BY SIZE, NUM-BCP-IM(7) DELIMITED BY SIZE INTO NUM-ITE(8)
            // COBOL: BCTITSCV-RUN.cbl:252-254
            numIte = "0" + c.getNumBcpIm();
            monIte = c.getMonBcpIm();
            digInt = c.getDigBcpIm();
        } else { // ST branch (SAVING + CTS)
            // COBOL: BCTITSCV-RUN.cbl:260-269
            proIte = "1";
            // CTS override
            // COBOL: BCTITSCV-RUN.cbl:262-265
            if ("009".equals(c.getBscCodFam())) {
                proIte = "2";
            }
            ofiIte = c.getOfiBcpSt();
            numIte = c.getNumBcpSt();
            monIte = c.getMonBcpSt();
            digInt = c.getDigBcpSt();
        }

        // Compute DIG-ITE1 over the 6-digit OFIBAN-ITE = BCO-ITE || OFI-ITE.
        // COBOL: BCTITSCV-RUN.cbl:272-283 (2000-CALCULA-DIGCHEQ-BANOFI)
        String ofibanIte = bcoIte + ofiIte;
        BigDecimal digIte1 = checkDigit.compute(ofibanIte);

        // Compute DIG-ITE2 over the 12-digit NUMERO-ITE
        //   = PRO-ITE || NUM-ITE || MON-ITE || DIG-INT.
        // COBOL: BCTITSCV-RUN.cbl:285-292 (3000-CALCULA-DIGCHEQ-CUENTA)
        String numeroIte = proIte + numIte + monIte + digInt;
        BigDecimal digIte2 = checkDigit.compute(numeroIte);

        // Assemble the full 20-byte CUENTA-ITE-EDIT.
        // COBOL layout: OFIBAN-ITE (6) + NUMERO-ITE (12) + DIG-CHEQUEO (2) = 20
        c.setCuentaIteEdit(ofibanIte + numeroIte + digIte1.toString() + digIte2.toString());
    }
}
