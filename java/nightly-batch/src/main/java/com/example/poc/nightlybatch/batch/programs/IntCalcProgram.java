package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layouts;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.StepIo;
import com.example.poc.nightlybatch.io.ZonedDecimal;
import com.example.poc.nightlybatch.service.CobolTimestamp;
import com.example.poc.nightlybatch.service.InterestCalculator;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Step 2 — INTCALC: the {@code INTCALC} driver (PARM from the manifest) calling
 * {@code CBACT04C} — monthly interest per account/category balance.
 */
// COBOL: INTCALC.cbl:17-32 (driver), CBACT04C.cbl:181-232 (main loop)
final class IntCalcProgram implements StepProgram {
    private final Programs programs;

    IntCalcProgram(Programs programs) {
        this.programs = programs;
    }

    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        // INTCALC driver: PARM-DATE X(10) from the PARM environment variable
        String parmDate = (run.parm(step) + " ".repeat(10)).substring(0, 10);

        io.entry("INTCALC");
        io.entry("CBACT04C");                                               // CALL 'CBACT04C' USING EXTERNAL-PARMS
        io.display("START OF EXECUTION OF PROGRAM CBACT04C");
        // 0000-…-0400 opens — COBOL: CBACT04C.cbl:182-186, 234-324
        for (String open : new String[]{"0000-TCATBALF-OPEN", "0100-XREFFILE-OPEN", "0200-DISCGRP-OPEN",
                                        "0300-ACCTFILE-OPEN", "0400-TRANFILE-OPEN"}) {
            io.paragraph("CBACT04C", open);
        }
        KsdsTable tcatbal = programs.table(run, step, "TCATBALF");
        KsdsTable xref = programs.table(run, step, "XREFFILE");
        KsdsTable discgrp = programs.table(run, step, "DISCGRP");
        KsdsTable accounts = programs.table(run, step, "ACCTFILE");
        List<CobolRecord> balances = tcatbal.readAllInKeyOrder();        // ACCESS SEQUENTIAL: key order

        // working storage — COBOL: CBACT04C.cbl:95-174
        CobolRecord tcatbalWs = CobolRecord.initialized(Layouts.TCATBAL);  // TRAN-CAT-BAL-RECORD
        CobolRecord accountWs = CobolRecord.initialized(Layouts.ACCOUNT);  // ACCOUNT-RECORD
        CobolRecord xrefWs = CobolRecord.initialized(Layouts.XREF);        // CARD-XREF-RECORD
        CobolRecord discgrpWs = CobolRecord.initialized(Layouts.DISCGRP);  // DIS-GROUP-RECORD
        CobolRecord tran = CobolRecord.initialized(Layouts.TRAN);          // TRAN-RECORD
        String lastAcctNum = " ".repeat(11);                                // WS-LAST-ACCT-NUM X(11)
        BigDecimal totalInt = BigDecimal.ZERO;                              // WS-TOTAL-INT S9(09)V99
        boolean firstTime = true;                                           // WS-FIRST-TIME
        long tranIdSuffix = 0;                                              // WS-TRANID-SUFFIX 9(06)

        InterestCalculator calc = new InterestCalculator(discgrp, accounts, io);
        String timestamp = CobolTimestamp.db2Format(run.clock());

        try (FixedRecordFile.Writer systran = FixedRecordFile.openOutput(run.dd(step, "TRANSACT"), Layouts.TRAN.lrecl())) {
            for (CobolRecord next : balances) {                             // 1000-TCATBALF-GET-NEXT until status 10 — COBOL: CBACT04C.cbl:325-349
                io.paragraph("CBACT04C", "1000-TCATBALF-GET-NEXT");
                tcatbalWs.moveFrom(next);
                io.display(tcatbalWs.toString());                           // DISPLAY TRAN-CAT-BAL-RECORD
                String acctId = tcatbalWs.get("TRANCAT-ACCT-ID");
                if (!acctId.equals(lastAcctNum)) {                          // control break on account
                    if (!firstTime) {
                        calc.updateAccount(accountWs, totalInt);            // 1050-UPDATE-ACCOUNT for the previous account
                    } else {
                        firstTime = false;
                    }
                    totalInt = BigDecimal.ZERO;
                    lastAcctNum = acctId;
                    // 1100-GET-ACCT-DATA — COBOL: CBACT04C.cbl:372-392
                    io.paragraph("CBACT04C", "1100-GET-ACCT-DATA");
                    Optional<CobolRecord> acct = accounts.read(acctId);
                    if (acct.isEmpty()) {
                        io.display("ACCOUNT NOT FOUND: ", acctId);
                        io.display("ERROR READING ACCOUNT FILE");
                        CobolRuntime.displayIoStatus(io, "CBACT04C", "23");
                        throw CobolRuntime.abend(io, "CBACT04C");
                    }
                    accountWs.moveFrom(acct.get());
                    // 1110-GET-XREF-DATA (READ … KEY IS FD-XREF-ACCT-ID) — COBOL: CBACT04C.cbl:393-414
                    io.paragraph("CBACT04C", "1110-GET-XREF-DATA");
                    Optional<CobolRecord> x = xref.readByAlternateKey(0, acctId);
                    if (x.isEmpty()) {
                        io.display("ACCOUNT NOT FOUND: ", acctId);
                        io.display("ERROR READING XREF FILE");
                        CobolRuntime.displayIoStatus(io, "CBACT04C", "23");
                        throw CobolRuntime.abend(io, "CBACT04C");
                    }
                    xrefWs.moveFrom(x.get());
                }
                // 1200-GET-INTEREST-RATE (+ DEFAULT fallback) — COBOL: CBACT04C.cbl:207-212, 415-461
                try {
                    calc.lookupRate(accountWs.get("ACCT-GROUP-ID"), tcatbalWs.get("TRANCAT-TYPE-CD"),
                            tcatbalWs.get("TRANCAT-CD"), discgrpWs);
                } catch (InterestCalculator.LookupFailed e) {
                    CobolRuntime.displayIoStatus(io, "CBACT04C", "23");
                    throw CobolRuntime.abend(io, "CBACT04C");
                }
                if (discgrpWs.decimal("DIS-INT-RATE").signum() != 0) {     // IF DIS-INT-RATE NOT = 0
                    // 1300-COMPUTE-INTEREST — COBOL: CBACT04C.cbl:462-472
                    io.paragraph("CBACT04C", "1300-COMPUTE-INTEREST");
                    BigDecimal monthly = InterestCalculator.monthlyInterest(
                            tcatbalWs.decimal("TRAN-CAT-BAL"), discgrpWs.decimal("DIS-INT-RATE"));
                    totalInt = ZonedDecimal.truncate(totalInt.add(monthly), 11, 2);   // ADD WS-MONTHLY-INT TO WS-TOTAL-INT
                    // 1300-B-WRITE-TX — COBOL: CBACT04C.cbl:473-517
                    io.paragraph("CBACT04C", "1300-B-WRITE-TX");
                    tranIdSuffix = (tranIdSuffix + 1) % 1_000_000;          // ADD 1 TO WS-TRANID-SUFFIX 9(06)
                    io.paragraph("CBACT04C", "Z-GET-DB2-FORMAT-TIMESTAMP");
                    InterestCalculator.fillInterestTransaction(tran, parmDate, tranIdSuffix, accountWs, xrefWs, monthly, timestamp);
                    systran.write(tran.toString());
                    // 1400-COMPUTE-FEES — COBOL: CBACT04C.cbl:518-521 (empty paragraph)
                    io.paragraph("CBACT04C", "1400-COMPUTE-FEES");
                }
            }
            // COBOL: CBACT04C.cbl:219-221 — ELSE PERFORM 1050-UPDATE-ACCOUNT is unreachable:
            // the last account's interest is never written back (faithful defect D1, CLAUDE.md rule 5).
        }
        io.paragraph("CBACT04C", "1000-TCATBALF-GET-NEXT");                 // the read that returns status 10
        // 9000-…-9400 closes — COBOL: CBACT04C.cbl:226-230, 522-612
        for (String close : new String[]{"9000-TCATBALF-CLOSE", "9100-XREFFILE-CLOSE", "9200-DISCGRP-CLOSE",
                                         "9300-ACCTFILE-CLOSE", "9400-TRANFILE-CLOSE"}) {
            io.paragraph("CBACT04C", close);
        }
        io.display("END OF EXECUTION OF PROGRAM CBACT04C");
        return 0;
    }
}
