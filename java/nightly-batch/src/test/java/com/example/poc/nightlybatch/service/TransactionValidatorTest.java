package com.example.poc.nightlybatch.service;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layouts;
import com.example.poc.nightlybatch.io.KsdsTable;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The four posting checks and their order (CBTRN02C.cbl:370-423), against an
 * in-memory H2 twin of the XREF and ACCOUNT KSDS files.
 */
class TransactionValidatorTest {
    private static final String CARD = "9680294154603697";
    private KsdsTable xref;
    private KsdsTable accounts;
    private CobolRecord xrefWs;
    private CobolRecord accountWs;

    @BeforeEach
    void setUp() {
        JdbcTemplate jdbc = new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:tv" + System.nanoTime() + ";DB_CLOSE_DELAY=-1", "sa", ""));
        xref = new KsdsTable(jdbc, "XREFFILE", new JobManifest.Dataset("ksds", 50, List.of(0, 16), List.of(List.of(25, 11)), "x.ksds", false, false, "CVACT03Y"));
        accounts = new KsdsTable(jdbc, "ACCTFILE", new JobManifest.Dataset("ksds", 300, List.of(0, 11), List.of(), "a.ksds", false, false, "CVACT01Y"));
        xref.write(CobolRecord.initialized(Layouts.XREF).set("XREF-CARD-NUM", CARD)
                .setDecimal("XREF-CUST-ID", BigDecimal.ONE).setDecimal("XREF-ACCT-ID", BigDecimal.ONE));
        accounts.write(account("1", "2020.00", "2025-05-20", "0.00", "0.00"));
        xrefWs = CobolRecord.initialized(Layouts.XREF);
        accountWs = CobolRecord.initialized(Layouts.ACCOUNT);
    }

    private static CobolRecord account(String id, String limit, String expiry, String cycCredit, String cycDebit) {
        return CobolRecord.initialized(Layouts.ACCOUNT)
                .setDecimal("ACCT-ID", new BigDecimal(id)).set("ACCT-ACTIVE-STATUS", "Y")
                .setDecimal("ACCT-CREDIT-LIMIT", new BigDecimal(limit)).set("ACCT-EXPIRAION-DATE", expiry)
                .setDecimal("ACCT-CURR-CYC-CREDIT", new BigDecimal(cycCredit)).setDecimal("ACCT-CURR-CYC-DEBIT", new BigDecimal(cycDebit));
    }

    private static CobolRecord daily(String card, String amount, String origDate) {
        return CobolRecord.initialized(Layouts.TRAN).set("TRAN-CARD-NUM", card)
                .setDecimal("TRAN-AMT", new BigDecimal(amount)).set("TRAN-ORIG-TS", origDate + " 10:00:00.000000");
    }

    private TransactionValidator.Result validate(CobolRecord daly) {
        return new TransactionValidator(xref, accounts).validate(daly, xrefWs, accountWs);
    }

    @Test
    void validTransactionPostsAndFillsWorkingStorage() {
        TransactionValidator.Result r = validate(daily(CARD, "100.00", "2022-06-10"));
        assertTrue(r.valid());
        assertEquals("00000000001", xrefWs.get("XREF-ACCT-ID"));
        assertEquals(new BigDecimal("2020.00"), accountWs.decimal("ACCT-CREDIT-LIMIT"));
    }

    @Test
    void unknownCardIs100() {
        assertEquals(100, validate(daily("9999999999999999", "1.00", "2022-06-10")).reason());
    }

    @Test
    void cardPointingToMissingAccountIs101() {
        xref.write(CobolRecord.initialized(Layouts.XREF).set("XREF-CARD-NUM", "1111222233334444")
                .setDecimal("XREF-ACCT-ID", new BigDecimal("99999999999")));
        assertEquals(101, validate(daily("1111222233334444", "1.00", "2022-06-10")).reason());
    }

    @Test
    void overLimitIs102AndExactlyAtLimitPasses() {
        assertTrue(validate(daily(CARD, "2020.00", "2022-06-10")).valid());          // ACCT-CREDIT-LIMIT >= WS-TEMP-BAL
        assertEquals(102, validate(daily(CARD, "2020.01", "2022-06-10")).reason());
    }

    @Test
    void cycleDebitStoredNegativeCountsAsGrossActivity() {
        accounts.rewrite(account("1", "1000.00", "2025-05-20", "999.77", "-880.22"));
        // 999.77 - (-880.22) + 554.22 = 2434.21 > 1000.00
        assertEquals(102, validate(daily(CARD, "554.22", "2022-06-10")).reason());
    }

    @Test
    void expiredAccountIs103AndOverridesOverLimit() {
        accounts.rewrite(account("1", "100.00", "2022-06-09", "0.00", "0.00"));
        TransactionValidator.Result r = validate(daily(CARD, "500.00", "2022-06-10"));   // over limit AND expired
        assertEquals(103, r.reason());
        assertEquals("TRANSACTION RECEIVED AFTER ACCT EXPIRATION", r.description());
    }

    @Test
    void tenDigitCycleCreditIsTruncatedIntoWsTempBal() {
        // faithful defect D6: 1000000050.00 does not fit S9(09)V99 → 50.00 → passes a 100.00 limit
        accounts.rewrite(account("1", "100.00", "2025-05-20", "1000000000.00", "0.00"));
        assertTrue(validate(daily(CARD, "50.00", "2022-06-10")).valid());
    }
}
