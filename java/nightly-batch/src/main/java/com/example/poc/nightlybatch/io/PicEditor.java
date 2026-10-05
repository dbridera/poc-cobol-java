package com.example.poc.nightlybatch.io;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Edited numeric pictures of the report (CVTRA07Y.cpy):
 * {@code -ZZZ,ZZZ,ZZZ.ZZ} (detail amount) and {@code +ZZZ,ZZZ,ZZZ.ZZ} (totals).
 * 15 characters: a fixed sign position followed by 14 characters of
 * zero-suppressed digits with commas and a point.
 *
 * <p>Rules taken from the golden master (fixture 03):
 * <ul>
 *   <li>sign position: {@code -} picture prints {@code -} or space; {@code +} picture prints {@code +} or {@code -};</li>
 *   <li>leading zeros and the commas inside them are suppressed to spaces;</li>
 *   <li>a value of zero prints as 15 spaces — every digit position is Z, so the
 *       whole field including the point and the sign is blanked.</li>
 * </ul>
 * The source item is {@code S9(9)V99}; MOVE into the edited field truncates to 2 decimals.
 */
public final class PicEditor {
    private PicEditor() {}

    /** {@code -ZZZ,ZZZ,ZZZ.ZZ} */
    public static String minusZzz(BigDecimal v) { return edit(v, '-'); }

    /** {@code +ZZZ,ZZZ,ZZZ.ZZ} */
    public static String plusZzz(BigDecimal v) { return edit(v, '+'); }

    private static String edit(BigDecimal value, char signPic) {
        BigDecimal t = ZonedDecimal.truncate(value, 11, 2);
        if (t.signum() == 0) return " ".repeat(15);
        BigDecimal abs = t.abs().setScale(2, RoundingMode.DOWN);
        long integerPart = abs.toBigInteger().longValueExact();
        String decimals = abs.remainder(BigDecimal.ONE).movePointRight(2).setScale(0, RoundingMode.DOWN).toPlainString();
        decimals = ("00" + decimals).substring(decimals.length());
        String intText = integerPart == 0 ? "" : String.format("%,d", integerPart);
        String body = " ".repeat(11 - intText.length()) + intText + "." + decimals;   // 14 chars
        char sign = switch (signPic) {
            case '-' -> t.signum() < 0 ? '-' : ' ';
            case '+' -> t.signum() < 0 ? '-' : '+';
            default -> throw new IllegalArgumentException("sign picture " + signPic);
        };
        return sign + body;
    }
}
