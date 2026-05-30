      *****************************************************************
      * BCTITSCV-RUN - CCI <-> Cuenta Comercial converter             *
      *                                                               *
      * Outer program: DRIVER-BCTITSCV - reads stdin, populates the  *
      *   200-byte TI-YRCV-PARAMETROS commarea, CALLs BCTITSCV,      *
      *   DISPLAYs the result.                                       *
      *                                                               *
      * Inner program: BCTITSCV - adapted from                        *
      *   cobol/cci-account-converter/original/BCTITSCV.COB           *
      *   (Banco de Credito del Peru, Feb 2015). Four CICS removals   *
      *   to make it run under GnuCOBOL standalone - see comment      *
      *   block ahead of the inner PROGRAM-ID and README.md.          *
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    DRIVER-BCTITSCV.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REQUEST-FILE ASSIGN TO 'requests.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REQUEST-FS.

       DATA DIVISION.

       FILE SECTION.
       FD  REQUEST-FILE.
       01  REQUEST-RECORD       PIC X(255).

       WORKING-STORAGE SECTION.

       01  WS-EYECATCHER       PIC X(16) VALUE 'DRIVER-BCTITSCV-'.

       01  WS-REQUEST-FS       PIC X(02) VALUE '00'.
       01  WS-EOF-FLAG         PIC X     VALUE 'N'.
           88  EOF-REACHED     VALUE 'Y'.

      * Driver hosts the commarea here in WS. The nested BCTITSCV
      * receives the same record in its LINKAGE SECTION via USING.
       COPY BCTIYRCV.

       PROCEDURE DIVISION.

       MAIN-DRIVER.
           OPEN INPUT REQUEST-FILE
           IF WS-REQUEST-FS NOT = '00'
               DISPLAY 'ERR OPEN requests.dat FS=' WS-REQUEST-FS
               STOP RUN RETURNING 1
           END-IF

           PERFORM READ-INPUT
           PERFORM UNTIL EOF-REACHED
               PERFORM CALL-BCTITSCV
               PERFORM DISPLAY-RESULT
               PERFORM READ-INPUT
           END-PERFORM

           CLOSE REQUEST-FILE
           STOP RUN RETURNING 0.

       READ-INPUT.
           READ REQUEST-FILE
               AT END SET EOF-REACHED TO TRUE
           END-READ.

       CALL-BCTITSCV.
      * Wipe the 200-byte commarea before each call so leftover bytes
      * from a prior fixture cannot leak into the output.
           MOVE SPACES TO TI-YRCV-PARAMETROS
      * Parse 6 whitespace-separated tokens from the request record:
      *   IND-CONV COD-INTFZ BSC-COD-FAM BSC-COD-PRO BSC-COD-SPR
      *   COD-CTA-CCI
           UNSTRING REQUEST-RECORD DELIMITED BY ALL SPACES
               INTO TI-YRCV-IND-CONV
                    TI-YRCV-COD-INTFZ
                    TI-YRCV-BSC-COD-FAM
                    TI-YRCV-BSC-COD-PRO
                    TI-YRCV-BSC-COD-SPR
                    TI-YRCV-COD-CTA-CCI
           END-UNSTRING
           CALL 'BCTITSCV' USING TI-YRCV-PARAMETROS.

       DISPLAY-RESULT.
      * Deterministic key-prefixed output block.
           DISPLAY 'RC: '         TI-YRCV-COD-RETURN
           DISPLAY 'MSG: '        FUNCTION TRIM(TI-YRCV-MSG-RETURN)
           DISPLAY 'FAM-RET: '    TI-YRCV-BSC-COD-FAM-RET
           DISPLAY 'BCP-EDIT: '   TI-YRCV-BCP-EDIT-IM
           DISPLAY 'CUENTA-ITE: ' TI-YRCV-CUENTA-ITE-EDIT
           DISPLAY '---'.

       END PROGRAM DRIVER-BCTITSCV.

      *****************************************************************
      * BCTITSCV - adapted from original/BCTITSCV.COB.                 *
      *                                                                *
      * Four surgical edits (no other changes - paragraphs, EVALUATE  *
      * chains, COMPUTE chains, mid-EVALUATE GOBACK in 0500 all stay  *
      * verbatim, per CLAUDE.md rule 5: don't refine the COBOL):       *
      *                                                                *
      *   1. LINKAGE: removed `01 DFHCOMMAREA PIC X(01).`             *
      *      (original line 69). Caller binds via USING directly.     *
      *                                                                *
      *   2. 0100-INICIO: removed `EXEC CICS HANDLE ABEND LABEL       *
      *      (3000-FINAL) END-EXEC` (original lines 82-85).           *
      *                                                                *
      *   3. 0120-RECIBE-COMMAREA: replaced the                       *
      *      `IF EIBCALEN GREATER 0 SET ADDRESS ... ELSE ... END-IF`  *
      *      block (original lines 93-100) with `CONTINUE.` - the    *
      *      "no commarea" branch is unreachable standalone.          *
      *                                                                *
      *   4. 3000-FINAL: replaced `EXEC CICS RETURN END-EXEC`         *
      *      (original lines 265-267) with `GOBACK.`.                  *
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    BCTITSCV.
       AUTHOR.        NAME AUTHOR.

       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  FILLER                       PIC X(40) VALUE
                       'INICIO DE WORKING-STORAGE PGM BCTITSCV**'.
       01  WS-VARIABLES.
           03  WS-TRES-NUMERO          PIC 9(03) VALUE ZEROS.
           03  WS-UNO-NUMERO           PIC 9(01) VALUE ZEROS.
           03  WS-DOS-NUMERO           PIC 9(02) VALUE ZEROS.
           03  FILLER REDEFINES WS-DOS-NUMERO.
               05 WS-DOS-NUMERO-DEC    PIC 9(01).
               05 WS-DOS-NUMERO-UNI    PIC 9(01).
           03  WS-I1                   PIC S9(03) VALUE ZEROS COMP.

       01  WS-FILL-BCO-OFI.
           03  WS-INICIAL              PIC 9(06).
           03  FILLER REDEFINES  WS-INICIAL.
               05 WS-INICIAL-9     PIC 9(01) OCCURS 06.
       01  WS-FILL-TI-YRCV-DIG.
           03  WS-INICIAL2             PIC 9(12).
           03  FILLER REDEFINES  WS-INICIAL2.
               05 WS-INICIAL-8     PIC 9(01) OCCURS 12.

       LINKAGE SECTION.
      *--- Adaptation 1: removed `01 DFHCOMMAREA PIC X(01).` here.
       COPY BCTIYRCV.

       PROCEDURE DIVISION USING TI-YRCV-PARAMETROS.

           PERFORM 0100-INICIO
           PERFORM 0500-EVALUA-PROCESO
           PERFORM 3000-FINAL
           .

       0100-INICIO.
      *--- Adaptation 2: removed `EXEC CICS HANDLE ABEND` block.
           PERFORM 0120-RECIBE-COMMAREA
           .

       0120-RECIBE-COMMAREA.
      *--- Adaptation 3: standalone caller binds commarea via USING;
      *    the EIBCALEN check + SET ADDRESS dance is unreachable.
           CONTINUE
           .

       0500-EVALUA-PROCESO.
            MOVE   TI-YRCV-COD-CTA-CCI       TO TI-YRCV-BCP-EDIT-IM
            PERFORM 1000-VALIDA-ARGUMENTOS   THRU 1000-FINVALIDA
            EVALUATE TRUE
                WHEN TI-YRCV-88-CCI-BCP
                     PERFORM 0600-CALCULA-CTA-COMERCIAL
                WHEN TI-YRCV-88-BCP-CCI
                     PERFORM 1500-CALCULA-CHEQUEO-INT THRU 1500-FININT
                WHEN OTHER
                     MOVE  '99'    TO   TI-YRCV-COD-RETURN
                     MOVE  'COD. CONV.NO VALIDO'  TO
                                        TI-YRCV-MSG-RETURN
                GOBACK
            END-EVALUATE
            .

       0600-CALCULA-CTA-COMERCIAL.
            EVALUATE TI-YRCV-IDT-CTA
      *         IMPACS BBBBBBBXXXCCCCCCCMDD
                WHEN '0'
                   MOVE '004'                TO TI-YRCV-BSC-COD-FAM-RET
                   MOVE TI-YRCV-COD-OFI      TO TI-YRCV-OFI-BCP-IM
                   MOVE TI-YRCV-NRO-CTA(2:7) TO TI-YRCV-NUM-BCP-IM
                   MOVE TI-YRCV-COD-MON      TO TI-YRCV-MON-BCP-IM
                   MOVE TI-YRCV-DIG-INT1     TO TI-YRCV-DIG-BCP-IM
      *         SAVING BBBBBBXXXCCCCCCCCMDD
                WHEN '1'
                   MOVE '005'                TO TI-YRCV-BSC-COD-FAM-RET
                   MOVE TI-YRCV-COD-OFI      TO TI-YRCV-OFI-BCP-ST
                   MOVE TI-YRCV-NRO-CTA      TO TI-YRCV-NUM-BCP-ST
                   MOVE TI-YRCV-COD-MON      TO TI-YRCV-MON-BCP-ST
                   MOVE TI-YRCV-DIG-INT1     TO TI-YRCV-DIG-BCP-ST
      *         CTS    BBBBBBXXXCCCCCCCCMDD
                WHEN '2'
                   MOVE '009'                TO TI-YRCV-BSC-COD-FAM-RET
                   MOVE TI-YRCV-COD-OFI      TO TI-YRCV-OFI-BCP-ST
                   MOVE TI-YRCV-NRO-CTA      TO TI-YRCV-NUM-BCP-ST
                   MOVE TI-YRCV-COD-MON      TO TI-YRCV-MON-BCP-ST
                   MOVE TI-YRCV-DIG-INT1     TO TI-YRCV-DIG-BCP-ST
            END-EVALUATE
            .

       1000-VALIDA-ARGUMENTOS.
            MOVE  '00'        TO   TI-YRCV-COD-RETURN
            IF  TI-YRCV-BSC-COD-FAM-IM OR TI-YRCV-BSC-COD-FAM-ST
                CONTINUE
            ELSE
                MOVE  '99'    TO   TI-YRCV-COD-RETURN
                MOVE  'COD. SIST.NO VALIDO'  TO
                                   TI-YRCV-MSG-RETURN
                GOBACK
            END-IF.

            IF  TI-YRCV-BSC-COD-PRO IS NUMERIC
                CONTINUE
            ELSE
                MOVE  '99'    TO   TI-YRCV-COD-RETURN
                MOVE  'ACCT.TYPE NO NUMRIC'  TO
                                   TI-YRCV-MSG-RETURN
                GOBACK
            END-IF.

            IF  TI-YRCV-BSC-COD-FAM-IM
                IF TI-YRCV-OFI-BCP-IM IS NUMERIC AND
                   TI-YRCV-NUM-BCP-IM IS NUMERIC AND
                   TI-YRCV-MON-BCP-IM IS NUMERIC AND
                   TI-YRCV-DIG-BCP-IM IS NUMERIC
                   CONTINUE
               ELSE
                   MOVE  '99'    TO   TI-YRCV-COD-RETURN
                   MOVE  'DATOS NO NUMERICOS '  TO
                                      TI-YRCV-MSG-RETURN
                   GOBACK
               END-IF
            ELSE
                IF TI-YRCV-OFI-BCP-ST IS NUMERIC AND
                   TI-YRCV-NUM-BCP-ST IS NUMERIC AND
                   TI-YRCV-MON-BCP-ST IS NUMERIC AND
                   TI-YRCV-DIG-BCP-ST IS NUMERIC
                   CONTINUE
               ELSE
                   MOVE  '99'    TO   TI-YRCV-COD-RETURN
                   MOVE  'DATOS NO NUMERICOS '  TO
                                      TI-YRCV-MSG-RETURN
                   GOBACK
               END-IF
            END-IF.
       1000-FINVALIDA.
            EXIT.

       1500-CALCULA-CHEQUEO-INT.
            MOVE '002'            TO TI-YRCV-BCO-ITE
            IF  TI-YRCV-BSC-COD-FAM-IM
                MOVE '0'              TO TI-YRCV-PRO-ITE
                MOVE TI-YRCV-OFI-BCP-IM TO TI-YRCV-OFI-ITE
                STRING  '0'              DELIMITED BY SIZE
                        TI-YRCV-NUM-BCP-IM DELIMITED BY SIZE
                                    INTO TI-YRCV-NUM-ITE
                MOVE TI-YRCV-MON-BCP-IM TO TI-YRCV-MON-ITE
                MOVE TI-YRCV-DIG-BCP-IM TO TI-YRCV-DIG-INT
            ELSE
                MOVE '1'              TO TI-YRCV-PRO-ITE
      *         PARA CUENTAS 'CTS' SE ASIGNA '2' COMO TIPO DE PRODUCTO
                IF  TI-YRCV-BSC-COD-FAM EQUAL '009'
                    MOVE '2'          TO TI-YRCV-PRO-ITE
                END-IF
                MOVE TI-YRCV-OFI-BCP-ST TO TI-YRCV-OFI-ITE
                MOVE TI-YRCV-NUM-BCP-ST TO TI-YRCV-NUM-ITE
                MOVE TI-YRCV-MON-BCP-ST TO TI-YRCV-MON-ITE
                MOVE TI-YRCV-DIG-BCP-ST TO TI-YRCV-DIG-INT
            END-IF
            PERFORM 2000-CALCULA-DIGCHEQ-BANOFI
            MOVE ZEROS TO WS-DOS-NUMERO WS-TRES-NUMERO WS-UNO-NUMERO
            PERFORM 3000-CALCULA-DIGCHEQ-CUENTA.
       1500-FININT.
            EXIT.

       2000-CALCULA-DIGCHEQ-BANOFI.
            MOVE    TI-YRCV-OFIBAN-ITE    TO WS-INICIAL.
            PERFORM 2500-SUMA-NUM-IMP  VARYING WS-I1 FROM 1 BY 2
                                               UNTIL WS-I1 > 06.
            PERFORM 2550-SUMA-NUM-PAR  VARYING WS-I1 FROM 2 BY 2
                                               UNTIL WS-I1 > 06.
            COMPUTE WS-DOS-NUMERO = ( WS-TRES-NUMERO / 10 )
            COMPUTE WS-UNO-NUMERO = (( WS-DOS-NUMERO * 10 ) + 10 ) -
                                     WS-TRES-NUMERO.
            MOVE WS-UNO-NUMERO TO TI-YRCV-DIG-ITE1.

       3000-CALCULA-DIGCHEQ-CUENTA.
            MOVE    TI-YRCV-NUMERO-ITE    TO WS-INICIAL2.
            PERFORM 3500-SUMA-NUM-IMP2 VARYING WS-I1 FROM 1 BY 2
                                                UNTIL WS-I1 > 12.
            PERFORM 3550-SUMA-NUM-PAR2 VARYING WS-I1 FROM 2 BY 2
                                                UNTIL WS-I1 > 12.
            COMPUTE WS-DOS-NUMERO = ( WS-TRES-NUMERO / 10 )
            COMPUTE WS-UNO-NUMERO = (( WS-DOS-NUMERO * 10 ) + 10 ) -
                                     WS-TRES-NUMERO.
            MOVE WS-UNO-NUMERO TO TI-YRCV-DIG-ITE2.

       2500-SUMA-NUM-IMP.
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-9 (WS-I1) * 1.
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.
       2550-SUMA-NUM-PAR.
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-9 (WS-I1) * 2.
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.
       3500-SUMA-NUM-IMP2.
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-8 (WS-I1) * 1.
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.
       3550-SUMA-NUM-PAR2.
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-8 (WS-I1) * 2
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.

       3000-FINAL.
      *--- Adaptation 4: replaced `EXEC CICS RETURN END-EXEC`.
           GOBACK
           .

       END PROGRAM BCTITSCV.
