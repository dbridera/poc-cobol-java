# poc-cobol-java

**LLM-driven COBOL → Java migration framework. Driven by Claude Code on a Pro/Max subscription — no API key, no LangChain.**

| | |
|---|---|
| Status | Modules **0**, **1A** (CICS facade), **1B** (DB / EXEC SQL), **2** (real BCP banking package), **3** (4-step JCL nightly batch, restart + abend) all end-to-end **GREEN** |
| Toolchain | GnuCOBOL 3.2 (BDB indexed files) + Java 21 + Maven 3.9 + Spring Boot 3.3 + JPA / Spring Batch + JDBC + H2 (+ SQLite shim for COBOL EXEC SQL) |
| Tests | 64 / 64 Java unit tests · **15 / 15 fixtures byte-exact equivalent** across 5 modules · 2 negative controls red-then-green · `check-module.sh --all` CONFORMANT |
| Sample source | Adapted from public [`cicsdev/cics-genapp`](https://github.com/cicsdev/cics-genapp) (modules 0/1A/1B) + Banco de Crédito del Perú `BCTITSCV` (module 2, real banking) + [AWS CardDemo](https://github.com/aws-samples/aws-mainframe-modernization-carddemo) nightly close, **verbatim** (module 3, Apache-2.0) |

---

## 1. What is this?

A proof-of-concept for migrating banking COBOL to Java with LLMs **and** proving the new code does exactly what the old code does — byte-for-byte.

The hard part isn't writing Java. The hard part is being *certain* the Java preserves the COBOL's behavior. We do that by:

1. Running the original COBOL on **GnuCOBOL** to capture inputs and exact outputs ("golden master").
2. Having Claude Code translate it to **Spring Boot 3 + JPA + BigDecimal**.
3. Replaying the same inputs through the Java and **diffing byte-for-byte**.

If the diff is green, the translation is correct.

---

## 2. 60-second quickstart

Pre-requisite: toolchain (see §8). After that, from the repo root, **one command runs all five modules end-to-end**:

```bash
./tools/demo-commands.sh all
```

Prints phase headers (A / C / D), echoes each command, runs the conformance gate, and ends with a computed proof block: 15 / 15 fixtures byte-exact equivalent across modules 0, 1A, 1B, 2, 3.

Per-module subcommands are below. For the full narrative + talking points, see [`docs/demo/DEMO.md`](./docs/demo/DEMO.md).

### Raw commands (for live typing / debugging)

```bash
# Module 0 — file I/O (VSAM-equivalent)
./tools/run-cobol.sh    add-motor-policy
./tools/run-java.sh     add-motor-policy
./tools/compare-outputs.py add-motor-policy

# Module 1B — EXEC SQL → JPA + H2
./tools/run-cobol-db.sh add-policy-db
./tools/run-java.sh     add-policy-db
./tools/compare-outputs.py add-policy-db

# Module 1A — CICS LINK chain → Spring service-to-service DI
./tools/run-cobol-db.sh add-policy-facade
./tools/run-java.sh     add-policy-facade
./tools/compare-outputs.py add-policy-facade

# Module 2 — real BCP banking package (CCI ↔ commercial account, mod-10 check digits)
./tools/run-cobol.sh    cci-account-converter
./tools/run-java.sh     cci-account-converter
./tools/compare-outputs.py cci-account-converter

# Module 3 — 4-step JCL nightly batch (CardDemo), 16 manifest steps, restart + abend fixtures
./tools/run-job.sh      nightly-batch          # == run-cobol.sh (dispatches on job.json)
./tools/run-java.sh     nightly-batch
./tools/compare-outputs.py nightly-batch
```

Expected output across all 5 modules:

```
[OK ] add-motor-policy/01-happy-small
[OK ] add-motor-policy/02-validation-errors
[OK ] add-motor-policy/03-numeric-boundaries
[OK ] add-policy-db/01-happy-small
[OK ] add-policy-db/02-sql-errors
[OK ] add-policy-facade/01-happy-chain
[OK ] cci-account-converter/01-cci-to-bcp-impacs
[OK ] cci-account-converter/02-bcp-to-cci-saving
[OK ] cci-account-converter/03-validation-error
[OK ] nightly-batch/01-happy-small   (files 44 · records 397 · bytes 77449 · differing 0)
[OK ] nightly-batch/02-rejects   (files 44 · records 318 · bytes 54090 · differing 0)
[OK ] nightly-batch/03-numeric-boundaries   (files 44 · records 237 · bytes 33539 · differing 0)
[OK ] nightly-batch/04-full-carddemo   (files 44 · records 3377 · bytes 792762 · differing 0)
[OK ] nightly-batch/05-restart   (files 44 · records 408 · bytes 77939 · differing 0)
[OK ] nightly-batch/06-abend-discgrp   (files 30 · records 115 · bytes 8981 · differing 0)
```

Plus JSON proof artifacts under `validation/reports/` — `"diffs": []` per fixture, with a `summary` of records and bytes compared.

---

## 2.5. Running the five example modules

| Module | What it proves | Command |
|---|---|---|
| 0 | VSAM / file access | `./tools/demo-commands.sh module-0` |
| 1B | DB2 / EXEC SQL → JPA | `./tools/demo-commands.sh module-1b` |
| 1A | CICS LINK → Spring service-to-service DI | `./tools/demo-commands.sh module-1a` |
| 2 | Real banking package + mod-10 check digits | `./tools/demo-commands.sh module-2` |
| 3 | 4-step JCL nightly batch: VSAM updated in place, sorts, step-level restart, abend | `./tools/demo-commands.sh module-3` |
| NC | Negative control: flip one rounding mode → red diff at a named record/column → revert | `./tools/demo-commands.sh negative-control` |
| — | Conformance: every module went through the same five phases with the same tooling | `./tools/demo-commands.sh conformance` |
| **all** | the five modules + conformance + computed cross-module proof block | `./tools/demo-commands.sh all` |

Each subcommand prints a per-phase narrative (A / C / D) and a RESULT summary citing the ADR(s) that module surfaced. Add `--quiet` to suppress narration. Full talking points + Q&A: [`docs/demo/DEMO.md`](./docs/demo/DEMO.md).

---

## 2.6. Translating a new COBOL module

Drop your COBOL under `cobol/<your-module>/src/*.cbl` (and copybooks under `cobol/<your-module>/copybooks/*.cpy`), open Claude Code at the repo root, and follow phases A → E using the skills under [`.claude/skills/`](./.claude/skills/). Each phase has a paste-ready prompt in [`docs/methodology/RUNNING-WITH-CLAUDE.md`](./docs/methodology/RUNNING-WITH-CLAUDE.md). The five-phase shape and rationale are explained in [`docs/methodology/METHODOLOGY.md`](./docs/methodology/METHODOLOGY.md). The hard rules every session must follow are in [`CLAUDE.md`](./CLAUDE.md).

Phase A produces both a prose `README.md` and a structured `DEPENDENCIES.md` (asset map: programs, paragraph PERFORM tree, external CALLs, copybooks, files, EXEC SQL, EXEC CICS, entry points — 8 fixed sections per [`.claude/skills/cobol-analyze/SKILL.md`](./.claude/skills/cobol-analyze/SKILL.md) §4.5). Phase B produces `specs/<your-module>.md`. Phase C produces `java/<your-module>/`. Phase D produces `validation/reports/<your-module>.json` with `"diffs": []` per fixture.

---

## 3. Methodology — five phases

| Phase | What happens | Output | Skill file |
|---|---|---|---|
| **A — Discovery** | Pick a module, get it runnable on GnuCOBOL, design fixtures, capture golden master | `cobol/<m>/README.md` + `cobol/<m>/DEPENDENCIES.md` (asset map), `golden-master/<m>/` | `.claude/skills/cobol-analyze/` |
| **B — Spec** | Claude writes a structured spec doc reviewable by a banking SME (data dictionary, control flow, edge cases). COBOL stays the source of truth. | `specs/<m>.md` | `.claude/skills/cobol-spec/` |
| **C — Translation** | Spring Boot 3 + JPA + Java 21. `BigDecimal` everywhere, traceability comments back to COBOL line ranges. | `java/<m>/` | `.claude/skills/java-translate/` |
| **D — Validation** | Replay golden-master fixtures against the Java; byte-exact diff. | `validation/reports/<m>.json` | `.claude/skills/equivalence-validate/` |
| **E — Framework** | Extract reusable skills + subagents from each module's lessons. | `.claude/skills/`, `.claude/agents/` | (this column) |

The full plan with rationale is at `~/.claude/plans/breezy-tinkering-mccarthy.md`. The hard rules every Claude session must follow are at [`CLAUDE.md`](./CLAUDE.md).

---

## 4. What lives where

```
poc-cobol-java/
├── README.md                          this file (entry point)
├── CLAUDE.md                          hard rules — every Claude session reads this
├── docs/
│   ├── methodology/                   permanent framework docs (10 files)
│   │   ├── METHODOLOGY.md             why the 5-phase shape
│   │   ├── DECISIONS.md               16 ADRs (load-bearing methodology choices)
│   │   ├── glossary.yaml              COBOL → Java idiom + naming map (the "RAG")
│   │   ├── SKILLS-GUIDE.md            handoff contracts between phases
│   │   ├── SCALING.md                 what the green diff does + doesn't prove
│   │   ├── RUNNING-WITH-CLAUDE.md     operator's guide for adopting the framework
│   │   ├── PRESENTATION.md            5-minute stakeholder explainer
│   │   ├── EXECUTIVE-REPORT.md        executive summary
│   │   ├── POC-COMPLETION-REPORT.md   full completion report
│   │   ├── MODULE-2-REPORT.md         module 2 session report
│   │   └── MODULE-3-REPORT.md         module 3 session report (multi-step batch)
│   ├── demo/
│   │   └── DEMO.md                    reproduce the full demo end-to-end
│   └── reference/                     drop the Anthropic playbook PDF here
│
├── cobol/
│   ├── add-motor-policy/              MODULE 0 — VSAM / file I/O
│   ├── add-policy-db/                 MODULE 1B — DB2 / EXEC SQL → JPA
│   ├── add-policy-facade/             MODULE 1A — CICS LINK → Spring DI
│   ├── cci-account-converter/         MODULE 2 — real BCP package (BCTITSCV)
│   │   ├── README.md                  prose Phase A doc (provenance, data dictionary, ...)
│   │   ├── DEPENDENCIES.md            structured 8-section asset map (Phase A)
│   │   ├── original/                  verbatim sources from the client
│   │   ├── src/                       adapted COBOL (compile unit)
│   │   ├── copybooks/                 lowercase copy for the GnuCOBOL -I path
│   │   └── fixtures/<n>/in/requests.dat
│   └── genapp-source/                 unmodified GenApp originals (traceability)
│
├── golden-master/<module>/<fixture>/  captured COBOL outputs (stdout, exit_code, out/)
│
├── specs/<module>.md                  structured spec (Phase B)
│
├── java/<module>/                     Spring Boot project (Phase C)
│   ├── pom.xml
│   └── src/{main,test}/java/com/example/poc/<module>/...
│
├── java-run/<module>/<fixture>/       regenerable; outputs from Java side
│
├── validation/reports/<module>.json   machine-readable diff proof
│
└── tools/
    ├── setup.md                       toolchain install instructions
    ├── run-cobol.sh                   compile + run COBOL (file-only), capture golden master
    ├── run-cobol-db.sh                same, for modules using the libcob_sqlite shim
    ├── run-java.sh                    package + run Spring Boot, capture java-run
    ├── compare-outputs.py             byte-exact diff harness
    ├── demo-commands.sh               narrated wrapper for the four reference modules
    ├── capture-fixtures.sh            batch wrapper for run-cobol.sh
    └── make-fixture.py                generate fixed-width requests.dat from JSON spec
```

VS Code suggestions:
- Recommended extensions: `bito.cobol`, `redhat.java`, `vscjava.vscode-maven`, `ms-python.python`.
- Open the workspace at the repo root; the `.claude/` directory already has skills + a settings file.

---

## 5. What's been tested — and the results

### Three layers of testing, all green on the latest run:

| Layer | Command | Result |
|---|---|---|
| Toolchain self-test | `./tools/run-cobol.sh --self-test` | OK (compiles + runs hello-world COBOL) |
| Java unit tests | `mvn -B test` per module | **64 / 64 passed across 5 modules** (35 + 29) |
| Behavioral equivalence | `./tools/demo-commands.sh all` | **15 fixtures · 5 modules · 0 bytes diverging** (module 3 alone: 44 files, ~4 850 records, ~1.04 MB compared per full run) |
| Process conformance | `./tools/check-module.sh --all` | **5 / 5 modules CONFORMANT** |

### Cross-module result table

| Module | What it proves | Fixtures | Diffs | Empirical finding codified |
|---|---|---|---|---|
| 0 — `add-motor-policy` | VSAM / file access | 3 | 0 | HALF_UP not HALF_EVEN ([ADR-4](./docs/methodology/DECISIONS.md)) |
| 1B — `add-policy-db` | DB2 / EXEC SQL → JPA + H2 | 2 | 0 | `em.persist + flush` over `JpaRepository.save` ([ADR-9](./docs/methodology/DECISIONS.md)) |
| 1A — `add-policy-facade` | CICS LINK → Spring DI | 1 | 0 | same-JVM Spring DI for PoC scope ([ADR-10](./docs/methodology/DECISIONS.md)) |
| 2 — `cci-account-converter` | Real BCP banking package + mod-10 check digits | 3 | 0 | Integer-division `RoundingMode.DOWN` ([ADR-11](./docs/methodology/DECISIONS.md)) + PIC narrow-store truncation as algorithm ([ADR-12](./docs/methodology/DECISIONS.md)) |
| 3 — `nightly-batch` | 4-step JCL nightly close (CardDemo, verbatim): KSDS updated in place, sorts, restart, abend, overpunched signs | 6 | 0 | JDBC over JPA for batch ([ADR-13](./docs/methodology/DECISIONS.md)) · job manifest + step-level restart ([ADR-14](./docs/methodology/DECISIONS.md)) · tasklet per program ([ADR-15](./docs/methodology/DECISIONS.md)) · determinism pins ([ADR-16](./docs/methodology/DECISIONS.md)) |
| **Total** | — | **15** | **0** | 9 ADRs across 5 modules |

### Equivalence proofs

Per-fixture `"diffs": []` in every `validation/reports/<module>.json`. Cross-module summary by running `./tools/demo-commands.sh proof`. Module 2 example:

```json
[
  { "fixture": "01-cci-to-bcp-impacs",  "module": "cci-account-converter", "diffs": [] },
  { "fixture": "02-bcp-to-cci-saving",  "module": "cci-account-converter", "diffs": [] },
  { "fixture": "03-validation-error",   "module": "cci-account-converter", "diffs": [] }
]
```

`diffs: []` means COBOL and Java agree on **every byte** of every output channel — stdout, exit code, output files, table dumps, and error logs.

### What the 14 records actually exercise

- All four CC brackets (≤1000, ≤1600, ≤2000, >2000) including the boundary values.
- All five validation rules (zero customer, zero CC, zero value, blank issue date, blank expiry date) — each one fires once.
- The unknown-request-id branch (RC=99).
- Numeric overflow trap (RC=11) on `999 999 accidents × 50` — both sides produce the identical error log line.
- The HALF_UP rounding rule (record producing `512.50 → 513`).

### Empirical findings the harness surfaced

These are *not* theoretical — every one was caught by running the diff:

1. **Default COBOL `ROUNDED` is HALF_UP, not HALF_EVEN.** Caught by module 0 record 2 of fixture 01 (`350 + 22500×0.005 + 50 = 512.50 → 513`). HALF_EVEN would give 512. → [ADR-4](./docs/methodology/DECISIONS.md).
2. **`EVALUATE TRUE` is short-circuit.** Reports the first failing rule, not all of them. Java preserves order.
3. **`ON SIZE ERROR` keeps its return code per paragraph.** A single top-level Java `catch` flattens this and loses the granular RC=11.
4. **Spring Boot banner + startup logs leak into stdout.** `application.properties` has `logging.level.root=OFF`, `spring.main.banner-mode=off`, `spring.main.log-startup-info=false`.
5. **Copybook `REDEFINES` is two interpretations of the same bytes** — must use a sealed interface or distinct view classes, never a single nullable bag. Module 2 codified a lighter [REDEFINES alternative](./docs/methodology/glossary.yaml) for flat-group views.
6. **`JpaRepository.save()` is INSERT-OR-UPDATE (MERGE), not INSERT.** Caught by module 1B fixture 02-sql-errors (duplicate PK). COBOL `EXEC SQL INSERT` throws on duplicate; `save()` silently overwrites. Fix: `EntityManager.persist() + em.flush() + @Transactional(REQUIRES_NEW)`. → [ADR-9](./docs/methodology/DECISIONS.md).
7. **Integer-division arithmetic uses `RoundingMode.DOWN`, not `HALF_UP`.** Caught by module 2 — the mod-10 check-digit calculation breaks if HALF_UP rounds `sum/10` upward. Distinct from ADR-4 (which governs `ROUNDED`). → [ADR-11](./docs/methodology/DECISIONS.md).
8. **PIC narrow-store truncation is part of the algorithm, not an overflow.** Module 2's mod-10 relies on `WS-UNO-NUMERO PIC 9(01) := 10 → 0` to compute `(10 - sum%10) % 10`. Java must reproduce explicitly with `result.remainder(BigDecimal.TEN)`. → [ADR-12](./docs/methodology/DECISIONS.md).
9. **Negative-control test confirmed (module 2).** Deliberately changing the `×2` multiplier in `CheckDigitCalculator` to `×1` produced a clean `[FAIL]` on fixture 02 (`CUENTA-ITE: ...28 → ...09`, exit 1). Reverted to green. The harness has teeth.
10. **`COMPUTE` without `ROUNDED` truncates toward zero** (module 3: `(balance × rate) / 1200` → 0.09575 becomes 0.09, −11.4875 becomes −11.48). Flipping the Java to `HALF_UP` turns fixture 03 red at `acctfile.unl` record 1 column 24 (`E` → `F`, one cent). Reverted.
11. **COBOL `INITIALIZE` leaves FILLER untouched.** The first Java run of module 3 was red on exactly 22 bytes per created category-balance row: the seed rows carry zero-filled FILLER, `READ … INTO` copies it into working storage, `INITIALIZE` keeps it, `WRITE` persists it. Verified on GnuCOBOL, fixed in `CobolRecord.initialize()`.
12. **Real legacy defects survive translation on purpose.** CardDemo's interest program never updates the last account (`CBACT04C.cbl:219-221`, unreachable `ELSE`) and its report overstates the grand total by the last amount (`CBTRN03C.cbl:197-204`, stale record at EOF). Both are replicated, cited in the Java, listed in the spec's SME checklist; "fixing" the first one turns fixture 01 red at `acctfile.unl` record 2.
13. **The pinned clock needs hundredths.** `COB_CURRENT_DATE="2022/07/18 00:00:00"` froze the seconds but the DB2 timestamps kept ticking in the hundredths; the fractional form `…:00.00` makes `FUNCTION CURRENT-DATE` constant. No source change needed.

### What we did NOT yet run (honest disclaimer)

- **Property-based tests** (jqwik dependency is in module 0's `pom.xml`) — still a placeholder; only module 2 has hand-pinned mod-10 cases.
- **Cross-COBOL-implementation check.** Only GnuCOBOL was used. A real migration should also run the original on the mainframe at least once and confirm GnuCOBOL produces the same golden master.
- **Negative-control on modules 0 / 1A / 1B.** Modules 2 and 3 proved teeth (module 3 twice); the other three still trust the harness without a same-module proof.
- **An all-EBCDIC-input fixture for module 3.** The EBCDIC seed files are decoded and checked against the ASCII fixtures, and `CODE-SET IS EBCDIC` was verified on GnuCOBOL, but no job run reads EBCDIC end to end yet.

---

## 6. How to work on this in VS Code

### Run everything from the integrated terminal

```bash
# from the repo root
./tools/run-cobol.sh add-motor-policy
./tools/run-java.sh  add-motor-policy
./tools/compare-outputs.py add-motor-policy
```

If `cobc`, `java`, or `mvn` are not on PATH for your terminal session:

```bash
export PATH="/usr/local/bin:/usr/local/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/usr/local/opt/openjdk@21"
```

### Common tasks

| Task | Where to edit | Then |
|---|---|---|
| Run all four reference modules end-to-end | n/a | `./tools/demo-commands.sh all` |
| Change a fixture's data | `cobol/<module>/fixtures/<name>/spec.json` | `python3 tools/make-fixture.py spec.json in/requests.dat`, then re-run the three commands above |
| Add a new fixture | new dir under `cobol/<module>/fixtures/` with `spec.json` | same as above |
| Change COBOL business logic | `cobol/<module>/src/*.cbl` | re-run all three commands; the diff will show what changed |
| Change Java translation | `java/<module>/src/main/java/...` | `mvn -B test` from the module dir, then `./tools/run-java.sh && ./tools/compare-outputs.py` |
| Add a new module from scratch | follow [`docs/methodology/RUNNING-WITH-CLAUDE.md`](./docs/methodology/RUNNING-WITH-CLAUDE.md) — paste-ready prompt per phase | `cobol-analyze` → `cobol-spec` → `java-translate` → `equivalence-validate` → crystallize |

### Debugging a red diff

`compare-outputs.py` prints unified diffs. The most common causes:

| Symptom | Fix |
|---|---|
| Spring Boot banner / log lines in stdout | check `java/<m>/src/main/resources/application.properties` |
| Off-by-one numeric value (e.g. 512 vs 513) | wrong rounding mode — default COBOL = HALF_UP |
| Trailing spaces appearing/disappearing | LINE SEQUENTIAL trimming — see `BatchRunner.writeErr` |
| `requests.dat` shows up as "missing in java" | `run-cobol.sh` should not capture inputs (already fixed) |
| Different policy numbers | counter not reset to 1 — both sides start fresh per run |

Full troubleshooting table at `.claude/skills/equivalence-validate/SKILL.md`.

### Working with Claude Code in this repo

The `.claude/` directory has six skills and one subagent. From a Claude Code session at the repo root:

- `cobol-analyze` — phase A discovery for a new module
- `cobol-spec` — phase B spec doc generation
- `java-translate` — phase C Spring Boot translation rules
- `equivalence-validate` — phase D byte-exact diff protocol
- `copybook-to-entity` — copybook → JPA `@Entity` / record DTO conversion
- `agents/equivalence-validator.md` — read-only subagent that runs phases A+C+D and reports green/red

The repo-root [`CLAUDE.md`](./CLAUDE.md) is loaded automatically at session start.

---

## 7. Module zero details — `add-motor-policy`

A single batch program adapted from GenApp's `LGAPDB01` (ADD POLICY → INSERT MOTOR path). For each motor-policy add request in `requests.dat`:

1. Validate the request (5 ordered rules — see spec §4).
2. Calculate the premium: `base(cc) + 0.005·value + 50·accidents`, rounded HALF_UP, with overflow trap.
3. Append a row to `policy.dat` and a row to `motor.dat`.
4. On any failure, write to `error.log` and emit an `ERR` line on stdout.

**Provenance** — what was kept verbatim, what was adapted, what was added — is documented at `cobol/add-motor-policy/README.md`. The full structured spec is at `specs/add-motor-policy.md` (10 sections, including SME review checklist).

---

## 8. Toolchain setup

This machine already has `gnu-cobol`, `openjdk@21`, and `maven` installed via Homebrew. Verification:

```bash
/usr/local/bin/cobc --version | head -1                        # cobc (GnuCOBOL) 3.2.0
/usr/local/opt/openjdk@21/bin/java -version 2>&1 | head -1    # openjdk version "21.0.11"
/usr/local/bin/mvn -v | head -1                                # Apache Maven 3.9.15
```

Full install instructions (Homebrew, sdkman, devcontainer alternatives) at [`tools/setup.md`](./tools/setup.md).

PostgreSQL is **not** required for module zero (the Java side writes flat files to enable byte-exact diffing). Module 1+ will need it; install steps are in `tools/setup.md`.

---

## 9. Limitations + next steps

### Out of scope for this PoC
Cross-JVM CICS LINK (REST/RPC equivalents) · CICS online dialog / BMS · DB2 cursors in batch · GDG generation management · an all-EBCDIC-input job run (the overpunch, binary diff and seed check are done) · vector-DB RAG · production CI/CD · mainframe deployment · performance (see `docs/methodology/SCALING.md`).

### Recommended next moves

1. **Run the negative-control test on modules 0 / 1A / 1B.** Module 2 proved harness teeth; the other three still trust the harness without a same-module proof. Half a day each.
2. **Add an IMPACS-encode + CTS fixture** to module 2 to cover the two paragraphs that 3 fixtures don't yet exercise (`1500` IMPACS branch, `1500` CTS-override branch). See [docs/methodology/MODULE-2-REPORT.md §7](./docs/methodology/MODULE-2-REPORT.md).
3. **Real Postgres** — flip `application.properties` `spring.datasource.url` from `jdbc:h2:mem:` to `jdbc:postgresql://...`. The JPA layer is unchanged.
4. **Property-based tests** with jqwik for the mod-10 check digit (canonical self-validating property: `check(payload ‖ check(payload)) == 0`).
5. **Drop the Anthropic Code Modernization Playbook PDF** into `docs/reference/` and reconcile any deltas with the methodology.

---

## 10. Key documents at a glance

| Want to know… | Read |
|---|---|
| **Reproduce the demo end-to-end** | [`docs/demo/DEMO.md`](./docs/demo/DEMO.md) |
| **Adopt the framework on a new COBOL module** | [`docs/methodology/RUNNING-WITH-CLAUDE.md`](./docs/methodology/RUNNING-WITH-CLAUDE.md) |
| What this is and why (5 min stakeholder pitch) | [`docs/methodology/PRESENTATION.md`](./docs/methodology/PRESENTATION.md) |
| Why the 5-phase shape (engineering rationale) | [`docs/methodology/METHODOLOGY.md`](./docs/methodology/METHODOLOGY.md) |
| Hard rules every Claude session must follow | [`CLAUDE.md`](./CLAUDE.md) |
| Handoff contracts between phases (skill ↔ skill) | [`docs/methodology/SKILLS-GUIDE.md`](./docs/methodology/SKILLS-GUIDE.md) |
| What the green diff does NOT prove (honesty) | [`docs/methodology/SCALING.md`](./docs/methodology/SCALING.md) |
| Naming + idiom map for the translator | [`docs/methodology/glossary.yaml`](./docs/methodology/glossary.yaml) |
| 16 ADRs — load-bearing methodology choices | [`docs/methodology/DECISIONS.md`](./docs/methodology/DECISIONS.md) |
| Full completion + executive reports | [`docs/methodology/POC-COMPLETION-REPORT.md`](./docs/methodology/POC-COMPLETION-REPORT.md) · [`docs/methodology/EXECUTIVE-REPORT.md`](./docs/methodology/EXECUTIVE-REPORT.md) |
| Module 2 session report (real-banking deep dive) | [`docs/methodology/MODULE-2-REPORT.md`](./docs/methodology/MODULE-2-REPORT.md) |
| Module 3 session report (multi-step batch, restart, faithful defects) | [`docs/methodology/MODULE-3-REPORT.md`](./docs/methodology/MODULE-3-REPORT.md) |
| Per-module spec (byte-exact contract) | `specs/<module>.md` |
| Per-module asset / dependency map | `cobol/<module>/DEPENDENCIES.md` |
| Approved methodology plan | `~/.claude/plans/breezy-tinkering-mccarthy.md` |
