# cobol/add-policy-db — Dependency Map

Asset inventory for the `add-policy-db` module (module 1B — DB2 / EXEC SQL → JPA pattern). Hand-authored as part of Phase A per [`.claude/skills/cobol-analyze/SKILL.md`](../../.claude/skills/cobol-analyze/SKILL.md) §4.5.

For business meaning, data dictionary, and the EXEC SQL → SQLite shim adaptation, see the prose [README.md](./README.md).

---

## 1. Programs

| PROGRAM-ID | Source | Entry signature | Role | Notes |
|---|---|---|---|---|
| `ADDPOLDB` | [`src/ADDPOLDB.cbl`](./src/ADDPOLDB.cbl) (lines 17–166) | `MAIN` (no USING) | top-level batch | carve of GenApp `LGAPDB01` `INSERT-POLICY` paragraph (lines 261–322); free-format `.cbl` so it's compiled with `cobc -free` via [`tools/run-cobol-db.sh`](../../tools/run-cobol-db.sh) |

Single PROGRAM-ID; no nested programs.

---

## 2. Paragraph PERFORM tree

### Program: `ADDPOLDB`

```
MAIN                                                 (entry, STOP RUN at end)
├── CALL "cob_sqlite_open"   USING WS-DB-PATH        [external — see §6 shim]
├── CALL "cob_sqlite_exec"   (DROP TABLE IF EXISTS POLICY)
├── CALL "cob_sqlite_exec"   (CREATE TABLE POLICY ...)
├── OPEN INPUT REQUEST-FILE
├── READ-RECORD                                      (PERFORM, then re-PERFORMed in loop)
└── (loop UNTIL EOF-REACHED)
    ├── INSERT-POLICY
    │   ├── STRING ... INTO WS-SQL                   (compose INSERT statement)
    │   └── CALL "cob_sqlite_exec" USING WS-SQL      [external — see §6 shim]
    └── READ-RECORD
├── CLOSE REQUEST-FILE
├── CALL "cob_sqlite_dump"   USING WS-TABLE WS-DUMP-PATH
├── CALL "cob_sqlite_close"
└── DISPLAY summary line
```

No `PERFORM ... THRU` (no fall-through). No `GO TO`. No EVALUATE chains. Per-record outcome (OK / ERR) is driven by the integer `WS-RC` returned from the shim call.

---

## 3. External program calls

| Caller paragraph | Call type | Target | Notes |
|---|---|---|---|
| `MAIN` | `CALL "cob_sqlite_open"` | C shim symbol (libcob_sqlite) | DB connection setup |
| `MAIN` | `CALL "cob_sqlite_exec"` × 2 (DROP, CREATE) | C shim | schema init |
| `INSERT-POLICY` | `CALL "cob_sqlite_exec"` | C shim | one INSERT per record |
| `MAIN` | `CALL "cob_sqlite_dump"` | C shim | table dump to `out/policy.csv` (deterministic, sorted by PK) |
| `MAIN` | `CALL "cob_sqlite_close"` | C shim | DB connection teardown |

All 6 shim symbols resolve to [`tools/spike/cob_sqlite.c`](../../tools/spike/cob_sqlite.c) (the libcob_sqlite spike). See [README.md](./README.md) for the EXEC SQL → shim mapping rationale.

---

## 4. Copybook usage

none — single program, no `COPY` statements. The request-record layout is defined inline in `FD REQUEST-FILE` and intentionally mirrors a subset of GenApp's `CA-POLICY-COMMON` (see [README.md](./README.md)); no copybook reuse here.

---

## 5. File / VSAM dependencies

| Logical name | File path | ORGANIZATION | OPEN mode | Format / width |
|---|---|---|---|---|
| `REQUEST-FILE` | `requests.dat` | LINE SEQUENTIAL | INPUT | fixed-width 99 chars/record (10 fields per spec; mirrors `CA-POLICY-COMMON` + PK + LASTCHANGED) |
| (out) `out/policy.db` | `out/policy.db` (SQLite binary) | n/a (managed by `cob_sqlite_open`) | created/truncated per run | SQLite DB file — not a COBOL FD |
| (out) `out/policy.csv` | `out/policy.csv` | n/a (written by `cob_sqlite_dump`) | OUTPUT | deterministic table dump, sorted by `POLICYNUMBER` PK; the byte-exact diff target |

`out/policy.db` and `out/policy.csv` are written by the C shim, not by COBOL `WRITE`. They exist in the working directory of the run (the sandbox spun up by [`tools/run-cobol-db.sh`](../../tools/run-cobol-db.sh)).

---

## 6. EXEC SQL / database dependencies

The original `LGAPDB01` issued `EXEC SQL INSERT INTO POLICY VALUES (...)` against DB2. Adapted to a `CALL "cob_sqlite_exec"` against the libcob_sqlite shim that wraps SQLite. SQL strings are composed via `STRING ... DELIMITED BY SIZE` from request fields, including `FUNCTION TRIM` on `REQ-BROKERS-REF` (a verbatim port of the original behavior, line 149).

| Statement type | Table | Columns / cursor | Host variables / source fields |
|---|---|---|---|
| `DROP TABLE IF EXISTS POLICY` | `POLICY` | n/a | (literal) |
| `CREATE TABLE POLICY` | `POLICY` | 9 columns: `POLICYNUMBER BIGINT PK`, `CUSTOMERNUMBER`, `ISSUEDATE`, `EXPIRYDATE`, `POLICYTYPE`, `LASTCHANGED`, `BROKERID`, `BROKERSREFERENCE`, `PAYMENT` | (literal DDL; canonical schema also in [`schema/policy.sql`](./schema/policy.sql)) |
| `INSERT INTO POLICY VALUES (...)` (one per request) | `POLICY` | 9 columns, positional | `REQ-POLICY-NUM`, `REQ-CUSTOMER-NUM`, `REQ-ISSUE-DATE`, `REQ-EXPIRY-DATE`, `REQ-POLICY-TYPE`, `REQ-LASTCHANGED`, `REQ-BROKER-ID`, `FUNCTION TRIM(REQ-BROKERS-REF)`, `REQ-PAYMENT` |

`POLICYNUMBER` PRIMARY KEY uniqueness violation surfaces as a non-zero `WS-RC` from `cob_sqlite_exec` → `ERR  POLNUM=... RC=1` (exercised by fixture `02-sql-errors`). This is the empirical surface that drove [docs/methodology/DECISIONS.md ADR-9](../../docs/methodology/DECISIONS.md) (`em.persist + flush` over `JpaRepository.save`).

---

## 7. EXEC CICS / runtime calls

none — module 1B strips all CICS plumbing. The GenApp ancestor `LGAPDB01` had `EXEC CICS ABEND ABCODE('LGSQ')` for SQL-error rollback and `EXEC CICS LINK PROGRAM("LGSTSQ")` for error-queue logging; both were removed during the carve. See [README.md](./README.md) for the kept/adapted/removed list.

---

## 8. Entry points

| Entry | Invoked by | Parameters / input contract |
|---|---|---|
| `ADDPOLDB` / `MAIN` | `./tools/run-cobol-db.sh add-policy-db` (or shell directly after compile with `cobc -free`) | none on command line; reads `requests.dat` from CWD; writes `out/policy.db` + `out/policy.csv` to CWD |
