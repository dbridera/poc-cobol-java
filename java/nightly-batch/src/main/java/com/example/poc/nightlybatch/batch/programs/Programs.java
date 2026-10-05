package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.batch.JobRun;
import com.example.poc.nightlybatch.batch.StepProgram;
import com.example.poc.nightlybatch.io.KsdsTable;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * Resolves a manifest step's {@code exec} name to the Java program that
 * translates it, and hands out the KSDS tables (one per manifest dataset,
 * created on first use — the IDCAMS DEFINE CLUSTER analogue).
 */
// cobol-trace-exempt: step → program resolver and table registry (IDCAMS DEFINE analogue), not a translated paragraph
@Component
public class Programs {
    private final JdbcTemplate jdbc;
    private final Map<String, KsdsTable> tables = new HashMap<>();

    public Programs(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public StepProgram forStep(JobManifest.Step step) {
        String exec = step.exec();
        if (exec.startsWith("LOAD-")) return new KsdsLoadProgram(this, exec);
        if (exec.startsWith("UNLD-")) return new KsdsUnloadProgram(this, exec);
        return switch (exec) {
            case "CBTRN02C" -> new PostTranProgram(this);
            case "INTCALC" -> new IntCalcProgram(this);
            case "CBSORT01" -> new MergeSortProgram();
            case "CBSORT02" -> new CardSortProgram();
            case "CBTRN03C" -> new TranReptProgram(this);
            default -> throw new IllegalArgumentException("no Java program for exec " + exec);
        };
    }

    /** The table behind the dataset bound to a DD name of a step. */
    public KsdsTable table(JobRun run, JobManifest.Step step, String ddName) {
        String dsName = step.dd().get(ddName);
        if (dsName == null) throw new IllegalArgumentException("step " + step.name() + " has no DD " + ddName);
        return tables.computeIfAbsent(dsName, n -> new KsdsTable(jdbc, n, run.manifest().dataset(n)));
    }
}
