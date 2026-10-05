package com.example.poc.nightlybatch.io;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * {@code ORGANIZATION IS SEQUENTIAL} files: fixed-length records, no line
 * terminators, ISO-8859-1 (every byte is one char, so overpunched signs and
 * FILLER bytes round-trip untouched).
 */
public final class FixedRecordFile {
    private FixedRecordFile() {}

    public static List<String> readAll(Path path, int lrecl) throws IOException {
        byte[] bytes = Files.readAllBytes(path);
        if (bytes.length % lrecl != 0) {
            throw new IOException(path + ": size " + bytes.length + " is not a multiple of lrecl " + lrecl);
        }
        List<String> out = new ArrayList<>(bytes.length / lrecl);
        for (int i = 0; i < bytes.length; i += lrecl) {
            out.add(new String(bytes, i, lrecl, StandardCharsets.ISO_8859_1));
        }
        return out;
    }

    /** {@code OPEN OUTPUT}: creates or truncates the file. */
    public static Writer openOutput(Path path, int lrecl) throws IOException {
        return new Writer(new BufferedOutputStream(Files.newOutputStream(path)), lrecl);
    }

    public static final class Writer implements AutoCloseable {
        private final OutputStream out;
        private final int lrecl;
        private int count;

        Writer(OutputStream out, int lrecl) { this.out = out; this.lrecl = lrecl; }

        public void write(String record) throws IOException {
            if (record.length() != lrecl) {
                throw new IllegalArgumentException("record length " + record.length() + " != lrecl " + lrecl);
            }
            out.write(record.getBytes(StandardCharsets.ISO_8859_1));
            count++;
        }

        public int count() { return count; }

        @Override
        public void close() throws IOException { out.close(); }
    }
}
