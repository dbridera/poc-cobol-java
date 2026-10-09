---
name: cobol-spec
description: Phase B — write a structured spec doc reviewable by a non-COBOL banking analyst. Use after cobol-analyze, before java-translate.
---

# Structured spec generation (Phase B)

The output is `specs/<module>.md`. The COBOL source remains the ground truth — this doc is for SME review and as a spec for translation, not as a substitute for the source.

## Required sections (in order)

1. **Header**: source-of-truth pointer, provenance.
2. **Purpose**: 2–4 sentences of what the module does in business terms.
3. **Inputs**: every input record / table / parameter, with PIC, width, Java type, validation.
4. **Per-record processing**: top-level pseudo-code mirroring the main paragraph. Show the short-circuit chain explicitly.
5. **Validation rules**: ordered table of (condition, RC, reason text). Order is contract — call it out.
6. **Numeric calculations**: every COMPUTE with operand types, scales, rounding mode, overflow behavior. Cite the empirical observations from `golden-master/` (e.g., "verified that record N produces value V").
7. **Outputs**: every file/table/stdout line with byte-exact format spec — column widths, padding direction, leading-zero rules. Include `error.log` and stdout summary.
8. **Side effects**: file open modes (OUTPUT = truncate), counters reset, transactional boundaries.
9. **Out of scope**: anything dropped vs the original (CICS, DB2 transactions, other policy types, etc.).
10. **Traceability**: a Java symbol → COBOL paragraph + line range table.
11. **SME review checklist**: 4–8 yes/no items the analyst can answer without reading COBOL.
12. **Faithful defects register** (when the module has any): each real bug in the source with its line range, observable effect and the fixture that shows it. The translation replicates them (rule 5); the SME checklist asks whether they are intended.

For **job modules** (`job.json` present): §3 lists datasets with LRECL, key and offsets plus the PARM and the pinned clock; §4 has one subsection per step in job order (loaders/sorts included) with the step's DISPLAY lines; §7 lists every captured dataset with its order (key order for unloads, input order for sequential writes) and the `run-log.txt` lines; §8 states the failure/restart semantics (RC outside `rc_ok`, `NOT RUN`, `always`, MAXRC, resumed ≡ unbroken). Template: `specs/nightly-batch.md`.

## Hard rules

- Never paraphrase a COBOL idiom into vague English. "Validates inputs" is wrong; list the rules in order.
- Never invent business meaning. If you don't know what a field means, mark it `TBD — ask SME`.
- The numeric calculations section must explicitly state the **rounding mode**. Default COBOL `ROUNDED` is HALF_UP. Verify by grepping the source for `ROUNDED MODE`. A COMPUTE/DIVIDE **without** ROUNDED into a field with decimals truncates toward zero (`RoundingMode.DOWN`), and an ADD without `ON SIZE ERROR` keeps the low-order digits — say which applies to every statement (glossary `numerics`).
- Every overflow trap (`ON SIZE ERROR`) must be listed with its reason string (verbatim from COBOL).
- The output formats section is the BYTE-EXACT contract for `equivalence-validate`. If you handwave here, the diff will fail.

## Paragraph guide (feeds the viewer)

Alongside the spec, write `cobol/<module>/PARAGRAPHS.md`: a `## PROGRAM-ID — what the program does` heading per program (several ids separated by commas share one heading), a short business summary, and a table `| Párrafo | Qué hace | Spec |` with one row per paragraph (name exactly as in the COBOL, including compiler labels such as `L$0` when the trace shows them) and the spec section that holds the exact rule. Plain language for a banking analyst, no COBOL jargon; name the faithful defects (D1, D2, …) where they live. `./tools/render-traceability.py <module>` shows the lines under each paragraph and in the bridge bar; `check-module.sh` warns when a paragraph has none.

## SME review loop

After producing the doc, have the SME review §2–§7. Apply corrections:
- If the SME corrects the spec → fix the spec, then check whether the COBOL agrees. If they disagree, the SME's correction may indicate a COBOL bug; flag it but do NOT change the COBOL.
- If the SME is fine but the COBOL behaves differently than the spec → fix the spec to match COBOL, then ask the SME whether the COBOL behavior is intended.

## Reference example

`specs/add-motor-policy.md` is the template. Mimic its section ordering and table style.
