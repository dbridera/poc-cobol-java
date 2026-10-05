package com.example.poc.nightlybatch.io;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * How GnuCOBOL's {@code DISPLAY} renders numeric items (the golden master is
 * GnuCOBOL output, ADR-2):
 * <ul>
 *   <li>{@code PIC 9(9)} → 9 digits, zero-padded: {@code 000000300}</li>
 *   <li>{@code PIC S9(9)V99} → sign, 9 digits, point, decimals: {@code +000000020.43}</li>
 *   <li>{@code PIC S9(9) BINARY} → sign and 9 digits: {@code +000000999}</li>
 * </ul>
 */
public final class CobolDisplay {
    private CobolDisplay() {}

    public static String unsigned(BigDecimal v, int digits) {
        return ZonedDecimal.encodeUnsigned(v, digits, 0);
    }

    public static String unsigned(long v, int digits) {
        return unsigned(BigDecimal.valueOf(v), digits);
    }

    /** {@code S9(n)V9(scale)} display: sign + integer digits + "." + decimals (no point when scale is 0). */
    public static String signed(BigDecimal v, int digits, int scale) {
        BigDecimal t = ZonedDecimal.truncate(v, digits, scale);
        String all = ZonedDecimal.encodeUnsigned(t.abs(), digits, scale);
        String sign = t.signum() < 0 ? "-" : "+";
        if (scale == 0) return sign + all;
        return sign + all.substring(0, digits - scale) + "." + all.substring(digits - scale);
    }

    public static String signedBinary(BigDecimal v, int digits) {
        return signed(v.setScale(0, RoundingMode.DOWN), digits, 0);
    }
}
