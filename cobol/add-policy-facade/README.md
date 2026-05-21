# cobol/add-policy-facade — module 1A (CICS LINK orchestrator)

Carve of [cobol/genapp-source/lgapol01.cbl](../genapp-source/lgapol01.cbl) — the "ADD policy" facade. Proves the CICS LINK → Spring service-to-service equivalence pattern.

## What it demonstrates (the stakeholder ask)

The original GenApp chains two COBOL programs:

```
caller --commarea--> LGAPOL01 (facade)
                      |
                      | EXEC CICS LINK PROGRAM(LGAPDB01) COMMAREA(...)
                      v
                     LGAPDB01 (does the INSERT)
```

The Java translation mirrors this with same-JVM Spring DI:

```
caller -> PolicyFacadeService.add(request)
            |
            | @Autowired call to inserter
            v
           PolicyInsertService.insert(entity)
```

Byte-exact diff on the stdout chain + the POLICY table dump proves the two architectures preserve identical observable behaviour.

## Provenance

### Kept verbatim
- The two-program chain: facade validates → delegates to DB program (preserved as facade → CALL "ADDPOLDB-INSERT").
- The facade-level return codes: `'00'` OK, `'98'` commarea too short, whatever the DB program returns otherwise.
- COBOL-level: nested PROGRAM-ID for the inner DB-insert routine (`ADDPOLDB-INSERT IS COMMON`) — preserves the "separate program" feel without dynamic linking gymnastics.

### Adapted (load-bearing for byte-exact diff)
- **EXEC CICS LINK PROGRAM("LGAPDB01") → CALL "ADDPOLDB-INSERT"**. GnuCOBOL has no CICS runtime; the COBOL `CALL` between programs in the same compilation unit gives the observable equivalent (control transfers + return-code propagation).
- **EXEC CICS ABEND → STOP RUN with non-zero RC**. Stripped CICS abend behavior; the program just terminates with a diagnostic.
- **EXEC CICS RETURN → GOBACK**. Standard COBOL subroutine return.
- **EIBCALEN length check → field-presence check on the parsed record**. Batch mode doesn't have a commarea length per se; we mimic it by rejecting records with `policy_num = 0` (the original treated 0 as "auto-assign" via DEFAULT; module 1B uses fixture-controlled PKs so 0 is invalid here).
- EXEC SQL/SQLite shim — identical to module 1B; see [../add-policy-db/README.md](../add-policy-db/README.md).

### Removed
- WRITE-ERROR-MESSAGE (CICS LINK to LGSTSQ error queue) — replaced by stderr write.
- EIBTRNID/EIBTRMID/EIBTASKN/EIBCALEN — CICS runtime variables; not meaningful in batch.

## How to run

```bash
./tools/run-cobol-db.sh add-policy-facade   # facade COBOL + nested INSERT program
./tools/run-java.sh     add-policy-facade   # Spring Boot: PolicyFacadeService -> PolicyInsertService
./tools/compare-outputs.py add-policy-facade
```

Schema is identical to module 1B's; see [../add-policy-db/schema/policy.sql](../add-policy-db/schema/policy.sql).
