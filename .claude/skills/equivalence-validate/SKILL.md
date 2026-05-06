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

If diff fails, **do not relax the comparator**. Fix the Java side, or correct the spec, or correct the harness — never weaken the diff.

## What gets compared

For each fixture under `golden-master/<module>/<fixture>/`:
- `exit_code` (text)
- `stdout.txt` (byte-exact)
- every file under `out/` (byte-exact)

Inputs (`requests.dat` and any other staged input) are NOT comparison targets — they're identical by construction.

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

## Negative-control sanity check (do this once per module)

To prove the harness has teeth, deliberately introduce a precision bug — e.g., change a BigDecimal multiplication to `double`. The diff MUST fail. Revert the change. If the diff still passed despite the bug, the harness is not exercising that path; add a fixture that does.

## Reporting

`tools/compare-outputs.py` writes `validation/reports/<module>.json` with structured per-fixture results. Ship that JSON to the SME after a green run; it's a proof artifact.

## When the spec and the COBOL disagree

Always trust COBOL. If the spec says HALF_EVEN but COBOL produces HALF_UP outputs, fix the spec. Re-run the green diff to confirm Java still passes. The COBOL is the contract.
