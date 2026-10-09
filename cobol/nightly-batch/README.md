# cobol/nightly-batch — CardDemo nightly close (module 3)

<!-- verbatim: CBTRN02C.cbl CBACT04C.cbl CBTRN03C.cbl -->

A four-step end-of-day batch job for a credit-card portfolio, taken from the
AWS CardDemo sample application and run unmodified under GnuCOBOL. It is the
first **multi-step** module of the PoC: one JCL-like job manifest
([`job.json`](./job.json)) drives six KSDS loads, the four business steps,
two sorts and two unloads, with step-level restart.

Stakeholder concern this module answers: *"How do you handle real batch —
JCL with several steps, VSAM files updated in place, sort steps, restart after
a failure, and the signed/packed numerics that only exist on the mainframe?"*

| | |
|---|---|
| Source | AWS CardDemo, Apache-2.0 — see [`original/SOURCE.md`](./original/SOURCE.md) |
| Business programs | `CBTRN02C` (posting), `CBACT04C` (interest), `CBTRN03C` (report) — **kept verbatim** |
| Added programs | `INTCALC` (PARM driver), `CEE3ABD` (abend stub), `CBSORT01` / `CBSORT02` (DFSORT stand-ins), generated `src/ksds/LOAD-*` / `UNLD-*` (IDCAMS REPRO stand-ins) |
| Fixtures | 6 — see §5 |
| Golden master | `golden-master/nightly-batch/<fixture>/` — per-step stdout + return codes, job log, 9 captured datasets |
| Spec | [`specs/nightly-batch.md`](../../specs/nightly-batch.md) |
| Dependency map | [`DEPENDENCIES.md`](./DEPENDENCIES.md) · [`dependency-graph.html`](./dependency-graph.html) |

---

## 1. Provenance

### Kept verbatim

`src/CBTRN02C.cbl`, `src/CBACT04C.cbl`, `src/CBTRN03C.cbl` and the nine
copybooks under `copybooks/` are byte-identical to `original/cbl/` and
`original/cpy/` (`tools/check-module.sh` enforces it with `cmp`). **No line of
the three business programs was changed.** Everything the mainframe runtime
used to provide is supplied from the outside:

| Mainframe facility | How it is supplied here | Where |
|---|---|---|
| JCL `//DD` statements (`ASSIGN TO DALYTRAN` …) | compiled with `-fassign-clause=external`; `tools/run-job.py` sets `DD_<name>=<sandbox path>` per step from `job.json` | `job.json` `steps[].dd` |
| `PARM='2022071800'` on `EXEC PGM=CBACT04C` | the `INTCALC` driver builds the halfword-length + text structure from the `PARM` env var and CALLs `CBACT04C` | `src/INTCALC.cbl` |
| `CEE3ABD` (Language Environment user abend) | a stub that stops the run with RC 12 | `src/CEE3ABD.cbl` |
| IDCAMS `REPRO` (load / backup VSAM) | generated loader/unloader programs | `src/ksds/*.cbl` via `tools/gen-ksds-io.py` |
| DFSORT steps | two small COBOL `SORT` programs | `src/CBSORT01.cbl`, `src/CBSORT02.cbl` |
| EBCDIC overpunched signs in the data (`{A-I}J-R`) | compiled with `-fsign=EBCDIC` | `job.json` `build.cobc_flags` |
| Paragraph execution trace (no mainframe equivalent — the harness's own evidence) | compiled with `-ftrace`; `tools/run-job.py` sets `COB_SET_TRACE=1` per step and normalises the output to one `PROGRAM Paragraph NAME` line per entered paragraph (`out/steps/*.trace.txt`); the Java side writes the same lines and the comparator diffs them | `job.json` `"trace": true` |
| The system clock (`FUNCTION CURRENT-DATE`) | pinned with `COB_CURRENT_DATE="2022/07/18 00:00:00.00"` (the fractional part freezes the hundredths too — spike d) | `job.json` `env` |
| VSAM AIX path (`XREFFIL1`) | `LOAD-XREFFILE` declares the `ALTERNATE RECORD KEY`; programs that open the file without it still work under BDB (spike c) | `job.json` `datasets.XREFFILE.alt_keys` |

### Adapted

| Original | Adapted to | Reason |
|---|---|---|
| `TRANREPT.jcl` SYMNAMES `PARM-START-DATE,C'2022-01-01'` / `PARM-END-DATE,C'2022-07-06'` hard-coded in the DFSORT INCLUDE | `CBSORT02` reads the range from the `DATEPARM` file (the same 80-byte record `CBTRN03C` reads) | one fixture file drives both the sort filter and the report header |
| `TRANREPT.jcl` `SORT FIELDS=(TRAN-CARD-NUM,A)` — order of equal keys unspecified (no `OPTION EQUALS`) | `CBSORT02` sorts on card number **then TRAN-ID** | deterministic order so the report can be diffed byte for byte |
| `TRANBKP.jcl` runs *before* POSTTRAN to back up and empty the previous master | not modelled: the fixture starts without a transaction master, so `OPEN OUTPUT` in `CBTRN02C` creates it; the backup *after* POSTTRAN (needed by COMBTRAN) is modelled as step `TRANBKP` | a pre-existing master is a fixture concern, not a program concern |
| GDG generations `(+1)` / `(0)` | plain file names in the sandbox (`tranbkp.dat`, `systran.dat`, …) | one run = one generation |

### Added

`src/INTCALC.cbl`, `src/CEE3ABD.cbl`, `src/CBSORT01.cbl`, `src/CBSORT02.cbl`,
`src/ksds/*` (generated — never edit by hand), `job.json`, the fixture
recipes (`fixtures/*/fixture.json`).

### Removed

Nothing from the programs. Not carried over from CardDemo: CICS online
programs, BMS maps, the IDCAMS DEFINE/DELETE jobs, scheduler definitions,
SYSOUT message datasets, the DB2/IMS/MQ variants.

---

## 2. The job

Four business steps, in the order CardDemo's scheduler runs them, plus the
technical steps the mainframe gets from JCL utilities. Groups are the column
`group` in `job.json`; the flat step list is the restart granularity.

| # | Group | Step | Program | What it does | Reads | Writes |
|---|---|---|---|---|---|---|
| — | SETUP | `LOAD-*` ×6 | generated | IDCAMS REPRO stand-ins: build the KSDS files from the fixture's sequential seed files | `*.dat` inputs | `*.ksds` |
| **1** | POSTTRAN | `POSTTRAN` | `CBTRN02C` | Post the day's transactions: validate (card, account, credit limit, expiry), update account balance + cycle totals and the per-category balance, store the transaction; rejects go to `DALYREJS` with a reason code; RC 4 if anything rejected | DALYTRAN, XREFFILE, ACCTFILE (I-O), TCATBALF (I-O) | TRANSACT (new), DALYREJS |
| — | TRANBKP | `TRANBKP` | `UNLD-TRANSACT` | Back up the posted transactions (REPRO out) | TRANSACT | `tranbkp.dat` |
| **2** | INTCALC | `INTCALC` | `CBACT04C` via driver | Monthly interest per account/category balance: rate from the account's disclosure group (DEFAULT fallback), `balance × rate / 1200` truncated, added to the balance, cycle totals reset, one interest transaction per account | TCATBALF, XREFFILE (by account), ACCTFILE (I-O), DISCGRP | SYSTRAN |
| **3** | COMBTRAN | `COMBSORT`, `COMBLOAD` | `CBSORT01`, `LOAD-TRANSACT` | Merge backup + interest transactions sorted by TRAN-ID and reload the transaction master | `tranbkp.dat`, `systran.dat` | `combined.dat`, TRANSACT |
| **4** | TRANREPT | `REPTUNLD`, `REPTSORT`, `TRANREPT` | `UNLD-TRANSACT`, `CBSORT02`, `CBTRN03C` | Unload the master, select the date range and sort by card number, print the paged report with account / page / grand totals | TRANSACT, DATEPARM, XREFFILE, TRANTYPE, TRANCATG | `tranbkp2.dat`, `trandaly.dat`, `tranrept.dat` |
| — | CAPTURE | `UNLD-ACCTFILE`, `UNLD-TCATBALF` | generated, `always: true` | Unload the two KSDS files updated in place so the diff can see them (run even when the job failed) | ACCTFILE, TCATBALF | `acctfile.unl`, `tcatbal.unl` |

Return-code semantics (identical on both sides, see ADR-14): a step whose RC
is not in its `rc_ok` list marks the job FAILED; later steps are `NOT RUN`
except `always` steps; the job's exit code is the maximum RC of every step
executed in the instance; an abend is RC 12.

---

## 3. How to run

```bash
./tools/run-job.sh nightly-batch                      # Phase A: golden master for all 6 fixtures
./tools/run-job.sh nightly-batch 05-restart --verbose # watch the kill + resume step by step
./tools/run-java.sh nightly-batch                     # Phase C: Spring Batch, same manifest
./tools/compare-outputs.py nightly-batch              # Phase D: byte-exact diff, 9 datasets + stdout + RC per fixture
./tools/check-module.sh nightly-batch                 # process conformance
./tools/gen-coverage.py nightly-batch                 # coverage matrix from the paragraph traces
```

`./tools/run-cobol.sh nightly-batch` is equivalent to `run-job.sh` (it
dispatches on `job.json`). The read-only `equivalence-validator` subagent runs
the same three commands. Fixture inputs are regenerated with
`./tools/carddemo-fixture.py build cobol/nightly-batch/fixtures/<name>`.

---

## 4. Data dictionary

All files are record-sequential (fixed length, no line terminators) or
INDEXED. All amounts are **zoned DISPLAY with a trailing overpunched sign**:
`0000005047G` is +504.77, `0000009190}` is −919.00, `0000000000{` is 0.00
(`{`/`A`–`I` = +0…+9, `}`/`J`–`R` = −0…−9). There is **no COMP-3 in the file
layouts**; COMP-3 appears only in `CBTRN03C`'s page/line counters. Say so on
stage when the audience expects packed fields.

| Dataset (manifest) | Copybook | LRECL | Key | Fields that matter |
|---|---|---|---|---|
| DALYTRAN / TRANSACT / TRANBKP / SYSTRAN / COMBINED / TRANDALY | `CVTRA06Y` / `CVTRA05Y` | 350 | TRAN-ID X(16) | TYPE-CD X(2), CAT-CD 9(4), SOURCE X(10), DESC X(100), **AMT S9(9)V99** @133, MERCHANT-ID 9(9), CARD-NUM X(16) @263, ORIG-TS X(26), PROC-TS X(26) @305 |
| ACCTFILE / ACCTUNL | `CVACT01Y` | 300 | ACCT-ID 9(11) | ACTIVE X(1), **CURR-BAL, CREDIT-LIMIT, CASH-CREDIT-LIMIT S9(10)V99**, OPEN/EXPIRAION/REISSUE dates X(10), **CYC-CREDIT, CYC-DEBIT S9(10)V99**, ADDR-ZIP X(10), GROUP-ID X(10) @113 |
| XREFFILE | `CVACT03Y` | 50 | CARD-NUM X(16); AIX ACCT-ID @26 | CUST-ID 9(9), ACCT-ID 9(11) |
| TCATBALF / TCATUNL | `CVTRA01Y` | 50 | ACCT-ID 9(11) + TYPE-CD X(2) + CAT-CD 9(4) | **TRAN-CAT-BAL S9(9)V99** |
| DISCGRP | `CVTRA02Y` | 50 | GROUP-ID X(10) + TYPE-CD X(2) + CAT-CD 9(4) | **DIS-INT-RATE S9(4)V99** (percent per year) |
| TRANTYPE | `CVTRA03Y` | 60 | TYPE X(2) | DESC X(50) |
| TRANCATG | `CVTRA04Y` | 60 | TYPE-CD X(2) + CAT-CD 9(4) | DESC X(50) |
| DALYREJS | — (inline in CBTRN02C) | 430 | — | the 350-byte DALYTRAN record + reason 9(4) + text X(76) |
| DATEPARM | — (inline in CBTRN03C) | 80 | — | START X(10), X(1), END X(10) |
| TRANREPT | `CVTRA07Y` | 133 | — | report lines; amounts edited `-ZZZ,ZZZ,ZZZ.ZZ` (detail) and `+ZZZ,ZZZ,ZZZ.ZZ` (totals) |

Field names in `tools/make-fixture.py` layouts are the COBOL data names, so
fixture recipes edit records by name (`"ACCT-CREDIT-LIMIT": "500.00"`).

---

## 5. Fixtures

| Fixture | Inputs | What it exercises | Expected |
|---|---|---|---|
| `01-happy-small` | accounts 1-5, 30 txns; accounts 1-2 given group `A000000000`, account 3's limit lowered to 1000.00 | the whole job on a readable scale: direct DISCGRP hit *and* DEFAULT fallback, TCATBAL create (type 03) and update paths, 6 rejects 102, interest for 4 accounts | RC 4; account 5 (last in TCATBAL order) keeps its cycle totals and gets no interest — defect D1 |
| `02-rejects` | accounts 1-5 + one orphan card | every reason code once: 100 (card not in XREF), 101 (XREF → non-existent account), 102 (over limit), 103 (expired before the transaction date), and precedence: account 4 is both over limit and expired → 103 | RC 4; rejects {100:1, 101:1, 102:6, 103:12} |
| `03-numeric-boundaries` | accounts 1-5, 7 hand-made txns | truncation 0.09575→0.09 and −11.4875→−11.48 (DOWN, not FLOOR); zero amount; exactly-at-limit passes, +0.01 rejects; balance 9999999999.00+5.00 wraps to 4.00 (no `ON SIZE ERROR`); 10-digit cycle credit truncated into `WS-TEMP-BAL S9(9)V99` so a 50.00 purchase passes a 100.00 limit | RC 4; **negative-control target** (flip `RoundingMode.DOWN` → red at a named record/column) |
| `04-full-carddemo` | the untouched seed set: 50 accounts, 300 txns | volume + the report's page breaks (18 pages) | RC 4; 262 posted / 38 rejected (all 102); 50 "Creating." lines; 312 report lines; grand total overstated by the last amount — defect D2 |
| `05-restart` | byte-copy of 01 | `JOB_PLAN="abend-after=INTCALC;resume"`: the job is killed after step 2 of 4 and resumed in a second run | outputs identical to 01 except `run-log.txt` and `steps/`; RC 4 (`check-module.sh` enforces the invariant) |
| `06-abend-discgrp` | accounts 1-2 + one txn with category 9999 | POSTTRAN accepts it (no category check) and creates the TCATBAL row; INTCALC finds no rate under the account's group nor under DEFAULT → `CEE3ABD` | RC 12; COMBTRAN and TRANREPT `NOT RUN (JOB FAILED)`; capture unloads still run |

Determinism: running `run-job.sh` twice yields byte-identical golden masters
(verified on 04).

---

## 6. Paragraph → fixture coverage

Business explanation per paragraph (what each one does, in Spanish, with the spec section): [PARAGRAPHS.md](./PARAGRAPHS.md); the viewer [traceability.html](./traceability.html) shows it under each paragraph.

<!-- BEGIN AUTO-GENERATED COVERAGE (gen-coverage.py) -->
Coverage from the paragraph traces: **82 / 86 paragraphs** of 14 programs are entered by at least one of the 6 fixtures. Full matrix: [COVERAGE.md](./COVERAGE.md).

Not reached by any fixture: `CBTRN02C.9999-ABEND-PROGRAM`, `CBTRN02C.9910-DISPLAY-IO-STATUS`, `CBTRN03C.9999-ABEND-PROGRAM`, `CBTRN03C.9910-DISPLAY-IO-STATUS`.
<!-- END AUTO-GENERATED COVERAGE -->

The matrix is **generated from the GnuCOBOL paragraph traces** of the golden
master (`-ftrace`, see spike k and ADR-17): `./tools/gen-coverage.py
nightly-batch` rewrites [COVERAGE.md](./COVERAGE.md) and the summary above;
`--check` is the drift gate used by `tools/check-module.sh`. The same traces
are emitted by the Java side and diffed as a channel of their own, so "the
Java executes the same paragraphs in the same order" is part of the
byte-exact proof.

The four unreached paragraphs are the abend path of `CBTRN02C` and `CBTRN03C`
(`9999-ABEND-PROGRAM`, `9910-DISPLAY-IO-STATUS`): reaching them needs a
broken file (open/write failure) or a transaction type/category missing from
the reference tables. The same two paragraphs of `CBACT04C` are reached by
fixture 06. Not exercised either, inside otherwise covered paragraphs: the
file-error branches of every open/close/read/write paragraph and the
`INVALID KEY` → reason 109 branch of `2800-UPDATE-ACCOUNT-REC` (documented in
the spec §9).

---

## 7. Faithful defects (replicated, never fixed — CLAUDE.md rule 5)

| Id | Where | What happens | Observable in |
|---|---|---|---|
| **D1** | `CBACT04C.cbl:219-221` | `ELSE PERFORM 1050-UPDATE-ACCOUNT` belongs to `IF END-OF-FILE = 'N'` inside `PERFORM UNTIL END-OF-FILE = 'Y'`; the loop condition is tested first, so the ELSE never runs. The last account in TCATBAL key order gets its interest **transaction** written but its balance is never updated and its cycle totals are never reset. | `acctfile.unl`: account 5 in 01/02/03/05, account 50 in 04 |
| **D2** | `CBTRN03C.cbl:197-204` | At end of file `READ … INTO TRAN-RECORD` leaves the previous record in place, and the EOF branch does `ADD TRAN-AMT TO WS-PAGE-TOTAL WS-ACCOUNT-TOTAL` once more before printing page and grand totals. The grand total is overstated by the last detail amount; the last card's account total is never printed. | `tranrept.dat` in 04: grand total 79,254.29 vs 79,233.86 input sum (Δ = 20.43, the last line); invisible in 03 because the last record there is the 0.00 transaction |
| **D3** | `CBTRN03C.cbl:177` | `NEXT SENTENCE` inside an inline `PERFORM` jumps past the loop's closing period (spike f): the first out-of-range record would end the whole report. Unreachable in the job because `REPTSORT` applies the same date filter first. | not observable; documented for the translator |
| D4 | `CBTRN02C.cbl:649` | `9300-DALYREJS-CLOSE` displays `XREFFILE-STATUS` instead of the rejects file status (copy-paste). | only on a close failure (✘) |
| D5 | `CBACT04C.cbl:281` | DISCGRP open error says `ERROR OPENING DALY REJECTS FILE`. | only on an open failure (✘) |
| D6 | `CBTRN02C.cbl:393-423` | `WS-TEMP-BAL` is `S9(09)V99` while the cycle totals are `S9(10)V99`: the over-limit check silently truncates the high-order digit (ADR-12 pattern: truncation is part of the algorithm). | 03, account 5 |

---

## 8. Spike log (WP0, GnuCOBOL 3.2.0 / BDB, macOS)

| # | Question | Result |
|---|---|---|
| a | Does `-fsign=EBCDIC` read and write the overpunched signs of the seed data? | **Pass.** `0000005047G` → +504.77, `0000009190}` → −919.00, written back identically; zero → `0000000000{`. Without the flag the values are misread (+504.70, +919.00) — the flag is load-bearing. |
| b | Do unquoted `ASSIGN TO DALYTRAN` names resolve through `DD_DALYTRAN`? | **Pass** with `-fassign-clause=external` (and also with the default dynamic clause). Without the variable the open fails with status 35, like a missing DD. |
| c | Does a BDB indexed file with an alternate key open in a program that does not declare it? | **Pass.** INPUT, I-O and REWRITE all return 00; re-opening with the alternate key afterwards still reads by it. One physical XREF copy is enough. |
| d | Does `COB_CURRENT_DATE` freeze `FUNCTION CURRENT-DATE`? | Date and seconds yes; **hundredths kept ticking** with `"2022/07/18 00:00:00"`. With fractional seconds, `"2022/07/18 00:00:00.00"`, the value is constant. Both programs copy the hundredths into the DB2 timestamp, so the fractional form is required. |
| e | Can a `CEE3ABD` stub end the step with RC 12 without returning? | **Pass** (`STOP RUN` after `MOVE 12 TO RETURN-CODE`; linked statically). |
| f | `NEXT SENTENCE` inside an inline `PERFORM`? | Control jumps to after the next period — past `END-PERFORM` *and* the following statement of the same sentence. |
| g | `SORT … USING f1 f2 GIVING f3` on record-sequential files; stability? | **Pass**; output order of equal keys followed input order in the test, but it is not guaranteed — hence the TRAN-ID tie-break in `CBSORT02`. |
| h | Indexed `OPEN OUTPUT` on an existing file; duplicate `WRITE`? | Truncates (old keys read status 23); duplicate write status 22. |
| i | Spring Batch 5 + H2 file database: restart across two JVM runs? | **Pass.** Run 1 fails after STEP2 via a decider (`.fail()`); run 2 with the same identifying parameters skips STEP1-2 and completes STEP3-4; `initialize-schema=always` tolerates the existing schema. One decider *object per position* is required — a shared decider loops. |
| j | Does `INITIALIZE` touch FILLER? Does `READ … INTO` move on INVALID KEY? | FILLER untouched (`KLMNO` survived); no move on a failed read. Both verified after the first Java run was red on exactly 22 FILLER bytes per created TCATBAL row. |
| k | Can GnuCOBOL emit a paragraph trace without touching the source? | **Pass.** Compile with `-ftrace`; at run time `COB_SET_TRACE=1 COB_TRACE_FILE=<path> COB_TRACE_FORMAT="%I %S"` writes one line per entered paragraph: `SPKK Paragraph: 1000-FIRST`, sections as `SPKK   Section: 4000-SECTION`, program starts as `SPKK     Entry: SPKK`, called programs with their own id (`CEE3ABD     Entry: CEE3ABD`), plus `Source:`/`Program-Id:` header lines to drop. Deterministic across runs; no file without `COB_SET_TRACE`; stdout of the traced binary byte-identical to the untraced one. `PERFORM a THRU c` logs a, b, c; a `PERFORM VARYING` logs the paragraph once per iteration; paragraphs after a `SECTION` header belong to it (a `PERFORM section` runs them all). |

---

## 9. Determinism pins

| Source of variation | Pin | Where |
|---|---|---|
| `FUNCTION CURRENT-DATE` in CBTRN02C and CBACT04C | `COB_CURRENT_DATE="2022/07/18 00:00:00.00"` → every `*-PROC-TS` is `2022-07-18-00.00.00.000000` | `job.json` env; Java: fixed `Clock` from the same value |
| Sort order of equal card numbers | secondary key TRAN-ID | `CBSORT02` |
| Interest transaction ids | `PARM-DATE` + running suffix, PARM pinned to `2022071800` | `job.json` step INTCALC |
| Report date range | `dateparm.dat` from `fixture.json` `date_range` | fixture |
| Timezone suffix of CURRENT-DATE (`-0300`) | lands in `COB-REST`, never copied anywhere | — |

---

## 10. Not covered by this module

DB2 cursors (CardDemo's batch is VSAM-only), COMP-3 **file** fields (only
working-storage counters here), GDG generation management, DFSORT `OPTION
EQUALS` semantics, JCL `COND=` expressions other than "stop after failure",
and the TRANREPT abend on a missing type/category (no fixture yet).
