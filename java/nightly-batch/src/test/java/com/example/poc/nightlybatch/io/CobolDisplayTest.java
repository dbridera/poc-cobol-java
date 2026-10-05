package com.example.poc.nightlybatch.io;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** GnuCOBOL DISPLAY formats observed in the golden master (spec §7.1). */
class CobolDisplayTest {

    @Test
    void unsignedNineDigits() {
        assertEquals("000000300", CobolDisplay.unsigned(300, 9));
        assertEquals("000000000", CobolDisplay.unsigned(0, 9));
    }

    @Test
    void signedWithImpliedDecimals() {
        assertEquals("+000000020.43", CobolDisplay.signed(new BigDecimal("20.43"), 11, 2));
        assertEquals("+000001644.09", CobolDisplay.signed(new BigDecimal("1644.09"), 11, 2));
        assertEquals("-000000011.48", CobolDisplay.signed(new BigDecimal("-11.48"), 11, 2));
        assertEquals("+000000000.00", CobolDisplay.signed(BigDecimal.ZERO, 11, 2));
    }

    @Test
    void signedBinaryAbendCode() {
        assertEquals("+000000999", CobolDisplay.signedBinary(BigDecimal.valueOf(999), 9));
    }
}
