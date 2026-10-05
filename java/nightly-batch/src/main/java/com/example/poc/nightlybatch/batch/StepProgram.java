package com.example.poc.nightlybatch.batch;

import com.example.poc.nightlybatch.io.StepIo;

/**
 * One COBOL program of the job (one {@code EXEC PGM=} step). Returns the
 * step's RETURN-CODE; throws {@link AbendException} where the COBOL calls
 * {@code CEE3ABD}.
 */
// cobol-trace-exempt: interface for translated programs, not a translated paragraph
@FunctionalInterface
public interface StepProgram {
    int run(JobRun run, JobManifest.Step step, StepIo io) throws Exception;
}
