package com.example.poc.nightlybatch.domain;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** Group-item semantics the translation relies on (spike j in the README log). */
class CobolRecordTest {

    @Test
    void initializeLeavesFillerUntouched() {
        // a category-balance row read from the seed data carries zero-filled FILLER
        CobolRecord ws = CobolRecord.of(Layouts.TCATBAL, "000000000010100010000011648G0000000000000000000000");
        ws.initialize();
        assertEquals("00000000000" + "  " + "0000" + "0000000000{" + "0000000000000000000000", ws.toString());
    }

    @Test
    void freshWorkingStorageIsSpacesAndZeros() {
        CobolRecord ws = CobolRecord.initialized(Layouts.TCATBAL);
        assertEquals("00000000000" + "  " + "0000" + "0000000000{" + " ".repeat(22), ws.toString());
    }

    @Test
    void addWithoutSizeErrorWrapsHighOrderDigits() {
        CobolRecord acct = CobolRecord.initialized(Layouts.ACCOUNT);
        acct.setDecimal("ACCT-CURR-BAL", new BigDecimal("9999999999.00"));
        acct.add("ACCT-CURR-BAL", new BigDecimal("5.00"));
        assertEquals(new BigDecimal("4.00"), acct.decimal("ACCT-CURR-BAL"));      // fixture 03, account 4
    }

    @Test
    void moveTextTruncatesAndPads() {
        CobolRecord tran = CobolRecord.initialized(Layouts.TRAN);
        tran.set("TRAN-TYPE-CD", "01234");
        assertEquals("01", tran.get("TRAN-TYPE-CD"));
        tran.set("TRAN-SOURCE", "System");
        assertEquals("System    ", tran.get("TRAN-SOURCE"));
        tran.setDecimal("TRAN-CAT-CD", new BigDecimal("05"));
        assertEquals("0005", tran.get("TRAN-CAT-CD"));
    }

    @Test
    void referenceModificationIsOneBased() {
        CobolRecord tran = CobolRecord.initialized(Layouts.TRAN);
        tran.set("TRAN-ORIG-TS", "2022-06-10 19:27:53.000000");
        assertEquals("2022-06-10", tran.substring("TRAN-ORIG-TS", 1, 10));
    }
}
