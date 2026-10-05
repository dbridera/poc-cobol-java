package com.example.poc.nightlybatch.batch;

/**
 * The Java equivalent of {@code CALL 'CEE3ABD' USING ABCODE TIMING}: the step
 * stops where it is and ends with the abend return code.
 *
 * // COBOL: CEE3ABD.cbl:17-25 (stub) — user abend U0999, RC 12
 */
public class AbendException extends RuntimeException {
    public static final int RC = 12;
    private final int abendCode;

    public AbendException(int abendCode) {
        super("user abend U" + abendCode);
        this.abendCode = abendCode;
    }

    public int abendCode() { return abendCode; }
}
