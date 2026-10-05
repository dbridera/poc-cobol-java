package com.example.poc.nightlybatch.service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * {@code Z-GET-DB2-FORMAT-TIMESTAMP}: {@code FUNCTION CURRENT-DATE}
 * ({@code YYYYMMDDhhmmsshh…}) rearranged into the DB2 timestamp shape
 * {@code YYYY-MM-DD-hh.mm.ss.hh0000}. The hundredths come from the clock; the
 * last four digits are the literal {@code '0000'}.
 */
public final class CobolTimestamp {
    private static final DateTimeFormatter DB2 = DateTimeFormatter.ofPattern("yyyy-MM-dd-HH.mm.ss.SS");

    private CobolTimestamp() {}

    // COBOL: CBTRN02C.cbl:692-706, CBACT04C.cbl:613-627
    public static String db2Format(LocalDateTime now) {
        return now.format(DB2) + "0000";
    }
}
