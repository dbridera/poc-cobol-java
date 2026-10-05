package com.example.poc.nightlybatch.io;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.RoundingMode;

/**
 * Zoned-decimal {@code PIC 9…V9…} / {@code PIC S9…V9…} (USAGE DISPLAY) with the
 * EBCDIC overpunched trailing sign as it appears after EBCDIC→ASCII conversion
 * (GnuCOBOL {@code -fsign=EBCDIC}): {@code 0000005047G} = +504.77,
 * {@code 0000009190}} = −919.00, {@code 0000000000{} = 0.00.
 *
 * <p>Storing a value applies COBOL's MOVE/ADD semantics without
 * {@code ON SIZE ERROR}: extra decimals are truncated (toward zero, ADR-11) and
 * extra high-order digits are dropped (ADR-12), so {@code 9999999999.00 + 5.00}
 * stored into {@code S9(10)V99} becomes {@code 0000000004.00}.
 */
public final class ZonedDecimal {
    private static final String POS = "{ABCDEFGHI";
    private static final String NEG = "}JKLMNOPQR";

    private ZonedDecimal() {}

    public static BigDecimal decodeSigned(String raw, int scale) {
        int n = raw.length();
        char last = raw.charAt(n - 1);
        int digit;
        boolean negative;
        int p = POS.indexOf(last);
        int q = NEG.indexOf(last);
        if (p >= 0) { digit = p; negative = false; }
        else if (q >= 0) { digit = q; negative = true; }
        else if (Character.isDigit(last)) { digit = last - '0'; negative = false; }
        else throw new IllegalArgumentException("bad overpunch sign in " + raw);
        BigInteger unscaled = new BigInteger(digitsOrZero(raw.substring(0, n - 1)) + digit);
        BigDecimal v = new BigDecimal(unscaled, scale);
        return negative ? v.negate() : v;
    }

    public static BigDecimal decodeUnsigned(String raw, int scale) {
        return new BigDecimal(new BigInteger(digitsOrZero(raw)), scale);
    }

    public static String encodeSigned(BigDecimal value, int digits, int scale) {
        BigDecimal t = truncate(value, digits, scale);
        String d = unscaledDigits(t, digits);
        int last = d.charAt(digits - 1) - '0';
        char sign = t.signum() < 0 ? NEG.charAt(last) : POS.charAt(last);
        return d.substring(0, digits - 1) + sign;
    }

    public static String encodeUnsigned(BigDecimal value, int digits, int scale) {
        return unscaledDigits(truncate(value, digits, scale), digits);
    }

    /** COBOL store semantics: scale truncation toward zero, then low-order digit retention. */
    public static BigDecimal truncate(BigDecimal value, int digits, int scale) {
        BigDecimal scaled = value.setScale(scale, RoundingMode.DOWN);
        BigInteger modulus = BigInteger.TEN.pow(digits);
        BigInteger kept = scaled.unscaledValue().abs().mod(modulus);
        BigDecimal result = new BigDecimal(kept, scale);
        return scaled.signum() < 0 ? result.negate() : result;
    }

    private static String unscaledDigits(BigDecimal truncated, int digits) {
        String s = truncated.unscaledValue().abs().toString();
        return "0".repeat(Math.max(0, digits - s.length())) + s;
    }

    private static String digitsOrZero(String s) {
        String t = s.replace(' ', '0');
        return t.isEmpty() ? "0" : t;
    }
}
