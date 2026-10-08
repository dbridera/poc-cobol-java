package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.domain.Layouts;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.StepIo;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Step 3a — COMBSORT: {@code CBSORT01}, the DFSORT stand-in of COMBTRAN.jcl:
 * {@code SORT FIELDS=(TRAN-ID,A)} over the backup + the interest transactions.
 */
// COBOL: CBSORT01.cbl:36-45
final class MergeSortProgram implements StepProgram {
    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        io.entry("CBSORT01");                                                // no paragraph labels in CBSORT01
        int lrecl = Layouts.TRAN.lrecl();
        List<String> all = new ArrayList<>(FixedRecordFile.readAll(run.dd(step, "SORTIN1"), lrecl));
        all.addAll(FixedRecordFile.readAll(run.dd(step, "SORTIN2"), lrecl));
        all.sort(Comparator.comparing(r -> r.substring(0, 16)));           // ASCENDING KEY SORT-TRAN-ID (stable)
        try (FixedRecordFile.Writer out = FixedRecordFile.openOutput(run.dd(step, "SORTOUT"), lrecl)) {
            for (String r : all) out.write(r);
        }
        io.display("CBSORT01: SORT COMPLETE");
        return 0;
    }
}
