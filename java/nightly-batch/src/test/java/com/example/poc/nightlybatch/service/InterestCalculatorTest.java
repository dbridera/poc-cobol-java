package com.example.poc.nightlybatch.service;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** COMPUTE without ROUNDED (CBACT04C.cbl:464-465): truncation toward zero at the cent. */
class InterestCalculatorTest {

    private static BigDecimal interest(String balance, String rate) {
        return InterestCalculator.monthlyInterest(new BigDecimal(balance), new BigDecimal(rate));
    }

    @Test
    void truncatesPositiveQuotient() {
        assertEquals(new BigDecimal("0.09"), interest("7.66", "15.00"));     // 0.09575 — HALF_UP would give 0.10
        assertEquals(new BigDecimal("0.06"), interest("5.00", "15.00"));     // 0.0625
        assertEquals(new BigDecimal("0.62"), interest("50.00", "15.00"));    // 0.625  — HALF_UP would give 0.63
        assertEquals(new BigDecimal("14.56"), interest("1164.80", "15.00")); // fixture 01, account 1
    }

    @Test
    void truncatesNegativeQuotientTowardZeroNotFloor() {
        assertEquals(new BigDecimal("-11.48"), interest("-919.00", "15.00")); // -11.4875 — FLOOR would give -11.49
    }

    @Test
    void zeroBalanceGivesZeroInterest() {
        assertEquals(new BigDecimal("0.00"), interest("0.00", "25.00"));
    }

    @Test
    void db2TimestampFromPinnedClock() {
        assertEquals("2022-07-18-00.00.00.000000", CobolTimestamp.db2Format(LocalDateTime.of(2022, 7, 18, 0, 0)));
        assertEquals("2026-10-04-23.01.14.870000",
                CobolTimestamp.db2Format(LocalDateTime.of(2026, 10, 4, 23, 1, 14, 870_000_000)));
    }
}
