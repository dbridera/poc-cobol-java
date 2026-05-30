# cobol/add-policy-facade — Dependency Map

Asset inventory for the `add-policy-facade` module (module 1A — CICS LINK orchestrator pattern). Hand-authored as part of Phase A per [`.claude/skills/cobol-analyze/SKILL.md`](../../.claude/skills/cobol-analyze/SKILL.md) §4.5.

For business meaning and the EXEC CICS LINK → nested-PROGRAM-ID + Spring DI adaptation, see the prose [README.md](./README.md).

---

## 1. Programs

| PROGRAM-ID | Source | Entry signature | Role | Notes |
|---|---|---|---|---|
| `ADDPFCD` | [`src/ADDPFCD.cbl`](./src/ADDPFCD.cbl) (lines 15–215) | `MAIN` (no USING) | top-level batch / facade | carve of GenApp `LGAPOL01` (MAINLINE) |
| `ADDPOLDB-INSERT` | nested in `ADDPFCD.cbl` (lines 173–214) `IS COMMON` | `USING LK-PARAMS` | nested callee | GnuCOBOL local equivalent of `EXEC CICS LINK PROGRAM("LGAPDB01")`; carved from GenApp `LGAPDB01` INSERT-POLICY |

`IS COMMON` makes `ADDPOLDB-INSERT` callable from outside its containing program by the `CALL` linker.

---

## 2. Paragraph PERFORM tree

### Program: `ADDPFCD` (outer / facade)

```
MAIN                                                 (entry, STOP RUN at end)
├── CALL "cob_sqlite_open"   USING WS-DB-PATH        [external shim — see §6]
├── CALL "cob_sqlite_exec"   (DROP TABLE IF EXISTS POLICY)
├── CALL "cob_sqlite_exec"   (CREATE TABLE POLICY ...)
├── OPEN INPUT REQUEST-FILE
├── READ-RECORD                                      (PERFORM, then re-PERFORMed in loop)
└── (loop UNTIL EOF-REACHED)
    ├── FACADE-HANDLE
    │   ├── (early-return) IF REQ-POLICY-NUM = 0 → emit ERR + EXIT PARAGRAPH    (RC=98 facade-level reject)
    │   ├── (copy 9 request fields into LK-INSERT-PARAMS)
    │   └── CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC       [external — nested, see §3]
    └── READ-RECORD
├── CLOSE REQUEST-FILE
├── CALL "cob_sqlite_dump"   USING WS-TABLE WS-DUMP-PATH
├── CALL "cob_sqlite_close"
└── DISPLAY summary line (PROCESSED / INSERTED / REJECTED)
```

### Program: `ADDPOLDB-INSERT` (nested / inner)

```
(PROCEDURE DIVISION USING LK-PARAMS)                 (entry, GOBACK at end)
├── MOVE SPACES TO WS-SQL-INNER
├── STRING ... INTO WS-SQL-INNER                     (compose INSERT statement from LK-IN-* fields)
└── CALL "cob_sqlite_exec" USING WS-SQL-INNER RETURNING WS-INNER-RC  [external — see §6]
    └── MOVE WS-INNER-RC TO RETURN-CODE              (propagates back to facade WS-RC)
```

No `PERFORM ... THRU` in either program. No `GO TO`. `FACADE-HANDLE` uses `EXIT PARAGRAPH` for early-return on `REQ-POLICY-NUM = 0` (the EIBCALEN-length-check equivalent — see [README.md](./README.md) "Adapted").

---

## 3. External program calls

| Caller paragraph | Call type | Target | Notes |
|---|---|---|---|
| `FACADE-HANDLE` (in ADDPFCD) | `CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC` | nested `ADDPOLDB-INSERT` (same compile unit) | **GnuCOBOL local equivalent of `EXEC CICS LINK PROGRAM("LGAPDB01") COMMAREA(...)`** — see [README.md](./README.md) "Adapted" and [docs/methodology/DECISIONS.md ADR-10](../../docs/methodology/DECISIONS.md) |
| `MAIN` (in ADDPFCD) | `CALL "cob_sqlite_open / _exec / _dump / _close"` | C shim symbols (libcob_sqlite) | shared shim — see §6 |
| `ADDPOLDB-INSERT` (nested) | `CALL "cob_sqlite_exec" USING WS-SQL-INNER` | C shim | one INSERT per record (the actual SQL work) |

---

## 4. Copybook usage

none — no `COPY` statements. The request layout, facade commarea, and nested LINKAGE record are all defined inline. The nested `LK-PARAMS` mirrors the relevant subset of GenApp's `lgcmarea.cpy` `CA-POLICY-COMMON + CA-POLICY-NUM` (see comment block at [`src/ADDPFCD.cbl:64-65`](./src/ADDPFCD.cbl#L64-L65)), but is not pulled in via COPY.

---

## 5. File / VSAM dependencies

| Logical name | File path | ORGANIZATION | OPEN mode | Format / width |
|---|---|---|---|---|
| `REQUEST-FILE` | `requests.dat` | LINE SEQUENTIAL | INPUT | fixed-width 99 chars/record (same layout as module 1B) |
| (out) `out/policy.db` | `out/policy.db` (SQLite binary) | n/a (managed by `cob_sqlite_open`) | created/truncated per run | SQLite DB file — not a COBOL FD |
| (out) `out/policy.csv` | `out/policy.csv` | n/a (written by `cob_sqlite_dump`) | OUTPUT | deterministic table dump, sorted by `POLICYNUMBER` PK; the byte-exact diff target |

Same shape as module 1B; the chain is what's being proven, not new file I/O.

---

## 6. EXEC SQL / database dependencies

Same SQLite shim shape as module 1B ([`add-policy-db/DEPENDENCIES.md` §6](../add-policy-db/DEPENDENCIES.md)). All SQL work is done by the **nested** `ADDPOLDB-INSERT` program; the facade does no SQL itself beyond schema init.

| Statement type | Issued by | Table | Columns / cursor | Host variables / source fields |
|---|---|---|---|---|
| `DROP TABLE IF EXISTS POLICY` | `ADDPFCD.MAIN` | `POLICY` | n/a | (literal) |
| `CREATE TABLE POLICY` | `ADDPFCD.MAIN` | `POLICY` | 9 columns (identical schema to module 1B) | (literal DDL) |
| `INSERT INTO POLICY VALUES (...)` (one per request) | `ADDPOLDB-INSERT` (nested) | `POLICY` | 9 columns, positional | `LK-IN-POLICY-NUM`, `LK-IN-CUSTOMER-NUM`, `LK-IN-ISSUE-DATE`, `LK-IN-EXPIRY-DATE`, `LK-IN-POLICY-TYPE`, `LK-IN-LASTCHANGED`, `LK-IN-BROKER-ID`, `FUNCTION TRIM(LK-IN-BROKERS-REF)`, `LK-IN-PAYMENT` |

Shim symbols invoked: `cob_sqlite_open`, `cob_sqlite_exec` (3× — DROP/CREATE/INSERT), `cob_sqlite_dump`, `cob_sqlite_close`. All resolve to [`tools/spike/cob_sqlite.c`](../../tools/spike/cob_sqlite.c).

---

## 7. EXEC CICS / runtime calls

All CICS calls in the GenApp ancestor were removed during the carve. The compiled binary contains **zero** CICS API references. Citing [README.md](./README.md) "Adapted":

| Original CICS construct | Adaptation status | Replaced with |
|---|---|---|
| `EXEC CICS LINK PROGRAM("LGAPDB01") COMMAREA(...)` | **REPLACED** | `CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC` (nested program) |
| `EXEC CICS ABEND ABCODE(...)` | **REPLACED** | `STOP RUN RETURNING <non-zero>` |
| `EXEC CICS RETURN` | **REPLACED** | `GOBACK` |
| `EIBCALEN` length check | **REPLACED** | field-presence check (`IF REQ-POLICY-NUM = 0 → RC=98 + EXIT PARAGRAPH`) |
| `EXEC CICS LINK PROGRAM("LGSTSQ")` (error queue) | **REMOVED** | stderr write (when needed) |
| `EIBTRNID` / `EIBTRMID` / `EIBTASKN` / `EIBCALEN` references | **REMOVED** | n/a — not meaningful in batch |

The CICS LINK adaptation is the load-bearing case; see [docs/methodology/DECISIONS.md ADR-10](../../docs/methodology/DECISIONS.md) for the methodology decision (same-JVM Spring DI as the Java-side equivalent).

---

## 8. Entry points

| Entry | Invoked by | Parameters / input contract |
|---|---|---|
| `ADDPFCD` / `MAIN` | `./tools/run-cobol-db.sh add-policy-facade` (or shell directly after compile with `cobc -free`) | none on command line; reads `requests.dat` from CWD; writes `out/policy.db` + `out/policy.csv` |
| `ADDPOLDB-INSERT` (nested) | `CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC` from `ADDPFCD.FACADE-HANDLE` | 87-byte commarea-equivalent record (`LK-PARAMS`: 9 fields) bound via USING; returns `WS-INNER-RC` via `RETURN-CODE` |
