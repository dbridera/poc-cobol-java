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
    private final OutputStream trace;   // null when the manifest does not enable tracing

    private StepIo(OutputStream out, OutputStream trace) { this.out = out; this.trace = trace; }

    public static StepIo open(Path file) throws IOException {
        return new StepIo(new BufferedOutputStream(Files.newOutputStream(file)), null);
    }

    /** stdout plus the paragraph trace ({@code <nn>-<NAME>.trace.txt}, same canonical form as the
     *  normalised GnuCOBOL {@code -ftrace} output: {@code PROGRAM Paragraph NAME}). */
    public static StepIo open(Path file, Path traceFile) throws IOException {
        return new StepIo(new BufferedOutputStream(Files.newOutputStream(file)),
                traceFile == null ? null : new BufferedOutputStream(Files.newOutputStream(traceFile)));
    }

    /** Program entry ({@code PROGRAM Entry PROGRAM}): the COBOL program starts. */
    public void entry(String program) { traceLine(program + " Entry " + program); }

    /** Paragraph entry ({@code PROGRAM Paragraph NAME}): control enters a paragraph, by PERFORM or fall-through. */
    public void paragraph(String program, String name) { traceLine(program + " Paragraph " + name); }

    private void traceLine(String line) {
        if (trace == null) return;
        try {
            trace.write(line.getBytes(StandardCharsets.ISO_8859_1));
            trace.write('\n');
        } catch (IOException e) {
            throw new java.io.UncheckedIOException(e);
        }
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
    public void close() throws IOException {
        out.close();
        if (trace != null) trace.close();
    }
}
