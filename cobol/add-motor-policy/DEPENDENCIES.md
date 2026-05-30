# cobol/add-motor-policy — Dependency Map

Asset inventory for the `add-motor-policy` module (module 0 — VSAM / file access pattern). Hand-authored as part of Phase A per [`.claude/skills/cobol-analyze/SKILL.md`](../../.claude/skills/cobol-analyze/SKILL.md) §4.5.

For business meaning, data dictionary, validation rules, and numeric semantics, see the prose [README.md](./README.md). For the byte-exact I/O contract, see [`specs/add-motor-policy.md`](../../specs/add-motor-policy.md).

---

## 1. Programs

| PROGRAM-ID | Source | Entry signature | Role | Notes |
|---|---|---|---|---|
| `ADDMPOL` | [`src/ADDMPOL.cbl`](./src/ADDMPOL.cbl) (lines 14–333) | `MAIN-LOGIC SECTION` (no USING) | top-level batch | adapted from GenApp `LGAPDB01` (ADD POLICY → INSERT MOTOR carve) |

Single PROGRAM-ID; no nested programs, no called sub-programs.

---

## 2. Paragraph PERFORM tree

### Program: `ADDMPOL`

```
MAIN-LOGIC SECTION                                   (entry, STOP RUN at end)
├── INITIALIZE-RUN                                   (OPEN all 4 files)
├── (loop UNTIL EOF-REACHED) PROCESS-REQUESTS
│   └── READ REQUEST-FILE
│       └── NOT AT END → HANDLE-ONE-REQUEST
│           ├── CHECK-REQUEST-ID                     (RC := 99 if request_id != '01AMOT')
│           ├── (if RC=0) VALIDATE-REQUEST           (EVALUATE TRUE chain, 5 rules)
│           ├── (if RC=0) CALC-MOTOR-PREMIUM         (EVALUATE on CC + 3 COMPUTEs + ON SIZE ERROR)
│           ├── (if RC=0) INSERT-POLICY              (MOVEs + WRITE POLICY-OUT-RECORD)
│           ├── (if RC=0) INSERT-MOTOR               (MOVEs + WRITE MOTOR-OUT-RECORD)
│           └── (else)   REPORT-ERROR                (WRITE ERROR-RECORD + DISPLAY)
├── FINALIZE-RUN                                     (CLOSE all 4 files)
└── PRINT-SUMMARY                                    (final DISPLAY)
```

No `PERFORM ... THRU` (no fall-through). No `GO TO`. The if-chain in `HANDLE-ONE-REQUEST` is a short-circuit guard pattern: once `WS-RETURN-CODE` is non-zero, subsequent paragraphs are skipped (matches the spec §3 short-circuit contract).

---

## 3. External program calls

none — single PROGRAM-ID, no CALLs, no LINKs.

---

## 4. Copybook usage

| Copybook | Top-level 01 | Used by (program · section) | Width |
|---|---|---|---|
| [`copybooks/lgpolicy.cpy`](./copybooks/lgpolicy.cpy) (verbatim from GenApp) | `DB2-POLICY`, `DB2-MOTOR`, `DB2-...` (multi-record copybook) | `ADDMPOL` · WORKING-STORAGE (via `COPY LGPOLICY` at line 154) | n/a — used as logical reference; `FD` records mirror it manually |

The copybook is logically referenced for the DB2-POLICY / DB2-MOTOR layouts. The output records (`POLICY-OUT-RECORD`, `MOTOR-OUT-RECORD`) are defined inline in `FD` to mirror those layouts. See [README.md "Provenance"](./README.md) for what was kept verbatim vs adapted.

---

## 5. File / VSAM dependencies

| Logical name | File path | ORGANIZATION | OPEN mode | Format / width |
|---|---|---|---|---|
| `REQUEST-FILE` | `requests.dat` | LINE SEQUENTIAL | INPUT | fixed-width 143 chars/record (16 fields per spec §2.1) |
| `POLICY-FILE` | `policy.dat` | LINE SEQUENTIAL | OUTPUT (truncate) | fixed-width 67 chars/record (8 fields per spec §6.2) |
| `MOTOR-FILE` | `motor.dat` | LINE SEQUENTIAL | OUTPUT (truncate) | fixed-width 87 chars/record (10 fields per spec §6.3) |
| `ERROR-FILE` | `error.log` | LINE SEQUENTIAL | OUTPUT (truncate) | `PIC X(120)` per line (trimmed by LINE SEQUENTIAL on WRITE) |

`OPEN OUTPUT` truncates each output file at run start. File-status checking on `WS-REQUEST-FS` / `-POLICY-FS` / `-MOTOR-FS` / `-ERROR-FS`. No VSAM, no DDname conventions — pure POSIX file I/O.

---

## 6. EXEC SQL / database dependencies

none — module 0 deliberately uses flat-file output (the VSAM-equivalent) so the byte-exact diff harness can compare without a DB. The GenApp ancestor (`LGAPDB01`) had EXEC SQL INSERTs against the DB2 POLICY and MOTOR tables; those were rewritten as `WRITE` against `policy.dat` / `motor.dat` during the carve.

---

## 7. EXEC CICS / runtime calls

none — module 0 strips all CICS plumbing. The GenApp ancestor `LGAPDB01` had `EXEC CICS ABEND ABCODE('LGSQ')` and `EXEC CICS LINK PROGRAM("LGSTSQ")` for error-queue logging; both were removed during the carve. See [README.md "Provenance"](./README.md) for the kept/adapted/removed list.

---

## 8. Entry points

| Entry | Invoked by | Parameters / input contract |
|---|---|---|
| `ADDMPOL` / `MAIN-LOGIC` | `./tools/run-cobol.sh add-motor-policy` (or shell directly) | none on command line; reads `requests.dat` from CWD; writes `policy.dat`, `motor.dat`, `error.log` to CWD |
