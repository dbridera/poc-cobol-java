package com.example.poc.nightlybatch.io;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** Overpunch convention of the CardDemo data under {@code -fsign=EBCDIC} (README spike a). */
class ZonedDecimalTest {

    @Test
    void decodesPositiveNegativeAndZeroOverpunch() {
        assertEquals(new BigDecimal("504.77"), ZonedDecimal.decodeSigned("0000005047G", 2));
        assertEquals(new BigDecimal("-919.00"), ZonedDecimal.decodeSigned("0000009190}", 2));
        assertEquals(new BigDecimal("0.00"), ZonedDecimal.decodeSigned("0000000000{", 2));
        assertEquals(new BigDecimal("15.00"), ZonedDecimal.decodeSigned("00150{", 2));
        assertEquals(new BigDecimal("-11.48"), ZonedDecimal.decodeSigned("0000000114Q", 2));
    }

    @Test
    void plainDigitsDecodeAsPositive() {
        assertEquals(new BigDecimal("91.90"), ZonedDecimal.decodeSigned("00000009190", 2));
    }

    @Test
    void encodesRoundTrip() {
        assertEquals("0000005047G", ZonedDecimal.encodeSigned(new BigDecimal("504.77"), 11, 2));
        assertEquals("0000009190}", ZonedDecimal.encodeSigned(new BigDecimal("-919.00"), 11, 2));
        assertEquals("0000000000{", ZonedDecimal.encodeSigned(BigDecimal.ZERO, 11, 2));
        assertEquals("0000000000J", ZonedDecimal.encodeSigned(new BigDecimal("-0.01"), 11, 2));
        assertEquals("0000000000I", ZonedDecimal.encodeSigned(new BigDecimal("0.09"), 11, 2));
        assertEquals("000000312", ZonedDecimal.encodeUnsigned(BigDecimal.valueOf(312), 9, 0));
    }

    @Test
    void storeTruncatesDecimalsTowardZeroAndDropsHighOrderDigits() {
        // ADR-11: extra decimals are cut, not rounded, in both directions
        assertEquals(new BigDecimal("0.09"), ZonedDecimal.truncate(new BigDecimal("0.09575"), 11, 2));
        assertEquals(new BigDecimal("-11.48"), ZonedDecimal.truncate(new BigDecimal("-11.4875"), 11, 2));
        // ADR-12: no ON SIZE ERROR — 9999999999.00 + 5.00 into S9(10)V99 keeps the low-order digits
        assertEquals(new BigDecimal("4.00"), ZonedDecimal.truncate(new BigDecimal("10000000004.00"), 12, 2));
        // WS-TEMP-BAL S9(09)V99 receiving a 10-digit cycle total (fixture 03, account 5)
        assertEquals(new BigDecimal("50.00"), ZonedDecimal.truncate(new BigDecimal("1000000050.00"), 11, 2));
    }
}
