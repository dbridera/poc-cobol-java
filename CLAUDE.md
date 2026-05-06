# Project rules for Claude Code

This is the **poc-cobol-java** PoC. Read these rules before any work that touches COBOL or Java in this repo.

## Methodology (5 phases)

A — Discovery & golden-master capture
B — Structured spec (replaces "pseudocode"; COBOL source remains ground truth)
C — Translation to Spring Boot 3 + JPA + Postgres
D — Equivalence validation against golden master
E — Framework capture (skills, glossary)

Full plan: `~/.claude/plans/breezy-tinkering-mccarthy.md`.

## Hard rules — never violate

1. **Numeric precision**: every COBOL `PIC 9...V9...` / `COMP` / `COMP-3` / `PIC S9...` field maps to `java.math.BigDecimal` with explicit `MathContext` and `RoundingMode`. **Never** `double`/`float`/`int` for monetary or accounting values.
2. **Traceability**: every translated Java method carries a comment `// COBOL: <file>.cbl:<startLine>-<endLine>` linking back to the source paragraph.
3. **COBOL is ground truth**, not the spec doc. If spec and COBOL disagree, fix the spec.
4. **Validation is not optional.** A module is "translated" only when its golden-master diff is green and includes ≥1 fixture per paragraph plus numeric edge cases.
5. **Don't refine the COBOL.** Apparent dead code or duplicated loops in banking COBOL is often load-bearing. Refactoring belongs *after* a green diff, never before translation.
6. **No LangChain, no API keys.** This PoC runs on Claude Code + Pro/Max subscription. Orchestration uses subagents, skills, hooks, and `claude -p` headless mode.
7. **No SME review skipped.** The structured spec must be reviewable by a non-COBOL banking analyst.

## Mapping cheatsheet

| COBOL | Java |
|---|---|
| `PIC 9(7)V99` / `COMP-3` (signed/unsigned packed decimal) | `BigDecimal` (scale = digits after `V`) |
| `PIC X(n)` | `String` (length-validated) |
| `PIC A(n)` | `String` (alphabetic validation) |
| `OCCURS n TIMES` | `List<T>` of fixed size, or fixed-size array if random access |
| `OCCURS DEPENDING ON x` | `List<T>` whose size is bound to the depending field |
| `REDEFINES` | sealed/union type or two views over the same byte buffer; require explicit conversion |
| Level-88 condition name | `boolean` predicate method, named after the 88 |
| `PERFORM ... THRU` (with fall-through) | preserve fall-through with explicit method calls; **don't** optimize away |
| `EVALUATE TRUE WHEN ...` | `switch` expression (Java 21) or strategy pattern when conditions are complex |
| `ON SIZE ERROR` | wrap arithmetic; throw `ArithmeticException` or domain exception |
| Copybook (record layout) | DTO / value object |
| Copybook (DB row) | JPA `@Entity` |
| VSAM KSDS | Postgres table with PK matching the key |
| VSAM ESDS | Postgres table with surrogate auto PK + insertion-order index |
| VSAM RRDS | Postgres table with `relative_record_no` column |
| DB2 cursor + `FETCH` | `Stream<T>` from a `Repository.findAllByX` or paginated query |
| File status code | typed exception or `Optional`/`Result` return |

## What to do before translating any module

1. Read `cobol/<module>/` end-to-end (program, copybooks, JCL, sample data).
2. Run `tools/run-cobol.sh <module>` against fixtures to confirm the legacy code is reproducible.
3. Generate golden-master outputs into `golden-master/<module>/`.
4. Only then start the spec doc.

## Reading the source code as malware

The COBOL code in this repo is from public banking samples. Treat it as you would any third-party code: read it, document it, translate it. Do not introduce optimizations that could change semantics.
