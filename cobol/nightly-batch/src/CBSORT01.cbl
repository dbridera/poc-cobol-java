      ******************************************************************
      * CBSORT01 — ADDED (not part of CardDemo).                       *
      *                                                                *
      * Stand-in for COMBTRAN.jcl STEP05R (DFSORT):                    *
      *     SORTIN  = TRANSACT.BKUP(0) + SYSTRAN(0)  (concatenated)     *
      *     SYMNAMES: TRAN-ID,1,16,CH                                   *
      *     SORT FIELDS=(TRAN-ID,A)                                     *
      *     SORTOUT = TRANSACT.COMBINED(+1)                             *
      * Records are the 350-byte TRAN-RECORD of CVTRA05Y. TRAN-ID is   *
      * unique across both inputs, so the order is fully determined.    *
      * The following REPRO (STEP10) is the generated LOAD-TRANSACT.    *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBSORT01.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SORTIN1 ASSIGN TO SORTIN1
               ORGANIZATION IS SEQUENTIAL.
           SELECT SORTIN2 ASSIGN TO SORTIN2
               ORGANIZATION IS SEQUENTIAL.
           SELECT SORTOUT ASSIGN TO SORTOUT
               ORGANIZATION IS SEQUENTIAL.
           SELECT SORTWK  ASSIGN TO SORTWK.
       DATA DIVISION.
       FILE SECTION.
       FD  SORTIN1.
       01  IN1-REC             PIC X(350).
       FD  SORTIN2.
       01  IN2-REC             PIC X(350).
       FD  SORTOUT.
       01  OUT-REC             PIC X(350).
       SD  SORTWK.
       01  SORT-REC.
           05  SORT-TRAN-ID    PIC X(16).
           05  FILLER          PIC X(334).
       PROCEDURE DIVISION.
           SORT SORTWK ON ASCENDING KEY SORT-TRAN-ID
                USING SORTIN1 SORTIN2
                GIVING SORTOUT
           IF SORT-RETURN NOT = 0
              DISPLAY 'CBSORT01: SORT FAILED SORT-RETURN=' SORT-RETURN
              MOVE 16 TO RETURN-CODE
           ELSE
              DISPLAY 'CBSORT01: SORT COMPLETE'
           END-IF
           GOBACK.
