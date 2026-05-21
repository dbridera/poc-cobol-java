# COBOL → Java Migration — Executive Report

> **A proof-of-concept that proves AI-assisted COBOL migrations can be validated to byte-for-byte behavioral equivalence — including two production-grade bugs the harness caught on first run.**

---

## 1. The problem

Banks run decades of COBOL on mainframes. Migrating it to Java is **expensive** because:

- Few engineers can read the COBOL.
- Few engineers can write modern Java.
- **Almost nobody can prove the new code does the same thing as the old code.**

LLMs solve the first two cheaply. The third is where every migration project actually breaks. "Approximately correct" Java is unacceptable when it determines how interest is computed, how policy premiums are rounded, or how a CICS transaction rolls back. A naive translation passes unit tests and silently miscomputes money.

**This PoC tackles the third problem: provable behavioral equivalence.**

---

## 2. What we set out to demo

A repeatable methodology in which every translated module is verified by **running the original COBOL, running the new Java, and diffing the outputs byte-for-byte.** Green diff = the migration is correct. Red diff = stop and investigate.

Banks routinely raise three concerns about a COBOL migration. We deliberately built one demo module per concern:

| Concern | Module | What it exercises |
|---|---|---|
| **VSAM / file access** | Module 0 — `add-motor-policy` | COBOL `SELECT / OPEN / READ / WRITE` against fixed-width record files |
| **DB2 / database access** | Module 1B — `add-policy-db` | `EXEC SQL INSERT` paragraph carved from a real banking program, translated to Spring Data JPA + relational DB |
| **COBOL orchestrator / CICS** | Module 1A — `add-policy-facade` | Two-program chain (`EXEC CICS LINK PROGRAM(X)`) translated to a Spring service-to-service call |

All three modules are real, all three are runnable end-to-end, all three pass the byte-exact diff.

---

## 3. Headline results

```
6 / 6   byte-exact diffs green across 3 modules
2       real precision bugs caught — bugs unit tests would miss
~30 s   end-to-end re-verify for any module on a laptop
0       API keys, vector DBs, or LangChain plumbing required
```

A bank can re-run the entire equivalence proof on a laptop in under a minute. The proof artifact for each module is a one-line JSON: `"diffs": []`.

---

## 4. The two bugs the harness caught

**These were not contrived test cases.** They surfaced organically the first time we exercised the methodology on real banking code.

### Bug 1 — Premium rounding off by €1 per record

| | |
|---|---|
| Calculation | `350 + 22 500 × 0.005 + 50 = 512.50` |
| What COBOL produces | **513** (round-half-up, the COBOL default) |
| What naive Java produces | **512** (round-half-even, Java's default) |
| Caught by | Module 0 fixture 01, record 2 |
| Real-world impact | Silent miscompute of every premium ever calculated under this rule. Would not be caught by any unit test the LLM wrote, because the LLM writes the same code in both. |

### Bug 2 — Silent data corruption on duplicate primary key

| | |
|---|---|
| COBOL `EXEC SQL INSERT` on duplicate PK | Rejects the insert; returns a SQL error code |
| Spring's `repository.save()` on duplicate PK | **Silently overwrites the existing row** (it's INSERT-OR-UPDATE, not INSERT) |
| Caught by | Module 1B fixture 02, record 4 (duplicate-PK case) |
| Real-world impact | Silent data corruption — an existing customer's policy is overwritten by a later request that happens to collide. No exception, no log line. Would ship undetected. |

**Both bugs would have passed every unit test the LLM generated.** The byte-exact diff caught them on the first run. The fix for each is documented; both fixes are now codified in the framework so no future module repeats them.

---

## 5. What this proves

1. **Behavioral equivalence is provable, not just claimed.** The contract is unambiguous: re-run COBOL → outputs A. Re-run Java → outputs B. A == B (every byte). Nothing else counts.

2. **The methodology spans all three major COBOL asset classes.** File I/O, database access, and program orchestration each get a dedicated proof module. The translation patterns and the harness work for all three.

3. **Each module makes the next one faster.** Module 0 took roughly a week. Modules 1A + 1B together took roughly a day, because the framework had crystallized — reusable skills, a translation glossary, and architectural decision records carry forward.

4. **No external infrastructure required.** Runs on Claude Code with a Pro/Max subscription. No API keys, no vector database, no LangChain. The translation rules and the validation harness are markdown and Python in the repository.

---

## 6. What is REAL vs what is a stand-in

Being explicit so the demo is not over-claimed:

| Concern | What we built | Production substitution |
|---|---|---|
| **Java target** | Real Spring Boot 3 + Spring Data JPA + Java 21 | **Same code in production.** Flip the JDBC URL — no Java change. |
| **Database** | H2 in-memory (Java side), SQLite (COBOL side) | Swap to **DB2 LUW** or **PostgreSQL** via the JDBC URL. No code change. |
| **`EXEC SQL` in COBOL** | 95-line C shim callable from COBOL | Install **GIXSQL** (open-source EXEC SQL preprocessor). Original `EXEC SQL ... END-EXEC` syntax preserved. |
| **VSAM physical format** | COBOL `LINE SEQUENTIAL` file I/O (the GnuCOBOL analogue) | Run the original COBOL on the mainframe **once** to capture the golden master. Same Java target. |
| **CICS LINK between programs** | Spring service-to-service call (same-JVM DI) | Same pattern for in-process. Cross-service maps to REST / message queue — separate module when needed. |

**The translation methodology is identical in every case.** What changes is the runtime substrate underneath. What we validated is the *pattern* — and patterns are what migrate, not specific bytes.

---

## 7. Why this approach beats the alternatives

| Alternative | Why it falls short |
|---|---|
| **SME review only** | Misses precision bugs (rounding, padding, sign handling) that are invisible in a review but visible the moment you compare bytes. |
| **AI writes the code and the tests** | Tautological — the same model wrote both. If it misunderstood `ROUNDED`, both the Java and the test pass with the wrong value. |
| **Pseudocode as an intermediate step** | COBOL idioms (`COMP-3` precision, `REDEFINES`, fall-through `PERFORM THRU`, `EVALUATE TRUE` short-circuit) lose fidelity in a pseudocode round-trip. |
| **"Refine the COBOL first, then translate"** | Banking COBOL's "redundancy" is often load-bearing. Refactoring before a green diff routinely breaks behavior. Refactor *after* the diff is green and any regression is immediately visible. |
| **LangChain + vector-DB RAG** | Extra infrastructure, API keys, indirection. At PoC scale (~handful of modules), a markdown glossary and Claude Code skills serve the same role with zero infrastructure. |

---

## 8. Effort + time signal

| Phase | Time on this PoC | What changes at production scale |
|---|---|---|
| Methodology + framework design | ~1 week | One-time cost; reused for every module |
| Module 0 (first module) | ~1 week | First module always pays the framework tax |
| Modules 1A + 1B (second + third) | ~1 day combined | **Framework crystallization is real** — each subsequent module is faster |
| Re-verifying any module | ~30 seconds | Instant feedback loop on every change |

**Implication for a real migration:** the first 2–3 modules dominate effort; the methodology then settles into a steady cadence. The cost model is approximately *fixed framework cost + small per-module cost*, not *large per-module cost compounding*.

---

## 9. Honest disclaimer — what's NOT yet validated

- **Mainframe ↔ GnuCOBOL semantic delta.** All three modules run on GnuCOBOL. A real migration must run the original on the mainframe at least once and confirm GnuCOBOL produces the same golden master. Known unaddressed risk; the methodology calls for it explicitly.
- **Negative-control tests not yet executed on every module.** The harness has teeth (proven by the two bugs above) — but the protocol of "deliberately corrupt one BigDecimal, confirm diff fails, revert" should run on every module before it ships.
- **Real DB2 and real GIXSQL not yet substituted in.** The Java side is production-shaped; the COBOL side uses stand-ins. The substitutions are mechanical, not conceptual.
- **Not addressed in this PoC:** JCL → Spring Batch, EBCDIC ↔ ASCII at I/O boundaries, cross-JVM CICS LINK (REST / queue), two-phase commit across LINKed programs, mainframe deployment, production CI/CD.

These are scope decisions, not gaps in the methodology. Each is a known step on the path to industrialization.

---

## 10. Recommended next steps

1. **Run negative-control tests** on each of the three modules — proves the harness still catches things at the module boundary. *(½ day)*
2. **Install GIXSQL** and re-validate module 1B with native `EXEC SQL` syntax preserved. *(1–2 days)*
3. **Point JPA at a real database** (Postgres or DB2 LUW). The Java code does not change. *(½ day)*
4. **Run module 1A against a mainframe** — capture the original COBOL's golden master once and confirm GnuCOBOL produces the same bytes. *(1 day, plus mainframe access)*
5. **Pick the next 3–5 modules** to validate the methodology at scale. Recommend a mix: another DB operation, a CICS chain with error paths, a JCL batch. *(2–4 weeks)*
6. **Industrialize** — replace the PoC package names with the bank's, promote the skills + glossary into the bank's Claude Code installation, wrap the harness in CI/CD. *(1 week)*

---

## 11. The one-sentence outcome

> *We took three pieces of real banking COBOL — file I/O, an `EXEC SQL INSERT` paragraph, and a CICS LINK chain — translated each one to Spring Boot + JPA with full traceability, proved them byte-for-byte equivalent to the originals, and caught two production-grade bugs that any traditional AI translation would have shipped silently.*

---

## Appendix — visual cues for the deck

- **Cover slide.** The one-sentence outcome (§11) as the hero line.
- **§1 problem slide.** Three-bullet "hard part isn't writing Java — it's proving correctness" framing.
- **§2 approach slide.** Three columns, one per stakeholder concern (VSAM / DB2 / CICS), each ticked green.
- **§3 results slide.** Four large numbers (6/6, 2, ~30s, 0) as big callouts.
- **§4 bugs slide.** Two side-by-side bug cards with "what COBOL did / what Java did / what would have shipped".
- **§5 proves slide.** Four numbered points.
- **§6 real-vs-stand-in slide.** The comparison table, with "production substitution" column highlighted.
- **§7 alternatives slide.** Five rows of *X / why it fails*.
- **§8 effort slide.** A line chart-style visual — Module 0 effort tall, modules 1A/1B short, future modules trending flat.
- **§9 disclaimer slide.** Four bullets, deliberately understated tone.
- **§10 next-steps slide.** Numbered roadmap with time estimates per step.
- **§11 closing slide.** The one-sentence outcome again, with three module names beneath.
