package com.example.poc.nightlybatch.batch.programs;

import com.example.poc.nightlybatch.batch.AbendException;
import com.example.poc.nightlybatch.io.StepIo;

/**
 * The two error paragraphs every CardDemo batch program shares.
 */
final class CobolRuntime {
    private CobolRuntime() {}

    /**
     * {@code 9910-DISPLAY-IO-STATUS}: a numeric two-character file status is shown
     * as {@code FILE STATUS IS: NNNN00xx} (the non-numeric branch is for status 9x,
     * never produced here).
     */
    // COBOL: CBTRN02C.cbl:714-727, CBACT04C.cbl:635-648, CBTRN03C.cbl:633-646
    static void displayIoStatus(StepIo io, String status) {
        io.display("FILE STATUS IS: NNNN", "00" + status);
    }

    /** {@code 9999-ABEND-PROGRAM}: display, then {@code CALL 'CEE3ABD'} with code 999. */
    // COBOL: CBTRN02C.cbl:707-712, CBACT04C.cbl:628-633, CBTRN03C.cbl:626-631
    static AbendException abend(StepIo io) {
        io.display("ABENDING PROGRAM");
        return new AbendException(999);
    }
}
