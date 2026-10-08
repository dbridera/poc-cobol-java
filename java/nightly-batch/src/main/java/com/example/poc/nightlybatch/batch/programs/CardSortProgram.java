package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layouts;
import com.example.poc.nightlybatch.io.CobolDisplay;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.StepIo;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Step 4b — REPTSORT: {@code CBSORT02}, the DFSORT stand-in of TRANREPT.jcl:
 * {@code INCLUDE COND} on the processing date (from DATEPARM) and
 * {@code SORT FIELDS=(TRAN-CARD-NUM,A)} with the documented TRAN-ID tie-break.
 */
// COBOL: CBSORT02.cbl:66-117
final class CardSortProgram implements StepProgram {
    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        io.entry("CBSORT02");
        io.paragraph("CBSORT02", "MAIN");
        int lrecl = Layouts.TRAN.lrecl();
        List<String> parm = FixedRecordFile.readAll(run.dd(step, "DATEPARM"), Layouts.DATEPARM.lrecl());
        if (parm.isEmpty()) {
            io.display("CBSORT02: DATEPARM IS EMPTY");
            return 12;
        }
        CobolRecord dateparm = CobolRecord.of(Layouts.DATEPARM, parm.get(0));
        String start = dateparm.get("WS-START-DATE");
        String end = dateparm.get("WS-END-DATE");

        io.paragraph("CBSORT02", "SELECT-RECORDS");                         // INPUT PROCEDURE of the SORT
        List<String> input = FixedRecordFile.readAll(run.dd(step, "SORTIN"), lrecl);
        List<String> selected = new ArrayList<>();
        for (String r : input) {                                           // SELECT-RECORDS input procedure
            String procDate = r.substring(304, 314);                       // IN-REC(305:10) = TRAN-PROC-TS(1:10)
            if (procDate.compareTo(start) >= 0 && procDate.compareTo(end) <= 0) selected.add(r);   // RELEASE
        }
        selected.sort(Comparator.comparing((String r) -> r.substring(262, 278))    // SORT-CARD-NUM
                .thenComparing(r -> r.substring(0, 16)));                            // SORT-TRAN-ID (adaptation 2)
        try (FixedRecordFile.Writer out = FixedRecordFile.openOutput(run.dd(step, "SORTOUT"), lrecl)) {
            for (String r : selected) out.write(r);
        }
        io.display("CBSORT02: SELECTED ", CobolDisplay.unsigned(selected.size(), 9), " OF ",
                CobolDisplay.unsigned(input.size(), 9), " RECORDS FOR ", start, " TO ", end);
        return 0;
    }
}
