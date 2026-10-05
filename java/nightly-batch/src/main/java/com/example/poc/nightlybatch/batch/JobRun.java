package com.example.poc.nightlybatch.batch;

import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Everything one JVM run of the job knows from its command line: the sandbox,
 * the run number, the injected abend (restart demo), PARM/env overrides and
 * the pinned clock. Also collects the per-step results of <em>this</em> run
 * for the job log.
 *
 * <p>Mirrors the state {@code tools/run-job.py} keeps for the COBOL side.
 */
// cobol-trace-exempt: harness state of one JVM run (mirror of tools/run-job.py), not a translated paragraph
public final class JobRun {
    private final JobManifest manifest;
    private final Path workdir;
    private final String fixture;
    private final int runNo;
    private final boolean lastRun;
    private final String abendAfter;
    private final Map<String, String> parms;
    private final Map<String, String> env;
    private final LocalDateTime clock;
    private final Map<String, String> stepResults = new LinkedHashMap<>();
    private boolean failed;

    JobRun(JobManifest manifest, Path workdir, String fixture, int runNo, boolean lastRun, String abendAfter,
           Map<String, String> parms, Map<String, String> env) {
        this.manifest = manifest;
        this.workdir = workdir;
        this.fixture = fixture;
        this.runNo = runNo;
        this.lastRun = lastRun;
        this.abendAfter = abendAfter;
        this.parms = parms;
        this.env = env;
        this.clock = parseCobCurrentDate(env.getOrDefault("COB_CURRENT_DATE", manifest.env().get("COB_CURRENT_DATE")));
    }

    public static JobRun fromOptions(JobManifest manifest, Path workdir, Map<String, String> opts) {
        Map<String, String> parms = new HashMap<>();
        Map<String, String> env = new HashMap<>();
        for (Map.Entry<String, String> e : opts.entrySet()) {
            if (e.getKey().startsWith("parm.")) parms.put(e.getKey().substring(5), e.getValue());
            if (e.getKey().startsWith("env.")) env.put(e.getKey().substring(4), e.getValue());
        }
        return new JobRun(manifest, workdir, opts.getOrDefault("fixture", "default"),
                Integer.parseInt(opts.getOrDefault("run", "1")),
                "true".equals(opts.get("last-run")),
                opts.get("abend-after"), parms, env);
    }

    /**
     * GnuCOBOL's {@code COB_CURRENT_DATE} ("2022/07/18 00:00:00.00"): the value
     * {@code FUNCTION CURRENT-DATE} returns, hundredths included (spike d).
     * Null = the real clock, which would make the golden master non-reproducible.
     */
    static LocalDateTime parseCobCurrentDate(String v) {
        if (v == null) return LocalDateTime.now();
        String s = v.trim().replace('/', '-');
        if (s.length() == 19) s = s + ".00";
        return LocalDateTime.parse(s, DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SS"));
    }

    public JobManifest manifest() { return manifest; }
    public Path workdir() { return workdir; }
    public String fixture() { return fixture; }
    public int runNo() { return runNo; }
    public boolean lastRun() { return lastRun; }
    public String abendAfter() { return abendAfter; }
    public LocalDateTime clock() { return clock; }
    public boolean isFailed() { return failed; }
    public void markFailed() { failed = true; }
    public Map<String, String> stepResults() { return stepResults; }

    /** PARM for a step: the fixture's override or the manifest value. */
    public String parm(JobManifest.Step step) {
        return parms.getOrDefault(step.name(), step.parm() == null ? "" : step.parm());
    }

    /** Sandbox path of the dataset bound to a DD name of a step (the JCL //DD). */
    public Path dd(JobManifest.Step step, String ddName) {
        String ds = step.dd().get(ddName);
        if (ds == null) throw new IllegalArgumentException("step " + step.name() + " has no DD " + ddName);
        return workdir.resolve(manifest.dataset(ds).path());
    }

    public JobManifest.Dataset ddDataset(JobManifest.Step step, String ddName) {
        return manifest.dataset(step.dd().get(ddName));
    }

    public Path stepsDir() { return workdir.resolve("out").resolve("steps"); }
    public Path runLog() { return workdir.resolve("out").resolve("run-log.txt"); }
}
