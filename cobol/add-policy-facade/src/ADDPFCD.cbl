*> ******************************************************************
*> *                                                                *
*> *  ADDPFCD - ADD POLICY FACADE (orchestrator chain)              *
*> *                                                                *
*> *  Carved from cicsdev/cics-genapp LGAPOL01 + LGAPDB01.          *
*> *  Demonstrates the CICS-LINK orchestrator pattern:              *
*> *                                                                *
*> *    Outer ADDPFCD validates each request, then CALLs the        *
*> *    nested ADDPOLDB-INSERT program (the equivalent of           *
*> *    EXEC CICS LINK PROGRAM("LGAPDB01")) to perform the          *
*> *    actual SQL INSERT through the libcob_sqlite shim.           *
*> *                                                                *
*> *  Provenance: see cobol/add-policy-facade/README.md             *
*> ******************************************************************
IDENTIFICATION DIVISION.
PROGRAM-ID. ADDPFCD.

ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT REQUEST-FILE ASSIGN TO 'requests.dat'
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-REQUEST-FS.

DATA DIVISION.

FILE SECTION.
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

01 WS-EYECATCHER     PIC X(16) VALUE 'ADDPFCD------WS '.

01 WS-REQUEST-FS     PIC X(2)  VALUE '00'.
01 WS-EOF            PIC X     VALUE 'N'.
   88 EOF-REACHED    VALUE 'Y'.

01 WS-DB-PATH        PIC X(256) VALUE 'out/policy.db'.
01 WS-DUMP-PATH      PIC X(256) VALUE 'out/policy.csv'.
01 WS-TABLE          PIC X(64)  VALUE 'POLICY'.

01 WS-SQL            PIC X(1024).
01 WS-RC             PIC S9(9) COMP-5.
01 WS-CA-RC          PIC 9(2).

01 WS-COUNTERS.
   03 WS-CNT-PROCESSED  PIC 9(6) VALUE 0.
   03 WS-CNT-INSERTED   PIC 9(6) VALUE 0.
   03 WS-CNT-REJECTED   PIC 9(6) VALUE 0.

01 WS-MSG-POLNUM     PIC 9(10).

*> Parameters passed to the nested ADDPOLDB-INSERT program. Layout
*> mirrors CA-POLICY-COMMON + CA-POLICY-NUM (lgcmarea.cpy:34-43).
01 LK-INSERT-PARAMS.
   03 LK-POLICY-NUM     PIC 9(10).
   03 LK-CUSTOMER-NUM   PIC 9(10).
   03 LK-ISSUE-DATE     PIC X(10).
   03 LK-EXPIRY-DATE    PIC X(10).
   03 LK-POLICY-TYPE    PIC X(1).
   03 LK-LASTCHANGED    PIC X(26).
   03 LK-BROKER-ID      PIC 9(10).
   03 LK-BROKERS-REF    PIC X(10).
   03 LK-PAYMENT        PIC 9(6).

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
        PERFORM FACADE-HANDLE
        PERFORM READ-RECORD
    END-PERFORM

    CLOSE REQUEST-FILE

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

*> COBOL: lgapol01.cbl:80-126 (MAINLINE SECTION)
*>   Original validated commarea length (RC=98 if too short). Batch
*>   mode validates field presence instead: policy_num must be > 0
*>   (the original used DB2 DEFAULT for auto-assign; module 1B
*>   requires fixture-controlled PKs).
FACADE-HANDLE.
    MOVE REQ-POLICY-NUM TO WS-MSG-POLNUM

    IF REQ-POLICY-NUM = 0
        ADD 1 TO WS-CNT-REJECTED
        MOVE 98 TO WS-CA-RC
        DISPLAY 'ERR  POLNUM=' WS-MSG-POLNUM ' RC=' WS-CA-RC
        EXIT PARAGRAPH
    END-IF

    *> Copy request fields into linkage block and CALL the nested
    *> insert program. This is the GnuCOBOL equivalent of
    *>   EXEC CICS LINK PROGRAM("LGAPDB01") COMMAREA(...)
    MOVE REQ-POLICY-NUM    TO LK-POLICY-NUM
    MOVE REQ-CUSTOMER-NUM  TO LK-CUSTOMER-NUM
    MOVE REQ-ISSUE-DATE    TO LK-ISSUE-DATE
    MOVE REQ-EXPIRY-DATE   TO LK-EXPIRY-DATE
    MOVE REQ-POLICY-TYPE   TO LK-POLICY-TYPE
    MOVE REQ-LASTCHANGED   TO LK-LASTCHANGED
    MOVE REQ-BROKER-ID     TO LK-BROKER-ID
    MOVE REQ-BROKERS-REF   TO LK-BROKERS-REF
    MOVE REQ-PAYMENT       TO LK-PAYMENT

    CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC

    IF WS-RC = 0
        ADD 1 TO WS-CNT-INSERTED
        DISPLAY 'OK   POLNUM=' WS-MSG-POLNUM
    ELSE
        ADD 1 TO WS-CNT-REJECTED
        DISPLAY 'ERR  POLNUM=' WS-MSG-POLNUM ' RC=' WS-RC
    END-IF.

*> ******************************************************************
*> *  ADDPOLDB-INSERT - nested program; the DB-insert routine       *
*> *  invoked by the facade (CICS LINK PROGRAM("LGAPDB01") in the   *
*> *  original). Mirrors INSERT-POLICY at lgapdb01.cbl:261-322.     *
*> ******************************************************************
IDENTIFICATION DIVISION.
PROGRAM-ID. ADDPOLDB-INSERT IS COMMON.

DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-SQL-INNER      PIC X(1024).
01 WS-INNER-RC       PIC S9(9) COMP-5.

LINKAGE SECTION.
01 LK-PARAMS.
   03 LK-IN-POLICY-NUM   PIC 9(10).
   03 LK-IN-CUSTOMER-NUM PIC 9(10).
   03 LK-IN-ISSUE-DATE   PIC X(10).
   03 LK-IN-EXPIRY-DATE  PIC X(10).
   03 LK-IN-POLICY-TYPE  PIC X(1).
   03 LK-IN-LASTCHANGED  PIC X(26).
   03 LK-IN-BROKER-ID    PIC 9(10).
   03 LK-IN-BROKERS-REF  PIC X(10).
   03 LK-IN-PAYMENT      PIC 9(6).

PROCEDURE DIVISION USING LK-PARAMS.
    MOVE SPACES TO WS-SQL-INNER
    STRING
        "INSERT INTO POLICY VALUES ("
        LK-IN-POLICY-NUM      ","
        LK-IN-CUSTOMER-NUM    ",'"
        LK-IN-ISSUE-DATE      "','"
        LK-IN-EXPIRY-DATE     "','"
        LK-IN-POLICY-TYPE     "','"
        LK-IN-LASTCHANGED     "',"
        LK-IN-BROKER-ID       ",'"
        FUNCTION TRIM(LK-IN-BROKERS-REF) "',"
        LK-IN-PAYMENT         ")"
        DELIMITED BY SIZE
        INTO WS-SQL-INNER
    END-STRING

    CALL "cob_sqlite_exec" USING WS-SQL-INNER RETURNING WS-INNER-RC
    MOVE WS-INNER-RC TO RETURN-CODE.
    GOBACK.

END PROGRAM ADDPOLDB-INSERT.
END PROGRAM ADDPFCD.
