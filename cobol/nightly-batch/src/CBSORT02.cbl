      ******************************************************************
      * CBSORT02 — ADDED (not part of CardDemo).                       *
      *                                                                *
      * Stand-in for TRANREPT.jcl STEP05R (DFSORT):                    *
      *     SYMNAMES: TRAN-CARD-NUM,263,16,ZD                           *
      *               TRAN-PROC-DT,305,10,CH                            *
      *               PARM-START-DATE,C'2022-01-01'                     *
      *               PARM-END-DATE,C'2022-07-06'                       *
      *     SORT FIELDS=(TRAN-CARD-NUM,A)                               *
      *     INCLUDE COND=(TRAN-PROC-DT,GE,PARM-START-DATE,AND,           *
      *                   TRAN-PROC-DT,LE,PARM-END-DATE)                *
      *                                                                *
      * Two documented adaptations:                                    *
      *  1. The date range is read from the DATEPARM file (the same    *
      *     80-byte record CBTRN03C reads) instead of being hard-coded  *
      *     in SYMNAMES, so one fixture drives both the sort and the    *
      *     report.                                                    *
      *  2. DFSORT without OPTION EQUALS leaves the order of records    *
      *     with equal card numbers unspecified. A secondary key on     *
      *     TRAN-ID (unique) makes the order deterministic so the       *
      *     report can be diffed byte for byte.                         *
      * ZD vs CH on an all-digit 16-char key compares identically.      *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBSORT02.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SORTIN   ASSIGN TO SORTIN
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SORTIN-STATUS.
           SELECT DATEPARM ASSIGN TO DATEPARM
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-DATEPARM-STATUS.
           SELECT SORTOUT  ASSIGN TO SORTOUT
               ORGANIZATION IS SEQUENTIAL.
           SELECT SORTWK   ASSIGN TO SORTWK.
       DATA DIVISION.
       FILE SECTION.
       FD  SORTIN.
       01  IN-REC              PIC X(350).
       FD  DATEPARM.
       01  DATEPARM-REC        PIC X(80).
       FD  SORTOUT.
       01  OUT-REC             PIC X(350).
       SD  SORTWK.
       01  SORT-REC.
           05  SORT-TRAN-ID    PIC X(16).
           05  FILLER          PIC X(246).
           05  SORT-CARD-NUM   PIC X(16).
           05  FILLER          PIC X(26).
           05  SORT-PROC-TS    PIC X(26).
           05  FILLER          PIC X(20).
       WORKING-STORAGE SECTION.
       01  WS-SORTIN-STATUS    PIC XX.
       01  WS-DATEPARM-STATUS  PIC XX.
       01  WS-DATEPARM-RECORD.
           05  WS-START-DATE   PIC X(10).
           05  FILLER          PIC X(01).
           05  WS-END-DATE     PIC X(10).
       01  WS-EOF              PIC X VALUE 'N'.
       01  WS-READ             PIC 9(09) VALUE 0.
       01  WS-SELECTED         PIC 9(09) VALUE 0.
       PROCEDURE DIVISION.
       MAIN.
           OPEN INPUT DATEPARM
           IF WS-DATEPARM-STATUS NOT = '00'
              DISPLAY 'CBSORT02: OPEN DATEPARM FAILED STATUS '
                      WS-DATEPARM-STATUS
              MOVE 12 TO RETURN-CODE
              GOBACK
           END-IF
           READ DATEPARM INTO WS-DATEPARM-RECORD
              AT END
                 DISPLAY 'CBSORT02: DATEPARM IS EMPTY'
                 MOVE 12 TO RETURN-CODE
                 GOBACK
           END-READ
           CLOSE DATEPARM
           SORT SORTWK ON ASCENDING KEY SORT-CARD-NUM
                                        SORT-TRAN-ID
                INPUT PROCEDURE IS SELECT-RECORDS
                GIVING SORTOUT
           IF SORT-RETURN NOT = 0
              DISPLAY 'CBSORT02: SORT FAILED SORT-RETURN=' SORT-RETURN
              MOVE 16 TO RETURN-CODE
           ELSE
              DISPLAY 'CBSORT02: SELECTED ' WS-SELECTED ' OF '
                      WS-READ ' RECORDS FOR ' WS-START-DATE
                      ' TO ' WS-END-DATE
           END-IF
           GOBACK.
       SELECT-RECORDS.
           OPEN INPUT SORTIN
           IF WS-SORTIN-STATUS NOT = '00'
              DISPLAY 'CBSORT02: OPEN SORTIN FAILED STATUS '
                      WS-SORTIN-STATUS
              MOVE 12 TO RETURN-CODE
              STOP RUN
           END-IF
           PERFORM UNTIL WS-EOF = 'Y'
              READ SORTIN
                 AT END MOVE 'Y' TO WS-EOF
                 NOT AT END
                    ADD 1 TO WS-READ
                    IF IN-REC(305:10) >= WS-START-DATE
                       AND IN-REC(305:10) <= WS-END-DATE
                       MOVE IN-REC TO SORT-REC
                       RELEASE SORT-REC
                       ADD 1 TO WS-SELECTED
                    END-IF
              END-READ
           END-PERFORM
           CLOSE SORTIN.
