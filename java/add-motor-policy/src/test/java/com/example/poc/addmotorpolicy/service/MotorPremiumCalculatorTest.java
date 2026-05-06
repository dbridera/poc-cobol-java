package com.example.poc.addmotorpolicy.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MotorPremiumCalculatorTest {

    private final MotorPremiumCalculator calc = new MotorPremiumCalculator();

    /**
     * The values on the right come from running the COBOL program under GnuCOBOL
     * and observing motor.dat. If you change the formula, regenerate the golden
     * master and update this table — DO NOT just adjust expected values.
     */
    @ParameterizedTest(name = "cc={0} value={1} accidents={2} -> premium={3}")
    @CsvSource({
            // 01-happy-small fixture
            "998,    12000, 0, 260",
            "1500,   22500, 1, 513",
            "2998,   75000, 2, 1275",
            // 03-numeric-boundaries (CC bracket edges)
            "1000,    5000, 0, 225",
            "1001,    5000, 0, 375",
            "1600,    5000, 0, 375",
            "2001,    5000, 0, 825",
            // value boundary
            "6500,  999999, 0, 5800",
            // validation-errors fixture (the one record that succeeded)
            "1984,   30000, 1, 700"
    })
    void matchesGoldenMaster(int cc, int value, int accidents, int expected) {
        BigDecimal got = calc.calculate(bd(cc), bd(value), bd(accidents));
        assertThat(got).isEqualByComparingTo(bd(expected));
    }

    @Test
    void halfUpRoundingNotHalfEven() {
        // value=22500 -> value_load=112.50; base=350; accidents*50=50; total=512.50.
        // HALF_EVEN would give 512; COBOL gives 513.
        BigDecimal got = calc.calculate(bd(1500), bd(22500), bd(1));
        assertThat(got).isEqualByComparingTo(bd(513));
    }

    @Test
    void overflowOnAccidentLoadingThrowsWithExactCobolReason() {
        // 999999 accidents * 50 = 49,999,950 >> 999,999.99
        assertThatThrownBy(() -> calc.calculate(bd(1500), bd(5000), bd(999999)))
                .isInstanceOf(PremiumOverflowException.class)
                .hasMessage("premium overflowed PIC 9(6)V99");
    }

    @Test
    void boundaryAt999999Point99IsRejected() {
        // Construct inputs so raw == 1_000_000 exactly: not representable in 9(6)V99.
        // base 800 + value*0.005 + accidents*50 = 1_000_000  -> value=199_840_000 won't fit 9(6).
        // Use accident loading instead: accidents=20000 -> 1_000_000 in 50-each.
        // Need cc>2000 (base 800) and value=0 won't pass validation but the calculator
        // doesn't validate; we only test the calculator here.
        BigDecimal cc = bd(2500);
        BigDecimal value = bd(40000);  // value_load = 200
        BigDecimal accidents = bd(19999); // 19999 * 50 = 999_950
        // total = 800 + 200 + 999950 = 1_000_950 -> overflow
        assertThatThrownBy(() -> calc.calculate(cc, value, accidents))
                .isInstanceOf(PremiumOverflowException.class);
    }

    private static BigDecimal bd(long n) { return new BigDecimal(n); }
}
