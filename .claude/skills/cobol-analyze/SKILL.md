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

## 2. Data dictionary

For every PIC clause in the working storage and FD sections of the program, record:
- name, PIC clause, group/elementary, USAGE (DISPLAY/COMP/COMP-3), VALUE if any
- business meaning (ask the SME or read comments)
- in-Java target type (use `docs/glossary.yaml` rules; numeric → `BigDecimal`)

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

A populated `cobol/<module>/README.md` with sections matching 1–7, plus a `fixtures/` tree ready for `tools/run-cobol.sh <module>` to capture into `golden-master/`.

## When NOT to skip ahead

Do not write the spec doc (Phase B) until §1–§7 are done. Do not write Java (Phase C) until `golden-master/` exists.
