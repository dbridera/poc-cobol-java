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
        io.entry("CBTRN03C");
        io.display("START OF EXECUTION OF PROGRAM CBTRN03C");
        // 0000-…-0500 opens — COBOL: CBTRN03C.cbl:159-164, 376-483
        for (String open : new String[]{"0000-TRANFILE-OPEN", "0100-REPTFILE-OPEN", "0200-CARDXREF-OPEN",
                                        "0300-TRANTYPE-OPEN", "0400-TRANCATG-OPEN", "0500-DATEPARM-OPEN"}) {
            io.paragraph("CBTRN03C", open);
        }
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
        io.paragraph("CBTRN03C", "0550-DATEPARM-READ");
        List<String> parm = FixedRecordFile.readAll(run.dd(step, "DATEPARM"), Layouts.DATEPARM.lrecl());
        CobolRecord dateparm = CobolRecord.of(Layouts.DATEPARM, parm.get(0));
        String startDate = dateparm.get("WS-START-DATE");
        String endDate = dateparm.get("WS-END-DATE");
        io.display("Reporting from ", startDate, " to ", endDate);

        try (FixedRecordFile.Writer rept = FixedRecordFile.openOutput(run.dd(step, "TRANREPT"), ReportWriter.LINE)) {
            ReportWriter report = new ReportWriter(rept, io);
            for (String raw : transactions) {                               // 1000-TRANFILE-GET-NEXT, status 00 — COBOL: CBTRN03C.cbl:248-272
                io.paragraph("CBTRN03C", "1000-TRANFILE-GET-NEXT");
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
                    io.paragraph("CBTRN03C", "1500-A-LOOKUP-XREF");
                    Optional<CobolRecord> x = xref.read(currCardNum);
                    if (x.isEmpty()) {
                        io.display("INVALID CARD NUMBER : ", currCardNum);
                        CobolRuntime.displayIoStatus(io, "CBTRN03C", "23");
                        throw CobolRuntime.abend(io, "CBTRN03C");
                    }
                    xrefWs.moveFrom(x.get());
                }
                // 1500-B-LOOKUP-TRANTYPE — COBOL: CBTRN03C.cbl:494-502
                io.paragraph("CBTRN03C", "1500-B-LOOKUP-TRANTYPE");
                Optional<CobolRecord> t = trantype.read(tran.get("TRAN-TYPE-CD"));
                if (t.isEmpty()) {
                    io.display("INVALID TRANSACTION TYPE : ", tran.get("TRAN-TYPE-CD"));
                    CobolRuntime.displayIoStatus(io, "CBTRN03C", "23");
                    throw CobolRuntime.abend(io, "CBTRN03C");
                }
                trantypeWs.moveFrom(t.get());
                // 1500-C-LOOKUP-TRANCATG — COBOL: CBTRN03C.cbl:504-512
                io.paragraph("CBTRN03C", "1500-C-LOOKUP-TRANCATG");
                String catKey = tran.get("TRAN-TYPE-CD") + tran.get("TRAN-CAT-CD");
                Optional<CobolRecord> c = trancatg.read(catKey);
                if (c.isEmpty()) {
                    io.display("INVALID TRAN CATG KEY : ", catKey);
                    CobolRuntime.displayIoStatus(io, "CBTRN03C", "23");
                    throw CobolRuntime.abend(io, "CBTRN03C");
                }
                trancatgWs.moveFrom(c.get());
                report.writeTransactionReport(tran, xrefWs, trantypeWs, trancatgWs, startDate, endDate);   // 1100-…
                firstTime = false;                                          // WS-FIRST-TIME := 'N' inside 1100 on first use
            }
            // end of file (status 10): READ INTO leaves the last record in TRAN-RECORD — COBOL: CBTRN03C.cbl:197-204
            io.paragraph("CBTRN03C", "1000-TRANFILE-GET-NEXT");             // the read that returns status 10
            io.display("TRAN-AMT ", CobolDisplay.signed(tran.decimal("TRAN-AMT"), 11, 2));
            io.display("WS-PAGE-TOTAL", CobolDisplay.signed(report.pageTotal(), 11, 2));
            report.addStaleAmount(tran.decimal("TRAN-AMT"));                // faithful defect D2
            report.writePageTotals();                                       // 1110-WRITE-PAGE-TOTALS
            report.writeGrandTotals();                                      // 1110-WRITE-GRAND-TOTALS
        }
        // L$0: GnuCOBOL's label for the sentence after `END-PERFORM.` (the NEXT SENTENCE target of line 177);
        // traced once when the main loop ends — COBOL: CBTRN03C.cbl:166-209
        io.paragraph("CBTRN03C", "L$0");
        // 9000-…-9500 closes — COBOL: CBTRN03C.cbl:211-216, 514-625
        for (String close : new String[]{"9000-TRANFILE-CLOSE", "9100-REPTFILE-CLOSE", "9200-CARDXREF-CLOSE",
                                         "9300-TRANTYPE-CLOSE", "9400-TRANCATG-CLOSE", "9500-DATEPARM-CLOSE"}) {
            io.paragraph("CBTRN03C", close);
        }
        io.display("END OF EXECUTION OF PROGRAM CBTRN03C");
        return 0;
    }
}
