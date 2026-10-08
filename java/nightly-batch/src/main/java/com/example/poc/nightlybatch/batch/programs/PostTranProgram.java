package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layouts;
import com.example.poc.nightlybatch.io.CobolDisplay;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.StepIo;
import com.example.poc.nightlybatch.service.TransactionPoster;
import com.example.poc.nightlybatch.service.TransactionValidator;

import java.math.BigDecimal;
import java.util.List;

/**
 * Step 1 — POSTTRAN: {@code CBTRN02C} — post the day's transactions.
 */
// COBOL: CBTRN02C.cbl:193-234 (PROCEDURE DIVISION main loop)
final class PostTranProgram implements StepProgram {
    private final Programs programs;

    PostTranProgram(Programs programs) {
        this.programs = programs;
    }

    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        io.entry("CBTRN02C");
        io.display("START OF EXECUTION OF PROGRAM CBTRN02C");
        // 0000-…-0500 opens — COBOL: CBTRN02C.cbl:195-200, 236-344
        for (String open : new String[]{"0000-DALYTRAN-OPEN", "0100-TRANFILE-OPEN", "0200-XREFFILE-OPEN",
                                        "0300-DALYREJS-OPEN", "0400-ACCTFILE-OPEN", "0500-TCATBALF-OPEN"}) {
            io.paragraph("CBTRN02C", open);
        }
        List<String> daily = FixedRecordFile.readAll(run.dd(step, "DALYTRAN"), Layouts.TRAN.lrecl());
        KsdsTable transact = programs.table(run, step, "TRANFILE");
        transact.truncate();                                               // OPEN OUTPUT TRANSACT-FILE
        KsdsTable xref = programs.table(run, step, "XREFFILE");
        KsdsTable accounts = programs.table(run, step, "ACCTFILE");
        KsdsTable tcatbal = programs.table(run, step, "TCATBALF");

        // working storage — COBOL: CBTRN02C.cbl:100-192
        CobolRecord dalytran = CobolRecord.initialized(Layouts.TRAN);     // DALYTRAN-RECORD (CVTRA06Y)
        CobolRecord tran = CobolRecord.initialized(Layouts.TRAN);         // TRAN-RECORD (CVTRA05Y)
        CobolRecord xrefWs = CobolRecord.initialized(Layouts.XREF);       // CARD-XREF-RECORD
        CobolRecord accountWs = CobolRecord.initialized(Layouts.ACCOUNT); // ACCOUNT-RECORD
        CobolRecord tcatbalWs = CobolRecord.initialized(Layouts.TCATBAL); // TRAN-CAT-BAL-RECORD
        CobolRecord reject = CobolRecord.initialized(Layouts.REJECT);     // REJECT-RECORD
        long transactionCount = 0;                                        // WS-TRANSACTION-COUNT 9(09)
        long rejectCount = 0;                                             // WS-REJECT-COUNT 9(09)

        TransactionValidator validator = new TransactionValidator(xref, accounts, io);
        TransactionPoster poster = new TransactionPoster(tcatbal, accounts, transact, run.clock(), io);

        try (FixedRecordFile.Writer rejects = FixedRecordFile.openOutput(run.dd(step, "DALYREJS"), Layouts.REJECT.lrecl())) {
            for (String raw : daily) {                                    // 1000-DALYTRAN-GET-NEXT until status 10
                io.paragraph("CBTRN02C", "1000-DALYTRAN-GET-NEXT");
                transactionCount++;
                dalytran.moveFrom(CobolRecord.of(Layouts.TRAN, raw));     // READ … INTO DALYTRAN-RECORD
                TransactionValidator.Result v = validator.validate(dalytran, xrefWs, accountWs);   // 1500-VALIDATE-TRAN
                if (v.valid()) {
                    try {
                        poster.post(dalytran, tran, xrefWs, accountWs, tcatbalWs);               // 2000-POST-TRANSACTION
                    } catch (TransactionPoster.TransactionWriteFailed e) {
                        io.display("ERROR WRITING TO TRANSACTION FILE");
                        CobolRuntime.displayIoStatus(io, "CBTRN02C", e.status);
                        throw CobolRuntime.abend(io, "CBTRN02C");
                    }
                } else {
                    rejectCount++;
                    io.paragraph("CBTRN02C", "2500-WRITE-REJECT-REC");
                    // 2500-WRITE-REJECT-REC — COBOL: CBTRN02C.cbl:446-466
                    reject.set("REJECT-TRAN-DATA", dalytran.toString());
                    reject.setDecimal("WS-VALIDATION-FAIL-REASON", BigDecimal.valueOf(v.reason()));
                    reject.set("WS-VALIDATION-FAIL-REASON-DESC", v.description());
                    rejects.write(reject.toString());
                }
            }
        }
        io.paragraph("CBTRN02C", "1000-DALYTRAN-GET-NEXT");                 // the read that returns status 10
        // 9000-…-9500 closes — COBOL: CBTRN02C.cbl:221-226
        for (String close : new String[]{"9000-DALYTRAN-CLOSE", "9100-TRANFILE-CLOSE", "9200-XREFFILE-CLOSE",
                                         "9300-DALYREJS-CLOSE", "9400-ACCTFILE-CLOSE", "9500-TCATBALF-CLOSE"}) {
            io.paragraph("CBTRN02C", close);
        }
        io.display("TRANSACTIONS PROCESSED :", CobolDisplay.unsigned(transactionCount, 9));
        io.display("TRANSACTIONS REJECTED  :", CobolDisplay.unsigned(rejectCount, 9));
        int rc = rejectCount > 0 ? 4 : 0;                                 // MOVE 4 TO RETURN-CODE
        io.display("END OF EXECUTION OF PROGRAM CBTRN02C");
        return rc;
    }
}
