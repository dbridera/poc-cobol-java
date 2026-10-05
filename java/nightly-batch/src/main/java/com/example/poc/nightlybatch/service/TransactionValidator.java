package com.example.poc.nightlybatch.service;

import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.ZonedDecimal;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * {@code 1500-VALIDATE-TRAN} of CBTRN02C: the four posting checks, in order,
 * writing a single reason field — a later failure overwrites an earlier one.
 */
public final class TransactionValidator {

    /** Outcome: reason 0 = valid. The XREF and account records read along the way are kept
     *  in the caller's working storage, as {@code READ … INTO} does. */
    public record Result(int reason, String description) {
        public static final Result OK = new Result(0, "");
        public boolean valid() { return reason == 0; }
    }

    private final KsdsTable xref;
    private final KsdsTable accounts;

    public TransactionValidator(KsdsTable xref, KsdsTable accounts) {
        this.xref = xref;
        this.accounts = accounts;
    }

    /**
     * @param daly       the DALYTRAN-RECORD being validated
     * @param xrefWs     working-storage CARD-XREF-RECORD, overwritten on a successful read
     * @param accountWs  working-storage ACCOUNT-RECORD, overwritten on a successful read
     */
    // COBOL: CBTRN02C.cbl:370-423
    public Result validate(CobolRecord daly, CobolRecord xrefWs, CobolRecord accountWs) {
        // 1500-A-LOOKUP-XREF — COBOL: CBTRN02C.cbl:380-392
        Optional<CobolRecord> x = xref.read(daly.get("TRAN-CARD-NUM"));
        if (x.isEmpty()) {
            return new Result(100, "INVALID CARD NUMBER FOUND");
        }
        xrefWs.moveFrom(x.get());

        // 1500-B-LOOKUP-ACCT — COBOL: CBTRN02C.cbl:393-423
        Optional<CobolRecord> a = accounts.read(xrefWs.get("XREF-ACCT-ID"));
        if (a.isEmpty()) {
            return new Result(101, "ACCOUNT RECORD NOT FOUND");
        }
        accountWs.moveFrom(a.get());
        Result result = Result.OK;

        // COMPUTE WS-TEMP-BAL = ACCT-CURR-CYC-CREDIT - ACCT-CURR-CYC-DEBIT + DALYTRAN-AMT
        // WS-TEMP-BAL is S9(09)V99: an 11th integer digit is silently dropped (faithful defect D6, ADR-12)
        BigDecimal temp = ZonedDecimal.truncate(
                accountWs.decimal("ACCT-CURR-CYC-CREDIT")
                        .subtract(accountWs.decimal("ACCT-CURR-CYC-DEBIT"))
                        .add(daly.decimal("TRAN-AMT")), 11, 2);
        if (accountWs.decimal("ACCT-CREDIT-LIMIT").compareTo(temp) < 0) {
            result = new Result(102, "OVERLIMIT TRANSACTION");
        }
        // IF ACCT-EXPIRAION-DATE >= DALYTRAN-ORIG-TS (1:10) — alphanumeric comparison, runs even after 102
        if (accountWs.get("ACCT-EXPIRAION-DATE").compareTo(daly.substring("TRAN-ORIG-TS", 1, 10)) < 0) {
            result = new Result(103, "TRANSACTION RECEIVED AFTER ACCT EXPIRATION");
        }
        return result;
    }
}
