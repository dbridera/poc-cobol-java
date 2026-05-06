# Architecture Decision Records — poc-cobol-java

Engineering-leadership reference. Each entry: **Context · Decision · Consequences · Alternatives**, with an evidence link into the repo. Cite these from other docs instead of restating the rationale.

Flat file by design — convert to `docs/decisions/` once entries exceed ~15.

---

## ADR-1 — Byte-exact diff is the validation contract

**Context.** A bank cannot ship a translation that "approximately" preserves COBOL behavior. Subtle precision bugs (rounding, padding, sign handling) are invisible to SME review and to LLM-generated unit tests, but visible the moment you compare bytes.

**Decision.** A module is "translated" only when, for every fixture, the Java run produces files and stdout **byte-identical** to the COBOL run. The harness is `tools/compare-outputs.py`; the proof artifact is `validation/reports/<module>.json`.

**Consequences.** Every output channel must be deterministic and reproducible — no Spring banner, no timestamps, no nondeterministic ordering, no locale-sensitive formatting. This rules out a class of defaults engineers don't normally think about.

**Alternatives considered.** SME review only (misses precision bugs). LLM-generated tests only (tautological — same model writes code and tests). Property-based tests (good supplement, doesn't prove behavioral equivalence).

**Evidence.** [validation/reports/add-motor-policy.json](../validation/reports/add-motor-policy.json) — `diffs: []` per fixture is the contract. [.claude/skills/equivalence-validate/SKILL.md](../.claude/skills/equivalence-validate/SKILL.md) defines the protocol.

---

## ADR-2 — GnuCOBOL is the reference compiler for the PoC

**Context.** Mainframe access for IBM Enterprise COBOL is expensive and slow to obtain. We need a COBOL runtime to capture the golden master, and engineers need to run it locally during translation.

**Decision.** Use GnuCOBOL 3.2 as the canonical compiler for the PoC. The COBOL source is structured so it builds and runs unmodified on GnuCOBOL.

**Consequences.** Adapted source must drop CICS / DB2 / IMS specifics that GnuCOBOL doesn't support — see `cobol/add-motor-policy/README.md` "What was adapted". The semantic delta between GnuCOBOL and IBM Enterprise COBOL is a known unaddressed risk (see [SCALING.md §6](./SCALING.md#6-threats-the-green-diff-does-not-prove)).

**Alternatives considered.** Mainframe COBOL via Z/OS pricing tier (slow procurement, blocks PoC velocity). Cobol-IT (commercial, similar tradeoffs to GnuCOBOL). Micro Focus COBOL (commercial). All three deferred to industrialization phase.

**Evidence.** [cobol/add-motor-policy/README.md](../cobol/add-motor-policy/README.md) lists every CICS/DB2 statement that was adapted away. [tools/run-cobol.sh](../tools/run-cobol.sh) compiles with `cobc`.

---

## ADR-3 — `BigDecimal` is mandatory for every COBOL numeric

**Context.** COBOL `PIC 9...V9...`, `COMP`, `COMP-3`, and `PIC S9...` are exact decimal. Java `double`/`float` are binary floating point — they cannot represent `0.1` exactly and silently lose precision in monetary arithmetic. `int`/`long` discard the fractional part entirely.

**Decision.** Every translated numeric field is `java.math.BigDecimal`, with `scale` = digits to the right of `V`, and explicit `MathContext` / `RoundingMode` at every operation. No exceptions for "small" or "non-monetary" values — the rule is unconditional.

**Consequences.** Engineers must specify scale and rounding at every arithmetic step. Tests and codecs become more verbose. Performance overhead is acceptable for batch banking workloads. The harness catches violations immediately — see ADR-4.

**Alternatives considered.** `double` "for non-monetary fields" — rejected because the line is fuzzy (engine CC, accident counts, percentages all participate in monetary arithmetic). `long` for integer fields — rejected for the same reason; uniformity is cheaper than per-field judgment.

**Evidence.** [CLAUDE.md §1](../CLAUDE.md), [docs/glossary.yaml `numerics`](./glossary.yaml), [.claude/skills/java-translate/SKILL.md](../.claude/skills/java-translate/SKILL.md) "Numerics".

---

## ADR-4 — Default COBOL `ROUNDED` is `HALF_UP`, not `HALF_EVEN`

**Context.** Many engineers assume "banker's rounding" (HALF_EVEN) is the default for financial systems. COBOL `ROUNDED` with no `MODE` clause is round-half-away-from-zero, which equals Java `RoundingMode.HALF_UP` for non-negative values. Translating with `HALF_EVEN` passes unit tests and silently miscomputes premiums.

**Decision.** Default rounding mode for translated arithmetic is `RoundingMode.HALF_UP`. Use `HALF_EVEN` only when the COBOL explicitly says `ROUNDED MODE IS NEAREST-EVEN`. Grep the source for `ROUNDED MODE` before assuming.

**Consequences.** Every paragraph that uses `ROUNDED` is audited. The glossary documents this empirically — record 2 of fixture 01 (`350 + 22500×0.005 + 50 = 512.50 → 513`) is the canonical proof: HALF_EVEN would give 512.

**Alternatives considered.** None — this is a fact about COBOL semantics, not a design choice. The decision is to make the fact mandatory in the methodology.

**Evidence.** [docs/glossary.yaml `numerics.default_rounding_note`](./glossary.yaml), [specs/add-motor-policy.md §5.1](../specs/add-motor-policy.md).

---

## ADR-5 — Structured spec replaces "agnostic pseudocode"

**Context.** A common LLM-translation pattern is COBOL → pseudocode → Java. Pseudocode loses COBOL idioms — `COMP-3` precision, `REDEFINES` byte-aliasing, `PERFORM THRU` fall-through, `EVALUATE TRUE` short-circuit ordering, `ON SIZE ERROR` per-paragraph RC. Round-tripping through pseudocode produces approximately-correct Java.

**Decision.** Replace pseudocode with a structured spec doc (see `specs/<module>.md`). The spec is an SME-reviewable artifact, not an intermediate representation. The COBOL source remains the ground truth — if the spec and the COBOL disagree, fix the spec.

**Consequences.** Each module produces a real document a banking analyst can review without reading COBOL. The spec template enforces sections that pseudocode omits (validation order, rounding mode, byte-exact output formats, traceability). Spec generation is Phase B; translation is Phase C against the spec.

**Alternatives considered.** No spec, translate directly (fails SME review). Pseudocode as IR (loses precision). A formal IR (e.g., MLIR-style) (over-engineering for this PoC).

**Evidence.** [.claude/skills/cobol-spec/SKILL.md](../.claude/skills/cobol-spec/SKILL.md), [specs/add-motor-policy.md](../specs/add-motor-policy.md). [CLAUDE.md §3](../CLAUDE.md) — "COBOL is ground truth, not the spec doc".

---

## ADR-6 — "Translate as malware" — no refactoring before a green diff

**Context.** Banking COBOL routinely contains "redundant" loops, dead-looking paragraphs, and copy-paste branches. Removing them before translation feels clean but routinely breaks behavior — the apparent dead code is often load-bearing (called by a paragraph the static analyzer missed, or relied on for side effects on a working-storage flag).

**Decision.** Translate the COBOL verbatim — preserve `PERFORM THRU` fall-through, paragraph order, EVALUATE order, level-88 condition names. Refactoring belongs *after* a green diff, never before.

**Consequences.** First-pass Java looks more verbose than idiomatic Java. That's fine — it's a translation, not a rewrite. Once the diff is green, refactoring is safe because regressions become visible immediately.

**Alternatives considered.** "AI refines duplicate loops first" (the original colleague proposal — explicitly rejected; see [PRESENTATION.md §2](./PRESENTATION.md)). Refactor in flight (creates a moving target the diff can't pin down).

**Evidence.** [CLAUDE.md §5](../CLAUDE.md), [.claude/skills/java-translate/SKILL.md](../.claude/skills/java-translate/SKILL.md) "Control flow". [docs/glossary.yaml `forbidden`](./glossary.yaml) lists the "dead paragraph" trap.

---

## ADR-7 — Spring Boot 3 + Java 21 + JPA is the target stack

**Context.** The Java target needs to be deployable in a real bank. The candidates are Spring Boot, Quarkus, Helidon, Micronaut, plain Java SE, or .NET. The team operates Java; the existing toolchain has Maven; banking ops know how to run Spring.

**Decision.** Spring Boot 3.3 on Java 21 with Spring Data JPA and PostgreSQL. Module zero defers JPA persistence to flat files so the byte-exact diff comes first; module 1+ wires `@Transactional` boundaries.

**Consequences.** The methodology's translation rules ([.claude/skills/java-translate/SKILL.md](../.claude/skills/java-translate/SKILL.md)) are stack-specific — `application.properties` rules to suppress the Spring banner, `@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)` for module zero. Migrating off Spring later is non-trivial.

**Alternatives considered.** Quarkus (smaller community in banking ops). Plain Java SE (no DI / transactional story). .NET (out of scope — team is JVM). The bank's actual base package replaces `com.example.poc` at industrialization (see `docs/glossary.yaml` TODO).

**Evidence.** [java/add-motor-policy/pom.xml](../java/add-motor-policy/pom.xml), [.claude/skills/java-translate/SKILL.md](../.claude/skills/java-translate/SKILL.md).

---

## ADR-8 — Claude Code skills + subagents over LangChain / RAG

**Context.** The colleague's original proposal framed LangChain + RAG as optional plumbing. Context management isn't optional for a translation pipeline — the LLM needs the COBOL source, the spec, the glossary, and the prior translation patterns simultaneously. The user has a Pro/Max subscription, no API key.

**Decision.** Orchestration uses Claude Code subagents, skills, and headless mode (`claude -p`). Repo-local context lives in `docs/glossary.yaml` (idiom map) and `.claude/skills/*/SKILL.md` (phase-specific rules). No LangChain, no vector DB, no API key.

**Consequences.** The framework runs on a Pro/Max subscription with no incremental token cost beyond the subscription. Skills are markdown — reviewable, diffable, version-controllable. The `equivalence-validator` subagent is read-only and bounded — it cannot weaken the diff.

**Alternatives considered.** LangChain + Pinecone/Weaviate (extra infra, API key required, indirection without value at this scale). Custom RAG over the repo (the repo is already a "RAG corpus" — `glossary.yaml` + skills serve the same purpose). OpenAI SDK (no Pro/Max equivalent; would require API budget).

**Evidence.** [CLAUDE.md §6](../CLAUDE.md), [.claude/skills/](../.claude/skills/), [.claude/agents/equivalence-validator.md](../.claude/agents/equivalence-validator.md).

---

## How to add an ADR

1. Append the next entry below with the same five-section shape.
2. Cite at least one repo path as evidence — line range, fixture, glossary key, or skill rule.
3. Cross-link from `METHODOLOGY.md` or `SCALING.md` if the new ADR underpins one of their claims.
4. When this file passes ~15 entries, split into `docs/decisions/0001-*.md` etc. and replace this file with an index.
