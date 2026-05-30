# Scaling honesty — what this methodology can and cannot do

Engineering-leadership read of where the PoC scales, where it breaks, and what the green diff does **not** prove. Builds on [ADR-1](./DECISIONS.md#adr-1--byte-exact-diff-is-the-validation-contract) and the empirical findings in [PRESENTATION.md §6](./PRESENTATION.md).

---

## 1. TL;DR for tech leads

- **Module zero is real.** One adapted GenApp module went COBOL → Java + byte-exact diff; the harness caught a real precision bug (HALF_UP vs HALF_EVEN) before any human reviewed the Java.
- **The framework is not yet crystallized.** We have N=1. The "skills + glossary amortize across modules" claim is a *prediction*, not yet evidence. Module 2–3 is when we'll know.
- **The harness is teeth-unproven.** Negative-control test (deliberately break a `BigDecimal`, confirm the diff fails) is documented but **not yet executed** on module zero. Run it before module 1.
- **GnuCOBOL is not IBM Enterprise COBOL.** Single-compiler validation is the largest unaddressed risk. Cross-compiler check requires mainframe access.
- **Several COBOL constructs break this approach today** — see §4. If your modules are heavy CICS dialog, IMS, or deep JCL chains, this PoC does not yet have an answer.

---

## 2. The cost of module N

### Module 0 actuals (what we measured)

| Phase | Wall time | What dominates | Reusable next time? |
|---|---|---|---|
| A — Discovery + golden master | ~½ day | Reading COBOL, designing 3 fixtures, getting GnuCOBOL to compile the adapted source | **No** — fixtures are per-module |
| B — Spec | ~2 hours | Writing the spec doc, SME walkthrough | **No** — spec is per-module |
| C — Translation | ~½ day | Iterating on Spring Boot stdout suppression, BigDecimal codec, REDEFINES handling | **Partly** — translator skill + glossary amortize |
| D — Validation | ~1 hour first time, then minutes per re-run | First-time stdout/format mismatches; once green, the harness is fast | **Yes** — same harness for every module |
| E — Framework | ~2 hours per lesson learned | Distilling a finding into a skill rule | **Cumulative** — lessons compound |

### Module 1 estimate (what we expect)

Assuming module 1 is another GenApp operation of similar size (e.g., INQUIRE POLICY, UPDATE POLICY):

| Phase | Module 1 estimate | Why |
|---|---|---|
| A | ~2 hours | Tooling already proven; fixtures still bespoke |
| B | ~1 hour | Spec template now exists; copy + edit |
| C | ~2–3 hours | Skills + glossary catch most idioms; new copybook may surface new patterns |
| D | < 30 min | Harness unchanged |
| E | ~1 hour or 0 | Only if a new lesson appears |

**Total: roughly half of module 0.** This is the *prediction*; module 1 will either confirm it or expose where the framework didn't actually amortize.

### What does NOT amortize

- **Fixtures** — every module needs its own input data covering its own validation rules and PIC boundaries.
- **SME review** — every spec needs a human banking analyst to confirm the rules match what the bank charges. No shortcut.
- **Copybook idiosyncrasies** — each new copybook can introduce a new `REDEFINES` shape or `OCCURS DEPENDING ON` chain that the existing skill doesn't yet cover.
- **CICS / DB2 adaptations** — the "what was adapted" section in [cobol/add-motor-policy/README.md](../../cobol/add-motor-policy/README.md) repeats per module until we have a real CICS/DB2 story (see §4).

### What DOES amortize

- **The harness** — `tools/run-cobol.sh`, `tools/run-java.sh`, `tools/compare-outputs.py` are module-agnostic.
- **The glossary** — every empirically-verified rule (HALF_UP, ON SIZE ERROR, REDEFINES, level-88) lives in `docs/glossary.yaml` and applies forever.
- **The skills** — the 5 phase skills + 1 subagent encode the translation contract. New skills get added per pattern, not per module.
- **The Spring Boot scaffolding** — `application.properties`, banner suppression, JPA wiring conventions.

---

## 3. Where the framework crystallizes

**Falsifiable prediction.** By module 3, the *new* content per module — measured in lines of skill or glossary additions — should trend toward zero. If module 3 still requires substantial new skill content, the framework is not generalizing and the methodology needs revision.

**Metric to track.** For each module, count:
1. New lines added to `docs/glossary.yaml`.
2. New skills created in `.claude/skills/`.
3. Existing skill files modified.

A healthy trend: module 1 adds noticeable content, module 2 adds less, module 3 adds almost none. If module 3 still adds glossary entries at the rate of module 1, the modules are not similar enough — either pick more cohesive modules, or accept that "framework" is an over-claim and call it a "library of skills".

**Stop-the-line condition.** If the negative-control test (see §6) ever stops failing on a deliberately-broken BigDecimal, the harness has lost teeth on that path. Add a fixture and stop adding modules until the harness covers it.

---

## 4. What breaks the approach

Each entry: **Why it breaks** + **earliest signal you're in this territory**. Use named COBOL constructs, not abstractions.

### CICS dialog (shared state across BMS maps)
**Why it breaks.** Golden master assumes batch-style I/O — input file in, output file out. CICS dialog programs maintain conversational state across screens (`COMMAREA`, `EIBCALEN`, pseudo-conversational restart). There is no single "input → output" pair to diff.
**Signal.** Source contains `EXEC CICS SEND MAP` / `RECEIVE MAP`, or a `DFHCOMMAREA` larger than a request record. Module zero adapted *around* this by reading from a flat file; we have no answer for code that *can't* be adapted around it.

### IMS hierarchical databases
**Why it breaks.** [.claude/skills/copybook-to-entity/SKILL.md](../../.claude/skills/copybook-to-entity/SKILL.md) maps copybooks to JPA `@Entity` (relational). IMS DBDs / PSBs / segment hierarchies don't map cleanly — relational tables are a fundamentally different shape.
**Signal.** Source contains `EXEC DLI` calls or a `PSBNAME` reference. Modules sitting on IMS need a different persistence-mapping strategy before the methodology applies.

### Deep JCL chains
**Why it breaks.** A JCL job is a graph of step → DD → file → next step. The PoC has no orchestration story — `tools/run-cobol.sh` runs one program against one input file. JCL features like generation data groups (GDG), conditional step execution (`COND=`), and dataset disposition (`DISP=(NEW,KEEP,DELETE)`) have no equivalent in the harness.
**Signal.** The COBOL is invoked from JCL with multi-step dependencies (more than 2 steps, or any `COND=` / `IF/THEN/ELSE` JCL). Spring Batch is a candidate target but is not yet in the methodology.

### EBCDIC at I/O boundaries
**Why it breaks.** "Byte-exact diff" assumes ASCII text on both sides. Real mainframe data is EBCDIC; ports often encode-convert at I/O boundaries. The diff becomes "encoding-exact" — a converter bug looks identical to a logic bug, and the harness can't tell them apart without an explicit charset assertion.
**Signal.** Source mentions `CODEPAGE` / `CCSID`, or any data file `cat`-displays as garbled text. Until the harness pins charset per file (planned, not implemented), don't trust diffs on these inputs.

### VSAM with alternate indexes (AIX) or sparse keys
**Why it breaks.** [docs/glossary.yaml `data_layer`](./glossary.yaml) maps KSDS / ESDS / RRDS to Postgres tables, but doesn't cover AIX (multiple keys per row, sparse). Naive translation collapses an AIX into a single PK and silently changes uniqueness semantics.
**Signal.** VSAM definition uses `ALTERNATE INDEX` or `RECORDS ARE NOT UNIQUE`. Add a glossary entry before translating.

### Programs that link to external assemblers / ASM stubs
**Why it breaks.** Anything outside the COBOL source is a black box to the LLM and to the harness. The methodology has no facility for translating BAL / HLASM.
**Signal.** `EXEC ASSEMBLER` blocks, or `CALL` to a name resolved at link-edit to an `.OBJ` outside the COBOL repo.

---

## 5. When NOT to use this methodology

- **Trivial modules** — under ~100 lines of business logic. Phase A + B overhead exceeds the value of the harness.
- **Pure presentation-layer COBOL** — CICS BMS maps, screen handlers with no business logic. Translate to a UI framework directly; there's no "behavior" to byte-diff.
- **Modules already covered by integration tests** with real expected outputs maintained by humans. The harness is redundant — use the existing tests as the contract and skip Phase A.
- **Code under active rewrite** by the original author. Translation works on stable code; a moving target invalidates the golden master every commit.
- **Generated COBOL** (e.g., from a 4GL or report generator). Translate the generator, not the output.

---

## 6. Threats the green diff does NOT prove

Engineering leadership will ask: "what doesn't your green diff prove?" Honest list:

- **Cross-compiler equivalence.** Module zero proves Java matches **GnuCOBOL output**, not IBM Enterprise COBOL output. The two compilers diverge on edge cases (e.g., `MOVE` truncation rules for misaligned `COMP-3`, intrinsic function precision, default code-page collation). Without a one-time mainframe run-through, this gap is unknown. See [ADR-2](./DECISIONS.md#adr-2--gnucobol-is-the-reference-compiler-for-the-poc).

- **Harness teeth.** The negative-control test ([.claude/skills/equivalence-validate/SKILL.md](../../.claude/skills/equivalence-validate/SKILL.md) "Negative-control sanity check") is **not yet run** on module zero. Until it is, we're trusting the harness without proof it would have failed if we'd been wrong. Fix before module 1.

- **EBCDIC collation in sort orders.** EBCDIC and ASCII sort the same letters but different *symbols* into different orders (`a < A` in EBCDIC; `A < a` in ASCII). Programs that sort or compare with mixed alphanumerics may produce different results on the mainframe even with identical logic.

- **`COMP-3` sign-nibble corner cases.** Packed decimal stores the sign in the low nibble of the last byte (`C`/`D`/`F`). Hand-built test data sometimes uses `F` (unsigned) where COBOL expects `C` (signed positive). Fixtures generated from `make-fixture.py` are well-formed; production data may not be.

- **Locale-dependent formatting / date arithmetic.** `CURRENT-DATE` / `FUNCTION CURRENT-DATE`, time zones, and locale-specific number formatting can diverge. Module zero has no date arithmetic; module 1+ likely will.

- **Runtime nondeterminism on the Java side.** `HashMap` iteration order, parallel-stream order, JVM tiered compilation differences. The harness pins what it sees; production traffic is bigger.

- **Concurrent transactional behavior.** Module zero is single-threaded batch. CICS-level rollback is replaced by `@Transactional` in module 1+ (see [ADR-7](./DECISIONS.md#adr-7--spring-boot-3--java-21--jpa-is-the-target-stack)). The diff says nothing about lock-order, deadlock, or isolation-level behavior.

---

## 7. What we'd need to industrialize this

Concrete asks. Each one corresponds to a risk in §6 or a gap in §4.

| Ask | Why | Cost order |
|---|---|---|
| Mainframe access for cross-compiler validation (one-time run-through per module) | Closes the GnuCOBOL ↔ Enterprise COBOL gap (§6, [ADR-2](./DECISIONS.md#adr-2--gnucobol-is-the-reference-compiler-for-the-poc)) | High — procurement |
| Negative-control test in CI | Proves harness teeth on every module (§6, [ADR-1](./DECISIONS.md#adr-1--byte-exact-diff-is-the-validation-contract)) | Low — half a day to wire |
| SME bandwidth model | Spec review is a per-module bottleneck (§2 "what doesn't amortize") | Medium — staffing |
| Charset-pinning in the harness | Closes EBCDIC blind spot (§4, §6) | Low — declare codepage per fixture |
| CICS dialog story | Otherwise §4 modules are out of scope | High — needs a separate PoC on a CICS module |
| JCL → orchestration story (Spring Batch?) | Otherwise multi-step jobs are out of scope (§4) | High — separate PoC |
| Real package name | Replace `com.example.poc` placeholder ([docs/glossary.yaml](./glossary.yaml) `naming.java_packages.base`) | Low — one config change |
| Module 1 + module 2 actually translated | Confirms or falsifies the §3 crystallization prediction | Medium — engineering time |

The PoC has earned permission to ask for these. None of them block more modules — but the answers determine whether this scales to a full estate or stops at "interesting demo".
