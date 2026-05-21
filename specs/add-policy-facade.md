# Spec: ADDPFCD — Add Policy Facade (CICS LINK → Spring DI)

**Source of truth:** [cobol/add-policy-facade/src/ADDPFCD.cbl](../cobol/add-policy-facade/src/ADDPFCD.cbl).

**Provenance:** carved from [cicsdev/cics-genapp LGAPOL01](../cobol/genapp-source/lgapol01.cbl) (the ADD-policy facade that `EXEC CICS LINK`s to LGAPDB01). See [cobol/add-policy-facade/README.md](../cobol/add-policy-facade/README.md) for kept / adapted / removed.

**What this module proves:** the CICS LINK chain → Spring service-to-service equivalence pattern. Stakeholder ask: *"how do we handle the COBOL orchestrator?"*

## 1. Purpose

A thin facade program that receives a policy-add request, validates it at the facade level, and **delegates** the actual INSERT to a separate program (the COBOL pattern that was originally `EXEC CICS LINK PROGRAM("LGAPDB01")`).

The Java translation collapses to two `@Service` classes: `PolicyFacadeService` calls `PolicyInsertService` via `@Autowired`. Byte-exact diff on the chained output proves the two architectures preserve identical observable behavior.

## 2. Inputs

Same record layout as module 1B — see [specs/add-policy-db.md §2.1](./add-policy-db.md#21-request-file-requestsdat-line-sequential-fixed-width-99-charsrecord).

## 3. Per-record processing (mirror of LGAPOL01 MAINLINE SECTION)

```
read REQUEST-RECORD
FACADE-HANDLE:
    if policy_num == 0:
        emit ERR POLNUM=0000000000 RC=98          # facade-level rejection
        counter rejected++
        next record
    copy fields into LK-INSERT-PARAMS
    CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC
    if WS-RC == 0:
        emit OK   POLNUM=<N>;  counter inserted++
    else:
        emit ERR  POLNUM=<N> RC=+0000000001
        counter rejected++
```

After all records: dump table + emit summary line (same as module 1B).

## 4. Orchestration contract

| Boundary | COBOL | Java |
|---|---|---|
| Caller → facade | `EXEC CICS LINK PROGRAM("LGAPOL01") COMMAREA(...)` | `PolicyFacadeService.add(request)` (called from `BatchRunner`) |
| Facade → DB program | `CALL "ADDPOLDB-INSERT" USING LK-INSERT-PARAMS RETURNING WS-RC` (nested COBOL program; in CICS this would be `EXEC CICS LINK PROGRAM("LGAPDB01")`) | `@Autowired PolicyInsertService.insert(entity)` |
| Facade-level rejection | `MOVE 98 TO WS-CA-RC` | `return Result.TOO_SHORT_98` |
| DB-program rejection | `MOVE WS-RC TO RETURN-CODE` (inner program returns 1 on any SQL error) | `catch (RuntimeException e) { return Result.SQL_ERROR; }` |

## 5. Return codes (mirror of CA-RETURN-CODE)

| Code | Source | Meaning | Demo line |
|---|---|---|---|
| `00` | nominal | row inserted | `OK   POLNUM=NNNNNNNNNN` |
| `98` | facade | request rejected at facade (policy_num = 0) | `ERR  POLNUM=NNNNNNNNNN RC=98` |
| `+0000000001` | DB program | inner INSERT failed (constraint, etc.) | `ERR  POLNUM=NNNNNNNNNN RC=+0000000001` |

## 6. Byte-exact output channels

| File | Format | Notes |
|---|---|---|
| stdout | one line per record + summary line | facade RC=98 lines look slightly different from DB-program RC=+0000000001 lines — both sides produce the same shape |
| `out/policy.csv` | identical schema to module 1B | the chained call ends in the same table dump |
| exit code | `0` | even with rejections |

## 7. Fixtures

| Fixture | Records | What it exercises |
|---|---|---|
| `01-happy-chain` | 3 valid | full chain: read → facade validates → CALL → INSERT → row in POLICY |

(Module 1A could grow a `02-facade-rejection` fixture later, with a `policy_num = 0` record. The current fixture proves the chain works end-to-end; the facade-rejection path is exercised by code review of [PolicyFacadeService.java](../java/add-policy-facade/src/main/java/com/example/poc/addpolicyfacade/service/PolicyFacadeService.java) for now.)

## 8. What's deliberately the same as module 1B

This module **inherits** the entire INSERT-POLICY translation pattern from module 1B — `EntityManager.persist`, `@Transactional(REQUIRES_NEW)`, fixture-controlled PK + LASTCHANGED, etc. Module 1A's new contribution is the *facade wrapper* and the *chained-call equivalence*.

If module 1B's pattern changes (e.g., to add real `@GeneratedValue`), module 1A inherits the change automatically because [java/add-policy-facade/.../PolicyInsertService.java](../java/add-policy-facade/src/main/java/com/example/poc/addpolicyfacade/service/PolicyInsertService.java) is the same code.

## 9. Out of scope (module 1A)

- Cross-JVM CICS LINK (REST / message queue / RPC) — see [docs/DECISIONS.md ADR-10](../docs/DECISIONS.md).
- `EXEC CICS ABEND`, `EXEC CICS ASKTIME`, `EXEC CICS FORMATTIME`, error queue logging via LGSTSQ — all stripped.
- Two-phase commit across LINKed programs.

## 10. SME review checklist

- [ ] The two-program chain in §4 matches the COBOL source.
- [ ] The facade-level validation (§3, `policy_num == 0` → RC=98) is acceptable as a stand-in for the original commarea-length check.
- [ ] The "nested PROGRAM-ID + COBOL CALL" stand-in for `EXEC CICS LINK PROGRAM` is acceptable for a GnuCOBOL-runnable PoC (see ADR-10).
- [ ] Out-of-scope list in §9 is complete.
