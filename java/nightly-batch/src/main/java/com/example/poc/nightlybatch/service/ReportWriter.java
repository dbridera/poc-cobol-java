package com.example.poc.nightlybatch.service;

import com.example.poc.nightlybatch.domain.CobolRecord;
import com.example.poc.nightlybatch.io.FixedRecordFile;
import com.example.poc.nightlybatch.io.PicEditor;
import com.example.poc.nightlybatch.io.ZonedDecimal;

import java.io.IOException;
import java.math.BigDecimal;

/**
 * The report paragraphs of CBTRN03C with their working storage: line counter,
 * page size 20, page / account / grand totals, and the CVTRA07Y line layouts.
 * Every line is 133 bytes, space-padded.
 */
public final class ReportWriter {
    public static final int LINE = 133;
    private static final int PAGE_SIZE = 20;                               // WS-PAGE-SIZE 9(03) COMP-3 VALUE 20
    private static final String HEADER_2 = "-".repeat(LINE);              // TRANSACTION-HEADER-2
    private static final String HEADER_1 = pad("Transaction ID", 17) + pad("Account ID", 12) + pad("Transaction Type", 19)
            + pad("Tran Category", 35) + pad("Tran Source", 14) + " " + pad("        Amount", 16);

    private final FixedRecordFile.Writer out;
    private long lineCounter;                                              // WS-LINE-COUNTER 9(09) COMP-3
    private BigDecimal pageTotal = BigDecimal.ZERO;                        // WS-PAGE-TOTAL S9(09)V99
    private BigDecimal accountTotal = BigDecimal.ZERO;                     // WS-ACCOUNT-TOTAL S9(09)V99
    private BigDecimal grandTotal = BigDecimal.ZERO;                       // WS-GRAND-TOTAL S9(09)V99
    private boolean firstTime = true;                                      // WS-FIRST-TIME
    private String reptStartDate = pad("", 10);                            // REPT-START-DATE
    private String reptEndDate = pad("", 10);                              // REPT-END-DATE

    public ReportWriter(FixedRecordFile.Writer out) {
        this.out = out;
    }

    public BigDecimal pageTotal() { return pageTotal; }

    /** The EOF branch of the main loop: {@code ADD TRAN-AMT TO WS-PAGE-TOTAL WS-ACCOUNT-TOTAL} with the stale record. */
    // COBOL: CBTRN03C.cbl:200-202 (faithful defect D2, CLAUDE.md rule 5)
    public void addStaleAmount(BigDecimal amount) {
        pageTotal = add(pageTotal, amount);
        accountTotal = add(accountTotal, amount);
    }

    /** {@code 1100-WRITE-TRANSACTION-REPORT}. */
    // COBOL: CBTRN03C.cbl:274-292
    public void writeTransactionReport(CobolRecord tran, CobolRecord xrefWs, CobolRecord trantypeWs, CobolRecord trancatgWs,
                                       String startDate, String endDate) throws IOException {
        if (firstTime) {
            firstTime = false;
            reptStartDate = startDate;
            reptEndDate = endDate;
            writeHeaders();
        }
        if (lineCounter % PAGE_SIZE == 0) {                                // FUNCTION MOD(WS-LINE-COUNTER, WS-PAGE-SIZE) = 0
            writePageTotals();
            writeHeaders();
        }
        BigDecimal amt = tran.decimal("TRAN-AMT");
        pageTotal = add(pageTotal, amt);
        accountTotal = add(accountTotal, amt);
        writeDetail(tran, xrefWs, trantypeWs, trancatgWs);
    }

    /** {@code 1110-WRITE-PAGE-TOTALS}. */
    // COBOL: CBTRN03C.cbl:293-305
    public void writePageTotals() throws IOException {
        writeLine(pad("Page Total", 11) + ".".repeat(86) + PicEditor.plusZzz(pageTotal));   // REPORT-PAGE-TOTALS
        grandTotal = add(grandTotal, pageTotal);
        pageTotal = BigDecimal.ZERO;
        lineCounter++;
        writeLine(HEADER_2);
        lineCounter++;
    }

    /** {@code 1120-WRITE-ACCOUNT-TOTALS}. */
    // COBOL: CBTRN03C.cbl:306-317
    public void writeAccountTotals() throws IOException {
        writeLine(pad("Account Total", 13) + ".".repeat(84) + PicEditor.plusZzz(accountTotal));   // REPORT-ACCOUNT-TOTALS
        accountTotal = BigDecimal.ZERO;
        lineCounter++;
        writeLine(HEADER_2);
        lineCounter++;
    }

    /** {@code 1110-WRITE-GRAND-TOTALS}. */
    // COBOL: CBTRN03C.cbl:318-323
    public void writeGrandTotals() throws IOException {
        writeLine(pad("Grand Total", 11) + ".".repeat(86) + PicEditor.plusZzz(grandTotal));     // REPORT-GRAND-TOTALS
    }

    /** {@code 1120-WRITE-HEADERS}: name header, blank line, column titles, dashes. */
    // COBOL: CBTRN03C.cbl:324-342
    private void writeHeaders() throws IOException {
        writeLine(pad("DALYREPT", 38) + pad("Daily Transaction Report", 41) + pad("Date Range: ", 12)
                + reptStartDate + " to " + reptEndDate);                                     // REPORT-NAME-HEADER
        lineCounter++;
        writeLine("");                                                                        // WS-BLANK-LINE
        lineCounter++;
        writeLine(HEADER_1);                                                                  // TRANSACTION-HEADER-1
        lineCounter++;
        writeLine(HEADER_2);                                                                  // TRANSACTION-HEADER-2
        lineCounter++;
    }

    /** {@code 1120-WRITE-DETAIL}: INITIALIZE the detail line (FILLER separators keep their VALUEs), then the MOVEs. */
    // COBOL: CBTRN03C.cbl:361-375, CVTRA07Y.cpy TRANSACTION-DETAIL-REPORT
    private void writeDetail(CobolRecord tran, CobolRecord xrefWs, CobolRecord trantypeWs, CobolRecord trancatgWs) throws IOException {
        String line = pad(tran.get("TRAN-ID"), 16) + " "
                + pad(xrefWs.get("XREF-ACCT-ID"), 11) + " "
                + pad(tran.get("TRAN-TYPE-CD"), 2) + "-"
                + pad(trantypeWs.get("TRAN-TYPE-DESC"), 15) + " "
                + pad(tran.get("TRAN-CAT-CD"), 4) + "-"
                + pad(trancatgWs.get("TRAN-CAT-TYPE-DESC"), 29) + " "
                + pad(tran.get("TRAN-SOURCE"), 10) + "    "
                + PicEditor.minusZzz(tran.decimal("TRAN-AMT")) + "  ";
        writeLine(line);
        lineCounter++;
    }

    /** {@code 1111-WRITE-REPORT-REC}: MOVE to the 133-byte FD record, WRITE. */
    // COBOL: CBTRN03C.cbl:343-360
    private void writeLine(String text) throws IOException {
        out.write(pad(text, LINE));
    }

    /** S9(09)V99 accumulators: ADD without SIZE ERROR keeps the low-order digits. */
    private static BigDecimal add(BigDecimal total, BigDecimal amount) {
        return ZonedDecimal.truncate(total.add(amount), 11, 2);
    }

    /** {@code MOVE text TO PIC X(width)}: left-justified, space-filled, truncated. */
    static String pad(String s, int width) {
        return s.length() >= width ? s.substring(0, width) : s + " ".repeat(width - s.length());
    }
}
