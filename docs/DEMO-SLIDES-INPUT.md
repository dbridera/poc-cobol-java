# Demo slides — input for Claude Design

**How to use this file:** open claude.ai, attach or paste this entire file, and use the prompt at the bottom. Claude will generate a 10-slide deck.

The content below is organized as one `## Slide N` per slide. Each slide has a title, the key points, and a visual hint.

---

## Slide 1 — Title

**Provable COBOL → Java migration with AI**

A proof-of-concept that proves AI-assisted COBOL migrations can be validated to byte-for-byte behavioral equivalence — across file access, database access, and program orchestration.

*Visual: clean title slide, dark background, bank-grade.*

---

## Slide 2 — The problem

**Banks have decades of COBOL. Migrations fail because correctness can't be proven.**

- Few engineers can read the COBOL.
- Few engineers can write modern Java.
- **Almost nobody can prove the new code does the same thing as the old code.**

LLMs solve the first two cheaply. The third is where every migration project breaks. "Approximately correct" Java is unacceptable when it determines how interest is computed or how policy premiums are rounded.

**This PoC tackles the third problem.**

*Visual: three icons (read / write / prove), with the third one in red / highlighted.*

---

## Slide 3 — The methodology

**Five phases. One non-negotiable contract.**

| Phase | Purpose |
|---|---|
| **A — Discovery** | Run the original COBOL on open-source GnuCOBOL, capture its exact outputs as a "golden master" |
| **B — Spec** | Generate a structured spec doc reviewable by a banking analyst (replaces "pseudocode") |
| **C — Translation** | Translate to Spring Boot 3 + JPA + Java 21, with `BigDecimal` for all numerics and traceability comments back to the COBOL source |
| **D — Validation** | Re-run the COBOL, re-run the Java, **diff the outputs byte-for-byte** |
| **E — Framework capture** | Save what was learned as reusable rules (skills, glossary, decision records) so the next module is faster |

**The contract:** a module is "translated" if and only if every byte of output matches between the COBOL and the Java. Nothing else counts.

*Visual: 5 phases as a horizontal pipeline with arrows; phase D ("byte-for-byte diff") visually emphasized.*

---

## Slide 4 — What we built

**Three demo modules, one per banking concern stakeholders always raise.**

| Concern stakeholders raise | Module | What it demonstrates |
|---|---|---|
| **"How do you handle VSAM / file access?"** | Module 0 — `add-motor-policy` | COBOL file I/O → Java NIO + Spring Boot |
| **"How do you handle DB2 / databases?"** | Module 1B — `add-policy-db` | `EXEC SQL INSERT` → JPA + relational DB |
| **"How do you handle the COBOL orchestrator / CICS?"** | Module 1A — `add-policy-facade` | `EXEC CICS LINK` chain → Spring service-to-service |

All three are runnable end-to-end. All three pass the byte-exact diff. The same harness runs all three — three commands per module, ~30 seconds wall time each.

*Visual: 3-column layout, one per module, each column ticked green.*

---

## Slide 5 — VSAM / file access (Module 0)

**The COBOL:** an "Add Motor Policy" batch program adapted from a public IBM banking sample. Reads policy requests from a fixed-width file, validates each one against 5 rules, calculates the premium with bracket-based pricing + rounding, writes parent + child records to output files.

**The translation:** Spring Boot 3 + Java 21. Every monetary field is `BigDecimal`. Every translated method carries a `// COBOL: file.cbl:start-end` traceability comment linking back to the source.

**The proof:** 3 fixtures, 14 records, byte-exact equivalent. `policy.dat`, `motor.dat`, `error.log`, stdout — every byte matches.

**The bug it caught:** COBOL's default rounding is HALF_UP (round-away-from-zero). Java's default for BigDecimal is HALF_EVEN (banker's rounding). On `350 + 22500 × 0.005 + 50 = 512.50`, COBOL produces **513**, naive Java produces **512**. **Off by €1 per premium.** Unit tests would have passed; the byte-exact diff caught it on the first run.

*Visual: side-by-side code panes (COBOL paragraph / Java method), with the rounding line highlighted on both.*

---

## Slide 6 — DB2 / EXEC SQL (Module 1B)

**The COBOL:** the `INSERT-POLICY` paragraph carved verbatim from the GenApp banking sample. Two `EXEC SQL` statements: an INSERT and a SELECT. Three SQLCODE branches: success, foreign-key violation, generic error.

**The translation:** Spring Data JPA + H2 in-memory database. `@Entity` for the POLICY table. `EntityManager.persist() + flush()` inside `@Transactional(propagation = REQUIRES_NEW)` — one transaction per request, matching the CICS pattern.

**The proof:** 2 fixtures including a duplicate-PK case. Both sides produce identical stdout AND an identical dump of the inserted POLICY table.

**The bug it caught:** Spring's standard `repository.save()` method is INSERT-OR-UPDATE (MERGE semantics). On a duplicate primary key, it silently **overwrites the existing row.** COBOL `EXEC SQL INSERT` always rejects. The byte-exact diff caught this immediately — a 4-record run with one duplicate produced 4 inserts on naive Java vs 3 inserts + 1 rejection on COBOL. **Silent data corruption** caught before shipping.

**Honest framing:** the COBOL side uses SQLite via a small shim because GnuCOBOL doesn't have `EXEC SQL` natively. The Java side uses real JPA. Production migration substitutes SQLite → DB2 LUW (one JDBC URL change) and substitutes the shim → GIXSQL (open-source EXEC SQL preprocessor that keeps the original COBOL syntax). The translation methodology is identical either way.

*Visual: comparison of `repository.save()` (red ✗) vs `em.persist() + em.flush()` (green ✓); ideally with the duplicate-PK scenario diagrammed.*

---

## Slide 7 — CICS / orchestrator (Module 1A)

**The COBOL:** a two-program chain adapted from the GenApp sample. The outer program receives a request, validates it, and `EXEC CICS LINK PROGRAM("LGAPDB01")` delegates the actual INSERT to a second program.

**The translation:** two Spring `@Service` classes. `PolicyFacadeService.add(request)` validates, then via `@Autowired` calls `PolicyInsertService.insert(entity)`. The CICS LINK collapses to Spring dependency injection in the same JVM. The `@Transactional` boundary lives on the inner insert service — matching the COBOL pattern where the inner program owns the SQL unit-of-work.

**The proof:** 1 fixture exercising the full chain — request read → facade validates → delegated call → INSERT → row in POLICY table. Byte-exact diff on the chained output.

**Honest framing:** GnuCOBOL has no CICS runtime, so `EXEC CICS LINK PROGRAM(X)` is modeled as a nested COBOL `PROGRAM-ID` with a `CALL` between them. Observable behavior (control transfer + payload + return code) is identical. Cross-JVM CICS LINK (REST / message-queue equivalents) is a separate translation pattern, deferred to a future module.

*Visual: two boxes labeled "PolicyFacadeService" and "PolicyInsertService" with an arrow between them; below, the COBOL equivalent with the same shape and the same arrow.*

---

## Slide 8 — Results

**6 of 6 byte-exact diffs green. 2 production-grade bugs caught.**

```
  6/6   fixtures byte-exact equivalent across 3 modules
   2    real precision bugs caught — bugs unit tests would miss
 ~30s   end-to-end re-verify for any module on a laptop
   0    API keys, vector DBs, or LangChain plumbing required
```

The proof artifact for each module is a one-line JSON file: `"diffs": []`. A bank can re-run the entire equivalence proof on a laptop in under a minute.

**The two bugs are real demo moments** — both would have shipped silently with a traditional AI translation. Both are now codified in the framework so no future module repeats them.

*Visual: 4 big number callouts. The "2 bugs" callout should be the visual hero.*

---

## Slide 9 — Scope — what's real, what's a stand-in

**Being explicit so we don't over-claim:**

| Layer | What we built | What changes in production |
|---|---|---|
| **Java target** | Real Spring Boot 3 + Spring Data JPA + Java 21 | **Same code.** No change. |
| **Database** | H2 in-memory (Java side), SQLite (COBOL side) | Swap to **DB2 LUW or PostgreSQL** via one JDBC URL change. No Java change. |
| **`EXEC SQL` syntax in COBOL** | 95-line C shim, COBOL `CALL` to it | Install **GIXSQL** (open-source EXEC SQL preprocessor). Original `EXEC SQL ... END-EXEC` syntax preserved. |
| **VSAM physical files** | COBOL `LINE SEQUENTIAL` (GnuCOBOL's analogue) | Run the original COBOL on the mainframe **once** to capture the golden master. Same Java target. |
| **CICS LINK between programs** | Same-JVM Spring DI | Identical for in-process. Cross-service maps to REST / message queue. |

**The translation methodology is the same in every case.** What changes is the runtime substrate underneath. We validated the *patterns*, and patterns are what migrate.

*Visual: two-column "what we built" vs "production substitution", with the methodology spanning both as a connecting bar.*

---

## Slide 10 — Next steps + closing

**To move from PoC to first production module shipped:**

1. **Negative-control tests** on each module — prove the harness still catches things at the module boundary. *(½ day)*
2. **Install GIXSQL** and re-validate with native `EXEC SQL` syntax preserved. *(1–2 days)*
3. **Point JPA at real DB2 or Postgres** — Java code does not change. *(½ day)*
4. **Cross-check against the mainframe** — run original COBOL on z/OS once, confirm GnuCOBOL produces the same bytes. *(1 day + access)*
5. **Pick the next 3–5 modules** — validate the methodology at scale. *(2–4 weeks)*
6. **Industrialize** — replace placeholder package names with the bank's, wrap the harness in CI/CD. *(1 week)*

---

> *We took three pieces of real banking COBOL — file I/O, an EXEC SQL INSERT paragraph, and a CICS LINK chain — translated each one to Spring Boot + JPA with full traceability, proved them byte-for-byte equivalent to the originals, and caught two production-grade bugs that any traditional AI translation would have shipped silently.*

*Visual: closing slide with the one-sentence outcome as the hero line; the three module names beneath as proof points.*

---

# Prompt to use in Claude Design

> Generate a 10-slide executive deck from this document. Each `## Slide N` section is one slide. Use the visual hints (italic lines) to choose layouts. Audience: bank executives and IT leadership. Tone: confident but honest about scope. Style: clean, minimal, bank-grade — not consumer-app flashy. Include the tables verbatim where they appear; the comparison tables (Slide 4, Slide 9) and the results numbers (Slide 8) are the visual hooks of the deck.
