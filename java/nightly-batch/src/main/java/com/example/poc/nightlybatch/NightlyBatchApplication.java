package com.example.poc.nightlybatch;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.JobStateDao;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.JobExecution;
import org.springframework.batch.core.JobParameters;
import org.springframework.batch.core.JobParametersBuilder;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/**
 * Entry point of the nightly-batch job (module 3).
 *
 * <p>Invoked once per <em>run</em> by {@code tools/run-job.py --side java}:
 * <pre>
 *   java -jar nightly-batch.jar --manifest=&lt;cobol/nightly-batch/job.json&gt; --workdir=&lt;sandbox&gt;
 *        --fixture=&lt;name&gt; --run=&lt;n&gt; [--last-run=true] [--abend-after=STEP] [--parm.STEP=v] [--env.VAR=v]
 * </pre>
 * The manifest is the JCL analogue: the same file drives the COBOL side, so step
 * order, DD→dataset mapping, return-code rules and capture rules cannot drift.
 * The exit code is MAXRC over every step executed in the job instance, exactly
 * like the bash-side driver (ADR-14).
 */
@SpringBootApplication
public class NightlyBatchApplication {

    public static void main(String[] args) throws Exception {
        Map<String, String> opts = parse(args);
        Path manifestPath = Path.of(require(opts, "manifest"));
        Path workdir = Path.of(require(opts, "workdir")).toAbsolutePath();
        JobManifest manifest = JobManifest.load(manifestPath);
        JobRun run = JobRun.fromOptions(manifest, workdir, opts);

        ConfigurableApplicationContext ctx = new SpringApplicationBuilder(NightlyBatchApplication.class)
                .properties("spring.datasource.url=jdbc:h2:file:" + workdir.resolve(".nightly-batch") + ";DB_CLOSE_ON_EXIT=TRUE")
                .initializers(c -> c.getBeanFactory().registerSingleton("jobRun", run))
                .run(args);

        int maxRc;
        try {
            JobParameters params = new JobParametersBuilder()
                    .addString("job", manifest.job())
                    .addString("fixture", run.fixture())
                    .toJobParameters();
            JobExecution exec = ctx.getBean(JobLauncher.class).run(ctx.getBean(Job.class), params);
            if (exec.getStatus().isUnsuccessful() && run.abendAfter() == null) {
                // a genuine Spring Batch failure (not the injected abend) must never pass silently
                System.err.println("job ended with status " + exec.getStatus() + ": " + exec.getAllFailureExceptions());
            }
            maxRc = ctx.getBean(JobStateDao.class).maxRc();
        } finally {
            ctx.close();
        }
        System.exit(maxRc);
    }

    static Map<String, String> parse(String[] args) {
        Map<String, String> m = new HashMap<>();
        for (String a : args) {
            if (!a.startsWith("--")) continue;
            int eq = a.indexOf('=');
            if (eq < 0) m.put(a.substring(2), "true");
            else m.put(a.substring(2, eq), a.substring(eq + 1));
        }
        return m;
    }

    private static String require(Map<String, String> opts, String key) {
        String v = opts.get(key);
        if (v == null || v.isBlank()) throw new IllegalArgumentException("missing --" + key + "=...");
        return v;
    }
}
