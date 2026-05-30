package com.example.poc.cciaccountconverter.service;

import com.example.poc.cciaccountconverter.domain.Commarea;
import org.springframework.stereotype.Service;

/**
 * Mirror of {@code 0600-CALCULA-CTA-COMERCIAL} in
 * [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:173-196].
 *
 * <p>CCI → commercial-account decoder. Branches on {@code TI-YRCV-IDT-CTA}
 * (byte 7 of the input CCI):
 * <ul>
 *   <li>{@code '0'} → IMPACS (family {@code 004}). Writes
 *       {@code BCP-EDIT-IM} bytes 8-20. NOTE: uses
 *       {@code NRO-CTA(2:7)} — bytes 2-8 of the 8-byte NRO-CTA, dropping
 *       the leading byte (IMPACS account is 7 digits).</li>
 *   <li>{@code '1'} → SAVING (family {@code 005}). Writes
 *       {@code BCP-EDIT-ST} bytes 7-20. Uses the full 8-byte NRO-CTA.</li>
 *   <li>{@code '2'} → CTS (family {@code 009}). Writes
 *       {@code BCP-EDIT-ST} bytes 7-20. Same field copy as SAVING.</li>
 *   <li>other → silent fall-through (output unchanged).</li>
 * </ul>
 *
 * <p>This routine never sets RC — the validator already passed by the
 * time we get here. It does NOT write to {@code CUENTA-ITE-EDIT}.
 */
// COBOL: BCTITSCV-RUN.cbl:173-196
@Service
public class CciDecoder {

    /** Run the EVALUATE on {@code IDT-CTA}. */
    // COBOL: BCTITSCV-RUN.cbl:174-195
    public void decode(Commarea c) {
        switch (c.getIdtCta()) {
            // COBOL: BCTITSCV-RUN.cbl:177-183 (WHEN '0' — IMPACS)
            case "0" -> {
                c.setBscCodFamRet("004");
                String num7 = c.getNroCta().substring(1, 8); // NRO-CTA(2:7) — drop leading byte
                c.writeBcpEditIm(c.getCodOfi(), num7, c.getCodMon(), c.getDigInt1());
            }
            // COBOL: BCTITSCV-RUN.cbl:185-191 (WHEN '1' — SAVING)
            case "1" -> {
                c.setBscCodFamRet("005");
                c.writeBcpEditSt(c.getCodOfi(), c.getNroCta(), c.getCodMon(), c.getDigInt1());
            }
            // COBOL: BCTITSCV-RUN.cbl:193-199 (WHEN '2' — CTS)
            case "2" -> {
                c.setBscCodFamRet("009");
                c.writeBcpEditSt(c.getCodOfi(), c.getNroCta(), c.getCodMon(), c.getDigInt1());
            }
            // No WHEN OTHER in the COBOL — fall through silently.
            default -> { /* COBOL fall-through: output fields unchanged */ }
        }
    }
}
