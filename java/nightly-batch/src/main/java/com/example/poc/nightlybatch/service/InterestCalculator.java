package com.example.poc.nightlybatch.service;

import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.StepIo;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Optional;

/**
 * The business paragraphs of CBACT04C: rate lookup with DEFAULT fallback,
 * monthly interest, the interest transaction and the account update.
 */
public final class InterestCalculator {
    private static final BigDecimal TWELVE_HUNDRED = BigDecimal.valueOf(1200);

    /** Thrown where CBACT04C abends after its own error displays. */
    public static final class LookupFailed extends RuntimeException {
        LookupFailed() { super("abend"); }
    }

    private final KsdsTable discgrp;
    private final KsdsTable accounts;
    private final StepIo io;

    public InterestCalculator(KsdsTable discgrp, KsdsTable accounts, StepIo io) {
        this.discgrp = discgrp;
        this.accounts = accounts;
        this.io = io;
    }

    /**
     * {@code 1200-GET-INTEREST-RATE} + {@code 1200-A-GET-DEFAULT-INT-RATE}: read the
     * disclosure-group row for (group, type, category); on status 23 retry with group
     * {@code DEFAULT}; if that is missing too, the program abends. The record read
     * lands in the working-storage DIS-GROUP-RECORD.
     */
    // COBOL: CBACT04C.cbl:415-461
    public void lookupRate(String groupId, String typeCd, String catCd, CobolRecord discgrpWs) {
        io.paragraph("CBACT04C", "1200-GET-INTEREST-RATE");
        Optional<CobolRecord> row = discgrp.read(groupId + typeCd + catCd);
        if (row.isPresent()) {
            discgrpWs.moveFrom(row.get());
            return;
        }
        io.display("DISCLOSURE GROUP RECORD MISSING");
        io.display("TRY WITH DEFAULT GROUP CODE");
        io.paragraph("CBACT04C", "1200-A-GET-DEFAULT-INT-RATE");
        Optional<CobolRecord> dflt = discgrp.read(padRight("DEFAULT", 10) + typeCd + catCd);
        if (dflt.isPresent()) {
            discgrpWs.moveFrom(dflt.get());
            return;
        }
        io.display("ERROR READING DEFAULT DISCLOSURE GROUP");
        throw new LookupFailed();
    }

    /**
     * {@code COMPUTE WS-MONTHLY-INT = (TRAN-CAT-BAL * DIS-INT-RATE) / 1200} — no ROUNDED,
     * so the quotient is truncated toward zero at 2 decimals (ADR-11): 0.09575 → 0.09,
     * −11.4875 → −11.48.
     */
    // COBOL: CBACT04C.cbl:462-467
    public static BigDecimal monthlyInterest(BigDecimal categoryBalance, BigDecimal annualRatePercent) {
        return categoryBalance.multiply(annualRatePercent).divide(TWELVE_HUNDRED, 2, RoundingMode.DOWN);
    }

    /**
     * {@code 1300-B-WRITE-TX}: fill the working-storage TRAN-RECORD for the interest
     * transaction. The description is a STRING of 24 characters; the rest of the
     * 100-byte field is whatever it already held (spaces).
     */
    // COBOL: CBACT04C.cbl:473-498
    public static void fillInterestTransaction(CobolRecord tran, String parmDate, long suffix, CobolRecord accountWs,
                                               CobolRecord xrefWs, BigDecimal monthlyInterest, String db2Timestamp) {
        tran.set("TRAN-ID", parmDate + String.format("%06d", suffix));            // STRING PARM-DATE, WS-TRANID-SUFFIX
        tran.set("TRAN-TYPE-CD", "01");
        tran.setDecimal("TRAN-CAT-CD", new BigDecimal("05"));                      // MOVE '05' TO TRAN-CAT-CD 9(4) → 0005
        tran.set("TRAN-SOURCE", "System");
        tran.set("TRAN-DESC", "Int. for a/c " + accountWs.get("ACCT-ID"));         // STRING 'Int. for a/c ', ACCT-ID
        tran.setDecimal("TRAN-AMT", monthlyInterest);
        tran.setDecimal("TRAN-MERCHANT-ID", BigDecimal.ZERO);
        tran.set("TRAN-MERCHANT-NAME", "");
        tran.set("TRAN-MERCHANT-CITY", "");
        tran.set("TRAN-MERCHANT-ZIP", "");
        tran.set("TRAN-CARD-NUM", xrefWs.get("XREF-CARD-NUM"));
        tran.set("TRAN-ORIG-TS", db2Timestamp);
        tran.set("TRAN-PROC-TS", db2Timestamp);
    }

    /** {@code 1050-UPDATE-ACCOUNT}: add the account's accumulated interest, reset the cycle totals, REWRITE. */
    // COBOL: CBACT04C.cbl:350-371
    public void updateAccount(CobolRecord accountWs, BigDecimal totalInterest) {
        io.paragraph("CBACT04C", "1050-UPDATE-ACCOUNT");
        accountWs.add("ACCT-CURR-BAL", totalInterest);
        accountWs.setDecimal("ACCT-CURR-CYC-CREDIT", BigDecimal.ZERO);
        accountWs.setDecimal("ACCT-CURR-CYC-DEBIT", BigDecimal.ZERO);
        if (!accounts.rewrite(accountWs)) {
            io.display("ERROR RE-WRITING ACCOUNT FILE");
            throw new LookupFailed();
        }
    }

    private static String padRight(String s, int width) {
        return s.length() >= width ? s.substring(0, width) : s + " ".repeat(width - s.length());
    }
}
