# Module 2 — `cci-account-converter` — session report

A real banking COBOL program (Banco de Crédito del Perú, 2015) driven end-to-end through the framework — adapted for GnuCOBOL, spec'd, translated to Spring Boot 3 + Java 21, and proven byte-exact equivalent against the original on three fixtures. **No code lost in translation; no test invented.**

---

## 1. TL;DR

| | |
|---|---|
| **Module** | `cci-account-converter` (originally `BCTITSCV`, Banco de Crédito del Perú) |
| **Purpose** | Bidirectional converter between Peruvian CCI (interbank code) and the bank's internal IMPACS / SAVING / CTS commercial account format |
| **What it computes** | Validates input, decodes a CCI into a commercial account, or **builds a CCI including the two mod-10 check digits** the Peruvian interbank standard requires |
| **Phases executed** | A (Discovery) · B (Spec) · C (Translation) · D (Validation) · E (Crystallization) — full A→E loop |
| **COBOL source size** | 270 lines verbatim original + 4 surgical CICS removals |
| **Java translation size** | 8 source files, ~430 LoC + 2 test files, 13 unit tests |
| **Validation result** | **3 / 3 fixtures byte-exact** on the first integrated run. `validation/reports/cci-account-converter.json` shows `"diffs": []` per fixture |
| **Negative control** | Confirmed: deliberately corrupting one BigDecimal multiplier produced a clean `[FAIL]` on fixture 02; reverted to green |
| **New methodology output** | **2 ADRs** (ADR-11, ADR-12) + **4 glossary entries** |

---

## 2. What this module does

`BCTITSCV` is a CICS commarea program used by BCP's online interbank-transfer system. Two directions, both through the same 200-byte `TI-YRCV-PARAMETROS` commarea controlled by `IND-CONV`:

- **CCI → BCP commercial account** (`IND-CONV='1'`). Decodes a 20-byte interbank code into the bank's IMPACS / SAVING / CTS internal account format. Drives on byte 7 (`IDT-CTA`): `0` = IMPACS, `1` = SAVING, `2` = CTS.
- **BCP commercial account → CCI** (`IND-CONV='2'`). Builds a 20-byte CCI from an internal account, **including the two trailing check digits** computed by a Luhn-style mod-10 algorithm over (a) the 6-digit bank+office prefix, then (b) the 12-digit body. This is the load-bearing piece — the check digits are what the interbank system rejects on if wrong.

Topologically simpler than module 1A (no DB, no file I/O beyond the input fixture) but the **check-digit arithmetic** exposed two new methodology rules — see §5.

---

## 3. What we did, phase by phase

### Phase A — Discovery + GnuCOBOL adaptation + golden master capture

Original sources came in at [sources/cobol-demo2/](../../sources/cobol-demo2/) (`BCTITSCV.COB` + `BCTIYRCV.CPY`). Staged into [cobol/cci-account-converter/](../../cobol/cci-account-converter/) with the existing module layout (`original/`, `copybooks/`, `src/`, `fixtures/`).

**Four surgical CICS removals** to make the program run under GnuCOBOL standalone (no other edits — paragraph order, EVALUATE chains, COMPUTE chains, mid-EVALUATE `GOBACK`s all preserved verbatim per [CLAUDE.md](../../CLAUDE.md) rule 5):

| Original (line) | Original code | Adapted to | Why |
|---|---|---|---|
| 69 | `01 DFHCOMMAREA PIC X(01).` | (removed) | Standalone caller binds via `USING` directly |
| 82–85 | `EXEC CICS HANDLE ABEND LABEL(3000-FINAL) END-EXEC` | (removed) | No CICS runtime; no abend handler to register |
| 93–100 | `IF EIBCALEN GREATER 0 SET ADDRESS ... ELSE ... END-IF` | `CONTINUE.` | `EIBCALEN` is CICS; the "no commarea" branch is unreachable standalone |
| 265–267 | `EXEC CICS RETURN END-EXEC` | `GOBACK.` | Standard COBOL subroutine return |

Built `src/BCTITSCV-RUN.cbl` as a single fixed-format compile unit with an outer `DRIVER-BCTITSCV` (reads `requests.dat`, fills commarea, calls inner, displays result) and the nested adapted `BCTITSCV`. Mirrors the nested-PROGRAM-ID pattern from [`cobol/add-policy-facade/src/ADDPFCD.cbl`](../../cobol/add-policy-facade/src/ADDPFCD.cbl).

**3 fixtures** in [cobol/cci-account-converter/fixtures/](../../cobol/cci-account-converter/fixtures/):

| Fixture | `IND-CONV` | `FAM` | Exercises | Expected output |
|---|---|---|---|---|
| `01-cci-to-bcp-impacs` | `1` | `004` IMPACS | `0500` → `1000-VALIDA` (pass) → `0600 WHEN '0'` (IMPACS decode) | `RC=00`, `BCP-EDIT=00221502152345678112` |
| `02-bcp-to-cci-saving` | `2` | `005` SAVING | `0500` → `1000-VALIDA` (pass ST) → `1500-CALCULA-CHEQUEO-INT` → `2000` + `3000-CALCULA-DIGCHEQ-CUENTA` (the mod-10 math) | `RC=00`, `CUENTA-ITE=00221511234567811228` |
| `03-validation-error` | `1` | `999` (invalid) | `0500` → `1000-VALIDA` rule 1 fails → `GOBACK` | `RC=99`, `MSG=COD. SIST.NO VALIDO` |

**Captured golden master** (`./tools/run-cobol.sh cci-account-converter`): all 3 fixtures `exit_code=0` with deterministic stdout. **Check digits hand-verified** against the algorithm by independent calculation — fixture 02 produces `DIG-ITE1='2'` and `DIG-ITE2='8'` matching the by-hand mod-10 sums (8 and 42 → checks 2 and 8).

Output: [cobol/cci-account-converter/README.md](../../cobol/cci-account-converter/README.md) (16 KB, 8 sections — provenance, inventory, data dictionary, external I/O, control flow, validation rules, numerics with the Phase B / C flags, fixture inventory).

### Phase B — Structured spec

[specs/cci-account-converter.md](../../specs/cci-account-converter.md) — 11 sections per the [cobol-spec skill](../../.claude/skills/cobol-spec/SKILL.md) template, including:

- The **dual-purpose 20-byte input**: same bytes accessed via direct CCI view (for `IND-CONV='1'`) or one of two REDEFINES views `BCP-EDIT-IM` / `BCP-EDIT-ST` (for `IND-CONV='2'`, per family).
- The **validation rule order** as contract: rule 1 (family in {`004`,`007`,`005`,`009`}) → rule 2 (`COD-PRO` numeric) → rule 3a/3b (per-family numeric check on the REDEFINES view) → rule 4 (`IND-CONV` ∈ {`1`,`2`}, in `0500` `WHEN OTHER`).
- The **mod-10 algorithm in pseudocode** with explicit scale-0 / `RoundingMode.DOWN` / PIC-truncation rules so the Java translator can't drift.
- Six **SME review checklist items** (e.g., "Is the hard-coded bank ID `002` for BCP correct?", "Is silent fall-through for `IDT-CTA` not in {0,1,2} intentional?").
- A **traceability table** mapping every planned Java symbol to its COBOL paragraph + line range.

### Phase C — Java translation

[java/cci-account-converter/](../../java/cci-account-converter/) — Spring Boot 3.3, Java 21, **no JPA** (no DB), just `spring-boot-starter`. Layout matches the [java-translate skill](../../.claude/skills/java-translate/SKILL.md) template.

```
java/cci-account-converter/
├── pom.xml                                    # SB 3.3.5, Java 21, no DB
├── src/main/resources/application.properties  # banner/log suppression (3 lines)
└── src/main/java/com/example/poc/cciaccountconverter/
    ├── CciAccountConverterApplication.java    # @SpringBootApplication
    ├── batch/BatchRunner.java                 # mirrors DRIVER-BCTITSCV
    ├── domain/Commarea.java                   # the 200-byte TI-YRCV-PARAMETROS, mutable
    └── service/
        ├── BctitscvService.java               # orchestrator (0100 + 0500 + 3000-FINAL)
        ├── BctitscvValidator.java             # 1000-VALIDA (4 rules, short-circuit)
        ├── CciDecoder.java                    # 0600-CALCULA-CTA-COMERCIAL (3 IDT-CTA branches)
        ├── CciEncoder.java                    # 1500-CALCULA-CHEQUEO-INT
        └── CheckDigitCalculator.java          # 2000+3000-CALCULA-DIGCHEQ-* (the mod-10)
└── src/test/java/.../service/
    ├── CheckDigitCalculatorTest.java          # 7 tests
    └── BctitscvValidatorTest.java             # 6 tests
```

**Hard rules enforced** (per [CLAUDE.md](../../CLAUDE.md)):
- Every `PIC 9...` field becomes `BigDecimal` — including loop indices and digit accumulators. This module has zero monetary values, but the rule is unconditional (now codified explicitly — see §5).
- Every method carries a `// COBOL: BCTITSCV-RUN.cbl:<startLine>-<endLine>` traceability comment.
- REDEFINES handled via per-view getter methods (`getOfiBcpIm()` vs `getOfiBcpSt()`) over a single backing String — a lighter alternative to the sealed-interface form (now codified, see §5).
- Banner + log suppression in `application.properties` so Spring's startup banner doesn't leak into stdout and corrupt the diff.

**Unit tests** — 13/13 green on `mvn -B test`:
```
CheckDigitCalculatorTest    7 tests  (hand-pinned mod-10 values, edge cases on sum%10, non-digit rejection)
BctitscvValidatorTest       6 tests  (each rule, IM/ST branches, short-circuit ordering)
```

### Phase D — Equivalence validation

```bash
./tools/run-java.sh cci-account-converter
./tools/compare-outputs.py cci-account-converter
```

**Result on first integrated run** — all three fixtures byte-exact green:

```
[OK ] cci-account-converter/01-cci-to-bcp-impacs
[OK ] cci-account-converter/02-bcp-to-cci-saving
[OK ] cci-account-converter/03-validation-error
EXIT=0
```

[validation/reports/cci-account-converter.json](../../validation/reports/cci-account-converter.json):
```json
[
  { "fixture": "01-cci-to-bcp-impacs",  "module": "cci-account-converter", "diffs": [] },
  { "fixture": "02-bcp-to-cci-saving",  "module": "cci-account-converter", "diffs": [] },
  { "fixture": "03-validation-error",   "module": "cci-account-converter", "diffs": [] }
]
```

**Negative-control test** (required by [java-translate skill](../../.claude/skills/java-translate/SKILL.md) verification §5):

Deliberately changed the `×2` multiplier in `CheckDigitCalculator`'s even-position loop to `×1` to confirm the harness has teeth. Re-running just fixture 02:

```
[FAIL] cci-account-converter/02-bcp-to-cci-saving
  --- stdout.txt ---
  -CUENTA-ITE: 00221511234567811228
  +CUENTA-ITE: 00221511234567811209
EXIT=1
```

The byte-exact diff caught the corruption immediately (check digits `28` → `09`). Reverted to the correct multiplier; all 3 fixtures back to green. **Proves the diff harness is load-bearing on this module — green means green, not "nothing was checked".**

### Phase E — Crystallization

Three findings from this module were genuinely new (not subsumed by existing rules). Added two ADRs and four glossary entries.

**Two new ADRs** in [docs/DECISIONS.md](./DECISIONS.md):

- **ADR-11 — Integer-truncation arithmetic uses `RoundingMode.DOWN`, not `HALF_UP`.** ADR-4 governs `ROUNDED` clauses; this ADR fills the other half — a `MOVE` (or `COMPUTE`) whose target has no `V` truncates the fractional part. `BigDecimal.divide(divisor, 0, RoundingMode.DOWN)`. Distinct from HALF_UP — they diverge whenever the units digit of the dividend is ≥ 5.
- **ADR-12 — PIC narrow-store truncation is part of the algorithm, not an overflow.** BCTITSCV's mod-10 relies on `WS-UNO-NUMERO PIC 9(01) := 10 → 0` to compute `(10 - sum%10) % 10`. A Java translator who treats this as overflow throws an exception where the COBOL is silently producing the correct answer. Translation must reproduce explicitly with `result.remainder(BigDecimal.TEN)` (or the general `result.remainder(BigDecimal.valueOf(10).pow(N))`) — and the spec must annotate the source line as truncation-as-algorithm so it can't be "fixed" by mistake later.

**Four new glossary entries** in [docs/glossary.yaml](./glossary.yaml):
- `numerics.policy_scope_note` — codifies that the BigDecimal-mandate is **unconditional** (no carve-out for "non-monetary" / "loop index" / "counter").
- `numerics.integer_truncation_rule` — companion to ADR-11.
- `numerics.pic_truncation_load_bearing` — companion to ADR-12.
- `idioms.mod_10_check_digit` — names the pattern (Luhn-style ×1/×2 with digit-sum and final `(10-sum%10)%10`), notes that it recurs across national interbank codes (CCI/PE, CBU/AR, IBAN, CLABE/MX), and recommends extracting `CheckDigitCalculator` to a `commons` package the first time a second module needs it.
- `idioms.REDEFINES_simple_alternative` — codifies the per-view-getter form (a single backing String + `substring`-based accessors) as a valid lighter alternative to the sealed-interface form when the two views are flat groups of compatible types.

---

## 4. Results summary

| Layer | Command | Result |
|---|---|---|
| Phase A — COBOL toolchain | `./tools/run-cobol.sh cci-account-converter` | 3/3 fixtures captured, `exit_code=0` |
| Phase A — check-digit hand-verification | manual mod-10 over `OFIBAN-ITE='002215'` and `NUMERO-ITE='112345678112'` | DIG-ITE1=`2` ✓ DIG-ITE2=`8` ✓ (match captured stdout) |
| Phase C — Java unit tests | `mvn -B test` | **13 / 13 passed** |
| Phase D — equivalence diff | `./tools/compare-outputs.py cci-account-converter` | **3 fixtures, 0 diffs** |
| Phase D — negative control | `×2 → ×1` swap, re-run fixture 02 | Caught: stdout diff at `CUENTA-ITE`, exit 1 |
| Phase D — green after revert | re-run all fixtures | 3 / 3 green, exit 0 |

**Across all three reference modules** (run together via the `equivalence-validator` subagent or the three commands per [README §2](../../README.md#2-60-second-quickstart)):

| Module | Fixtures | Diffs |
|---|---|---|
| `add-motor-policy` (module 0) | 3 | 0 |
| `add-policy-db` (module 1B) | 2 | 0 |
| `add-policy-facade` (module 1A) | 1 | 0 |
| **`cci-account-converter` (module 2)** | **3** | **0** |
| **Total** | **9 fixtures across 4 modules** | **0 byte differences** |

---

## 5. New methodology output (Phase E findings)

These are the lessons this module taught the framework that no prior module had surfaced:

1. **Integer division vs. ROUNDED.** ADR-4 covered `ROUNDED` clauses (HALF_UP) but said nothing about plain assignment of a quotient into an integer PIC target. `BCTITSCV` exposed this gap. → **ADR-11** + glossary `numerics.integer_truncation_rule`.

2. **PIC narrow-store truncation as algorithm.** Banking COBOL frequently uses the silent drop of high digits as the algorithm (mod-10 reduction, etc.), not as an error condition. → **ADR-12** + glossary `numerics.pic_truncation_load_bearing`.

3. **BigDecimal rule is genuinely unconditional.** This module has zero monetary values yet uses BigDecimal throughout. Confirms the rule's value isn't "for money" but "to foreclose an entire class of bugs without per-field judgment". → glossary `numerics.policy_scope_note`.

4. **Mod-10 check digit is a recurring banking idiom.** CCI (Peru), CBU (Argentina), IBAN, CLABE (Mexico) all use variants. → glossary `idioms.mod_10_check_digit` with the canonical Java template, plus a note recommending `CheckDigitCalculator` go to `commons` when a second module needs it.

5. **REDEFINES has a lighter form than sealed interface.** When the two views are flat groups of compatible types and the calling code always knows which view is in play, a single backing String + per-view substring accessors is enough. → glossary `idioms.REDEFINES_simple_alternative`.

---

## 6. Files added or changed

### Added (untracked — pending commit decision)
- [cobol/cci-account-converter/](../../cobol/cci-account-converter/) — 9 files: `README.md`, `original/` × 2, `copybooks/` × 1, `src/BCTITSCV-RUN.cbl`, `fixtures/<3>/in/requests.dat`
- [java/cci-account-converter/](../../java/cci-account-converter/) — 12 source files (8 main + 2 tests + `pom.xml` + `application.properties`)
- [golden-master/cci-account-converter/](../../golden-master/cci-account-converter/) — captured outputs (9 files: `stdout.txt`, `exit_code`, `stderr.txt` × 3 fixtures)
- [specs/cci-account-converter.md](../../specs/cci-account-converter.md)
- [validation/reports/cci-account-converter.json](../../validation/reports/cci-account-converter.json)
- [docs/MODULE-2-REPORT.md](./MODULE-2-REPORT.md) — this report
- [sources/cobol-demo2/](../../sources/cobol-demo2/) — the original drop from the client (preserved untouched)

### Modified
- [docs/DECISIONS.md](./DECISIONS.md) — added ADR-11 and ADR-12 (before the "How to add an ADR" footer).
- [docs/glossary.yaml](./glossary.yaml) — added four entries under `numerics` and `idioms`.

### Already committed earlier in this session (commit `538b21e` on `origin/main`)
- [docs/RUNNING-WITH-CLAUDE.md](./RUNNING-WITH-CLAUDE.md) — operator's guide for adopting the framework with Claude Code, covering phases A→E with paste-ready prompts per phase.

---

## 7. What's next

Recommended follow-ups before declaring this module fully complete on par with module 1A/1B:

1. **Add a CTS fixture** (`BSC-COD-FAM='009'`) to exercise the `IF TI-YRCV-BSC-COD-FAM EQUAL '009' MOVE '2' TO TI-YRCV-PRO-ITE` branch in `1500` (currently uncovered — SAVING goes through but never sets `PRO-ITE='2'`).
2. **Add an IMPACS encode fixture** (`IND-CONV='2'`, family `004`) to exercise the `STRING '0' DELIMITED BY SIZE, NUM-BCP-IM DELIMITED BY SIZE INTO NUM-ITE` line in `1500` — the leading-zero pad on the 7-digit IMPACS account.
3. **Property-based tests** for `CheckDigitCalculator` using jqwik (the dependency is already in module 0's `pom.xml`). Generate random 6-digit and 12-digit strings, verify `check(check ‖ original) == 0` (the standard "self-validating" property of mod-10).
4. **Run the `equivalence-validator` subagent across all 4 modules** to confirm no regression elsewhere from the ADR changes.
5. **Commit decision.** The current working tree has all module 2 work + 2 ADR additions + 4 glossary entries uncommitted. Suggested commit message: `Module 2 (BCTITSCV / cci-account-converter): full A→E green` with the 2 ADRs and 4 glossary entries summarized in the body.

---

## Appendix — quick reproduction

From the repo root:

```bash
# Phase A: capture COBOL golden master
./tools/run-cobol.sh cci-account-converter

# Phase C verification: unit tests
( cd java/cci-account-converter && mvn -B test )

# Phase D: build + run Java + byte-exact diff
./tools/run-java.sh cci-account-converter
./tools/compare-outputs.py cci-account-converter

# Expected:
#   [OK ] cci-account-converter/01-cci-to-bcp-impacs
#   [OK ] cci-account-converter/02-bcp-to-cci-saving
#   [OK ] cci-account-converter/03-validation-error
#   exit 0
```

Or in a Claude Code session at the repo root:

> Run the `equivalence-validator` subagent for `cci-account-converter` and report `RESULT: GREEN` or `RESULT: RED`.
