package com.example.poc.cciaccountconverter.service;

import com.example.poc.cciaccountconverter.domain.Commarea;
import org.springframework.stereotype.Service;

/**
 * Mirror of {@code 1000-VALIDA-ARGUMENTOS THRU 1000-FINVALIDA} in
 * [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:198-245].
 *
 * <p>Rules are evaluated <b>in order</b>; the <b>first</b> failure sets
 * RC=99, writes the verbatim message text, and stops (the COBOL
 * {@code GOBACK} exits the entire BCTITSCV program — mirrored here as
 * an early return from {@link #validate}).
 *
 * <p>Message strings are reproduced verbatim — including the trailing
 * space in {@code "DATOS NO NUMERICOS "} which is part of the original
 * COBOL literal.
 */
// COBOL: BCTITSCV-RUN.cbl:198-245
@Service
public class BctitscvValidator {

    static final String MSG_COD_SIST_INVALID = "COD. SIST.NO VALIDO";
    static final String MSG_ACCT_TYPE_NUMERIC = "ACCT.TYPE NO NUMRIC";
    static final String MSG_DATOS_NO_NUMERICOS = "DATOS NO NUMERICOS "; // trailing space verbatim

    /**
     * Apply all rules. On any failure, mutates the commarea's RC + MSG
     * fields and returns {@code true} (= early-exit / GOBACK). On success,
     * sets RC to "00" and returns {@code false}.
     */
    // COBOL: BCTITSCV-RUN.cbl:198 (1000-VALIDA-ARGUMENTOS)
    public boolean validate(Commarea c) {
        c.setCodReturn("00");

        // Rule 1: COD-FAM must be in IM or ST sets.
        // COBOL: BCTITSCV-RUN.cbl:200-206
        if (!c.isFamilyIm() && !c.isFamilySt()) {
            fail(c, MSG_COD_SIST_INVALID);
            return true;
        }

        // Rule 2: COD-PRO must be IS NUMERIC.
        // COBOL: BCTITSCV-RUN.cbl:209-215
        if (!isNumeric(c.getBscCodPro())) {
            fail(c, MSG_ACCT_TYPE_NUMERIC);
            return true;
        }

        // Rule 3: per-family numeric check on the BCP-EDIT view.
        // COBOL: BCTITSCV-RUN.cbl:218-242
        if (c.isFamilyIm()) {
            if (!isNumeric(c.getOfiBcpIm())
                    || !isNumeric(c.getNumBcpIm())
                    || !isNumeric(c.getMonBcpIm())
                    || !isNumeric(c.getDigBcpIm())) {
                fail(c, MSG_DATOS_NO_NUMERICOS);
                return true;
            }
        } else { // ST
            if (!isNumeric(c.getOfiBcpSt())
                    || !isNumeric(c.getNumBcpSt())
                    || !isNumeric(c.getMonBcpSt())
                    || !isNumeric(c.getDigBcpSt())) {
                fail(c, MSG_DATOS_NO_NUMERICOS);
                return true;
            }
        }

        return false; // all rules passed
    }

    private static void fail(Commarea c, String message) {
        c.setCodReturn("99");
        c.setMsgReturn(message);
    }

    /** COBOL {@code IS NUMERIC}: every byte is an ASCII digit, non-empty. */
    static boolean isNumeric(String s) {
        if (s == null || s.isEmpty()) return false;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c < '0' || c > '9') return false;
        }
        return true;
    }
}
