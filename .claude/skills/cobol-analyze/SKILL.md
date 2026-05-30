---
name: cobol-analyze
description: Phase A — analyze a COBOL module before translation. Use when starting a new module, when the user names a COBOL program, or when fixtures need to be designed.
---

# COBOL discovery (Phase A)

You are starting a new module. Before generating a spec or any Java, complete every item in this checklist. Output is dropped into `cobol/<module>/README.md` and influences fixture design.

## 1. Inventory

- Programs: list every `*.cbl` in `cobol/<module>/src/`. For each, note PROGRAM-ID, public entry points, and external CALLs.
- Copybooks: list every `*.cpy`. For each, list its 01-level groups and which programs use it.
- JCL / shell drivers (if any): list and note inputs/outputs.

The structured form of this inventory — Programs (§1), Copybook usage (§4), Entry points (§8) — lives in the standalone `cobol/<module>/DEPENDENCIES.md` artifact (see §4.5). The README §1 carries the prose/narrative version (provenance, what was kept/adapted/removed); DEPENDENCIES.md carries the asset inventory in fixed-format tables. Don't duplicate; cross-link.

## 2. Data dictionary

For every PIC clause in the working storage and FD sections of the program, record:
- name, PIC clause, group/elementary, USAGE (DISPLAY/COMP/COMP-3), VALUE if any
- business meaning (ask the SME or read comments)
- in-Java target type (use `docs/methodology/glossary.yaml` rules; numeric → `BigDecimal`)

## 3. External I/O

Document every:
- `EXEC SQL` statement → which DB2 table, what columns, host variables
- `EXEC CICS READ FILE` → which VSAM file
- `OPEN`/`READ`/`WRITE`/`CLOSE` → which sequential/indexed file, fixed/variable length
- `DISPLAY` / `ACCEPT` / terminal I/O

## 4. Control-flow map

Produce a paragraph-level call graph:
- which paragraphs are top-level, which are PERFORM'd, which fall through
- explicitly mark any `PERFORM ... THRU` (fall-through is load-bearing)
- mark any GO TO and document the control-flow violation

The narrative description goes in the README. The **structured ASCII tree** version lives in `DEPENDENCIES.md` §2 — see §4.5.

## 4.5 Dependency map — `cobol/<module>/DEPENDENCIES.md`

A standalone, machine-grokkable asset doc. Hand-authored during this phase. Fixed structure across every module so cross-module diffs / audits are easy:

| § | Section | Format |
|---|---|---|
| 1 | **Programs** | table of every PROGRAM-ID (incl. nested), source path with line range, entry signature, role, notes |
| 2 | **Paragraph PERFORM tree** | one ASCII tree per PROGRAM-ID, rooted at the top-level entry. Show every `PERFORM` and `PERFORM ... THRU` (mark THRU as `[fall-through]`). Mark any `GO TO` as `[GO TO — load-bearing? yes/no]`. A `CALL` to another program in the same compile unit shows as `[external — see §3]` |
| 3 | **External program calls** | table: `Caller paragraph \| Call type (CALL / EXEC CICS LINK / XCTL) \| Target \| Notes` |
| 4 | **Copybook usage** | table: `Copybook \| Top-level 01 \| Used by (program · section) \| Width` |
| 5 | **File / VSAM dependencies** | table: `Logical name \| File path / DDname \| ORGANIZATION \| OPEN mode \| Format/width` |
| 6 | **EXEC SQL / database dependencies** | table: `Statement type \| Table \| Columns or cursor \| Host variables`. For modules using the libcob_sqlite shim, list shim symbols (`cob_sqlite_open` / `_exec` / `_dump` / `_close`) and cite [tools/spike/cob_sqlite.c](../../tools/spike/cob_sqlite.c) |
| 7 | **EXEC CICS / runtime calls** | table: `Paragraph \| EXEC verb + operands \| Adaptation status (preserved / removed / replaced)`. Cite the adaptation number from the module's README provenance section |
| 8 | **Entry points** | table: `Entry \| Invoked by \| Parameters / input contract` |

**Empty sections still appear** with a one-line `none — <why>` note (e.g., `none — pure compute module, no DB access`). Uniform structure across modules is the point.

**No data dictionary in this file.** That's already in `README.md` §2 (analyst-facing) and `specs/<module>.md` §2 (translator-facing). DEPENDENCIES.md is the asset/topology inventory — what's there, what calls what, what depends on what — not the per-PIC data dictionary.

Canonical example to mirror: [cobol/cci-account-converter/DEPENDENCIES.md](../../../cobol/cci-account-converter/DEPENDENCIES.md). All 4 existing modules carry this file; new modules must too.

## 5. Numeric semantics

- For every COMPUTE/ADD/SUBTRACT/MULTIPLY/DIVIDE: note operand PIC clauses and target.
- Record any `ROUNDED` clause. **DEFAULT `ROUNDED` IS HALF_UP, NOT HALF_EVEN.** If `ROUNDED MODE IS NEAREST-EVEN` appears, use HALF_EVEN in Java.
- Record every `ON SIZE ERROR` handler — these become `try/catch ArithmeticException` (or pre-checks) in Java with the EXACT reason string preserved.

## 6. Validation rules

For every `EVALUATE` / nested `IF` chain that gates business actions:
- Record the order of conditions — order is part of the contract (short-circuit).
- For each condition, record the side effect (which RC, which message).

## 7. Fixture design

Plan ≥3 fixtures:
1. **Happy path**: 2–3 valid records exercising representative branches.
2. **Validation errors**: one record per validation rule that fails it; ideally one record that passes through.
3. **Numeric boundaries**: CC/value/accidents/etc. at PIC boundaries; at least one record that should trigger `ON SIZE ERROR`.

Every fixture record must be parseable. Use `tools/make-fixture.py` if the format is fixed-width.

## 8. Output of this phase

Three artifacts in `cobol/<module>/`:

1. **`README.md`** — prose Phase A doc with sections matching 1–7 above (provenance, data dictionary, control-flow narrative, validation rules, numeric semantics).
2. **`DEPENDENCIES.md`** — the structured 8-section asset map specified in §4.5. Hand-authored alongside the README; format is fixed across modules.
3. **`fixtures/<name>/`** tree — ≥3 fixtures (happy / validation errors / numeric boundaries per §7), each ready for `tools/run-cobol.sh <module>` (or `run-cobol-db.sh` for DB modules) to capture into `golden-master/<module>/`.

A Phase A is not complete until all three exist.

## When NOT to skip ahead

Do not write the spec doc (Phase B) until §1–§7 are done. Do not write Java (Phase C) until `golden-master/` exists.
