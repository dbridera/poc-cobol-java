package com.example.poc.cciaccountconverter.service;

import com.example.poc.cciaccountconverter.domain.Commarea;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BctitscvValidatorTest {

    private final BctitscvValidator validator = new BctitscvValidator();

    private static Commarea valid() {
        // Fixture-01-style input: IMPACS family, 20-byte CCI numeric throughout.
        Commarea c = new Commarea();
        c.setIndConv("1");
        c.setCodIntfz("IBNK");
        c.setBscCodFam("004");
        c.setBscCodPro("001");
        c.setBscCodSpr("000");
        c.setCodCtaCci("00221501234567811234");
        // BCTITSCV's 0500 line 106 copies COD-CTA-CCI into BCP-EDIT-IM
        // before validation; replicate here so the per-family numeric
        // check sees a populated BCP-EDIT-IM view.
        c.setBcpEditIm("00221501234567811234");
        return c;
    }

    @Test
    void all_rules_pass_sets_rc_00() {
        Commarea c = valid();
        boolean failed = validator.validate(c);
        assertFalse(failed);
        assertEquals("00", c.getCodReturn());
    }

    @Test
    void rule_1_invalid_family() {
        Commarea c = valid();
        c.setBscCodFam("999");
        assertTrue(validator.validate(c));
        assertEquals("99", c.getCodReturn());
        assertEquals(BctitscvValidator.MSG_COD_SIST_INVALID, c.getMsgReturn().stripTrailing());
    }

    @Test
    void rule_2_non_numeric_product() {
        Commarea c = valid();
        c.setBscCodPro("ABC");
        assertTrue(validator.validate(c));
        assertEquals("99", c.getCodReturn());
        assertEquals(BctitscvValidator.MSG_ACCT_TYPE_NUMERIC, c.getMsgReturn().stripTrailing());
    }

    @Test
    void rule_3_im_branch_non_numeric_bcp_edit() {
        Commarea c = valid();
        // Wipe the BCP-EDIT-IM bytes 8-20 with non-digits so the IM
        // numeric check trips.
        c.setBcpEditIm("0000000XX2345678112");
        assertTrue(validator.validate(c));
        assertEquals("99", c.getCodReturn());
        // Message has a verbatim trailing space — that's the COBOL literal.
        assertEquals(BctitscvValidator.MSG_DATOS_NO_NUMERICOS, c.getMsgReturn().substring(0, 19));
    }

    @Test
    void rule_3_st_branch_non_numeric_bcp_edit() {
        Commarea c = valid();
        c.setBscCodFam("005"); // SAVING → ST branch
        c.setBcpEditIm("000000XX12345678112");
        assertTrue(validator.validate(c));
        assertEquals("99", c.getCodReturn());
    }

    @Test
    void short_circuit_first_rule_wins() {
        Commarea c = valid();
        c.setBscCodFam("999");  // rule 1 fails
        c.setBscCodPro("ABC");  // rule 2 would also fail
        validator.validate(c);
        // Should report rule 1, not rule 2.
        assertEquals(BctitscvValidator.MSG_COD_SIST_INVALID, c.getMsgReturn().stripTrailing());
    }
}
