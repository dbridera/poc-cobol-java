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

## Hard rules

- Never paraphrase a COBOL idiom into vague English. "Validates inputs" is wrong; list the rules in order.
- Never invent business meaning. If you don't know what a field means, mark it `TBD — ask SME`.
- The numeric calculations section must explicitly state the **rounding mode**. Default COBOL `ROUNDED` is HALF_UP. Verify by grepping the source for `ROUNDED MODE`.
- Every overflow trap (`ON SIZE ERROR`) must be listed with its reason string (verbatim from COBOL).
- The output formats section is the BYTE-EXACT contract for `equivalence-validate`. If you handwave here, the diff will fail.

## SME review loop

After producing the doc, have the SME review §2–§7. Apply corrections:
- If the SME corrects the spec → fix the spec, then check whether the COBOL agrees. If they disagree, the SME's correction may indicate a COBOL bug; flag it but do NOT change the COBOL.
- If the SME is fine but the COBOL behaves differently than the spec → fix the spec to match COBOL, then ask the SME whether the COBOL behavior is intended.

## Reference example

`specs/add-motor-policy.md` is the template. Mimic its section ordering and table style.
