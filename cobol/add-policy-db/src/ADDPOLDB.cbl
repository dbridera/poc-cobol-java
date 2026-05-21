*> ******************************************************************
*> *                                                                *
*> *  ADDPOLDB - ADD POLICY (DB row), batch, GnuCOBOL-runnable      *
*> *                                                                *
*> *  Carved from cicsdev/cics-genapp LGAPDB01 INSERT-POLICY        *
*> *  paragraph (lines 261-322). See cobol/add-policy-db/README.md  *
*> *  for what was kept, adapted, and removed.                      *
*> *                                                                *
*> *  Reads requests.dat (fixed-width 99-char records), INSERTs one *
*> *  row per request into the SQLite POLICY table via libcob_sqlite*
*> *  (the GIXSQL-equivalent shim from tools/spike/cob_sqlite.c),   *
*> *  then dumps the table to out/policy.csv for byte-exact diff.   *
*> *                                                                *
*> *  Compile + run:                                                *
*> *    ./tools/run-cobol-db.sh add-policy-db                       *
*> ******************************************************************
IDENTIFICATION DIVISION.
PROGRAM-ID. ADDPOLDB.

ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT REQUEST-FILE ASSIGN TO 'requests.dat'
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-REQUEST-FS.

DATA DIVISION.

FILE SECTION.
*> Fixed-width request record (99 chars).
*>   Mirrors the subset of CA-POLICY-COMMON the INSERT-POLICY paragraph
*>   uses, plus the fixture-controlled PK and LASTCHANGED.
FD  REQUEST-FILE.
01 REQUEST-RECORD.
   03 REQ-REQUEST-ID     PIC X(6).
   03 REQ-POLICY-NUM     PIC 9(10).
   03 REQ-CUSTOMER-NUM   PIC 9(10).
   03 REQ-ISSUE-DATE     PIC X(10).
   03 REQ-EXPIRY-DATE    PIC X(10).
   03 REQ-POLICY-TYPE    PIC X(1).
   03 REQ-LASTCHANGED    PIC X(26).
   03 REQ-BROKER-ID      PIC 9(10).
   03 REQ-BROKERS-REF    PIC X(10).
   03 REQ-PAYMENT        PIC 9(6).

WORKING-STORAGE SECTION.

01 WS-EYECATCHER     PIC X(16) VALUE 'ADDPOLDB------WS'.

01 WS-REQUEST-FS     PIC X(2)  VALUE '00'.
01 WS-EOF            PIC X     VALUE 'N'.
   88 EOF-REACHED    VALUE 'Y'.

01 WS-DB-PATH        PIC X(256) VALUE 'out/policy.db'.
01 WS-DUMP-PATH      PIC X(256) VALUE 'out/policy.csv'.
01 WS-TABLE          PIC X(64)  VALUE 'POLICY'.

01 WS-SQL            PIC X(1024).
01 WS-RC             PIC S9(9) COMP-5.

01 WS-COUNTERS.
   03 WS-CNT-PROCESSED  PIC 9(6) VALUE 0.
   03 WS-CNT-INSERTED   PIC 9(6) VALUE 0.
   03 WS-CNT-REJECTED   PIC 9(6) VALUE 0.

01 WS-MSG.
   03 FILLER            PIC X(4) VALUE 'OK  '.
   03 WS-MSG-POLNUM     PIC 9(10).

PROCEDURE DIVISION.

MAIN.
    *> Open the database and create the POLICY table from scratch.
    CALL "cob_sqlite_open" USING WS-DB-PATH RETURNING WS-RC
    IF WS-RC NOT = 0
        DISPLAY 'OPEN FAILED'
        STOP RUN RETURNING 1
    END-IF

    MOVE 'DROP TABLE IF EXISTS POLICY' TO WS-SQL
    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC

    MOVE 'CREATE TABLE POLICY (POLICYNUMBER BIGINT PRIMARY KEY, CUSTOMERNUMBER BIGINT NOT NULL, ISSUEDATE TEXT NOT NULL, EXPIRYDATE TEXT NOT NULL, POLICYTYPE TEXT NOT NULL, LASTCHANGED TEXT NOT NULL, BROKERID BIGINT NOT NULL, BROKERSREFERENCE TEXT NOT NULL, PAYMENT INTEGER NOT NULL)' TO WS-SQL
    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC
    IF WS-RC NOT = 0
        DISPLAY 'CREATE FAILED'
        STOP RUN RETURNING 1
    END-IF

    OPEN INPUT REQUEST-FILE
    IF WS-REQUEST-FS NOT = '00'
        DISPLAY 'OPEN REQUEST-FILE failed, FS=' WS-REQUEST-FS
        STOP RUN RETURNING 1
    END-IF

    PERFORM READ-RECORD
    PERFORM UNTIL EOF-REACHED
        ADD 1 TO WS-CNT-PROCESSED
        PERFORM INSERT-POLICY
        PERFORM READ-RECORD
    END-PERFORM

    CLOSE REQUEST-FILE

    *> Dump POLICY table to out/policy.csv (deterministic, sorted by PK).
    CALL "cob_sqlite_dump" USING WS-TABLE WS-DUMP-PATH RETURNING WS-RC
    IF WS-RC NOT = 0
        DISPLAY 'DUMP FAILED'
        STOP RUN RETURNING 1
    END-IF

    CALL "cob_sqlite_close" RETURNING WS-RC

    DISPLAY 'PROCESSED=' WS-CNT-PROCESSED
            ' INSERTED=' WS-CNT-INSERTED
            ' REJECTED=' WS-CNT-REJECTED
    STOP RUN RETURNING 0.

READ-RECORD.
    READ REQUEST-FILE
        AT END SET EOF-REACHED TO TRUE
    END-READ.

*> COBOL: lgapdb01.cbl:261-322 (INSERT-POLICY paragraph)
*>   Original used DB2 DEFAULT for auto-PK and CURRENT TIMESTAMP for
*>   LASTCHANGED; we receive both from the request for byte-exact
*>   reproducibility (see README "Adapted" section).
INSERT-POLICY.
    *> Clear WS-SQL so leftover bytes from the prior MOVE/STRING don't
    *> bleed into the new statement (the shim trims trailing spaces,
    *> not embedded non-space junk).
    MOVE SPACES TO WS-SQL
    STRING
        "INSERT INTO POLICY VALUES ("
        REQ-POLICY-NUM
        ","
        REQ-CUSTOMER-NUM
        ",'"
        REQ-ISSUE-DATE
        "','"
        REQ-EXPIRY-DATE
        "','"
        REQ-POLICY-TYPE
        "','"
        REQ-LASTCHANGED
        "',"
        REQ-BROKER-ID
        ",'"
        FUNCTION TRIM(REQ-BROKERS-REF)
        "',"
        REQ-PAYMENT
        ")"
        DELIMITED BY SIZE
        INTO WS-SQL
    END-STRING

    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC
    MOVE REQ-POLICY-NUM TO WS-MSG-POLNUM
    IF WS-RC = 0
        ADD 1 TO WS-CNT-INSERTED
        DISPLAY 'OK   POLNUM=' WS-MSG-POLNUM
    ELSE
        ADD 1 TO WS-CNT-REJECTED
        DISPLAY 'ERR  POLNUM=' WS-MSG-POLNUM ' RC=' WS-RC
    END-IF.
