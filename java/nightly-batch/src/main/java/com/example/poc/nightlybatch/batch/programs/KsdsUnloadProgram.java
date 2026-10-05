package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.io.CobolDisplay;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.StepIo;

/**
 * {@code UNLD-<DS>} — IDCAMS REPRO stand-in: KSDS → sequential file, key order.
 */
// COBOL: src/ksds/UNLD-ACCTFILE.cbl:33-59 (MAIN; every generated UNLD-*.cbl has the same shape)
final class KsdsUnloadProgram implements StepProgram {
    private final Programs programs;
    private final String name;

    KsdsUnloadProgram(Programs programs, String name) {
        this.programs = programs;
        this.name = name;
    }

    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        KsdsTable ksds = programs.table(run, step, "KSDS");
        JobManifest.Dataset ds = run.ddDataset(step, "KSDS");
        int count;
        try (FixedRecordFile.Writer out = FixedRecordFile.openOutput(run.dd(step, "SEQOUT"), ds.lrecl())) {
            for (CobolRecord rec : ksds.readAllInKeyOrder()) out.write(rec.toString());
            count = out.count();
        }
        io.display(name, ": UNLOADED ", CobolDisplay.unsigned(count, 9), " RECORDS");
        return 0;
    }
}
