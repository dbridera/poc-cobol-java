package com.example.poc.cciaccountconverter.service;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Mod-10 check-digit calculator. Mirror of
 * {@code 2000-CALCULA-DIGCHEQ-BANOFI} ({@code OFIBAN-ITE}, 6 digits) and
 * {@code 3000-CALCULA-DIGCHEQ-CUENTA} ({@code NUMERO-ITE}, 12 digits) in
 * [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:272-306].
 *
 * <p>Algorithm:
 * <pre>
 *   sum = 0
 *   for i in odd positions [1, 3, 5, ...]:  sum += digitSum(d[i] * 1)
 *   for i in even positions [2, 4, 6, ...]: sum += digitSum(d[i] * 2)
 *   check = ((sum / 10) * 10 + 10) - sum
 *   // ↑ then implicit PIC 9(01) truncation when result == 10 → 0
 * </pre>
 * where {@code digitSum(n)} is {@code (n/10) + (n%10)}.
 *
 * <p><b>Numeric contract</b> (per spec §5.3):
 * <ul>
 *   <li>All operands are {@code BigDecimal} scale 0 — every COBOL
 *       {@code PIC 9} field becomes {@code BigDecimal} (CLAUDE.md rule 1)
 *       even though none of these are monetary values.</li>
 *   <li>{@code sum / 10} uses {@link RoundingMode#DOWN} (integer
 *       truncation). HALF_UP here would give wrong check digits for
 *       sums whose units digit is ≥ 5.</li>
 *   <li>The final {@code .remainder(TEN)} models COBOL's PIC 9(01)
 *       truncation: when the formula yields exactly 10 (i.e.,
 *       {@code sum mod 10 == 0}), the result must be 0.</li>
 * </ul>
 */
// COBOL: BCTITSCV-RUN.cbl:272-306
@Service
public class CheckDigitCalculator {

    private static final BigDecimal TWO = BigDecimal.valueOf(2);

    /**
     * Compute the single check digit (0..9) for the given fixed-length
     * digit string. The string must contain only ASCII digits {@code '0'..'9'}.
     * Position 1 (and odd positions thereafter) is multiplied by 1; position
     * 2 (and even positions thereafter) is multiplied by 2.
     */
    // COBOL: BCTITSCV-RUN.cbl:272-283 (2000) and 285-292 (3000)
    public BigDecimal compute(String digits) {
        if (digits == null) {
            throw new IllegalArgumentException("digits must not be null");
        }
        BigDecimal sum = BigDecimal.ZERO;
        int n = digits.length();

        // Odd positions (COBOL 1-indexed: 1, 3, 5, ...), multiplier 1.
        // COBOL: BCTITSCV-RUN.cbl:292-295 (2500), 299-301 (3500)
        for (int idx = 0; idx < n; idx += 2) {
            BigDecimal d = digitAt(digits, idx);
            BigDecimal product = d.multiply(BigDecimal.ONE);
            sum = sum.add(digitSum(product));
        }

        // Even positions (COBOL 1-indexed: 2, 4, 6, ...), multiplier 2.
        // COBOL: BCTITSCV-RUN.cbl:296-298 (2550), 302-306 (3550)
        for (int idx = 1; idx < n; idx += 2) {
            BigDecimal d = digitAt(digits, idx);
            BigDecimal product = d.multiply(TWO);
            sum = sum.add(digitSum(product));
        }

        // dos = sum / 10  (integer truncation; PIC 9(02) <- 9(03))
        BigDecimal dos = sum.divide(BigDecimal.TEN, 0, RoundingMode.DOWN);
        // uno = ((dos * 10) + 10) - sum
        BigDecimal uno = dos.multiply(BigDecimal.TEN)
                            .add(BigDecimal.TEN)
                            .subtract(sum);
        // PIC 9(01) truncation: 10 → 0 (load-bearing — see spec §5.3).
        return uno.remainder(BigDecimal.TEN);
    }

    /** {@code (product / 10) + (product mod 10)} — extract tens + units. */
    private static BigDecimal digitSum(BigDecimal product) {
        BigDecimal tens  = product.divide(BigDecimal.TEN, 0, RoundingMode.DOWN);
        BigDecimal units = product.remainder(BigDecimal.TEN);
        return tens.add(units);
    }

    /** Read a single ASCII digit as a {@code BigDecimal} (scale 0). */
    private static BigDecimal digitAt(String s, int idx) {
        char c = s.charAt(idx);
        if (c < '0' || c > '9') {
            throw new IllegalArgumentException(
                "non-digit '" + c + "' at position " + idx + " in '" + s + "'");
        }
        return BigDecimal.valueOf(c - '0');
    }
}
