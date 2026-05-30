# Running this PoC with Claude Code

A hands-on guide for an engineer who has cloned this repo and wants to use **Claude Code** (Pro/Max subscription, no API key) to translate a **new COBOL module** through the five-phase methodology — with the byte-exact diff as the safety net.

This doc is the operator's manual. For the **why** and **what** of the methodology, read [README.md](../../README.md) and [docs/METHODOLOGY.md](./METHODOLOGY.md) first. For the contracts **between** phases, read [docs/SKILLS-GUIDE.md](./SKILLS-GUIDE.md).

---

## 1. What you'll be able to do after reading this

Drop a new COBOL program into `cobol/<your-module>/`, open Claude Code at the repo root, and drive it through phases A → E until `validation/reports/<your-module>.json` shows `"diffs": []`. The Java that comes out the other side is Spring Boot 3 + JPA + `BigDecimal`, with `// COBOL: <file>.cbl:<lines>` traceability comments on every method, and is provably byte-exact against the original COBOL on a set of fixtures you designed.

You'll do this by invoking the **skills** in [.claude/skills/](../../.claude/skills/) one phase at a time and asking the **`equivalence-validator` subagent** to confirm green after every Phase C edit.

---

## 2. Prerequisites

- **Claude Code** — Pro or Max subscription. No API key, no LangChain. (See [CLAUDE.md](../../CLAUDE.md) rule 6 — this is a hard rule for this PoC.)
- **Toolchain** — GnuCOBOL 3.2, Java 21, Maven 3.9. Install instructions: [tools/setup.md](../../tools/setup.md). Sanity check:

  ```bash
  ./tools/run-cobol.sh --self-test
  ```

  Should compile and run a hello-world COBOL program.
- **A COBOL module to translate** — drop your sources under `cobol/<your-module>/src/*.cbl`, copybooks under `cobol/<your-module>/copybooks/*.cpy`. If you don't have one yet, re-run the three reference modules per §4 to confirm the harness works.

---

## 3. What Claude Code auto-loads in this repo

Open Claude Code at the repo root (`/path/to/poc-cobol-java`). The following load automatically — no configuration needed:

- **[CLAUDE.md](../../CLAUDE.md)** — the **7 hard rules** every session must follow. The two you'll feel immediately: rule 1 (`BigDecimal` for every COBOL numeric, never `double`/`float`/`int`) and rule 2 (every translated Java method carries a `// COBOL: <file>.cbl:<startLine>-<endLine>` traceability comment).
- **Five skills** under [.claude/skills/](../../.claude/skills/) — phase-specific procedures that Claude can invoke by name.
- **One subagent** under [.claude/agents/](../../.claude/agents/) — the read-only `equivalence-validator`.

### The skills (phase → skill → trigger)

These mirror the table in [docs/SKILLS-GUIDE.md §1](./SKILLS-GUIDE.md#1-phase--skill-map). The "trigger" column is the verbatim `description:` from each `SKILL.md` front matter — that's what Claude pattern-matches against when deciding to invoke the skill.

| Phase | Skill | Trigger |
|---|---|---|
| A — Discovery | [`cobol-analyze`](../../.claude/skills/cobol-analyze/SKILL.md) | "Phase A — analyze a COBOL module before translation. Use when starting a new module, when the user names a COBOL program, or when fixtures need to be designed." |
| B — Spec | [`cobol-spec`](../../.claude/skills/cobol-spec/SKILL.md) | "Phase B — write a structured spec doc reviewable by a non-COBOL banking analyst. Use after cobol-analyze, before java-translate." |
| C — Translation | [`java-translate`](../../.claude/skills/java-translate/SKILL.md) | "Phase C — translate a COBOL module to Spring Boot 3 + JPA + BigDecimal. Use after the spec exists and golden-master is captured." |
| C (data layer helper) | [`copybook-to-entity`](../../.claude/skills/copybook-to-entity/SKILL.md) | "Convert a COBOL copybook to JPA @Entity / record DTO classes. Use when starting Phase C for a module whose copybooks haven't been mapped yet." |
| D — Validation | [`equivalence-validate`](../../.claude/skills/equivalence-validate/SKILL.md) | "Phase D — establish byte-exact behavioral equivalence between COBOL and Java for a module. Use after Phase C produces a green build." |
| D — Validation (subagent) | [`equivalence-validator`](../../.claude/agents/equivalence-validator.md) | "Run COBOL + Java for a module and report whether the byte-exact diff is green. Use proactively after Phase C changes." |
| E — Framework capture | *(no skill — see §5.5)* | Phase E produces skills, glossary entries, and ADRs rather than consuming them. |

You don't have to memorize these. Naming the module and the phase in plain English (see the prompts in §5) is enough.

---

## 4. Sanity check — re-run the three reference modules with Claude

Before touching your own module, confirm the harness is green on your machine. Open Claude Code at the repo root and paste:

> Run the `equivalence-validator` subagent for each of these modules in turn — `add-motor-policy`, `add-policy-db`, `add-policy-facade` — and tell me whether each ends in `RESULT: GREEN`.

The subagent runs `tools/run-cobol.sh`, `tools/run-java.sh`, and `tools/compare-outputs.py` for each module, reads `validation/reports/<module>.json`, and emits a per-fixture `[OK]`/`[FAIL]` line followed by `RESULT: GREEN` or `RESULT: RED`. (See [.claude/agents/equivalence-validator.md](../../.claude/agents/equivalence-validator.md) for the exact procedure.)

If everything is `RESULT: GREEN`, the harness, toolchain, and skills are all wired correctly. Move on to §5.

If any module reports `RESULT: RED`, the failure is in your local toolchain — not in the methodology. Diagnose with §7 first.

You can also run the same three commands manually without Claude — see [README.md §2](../../README.md#2-60-second-quickstart). The subagent's job is to bundle them so you don't have to.

---

## 5. Translating a new module — phase by phase

Assume your module's name is `<your-module>` and its sources are already at `cobol/<your-module>/src/*.cbl` and `cobol/<your-module>/copybooks/*.cpy`.

### 5.1 Phase A — Discovery

**Input.** Just the COBOL — programs, copybooks, any JCL or shell drivers, sample data.

**Prompt.**

> I want to start a new module called `<your-module>`. Use the `cobol-analyze` skill to inventory the sources under `cobol/<your-module>/`, build the data dictionary, design fixtures, and capture the golden master with `tools/run-cobol.sh`.

**What fires.** [`cobol-analyze`](../../.claude/skills/cobol-analyze/SKILL.md). Claude reads every `.cbl` and `.cpy`, populates `cobol/<your-module>/README.md` with the seven sections in the skill (inventory, data dictionary, external I/O, control flow, validation rules, numerics, fixture design), and creates `cobol/<your-module>/fixtures/<name>/spec.json` per fixture.

**Verify before moving on.**

- `cobol/<your-module>/README.md` exists and has no `TBD` entries in the control-flow map.
- `golden-master/<your-module>/<fixture>/` exists for every fixture, with `stdout.txt`, `exit_code`, `stderr.txt`, and any output files.
- You have **at least three fixtures**: happy path, validation errors, numeric boundaries.

### 5.2 Phase B — Structured spec

**Input.** Phase A outputs and the COBOL source.

**Prompt.**

> Phase A is done for `<your-module>`. Use the `cobol-spec` skill to write `specs/<your-module>.md`. Make sure it's reviewable by a banking analyst who doesn't read COBOL.

**What fires.** [`cobol-spec`](../../.claude/skills/cobol-spec/SKILL.md). Output is `specs/<your-module>.md` with the 11 sections specified in the skill (header, purpose, inputs, per-record processing, validation rules in order, numerics with rounding mode and overflow behavior, outputs with byte-exact format, side effects, out of scope, traceability table, SME review checklist).

**Verify before moving on.**

- Every `ROUNDED` clause has a documented rounding mode (default COBOL is HALF_UP — see [docs/DECISIONS.md ADR-4](./DECISIONS.md)).
- Every `ON SIZE ERROR` has its reason string copied verbatim from the COBOL.
- The §11 SME review checklist is filled in.
- If you have a banking SME available, get §§2–7 reviewed now. Spec errors caught here are an order of magnitude cheaper than catching them in Phase D.

### 5.3 Phase C — Translation

**Input.** `specs/<your-module>.md`, `golden-master/<your-module>/`, [docs/glossary.yaml](./glossary.yaml), [CLAUDE.md](../../CLAUDE.md) hard rules.

**Prompt.**

> The spec for `<your-module>` is done and SME-reviewed. Use the `java-translate` skill to produce `java/<your-module>/` as a Spring Boot 3 project. If any copybook hasn't been mapped to a Java entity yet, use the `copybook-to-entity` skill first. Mirror the layout of `java/add-motor-policy/`.

**What fires.** [`java-translate`](../../.claude/skills/java-translate/SKILL.md) — and [`copybook-to-entity`](../../.claude/skills/copybook-to-entity/SKILL.md) for each new copybook. Output is a Spring Boot project at `java/<your-module>/` with `BigDecimal` everywhere, `// COBOL: <file>.cbl:<lines>` traceability comments on every method, and an `application.properties` that suppresses Spring's banner and startup logs (otherwise they leak into stdout and break the byte-exact diff — see [README.md §5](../../README.md#5-whats-been-tested--and-the-results) finding 4).

**Verify before moving on.**

- `(cd java/<your-module> && mvn -B test)` is green.
- Every method has a `// COBOL: ...` comment. Grep for it: `grep -rL "// COBOL:" java/<your-module>/src/main/java` should be empty (every file has at least one).
- No `double` or `float` anywhere a monetary or accounting value is involved. Hard rule 1. (See [docs/DECISIONS.md ADR-3](./DECISIONS.md).)
- `REDEFINES` is implemented as a sealed interface or two view classes, never a single nullable bag.

### 5.4 Phase D — Equivalence validation

**Input.** Phase A golden master + Phase C Java build.

**Prompt (after every Phase C edit, however small).**

> Run the `equivalence-validator` subagent for `<your-module>` and report `RESULT: GREEN` or `RESULT: RED`. If red, paste the diff hunks.

**What fires.** The [`equivalence-validator`](../../.claude/agents/equivalence-validator.md) subagent. It's **read-only by design** — it cannot edit Java, COBOL, scripts, or the comparator. It runs `tools/run-cobol.sh`, `tools/run-java.sh`, `tools/compare-outputs.py`, reads `validation/reports/<your-module>.json`, and reports.

For more detail on what gets compared and how, see [`equivalence-validate`](../../.claude/skills/equivalence-validate/SKILL.md).

**Verify before moving on.**

- Every fixture shows `[OK]`.
- `validation/reports/<your-module>.json` shows `"diffs": []` per fixture.
- **Run the negative-control test at least once per module.** Change one `BigDecimal` calculation to `double` (or one `em.persist()` back to `JpaRepository.save()`), confirm the diff fails, then revert. This proves the harness has teeth — that green means green, not "nothing was checked". See [README.md §9](../../README.md#9-limitations--next-steps) item 1.

**Don't proceed if** any diff fails. Fix Java, the spec, or the harness — **never weaken the comparator**. ([docs/DECISIONS.md ADR-1](./DECISIONS.md).)

### 5.5 Phase E — Crystallization

Phase E has no skill — it *produces* skill content. After the green run, ask Claude to capture anything you learned that wasn't already in the methodology.

**Prompt.**

> Phase D is green for `<your-module>`. What did we learn during this module that's not already in `docs/glossary.yaml` or `docs/DECISIONS.md`? For each empirical finding, add a glossary entry with a `note:` field, and if it's load-bearing, add an ADR to `docs/DECISIONS.md` (Context · Decision · Consequences · Alternatives · Evidence).

Examples of findings already crystallized this way:

- **HALF_UP, not HALF_EVEN**, is the default COBOL `ROUNDED` mode — caught by module 0 fixture 01. [ADR-4](./DECISIONS.md).
- **`EntityManager.persist()`** must replace `JpaRepository.save()` for COBOL `EXEC SQL INSERT` semantics, because `save()` silently overwrites on duplicate PK and COBOL throws. [ADR-9](./DECISIONS.md).

If you find a recurring pattern that deserves its own phase-skill, create a new `.claude/skills/<your-skill>/SKILL.md`. The next module gets it for free.

---

## 6. What constrains Claude (and why your code stays correct)

The LLM does the writing. The methodology and the byte-exact diff do the checking. Claude is constrained by:

- **[CLAUDE.md](../../CLAUDE.md)** — the 7 hard rules. Loaded automatically every session. The two you'll feel: **rule 1** (`BigDecimal` everywhere) and **rule 2** (traceability comments). Rule 4 is the validation contract: **no module is "translated" until its golden-master diff is green.**
- **[docs/glossary.yaml](./glossary.yaml)** — the COBOL-to-Java idiom map. Sections: `numerics`, `idioms`, `data_layer`, `db_access`, `orchestration`, `control_flow`, `forbidden`. Each entry has a `note:` field for the empirical lesson. This is the repo-local "RAG corpus" — the more modules you translate, the smarter the next module's Phase C becomes.
- **[docs/DECISIONS.md](./DECISIONS.md)** — 10 ADRs codifying load-bearing methodology choices. Each has Context · Decision · Consequences · Alternatives · Evidence sections. Defensible under audit.
- **Per-skill `SKILL.md` files** — phase-specific procedures Claude follows when invoked.

If Claude proposes something that violates any of these, **reject it**. The skills and ADRs encode lessons paid for in prior debugging sessions.

---

## 7. When a diff goes red

`compare-outputs.py` prints unified diffs. The most common symptoms (sourced from [README.md §6](../../README.md#debugging-a-red-diff) and [.claude/skills/equivalence-validate/SKILL.md](../../.claude/skills/equivalence-validate/SKILL.md)):

| Symptom | Likely cause | Fix |
|---|---|---|
| Spring Boot banner or log lines in `stdout.txt` | Default Spring logging | Set `logging.level.root=OFF`, `spring.main.banner-mode=off`, `spring.main.log-startup-info=false` in `application.properties` |
| Off-by-one numeric (e.g. `512` vs `513`) | Wrong rounding mode | Default COBOL `ROUNDED` is `HALF_UP`, **not** `HALF_EVEN`. See [ADR-4](./DECISIONS.md) |
| `ERR` line with different RC than COBOL | `ON SIZE ERROR` flattened by a single top-level Java `catch` | Catch per arithmetic step, preserve the per-paragraph RC |
| `requests.dat` shows up as "missing in java" | `run-cobol.sh` is capturing inputs as outputs | Already fixed — re-pull from main |
| Different PK / policy numbers between runs | Counter not reset between runs | Both sides must start fresh per `BatchRunner` invocation |
| `INSERT` silently succeeds where COBOL throws on duplicate PK | `JpaRepository.save()` is INSERT-OR-UPDATE (MERGE) | Use `EntityManager.persist()` + `em.flush()` + `@Transactional(REQUIRES_NEW)`. See [ADR-9](./DECISIONS.md) |
| Trailing spaces appearing/disappearing | `LINE SEQUENTIAL` trimming | Match COBOL trimming in `BatchRunner` write path |

Cardinal rule: **never relax the comparator**. The fix is always upstream — in the Java, the spec, the COBOL understanding, or the fixture. ([docs/DECISIONS.md ADR-1](./DECISIONS.md).)

---

## 8. What NOT to ask Claude to do

- **Don't refactor the COBOL.** Apparent dead code or duplicated loops in banking COBOL is often load-bearing. ([CLAUDE.md](../../CLAUDE.md) rule 5.) Refactoring belongs *after* a green diff, never before translation.
- **Don't introduce LangChain, an API key, or any external orchestration framework.** This PoC runs on Claude Code + Pro/Max subscription only. ([CLAUDE.md](../../CLAUDE.md) rule 6.)
- **Don't skip SME review of the Phase B spec.** ([CLAUDE.md](../../CLAUDE.md) rule 7.)
- **Don't relax `compare-outputs.py`** to make a red diff go green. The fix is always upstream. ([docs/DECISIONS.md ADR-1](./DECISIONS.md).)
- **Don't replace `BigDecimal` with `double`/`float`/`int` for monetary values** — even if a test happens to pass. ([CLAUDE.md](../../CLAUDE.md) rule 1, [docs/DECISIONS.md ADR-3](./DECISIONS.md).)
- **Don't claim "translated" before Phase D is green.** A module is translated when `validation/reports/<module>.json` shows `"diffs": []` per fixture, with at least one fixture per paragraph plus numeric edge cases. ([CLAUDE.md](../../CLAUDE.md) rule 4.)

---

## 9. Where to read next

| Want to know… | Read |
|---|---|
| The PoC's quickstart, results, and file layout | [README.md](../../README.md) |
| The methodology and rationale for the five phases | [docs/METHODOLOGY.md](./METHODOLOGY.md) |
| The handoff contracts between phases (what each consumes and produces) | [docs/SKILLS-GUIDE.md](./SKILLS-GUIDE.md) |
| The hard rules that every Claude session must follow | [CLAUDE.md](../../CLAUDE.md) |
| The 10 ADRs underpinning the methodology | [docs/DECISIONS.md](./DECISIONS.md) |
| The COBOL → Java idiom map (with empirical notes) | [docs/glossary.yaml](./glossary.yaml) |
| How a module's spec should look | [specs/add-motor-policy.md](../../specs/add-motor-policy.md) |
