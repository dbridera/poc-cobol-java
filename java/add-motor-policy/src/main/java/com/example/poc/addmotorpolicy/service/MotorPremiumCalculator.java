package com.example.poc.addmotorpolicy.service;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Mirror of CALC-MOTOR-PREMIUM in ADDMPOL.cbl:232-264.
 *
 * <p>premium = base(cc) + 0.005·value + 50·accidents
 * <p>Rounded HALF_UP to whole currency to fit MOUT-PREMIUM PIC 9(6).
 *
 * <p>Hard rules from the methodology:
 * <ul>
 *   <li>All arithmetic is {@link BigDecimal}. NEVER use {@code double}/{@code float}.</li>
 *   <li>Rounding mode is HALF_UP — verified empirically against the COBOL run
 *       (record 2 of 01-happy-small: 512.50 → 513).</li>
 *   <li>Overflow of premium ≥ 1,000,000.00 throws {@link PremiumOverflowException}
 *       with the EXACT reason string "premium overflowed PIC 9(6)V99" so RC=11
 *       reporting matches COBOL.</li>
 * </ul>
 */
@Component
public class MotorPremiumCalculator {

    static final BigDecimal BASE_LE_1000 = new BigDecimal("200.00");
    static final BigDecimal BASE_LE_1600 = new BigDecimal("350.00");
    static final BigDecimal BASE_LE_2000 = new BigDecimal("500.00");
    static final BigDecimal BASE_GT_2000 = new BigDecimal("800.00");

    static final BigDecimal CC_BREAK_1 = new BigDecimal("1000");
    static final BigDecimal CC_BREAK_2 = new BigDecimal("1600");
    static final BigDecimal CC_BREAK_3 = new BigDecimal("2000");

    static final BigDecimal VALUE_RATE       = new BigDecimal("0.005");
    static final BigDecimal ACCIDENT_LOAD    = new BigDecimal("50");

    /** PIC 9(6)V99 cap: max representable value is 999999.99 (i.e. < 1_000_000). */
    static final BigDecimal PREMIUM_RAW_CAP   = new BigDecimal("1000000");

    /** PIC 9(6) cap for the final integer premium: max representable is 999999. */
    static final BigDecimal PREMIUM_INT_CAP   = new BigDecimal("1000000");

    /**
     * @return premium as a whole-currency BigDecimal (scale 0) suitable for MOUT-PREMIUM.
     * @throws PremiumOverflowException with reason matching the COBOL EM-REASON text.
     */
    public BigDecimal calculate(BigDecimal cc, BigDecimal value, BigDecimal accidents) {
        BigDecimal base = baseFor(cc);
        BigDecimal valueLoad = value.multiply(VALUE_RATE);                  // scale up to 3
        BigDecimal accidentLoad = accidents.multiply(ACCIDENT_LOAD);        // scale 0
        BigDecimal raw = base.add(valueLoad).add(accidentLoad);             // scale up to 3

        // COBOL: ON SIZE ERROR on the COMPUTE that produces WS-CALC-PREMIUM PIC 9(6)V99
        // "Overflow" means the value cannot be stored in 9(6)V99, i.e. >= 1_000_000.
        if (raw.compareTo(PREMIUM_RAW_CAP) >= 0) {
            throw new PremiumOverflowException("premium overflowed PIC 9(6)V99");
        }

        // COBOL: COMPUTE WS-CALC-PREMIUM-INT ROUNDED = WS-CALC-PREMIUM (HALF_UP)
        BigDecimal rounded = raw.setScale(0, RoundingMode.HALF_UP);

        if (rounded.compareTo(PREMIUM_INT_CAP) >= 0) {
            throw new PremiumOverflowException("premium overflow on round");
        }

        return rounded;
    }

    /** EVALUATE TRUE branches in the COBOL CALC-MOTOR-PREMIUM paragraph. */
    BigDecimal baseFor(BigDecimal cc) {
        if (cc.compareTo(CC_BREAK_1) <= 0) return BASE_LE_1000;
        if (cc.compareTo(CC_BREAK_2) <= 0) return BASE_LE_1600;
        if (cc.compareTo(CC_BREAK_3) <= 0) return BASE_LE_2000;
        return BASE_GT_2000;
    }
}
