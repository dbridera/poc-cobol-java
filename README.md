# poc-cobol-java

**LLM-driven COBOL → Java migration framework. Driven by Claude Code on a Pro/Max subscription — no API key, no LangChain.**

| | |
|---|---|
| Status | Modules **0**, **1A** (CICS facade), **1B** (DB / EXEC SQL) all end-to-end **GREEN** |
| Toolchain | GnuCOBOL 3.2 + Java 21 + Maven 3.9 + Spring Boot 3.3 + JPA + H2 (+ SQLite shim for COBOL EXEC SQL) |
| Tests | 22 / 22 Java unit tests · **6 / 6 fixtures byte-exact equivalent** across 3 modules |
| Sample source | Adapted from public [`cicsdev/cics-genapp`](https://github.com/cicsdev/cics-genapp) |

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

Pre-requisite: toolchain (see §8). After that, from the repo root:

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
```

Expected output across all 3 modules:

```
[OK ] add-motor-policy/01-happy-small
[OK ] add-motor-policy/02-validation-errors
[OK ] add-motor-policy/03-numeric-boundaries
[OK ] add-policy-db/01-happy-small
[OK ] add-policy-db/02-sql-errors
[OK ] add-policy-facade/01-happy-chain
```

Plus JSON proof artifacts under `validation/reports/` — `"diffs": []` per fixture.

---

## 3. Methodology — five phases

| Phase | What happens | Output | Skill file |
|---|---|---|---|
| **A — Discovery** | Pick a module, get it runnable on GnuCOBOL, design fixtures, capture golden master | `cobol/<m>/`, `golden-master/<m>/` | `.claude/skills/cobol-analyze/` |
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
│   ├── PRESENTATION.md                5-minute explainer for stakeholders
│   ├── glossary.yaml                  COBOL → Java idiom + naming map
│   └── reference/                     drop the Anthropic playbook PDF here
│
├── cobol/
│   ├── add-motor-policy/              MODULE ZERO
│   │   ├── README.md                  provenance: kept / adapted / added
│   │   ├── src/ADDMPOL.cbl            adapted from GenApp LGAPDB01
│   │   ├── copybooks/lgpolicy.cpy     verbatim from GenApp
│   │   └── fixtures/
│   │       ├── 01-happy-small/        spec.json + generated requests.dat
│   │       ├── 02-validation-errors/
│   │       └── 03-numeric-boundaries/
│   └── genapp-source/                 unmodified GenApp originals (traceability)
│
├── golden-master/
│   └── add-motor-policy/              captured COBOL outputs per fixture
│       └── <fixture>/{stdout.txt, exit_code, stderr.txt, out/...}
│
├── specs/
│   └── add-motor-policy.md            structured spec (Phase B)
│
├── java/
│   └── add-motor-policy/              Spring Boot project (Phase C)
│       ├── pom.xml
│       └── src/{main,test}/java/com/example/poc/addmotorpolicy/
│           ├── AddMotorPolicyApplication.java
│           ├── batch/{BatchRunner, RecordCodec}.java
│           ├── domain/{MotorPolicyRequest, PolicyEntity, MotorEntity}.java
│           └── service/{MotorPremiumCalculator, RequestValidator,
│                        PremiumOverflowException}.java
│
├── java-run/                          regenerable; outputs from Java side
│   └── add-motor-policy/<fixture>/
│
├── validation/
│   └── reports/add-motor-policy.json  machine-readable diff proof
│
└── tools/
    ├── setup.md                       toolchain install instructions
    ├── run-cobol.sh                   compile + run COBOL, capture golden master
    ├── run-java.sh                    package + run Spring Boot, capture java-run
    ├── compare-outputs.py             byte-exact diff harness
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
| Java unit tests | `(cd java/add-motor-policy && mvn -B test)` | **22 / 22 passed** |
| Behavioral equivalence | `./tools/compare-outputs.py add-motor-policy` | **3 fixtures, 14 records, 0 diffs** |

### Java unit tests (last `mvn test`)

```
Tests run: 3,  RecordCodecTest                (parse + encode policy/motor records)
Tests run: 12, MotorPremiumCalculatorTest     (CC brackets, HALF_UP, overflow, golden values)
Tests run: 7,  RequestValidatorTest           (short-circuit ordering for each rule)
Tests run: 22, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

### Equivalence proof (`validation/reports/add-motor-policy.json`)

```json
[
  { "fixture": "01-happy-small",        "module": "add-motor-policy", "diffs": [] },
  { "fixture": "02-validation-errors",  "module": "add-motor-policy", "diffs": [] },
  { "fixture": "03-numeric-boundaries", "module": "add-motor-policy", "diffs": [] }
]
```

`diffs: []` per fixture means COBOL and Java agree on **every byte** of stdout, exit code, `policy.dat`, `motor.dat`, and `error.log`.

### What the 14 records actually exercise

- All four CC brackets (≤1000, ≤1600, ≤2000, >2000) including the boundary values.
- All five validation rules (zero customer, zero CC, zero value, blank issue date, blank expiry date) — each one fires once.
- The unknown-request-id branch (RC=99).
- Numeric overflow trap (RC=11) on `999 999 accidents × 50` — both sides produce the identical error log line.
- The HALF_UP rounding rule (record producing `512.50 → 513`).

### Empirical findings the harness surfaced

These are *not* theoretical — every one was caught by running the diff:

1. **Default COBOL `ROUNDED` is HALF_UP, not HALF_EVEN.** Caught by record 2 of fixture 01 (`350 + 22500×0.005 + 50 = 512.50 → 513`). HALF_EVEN would give 512. Glossary updated.
2. **`EVALUATE TRUE` is short-circuit.** Reports the first failing rule, not all of them. Java preserves order.
3. **`ON SIZE ERROR` keeps its return code per paragraph.** A single top-level Java `catch` flattens this and loses the granular RC=11.
4. **Spring Boot banner + startup logs leak into stdout.** `application.properties` has `logging.level.root=OFF`, `spring.main.banner-mode=off`, `spring.main.log-startup-info=false`.
5. **Copybook `REDEFINES` is two interpretations of the same bytes** — must use a sealed interface or distinct view classes, never a single nullable bag.
6. **`JpaRepository.save()` is INSERT-OR-UPDATE (MERGE), not INSERT.** Caught by module 1B fixture 02-sql-errors (duplicate PK). COBOL `EXEC SQL INSERT` throws on duplicate; `save()` silently overwrites. Fix: `EntityManager.persist() + em.flush() + @Transactional(REQUIRES_NEW)`. See [DECISIONS.md ADR-9](./docs/DECISIONS.md).

### What we did NOT yet run (honest disclaimer)

- **Negative-control test.** Deliberately switching one BigDecimal calc to `double` and confirming the diff fails. Recommended before module 1.
- **Property-based tests** (jqwik dependency is in `pom.xml`) — placeholder for module 1+.
- **Cross-COBOL-implementation check.** Only GnuCOBOL was used. A real migration should also run the original on the mainframe at least once and confirm GnuCOBOL produces the same golden master.

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
| Change a fixture's data | `cobol/<module>/fixtures/<name>/spec.json` | `python3 tools/make-fixture.py spec.json in/requests.dat`, then re-run the three commands above |
| Add a new fixture | new dir under `cobol/<module>/fixtures/` with `spec.json` | same as above |
| Change COBOL business logic | `cobol/<module>/src/*.cbl` | re-run all three commands; the diff will show what changed |
| Change Java translation | `java/<module>/src/main/java/...` | `mvn -B test` from the module dir, then `./tools/run-java.sh && ./tools/compare-outputs.py` |
| Add a new module from scratch | start a Claude Code session with the `cobol-analyze` skill | follow phases A → E in order |

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
JCL → Spring Batch · cross-JVM CICS LINK (REST/RPC equivalents) · EBCDIC ↔ ASCII at I/O boundaries · vector-DB RAG · production CI/CD · mainframe deployment.

### Recommended next moves

1. **Run the negative-control test** on each module — change one BigDecimal to double (module 0), or one `em.persist()` back to `repository.save()` (modules 1A/1B), confirm the diff fails, then revert. Proves the harness has teeth on every module.
2. **Module 2** — pick another GenApp operation (INQUIRE POLICY or UPDATE POLICY). The skills + glossary should make this much faster now that modules 1A and 1B have crystallized the DB + orchestrator patterns.
3. **Real Postgres** — flip `application.properties` `spring.datasource.url` from `jdbc:h2:mem:` to `jdbc:postgresql://...`. The JPA layer is unchanged.
4. **Drop the Anthropic Code Modernization Playbook PDF** into `docs/reference/` and reconcile any deltas with the methodology.

---

## 10. Key documents at a glance

| Want to know… | Read |
|---|---|
| What this is and why (5 min) | [`docs/PRESENTATION.md`](./docs/PRESENTATION.md) |
| Hard rules every Claude session must follow | [`CLAUDE.md`](./CLAUDE.md) |
| What module zero does, byte by byte | [`specs/add-motor-policy.md`](./specs/add-motor-policy.md) |
| What was kept / adapted / added from GenApp | [`cobol/add-motor-policy/README.md`](./cobol/add-motor-policy/README.md) |
| Naming + idiom map for the translator | [`docs/glossary.yaml`](./docs/glossary.yaml) |
| Approved methodology plan | `~/.claude/plans/breezy-tinkering-mccarthy.md` |
