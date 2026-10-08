package com.example.poc.nightlybatch.batch;

import com.example.poc.nightlybatch.batch.programs.Programs;
import com.example.poc.nightlybatch.io.CobolDisplay;
import com.example.poc.nightlybatch.io.StepIo;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.FlowBuilder;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.job.flow.Flow;
import org.springframework.batch.core.job.flow.FlowExecutionStatus;
import org.springframework.batch.core.job.flow.JobExecutionDecider;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

/**
 * Builds the Spring Batch {@link Job} from the manifest: one tasklet step per
 * manifest step, in order, with a decider after each step that fails the job
 * when the injected abend ({@code --abend-after}) names that step (ADR-14).
 *
 * <p>Semantics identical to {@code tools/run-job.py}:
 * <ul>
 *   <li>a step whose RC is outside {@code rc_ok} marks the job FAILED; later steps
 *       are NOT RUN except {@code always} steps (JCL COND analogue);</li>
 *   <li>a step that abends ({@link AbendException}) ends with RC 12 and prints the
 *       {@code CEE3ABD} stub line, exactly like the COBOL executable;</li>
 *   <li>per-step stdout goes to {@code out/steps/nn-NAME.stdout.txt}, the RC to
 *       {@code nn-NAME.rc}; the job log is written by {@link RunLogListener}.</li>
 * </ul>
 * Tasklet per program (not chunk-oriented): the COBOL programs read, modify and
 * rewrite records inside one loop, and a chunk boundary would make later records
 * see stale balances (ADR-15).
 */
@Configuration
public class NightlyJobConfig {

    @Bean
    public Job nightlyJob(JobRepository repo, PlatformTransactionManager tm, JobRun run, JobStateDao state,
                          Programs programs, RunLogListener runLog) {
        List<JobManifest.Step> steps = run.manifest().steps();
        FlowBuilder<Flow> fb = new FlowBuilder<>("nightly-flow");
        FlowBuilder.TransitionBuilder<Flow> t = null;
        for (int i = 0; i < steps.size(); i++) {
            JobManifest.Step ms = steps.get(i);
            Step s = new StepBuilder(ms.name(), repo).tasklet(tasklet(run, state, programs, ms), tm).build();
            // one decider object per position: Spring Batch keys flow states by identity
            JobExecutionDecider d = (je, se) -> ms.name().equals(run.abendAfter())
                    ? new FlowExecutionStatus("ABEND") : FlowExecutionStatus.COMPLETED;
            t = (i == 0 ? fb.start(s) : t.to(s)).next(d).on("ABEND").fail().from(d).on("*");
        }
        Flow flow = t.end().build();
        return new JobBuilder(run.manifest().job(), repo).listener(runLog).start(flow).end().build();
    }

    private Tasklet tasklet(JobRun run, JobStateDao state, Programs programs, JobManifest.Step ms) {
        return (contribution, chunkContext) -> {
            String nn = run.manifest().stepNumber(ms.name());
            if (run.isFailed() && !ms.always()) {
                run.stepResults().put(ms.name(), "NOT RUN (JOB FAILED)");
                return RepeatStatus.FINISHED;
            }
            Files.createDirectories(run.stepsDir());
            int rc;
            Path traceFile = run.manifest().trace() ? run.stepsDir().resolve(nn + "-" + ms.name() + ".trace.txt") : null;
            try (StepIo io = StepIo.open(run.stepsDir().resolve(nn + "-" + ms.name() + ".stdout.txt"), traceFile)) {
                try {
                    rc = programs.forStep(ms).run(run, ms, io);
                } catch (AbendException abend) {
                    // COBOL: CEE3ABD.cbl:23-25 — the stub's DISPLAY, then STOP RUN with RETURN-CODE 12
                    io.entry("CEE3ABD");
                    io.display("CEE3ABD: USER ABEND U", CobolDisplay.signedBinary(BigDecimal.valueOf(abend.abendCode()), 9));
                    rc = AbendException.RC;
                }
            }
            Files.writeString(run.stepsDir().resolve(nn + "-" + ms.name() + ".rc"), rc + "\n");
            state.record(ms.name(), rc, run.runNo());
            run.stepResults().put(ms.name(), "RC=" + String.format("%04d", rc));
            if (!ms.rcOk().contains(rc)) run.markFailed();
            return RepeatStatus.FINISHED;
        };
    }
}
