# cobol/cci-account-converter — Dependency Map

Asset inventory for the `cci-account-converter` module. Hand-authored as part of Phase A per [`.claude/skills/cobol-analyze/SKILL.md`](../../.claude/skills/cobol-analyze/SKILL.md) §4.5.

For business meaning, data dictionary, validation rules, and numeric semantics, see the prose [README.md](./README.md). For the byte-exact I/O contract, see [`specs/cci-account-converter.md`](../../specs/cci-account-converter.md).

---

## 1. Programs

| PROGRAM-ID | Source | Entry signature | Role | Notes |
|---|---|---|---|---|
| `DRIVER-BCTITSCV` | [`src/BCTITSCV-RUN.cbl`](./src/BCTITSCV-RUN.cbl) (lines 15–86) | `MAIN-DRIVER` (no USING) | top-level batch | reads `requests.dat`, populates commarea, calls inner BCTITSCV per record |
| `BCTITSCV` | nested in `BCTITSCV-RUN.cbl` (lines 113–312) | `USING TI-YRCV-PARAMETROS` | callee (nested) | adapted from `original/BCTITSCV.COB`; 4 CICS surgical edits — see README Provenance |

---

## 2. Paragraph PERFORM tree

### Program: `DRIVER-BCTITSCV`

```
MAIN-DRIVER                                          (entry)
├── OPEN INPUT REQUEST-FILE
├── READ-INPUT                                       (PERFORM, then re-PERFORMed in the loop)
└── (loop UNTIL EOF-REACHED)
    ├── CALL-BCTITSCV
    │   ├── MOVE SPACES TO TI-YRCV-PARAMETROS         (commarea reset)
    │   ├── UNSTRING REQUEST-RECORD                   (parse 6 tokens)
    │   └── CALL 'BCTITSCV' USING TI-YRCV-PARAMETROS  [external — see §3]
    ├── DISPLAY-RESULT                                (5 DISPLAY lines + separator)
    └── READ-INPUT
```

### Program: `BCTITSCV`

```
(PROCEDURE DIVISION USING TI-YRCV-PARAMETROS)
├── 0100-INICIO
│   └── 0120-RECIBE-COMMAREA                         (CONTINUE-only after Adaptation 3)
├── 0500-EVALUA-PROCESO
│   ├── MOVE TI-YRCV-COD-CTA-CCI TO TI-YRCV-BCP-EDIT-IM  (REDEFINES overlay)
│   ├── 1000-VALIDA-ARGUMENTOS THRU 1000-FINVALIDA   [fall-through; GOBACK on any rule failure]
│   └── EVALUATE TRUE
│       ├── WHEN 88-CCI-BCP  → 0600-CALCULA-CTA-COMERCIAL
│       │                       └── EVALUATE TI-YRCV-IDT-CTA
│       │                           (WHEN '0' IMPACS / '1' SAVING / '2' CTS — no PERFORMs, only MOVEs)
│       ├── WHEN 88-BCP-CCI  → 1500-CALCULA-CHEQUEO-INT THRU 1500-FININT  [fall-through]
│       │                       ├── 2000-CALCULA-DIGCHEQ-BANOFI
│       │                       │   ├── 2500-SUMA-NUM-IMP   (PERFORM VARYING WS-I1 FROM 1 BY 2)
│       │                       │   └── 2550-SUMA-NUM-PAR   (PERFORM VARYING WS-I1 FROM 2 BY 2)
│       │                       └── 3000-CALCULA-DIGCHEQ-CUENTA
│       │                           ├── 3500-SUMA-NUM-IMP2  (PERFORM VARYING WS-I1 FROM 1 BY 2)
│       │                           └── 3550-SUMA-NUM-PAR2  (PERFORM VARYING WS-I1 FROM 2 BY 2)
│       └── WHEN OTHER       → MOVE '99' / 'COD. CONV.NO VALIDO' + GOBACK
└── 3000-FINAL                                       (GOBACK only after Adaptation 4)
```

**Paragraph-name collision (preserved verbatim)**: `3000-FINAL` and `3000-CALCULA-DIGCHEQ-CUENTA` both exist. COBOL resolves by name. No GO TO anywhere.

**Mid-EVALUATE `GOBACK`s** in `0500-EVALUA-PROCESO` `WHEN OTHER` and in three places inside `1000-VALIDA-ARGUMENTOS` exit the entire `BCTITSCV` program — control returns to `DRIVER-BCTITSCV` and skips `3000-FINAL`.

---

## 3. External program calls

| Caller paragraph | Call type | Target | Notes |
|---|---|---|---|
| `CALL-BCTITSCV` (in DRIVER-BCTITSCV) | `CALL 'BCTITSCV' USING TI-YRCV-PARAMETROS` | nested `BCTITSCV` (same compile unit) | GnuCOBOL local equivalent of CICS LINK; commarea bound via USING |

---

## 4. Copybook usage

| Copybook | Top-level 01 | Used by (program · section) | Width |
|---|---|---|---|
| [`copybooks/BCTIYRCV.cpy`](./copybooks/BCTIYRCV.cpy) | `TI-YRCV-PARAMETROS` | `DRIVER-BCTITSCV` · WORKING-STORAGE; `BCTITSCV` · LINKAGE | 200 bytes |
| [`original/BCTIYRCV.CPY`](./original/BCTIYRCV.CPY) | `TI-YRCV-PARAMETROS` | (audit-only; verbatim original, never compiled in) | 200 bytes |

---

## 5. File / VSAM dependencies

| Logical name | File path | ORGANIZATION | OPEN mode | Format / width |
|---|---|---|---|---|
| `REQUEST-FILE` | `requests.dat` (per-fixture, staged from `fixtures/<name>/in/requests.dat`) | LINE SEQUENTIAL | INPUT | text, whitespace-separated 6 tokens; record buffer `PIC X(255)` |

No output files. No VSAM. No SELECT/ASSIGN for any other DDname.

---

## 6. EXEC SQL / database dependencies

none — pure compute module. No DB2, no EXEC SQL, no SQLite shim, no connection setup.

---

## 7. EXEC CICS / runtime calls

All four CICS calls in the **original** `BCTITSCV.COB` were surgically removed during adaptation (see [README.md §1 "Provenance"](./README.md#1-provenance) for the verbatim original ↔ adapted mapping). The compiled binary contains **zero** CICS API references.

| Paragraph in original | EXEC verb + operands | Original line(s) | Adaptation status |
|---|---|---|---|
| `0100-INICIO` | `EXEC CICS HANDLE ABEND LABEL(3000-FINAL) END-EXEC` | 82–85 | **REMOVED** (Adaptation 2) — no CICS runtime to register a handler with |
| `0120-RECIBE-COMMAREA` | `IF EIBCALEN GREATER 0 SET ADDRESS OF TI-YRCV-PARAMETROS TO ADDRESS OF DFHCOMMAREA ELSE MOVE '99' ... END-IF` | 93–100 | **REPLACED** with `CONTINUE.` (Adaptation 3) — caller binds commarea via `USING` directly; the EIBCALEN-zero branch is unreachable standalone |
| `3000-FINAL` | `EXEC CICS RETURN END-EXEC` | 265–267 | **REPLACED** with `GOBACK.` (Adaptation 4) — standard COBOL subroutine return |
| `LINKAGE SECTION` | `01 DFHCOMMAREA PIC X(01).` | 69 | **REMOVED** (Adaptation 1) — no pointer dance needed |

No EXEC CICS LINK / XCTL / READ / WRITE / READQ / WRITEQ / ABEND in the original.

---

## 8. Entry points

| Entry | Invoked by | Parameters / input contract |
|---|---|---|
| `DRIVER-BCTITSCV` / `MAIN-DRIVER` | `./tools/run-cobol.sh cci-account-converter` (or shell directly) | none on command line; reads `requests.dat` from CWD |
| `BCTITSCV` | `CALL 'BCTITSCV' USING TI-YRCV-PARAMETROS` from `DRIVER-BCTITSCV.CALL-BCTITSCV` | 200-byte commarea (`TI-YRCV-PARAMETROS`) bound via USING; mutated in place |
