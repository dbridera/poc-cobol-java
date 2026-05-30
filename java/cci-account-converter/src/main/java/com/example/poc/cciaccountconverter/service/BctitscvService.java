package com.example.poc.cciaccountconverter.service;

import com.example.poc.cciaccountconverter.domain.Commarea;
import org.springframework.stereotype.Service;

/**
 * Orchestrator: mirror of the {@code BCTITSCV} {@code PROCEDURE DIVISION}
 * body — {@code 0100-INICIO} → {@code 0500-EVALUA-PROCESO} →
 * {@code 3000-FINAL} in [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:138-171].
 *
 * <p>The {@code 0100} and {@code 3000-FINAL} paragraphs are stubs after
 * the four CICS adaptations: {@code 0100} was {@code EXEC CICS HANDLE
 * ABEND}, {@code 3000-FINAL} was {@code EXEC CICS RETURN}. Standalone
 * they are no-ops; we keep the method shells for traceability.
 *
 * <p>The main dispatch (the {@code EVALUATE TRUE} on
 * {@code TI-YRCV-IND-CONV}) lives in {@link #evaluaProceso}.
 */
// COBOL: BCTITSCV-RUN.cbl:138-171
@Service
public class BctitscvService {

    private final BctitscvValidator validator;
    private final CciDecoder decoder;
    private final CciEncoder encoder;

    public BctitscvService(BctitscvValidator validator, CciDecoder decoder, CciEncoder encoder) {
        this.validator = validator;
        this.decoder = decoder;
        this.encoder = encoder;
    }

    /** Mirror of {@code PROCEDURE DIVISION USING TI-YRCV-PARAMETROS}. */
    // COBOL: BCTITSCV-RUN.cbl:138-142
    public void run(Commarea c) {
        iniciar(c);
        evaluaProceso(c);
        finalizar(c);
    }

    /** {@code 0100-INICIO} + {@code 0120-RECIBE-COMMAREA}. After adaptations
     *  2 and 3, these are no-ops. */
    // COBOL: BCTITSCV-RUN.cbl:144-155
    void iniciar(Commarea c) {
        // Adaptation 2: removed EXEC CICS HANDLE ABEND.
        // Adaptation 3: removed EIBCALEN / SET ADDRESS dance.
    }

    /**
     * {@code 0500-EVALUA-PROCESO}: lay the input over the BCP-EDIT
     * REDEFINES view, validate, then dispatch on {@code IND-CONV}.
     *
     * <p>Returns silently after a validation failure — the COBOL
     * {@code GOBACK} inside {@code 1000-VALIDA} exits the entire program;
     * we mirror by skipping the EVALUATE block on a validator-reported
     * failure.
     */
    // COBOL: BCTITSCV-RUN.cbl:157-171
    void evaluaProceso(Commarea c) {
        // Line 158: MOVE TI-YRCV-COD-CTA-CCI TO TI-YRCV-BCP-EDIT-IM
        c.setBcpEditIm(c.getCodCtaCci());

        // 1000-VALIDA-ARGUMENTOS THRU 1000-FINVALIDA — short-circuit GOBACK
        // on failure.
        boolean validationFailed = validator.validate(c);
        if (validationFailed) {
            return;
        }

        // EVALUATE TRUE
        if (c.isCciToBcp()) {
            decoder.decode(c);
        } else if (c.isBcpToCci()) {
            encoder.encode(c);
        } else {
            // WHEN OTHER
            // COBOL: BCTITSCV-RUN.cbl:167-170
            c.setCodReturn("99");
            c.setMsgReturn("COD. CONV.NO VALIDO");
        }
    }

    /** {@code 3000-FINAL}. After adaptation 4, just GOBACK. No-op in Java. */
    // COBOL: BCTITSCV-RUN.cbl:308-312
    void finalizar(Commarea c) {
        // Adaptation 4: was EXEC CICS RETURN, now GOBACK.
    }
}
