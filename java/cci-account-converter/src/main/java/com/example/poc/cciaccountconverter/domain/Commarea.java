package com.example.poc.cciaccountconverter.domain;

/**
 * Mirror of the 200-byte {@code TI-YRCV-PARAMETROS} commarea defined in
 * {@code copybooks/BCTIYRCV.cpy}. Mutable holder because BCTITSCV reads
 * input fields then writes back into overlapping bytes (the
 * {@code BCP-EDIT-IM} / {@code BCP-EDIT-ST} REDEFINES views).
 *
 * <p>All fields are {@code String} — every PIC clause in the copybook is
 * alphanumeric ({@code PIC X}). Numeric arithmetic happens on local
 * {@link java.math.BigDecimal} values inside the calculator services
 * ({@code BigDecimal} mandate per CLAUDE.md hard rule 1).
 *
 * <p>Initial state matches the driver's {@code MOVE SPACES TO
 * TI-YRCV-PARAMETROS}: every field is space-padded to its PIC width.
 */
public class Commarea {

    // ---- Input fields (driver populates from requests.dat tokens) -----------

    /** PIC X(04) — interface code, pass-through. */
    private String codIntfz = "    ";

    /** PIC X(01) — direction: '1' = CCI→BCP, '2' = BCP→CCI. */
    private String indConv = " ";

    /** PIC X(03) — account family: 004/007 IMPACS, 005/009 SAVING/CTS. */
    private String bscCodFam = "   ";

    /** PIC X(03) — product code, validated numeric. */
    private String bscCodPro = "   ";

    /** PIC X(03) — subproduct code, pass-through. */
    private String bscCodSpr = "   ";

    /** PIC X(20) — the 20-byte dual-purpose input: CCI string for
     *  IND-CONV=1, commercial-account layout for IND-CONV=2. */
    private String codCtaCci = "                    ";

    // ---- Output fields (BCTITSCV writes) ------------------------------------

    /** PIC X(02) — return code, "00" or "99". */
    private String codReturn = "  ";

    /** PIC X(80) — error message text (verbatim from COBOL). */
    private String msgReturn = " ".repeat(80);

    /** PIC X(03) — returned account family ({@code 0600} CCI→BCP only). */
    private String bscCodFamRet = "   ";

    /** PIC X(20) — BCP-EDIT-IM view (REDEFINES alias of BCP-EDIT-ST).
     *  Set unconditionally at {@code 0500-EVALUA-PROCESO} entry to a copy
     *  of {@link #codCtaCci}; bytes 8-20 may be overwritten by
     *  {@code 0600-CALCULA-CTA-COMERCIAL}. */
    private String bcpEditIm = "                    ";

    /** PIC X(20) — composed output CCI ({@code 1500} BCP→CCI only). */
    private String cuentaIteEdit = "                    ";

    // ---- Getters / setters --------------------------------------------------

    public String getCodIntfz()      { return codIntfz; }
    public String getIndConv()       { return indConv; }
    public String getBscCodFam()     { return bscCodFam; }
    public String getBscCodPro()     { return bscCodPro; }
    public String getBscCodSpr()     { return bscCodSpr; }
    public String getCodCtaCci()     { return codCtaCci; }
    public String getCodReturn()     { return codReturn; }
    public String getMsgReturn()     { return msgReturn; }
    public String getBscCodFamRet()  { return bscCodFamRet; }
    public String getBcpEditIm()     { return bcpEditIm; }
    public String getCuentaIteEdit() { return cuentaIteEdit; }

    public void setCodIntfz(String v)      { codIntfz = pad(v, 4); }
    public void setIndConv(String v)       { indConv = pad(v, 1); }
    public void setBscCodFam(String v)     { bscCodFam = pad(v, 3); }
    public void setBscCodPro(String v)     { bscCodPro = pad(v, 3); }
    public void setBscCodSpr(String v)     { bscCodSpr = pad(v, 3); }
    public void setCodCtaCci(String v)     { codCtaCci = pad(v, 20); }
    public void setCodReturn(String v)     { codReturn = pad(v, 2); }
    public void setMsgReturn(String v)     { msgReturn = pad(v, 80); }
    public void setBscCodFamRet(String v)  { bscCodFamRet = pad(v, 3); }
    public void setBcpEditIm(String v)     { bcpEditIm = pad(v, 20); }
    public void setCuentaIteEdit(String v) { cuentaIteEdit = pad(v, 20); }

    // ---- 88-level condition names (mirror copybook lines 11-15) -------------

    /** 88-level {@code TI-YRCV-88-CCI-BCP VALUE '1'}. */
    public boolean isCciToBcp() { return "1".equals(indConv); }

    /** 88-level {@code TI-YRCV-88-BCP-CCI VALUE '2'}. */
    public boolean isBcpToCci() { return "2".equals(indConv); }

    /** 88-level {@code TI-YRCV-BSC-COD-FAM-IM VALUE '004' '007'}. */
    public boolean isFamilyIm() { return "004".equals(bscCodFam) || "007".equals(bscCodFam); }

    /** 88-level {@code TI-YRCV-BSC-COD-FAM-ST VALUE '005' '009'}. */
    public boolean isFamilySt() { return "005".equals(bscCodFam) || "009".equals(bscCodFam); }

    // ---- Sub-field accessors over the 20-byte dual-purpose CCI --------------
    // CCI direct view (used for IND-CONV='1' decoding in 0600):

    /** Bytes 1-3 of COD-CTA-CCI. */
    public String getCodBco()  { return codCtaCci.substring(0, 3); }
    /** Bytes 4-6 of COD-CTA-CCI. */
    public String getCodOfi()  { return codCtaCci.substring(3, 6); }
    /** Byte 7 of COD-CTA-CCI — drives the {@code 0600} EVALUATE. */
    public String getIdtCta()  { return codCtaCci.substring(6, 7); }
    /** Bytes 8-15 of COD-CTA-CCI. */
    public String getNroCta()  { return codCtaCci.substring(7, 15); }
    /** Byte 16 of COD-CTA-CCI. */
    public String getCodMon()  { return codCtaCci.substring(15, 16); }
    /** Bytes 17-18 of COD-CTA-CCI. */
    public String getDigInt1() { return codCtaCci.substring(16, 18); }

    // BCP-EDIT-IM view (over the 20 bytes of bcpEditIm):

    /** Bytes 8-10 of BCP-EDIT-IM. */
    public String getOfiBcpIm() { return bcpEditIm.substring(7, 10); }
    /** Bytes 11-17 of BCP-EDIT-IM. */
    public String getNumBcpIm() { return bcpEditIm.substring(10, 17); }
    /** Byte 18 of BCP-EDIT-IM. */
    public String getMonBcpIm() { return bcpEditIm.substring(17, 18); }
    /** Bytes 19-20 of BCP-EDIT-IM. */
    public String getDigBcpIm() { return bcpEditIm.substring(18, 20); }

    // BCP-EDIT-ST view (REDEFINES of BCP-EDIT-IM, offset shifts by 1 byte):

    /** Bytes 7-9 of BCP-EDIT-IM (ST view). */
    public String getOfiBcpSt() { return bcpEditIm.substring(6, 9); }
    /** Bytes 10-17 of BCP-EDIT-IM (ST view). */
    public String getNumBcpSt() { return bcpEditIm.substring(9, 17); }
    /** Byte 18 of BCP-EDIT-IM (ST view). */
    public String getMonBcpSt() { return bcpEditIm.substring(17, 18); }
    /** Bytes 19-20 of BCP-EDIT-IM (ST view). */
    public String getDigBcpSt() { return bcpEditIm.substring(18, 20); }

    /** 0600 IM branch: overwrite bytes 8-20 of bcpEditIm. */
    public void writeBcpEditIm(String ofi3, String num7, String mon1, String dig2) {
        bcpEditIm = bcpEditIm.substring(0, 7) + pad(ofi3, 3) + pad(num7, 7) + pad(mon1, 1) + pad(dig2, 2);
    }

    /** 0600 ST branch: overwrite bytes 7-20 of bcpEditIm. */
    public void writeBcpEditSt(String ofi3, String num8, String mon1, String dig2) {
        bcpEditIm = bcpEditIm.substring(0, 6) + pad(ofi3, 3) + pad(num8, 8) + pad(mon1, 1) + pad(dig2, 2);
    }

    // ---- Helper -------------------------------------------------------------

    /** Right-pad / truncate to exactly {@code width} characters (PIC X semantics). */
    private static String pad(String v, int width) {
        if (v == null) return " ".repeat(width);
        if (v.length() == width) return v;
        if (v.length() > width) return v.substring(0, width);
        return v + " ".repeat(width - v.length());
    }
}
