---
name: equivalence-validate
description: Phase D — establish byte-exact behavioral equivalence between COBOL and Java for a module. Use after Phase C produces a green build.
---

# Behavioral equivalence (Phase D)

The contract: for every fixture, the Java run produces files and stdout byte-identical to the COBOL run.

## Procedure

```bash
# 1. (re)capture COBOL golden master
./tools/run-cobol.sh <module>

# 2. build + run Java
./tools/run-java.sh <module>

# 3. diff
./tools/compare-outputs.py <module>     # exit 0 = green
```

For job modules (`cobol/<module>/job.json`) the same three commands apply — `run-cobol.sh` / `run-java.sh` dispatch to `tools/run-job.py`, which stages the fixture, runs every step with its DD mapping (and the `abend-after=…;resume` plan of a restart fixture), and captures only the manifest's `capture: true` datasets plus `out/steps/*` and `out/run-log.txt`. `./tools/run-job.sh <module> <fixture> --verbose` prints the step/RC lines live (the restart demo moment).

If diff fails, **do not relax the comparator**. Fix the Java side, or correct the spec, or correct the harness — never weaken the diff.

## What gets compared

For each fixture under `golden-master/<module>/<fixture>/`:
- `exit_code` (text)
- `stdout.txt` (byte-exact)
- every file under `out/` (byte-exact)

Inputs (`requests.dat` and any other staged input) are NOT comparison targets — they're identical by construction.

Every comparison is byte-exact. For a file that is not UTF-8 text, or whose record length is known (`job.json` datasets by file name, or `fixtures/<f>/compare.json` `{"lrecl": {...}}`), a mismatch is reported as a **binary report**: first differing offset, 1-based record and column, hex of both bytes, the surrounding record text, up to 5 sample records. Every fixture entry in the JSON carries a `summary` (files/records/bytes compared, bytes differing); `./tools/compare-outputs.py --summary` totals them per module for the demo proof.

## Common diagnoses

| Diff symptom | Likely cause | Fix |
|---|---|---|
| Spring Boot banner + log lines in `stdout.txt` | missing `application.properties` overrides | set `banner-mode=off`, `log-startup-info=false`, `logging.level.root=OFF` |
| Off-by-one in numeric value (e.g., 512 vs 513) | wrong rounding mode | check default-COBOL = HALF_UP; spec must state mode |
| Trailing spaces appearing/disappearing in `error.log` | LINE SEQUENTIAL trims; Java forgot `stripTrailing` | trim record before write |
| `ERR ... <reason>` line wrong length | reason field width mismatch with `EM-REASON PIC X(n)` | space-pad to the COBOL PIC width |
| `policy.dat` / `motor.dat` records have wrong width | encoder PIC widths drifted from the COBOL FD | regenerate from spec §6 |
| `requests.dat` shows up as "missing in java" | run-cobol.sh capturing inputs | exclude staged inputs from `out/` |
| Diff is green but tests fail | unit tests have stale expectations | regenerate expected values from new golden master, never the reverse |
| `tcatbal.unl`/created rows differ only in FILLER bytes | Java `INITIALIZE` blanked FILLER | COBOL INITIALIZE leaves FILLER untouched; keep the working-storage record alive across the loop |
| Timestamps differ in the last digits | clock not pinned, or pinned without hundredths | `COB_CURRENT_DATE="YYYY/MM/DD HH:MM:SS.hh"` in `job.json` env, same value on the Java side |
| Report amount `0.09` vs `.09`, or 15 spaces vs `.00` | edited-picture rules | every integer position is `Z`: zero integer part is suppressed, a zero value blanks the whole field |
| Sorted output order differs on equal keys | DFSORT order unspecified | add the documented tie-break on a unique field (ADR-16) |
| `run-log.txt` differs | step semantics drift | both sides must follow ADR-14: RC lines, `SKIPPED (COMPLETED IN RUN n)`, `NOT RUN (JOB FAILED)`, `ABEND AFTER X (injected)`, `END MAXRC` |

## Negative-control sanity check (do this once per module)

To prove the harness has teeth, deliberately introduce a precision bug — e.g., change a BigDecimal multiplication to `double` or a rounding mode. The diff MUST fail at a named record/column. Revert the change. If the diff still passed despite the bug, the harness is not exercising that path; add a fixture that does. For modules with a faithful-defects register, run a second control: "fix" one defect and confirm the diff goes red (module 3: both controls recorded in `docs/demo/DEMO.md`). `./tools/demo-commands.sh negative-control` scripts the first one.

## Invariants between fixtures (job modules)

A restart fixture (`RESTART_EQUIVALENT_TO=<fixture>` in `fixture.env`) must produce outputs identical to its unbroken twin except `run-log.txt` and `steps/`, on **both** trees; `./tools/check-module.sh <module>` enforces it along with the other process-conformance checks (provenance, verbatim sources, spec sections, traceability, report freshness).

## Reporting

`tools/compare-outputs.py` writes `validation/reports/<module>.json` with structured per-fixture results. Ship that JSON to the SME after a green run; it's a proof artifact.

## When the spec and the COBOL disagree

Always trust COBOL. If the spec says HALF_EVEN but COBOL produces HALF_UP outputs, fix the spec. Re-run the green diff to confirm Java still passes. The COBOL is the contract.
