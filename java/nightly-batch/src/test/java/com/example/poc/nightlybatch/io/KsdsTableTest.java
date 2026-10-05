package com.example.poc.nightlybatch.io;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layouts;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/** KSDS verbs over the H2 twin: write/duplicate, read, alternate key, rewrite, key-order unload. */
class KsdsTableTest {

    private static KsdsTable table(String name, JobManifest.Dataset ds) {
        JdbcTemplate jdbc = new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:kt" + System.nanoTime() + ";DB_CLOSE_DELAY=-1", "sa", ""));
        return new KsdsTable(jdbc, name, ds);
    }

    @Test
    void writeReadRewriteAndDuplicateKey() {
        KsdsTable t = table("TCATBALF", new JobManifest.Dataset("ksds", 50, List.of(0, 17), List.of(), "t.ksds", false, false, "CVTRA01Y"));
        CobolRecord r = CobolRecord.of(Layouts.TCATBAL, "000000000010100010000011648G0000000000000000000000");
        assertTrue(t.write(r));
        assertFalse(t.write(r), "second WRITE of the same key is file status 22");
        CobolRecord back = t.read("00000000001010001").orElseThrow();
        assertEquals(r.toString(), back.toString(), "round trip is byte-exact, FILLER included");
        back.add("TRAN-CAT-BAL", new BigDecimal("1.00"));
        assertTrue(t.rewrite(back));
        assertEquals(new BigDecimal("1165.87"), t.read("00000000001010001").orElseThrow().decimal("TRAN-CAT-BAL"));
        assertTrue(t.read("00000000009010001").isEmpty(), "status 23");
    }

    @Test
    void alternateKeyAndKeyOrder() {
        KsdsTable x = table("XREFFILE", new JobManifest.Dataset("ksds", 50, List.of(0, 16), List.of(List.of(25, 11)), "x.ksds", false, false, "CVACT03Y"));
        x.write(CobolRecord.initialized(Layouts.XREF).set("XREF-CARD-NUM", "9680294154603697").setDecimal("XREF-ACCT-ID", BigDecimal.ONE));
        x.write(CobolRecord.initialized(Layouts.XREF).set("XREF-CARD-NUM", "0923877193247330").setDecimal("XREF-ACCT-ID", BigDecimal.TWO));
        assertEquals("9680294154603697", x.readByAlternateKey(0, "00000000001").orElseThrow().get("XREF-CARD-NUM"));
        List<CobolRecord> all = x.readAllInKeyOrder();
        assertEquals("0923877193247330", all.get(0).get("XREF-CARD-NUM"), "READ NEXT returns byte order of the primary key");
        x.truncate();
        assertEquals(0, x.count());
    }
}
