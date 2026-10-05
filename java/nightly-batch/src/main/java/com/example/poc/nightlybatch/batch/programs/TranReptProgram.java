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
import com.example.poc.nightlybatch.service.ReportWriter;

import java.util.List;
import java.util.Optional;

/**
 * Step 4c — TRANREPT: {@code CBTRN03C} — the daily transaction report.
 */
// COBOL: CBTRN03C.cbl:157-218 (PROCEDURE DIVISION main loop)
final class TranReptProgram implements StepProgram {
    private final Programs programs;

    TranReptProgram(Programs programs) {
        this.programs = programs;
    }

    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        io.display("START OF EXECUTION OF PROGRAM CBTRN03C");
        // 0000-…-0500 opens — COBOL: CBTRN03C.cbl:159-164, 376-483
        List<String> transactions = FixedRecordFile.readAll(run.dd(step, "TRANFILE"), Layouts.TRAN.lrecl());
        KsdsTable xref = programs.table(run, step, "CARDXREF");
        KsdsTable trantype = programs.table(run, step, "TRANTYPE");
        KsdsTable trancatg = programs.table(run, step, "TRANCATG");

        // working storage — COBOL: CBTRN03C.cbl:93-155
        CobolRecord tran = CobolRecord.initialized(Layouts.TRAN);           // TRAN-RECORD
        CobolRecord xrefWs = CobolRecord.initialized(Layouts.XREF);         // CARD-XREF-RECORD
        CobolRecord trantypeWs = CobolRecord.initialized(Layouts.TRANTYPE); // TRAN-TYPE-RECORD
        CobolRecord trancatgWs = CobolRecord.initialized(Layouts.TRANCATG); // TRAN-CAT-RECORD
        String currCardNum = " ".repeat(16);                                // WS-CURR-CARD-NUM
        boolean firstTime = true;                                           // WS-FIRST-TIME (the loop's own copy of the flag)

        // 0550-DATEPARM-READ — COBOL: CBTRN03C.cbl:220-246
        List<String> parm = FixedRecordFile.readAll(run.dd(step, "DATEPARM"), Layouts.DATEPARM.lrecl());
        CobolRecord dateparm = CobolRecord.of(Layouts.DATEPARM, parm.get(0));
        String startDate = dateparm.get("WS-START-DATE");
        String endDate = dateparm.get("WS-END-DATE");
        io.display("Reporting from ", startDate, " to ", endDate);

        try (FixedRecordFile.Writer rept = FixedRecordFile.openOutput(run.dd(step, "TRANREPT"), ReportWriter.LINE)) {
            ReportWriter report = new ReportWriter(rept);
            for (String raw : transactions) {                               // 1000-TRANFILE-GET-NEXT, status 00
                tran.moveFrom(CobolRecord.of(Layouts.TRAN, raw));           // READ … INTO TRAN-RECORD
                // date filter (171-176): always true — REPTSORT applied the same range; the NEXT SENTENCE
                // branch would leave the loop (faithful defect D3, documented, unreachable)
                io.display(tran.toString());                                // DISPLAY TRAN-RECORD
                if (!currCardNum.equals(tran.get("TRAN-CARD-NUM"))) {       // IF WS-CURR-CARD-NUM NOT= TRAN-CARD-NUM
                    if (!firstTime) {
                        report.writeAccountTotals();                        // 1120-WRITE-ACCOUNT-TOTALS
                    }
                    currCardNum = tran.get("TRAN-CARD-NUM");
                    // 1500-A-LOOKUP-XREF — COBOL: CBTRN03C.cbl:484-492
                    Optional<CobolRecord> x = xref.read(currCardNum);
                    if (x.isEmpty()) {
                        io.display("INVALID CARD NUMBER : ", currCardNum);
                        CobolRuntime.displayIoStatus(io, "23");
                        throw CobolRuntime.abend(io);
                    }
                    xrefWs.moveFrom(x.get());
                }
                // 1500-B-LOOKUP-TRANTYPE — COBOL: CBTRN03C.cbl:494-502
                Optional<CobolRecord> t = trantype.read(tran.get("TRAN-TYPE-CD"));
                if (t.isEmpty()) {
                    io.display("INVALID TRANSACTION TYPE : ", tran.get("TRAN-TYPE-CD"));
                    CobolRuntime.displayIoStatus(io, "23");
                    throw CobolRuntime.abend(io);
                }
                trantypeWs.moveFrom(t.get());
                // 1500-C-LOOKUP-TRANCATG — COBOL: CBTRN03C.cbl:504-512
                String catKey = tran.get("TRAN-TYPE-CD") + tran.get("TRAN-CAT-CD");
                Optional<CobolRecord> c = trancatg.read(catKey);
                if (c.isEmpty()) {
                    io.display("INVALID TRAN CATG KEY : ", catKey);
                    CobolRuntime.displayIoStatus(io, "23");
                    throw CobolRuntime.abend(io);
                }
                trancatgWs.moveFrom(c.get());
                report.writeTransactionReport(tran, xrefWs, trantypeWs, trancatgWs, startDate, endDate);   // 1100-…
                firstTime = false;                                          // WS-FIRST-TIME := 'N' inside 1100 on first use
            }
            // end of file (status 10): READ INTO leaves the last record in TRAN-RECORD — COBOL: CBTRN03C.cbl:197-204
            io.display("TRAN-AMT ", CobolDisplay.signed(tran.decimal("TRAN-AMT"), 11, 2));
            io.display("WS-PAGE-TOTAL", CobolDisplay.signed(report.pageTotal(), 11, 2));
            report.addStaleAmount(tran.decimal("TRAN-AMT"));                // faithful defect D2
            report.writePageTotals();                                       // 1110-WRITE-PAGE-TOTALS
            report.writeGrandTotals();                                      // 1110-WRITE-GRAND-TOTALS
        }
        // 9000-…-9500 closes — COBOL: CBTRN03C.cbl:211-216
        io.display("END OF EXECUTION OF PROGRAM CBTRN03C");
        return 0;
    }
}
