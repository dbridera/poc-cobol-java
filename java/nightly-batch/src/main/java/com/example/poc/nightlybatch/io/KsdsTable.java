package com.example.poc.nightlybatch.io;

import com.example.poc.nightlybatch.batch.JobManifest;
import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.domain.Layout;
import com.example.poc.nightlybatch.domain.Layouts;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * A VSAM KSDS as a relational table (CLAUDE.md mapping: KSDS → table with the
 * record key as primary key; an alternate index → a secondary index).
 *
 * <p>Columns are the copybook fields: alphanumerics and unsigned numerics as
 * {@code VARCHAR} (exact bytes, zero/space padding preserved so {@code ORDER BY}
 * reproduces VSAM key order), signed amounts as {@code DECIMAL(p,s)}. FILLER
 * bytes get their own columns so a record round-trips byte for byte.
 *
 * <p>The COBOL file verbs map to:
 * <ul>
 *   <li>{@code OPEN OUTPUT} → {@link #truncate()} ({@code DELETE} + create)</li>
 *   <li>{@code WRITE} → {@code INSERT}; a duplicate primary key is file status 22</li>
 *   <li>{@code READ key} → {@code SELECT … WHERE pk = ?}; not found is status 23</li>
 *   <li>{@code READ … KEY IS alt} → {@code SELECT … WHERE alt = ? ORDER BY pk} (first row)</li>
 *   <li>{@code REWRITE} → {@code UPDATE … WHERE pk = ?}</li>
 *   <li>{@code READ NEXT} (sequential access) → {@code SELECT … ORDER BY pk}</li>
 * </ul>
 * JDBC rather than JPA on purpose (ADR-13): the programs read-modify-rewrite one
 * record at a time and must see every write immediately, with no identity map
 * and no deferred flush between them.
 */
public final class KsdsTable {
    private final JdbcTemplate jdbc;
    private final String table;
    private final Layout layout;
    private final List<Layout.Field> keyFields;
    private final List<List<Layout.Field>> altKeys = new ArrayList<>();
    private final RowMapper<CobolRecord> mapper;

    public KsdsTable(JdbcTemplate jdbc, String datasetName, JobManifest.Dataset ds) {
        this(jdbc, datasetName, Layouts.forCopybook(ds.copybook()), ds);
    }

    public KsdsTable(JdbcTemplate jdbc, String datasetName, Layout layout, JobManifest.Dataset ds) {
        if (!ds.isKsds()) throw new IllegalArgumentException(datasetName + " is not a KSDS");
        this.jdbc = jdbc;
        this.table = datasetName.replace('-', '_');
        this.layout = layout;
        this.keyFields = layout.fieldsCovering(ds.keyOffset(), ds.keyLength());
        for (List<Integer> ak : ds.altKeys()) altKeys.add(layout.fieldsCovering(ak.get(0), ak.get(1)));
        this.mapper = (rs, n) -> fromRow(rs);
        createIfAbsent();
    }

    public Layout layout() { return layout; }

    // ---------------------------------------------------------------- DDL

    private void createIfAbsent() {
        String cols = layout.fields().stream().map(f -> col(f) + " " + sqlType(f) + " NOT NULL")
                .collect(Collectors.joining(", "));
        String pk = keyFields.stream().map(KsdsTable::col).collect(Collectors.joining(", "));
        jdbc.execute("CREATE TABLE IF NOT EXISTS " + table + " (" + cols + ", PRIMARY KEY (" + pk + "))");
        for (int i = 0; i < altKeys.size(); i++) {
            String ix = altKeys.get(i).stream().map(KsdsTable::col).collect(Collectors.joining(", "));
            jdbc.execute("CREATE INDEX IF NOT EXISTS " + table + "_AIX" + (i + 1) + " ON " + table + " (" + ix + ")");
        }
    }

    /** {@code OPEN OUTPUT}: the file is recreated empty. */
    public void truncate() {
        jdbc.execute("TRUNCATE TABLE " + table);
    }

    private static String col(Layout.Field f) { return f.name().replace('-', '_'); }

    private static String sqlType(Layout.Field f) {
        return switch (f.kind()) {
            case X, N -> "VARCHAR(" + f.length() + ")";
            case S -> "DECIMAL(" + f.length() + "," + f.scale() + ")";
        };
    }

    // ---------------------------------------------------------------- verbs

    /** {@code WRITE}: false = status 22 (duplicate key). */
    public boolean write(CobolRecord rec) {
        String names = layout.fields().stream().map(KsdsTable::col).collect(Collectors.joining(", "));
        String marks = layout.fields().stream().map(f -> "?").collect(Collectors.joining(", "));
        try {
            jdbc.update("INSERT INTO " + table + " (" + names + ") VALUES (" + marks + ")", params(rec, layout.fields()));
            return true;
        } catch (DuplicateKeyException e) {
            return false;
        }
    }

    /** {@code READ file} with the record key set: empty = status 23. */
    public Optional<CobolRecord> read(String key) {
        return jdbc.query("SELECT * FROM " + table + " WHERE " + where(keyFields), mapper, keyParams(keyFields, key))
                .stream().findFirst();
    }

    /** {@code READ file KEY IS alternate-key}: first record in that key's sequence. */
    public Optional<CobolRecord> readByAlternateKey(int altIndex, String key) {
        List<Layout.Field> ak = altKeys.get(altIndex);
        String sql = "SELECT * FROM " + table + " WHERE " + where(ak) + " ORDER BY " + orderBy(keyFields);
        return jdbc.query(sql, mapper, keyParams(ak, key)).stream().findFirst();
    }

    /** {@code REWRITE}: false = INVALID KEY (no such record). */
    public boolean rewrite(CobolRecord rec) {
        List<Layout.Field> nonKey = layout.fields().stream().filter(f -> !keyFields.contains(f)).toList();
        String sets = nonKey.stream().map(f -> col(f) + " = ?").collect(Collectors.joining(", "));
        Object[] setParams = params(rec, nonKey);
        Object[] keyParams = params(rec, keyFields);
        Object[] all = new Object[setParams.length + keyParams.length];
        System.arraycopy(setParams, 0, all, 0, setParams.length);
        System.arraycopy(keyParams, 0, all, setParams.length, keyParams.length);
        return jdbc.update("UPDATE " + table + " SET " + sets + " WHERE " + where(keyFields), all) == 1;
    }

    /** Sequential access ({@code READ NEXT} until status 10): every record in key order. */
    public List<CobolRecord> readAllInKeyOrder() {
        return jdbc.query("SELECT * FROM " + table + " ORDER BY " + orderBy(keyFields), mapper);
    }

    public int count() {
        Integer n = jdbc.queryForObject("SELECT COUNT(*) FROM " + table, Integer.class);
        return n == null ? 0 : n;
    }

    // ---------------------------------------------------------------- mapping

    private static String where(List<Layout.Field> fields) {
        return fields.stream().map(f -> col(f) + " = ?").collect(Collectors.joining(" AND "));
    }

    private static String orderBy(List<Layout.Field> fields) {
        return fields.stream().map(KsdsTable::col).collect(Collectors.joining(", "));
    }

    /** Split the raw key bytes into the per-field values of the (possibly composite) key. */
    private static Object[] keyParams(List<Layout.Field> fields, String rawKey) {
        Object[] out = new Object[fields.size()];
        int pos = 0;
        for (int i = 0; i < fields.size(); i++) {
            Layout.Field f = fields.get(i);
            String part = rawKey.substring(pos, pos + f.length());
            out[i] = f.kind() == Layout.Kind.S ? ZonedDecimal.decodeSigned(part, f.scale()) : part;
            pos += f.length();
        }
        return out;
    }

    private static Object[] params(CobolRecord rec, List<Layout.Field> fields) {
        Object[] out = new Object[fields.size()];
        for (int i = 0; i < fields.size(); i++) {
            Layout.Field f = fields.get(i);
            out[i] = f.kind() == Layout.Kind.S ? rec.decimal(f.name()) : rec.get(f.name());
        }
        return out;
    }

    private CobolRecord fromRow(ResultSet rs) throws SQLException {
        CobolRecord rec = CobolRecord.initialized(layout);
        for (Layout.Field f : layout.fields()) {
            if (f.kind() == Layout.Kind.S) {
                BigDecimal v = rs.getBigDecimal(col(f));
                rec.setDecimal(f.name(), v == null ? BigDecimal.ZERO : v);
            } else {
                rec.set(f.name(), rs.getString(col(f)));
            }
        }
        return rec;
    }
}
