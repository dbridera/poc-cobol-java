package com.example.poc.nightlybatch.domain;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A copybook's record layout: ordered fixed-width fields, each with its COBOL
 * data name and PICTURE class.
 * <ul>
 *   <li>{@code X} — alphanumeric, space-padded</li>
 *   <li>{@code N} — unsigned numeric DISPLAY ({@code PIC 9(n)[V9(s)]}), zero-padded</li>
 *   <li>{@code S} — signed numeric DISPLAY ({@code PIC S9(n)[V9(s)]}), trailing EBCDIC overpunch</li>
 * </ul>
 * Numeric fields map to {@code BigDecimal} with the scale of the PIC (CLAUDE.md rule 1).
 */
public final class Layout {

    public enum Kind { X, N, S }

    public record Field(String name, Kind kind, int length, int scale, int offset) {
        public boolean numeric() { return kind != Kind.X; }
        public int end() { return offset + length; }
    }

    private final String name;
    private final String copybook;
    private final List<Field> fields;
    private final Map<String, Field> byName = new LinkedHashMap<>();
    private final int lrecl;

    private Layout(String name, String copybook, List<Field> fields) {
        this.name = name;
        this.copybook = copybook;
        this.fields = List.copyOf(fields);
        int len = 0;
        for (Field f : fields) {
            byName.put(f.name(), f);
            len = f.end();
        }
        this.lrecl = len;
    }

    public static Builder builder(String name, String copybook) { return new Builder(name, copybook); }

    public String name() { return name; }
    public String copybook() { return copybook; }
    public int lrecl() { return lrecl; }
    public List<Field> fields() { return fields; }

    public Field field(String fieldName) {
        Field f = byName.get(fieldName);
        if (f == null) throw new IllegalArgumentException(name + " has no field " + fieldName);
        return f;
    }

    /** Fields whose byte range tiles exactly [offset, offset+length) — a KSDS key. */
    public List<Field> fieldsCovering(int offset, int length) {
        List<Field> out = new ArrayList<>();
        int pos = offset;
        for (Field f : fields) {
            if (f.offset() == pos && f.end() <= offset + length) {
                out.add(f);
                pos = f.end();
            }
        }
        if (pos != offset + length) {
            throw new IllegalArgumentException(name + ": no field boundary tiles key (" + offset + "," + length + ")");
        }
        return out;
    }

    public static final class Builder {
        private final String name;
        private final String copybook;
        private final List<Field> fields = new ArrayList<>();
        private int offset;
        private int fillerCount;

        Builder(String name, String copybook) { this.name = name; this.copybook = copybook; }

        public Builder x(String fieldName, int length) { return add(fieldName, Kind.X, length, 0); }
        public Builder n(String fieldName, int digits) { return add(fieldName, Kind.N, digits, 0); }
        public Builder n(String fieldName, int digits, int scale) { return add(fieldName, Kind.N, digits, scale); }
        public Builder s(String fieldName, int digits, int scale) { return add(fieldName, Kind.S, digits, scale); }
        public Builder filler(int length) { return add("FILLER-" + (++fillerCount), Kind.X, length, 0); }

        private Builder add(String fieldName, Kind kind, int length, int scale) {
            fields.add(new Field(fieldName, kind, length, scale, offset));
            offset += length;
            return this;
        }

        public Layout build() { return new Layout(name, copybook, fields); }
    }
}
