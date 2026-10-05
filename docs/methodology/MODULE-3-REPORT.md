# Module 3 — `nightly-batch` — session report

**What:** the AWS CardDemo nightly close — a four-step JCL batch job (post transactions → charge interest → rebuild the transaction master → print the daily report) — translated to Spring Batch and proven byte-exact against GnuCOBOL on 6 fixtures, including a killed-and-resumed run and an abend.

**Why it matters:** it is the first module where the methodology meets *real* batch: several programs sharing VSAM files updated in place, sort steps, return-code semantics, checkpoint/restart, mainframe-only data formats (overpunched signs) and genuine legacy defects. SCALING.md used to list "deep JCL chains" and "EBCDIC at I/O boundaries" under *what breaks the approach*; both moved to *covered, with limits*.

| | |
|---|---|
| Source | [aws-samples/aws-mainframe-modernization-carddemo](https://github.com/aws-samples/aws-mainframe-modernization-carddemo) @ `59cc6c2`, Apache-2.0 — `CBTRN02C`, `CBACT04C`, `CBTRN03C` **kept verbatim** |
| Job | [`cobol/nightly-batch/job.json`](../../cobol/nightly-batch/job.json): 16 steps, 24 datasets (6 loads, 4 business groups, 2 capture unloads) |
| Fixtures | 6 — happy · rejects · numeric boundaries · full seed set · restart · abend |
| Result | **6 / 6 byte-exact**, 44 files per fixture (30 for the abend), 0 bytes differing; two negative controls red then green |
| New ADRs | [ADR-13](./DECISIONS.md) JDBC over JPA for batch · [ADR-14](./DECISIONS.md) job manifest + step-level restart · [ADR-15](./DECISIONS.md) tasklet per program · [ADR-16](./DECISIONS.md) determinism pins |
| Branch | `feature/nightly-batch`, one commit per work package |

---

## 1. What was built

**Harness (WP1, before any module code).** A manifest runner ([`tools/run-job.py`](../../tools/run-job.py)) that executes a job step list on either side with JCL-like DD mapping, an injectable kill-and-resume plan, MAXRC exit codes and a capture allow-list; a byte-exact comparator with binary reports (first differing offset, record, column, hex) and per-fixture record/byte counts; a generator for IDCAMS REPRO stand-ins ([`tools/gen-ksds-io.py`](../../tools/gen-ksds-io.py)); a CardDemo fixture builder; job-step nodes in the dependency renderer; and a process-conformance gate ([`tools/check-module.sh`](../../tools/check-module.sh)). Regression gate: the existing nine fixtures stayed green through the harness change.

**COBOL module (WP2).** Verbatim programs plus four small *added* programs for what GnuCOBOL lacks — a PARM driver, a `CEE3ABD` stub, two `SORT` programs standing in for DFSORT — and generated loaders/unloaders. No line of the three business programs changed; `check-module.sh` verifies it with `cmp`.

**Spec (WP3).** [`specs/nightly-batch.md`](../../specs/nightly-batch.md): 12 sections, including the validation order (100→101→102→103, 103 overrides 102), the numeric rules (truncation toward zero, low-order retention, the `WS-TEMP-BAL` truncation), the report layout to the byte, and a faithful-defects register.

**Java (WP4).** [`java/nightly-batch`](../../java/nightly-batch): Spring Batch 5 job built from the manifest, one tasklet per program, H2 file database in the sandbox so the `JobRepository` survives between the two JVM runs of a restart, `KsdsTable` over `JdbcTemplate`, `CobolRecord` with COBOL store semantics, `ZonedDecimal`, `PicEditor`, `CobolDisplay`. 29 unit tests.

**Validation (WP5).** Green on the first full run after one fix (below). Negative controls: a one-token rounding change turned fixture 03 red at `acctfile.unl` record 1 column 24; "fixing" the unreachable ELSE turned fixture 01 red at record 2. The restart fixture's outputs equal the unbroken run's on both sides.

---

## 2. Timeline of findings (the things the harness, not a reviewer, caught)

1. **FILLER bytes.** First Java run: 110 bytes differing, all in `tcatbal.unl`, all in rows created by posting. The seed rows carry zero-filled FILLER; `READ … INTO` copies it into working storage; `INITIALIZE` leaves FILLER alone; `WRITE` persists it. The Java `initialize()` blanked FILLER. One probe program on GnuCOBOL confirmed the semantics; one line fixed it. Glossary: `idioms.initialize_skips_filler`.
2. **The pinned clock kept ticking.** `COB_CURRENT_DATE="2022/07/18 00:00:00"` froze seconds, not hundredths, and both programs copy the hundredths into every timestamp. The fractional form `…:00.00` makes `FUNCTION CURRENT-DATE` constant — no source change (spike d, ADR-16).
3. **Overpunch is load-bearing.** Without `-fsign=EBCDIC` GnuCOBOL reads `0000005047G` as +504.70 and `0000009190}` as +919.00 (spike a).
4. **Truncation, three ways.** `COMPUTE` without `ROUNDED` truncates toward zero (0.09575 → 0.09, −11.4875 → −11.48); `ADD` without `ON SIZE ERROR` keeps low-order digits (9999999999.00 + 5.00 → 4.00); a 10-digit cycle total moved into `S9(09)V99` loses its first digit so a purchase passes a limit it exceeds by ten million. All three are in fixture 03 and in the Java store rules.
5. **Two real defects in the sample.** The last account never receives its interest (`CBACT04C.cbl:219-221`); the report's grand total is overstated by the last amount (`CBTRN03C.cbl:197-204`) — invisible in fixture 03 only because its last record is the zero-amount transaction, plain in fixture 04 (79,254.29 vs an input sum of 79,233.86). Replicated, cited, on the SME checklist.
6. **One decider per position.** A single Spring Batch decider reused after every step loops forever (flow states are keyed by object identity). Spike i.

---

## 3. What this module changes in the framework

- `cobol-analyze` gains §3.5 (JCL → `job.json`, spike log, faithful-defects register) and §9 of `DEPENDENCIES.md`; `cobol-spec` gains the register and the multi-step sections; `java-translate` gains the multi-step batch pattern; `equivalence-validate` gains the binary report, the restart invariant and the second negative control; the validator subagent dispatches by module type.
- `tools/check-module.sh` is the new Phase E gate: every module (the four earlier ones included) now passes the same 12 checks. Six older classes received the `// COBOL: <file>.cbl:<lines>` tag they were missing.
- Glossary: 21 new entries across numerics, idioms, data layer, orchestration, testing and the forbidden list.

---

## 4. What to say on stage, and what not to claim

Say: the programs are public and verbatim; the runtime (JCL, IDCAMS, DFSORT, Language Environment) is replaced by small documented stand-ins; the diff covers every byte the job leaves behind, including the job log of a crash-and-resume; the harness caught a one-byte FILLER difference and a one-cent rounding change.

Don't claim: COMP-3 file fields (the data is zoned with overpunched signs; COMP-3 only in counters), an EBCDIC end-to-end run (seed files verified, `CODE-SET` verified, no job run yet), GDG or selective `COND=` modelling, or any performance statement (GnuCOBOL on x86 is not a baseline — SCALING.md).

---

## 5. Effort

| Work package | Wall time (this session) |
|---|---|
| WP0 spikes (9) | ~1 h |
| WP1 harness + regression | ~2 h |
| WP2 module + fixtures + golden master + Phase A docs | ~2 h |
| WP3 spec | ~45 min |
| WP4 Java + tests | ~2 h |
| WP5 validation + negative controls | ~30 min |
| WP6 ADRs, glossary, skills, demo, docs | ~1.5 h |

About one working day of Claude Code session time against the eight days estimated in the plan; the estimate assumed human-paced iteration on the Java side, which the first-run-green result made unnecessary.

---

## 6. Open items

- `07-ebcdic-input` fixture (generated `CODE-SET` converters; needs its own golden master because the two CardDemo seed sets differ by one byte in two files).
- A TRANREPT abend fixture (missing type/category row) to exercise the report's three `INVALID KEY` paths.
- Negative controls on modules 0 / 1A / 1B.
- Partitioned run of the full fixture (Java vs Java only) for the optional performance moment.
