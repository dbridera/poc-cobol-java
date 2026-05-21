# cobol/add-policy-db — module 1B (DB-touching paragraph)

Carve of the **INSERT-POLICY** paragraph from [cobol/genapp-source/lgapdb01.cbl:261-322](../genapp-source/lgapdb01.cbl). Proves the EXEC SQL → JPA byte-exact equivalence pattern.

## Provenance

### Kept verbatim
- The INSERT statement column list and order (POLICYNUMBER, CUSTOMERNUMBER, ISSUEDATE, EXPIRYDATE, POLICYTYPE, LASTCHANGED, BROKERID, BROKERSREFERENCE, PAYMENT) — matches DB2 `POLICY` table in the GenApp DDL.
- Field types and widths from `CA-POLICY-COMMON` (see [lgcmarea.cpy:37-43](../genapp-source/lgcmarea.cpy)).
- The 3 SQLCODE evaluation branches: 0 → RC=00, -530 → RC=70, other → RC=90.

### Adapted (load-bearing for byte-exact diff)
- **EXEC SQL → CALL "cob_sqlite_exec"**. GnuCOBOL has no native EXEC SQL preprocessor; we route through the spike-proven [tools/spike/cob_sqlite.c](../../tools/spike/cob_sqlite.c) shim. Production migration would use GIXSQL. The shim emits the same shape of side-effects: row inserted in a SQL DB, observable by table dump.
- **DEFAULT auto-PK → explicit POLICYNUMBER from the request**. The original uses DB2's `DEFAULT` to auto-assign POLICYNUMBER and `IDENTITY_VAL_LOCAL()` to retrieve it. For byte-exact reproducibility we make the PK fixture-controlled (the request carries the policy number).
- **CURRENT TIMESTAMP → explicit LASTCHANGED from the request**. Same reason: a frozen timestamp in the fixture so both COBOL and Java produce identical rows.
- **EXEC CICS RETURN → GOBACK / continue loop**. Stripped CICS error returns; the per-record return code is logged to stdout instead.
- **EXEC CICS ABEND, EXEC CICS LINK** → not used in INSERT-POLICY; not carved.
- DB2 SMALLINT/INTEGER → SQLite INTEGER (text-affinity-free); DB2 DATE/TIMESTAMP/VARCHAR → SQLite TEXT.

### Removed (out of carve scope)
- INSERT-ENDOW / INSERT-HOUSE / INSERT-MOTOR / INSERT-COMMERCIAL (separate paragraphs in the original; module 1B is only INSERT-POLICY).
- WRITE-ERROR-MESSAGE (EXEC CICS LINK to LGSTSQ for error queue logging — replaced by stderr writes).
- LGAPVS01 callout (the next program in the orchestration chain — out of scope for module 1B).

## How to run

```bash
./tools/run-cobol-db.sh add-policy-db   # compile + run COBOL with the shim
./tools/run-java-db.sh  add-policy-db   # build + run Spring Boot + JPA + H2 (TODO module 1B step 4)
./tools/compare-outputs.py add-policy-db
```

See [schema/policy.sql](schema/policy.sql) for the table DDL (used identically by COBOL via shim and by Java via JPA's `schema.sql`).
