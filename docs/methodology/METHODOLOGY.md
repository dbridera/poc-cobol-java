# Methodology — why the 5-phase shape

Internal rationale. Companion to [PRESENTATION.md](./PRESENTATION.md) (which describes *what* each phase produces) and [DECISIONS.md](./DECISIONS.md) (which catalogs individual decisions). This doc explains why the methodology has *this* shape — what each phase is load-bearing for, what would break if you dropped it.

Audience: engineering leadership and future contributors deciding whether to keep, change, or extend the framework.

---

## 1. Why golden master must precede spec

**The trap.** A natural reading order is: "read the COBOL → write a spec → then capture inputs/outputs to test against". This puts the spec *between* the engineer and the COBOL semantics, and the spec becomes the contract.

**Why it's wrong.** The spec is written by humans (or LLMs); both make mistakes. The COBOL produces actual bytes. Once a spec is written and the engineer has anchored on it, every subsequent question ("does the Java match?") is answered against the spec, not the source. A subtle precision bug — wrong rounding mode, wrong padding, wrong overflow RC — slips through because the spec also got it wrong, and the engineer is comparing two wrong things.

**The fix.** Run the COBOL first. Capture exact outputs across fixtures. *Now* the contract is bytes on disk, not prose. The spec exists to make those bytes reviewable by a human; if the spec disagrees with the bytes, the spec is wrong (see [CLAUDE.md §3](../../CLAUDE.md)).

**Concrete example.** Module zero's HALF_UP discovery. If we'd written the spec first based on "default rounding for financial systems is banker's rounding", every reviewer would have signed off. The byte-exact diff against the GnuCOBOL output produced 513, the spec said 512, the spec was wrong. Captured in [ADR-4](./DECISIONS.md#adr-4--default-cobol-rounded-is-half_up-not-half_even).

---

## 2. Why the spec is reviewable, not pseudocode

**The trap.** Many LLM-translation pipelines use COBOL → pseudocode → Java. Pseudocode looks like a neutral intermediate representation. It isn't.

**Why it's wrong.** Pseudocode discards the COBOL idioms that carry behavior:
- `COMP-3` precision becomes "a number".
- `REDEFINES` becomes "two views of a struct" or, worse, "a polymorphic field".
- `PERFORM ... THRU FOO-EXIT` (deliberate fall-through) becomes "do A, then B".
- `EVALUATE TRUE WHEN ...` (short-circuit) becomes "check these conditions".
- `ON SIZE ERROR` becomes "handle overflow".

Each one of those translations is plausible, and each one is **wrong by default** — see the lessons in §5. The LLM that round-trips through pseudocode is generating Java from a lossy intermediate, not from the source.

**The fix.** Replace pseudocode with a structured spec doc that:
1. Stays alongside the COBOL — never substitutes for it.
2. Calls out the byte-exact contract (PIC widths, padding direction, padding character, trailing-space rules).
3. Calls out the order contract (validation order, paragraph order, fall-through chains).
4. Calls out the numeric contract (scale, rounding mode, overflow behavior with reason strings).

**One-way door.** Once you adopt pseudocode-as-IR, fixing the precision loss requires a parallel artifact anyway — at which point the spec replaces the pseudocode entirely. See [ADR-5](./DECISIONS.md#adr-5--structured-spec-replaces-agnostic-pseudocode).

---

## 3. Why "translate as malware" — no refactoring before a green diff

**The trap.** First-pass COBOL translation tempts engineers to "clean up" — remove a duplicated loop, collapse two near-identical paragraphs, prune an apparently-dead branch. It feels like good engineering.

**Why it's wrong.** Banking COBOL is decades old, has been touched by many engineers, and has behaviors that nobody currently working on it remembers. Apparent dead code routinely:
- Is called by a paragraph the static analyzer missed (e.g., via `GO TO`).
- Has side effects on a working-storage flag a downstream paragraph reads.
- Is a regulator-driven workaround that was never documented.
- Is the only path that handles a corner case the test data doesn't reach.

When you "clean up" before translating, the diff has nothing to anchor on — the Java is no longer trying to match the COBOL.

**The fix.** Translate the COBOL verbatim — preserve paragraph order, fall-through, EVALUATE order, level-88 condition names. Get the diff green. *Now* refactor — every regression is visible immediately because the diff goes red. See [ADR-6](./DECISIONS.md#adr-6--translate-as-malware--no-refactoring-before-a-green-diff).

**Concrete rule.** [.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md) "Control flow" makes this non-negotiable: one paragraph → one method, no collapsing. [docs/glossary.yaml `forbidden`](./glossary.yaml) bans "removing 'dead' COBOL paragraphs without proof they are unreachable from any entry point".

---

## 4. Why Phase E exists

**The trap.** Translate one module, declare victory. Treat the next module as a fresh problem.

**Why it's wrong.** A "framework" only earns its name if module N's translation costs less than module N-1. Without Phase E, every module re-discovers HALF_UP, re-discovers Spring banner suppression, re-debates how to map REDEFINES. The framework collapses to "we successfully translated one thing, N times, with N independent learnings."

**The fix.** Phase E captures lessons as reusable artifacts:
- Empirical findings → entries in [docs/glossary.yaml](./glossary.yaml).
- Phase-specific procedures → skills in `.claude/skills/`.
- Cross-cutting protocols (e.g., "run the diff after every Phase C change") → subagents like [.claude/agents/equivalence-validator.md](../../.claude/agents/equivalence-validator.md).

The test of Phase E is the [SCALING.md §3](./SCALING.md#3-where-the-framework-crystallizes) prediction: by module 3, new content per module trends toward zero. If Phase E is doing its job, module N is a fill-in-the-blank exercise. If module N still produces substantial new skill content, Phase E missed something or the modules aren't similar enough.

**Why it's late.** Phase E runs *after* validation, not in parallel. You don't know what's reusable until you've shipped it once. Premature abstraction in Phase E produces skill files that look right and don't apply.

---

## 5. Lessons that justified Phase E

The five empirical findings from module zero, with two angles per finding that justify Phase E's existence:
- **(a)** what failure mode would have shipped silently without the harness.
- **(b)** what we should add to the harness for module 1+ to catch the next class of bug.

Findings themselves are listed in [PRESENTATION.md §6](./PRESENTATION.md) and [README.md §5](../../README.md). Don't restate — extend.

### 5.1 Default `ROUNDED` is `HALF_UP`, not `HALF_EVEN`

**(a) Silent failure mode.** Java with `HALF_EVEN` passes all unit tests written by a human or an LLM ("banker's rounding sounds right for banking"). Premium-calculation code computes `512` where COBOL produced `513`. The bank charges customers $1 less than the COBOL did, on records ending in `.50`. Nobody notices for years.

**(b) For module 1+.** Add an automated check during Phase A: grep the COBOL source for `ROUNDED MODE` and assert in the spec which mode each paragraph uses. Currently this is a human responsibility documented in [.claude/skills/cobol-spec/SKILL.md](../../.claude/skills/cobol-spec/SKILL.md); promote it to a `tools/audit-rounding.sh` that fails Phase B if the spec doesn't pin a mode for every `ROUNDED`.

### 5.2 `EVALUATE TRUE` short-circuit ordering is part of the contract

**(a) Silent failure mode.** A "smart" Java translator collects all validation errors and returns them as a list (this is what good API design looks like). The COBOL reports only the *first* failing rule. Downstream systems that parse `error.log` and extract `RC=10` + reason now see different reason strings — sometimes the first failing rule, sometimes the last, depending on how the Java collected them.

**(b) For module 1+.** Add a Phase D fixture per module that exercises *multiple* simultaneous validation failures and asserts the COBOL's first-failure RC + reason text. Module zero's fixture 02 only fires one rule per record, which would not have caught a "collect all errors" Java translation. Add `02b-multiple-errors` style fixtures.

### 5.3 `ON SIZE ERROR` keeps its return code per paragraph

**(a) Silent failure mode.** A single top-level `try { … } catch (ArithmeticException e)` in `BatchRunner` produces a generic RC=99 ("unknown error") instead of RC=11 ("premium overflow"). Reconciliation scripts looking for RC=11 in `error.log` to identify overflow rejects produce wrong counts; auditors looking for "premium overflow" reason strings find none.

**(b) For module 1+.** Add a glossary rule (already done — see [docs/glossary.yaml `numerics.on_size_error_note`](./glossary.yaml)) plus a Phase C rule in [.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md) "Numerics" that mandates per-paragraph try/catch with the EXACT COBOL reason string. For module 1+, fixture design should include at least one overflow per arithmetic paragraph, not just the calculator.

### 5.4 Spring Boot banner + startup logs leak into stdout

**(a) Silent failure mode.** With default Spring Boot config, a 13-line banner + INFO log lines precede the first business stdout line. The diff fails immediately and *loudly*, but on the first project this looks like a bug in the harness rather than a bug in the Java. An engineer who isn't expecting it might "fix" the harness by filtering startup lines — and now the harness is permanently weakened against future surprise output.

**(b) For module 1+.** [.claude/skills/java-translate/SKILL.md](../../.claude/skills/java-translate/SKILL.md) "Output formatting" makes the three properties mandatory; [.claude/skills/equivalence-validate/SKILL.md](../../.claude/skills/equivalence-validate/SKILL.md) "Common diagnoses" lists this as a known cause. Stronger move: a Phase C build-time check that fails if `application.properties` is missing the three lines for any module that diffs stdout. Trivial; not yet implemented.

### 5.5 Copybook `REDEFINES` is two interpretations of the same bytes

**(a) Silent failure mode.** A naive Java mapping creates a single class with all union fields nullable. Code reads the wrong fields when given a record of the "other" type — same byte buffer, different interpretation. Worst case: a Motor record's `value` field overlays an Endowment record's `term` field, both are valid `BigDecimal`s, and the bug only shows up on records where the two interpretations happen to produce different but plausible numbers.

**(b) For module 1+.** [.claude/skills/copybook-to-entity/SKILL.md](../../.claude/skills/copybook-to-entity/SKILL.md) "REDEFINES — the trap" mandates sealed-interface-or-two-views, never collapse-to-nullable. For module 1+, add a Phase A check: if a copybook has `REDEFINES`, the Phase B spec must list the discriminator and the alternative shapes, and the Phase C Java must contain a `sealed interface`. Promote this to a script in `tools/audit-redefines.sh`.

---

## 6. The shape, summarized

```
A — Discovery       (run the original; capture bytes; design fixtures)
       │
       │  COBOL is now reproducible; the contract exists in /golden-master
       ▼
B — Spec            (write the human-reviewable artifact; SME signs off)
       │
       │  spec is a derivative of COBOL, never a substitute
       ▼
C — Translation     (Spring Boot 3 + JPA + BigDecimal; no refactoring)
       │
       │  Java exists; nobody yet trusts it
       ▼
D — Validation      (replay the inputs; byte-exact diff)
       │
       │  green diff = "Java does what COBOL does"; red diff = stop, fix
       ▼
E — Framework       (extract reusable rules into skills + glossary)
```

The arrows are not optional. Skipping A leaves the spec ungrounded. Skipping B leaves the SME without a review surface. Skipping D ships approximately-correct Java. Skipping E means module 1 costs as much as module 0.

---

## See also

- [DECISIONS.md](./DECISIONS.md) — individual ADRs that ground each rule above.
- [SCALING.md](./SCALING.md) — what this methodology can and cannot handle, and what the green diff doesn't prove.
- [SKILLS-GUIDE.md](./SKILLS-GUIDE.md) — handoff contracts between phases, extension recipe.
- [PRESENTATION.md](./PRESENTATION.md) — the 5-min stakeholder framing, including the original-proposal critique.
- [CLAUDE.md](../../CLAUDE.md) — hard rules every Claude session reads at start.
