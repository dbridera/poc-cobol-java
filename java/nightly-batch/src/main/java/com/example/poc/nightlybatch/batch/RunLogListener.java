package com.example.poc.nightlybatch.batch;

import org.springframework.batch.core.JobExecution;
import org.springframework.batch.core.JobExecutionListener;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.Map;

/**
 * Writes {@code out/run-log.txt} in exactly the format of the COBOL-side driver
 * ({@code tools/run-job.py}), so the log itself is part of the byte-exact diff:
 * <pre>
 * JOB NIGHTLY RUN 1
 * STEP 07 POSTTRAN RC=0004
 * ABEND AFTER INTCALC (injected)
 * JOB NIGHTLY RUN 2
 * STEP 01 LOAD-ACCTFILE SKIPPED (COMPLETED IN RUN 1)
 * ...
 * JOB NIGHTLY END MAXRC=0004
 * </pre>
 * Steps skipped on restart are the ones Spring Batch's JobRepository already
 * holds as COMPLETED; their RC and run number come from {@link JobStateDao}.
 */
// cobol-trace-exempt: job log writer (mirror of tools/run-job.py), not a translated paragraph
@Component
public class RunLogListener implements JobExecutionListener {
    private final JobRun run;
    private final JobStateDao state;

    public RunLogListener(JobRun run, JobStateDao state) {
        this.run = run;
        this.state = state;
    }

    @Override
    public void afterJob(JobExecution jobExecution) {
        StringBuilder sb = new StringBuilder();
        sb.append("JOB ").append(run.manifest().job()).append(" RUN ").append(run.runNo()).append('\n');
        Map<String, int[]> done = state.completed();
        for (JobManifest.Step s : run.manifest().steps()) {
            String tag = "STEP " + run.manifest().stepNumber(s.name()) + " " + s.name();
            String result = run.stepResults().get(s.name());
            if (result != null) {
                sb.append(tag).append(' ').append(result).append('\n');
            } else if (done.containsKey(s.name())) {
                sb.append(tag).append(" SKIPPED (COMPLETED IN RUN ").append(done.get(s.name())[1]).append(")\n");
            }
            // else: not reached in this run (after an injected abend) — nothing, like the bash side
        }
        if (run.abendAfter() != null && jobExecution.getStatus().isUnsuccessful()) {
            sb.append("ABEND AFTER ").append(run.abendAfter()).append(" (injected)\n");
        }
        if (run.lastRun()) {
            sb.append("JOB ").append(run.manifest().job()).append(" END MAXRC=")
              .append(String.format("%04d", state.maxRc())).append('\n');
        }
        try {
            Files.createDirectories(run.runLog().getParent());
            Files.writeString(run.runLog(), sb.toString(), StandardCharsets.ISO_8859_1,
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
