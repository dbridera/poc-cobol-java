      ******************************************************************
      * CEE3ABD — ADDED stub (not part of CardDemo).                   *
      *                                                                *
      * On z/OS, CEE3ABD is the Language Environment service that      *
      * terminates the enclave with a user abend (U0999 here). GnuCOBOL *
      * has no LE, so this stub reproduces the only two observable      *
      * effects the batch job depends on: the program stops right here  *
      * (the PERFORMed abend paragraph never returns) and the step ends  *
      * with a non-zero return code. RC 12 is the job manifest's abend   *
      * code (job.json: steps[].rc_ok).                                  *
      *                                                                *
      * Callers: CBTRN02C.cbl 9999-ABEND-PROGRAM (711),                 *
      *          CBACT04C.cbl 9999-ABEND-PROGRAM (632),                 *
      *          CBTRN03C.cbl 9999-ABEND-PROGRAM.                       *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CEE3ABD.
       DATA DIVISION.
       LINKAGE SECTION.
       01  ABCODE  PIC S9(9) BINARY.
       01  TIMING  PIC S9(9) BINARY.
       PROCEDURE DIVISION USING ABCODE TIMING.
           DISPLAY 'CEE3ABD: USER ABEND U' ABCODE
           MOVE 12 TO RETURN-CODE
           STOP RUN.
