package com.example.poc.nightlybatch.batch;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * The Java twin of the COBOL side's {@code .jobstate} file: one row per
 * completed step with its return code and the run that executed it. Spring
 * Batch's own {@code JobRepository} decides what to skip on restart; this
 * table only carries the RC bookkeeping the job log and the exit code need.
 */
// cobol-trace-exempt: RC bookkeeping (mirror of the COBOL-side .jobstate), not a translated paragraph
@Component
public class JobStateDao {
    private final JdbcTemplate jdbc;

    public JobStateDao(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
        jdbc.execute("CREATE TABLE IF NOT EXISTS JOB_STEP_STATE ("
                + "STEP_NAME VARCHAR(40) PRIMARY KEY, RC INT NOT NULL, RUN_NO INT NOT NULL)");
    }

    public void record(String step, int rc, int runNo) {
        jdbc.update("MERGE INTO JOB_STEP_STATE (STEP_NAME, RC, RUN_NO) KEY (STEP_NAME) VALUES (?, ?, ?)", step, rc, runNo);
    }

    /** step name → [rc, runNo] for every step completed so far (any run). */
    public Map<String, int[]> completed() {
        Map<String, int[]> out = new LinkedHashMap<>();
        jdbc.query("SELECT STEP_NAME, RC, RUN_NO FROM JOB_STEP_STATE", rs -> {
            out.put(rs.getString(1), new int[]{rs.getInt(2), rs.getInt(3)});
        });
        return out;
    }

    public int maxRc() {
        Integer v = jdbc.queryForObject("SELECT COALESCE(MAX(RC), 0) FROM JOB_STEP_STATE", Integer.class);
        return v == null ? 0 : v;
    }
}
