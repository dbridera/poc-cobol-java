package com.example.poc.nightlybatch.domain;

import java.util.Map;

/**
 * The record layouts of the nightly close, one per copybook under
 * {@code cobol/nightly-batch/copybooks/} (field names are the COBOL data names
 * so every rule in the spec can be read against them). Widths are the PIC
 * sizes; {@code S9(9)V99} is 11 bytes with 2 implied decimals.
 */
public final class Layouts {
    private Layouts() {}

    /** CVTRA05Y TRAN-RECORD (also CVTRA06Y DALYTRAN-RECORD, same shape) — 350 bytes. */
    // COBOL: copybooks/CVTRA05Y.cpy, copybooks/CVTRA06Y.cpy
    public static final Layout TRAN = Layout.builder("TRAN", "CVTRA05Y")
            .x("TRAN-ID", 16).x("TRAN-TYPE-CD", 2).n("TRAN-CAT-CD", 4).x("TRAN-SOURCE", 10).x("TRAN-DESC", 100)
            .s("TRAN-AMT", 11, 2).n("TRAN-MERCHANT-ID", 9).x("TRAN-MERCHANT-NAME", 50).x("TRAN-MERCHANT-CITY", 50)
            .x("TRAN-MERCHANT-ZIP", 10).x("TRAN-CARD-NUM", 16).x("TRAN-ORIG-TS", 26).x("TRAN-PROC-TS", 26).filler(20)
            .build();

    /** CVACT01Y ACCOUNT-RECORD — 300 bytes. */
    // COBOL: copybooks/CVACT01Y.cpy
    public static final Layout ACCOUNT = Layout.builder("ACCOUNT", "CVACT01Y")
            .n("ACCT-ID", 11).x("ACCT-ACTIVE-STATUS", 1).s("ACCT-CURR-BAL", 12, 2).s("ACCT-CREDIT-LIMIT", 12, 2)
            .s("ACCT-CASH-CREDIT-LIMIT", 12, 2).x("ACCT-OPEN-DATE", 10).x("ACCT-EXPIRAION-DATE", 10).x("ACCT-REISSUE-DATE", 10)
            .s("ACCT-CURR-CYC-CREDIT", 12, 2).s("ACCT-CURR-CYC-DEBIT", 12, 2).x("ACCT-ADDR-ZIP", 10).x("ACCT-GROUP-ID", 10)
            .filler(178)
            .build();

    /** CVACT03Y CARD-XREF-RECORD — 50 bytes. */
    // COBOL: copybooks/CVACT03Y.cpy
    public static final Layout XREF = Layout.builder("XREF", "CVACT03Y")
            .x("XREF-CARD-NUM", 16).n("XREF-CUST-ID", 9).n("XREF-ACCT-ID", 11).filler(14)
            .build();

    /** CVTRA01Y TRAN-CAT-BAL-RECORD — 50 bytes. */
    // COBOL: copybooks/CVTRA01Y.cpy
    public static final Layout TCATBAL = Layout.builder("TCATBAL", "CVTRA01Y")
            .n("TRANCAT-ACCT-ID", 11).x("TRANCAT-TYPE-CD", 2).n("TRANCAT-CD", 4).s("TRAN-CAT-BAL", 11, 2).filler(22)
            .build();

    /** CVTRA02Y DIS-GROUP-RECORD — 50 bytes. */
    // COBOL: copybooks/CVTRA02Y.cpy
    public static final Layout DISCGRP = Layout.builder("DISCGRP", "CVTRA02Y")
            .x("DIS-ACCT-GROUP-ID", 10).x("DIS-TRAN-TYPE-CD", 2).n("DIS-TRAN-CAT-CD", 4).s("DIS-INT-RATE", 6, 2).filler(28)
            .build();

    /** CVTRA03Y TRAN-TYPE-RECORD — 60 bytes. */
    // COBOL: copybooks/CVTRA03Y.cpy
    public static final Layout TRANTYPE = Layout.builder("TRANTYPE", "CVTRA03Y")
            .x("TRAN-TYPE", 2).x("TRAN-TYPE-DESC", 50).filler(8)
            .build();

    /** CVTRA04Y TRAN-CAT-RECORD — 60 bytes. */
    // COBOL: copybooks/CVTRA04Y.cpy
    public static final Layout TRANCATG = Layout.builder("TRANCATG", "CVTRA04Y")
            .x("TRAN-TYPE-CD", 2).n("TRAN-CAT-CD", 4).x("TRAN-CAT-TYPE-DESC", 50).filler(4)
            .build();

    /** CBTRN03C WS-DATEPARM-RECORD, read INTO from an 80-byte record. */
    // COBOL: CBTRN03C.cbl:123-126
    public static final Layout DATEPARM = Layout.builder("DATEPARM", "CBTRN03C")
            .x("WS-START-DATE", 10).filler(1).x("WS-END-DATE", 10).filler(59)
            .build();

    /** CBTRN02C REJECT-RECORD: the daily record + WS-VALIDATION-TRAILER — 430 bytes. */
    // COBOL: CBTRN02C.cbl:176-182
    public static final Layout REJECT = Layout.builder("REJECT", "CBTRN02C")
            .x("REJECT-TRAN-DATA", 350).n("WS-VALIDATION-FAIL-REASON", 4).x("WS-VALIDATION-FAIL-REASON-DESC", 76)
            .build();

    private static final Map<String, Layout> BY_COPYBOOK = Map.of(
            "CVTRA05Y", TRAN, "CVTRA06Y", TRAN, "CVACT01Y", ACCOUNT, "CVACT03Y", XREF, "CVTRA01Y", TCATBAL,
            "CVTRA02Y", DISCGRP, "CVTRA03Y", TRANTYPE, "CVTRA04Y", TRANCATG);

    /** Layout of a manifest dataset, by its {@code copybook} attribute. */
    public static Layout forCopybook(String copybook) {
        Layout l = BY_COPYBOOK.get(copybook);
        if (l == null) throw new IllegalArgumentException("no layout for copybook " + copybook);
        return l;
    }
}
