      ******************************************************************
      *                                                                *
      *  ADDMPOL - ADD MOTOR POLICY (batch, GnuCOBOL-runnable)         *
      *                                                                *
      *  Adapted from cicsdev/cics-genapp LGAPDB01.                    *
      *  See cobol/add-motor-policy/README.md for what was kept,       *
      *  what was adapted, and what was added.                         *
      *                                                                *
      *  Reads requests.dat, writes policy.dat / motor.dat / error.log *
      *  with record layouts that mirror the DB2-POLICY and DB2-MOTOR  *
      *  groups in lgpolicy.cpy.                                       *
      *                                                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADDMPOL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REQUEST-FILE ASSIGN TO 'requests.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REQUEST-FS.
           SELECT POLICY-FILE  ASSIGN TO 'policy.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-POLICY-FS.
           SELECT MOTOR-FILE   ASSIGN TO 'motor.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-MOTOR-FS.
           SELECT ERROR-FILE   ASSIGN TO 'error.log'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ERROR-FS.

       DATA DIVISION.

      ******************************************************************
      *  F I L E   S E C T I O N                                       *
      ******************************************************************
       FILE SECTION.

      *----- Input request record (fixed-width, 143 chars) -------------*
      *  Layout mirrors the relevant subset of CA-MOTOR (lgcmarea.cpy)  *
      *  but without CA-M-PREMIUM (we compute it).                      *
      *-----------------------------------------------------------------*
       FD  REQUEST-FILE.
       01  REQUEST-RECORD.
           03 REQ-REQUEST-ID            PIC X(6).
           03 REQ-CUSTOMER-NUM          PIC 9(10).
           03 REQ-POLICY-NUM            PIC 9(10).
           03 REQ-ISSUE-DATE            PIC X(10).
           03 REQ-EXPIRY-DATE           PIC X(10).
           03 REQ-BROKER-ID             PIC 9(10).
           03 REQ-BROKERS-REF           PIC X(10).
           03 REQ-PAYMENT               PIC 9(6).
           03 REQ-MAKE                  PIC X(15).
           03 REQ-MODEL                 PIC X(15).
           03 REQ-VALUE                 PIC 9(6).
           03 REQ-REGNUMBER             PIC X(7).
           03 REQ-COLOUR                PIC X(8).
           03 REQ-CC                    PIC 9(4).
           03 REQ-MANUFACTURED          PIC X(10).
           03 REQ-ACCIDENTS             PIC 9(6).

      *----- Policy output (one parent row per accepted request) -------*
       FD  POLICY-FILE.
       01  POLICY-OUT-RECORD.
           03 POUT-POLICYNUMBER         PIC 9(10).
           03 POUT-CUSTOMERNUMBER       PIC 9(10).
           03 POUT-POLICYTYPE           PIC X.
           03 POUT-ISSUEDATE            PIC X(10).
           03 POUT-EXPIRYDATE           PIC X(10).
           03 POUT-BROKERID             PIC 9(10).
           03 POUT-BROKERSREF           PIC X(10).
           03 POUT-PAYMENT              PIC 9(6).

      *----- Motor output (one child row per accepted request) ---------*
       FD  MOTOR-FILE.
       01  MOTOR-OUT-RECORD.
           03 MOUT-POLICYNUMBER         PIC 9(10).
           03 MOUT-MAKE                 PIC X(15).
           03 MOUT-MODEL                PIC X(15).
           03 MOUT-VALUE                PIC 9(6).
           03 MOUT-REGNUMBER            PIC X(7).
           03 MOUT-COLOUR               PIC X(8).
           03 MOUT-CC                   PIC 9(4).
           03 MOUT-MANUFACTURED         PIC X(10).
           03 MOUT-PREMIUM              PIC 9(6).
           03 MOUT-ACCIDENTS            PIC 9(6).

      *----- Error log line --------------------------------------------*
       FD  ERROR-FILE.
       01  ERROR-RECORD                 PIC X(120).

      ******************************************************************
      *  W O R K I N G - S T O R A G E   S E C T I O N                 *
      ******************************************************************
       WORKING-STORAGE SECTION.

      *----- Eyecatcher (preserved from GenApp style) ------------------*
       01  WS-HEADER.
           03 WS-EYECATCHER             PIC X(16)
                                        VALUE 'ADDMPOL-------WS'.
           03 WS-PROGRAM-NAME           PIC X(8)
                                        VALUE 'ADDMPOL '.

      *----- File status codes -----------------------------------------*
       01  WS-FILE-STATUSES.
           03 WS-REQUEST-FS             PIC X(2) VALUE '00'.
           03 WS-POLICY-FS              PIC X(2) VALUE '00'.
           03 WS-MOTOR-FS               PIC X(2) VALUE '00'.
           03 WS-ERROR-FS               PIC X(2) VALUE '00'.

      *----- EOF flag --------------------------------------------------*
       01  WS-FLAGS.
           03 WS-EOF                    PIC X VALUE 'N'.
              88 EOF-REACHED            VALUE 'Y'.
              88 NOT-EOF                VALUE 'N'.

      *----- Per-request return code (matches GenApp CA-RETURN-CODE) ---*
       01  WS-RETURN-CODE               PIC 9(2) VALUE 0.
           88 RC-OK                     VALUE 0.
           88 RC-VALIDATION-ERR         VALUE 10.
           88 RC-PREMIUM-OVERFLOW       VALUE 11.
           88 RC-IO-ERR                 VALUE 90.
           88 RC-UNKNOWN-REQUEST        VALUE 99.

      *----- Counters (printed in summary) -----------------------------*
       01  WS-COUNTERS.
           03 WS-CNT-PROCESSED          PIC 9(6) VALUE 0.
           03 WS-CNT-INSERTED           PIC 9(6) VALUE 0.
           03 WS-CNT-REJECTED           PIC 9(6) VALUE 0.

      *----- Policy number generator (replaces DB2 IDENTITY) -----------*
       01  WS-NEXT-POLICYNUM            PIC 9(10) VALUE 1.

      *----- Premium calculation (BigDecimal in Java) ------------------*
       01  WS-CALC.
           03 WS-CALC-BASE              PIC 9(6)V99 VALUE 0.
           03 WS-CALC-VALUE-LOAD        PIC 9(6)V99 VALUE 0.
           03 WS-CALC-ACC-LOAD          PIC 9(6)V99 VALUE 0.
           03 WS-CALC-PREMIUM           PIC 9(6)V99 VALUE 0.
           03 WS-CALC-PREMIUM-INT       PIC 9(6) VALUE 0.

      *----- Per-request error message ---------------------------------*
       01  WS-ERROR-LINE.
           03 EM-CUSTOMER-NUM           PIC 9(10).
           03 FILLER                    PIC X     VALUE ' '.
           03 EM-REASON-CODE            PIC 9(2).
           03 FILLER                    PIC X     VALUE ' '.
           03 EM-REASON                 PIC X(106) VALUE SPACES.

      *----- Bring in the GenApp data dictionary -----------------------*
      *  We use DB2-POLICY and DB2-MOTOR layouts as logical references; *
      *  output records above intentionally mirror them.                *
       COPY LGPOLICY.

      ******************************************************************
      *  P R O C E D U R E   D I V I S I O N                           *
      ******************************************************************
       PROCEDURE DIVISION.

       MAIN-LOGIC SECTION.
           PERFORM INITIALIZE-RUN
           PERFORM PROCESS-REQUESTS UNTIL EOF-REACHED
           PERFORM FINALIZE-RUN
           PERFORM PRINT-SUMMARY
           STOP RUN.

      *================================================================*
       INITIALIZE-RUN.
           OPEN INPUT  REQUEST-FILE
           IF WS-REQUEST-FS NOT = '00'
               DISPLAY 'FATAL: cannot open requests.dat status='
                       WS-REQUEST-FS
               MOVE 90 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT POLICY-FILE
           OPEN OUTPUT MOTOR-FILE
           OPEN OUTPUT ERROR-FILE.

      *================================================================*
       PROCESS-REQUESTS.
           READ REQUEST-FILE
               AT END
                   SET EOF-REACHED TO TRUE
               NOT AT END
                   ADD 1 TO WS-CNT-PROCESSED
                   PERFORM HANDLE-ONE-REQUEST
           END-READ.

      *================================================================*
       HANDLE-ONE-REQUEST.
           SET RC-OK TO TRUE
           PERFORM CHECK-REQUEST-ID
           IF RC-OK
               PERFORM VALIDATE-REQUEST
           END-IF
           IF RC-OK
               PERFORM CALC-MOTOR-PREMIUM
           END-IF
           IF RC-OK
               PERFORM INSERT-POLICY
           END-IF
           IF RC-OK
               PERFORM INSERT-MOTOR
           END-IF
           IF RC-OK
               ADD 1 TO WS-CNT-INSERTED
               DISPLAY 'OK  CUST=' REQ-CUSTOMER-NUM
                       ' POL=' WS-NEXT-POLICYNUM
                       ' PREM=' WS-CALC-PREMIUM-INT
               ADD 1 TO WS-NEXT-POLICYNUM
           ELSE
               ADD 1 TO WS-CNT-REJECTED
               PERFORM REPORT-ERROR
           END-IF.

      *================================================================*
       CHECK-REQUEST-ID.
           IF REQ-REQUEST-ID NOT = '01AMOT'
               SET RC-UNKNOWN-REQUEST TO TRUE
               MOVE 'unknown request id'    TO EM-REASON
           END-IF.

      *================================================================*
       VALIDATE-REQUEST.
           EVALUATE TRUE
             WHEN REQ-CUSTOMER-NUM = 0
               SET RC-VALIDATION-ERR TO TRUE
               MOVE 'customer number is zero'  TO EM-REASON
             WHEN REQ-CC = 0
               SET RC-VALIDATION-ERR TO TRUE
               MOVE 'engine cc is zero'        TO EM-REASON
             WHEN REQ-VALUE = 0
               SET RC-VALIDATION-ERR TO TRUE
               MOVE 'vehicle value is zero'    TO EM-REASON
             WHEN REQ-ISSUE-DATE = SPACES
               SET RC-VALIDATION-ERR TO TRUE
               MOVE 'issue date is blank'      TO EM-REASON
             WHEN REQ-EXPIRY-DATE = SPACES
               SET RC-VALIDATION-ERR TO TRUE
               MOVE 'expiry date is blank'     TO EM-REASON
           END-EVALUATE.

      *================================================================*
      *  Premium = base(CC) + 0.5% * value + 50 * accidents             *
      *  Rounded half-even to whole currency to fit MOUT-PREMIUM 9(6).  *
      *================================================================*
       CALC-MOTOR-PREMIUM.
           EVALUATE TRUE
             WHEN REQ-CC <= 1000
               MOVE 200.00 TO WS-CALC-BASE
             WHEN REQ-CC <= 1600
               MOVE 350.00 TO WS-CALC-BASE
             WHEN REQ-CC <= 2000
               MOVE 500.00 TO WS-CALC-BASE
             WHEN OTHER
               MOVE 800.00 TO WS-CALC-BASE
           END-EVALUATE
           COMPUTE WS-CALC-VALUE-LOAD = REQ-VALUE * 0.005
           COMPUTE WS-CALC-ACC-LOAD   = REQ-ACCIDENTS * 50
           COMPUTE WS-CALC-PREMIUM    = WS-CALC-BASE
                                      + WS-CALC-VALUE-LOAD
                                      + WS-CALC-ACC-LOAD
               ON SIZE ERROR
                   SET RC-PREMIUM-OVERFLOW TO TRUE
                   MOVE 'premium overflowed PIC 9(6)V99' TO EM-REASON
           END-COMPUTE
           IF RC-OK
               COMPUTE WS-CALC-PREMIUM-INT ROUNDED =
                       WS-CALC-PREMIUM
                   ON SIZE ERROR
                       SET RC-PREMIUM-OVERFLOW TO TRUE
                       MOVE 'premium overflow on round' TO EM-REASON
               END-COMPUTE
           END-IF.

      *================================================================*
       INSERT-POLICY.
           MOVE WS-NEXT-POLICYNUM TO POUT-POLICYNUMBER
           MOVE REQ-CUSTOMER-NUM  TO POUT-CUSTOMERNUMBER
           MOVE 'M'               TO POUT-POLICYTYPE
           MOVE REQ-ISSUE-DATE    TO POUT-ISSUEDATE
           MOVE REQ-EXPIRY-DATE   TO POUT-EXPIRYDATE
           MOVE REQ-BROKER-ID     TO POUT-BROKERID
           MOVE REQ-BROKERS-REF   TO POUT-BROKERSREF
           MOVE REQ-PAYMENT       TO POUT-PAYMENT
           WRITE POLICY-OUT-RECORD
           IF WS-POLICY-FS NOT = '00'
               SET RC-IO-ERR TO TRUE
               MOVE 'write policy.dat failed' TO EM-REASON
           END-IF.

      *================================================================*
       INSERT-MOTOR.
           MOVE WS-NEXT-POLICYNUM TO MOUT-POLICYNUMBER
           MOVE REQ-MAKE          TO MOUT-MAKE
           MOVE REQ-MODEL         TO MOUT-MODEL
           MOVE REQ-VALUE         TO MOUT-VALUE
           MOVE REQ-REGNUMBER     TO MOUT-REGNUMBER
           MOVE REQ-COLOUR        TO MOUT-COLOUR
           MOVE REQ-CC            TO MOUT-CC
           MOVE REQ-MANUFACTURED  TO MOUT-MANUFACTURED
           MOVE WS-CALC-PREMIUM-INT TO MOUT-PREMIUM
           MOVE REQ-ACCIDENTS     TO MOUT-ACCIDENTS
           WRITE MOTOR-OUT-RECORD
           IF WS-MOTOR-FS NOT = '00'
               SET RC-IO-ERR TO TRUE
               MOVE 'write motor.dat failed' TO EM-REASON
           END-IF.

      *================================================================*
       REPORT-ERROR.
           MOVE REQ-CUSTOMER-NUM TO EM-CUSTOMER-NUM
           MOVE WS-RETURN-CODE   TO EM-REASON-CODE
           WRITE ERROR-RECORD FROM WS-ERROR-LINE
           DISPLAY 'ERR CUST=' REQ-CUSTOMER-NUM
                   ' RC=' WS-RETURN-CODE
                   ' ' EM-REASON.

      *================================================================*
       FINALIZE-RUN.
           CLOSE REQUEST-FILE
           CLOSE POLICY-FILE
           CLOSE MOTOR-FILE
           CLOSE ERROR-FILE.

      *================================================================*
       PRINT-SUMMARY.
           DISPLAY 'SUMMARY processed=' WS-CNT-PROCESSED
                   ' inserted=' WS-CNT-INSERTED
                   ' rejected=' WS-CNT-REJECTED.
