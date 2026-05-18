*> ******************************************************************
*> *  HELLO-DB - module 1 spike, COBOL side                         *
*> *                                                                *
*> *  Proves COBOL on GnuCOBOL can drive a SQL database through     *
*> *  CALL "cob_sqlite_*" to libcob_sqlite.dylib (wraps libsqlite3).*
*> *                                                                *
*> *  In production this would be EXEC SQL routed through GIXSQL.   *
*> *  The shim emits the same shape of side-effects: row inserted,  *
*> *  table dumped to a deterministic text file.                    *
*> *                                                                *
*> *  Compile in free format:                                       *
*> *    cobc -free -x hello-db.cbl -L. -lcob_sqlite \               *
*> *         -L/usr/local/opt/sqlite/lib                            *
*> ******************************************************************
IDENTIFICATION DIVISION.
PROGRAM-ID. HELLO-DB.

DATA DIVISION.
WORKING-STORAGE SECTION.

01 WS-DB-PATH    PIC X(256) VALUE 'out/spike.db'.
01 WS-DUMP-PATH  PIC X(256) VALUE 'out/widget.txt'.
01 WS-TABLE      PIC X(64)  VALUE 'WIDGET'.

01 WS-SQL        PIC X(512).
01 WS-RC         PIC S9(9) COMP-5.

PROCEDURE DIVISION.

    CALL "cob_sqlite_open" USING WS-DB-PATH RETURNING WS-RC
    IF WS-RC NOT = 0
        DISPLAY 'OPEN FAILED'
        STOP RUN RETURNING 1
    END-IF

    MOVE 'DROP TABLE IF EXISTS WIDGET' TO WS-SQL
    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC

    MOVE 'CREATE TABLE WIDGET (id INT PRIMARY KEY, name TEXT, ts TEXT)' TO WS-SQL
    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC
    IF WS-RC NOT = 0
        STOP RUN RETURNING 1
    END-IF

    MOVE "INSERT INTO WIDGET VALUES (1,'first','2026-01-01 00:00:00')" TO WS-SQL
    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC
    IF WS-RC NOT = 0
        STOP RUN RETURNING 1
    END-IF

    MOVE "INSERT INTO WIDGET VALUES (2,'second','2026-01-01 00:00:00')" TO WS-SQL
    CALL "cob_sqlite_exec" USING WS-SQL RETURNING WS-RC
    IF WS-RC NOT = 0
        STOP RUN RETURNING 1
    END-IF

    CALL "cob_sqlite_dump" USING WS-TABLE WS-DUMP-PATH RETURNING WS-RC
    IF WS-RC NOT = 0
        STOP RUN RETURNING 1
    END-IF

    CALL "cob_sqlite_close" RETURNING WS-RC
    DISPLAY 'WIDGETS INSERTED OK'
    STOP RUN RETURNING 0.
