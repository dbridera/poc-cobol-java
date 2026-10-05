package com.example.poc.nightlybatch.io;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** Edited pictures of CVTRA07Y, values taken from the golden master of fixtures 03 and 04. */
class PicEditorTest {

    @Test
    void detailAmountHasFixedSignPositionAndZeroSuppression() {
        assertEquals("         183.88", PicEditor.minusZzz(new BigDecimal("183.88")));
        assertEquals("-         47.88", PicEditor.minusZzz(new BigDecimal("-47.88")));
        assertEquals("-        919.00", PicEditor.minusZzz(new BigDecimal("-919.00")));
        assertEquals("       1,664.52", PicEditor.minusZzz(new BigDecimal("1664.52")));
    }

    @Test
    void zeroPrintsAsAllSpacesBecauseEveryDigitPositionIsZ() {
        assertEquals(" ".repeat(15), PicEditor.minusZzz(BigDecimal.ZERO));
        assertEquals(" ".repeat(15), PicEditor.minusZzz(new BigDecimal("0.00")));
    }

    @Test
    void totalsShowExplicitSign() {
        assertEquals("+      1,664.52", PicEditor.plusZzz(new BigDecimal("1664.52")));
        assertEquals("-        930.48", PicEditor.plusZzz(new BigDecimal("-930.48")));
        assertEquals("+     79,254.29", PicEditor.plusZzz(new BigDecimal("79254.29")));
        assertEquals("+          5.06", PicEditor.plusZzz(new BigDecimal("5.06")));
    }

    @Test
    void moveIntoEditedFieldTruncatesExtraDecimalsAndSuppressesZeroIntegerPart() {
        // interest of 0.09 in fixture 03: every integer position is Z, so only ".09" survives
        assertEquals("            .09", PicEditor.minusZzz(new BigDecimal("0.0999")));
    }
}
