# Spec: ADDPOLDB — Add Policy (DB row, EXEC SQL → JPA)

**Source of truth:** [cobol/add-policy-db/src/ADDPOLDB.cbl](../cobol/add-policy-db/src/ADDPOLDB.cbl). If this spec disagrees with the COBOL, the COBOL wins. Update the spec.

**Provenance:** carved from [cicsdev/cics-genapp LGAPDB01 INSERT-POLICY paragraph](../cobol/genapp-source/lgapdb01.cbl) (lines 261-322). See [cobol/add-policy-db/README.md](../cobol/add-policy-db/README.md) for kept / adapted / removed.

**What this module proves:** the EXEC SQL → JPA byte-exact equivalence pattern. Stakeholder ask: *"how do we handle DB2 / database access?"*

## 1. Purpose

For each ADD-POLICY request in an input file, INSERT a single row into the `POLICY` table. Reject duplicate primary keys with a structured return code; emit a per-record outcome and a summary line to stdout. At the end, dump the table to a deterministic text file for byte-exact diff against the Java side's dump.

## 2. Inputs

### 2.1 Request file (`requests.dat`, line-sequential, fixed-width 99 chars/record)

| # | Field | COBOL PIC | Width | Java type | Notes |
|---|---|---|---|---|---|
| 1 | request_id | X(6) | 6 | String | parsed but not stored (no per-request dispatch in module 1B yet) |
| 2 | policy_num | 9(10) | 10 | `Long` | fixture-controlled PK; must be > 0 |
| 3 | customer_num | 9(10) | 10 | `Long` | passed through |
| 4 | issue_date | X(10) | 10 | String | ISO-8601 `YYYY-MM-DD`; passed through |
| 5 | expiry_date | X(10) | 10 | String | ISO-8601 `YYYY-MM-DD`; passed through |
| 6 | policy_type | X(1) | 1 | String | `M`/`H`/`E`/`C` (motor/house/endowment/commercial); passed through |
| 7 | lastchanged | X(26) | 26 | String | DB2 timestamp `YYYY-MM-DD-HH.MM.SS.NNNNNN`; fixture-controlled |
| 8 | broker_id | 9(10) | 10 | `Long` | passed through |
| 9 | brokers_ref | X(10) | 10 | String | trimmed of trailing spaces before INSERT (FUNCTION TRIM in COBOL, .stripTrailing() in Java) |
| 10 | payment | 9(6) | 6 | `Long` | passed through |

### 2.2 Database state

- Schema is identical on both sides — see [cobol/add-policy-db/schema/policy.sql](../cobol/add-policy-db/schema/policy.sql) and [java/add-policy-db/src/main/resources/schema.sql](../java/add-policy-db/src/main/resources/schema.sql). Both sides **DROP + CREATE** at every run for deterministic state.
- COBOL side uses SQLite via [tools/spike/libcob_sqlite.dylib](../tools/spike/cob_sqlite.c) (the shim proven in [tools/spike/REPORT.md](../tools/spike/REPORT.md)). Java side uses H2 in-memory (`jdbc:h2:mem:add-policy-db;MODE=LEGACY`).
- **Neither H2 nor SQLite is DB2.** What the methodology proves is the *translation pattern* (EXEC SQL → JPA, SQLCODE → typed exception, IDENTITY_VAL_LOCAL → @GeneratedValue). Production swaps the JDBC URL.

## 3. Per-record processing (mirror of `INSERT-POLICY`)

```
read REQUEST-RECORD
build INSERT statement with the 9 column values (via COBOL STRING / Java em.persist)
execute via shim (COBOL) / em.persist + em.flush (Java)
if SQLCODE 0       -> emit OK   POLNUM=<N>;   counter inserted++
if SQLCODE -803    -> emit ERR  POLNUM=<N> RC=+0000000001;  counter rejected++
                      (in module 1B: UNIQUE constraint failure on duplicate PK)
```

After all records:
- Dump `POLICY` table to `out/policy.csv` (sorted by PRIMARY KEY for deterministic order).
- Emit summary: `PROCESSED=NNNNNN INSERTED=NNNNNN REJECTED=NNNNNN`.

## 4. SQL contract

| # | Operation | COBOL (via shim) | Java (JPA) |
|---|---|---|---|
| 1 | Schema reset | `DROP TABLE IF EXISTS POLICY; CREATE TABLE POLICY (...)` via `cob_sqlite_exec` | `schema.sql` with `spring.sql.init.mode=always` |
| 2 | Insert one row | `INSERT INTO POLICY VALUES (...)` via `cob_sqlite_exec` | `EntityManager.persist(entity); em.flush()` |
| 3 | Dump table | `SELECT * FROM POLICY ORDER BY 1` via `cob_sqlite_dump` | `repository.findAll().sort(...)` then write |

**Critical:** Java uses `EntityManager.persist`, **NOT** `JpaRepository.save()`. See [docs/DECISIONS.md ADR-9](../docs/DECISIONS.md) — `save()` is INSERT-OR-UPDATE (MERGE) and silently corrupts data on duplicate PK. Caught empirically by fixture 02-sql-errors.

## 5. Error handling

| SQLCODE / exception | RC | Behavior |
|---|---|---|
| 0 (COBOL) / no exception (Java) | (none) | row inserted; emit OK line |
| -803 (COBOL) / `ConstraintViolationException` (Java) | `+0000000001` | duplicate PK; emit ERR line; counter rejected++; **next record continues unaffected** |
| Other SQL error | `+0000000001` | (current module 1B does not distinguish; future modules may add finer codes) |

Each insert is wrapped in `@Transactional(propagation = REQUIRES_NEW)` on the Java side — one transaction per request, matching the COBOL pattern of "one CICS transaction per program invocation". A failure on record N does not poison the session for record N+1.

## 6. Byte-exact output channels

| File | Format | Both sides produce |
|---|---|---|
| stdout | one line per record: `OK   POLNUM=NNNNNNNNNN` or `ERR  POLNUM=NNNNNNNNNN RC=+NNNNNNNNNN`, then summary | identical |
| `out/policy.csv` | `id|customer|issue|expiry|type|lastchanged|broker|brokersref|payment\n` per row, sorted by id, no header | identical |
| exit code | `0` on normal completion (even with rejected records) | identical |

## 7. Fixtures

| Fixture | Records | What it exercises |
|---|---|---|
| `01-happy-small` | 3 valid (motor, house, endowment) | nominal INSERT path |
| `02-sql-errors` | 3 valid + 1 with duplicate PK | UNIQUE constraint propagation; **proved the JPA save() vs persist() finding** |

## 8. Out of scope (module 1B)

- Foreign-key references to a `CUSTOMER` table — the original LGAPDB01 has an FK constraint that triggers SQLCODE -530. We don't carry that across to module 1B; future modules may.
- Cursors (`EXEC SQL OPEN/FETCH/CLOSE`).
- The other INSERT paragraphs (INSERT-ENDOW / INSERT-HOUSE / INSERT-MOTOR / INSERT-COMMERCIAL).
- DB2 numeric truncation (the original moves `CA-CUSTOMER-NUM PIC 9(10)` into `DB2-CUSTOMERNUM-INT PIC S9(9)` — we use BIGINT to side-step).
- `IDENTITY_VAL_LOCAL()` and `CURRENT TIMESTAMP` defaults — we use fixture-controlled values for byte-exact diff.

## 9. SME review checklist

- [ ] Field widths in §2.1 match the COBOL FD in [ADDPOLDB.cbl:33-44](../cobol/add-policy-db/src/ADDPOLDB.cbl).
- [ ] Column order in §4 row 1 matches both schema.sql files.
- [ ] The SQLCODE → RC mapping in §5 is acceptable for downstream callers.
- [ ] The "fixture-controlled PK + LASTCHANGED" adaptation in §2.2 is acceptable for a PoC (production would use @GeneratedValue and mask the PK column from the diff).
- [ ] Out-of-scope list in §8 is complete and acceptable.
