package com.example.poc.nightlybatch.domain;

import com.example.poc.nightlybatch.io.ZonedDecimal;

import java.math.BigDecimal;
import java.util.Arrays;

/**
 * A record buffer with the semantics of a COBOL group item: fixed bytes, fields
 * addressed by name, {@code MOVE}/{@code ADD} store rules applied on write.
 *
 * <ul>
 *   <li>{@link #get(String)} returns the raw bytes of an alphanumeric field (space-padded, as COBOL compares them);</li>
 *   <li>{@link #decimal(String)} decodes a numeric field to {@code BigDecimal} with the PIC's scale;</li>
 *   <li>{@link #set} / {@link #setDecimal} store with COBOL truncation: alphanumerics are
 *       left-justified and space-filled or cut on the right; numerics lose extra decimals
 *       (toward zero) and extra high-order digits — there is no {@code ON SIZE ERROR}
 *       anywhere in these programs (ADR-12);</li>
 *   <li>{@link #add} is {@code ADD x TO field}; {@link #initialize()} is {@code INITIALIZE}
 *       (spaces for X, zeros for numerics).</li>
 * </ul>
 * Bytes of fields that are never touched (FILLER, unused columns) survive unchanged,
 * exactly as they would in working storage.
 */
public final class CobolRecord {
    private final Layout layout;
    private final char[] buf;

    private CobolRecord(Layout layout, char[] buf) {
        this.layout = layout;
        this.buf = buf;
    }

    /** A fresh record as COBOL working storage starts (GnuCOBOL default byte init): spaces for X and FILLER, zeros for numerics. */
    public static CobolRecord initialized(Layout layout) {
        CobolRecord r = new CobolRecord(layout, new char[layout.lrecl()]);
        Arrays.fill(r.buf, ' ');
        r.initialize();
        return r;
    }

    public static CobolRecord of(Layout layout, String raw) {
        if (raw.length() != layout.lrecl()) {
            throw new IllegalArgumentException(layout.name() + ": record length " + raw.length() + " != " + layout.lrecl());
        }
        return new CobolRecord(layout, raw.toCharArray());
    }

    public Layout layout() { return layout; }

    /**
     * {@code INITIALIZE}: alphanumerics to spaces, numerics to zero — and FILLER
     * items untouched (no WITH FILLER), so whatever a previous {@code READ … INTO}
     * left there survives. Verified against GnuCOBOL 3.2 (README spike log).
     */
    public void initialize() {
        for (Layout.Field f : layout.fields()) {
            if (f.name().startsWith("FILLER-")) continue;
            if (f.numeric()) setDecimal(f, BigDecimal.ZERO);
            else Arrays.fill(buf, f.offset(), f.end(), ' ');
        }
    }

    /** Raw bytes of a field (any kind). */
    public String get(String field) {
        Layout.Field f = layout.field(field);
        return new String(buf, f.offset(), f.length());
    }

    /** {@code field(start:length)} reference modification, 1-based start like COBOL. */
    public String substring(String field, int start1, int length) {
        Layout.Field f = layout.field(field);
        return new String(buf, f.offset() + start1 - 1, length);
    }

    public BigDecimal decimal(String field) {
        Layout.Field f = layout.field(field);
        String raw = get(field);
        return switch (f.kind()) {
            case S -> ZonedDecimal.decodeSigned(raw, f.scale());
            case N -> ZonedDecimal.decodeUnsigned(raw, f.scale());
            case X -> throw new IllegalArgumentException(field + " is alphanumeric");
        };
    }

    /** {@code MOVE text TO field}: left-justified, space-filled, truncated on the right. */
    public CobolRecord set(String field, String text) {
        Layout.Field f = layout.field(field);
        for (int i = 0; i < f.length(); i++) {
            buf[f.offset() + i] = i < text.length() ? text.charAt(i) : ' ';
        }
        return this;
    }

    public CobolRecord setDecimal(String field, BigDecimal value) {
        return setDecimal(layout.field(field), value);
    }

    private CobolRecord setDecimal(Layout.Field f, BigDecimal value) {
        String encoded = switch (f.kind()) {
            case S -> ZonedDecimal.encodeSigned(value, f.length(), f.scale());
            case N -> ZonedDecimal.encodeUnsigned(value, f.length(), f.scale());
            case X -> throw new IllegalArgumentException(f.name() + " is alphanumeric");
        };
        encoded.getChars(0, f.length(), buf, f.offset());
        return this;
    }

    /** {@code ADD value TO field} (no ROUNDED, no SIZE ERROR). */
    public CobolRecord add(String field, BigDecimal value) {
        return setDecimal(field, decimal(field).add(value));
    }

    /** {@code MOVE other-group TO this-group} (same length): a byte copy. */
    public CobolRecord moveFrom(CobolRecord other) {
        if (other.buf.length != buf.length) throw new IllegalArgumentException("group lengths differ");
        System.arraycopy(other.buf, 0, buf, 0, buf.length);
        return this;
    }

    public CobolRecord copy() {
        return new CobolRecord(layout, buf.clone());
    }

    /** The record bytes — what {@code DISPLAY record} prints and {@code WRITE} stores. */
    @Override
    public String toString() { return new String(buf); }
}
