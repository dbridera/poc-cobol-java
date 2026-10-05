package com.example.poc.nightlybatch.batch;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

/**
 * The job manifest {@code cobol/nightly-batch/job.json} — the JCL analogue shared
 * with the COBOL side (read there by {@code tools/jobman.py}).
 *
 * <p>Datasets are named files inside the sandbox; steps map DD names to
 * datasets and name the program to execute. Only the fields the Java side needs
 * are modelled; everything else is ignored.
 */
// cobol-trace-exempt: manifest model of cobol/nightly-batch/job.json (the JCL analogue), not a translated paragraph
@JsonIgnoreProperties(ignoreUnknown = true)
public record JobManifest(String job, Map<String, String> env, Map<String, Dataset> datasets, List<Step> steps) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Dataset(String org, int lrecl, List<Integer> key, List<List<Integer>> alt_keys, String path,
                          boolean input, boolean capture, String copybook) {
        public boolean isKsds() { return "ksds".equals(org); }
        public int keyOffset() { return key.get(0); }
        public int keyLength() { return key.get(1); }
        public List<List<Integer>> altKeys() { return alt_keys == null ? List.of() : alt_keys; }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Step(String name, String group, String exec, Map<String, String> dd, List<Integer> rc_ok,
                       boolean always, String parm) {
        public List<Integer> rcOk() { return rc_ok == null || rc_ok.isEmpty() ? List.of(0) : rc_ok; }
    }

    public static JobManifest load(Path path) throws IOException {
        return new ObjectMapper().readValue(path.toFile(), JobManifest.class);
    }

    public Map<String, String> env() { return env == null ? Map.of() : env; }

    public Dataset dataset(String name) {
        Dataset d = datasets.get(name);
        if (d == null) throw new IllegalArgumentException("unknown dataset " + name);
        return d;
    }

    /** 1-based position of a step, zero-padded to two digits ("07"). */
    public String stepNumber(String stepName) {
        for (int i = 0; i < steps.size(); i++) {
            if (steps.get(i).name().equals(stepName)) return String.format("%02d", i + 1);
        }
        throw new IllegalArgumentException("unknown step " + stepName);
    }
}
