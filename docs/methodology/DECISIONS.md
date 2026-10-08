# Architecture Decision Records — poc-cobol-java

Engineering-leadership reference. Each entry: **Context · Decision · Consequences · Alternatives**, with an evidence link into the repo. Cite these from other docs instead of restating the rationale.

Flat file by design — convert to `docs/decisions/` once entries exceed ~15.

---

## ADR-1 — Byte-exact diff is the validation contract

**Context.** A bank cannot ship a translation that "approximately" preserves COBOL behavior. Subtle precision bugs (rounding, padding, sign handling) are invisible to SME review and to LLM-generated unit tests, but visible the moment you compare bytes.

**Decision.** A module is "translated" only when, for every fixture, the Java run produces files and stdout **byte-identical** to the COBOL run. The harness is `tools/compare-outputs.py`; the proof artifact is `validation/reports/<module>.json`.

**Consequences.** Every output channel must be deterministic and reproducible — no Spring banner, no timestamps, no nondeterministic ordering, no locale-sensitive formatting. This rules out a class of defaults engineers don't normally think about.

**Alternatives considered.** SME review only (misses precision bugs). LLM-generated tests only (tautological — same model writes code and tests). Property-based tests (good supplement, doesn't prove behavioral equivalence).

**Evidence.** [validation/reports/add-motor-policy.json](../../validation/reports/add-motor-policy.json) — `diffs: []` per fixture is the contract. [.claude/skills/equivalence-validate/SKILL.md](../../.claude/skills/equivalence-validate/SKILL.md) defines the protocol.

---

## ADR-2 — GnuCOBOL is the reference compiler for the PoC

**Context.** Mainframe access for IBM Enterprise COBOL is expensive and slow to obtain. We need a COBOL runtime to capture the golden master, and engineers need to run it locally during translation.

**Decision.** Use GnuCOBOL 3.2 as the canonical compiler for the PoC. The COBOL source is structured so it builds and runs unmodified on GnuCOBOL.

**Consequences.** Adapted source must drop CICS / DB2 / IMS specifics that GnuCOBOL doesn't support — see `cobol/add-motor-policy/README.md` "What was adapted". The semantic delta between GnuCOBOL and IBM Enterprise COBOL is a known unaddressed risk (see [SCALING.md §6](./SCALING.md#6-threats-the-green-diff-does-not-prove)).

**Alternatives considered.** Mainframe COBOL via Z/OS pricing tier (slow procurement, blocks PoC velocity). Cobol-IT (commercial, similar tradeoffs to GnuCOBOL). Micro Focus COBOL (commercial). All three deferred to industrialization phase.

**Evidence.** [cobol/add-motor-policy/README.md](../../cobol/add-motor-policy/README.md) lists every CICS/DB2 statement that was adapted away. [tools/run-cobol.sh](../../tools/run-cobol.sh) compiles with `cobc`.

---

## ADR-3 — `BigDecimal` is mandatory for every COBOL numeric

**Context.** COBOL `PIC 9...V9...`, `COMP`, `COMP-3`, and `PIC S9...` are exact decimal. Java `double`/`float` are binary floating point — they cannot represent `0.1` exactly and silently lose precision in monetary arithmetic. `int`/`long` discard the fractional part entirely.

**Decision.** Every translated numeric field is `java.math.BigDecimal`, with `scale` = digits to the right of `V`, and explicit `MathContext` / `RoundingMode` at every operation. No exceptions for "small" or "non-monetary" values — the rule is unconditional.

**Consequences.** Engineers must specify scale and rounding at every arithmetic step. Tests and codecs become more verbose. Performance overhead is acceptable for batch banking workloads. The harness catches violations immediately — see ADR-4.

**Alternatives considered.** `double` "for non-monetary fields" — rejected because the line is fuzzy (engine CC, accident counts, percentages all participate in monetary arithmetic). `long` for integer fields — rejected for the same reason; uniformity is cheaper than per-field judgment.

**Evidence.** [CLAUDE.md §1](../../CLAUDE.md), [docs/glossary.yaml `numerics`](./glossary.yaml), [.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md) "Numerics".

---

## ADR-4 — Default COBOL `ROUNDED` is `HALF_UP`, not `HALF_EVEN`

**Context.** Many engineers assume "banker's rounding" (HALF_EVEN) is the default for financial systems. COBOL `ROUNDED` with no `MODE` clause is round-half-away-from-zero, which equals Java `RoundingMode.HALF_UP` for non-negative values. Translating with `HALF_EVEN` passes unit tests and silently miscomputes premiums.

**Decision.** Default rounding mode for translated arithmetic is `RoundingMode.HALF_UP`. Use `HALF_EVEN` only when the COBOL explicitly says `ROUNDED MODE IS NEAREST-EVEN`. Grep the source for `ROUNDED MODE` before assuming.

**Consequences.** Every paragraph that uses `ROUNDED` is audited. The glossary documents this empirically — record 2 of fixture 01 (`350 + 22500×0.005 + 50 = 512.50 → 513`) is the canonical proof: HALF_EVEN would give 512.

**Alternatives considered.** None — this is a fact about COBOL semantics, not a design choice. The decision is to make the fact mandatory in the methodology.

**Evidence.** [docs/glossary.yaml `numerics.default_rounding_note`](./glossary.yaml), [specs/add-motor-policy.md §5.1](../../specs/add-motor-policy.md).

---

## ADR-5 — Structured spec replaces "agnostic pseudocode"

**Context.** A common LLM-translation pattern is COBOL → pseudocode → Java. Pseudocode loses COBOL idioms — `COMP-3` precision, `REDEFINES` byte-aliasing, `PERFORM THRU` fall-through, `EVALUATE TRUE` short-circuit ordering, `ON SIZE ERROR` per-paragraph RC. Round-tripping through pseudocode produces approximately-correct Java.

**Decision.** Replace pseudocode with a structured spec doc (see `specs/<module>.md`). The spec is an SME-reviewable artifact, not an intermediate representation. The COBOL source remains the ground truth — if the spec and the COBOL disagree, fix the spec.

**Consequences.** Each module produces a real document a banking analyst can review without reading COBOL. The spec template enforces sections that pseudocode omits (validation order, rounding mode, byte-exact output formats, traceability). Spec generation is Phase B; translation is Phase C against the spec.

**Alternatives considered.** No spec, translate directly (fails SME review). Pseudocode as IR (loses precision). A formal IR (e.g., MLIR-style) (over-engineering for this PoC).

**Evidence.** [.claude/skills/cobol-spec/SKILL.md](../../.claude/skills/cobol-spec/SKILL.md), [specs/add-motor-policy.md](../../specs/add-motor-policy.md). [CLAUDE.md §3](../../CLAUDE.md) — "COBOL is ground truth, not the spec doc".

---

## ADR-6 — "Translate as malware" — no refactoring before a green diff

**Context.** Banking COBOL routinely contains "redundant" loops, dead-looking paragraphs, and copy-paste branches. Removing them before translation feels clean but routinely breaks behavior — the apparent dead code is often load-bearing (called by a paragraph the static analyzer missed, or relied on for side effects on a working-storage flag).

**Decision.** Translate the COBOL verbatim — preserve `PERFORM THRU` fall-through, paragraph order, EVALUATE order, level-88 condition names. Refactoring belongs *after* a green diff, never before.

**Consequences.** First-pass Java looks more verbose than idiomatic Java. That's fine — it's a translation, not a rewrite. Once the diff is green, refactoring is safe because regressions become visible immediately.

**Alternatives considered.** "AI refines duplicate loops first" (the original colleague proposal — explicitly rejected; see [PRESENTATION.md §2](./PRESENTATION.md)). Refactor in flight (creates a moving target the diff can't pin down).

**Evidence.** [CLAUDE.md §5](../../CLAUDE.md), [.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md) "Control flow". [docs/glossary.yaml `forbidden`](./glossary.yaml) lists the "dead paragraph" trap.

---

## ADR-7 — Spring Boot 3 + Java 21 + JPA is the target stack

**Context.** The Java target needs to be deployable in a real bank. The candidates are Spring Boot, Quarkus, Helidon, Micronaut, plain Java SE, or .NET. The team operates Java; the existing toolchain has Maven; banking ops know how to run Spring.

**Decision.** Spring Boot 3.3 on Java 21 with Spring Data JPA and PostgreSQL. Module zero defers JPA persistence to flat files so the byte-exact diff comes first; module 1+ wires `@Transactional` boundaries.

**Consequences.** The methodology's translation rules ([.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md)) are stack-specific — `application.properties` rules to suppress the Spring banner, `@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)` for module zero. Migrating off Spring later is non-trivial.

**Alternatives considered.** Quarkus (smaller community in banking ops). Plain Java SE (no DI / transactional story). .NET (out of scope — team is JVM). The bank's actual base package replaces `com.example.poc` at industrialization (see `docs/glossary.yaml` TODO).

**Evidence.** [java/add-motor-policy/pom.xml](../../java/add-motor-policy/pom.xml), [.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md).

---

## ADR-8 — Claude Code skills + subagents over LangChain / RAG

**Context.** The colleague's original proposal framed LangChain + RAG as optional plumbing. Context management isn't optional for a translation pipeline — the LLM needs the COBOL source, the spec, the glossary, and the prior translation patterns simultaneously. The user has a Pro/Max subscription, no API key.

**Decision.** Orchestration uses Claude Code subagents, skills, and headless mode (`claude -p`). Repo-local context lives in `docs/glossary.yaml` (idiom map) and `.claude/skills/*/SKILL.md` (phase-specific rules). No LangChain, no vector DB, no API key.

**Consequences.** The framework runs on a Pro/Max subscription with no incremental token cost beyond the subscription. Skills are markdown — reviewable, diffable, version-controllable. The `equivalence-validator` subagent is read-only and bounded — it cannot weaken the diff.

**Alternatives considered.** LangChain + Pinecone/Weaviate (extra infra, API key required, indirection without value at this scale). Custom RAG over the repo (the repo is already a "RAG corpus" — `glossary.yaml` + skills serve the same purpose). OpenAI SDK (no Pro/Max equivalent; would require API budget).

**Evidence.** [CLAUDE.md §6](../../CLAUDE.md), [.claude/skills/](../../.claude/skills/), [.claude/agents/equivalence-validator.md](../../.claude/agents/equivalence-validator.md).

---

## ADR-9 — `EntityManager.persist` over `JpaRepository.save` for COBOL INSERT semantics

**Context.** `EXEC SQL INSERT INTO POLICY VALUES (...)` on DB2 is *always* an INSERT — duplicate PK returns SQLCODE -803 (or constraint-violation equivalent). The Spring Data JPA `repository.save(entity)` is *INSERT-OR-UPDATE* (MERGE): if the supplied entity has an `@Id` that already exists, Hibernate silently overwrites the row, and the method returns successfully.

**Decision.** Translations of `EXEC SQL INSERT` use `EntityManager.persist(entity)` + `em.flush()` inside a service method annotated `@Transactional(propagation = REQUIRES_NEW)`. The flush forces the INSERT to execute (and fail, if it's going to) inside the called method, not at outer-transaction commit time. The caller catches `RuntimeException` and routes to a per-request return code.

**Consequences.** The COBOL pattern "one CICS transaction per request" maps cleanly: each invocation of the insert service starts a fresh transaction, and a constraint failure on record N doesn't poison the persistence context for record N+1. The downside is that every translated INSERT paragraph now has a tighter contract than vanilla Spring Data JPA — code reviewers must reject `save()` for COBOL INSERTs.

**Alternatives considered.** `repository.save()` — rejected; silently MERGEs and silently corrupts data, caught only by the byte-exact diff. `repository.existsById()` before `save()` — adds a SELECT round-trip and still doesn't atomically prevent races. `entityManager.persist()` without explicit `flush()` — the constraint failure surfaces at `@Transactional` commit time, which makes the catch point ambiguous and creates `UnexpectedRollbackException` headaches.

**Evidence.** [java/add-policy-db/src/main/java/com/example/poc/addpolicydb/service/PolicyInsertService.java](../../java/add-policy-db/src/main/java/com/example/poc/addpolicydb/service/PolicyInsertService.java) (the canonical pattern with rationale Javadoc). [cobol/add-policy-db/fixtures/02-sql-errors/](../../cobol/add-policy-db/fixtures/02-sql-errors/) is the fixture that surfaced the issue: a 4-record run with a duplicate PK on record 4. Naive `save()` produced 4 inserted + corrupted row 1; the diff caught both deltas. [docs/glossary.yaml `db_access.exec_sql_insert`](./glossary.yaml).

---

## ADR-10 — `EXEC CICS LINK` maps to same-JVM Spring DI (for this PoC scope)

**Context.** The original GenApp chains COBOL programs via `EXEC CICS LINK PROGRAM("LGAPDB01") COMMAREA(...)`. CICS LINK is in-region (same address space) for these examples. A faithful translation needs to preserve the *observable* chain — one program hands off control + a payload to another, gets it back mutated — without dragging in the CICS runtime, transaction scope, or recovery semantics that don't apply to a batch PoC.

**Decision.** Translate `EXEC CICS LINK PROGRAM(X) COMMAREA(Y)` as a same-JVM Spring DI call: `XService.handle(Y)` injected via `@Autowired`. The commarea becomes a mutable DTO (or, more idiomatically, an input record + a return result). Cross-JVM / cross-service mappings (REST, gRPC, message queue) are deferred to a future module that actually exercises them.

**Consequences.** The Java side has the same two-program structure visible to reviewers (one `@Service` calls another). The transaction boundary lives on the inner insert service (ADR-9), not the facade — matching the COBOL pattern where LGAPDB01 owns the SQL unit-of-work. Limitation: this PoC does not address CICS transaction nesting, two-phase commit across LINKed programs, or LINKed programs that themselves write to recoverable resources. Those are out of scope per [README §9](../../README.md#9-limitations--next-steps).

**Alternatives considered.** Inline the called program into the caller — rejected; loses the "program A calls program B" structure that's visible to the audience and required for refactoring later. REST call between two Spring apps — over-engineering for a same-JVM chain. A custom "CICS LINK emulator" — out of scope. Translate to Spring Cloud Function — adds infra without value at PoC scale.

**Evidence.** [cobol/add-policy-facade/src/ADDPFCD.cbl](../../cobol/add-policy-facade/src/ADDPFCD.cbl) (nested ADDPOLDB-INSERT program — the GnuCOBOL local equivalent of CICS LINK). [java/add-policy-facade/src/main/java/com/example/poc/addpolicyfacade/service/PolicyFacadeService.java](../../java/add-policy-facade/src/main/java/com/example/poc/addpolicyfacade/service/PolicyFacadeService.java) (the `@Autowired` PolicyInsertService is the LINK-equivalent). [validation/reports/add-policy-facade.json](../../validation/reports/add-policy-facade.json) proves byte-exact equivalence on the chained output.

---

## ADR-11 — Integer-truncation arithmetic uses `RoundingMode.DOWN`, not `HALF_UP`

**Context.** ADR-4 establishes `HALF_UP` as the default for COBOL `ROUNDED`. But a large class of arithmetic doesn't use `ROUNDED` at all — assignment of a `9(M)V9(N)` source into a `9(M)` target silently drops the fractional part. Banking algorithms exploit this: BCTITSCV's mod-10 check digit computes `WS-DOS-NUMERO = WS-TRES-NUMERO / 10` where the target is `PIC 9(02)`, producing integer truncation. A naive `BigDecimal.divide(TEN, 0, HALF_UP)` is wrong here — it rounds `sum=5` up to `1` instead of down to `0`, which shifts the final check digit by 10 and produces a wrong CCI.

**Decision.** For a COBOL expression `target = source / divisor` where `target` has no fractional digits (no `V`), translate to `source.divide(divisor, 0, RoundingMode.DOWN)`. Reserve `HALF_UP` for cases where the COBOL explicitly says `ROUNDED` (ADR-4) or where the target preserves fractional digits.

**Consequences.** Every `COMPUTE` and `MOVE` involving a quotient must be examined for the target's scale, not just the source operand. The Phase B spec must classify each arithmetic step as "rounding" (ADR-4) or "truncation" (this ADR). The glossary's `numerics.integer_truncation_rule` codifies the test: if the target is `PIC 9(N)` with no `V`, use `DOWN`.

**Alternatives considered.** Always use `HALF_UP` for simplicity — rejected; produces wrong check digits whenever the units digit of the dividend is ≥ 5. Always use `DOWN` for simplicity — rejected; produces wrong premiums for monetary `ROUNDED` arithmetic (ADR-4). Two distinct modes per scope is the price of being faithful to the COBOL.

**Evidence.** [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:284](../../cobol/cci-account-converter/src/BCTITSCV-RUN.cbl) (the `COMPUTE WS-DOS-NUMERO = (WS-TRES-NUMERO / 10)` line). [java/cci-account-converter/.../CheckDigitCalculator.java](../../java/cci-account-converter/src/main/java/com/example/poc/cciaccountconverter/service/CheckDigitCalculator.java) (uses `RoundingMode.DOWN`). [specs/cci-account-converter.md §5.3](../../specs/cci-account-converter.md). [docs/glossary.yaml `numerics.integer_truncation_rule`](./glossary.yaml). [validation/reports/cci-account-converter.json](../../validation/reports/cci-account-converter.json) — 3/3 byte-exact on first Java run.

---

## ADR-12 — PIC narrow-store truncation is part of the algorithm, not an overflow

**Context.** A COBOL `MOVE x TO field-pic-9(N)` where `x` has more than N digits silently drops the high digits. Engineers trained on Java tend to read this as a buggy data type and "fix" it with `Math.toIntExact`-style overflow checks. But banking COBOL frequently relies on PIC narrow-store truncation as the algorithm — the canonical case is mod-N arithmetic done by computing in a wide accumulator and storing into a `9(1)` to get the result mod 10.

**Decision.** When a spec identifies that PIC narrow-store truncation is load-bearing, the Java translation must reproduce it **explicitly** — `result.remainder(BigDecimal.valueOf(10).pow(N))` for the general case, `result.remainder(BigDecimal.TEN)` for the common `PIC 9(01)` case — and the spec must annotate the line as truncation-as-algorithm so the diff harness's coverage of that step is intentional. Implicit fall-through is not acceptable: a translator who doesn't notice the trick produces output that's off by exactly 10 (or 100, etc.) on edge cases.

**Consequences.** The Phase A `cobol-analyze` skill must flag every `MOVE n-digit-source TO PIC 9(narrower)`. The spec must declare it either (a) load-bearing (Java must `remainder()` to match) or (b) genuine overflow (Java must `throw`). A row in the spec's "numerics" table for every such occurrence.

**Alternatives considered.** Translate truncation as a runtime check (`if (result.intValueExact() > 99) throw`) — rejected; this produces a thrown exception for inputs where the COBOL is silently producing the correct answer. Always model PIC widths as Java `BigInteger` with explicit `mod()` calls everywhere — rejected as over-engineering for the cases where the source field already has enough digits.

**Evidence.** [cobol/cci-account-converter/src/BCTITSCV-RUN.cbl:285-287](../../cobol/cci-account-converter/src/BCTITSCV-RUN.cbl) (the `MOVE WS-UNO-NUMERO TO TI-YRCV-DIG-ITE1` after a formula that can yield 10 → must store 0). [specs/cci-account-converter.md §5.3 "WS-UNO-NUMERO overflow is load-bearing"](../../specs/cci-account-converter.md). [docs/glossary.yaml `numerics.pic_truncation_load_bearing`](./glossary.yaml). [java/cci-account-converter/.../CheckDigitCalculator.java](../../java/cci-account-converter/src/main/java/com/example/poc/cciaccountconverter/service/CheckDigitCalculator.java) ends with `.remainder(BigDecimal.TEN)`.

---

## ADR-13 — JDBC (`JdbcTemplate`) over JPA for record-at-a-time batch access to KSDS files

**Context.** Batch COBOL works one record at a time: `READ` by key, change a few fields in working storage, `REWRITE`, and the very next `READ` of the same file must see that change. Module 1B mapped `EXEC SQL INSERT` to JPA and immediately hit the `save()`-is-MERGE trap (ADR-9); a KSDS updated in place inside a loop is the same trap multiplied: an identity map that hands back a stale managed entity, a deferred flush that reorders writes, and `@Transactional` boundaries that have no COBOL counterpart. The report program also needs `READ NEXT` in key order while another file is being rewritten.

**Decision.** For multi-step batch modules the KSDS files are relational tables accessed with `JdbcTemplate` and explicit SQL (`INSERT` = `WRITE`, `UPDATE … WHERE pk` = `REWRITE`, `SELECT … WHERE pk` = `READ`, `SELECT … ORDER BY pk` = `READ NEXT`, a secondary index = the VSAM alternate index). One `KsdsTable` class maps a copybook layout to a table (alphanumerics and unsigned numerics as `VARCHAR` so key padding and byte order are preserved, signed amounts as `DECIMAL(p,s)`, FILLER as its own column so a record round-trips byte for byte). JPA remains the target for online, request-scoped services (modules 1A/1B).

**Consequences.** Every file verb has a visible SQL twin; no hidden caching or flush ordering. `ORDER BY` on the padded key columns reproduces BDB/VSAM key order without a collation clause. The cost is hand-written DDL per layout — generated from the layout descriptor, so one class covers all nine copybooks of module 3.

**Alternatives considered.** JPA with `flush()`/`clear()` after every record — rejected: it re-creates the COBOL semantics by fighting the framework, and the identity map still bites on `READ NEXT`. Raw record tables (`KEY VARCHAR, REC VARCHAR(lrecl)`) — rejected: byte-faithful but defeats the point of showing "VSAM becomes a relational table"; the demo must show real columns.

**Evidence.** [java/nightly-batch/.../io/KsdsTable.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/io/KsdsTable.java). [specs/nightly-batch.md §8](../../specs/nightly-batch.md). [validation/reports/nightly-batch.json](../../validation/reports/nightly-batch.json) — 6/6 byte-exact including `acctfile.unl` and `tcatbal.unl`, the unloads of the two files rewritten in place.

---

## ADR-14 — A job manifest is the JCL analogue; restart is step-level; in-place-updated files are captured by unload steps

**Context.** SCALING.md §4 listed "deep JCL chains" as a construct that breaks the approach: the harness ran one program against one input. A real nightly close is a chain of steps sharing files, with `COND=`-style failure handling, checkpoint/restart, and VSAM files that are *modified* rather than produced — the single-program harness would never have captured them (it only moved files that were not staged inputs).

**Decision.** A multi-step module declares `cobol/<module>/job.json`: datasets (organization, LRECL, key, sandbox path, `input`/`capture` flags) and an ordered step list (program, DD→dataset map, PARM, `rc_ok`, `always`). `tools/run-job.py` executes it on the COBOL side with `DD_<name>` environment variables (GnuCOBOL `-fassign-clause=external`); the Spring Batch application reads the **same file** and builds one Step per manifest step. Semantics are identical on both sides: a RC outside `rc_ok` fails the job, later steps are `NOT RUN` except `always` steps, the exit code is MAXRC over the job instance, a killed job (`abend-after=STEP;resume`) is resumed by skipping completed steps (`.jobstate` on the COBOL side, the `JobRepository` on the Java side), and both write the same `run-log.txt`. Only datasets flagged `capture: true` leave the sandbox; KSDS files are never captured — generated `UNLD-*` steps (IDCAMS REPRO stand-ins, `always: true`) write their sequential twins so in-place updates are diffed.

**Consequences.** Step order, DD mapping and failure rules cannot drift between the two sides because there is one source of truth. The restart demo is a fixture (`05-restart`) with an invariant enforced by `tools/check-module.sh`: its outputs equal the unbroken run's. The job log is part of the byte-exact contract. GDG generations are not modelled (one run = one generation).

**Alternatives considered.** Translate the JCL to a shell script per module — rejected: nothing would tie the Java step list to it. Spring Batch XML/Java config written by hand — rejected: same drift risk, and the COBOL side would still need its own driver. A commercial JCL-to-Spring-Batch converter — out of scope for the PoC and would not solve capture.

**Evidence.** [cobol/nightly-batch/job.json](../../cobol/nightly-batch/job.json). [tools/run-job.py](../../tools/run-job.py), [tools/jobman.py](../../tools/jobman.py). [java/nightly-batch/.../batch/NightlyJobConfig.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/batch/NightlyJobConfig.java), [RunLogListener.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/batch/RunLogListener.java). [golden-master/nightly-batch/05-restart/out/run-log.txt](../../golden-master/nightly-batch/05-restart/out/run-log.txt). README spike i (Spring Batch 5 + H2 file database restarts across two JVM runs).

---

## ADR-15 — One Spring Batch tasklet per COBOL program, not chunk-oriented steps

**Context.** Spring Batch's idiomatic step is chunk-oriented: read N items, process, write, commit. CBTRN02C reads a transaction, reads the account, rewrites it, and the next transaction of the same account must see the new balance; CBACT04C accumulates interest across a control break and rewrites at the break. A chunk boundary between two transactions of one account would make the second one read a stale balance (or a flushed-then-reread one, depending on configuration) — a translation that is correct for chunk size 1 and wrong for chunk size 10 is not a translation.

**Decision.** Each manifest step is a `Tasklet` that runs the whole program in one transaction, exactly as the COBOL executable runs: open, loop, close, return code. Chunk-oriented steps may be introduced later *per program* once the byte-exact diff is green, as an optimisation under rule 5 ("refactor after green, never before").

**Consequences.** No batch-level parallelism or partitioning for now; stdout ordering and record-at-a-time visibility are exact. The performance story (SCALING.md, colleague's §5) stays separate from the correctness story.

**Alternatives considered.** Chunk size 1 — works but misleads: it looks tunable and is not. `ItemReader`/`ItemWriter` with a custom `ItemStream` reading KSDS — rejected for the same visibility reason.

**Evidence.** [java/nightly-batch/.../batch/NightlyJobConfig.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/batch/NightlyJobConfig.java) (tasklet factory). [specs/nightly-batch.md §4.2, §4.4](../../specs/nightly-batch.md).

---

## ADR-16 — Determinism pins: pinned clock with hundredths, EBCDIC overpunch flag, explicit sort tie-break

**Context.** The nightly close has three sources of non-determinism that the single-program modules never had: `FUNCTION CURRENT-DATE` stamped into every transaction (including hundredths of a second), signed zoned data whose sign is an EBCDIC overpunch (`{A-I}J-R`) that GnuCOBOL misreads by default, and a DFSORT step whose order among equal keys is unspecified.

**Decision.** (1) `COB_CURRENT_DATE="2022/07/18 00:00:00.00"` in the manifest env — the fractional form is required: without it the hundredths keep ticking (README spike d). The Java side derives a fixed `LocalDateTime` from the same string. (2) `-fsign=EBCDIC` in the manifest's compiler flags; `ZonedDecimal` implements the same table on the Java side. (3) The sort stand-in adds TRAN-ID as a secondary key where DFSORT ran without `OPTION EQUALS`; documented as an adaptation in the module README.

**Consequences.** Golden masters are reproducible run to run (verified by re-running fixture 04 and diffing). The pins are data, not source changes: the three CardDemo programs stay verbatim. Any new module with a clock must declare its pin in the manifest; the spec names it in §8.

**Alternatives considered.** Masking timestamps in the comparator — rejected (ADR-1: never weaken the diff). Editing `Z-GET-DB2-FORMAT-TIMESTAMP` to a constant — rejected once the fractional `COB_CURRENT_DATE` form proved to work; it would have cost the "kept verbatim" claim.

**Evidence.** [cobol/nightly-batch/job.json](../../cobol/nightly-batch/job.json) `env` and `build.cobc_flags`. [cobol/nightly-batch/README.md §8-9](../../cobol/nightly-batch/README.md) (spike log a, d, g; determinism pins). [java/nightly-batch/.../batch/JobRun.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/batch/JobRun.java) `parseCobCurrentDate`, [io/ZonedDecimal.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/io/ZonedDecimal.java).

---

## ADR-17 — The paragraph trace is a diff channel and the source of the coverage matrix

**Context.** Two things in module 3 were asserted by hand: the paragraph → fixture coverage matrix in the README (written by reading the source) and the claim that the Java "follows the same paragraphs". When a diff went red, the comparator pointed at a byte, not at the paragraph where the behaviour diverged. GnuCOBOL can emit one line per paragraph entered (`-ftrace`, `COB_SET_TRACE`, spike k) without touching the source.

**Decision.** Job modules declare `"trace": true`. `tools/run-job.py` enables the GnuCOBOL trace per step and normalises it to `PROGRAM Paragraph NAME` lines in `out/steps/<nn>-<NAME>.trace.txt`; the Java side (`StepIo.entry/paragraph`) writes the same lines at every paragraph entry, including the ones GnuCOBOL generates (`L$0`, the sentence after the main `PERFORM`). `compare-outputs.py` diffs the traces as a channel of their own and names the **first divergent paragraph** with five lines of context; a trace mismatch is red like any other channel. `tools/gen-coverage.py` derives `COVERAGE.md` and the README summary from the golden-master traces; `check-module.sh` fails on drift.

**Consequences.** Mirroring every paragraph entry is a translation discipline: a method that silently merges two paragraphs, or skips an `EXIT.` paragraph, is caught the first time the module runs. The coverage matrix is evidence, not prose; the four unreached paragraphs of module 3 are exactly the ones the hand-written matrix had marked ✘. Sabotage 2 (ADR-14 restart demo's sibling: "fixing" the unreachable `ELSE`) now reports `cobol 1000-TCATBALF-GET-NEXT vs java 1050-UPDATE-ACCOUNT` at trace entry 68 instead of a byte. Cost: ~60 one-line `io.paragraph(...)` calls in module 3; no runtime cost on the COBOL side without `COB_SET_TRACE`.

**Alternatives considered.** Statement-level trace (`-ftraceall`) — rejected: statements have no Java twin, and the volume is unusable. Comparing traces as sets rather than sequences — rejected: order and repetition are the point (a control-break paragraph entered once too often is the bug). Trace only on the COBOL side for coverage — kept as a subset, but the Java twin is what turns "the same paragraphs" from a claim into a diff.

**Evidence.** [cobol/nightly-batch/job.json](../../cobol/nightly-batch/job.json) (`trace`, `-ftrace`). [tools/run-job.py](../../tools/run-job.py) `normalise_trace`. [java/nightly-batch/.../io/StepIo.java](../../java/nightly-batch/src/main/java/com/example/poc/nightlybatch/io/StepIo.java). [tools/compare-outputs.py](../../tools/compare-outputs.py) `trace_report`. [cobol/nightly-batch/COVERAGE.md](../../cobol/nightly-batch/COVERAGE.md) (82/86). README spike k. [validation/reports/nightly-batch.json](../../validation/reports/nightly-batch.json) — `summary.trace_entries_compared` 5 743 on fixture 04, 0 differing.

---

## How to add an ADR

1. Append the next entry below with the same five-section shape.
2. Cite at least one repo path as evidence — line range, fixture, glossary key, or skill rule.
3. Cross-link from `METHODOLOGY.md` or `SCALING.md` if the new ADR underpins one of their claims.
4. When this file passes ~15 entries, split into `docs/decisions/0001-*.md` etc. and replace this file with an index.
