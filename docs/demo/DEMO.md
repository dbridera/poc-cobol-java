# Demo — reproduce the full PoC end-to-end

**One file. Everything you need to re-run the five-module COBOL → Java demo on a clean machine and confirm 15 / 15 byte-exact equivalent.**

For the *why* behind the methodology (5-phase framework, hard rules, ADRs), see [../methodology/](../methodology/). This doc is the **how** — setup, commands, expected output, and the talking points you'll hit when someone asks "wait, how did that actually work?"

---

## 1. What this demo proves

| | |
|---|---|
| **Modules** | 5 — `add-motor-policy` (VSAM) · `add-policy-db` (DB2/SQL) · `add-policy-facade` (CICS LINK) · `cci-account-converter` (real BCP banking package) · `nightly-batch` (4-step JCL nightly close from AWS CardDemo, verbatim) |
| **Fixtures** | 15 — 3 + 2 + 1 + 3 + 6 |
| **Byte differences** | **0** across all 15 fixtures, all output channels (stdout, exit code, files, table dumps, binary fixed-length datasets, job log) |
| **Java tests** | 64 unit tests across the 5 modules — all green |
| **Negative control** | Module 2: corrupting one BigDecimal multiplier → clean `[FAIL]`. Module 3: flipping `RoundingMode.DOWN` to `HALF_UP` → red at `acctfile.unl` record 1 column 24 (one cent); "fixing" the interest program's unreachable ELSE → red at record 2. All reverted to green |
| **Process conformance** | `./tools/check-module.sh --all` — every module carries the same Phase A–E artefacts and passed the same tooling |
| **What this is NOT** | A claim that AI alone produces correct Java. It's a claim that **AI + a byte-exact diff harness** produces *verifiably* correct Java — and the harness has teeth. |

---

## 2. Prerequisites

Toolchain (already installed via Homebrew on the demo machine):

```bash
cobc --version | head -1     # cobc (GnuCOBOL) 3.2.0
java -version 2>&1 | head -1 # openjdk version "21.0.x"
mvn -v | head -1             # Apache Maven 3.9.x
```

If any is missing, see [../../tools/setup.md](../../tools/setup.md).

PATH sanity (the demo machine sometimes needs this in non-login shells):

```bash
export PATH="/usr/local/bin:/usr/local/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/usr/local/opt/openjdk@21"
```

Repo state should be clean (committed or stashed) — the demo script writes into `golden-master/`, `java-run/`, `validation/reports/`, and the per-module `bin/` and `target/` directories. None of these are committed normally.

---

## 3. The five modules

### Module 0 — `add-motor-policy` (VSAM / file access)

Stakeholder concern this answers: **"how do you handle VSAM / file I/O?"**

A single batch program. For each request in `requests.dat`: validate, calculate the motor premium, append rows to `policy.dat` + `motor.dat`, write rejects to `error.log`. The Java side does the same with `java.nio.file`.

- **3 fixtures**: happy path (3 records), validation errors (5 rules, each fired once), numeric boundaries (overflow at PIC 9(6)V99 ceiling).
- **Channels diffed**: stdout, exit code, `policy.dat`, `motor.dat`, `error.log`.
- **Empirical finding codified** ([../methodology/DECISIONS.md ADR-4](../methodology/DECISIONS.md)): **default COBOL `ROUNDED` is `HALF_UP`, not `HALF_EVEN`**. Caught by fixture 01 record 2: `350 + 22500×0.005 + 50 = 512.50 → 513`, not 512.

### Module 1B — `add-policy-db` (DB2 / EXEC SQL → JPA + H2)

Stakeholder concern: **"how do you handle DB2 / databases?"**

COBOL `EXEC SQL INSERT INTO POLICY VALUES (...)` against SQLite (via the libcob_sqlite shim). Java `EntityManager.persist(entity); em.flush()` against H2. Both dump the `POLICY` table to a deterministic CSV — diffed byte-for-byte.

- **2 fixtures**: happy path (3 rows), SQL errors (duplicate PK on the 4th row).
- **Channels diffed**: stdout, exit code, `policy.csv`.
- **Empirical finding** ([../methodology/DECISIONS.md ADR-9](../methodology/DECISIONS.md)): **`JpaRepository.save()` is `INSERT-OR-UPDATE (MERGE)`, not `INSERT`**. Caught by fixture 02: COBOL throws on duplicate PK, `save()` silently overwrites. Fix: `EntityManager.persist() + em.flush() + @Transactional(REQUIRES_NEW)`.

### Module 1A — `add-policy-facade` (CICS LINK → Spring service-to-service DI)

Stakeholder concern: **"how do you handle CICS / the COBOL orchestrator?"**

Two COBOL programs chained: the outer facade `CALL`s the nested DB program (GnuCOBOL stand-in for `EXEC CICS LINK PROGRAM`). Java mirrors with `PolicyFacadeService` `@Autowired`-calling `PolicyInsertService`.

- **1 fixture**: happy path showing the chained execution end-to-end.
- **Channels diffed**: stdout from both levels + `policy.csv`.
- **Empirical finding** ([../methodology/DECISIONS.md ADR-10](../methodology/DECISIONS.md)): **`EXEC CICS LINK` → same-JVM Spring DI for this PoC scope.** Cross-JVM mappings (REST / gRPC) deferred to a module that actually needs them.

### Module 2 — `cci-account-converter` (real banking package — Banco de Crédito del Perú)

Stakeholder concern: **"does this work on a real legacy program, not just GenApp samples?"**

The `BCTITSCV` program from BCP's online interbank-transfer system (Feb 2015). Bidirectional converter between Peruvian CCI (interbank code) and the bank's commercial-account format. The hard part: a **Luhn-style mod-10 check-digit calculation** with alternating ×1/×2 multipliers and digit sums.

- **3 fixtures**: CCI → IMPACS commercial decode, BCP commercial → CCI encode (the mod-10 path), validation error.
- **Channels diffed**: stdout, exit code.
- **Empirical findings** (two new ADRs from this module):
  - [ADR-11](../methodology/DECISIONS.md): **integer division uses `RoundingMode.DOWN`, not `HALF_UP`** (companion to ADR-4 which covers `ROUNDED`).
  - [ADR-12](../methodology/DECISIONS.md): **PIC narrow-store truncation is part of the algorithm, not an overflow** — `WS-UNO-NUMERO PIC 9(01) := 10 → 0` is how COBOL computes `mod 10`. Java must reproduce with `result.remainder(BigDecimal.TEN)`.

Full session report: [../methodology/MODULE-2-REPORT.md](../methodology/MODULE-2-REPORT.md).

### Module 3 — `nightly-batch` (a real 4-step JCL batch job — AWS CardDemo nightly close)

Stakeholder concern this answers: **"how do you handle real batch — JCL with several steps, VSAM files updated in place, sort steps, restart after a crash, abends, and the signed data formats that only exist on the mainframe?"**

Three CardDemo programs **kept byte-for-byte verbatim** (`CBTRN02C` posting, `CBACT04C` interest, `CBTRN03C` report) run as one job of 16 steps described by [`cobol/nightly-batch/job.json`](../../cobol/nightly-batch/job.json), the JCL analogue: six KSDS loads, **post the day's transactions**, back up, **charge monthly interest**, **sort + reload the transaction master**, **unload + sort + print the daily report**, two capture unloads. The Java side is Spring Batch, one Step per JCL step built from the *same* manifest, with the KSDS files as H2 tables accessed through JDBC.

- **6 fixtures**: happy (accounts 1-5), rejects (reason codes 100/101/102/103 and their precedence), numeric boundaries (truncation toward zero, overflow without `ON SIZE ERROR`, a 10-digit cycle total truncated so a 50.00 purchase passes a 100.00 limit), the full seed set (300 transactions, 18 report pages), **restart** (killed after step 2 of 4, resumed — outputs identical to the unbroken run), **abend** (unknown category → `CEE3ABD`, RC 12, later steps `NOT RUN`, capture steps still run).
- **Channels diffed per fixture**: per-step stdout and return code, the **paragraph trace** of every step (one line per paragraph GnuCOBOL enters; the Java emits the same lines — 5 743 entries on the full fixture), the job log, and 9 fixed-length binary datasets (rejects, backups, interest transactions, the sorted master, the report, the unloads of the two files rewritten in place) — 60 files per fixture.
- **Translator tooling** (ADR-17): a red diff names the field (`record 1 (ACCT-ID=00000000001): ACCT-CURR-BAL cobol=201.75 java=201.76`) or the first divergent paragraph; the coverage matrix in [`cobol/nightly-batch/COVERAGE.md`](../../cobol/nightly-batch/COVERAGE.md) is generated from the traces (82 / 86 paragraphs, the 4 unreached are the abend paragraphs of posting and report); [`cobol/nightly-batch/traceability.html`](../../cobol/nightly-batch/traceability.html) shows the COBOL and the Java side by side, linked by the citations and coloured by coverage; a click on a paragraph jumps to the Java that translates it, and every paragraph carries a plain-language "Qué hace" line from [`PARAGRAPHS.md`](../../cobol/nightly-batch/PARAGRAPHS.md).
- **Empirical findings** (four new ADRs): JDBC over JPA for record-at-a-time batch ([ADR-13](../methodology/DECISIONS.md)); a job manifest as the JCL analogue with step-level restart and unload-based capture ([ADR-14](../methodology/DECISIONS.md)); tasklet per program, never chunk-oriented ([ADR-15](../methodology/DECISIONS.md)); determinism pins — pinned clock *with hundredths*, `-fsign=EBCDIC`, sort tie-break ([ADR-16](../methodology/DECISIONS.md)).
- **Faithful defects, replicated on purpose** (CLAUDE.md rule 5): the interest program never updates the last account (`CBACT04C.cbl:219-221`, unreachable `ELSE`), and the report overstates the grand total by the last amount (`CBTRN03C.cbl:197-204`, stale record at EOF). Both are cited in the Java and on the spec's SME checklist. Say it on stage: *we translate what the bank runs, bugs included — and we tell the bank where they are.*
- **Honesty note**: the data uses zoned-decimal overpunched signs, not COMP-3 file fields (COMP-3 appears only in the report's counters). The restart proves "same final output", not "same checkpoint mechanism" — the COBOL-side checkpoint is the harness's, the Java side is Spring Batch's `JobRepository`.

Full session report: [../methodology/MODULE-3-REPORT.md](../methodology/MODULE-3-REPORT.md). Module docs: [`cobol/nightly-batch/README.md`](../../cobol/nightly-batch/README.md), [`specs/nightly-batch.md`](../../specs/nightly-batch.md).

---

## 4. Running it

Presenter's guide for the stage, in Spanish, with the expected output of every command: [GUIA-DEMO.md](./GUIA-DEMO.md).

Three equivalent options. Pick whichever fits the audience.

### Option A — wrapper script (recommended; one command, narrated)

```bash
./tools/demo-commands.sh all
```

Prints phase headers (A / C / D), echoes each command before running it, runs the conformance gate, and finishes with a computed `proof` block over all `validation/reports/*.json`. Total wall time: ~3 minutes on the demo machine (module 3 starts seven JVMs).

**On stage, add `--step`.** The script then narrates in Spanish (the deck's language; `--en` keeps English), pauses for Enter after every explanation and before every command and "moment", and after each phase lists the **intermediate artifacts** it just produced or used as clickable `file://` links (Terminal.app, iTerm2 and the VS Code terminal all open them) with a number to open one from the keyboard: the verbatim COBOL, the spec, `PARAGRAPHS.md`, the test cases, the COBOL reference output, the Java, the Java output, the agentic eval report, the side-by-side viewer, the coverage, the ADRs. `explore <module>` prints that whole trail on its own.

Subcommands for running one at a time:

| Command | What runs |
|---|---|
| `./tools/demo-commands.sh preflight` | Toolchain check + clean state + warm-up (run ~30 min before the demo) |
| `./tools/demo-commands.sh module-0` | Module 0 (3 fixtures) |
| `./tools/demo-commands.sh module-1b` | Module 1B (2 fixtures) |
| `./tools/demo-commands.sh module-1a` | Module 1A (1 fixture) |
| `./tools/demo-commands.sh module-2` | Module 2 (3 fixtures) |
| `./tools/demo-commands.sh module-3` | Module 3 (6 fixtures) + three demo moments: the restart job log, the faithful bug, and coverage + the side-by-side viewer |
| `./tools/demo-commands.sh negative-control` | Two sabotages in module 3: a rounding mode → `ACCT-CURR-BAL cobol=201.75 java=201.76`; "fixing" the legacy bug → `cobol 1000-TCATBALF-GET-NEXT vs java 1050-UPDATE-ACCOUNT` at trace entry 68 + account 5 → both reverted → green. Shows the `git diff` of each sabotage and repeats the red lines on their own |
| `./tools/demo-commands.sh agentic-eval [module]` | **The agentic eval as an agent.** Prints the validator's definition (tools, constraints), then runs `claude -p "…" --agent equivalence-validator --output-format stream-json` headless with an allow-list of commands, rendered live by `tools/demo-agentic-eval.py`: what the agent says, each command it runs, the tail of each result, its final report, `RESULT: GREEN`. About 70 s for module 3. `--replay` (or no `claude`, or a non-green live call) plays the recorded transcript in `docs/demo/transcripts/` at stage pace; `RECORD=1` saves a green live run as the new recording |
| `./tools/demo-commands.sh viewer [module]` | Opens `cobol/<module>/traceability.html` (the COBOL ↔ Java side-by-side viewer) and prints the 30-second on-stage script: read the program summary, click a paragraph, read its "Qué hace" line, click a citation back. `module-3` calls it in its third moment |
| `./tools/demo-commands.sh explore [module]` | Every artifact of a module as a numbered list of clickable links; a number opens it (html in the browser, directories in Finder, text in the editor) |
| `./tools/demo-commands.sh conformance` | `check-module.sh --all`: same five phases, same tooling, every module |
| `./tools/demo-commands.sh proof` | Per-fixture summary of all `validation/reports/*.json` + computed cross-module totals |
| `./tools/demo-commands.sh all` | All five modules + conformance + proof |
| `--step` | stage mode: pause for Enter after each explanation and before each command / moment; artifact lists accept a number to open |
| `--en` | narrate in English (default Spanish) |
| `--quiet` | (suffix to any subcommand) suppress the narrative phase headers |
| `--replay` | `agentic-eval`: replay the recording instead of calling `claude` |

### Option B — raw commands (for live typing on stage)

Each module is a 3-command triplet: capture COBOL golden master, build + run Java, byte-exact diff.

```bash
# Module 0 — file I/O
./tools/run-cobol.sh    add-motor-policy
./tools/run-java.sh     add-motor-policy
./tools/compare-outputs.py add-motor-policy

# Module 1B — EXEC SQL → JPA + H2
./tools/run-cobol-db.sh add-policy-db
./tools/run-java.sh     add-policy-db
./tools/compare-outputs.py add-policy-db

# Module 1A — CICS LINK chain → Spring DI
./tools/run-cobol-db.sh add-policy-facade
./tools/run-java.sh     add-policy-facade
./tools/compare-outputs.py add-policy-facade

# Module 2 — real BCP package (BCTITSCV)
./tools/run-cobol.sh    cci-account-converter
./tools/run-java.sh     cci-account-converter
./tools/compare-outputs.py cci-account-converter

# Module 3 — 4-step JCL nightly batch (CardDemo)
./tools/run-job.sh      nightly-batch                      # or run-cobol.sh — it dispatches on job.json
./tools/run-job.sh      nightly-batch 05-restart --verbose # the restart moment, step by step
./tools/run-java.sh     nightly-batch
./tools/compare-outputs.py nightly-batch
```

Note module 0 and module 2 use `run-cobol.sh` (file-only); modules 1A/1B use `run-cobol-db.sh` (loads the SQLite shim); module 3 uses `run-job.sh` (the multi-step manifest runner).

### Option C — Claude Code session (for an audience asking "how does Claude drive this?")

In a Claude Code session at the repo root:

> Run the `equivalence-validator` subagent for each of these modules in turn — `add-motor-policy`, `add-policy-db`, `add-policy-facade`, `cci-account-converter`, `nightly-batch` — and tell me whether each ends in `RESULT: GREEN`.

The read-only subagent invokes the same 3 commands per module and reports per-fixture `[OK]` / `[FAIL]` plus a final `RESULT: GREEN` line. See [.claude/agents/equivalence-validator.md](../../.claude/agents/equivalence-validator.md) for the spec. The scripted form of this is `./tools/demo-commands.sh agentic-eval` (Option A), which needs no interactive session: it calls the same agent headless and renders the stream.

---

## 5. What to expect

End of `./tools/demo-commands.sh all`:

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
[OK ] nightly-batch/01-happy-small   (files 60 · records 397 · trace entries 608 · bytes 102247 · differing 0)
[OK ] nightly-batch/02-rejects   (files 44 · records 318 · bytes 54090 · differing 0)
[OK ] nightly-batch/03-numeric-boundaries   (files 44 · records 237 · bytes 33539 · differing 0)
[OK ] nightly-batch/04-full-carddemo   (files 44 · records 3377 · bytes 792762 · differing 0)
[OK ] nightly-batch/05-restart   (files 44 · records 408 · bytes 77939 · differing 0)
[OK ] nightly-batch/06-abend-discgrp   (files 30 · records 115 · bytes 8981 · differing 0)
...
RESULT: CONFORMANT (… checks passed, 5 module(s))
...
────────────────────────────────────────────────────────────
  TOTAL 15/15 fixtures byte-exact · records 4875 · bytes 1045…  · differing 0
────────────────────────────────────────────────────────────
```

The `TOTAL` line is computed from the JSON reports by `./tools/compare-outputs.py --summary` — nothing in the proof block is hard-coded.

The per-fixture JSON proof artifacts in `validation/reports/*.json` each show `"diffs": []` per fixture. **`"diffs": []` is the contract.** Any non-empty `diffs` is a stop-the-demo signal — investigate before continuing.

If the run is **red** instead of green, the most common causes (full diagnostic table in [../methodology/RUNNING-WITH-CLAUDE.md §7](../methodology/RUNNING-WITH-CLAUDE.md)):

| Symptom | Likely cause | Fix |
|---|---|---|
| `cobc: command not found` | `PATH` missing `/usr/local/bin` | export PATH per §2 above |
| `[FAIL]` with off-by-one numeric | wrong rounding mode | check ADR-4 (HALF_UP) and ADR-11 (DOWN for integer division) |
| Spring Boot banner in stdout | logging not suppressed | check `application.properties` for the 3 banner-off lines |
| Maven download stalls | skipped preflight | wait — the next run will be cached. Don't restart. |

---

## 6. Talking points & Q&A

### How was the Java actually written?

> *"Claude Code wrote it. It read the COBOL source paragraph, then read the methodology we'd written down (hard rules in [CLAUDE.md](../../CLAUDE.md), a glossary of COBOL → Java idiom mappings in [docs/methodology/glossary.yaml](../methodology/glossary.yaml), and phase-specific skills under [.claude/skills/](../../.claude/skills/)), and produced Java that follows those rules. We then ran the byte-exact diff. If red, we fixed the Java. If green, we crystallized what we learned into the glossary so the next module benefits."*

That's the answer. The LLM does the writing; the methodology and the byte-exact diff do the checking. The Java in the repo is the **output** of that loop — not free-form LLM output.

### What does the byte-exact diff prove? What doesn't it?

**Proves**: for every input fixture, the Java produces the exact same observable bytes as the original COBOL. That includes stdout, exit codes, output files, database table dumps, and error logs — every channel the program writes to.

**Doesn't prove** (full honesty in [../methodology/SCALING.md](../methodology/SCALING.md)):
- Coverage outside the fixture set. If your fixtures don't exercise a code path, the diff says nothing about it.
- Non-functional properties (performance, memory, concurrency).
- That the COBOL was correct to begin with. We translate it faithfully — bugs and all.
- That the Java will behave the same against future input categories you haven't yet imagined.

### Why is BigDecimal mandatory?

Hard rule 1 from [CLAUDE.md](../../CLAUDE.md), formalized in [../methodology/DECISIONS.md ADR-3](../methodology/DECISIONS.md). Every COBOL numeric — `COMP-3`, `PIC 9V99`, `PIC S9` — maps to `BigDecimal` with explicit `MathContext` and `RoundingMode`. Never `double`/`float`/`int` for money. The rule is **unconditional** — even loop indices and digit accumulators (module 2 has zero monetary values but still uses `BigDecimal` throughout). The point of the rule is that it forecloses an entire class of bugs (silent precision loss, locale-dependent rounding) without per-field judgment calls.

### What's the load-bearing piece of the demo?

**The byte-exact diff harness, not the Java.** The Java is what the LLM produced under constraint; the harness is what verifies the constraint held. Two empirical findings caught only because the harness ran:
- **ADR-4** — the HALF_UP-vs-HALF_EVEN rounding bug (module 0)
- **ADR-9** — the `save()`-vs-`persist()` bug (module 1B)
Both would have shipped with a commercial COBOL → Java translator that only checks "the Java compiles" — neither would have been caught by unit tests we wrote against the Java alone.

### What if the LLM hallucinates code?

The diff catches it. We've caught three bugs this way (rounding, save-vs-persist, mod-10 check-digit handling). The byte-exact diff doesn't care whether the Java is pretty; it cares whether the bytes match. **A negative-control test is documented**: deliberately changing the ×2 multiplier in module 2's `CheckDigitCalculator` to ×1 produces a red diff on fixture 02 (`CUENTA-ITE: ...28` → `...09`, exit 1). Confirms the harness has teeth.

### How do you handle DB2 / EXEC SQL specifics?

Each SQLCODE branch maps to a typed exception. The glossary ([../methodology/glossary.yaml](../methodology/glossary.yaml) `db_access` section) has the mapping: SQLCODE 0 → return, -530 → `DataIntegrityViolationException`, etc. ADR-9 has the rationale for the `persist + flush + REQUIRES_NEW` pattern that replaces a naive `JpaRepository.save()`.

### How do you handle CICS?

Same approach. `EXEC CICS LINK` becomes a Spring `@Autowired` service-to-service call. `EXEC CICS ABEND` becomes a typed exception. `EXEC CICS RETURN` becomes a method return. All in the glossary's `orchestration` section. [ADR-10](../methodology/DECISIONS.md) covers the same-JVM-only scope of this PoC.

### How do you handle JCL, multi-step batch, restart?

> *"Module 3 is a real four-step nightly close from a public card-processing sample. The job is described once, in a manifest that plays the role of the JCL; the same file drives the COBOL run on GnuCOBOL and builds the Spring Batch job, so step order, file mapping and return-code rules cannot drift. One fixture kills the job after step 2 and resumes it; the resumed run must produce the same bytes as the unbroken one, on both sides — the checker enforces it. Another fixture abends: the job stops, the later steps are marked NOT RUN, the capture steps still run, exit code 12 on both sides."*

What we don't claim: GDG generations, selective `COND=` expressions and an all-EBCDIC input run are not modelled (see [SCALING.md §4](../methodology/SCALING.md)).

### How do I know you translated everything?

> *"Three ways, all generated. The coverage matrix comes from the paragraph traces GnuCOBOL emits while building the golden master: 82 of 86 paragraphs are entered by at least one case, and the four that are not are the abend paragraphs no case reaches — listed, not hidden. The Java emits the same paragraph trace, and it is part of the byte-exact diff: if the Java skipped or merged a paragraph, the diff names it. And the viewer puts the COBOL and the Java side by side, linked by the citation every method carries, so an auditor clicks a paragraph and sees the Java that translates it."*

### You translated a bug on purpose?

> *"Yes — two of them, and we can show you the exact line. The interest program never updates the last account; the report overstates its grand total by the last amount. Rule 5 of our methodology says: don't refine the COBOL before the diff is green. The Java reproduces both, cites both, and the spec's SME checklist asks the bank whether they are intended. When we 'fixed' the first one as a negative control, the diff went red at account 5 — the harness protects the bank from well-meaning improvements too."*

### Why not use a commercial COBOL-to-Java tool?

Commercial tools translate syntax — they produce compilable Java that looks like the COBOL. They don't prove behavioral equivalence. We do, by running both and diffing the bytes. The three empirical bugs we caught would have shipped with a commercial-tool translation.

### How is this reproducible across teams?

Every rule the LLM follows is version-controlled markdown: [CLAUDE.md](../../CLAUDE.md), [docs/methodology/glossary.yaml](../methodology/glossary.yaml), [.claude/skills/](../../.claude/skills/), [docs/methodology/DECISIONS.md](../methodology/DECISIONS.md). A new engineer reading the repo can audit exactly what constraints applied. The LLM is the writer; the framework is the spec. The operator's guide for adopting the framework on a new module is [../methodology/RUNNING-WITH-CLAUDE.md](../methodology/RUNNING-WITH-CLAUDE.md).

### What happens when the spec and the COBOL disagree?

Hard rule 3 from [CLAUDE.md](../../CLAUDE.md): **COBOL is ground truth, not the spec.** If they disagree, fix the spec.

---

## 7. Reproducibility checklist

Before the demo:

1. **Pull latest.** `git pull`. Working tree should be clean.
2. **Preflight.** `./tools/demo-commands.sh preflight` — runs the toolchain check, cleans `java-run/` and per-module `bin/`, then warms up all five modules end-to-end. Total ~3 min. Output ends with `Pre-flight complete. Fifteen fixtures byte-exact equivalent.`
3. **Spot-check one report.** `./tools/compare-outputs.py --summary` — one line per module, `TOTAL 15/15`. For the raw JSON: `python3 -m json.tool validation/reports/nightly-batch.json`.
3b. **Rehearse the negative control once** (`./tools/demo-commands.sh negative-control`, ~1 min) so the red diff is not a surprise on stage.
4. **Confirm Claude Code can see the skills.** Open Claude Code at the repo root. The five skills under `.claude/skills/` and the one subagent under `.claude/agents/` load automatically.

During the demo:

5. Run `./tools/demo-commands.sh all` (or per-module subcommands if pacing). Narrate per §3 above.
6. Open `validation/reports/nightly-batch.json` to show `"diffs": []` × 6 with the `summary` counts, then `./tools/demo-commands.sh negative-control` for the red-then-green moment.
7. Hit Q&A from §6 above.

If anything fails on stage:

- **Don't restart.** Maven downloads are cached — the next attempt will work.
- **Show the diff.** `cat validation/reports/<module>.json | python3 -m json.tool` shows exactly which bytes diverge. "Stop the demo and show the diff" is itself a demonstration that the harness is honest.
