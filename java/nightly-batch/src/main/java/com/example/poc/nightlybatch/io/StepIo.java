package com.example.poc.nightlybatch.io;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * The step's SYSOUT: what the COBOL program's {@code DISPLAY} statements write.
 * ISO-8859-1 so raw record displays (overpunch characters included) are the
 * same bytes as GnuCOBOL's.
 */
public final class StepIo implements AutoCloseable {
    private final OutputStream out;

    private StepIo(OutputStream out) { this.out = out; }

    public static StepIo open(Path file) throws IOException {
        return new StepIo(new BufferedOutputStream(Files.newOutputStream(file)));
    }

    /** {@code DISPLAY a b c}: operands concatenated without separators, then a newline. */
    public void display(String... operands) {
        try {
            for (String s : operands) out.write(s.getBytes(StandardCharsets.ISO_8859_1));
            out.write('\n');
        } catch (IOException e) {
            throw new java.io.UncheckedIOException(e);
        }
    }

    @Override
    public void close() throws IOException { out.close(); }
}
