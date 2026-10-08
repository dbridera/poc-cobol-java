package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.io.CobolDisplay;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.KsdsTable;
import com.example.poc.nightlybatch.io.StepIo;

import java.util.List;

/**
 * {@code LOAD-<DS>} — IDCAMS REPRO stand-in: sequential file → KSDS.
 */
// COBOL: src/ksds/LOAD-ACCTFILE.cbl:34-67 (MAIN; every generated LOAD-*.cbl has the same shape)
final class KsdsLoadProgram implements StepProgram {
    private final Programs programs;
    private final String name;

    KsdsLoadProgram(Programs programs, String name) {
        this.programs = programs;
        this.name = name;
    }

    @Override
    public int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception {
        io.entry(name);
        io.paragraph(name, "MAIN");
        KsdsTable ksds = programs.table(run, step, "KSDS");
        JobManifest.Dataset ds = run.ddDataset(step, "KSDS");
        List<String> records = FixedRecordFile.readAll(run.dd(step, "SEQIN"), ds.lrecl());
        ksds.truncate();                                   // OPEN OUTPUT
        int count = 0;
        int rc = 0;
        for (String raw : records) {
            CobolRecord rec = CobolRecord.of(ksds.layout(), raw);
            if (ksds.write(rec)) {
                count++;
            } else {
                String key = raw.substring(ds.keyOffset(), ds.keyOffset() + ds.keyLength());
                io.display(name, ": DUPLICATE KEY ", key, " STATUS ", "22");
                rc = 8;
            }
        }
        io.display(name, ": LOADED ", CobolDisplay.unsigned(count, 9), " RECORDS");
        return rc;
    }
}
