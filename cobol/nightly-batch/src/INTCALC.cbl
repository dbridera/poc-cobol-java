      ******************************************************************
      * INTCALC — ADDED driver (not part of CardDemo).                 *
      *                                                                *
      * Stand-in for INTCALC.jcl:                                      *
      *     //STEP15 EXEC PGM=CBACT04C,PARM='2022071800'                *
      *                                                                *
      * z/OS hands PARM to the program as a halfword length followed   *
      * by the text, which CBACT04C receives through                   *
      * PROCEDURE DIVISION USING EXTERNAL-PARMS (CBACT04C.cbl:175-181). *
      * A GnuCOBOL main program compiled with -x gets no such argument, *
      * so this driver builds the identical structure from the PARM    *
      * environment variable (set by tools/run-job.py from job.json)   *
      * and CALLs the unmodified CBACT04C statically linked into the   *
      * same executable.                                               *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTCALC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PARM-TEXT        PIC X(100) VALUE SPACES.
       01  EXTERNAL-PARMS.
           05  PARM-LENGTH     PIC S9(04) COMP.
           05  PARM-DATE       PIC X(10).
       PROCEDURE DIVISION.
           ACCEPT WS-PARM-TEXT FROM ENVIRONMENT 'PARM'
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-PARM-TEXT TRAILING))
             TO PARM-LENGTH
           MOVE WS-PARM-TEXT(1:10) TO PARM-DATE
           CALL 'CBACT04C' USING EXTERNAL-PARMS
           GOBACK.
