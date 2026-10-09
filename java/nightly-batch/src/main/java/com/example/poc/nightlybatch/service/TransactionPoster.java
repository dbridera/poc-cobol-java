package com.example.poc.nightlybatch.service;

import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layouts;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.StepIo;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * {@code 2000-POST-TRANSACTION} of CBTRN02C and its three updates. Works on the
 * program's working-storage records exactly as the COBOL does: the transaction
 * record is built field by field, the category balance is read into (or
 * initialised in) its working-storage copy, the account copy filled by the
 * validator is updated and rewritten.
 */
public final class TransactionPoster {

    /** Thrown where CBTRN02C would abend (write failure on the transaction file). */
    public static final class TransactionWriteFailed extends RuntimeException {
        public final String status;
        TransactionWriteFailed(String status) { super("status " + status); this.status = status; }
    }

    private final KsdsTable tcatbal;
    private final KsdsTable accounts;
    private final KsdsTable transact;
    private final LocalDateTime clock;
    private final StepIo io;

    public TransactionPoster(KsdsTable tcatbal, KsdsTable accounts, KsdsTable transact, LocalDateTime clock, StepIo io) {
        this.tcatbal = tcatbal;
        this.accounts = accounts;
        this.transact = transact;
        this.clock = clock;
        this.io = io;
    }

    /**
     * @param daly       DALYTRAN-RECORD
     * @param tran       working-storage TRAN-RECORD (persists across records)
     * @param xrefWs     CARD-XREF-RECORD filled by the validator
     * @param accountWs  ACCOUNT-RECORD filled by the validator
     * @param tcatbalWs  working-storage TRAN-CAT-BAL-RECORD (persists across records)
     * @return the validation reason set by the account rewrite (109) or 0
     */
    // COBOL: CBTRN02C.cbl:424-445
    public int post(CobolRecord daly, CobolRecord tran, CobolRecord xrefWs, CobolRecord accountWs, CobolRecord tcatbalWs) {
        io.paragraph("CBTRN02C", "2000-POST-TRANSACTION");
        tran.set("TRAN-ID", daly.get("TRAN-ID"));
        tran.set("TRAN-TYPE-CD", daly.get("TRAN-TYPE-CD"));
        tran.setDecimal("TRAN-CAT-CD", daly.decimal("TRAN-CAT-CD"));
        tran.set("TRAN-SOURCE", daly.get("TRAN-SOURCE"));
        tran.set("TRAN-DESC", daly.get("TRAN-DESC"));
        tran.setDecimal("TRAN-AMT", daly.decimal("TRAN-AMT"));
        tran.setDecimal("TRAN-MERCHANT-ID", daly.decimal("TRAN-MERCHANT-ID"));
        tran.set("TRAN-MERCHANT-NAME", daly.get("TRAN-MERCHANT-NAME"));
        tran.set("TRAN-MERCHANT-CITY", daly.get("TRAN-MERCHANT-CITY"));
        tran.set("TRAN-MERCHANT-ZIP", daly.get("TRAN-MERCHANT-ZIP"));
        tran.set("TRAN-CARD-NUM", daly.get("TRAN-CARD-NUM"));
        tran.set("TRAN-ORIG-TS", daly.get("TRAN-ORIG-TS"));
        io.paragraph("CBTRN02C", "Z-GET-DB2-FORMAT-TIMESTAMP");
        tran.set("TRAN-PROC-TS", CobolTimestamp.db2Format(clock));
        updateTcatbal(daly, xrefWs, tcatbalWs);
        int reason = updateAccount(daly, accountWs);
        writeTransaction(tran);
        return reason;
    }

    // COBOL: CBTRN02C.cbl:467-544 (2700-UPDATE-TCATBAL, 2700-A, 2700-B)
    private void updateTcatbal(CobolRecord daly, CobolRecord xrefWs, CobolRecord tcatbalWs) {
        io.paragraph("CBTRN02C", "2700-UPDATE-TCATBAL");
        String key = xrefWs.get("XREF-ACCT-ID") + daly.get("TRAN-TYPE-CD") + daly.get("TRAN-CAT-CD");
        Optional<CobolRecord> found = tcatbal.read(key);
        if (found.isEmpty()) {
            io.display("TCATBAL record not found for key : ", key, ".. Creating.");
            // 2700-A-CREATE-TCATBAL-REC: INITIALIZE (FILLER untouched), key fields, ADD amount, WRITE
            io.paragraph("CBTRN02C", "2700-A-CREATE-TCATBAL-REC");
            tcatbalWs.initialize();
            tcatbalWs.setDecimal("TRANCAT-ACCT-ID", xrefWs.decimal("XREF-ACCT-ID"));
            tcatbalWs.set("TRANCAT-TYPE-CD", daly.get("TRAN-TYPE-CD"));
            tcatbalWs.setDecimal("TRANCAT-CD", daly.decimal("TRAN-CAT-CD"));
            tcatbalWs.add("TRAN-CAT-BAL", daly.decimal("TRAN-AMT"));
            if (!tcatbal.write(tcatbalWs)) {
                throw new TransactionWriteFailed("22");   // 'ERROR WRITING TRANSACTION BALANCE FILE' path, not exercised
            }
        } else {
            // 2700-B-UPDATE-TCATBAL-REC: ADD amount, REWRITE
            io.paragraph("CBTRN02C", "2700-B-UPDATE-TCATBAL-REC");
            tcatbalWs.moveFrom(found.get());
            tcatbalWs.add("TRAN-CAT-BAL", daly.decimal("TRAN-AMT"));
            tcatbal.rewrite(tcatbalWs);
        }
    }

    // COBOL: CBTRN02C.cbl:545-561 (2800-UPDATE-ACCOUNT-REC)
    private int updateAccount(CobolRecord daly, CobolRecord accountWs) {
        io.paragraph("CBTRN02C", "2800-UPDATE-ACCOUNT-REC");
        BigDecimal amt = daly.decimal("TRAN-AMT");
        accountWs.add("ACCT-CURR-BAL", amt);                  // no ON SIZE ERROR: high-order digits drop (ADR-12)
        if (amt.signum() >= 0) {
            accountWs.add("ACCT-CURR-CYC-CREDIT", amt);
        } else {
            accountWs.add("ACCT-CURR-CYC-DEBIT", amt);        // debits accumulate as a negative number
        }
        return accounts.rewrite(accountWs) ? 0 : 109;         // INVALID KEY → 109 'ACCOUNT RECORD NOT FOUND' (not a reject)
    }

    // COBOL: CBTRN02C.cbl:562-581 (2900-WRITE-TRANSACTION-FILE)
    private void writeTransaction(CobolRecord tran) {
        io.paragraph("CBTRN02C", "2900-WRITE-TRANSACTION-FILE");
        if (!transact.write(tran)) {
            throw new TransactionWriteFailed("22");
        }
    }
}
