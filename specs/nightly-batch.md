# Spec — `nightly-batch` (CardDemo nightly close)

## 1. Header

| | |
|---|---|
| Module | `nightly-batch` (module 3) |
| COBOL ground truth | `cobol/nightly-batch/src/CBTRN02C.cbl`, `CBACT04C.cbl`, `CBTRN03C.cbl` (verbatim AWS CardDemo) + added `INTCALC.cbl`, `CEE3ABD.cbl`, `CBSORT01.cbl`, `CBSORT02.cbl`, generated `src/ksds/*.cbl` |
| Job manifest | `cobol/nightly-batch/job.json` (16 steps, 24 datasets) |
| Java target | `java/nightly-batch` — Spring Boot 3 + Spring Batch 5 + JDBC/H2, `BigDecimal` everywhere |
| Golden master | `golden-master/nightly-batch/<fixture>/` (6 fixtures) |
| Reviewer | a banking analyst who does not read COBOL; every rule below cites the COBOL line it came from |
| Status | Phase B — written from the golden master; COBOL wins on any disagreement (CLAUDE.md rule 3) |

Terminology: a *step* is one program run (JCL `EXEC PGM=`); a *dataset* is a file in the job's sandbox; *KSDS* is an indexed file with a unique key (VSAM on the mainframe, BDB under GnuCOBOL, a table on the Java side).

---

## 2. Purpose

End-of-day close of a credit-card portfolio in four business steps:

1. **Post the day's transactions** (`POSTTRAN`, `CBTRN02C`) — validate each card transaction and apply it to the account, the per-category balance and the transaction master; reject the rest with a reason code.
2. **Charge monthly interest** (`INTCALC`, `CBACT04C`) — for each account's category balance, look up the interest rate of the account's disclosure group and add the interest to the account; write one interest transaction per account.
3. **Rebuild the transaction master** (`COMBTRAN`, `CBSORT01` + `LOAD-TRANSACT`) — merge posted and interest transactions, sorted by transaction id.
4. **Print the daily transaction report** (`TRANREPT`, `UNLD-TRANSACT` + `CBSORT02` + `CBTRN03C`) — select the date range, sort by card, print with account, page and grand totals.

Around them, SETUP loaders build the KSDS files from the fixture (IDCAMS REPRO), `TRANBKP` backs up the posted transactions, and two always-on CAPTURE unloads expose the in-place-updated KSDS files to the diff.

---

## 3. Inputs

All files are fixed-length records with **no line terminators**. Signed amounts are zoned decimal with a trailing EBCDIC overpunch (`{`/`A`–`I` = +0…+9, `}`/`J`–`R` = −0…−9); unsigned numerics are plain digits, zero-padded; text is space-padded.

| Dataset | File | LRECL | Layout (1-based offsets) | Staged from |
|---|---|---|---|---|
| ACCTDATA → ACCTFILE | `acctdata.dat` → `acctfile.ksds` | 300 | `ACCT-ID` 9(11) @1 **key** · `ACCT-ACTIVE-STATUS` X @12 · `ACCT-CURR-BAL` S9(10)V99 @13 · `ACCT-CREDIT-LIMIT` @25 · `ACCT-CASH-CREDIT-LIMIT` @37 · `ACCT-OPEN-DATE` X(10) @49 · `ACCT-EXPIRAION-DATE` @59 · `ACCT-REISSUE-DATE` @69 · `ACCT-CURR-CYC-CREDIT` S9(10)V99 @79 · `ACCT-CURR-CYC-DEBIT` @91 · `ACCT-ADDR-ZIP` X(10) @103 · `ACCT-GROUP-ID` X(10) @113 · FILLER X(178) @123 | fixture `in/` |
| CARDXREF → XREFFILE | `cardxref.dat` → `xreffile.ksds` | 50 | `XREF-CARD-NUM` X(16) @1 **key** · `XREF-CUST-ID` 9(9) @17 · `XREF-ACCT-ID` 9(11) @26 **alternate key** · FILLER X(14) | fixture |
| TCATBAL → TCATBALF | `tcatbal.dat` → `tcatbal.ksds` | 50 | `TRANCAT-ACCT-ID` 9(11) @1 + `TRANCAT-TYPE-CD` X(2) @12 + `TRANCAT-CD` 9(4) @14 = **17-byte key** · `TRAN-CAT-BAL` S9(9)V99 @18 · FILLER X(22) | fixture |
| DISCGRPS → DISCGRP | `discgrp.dat` → `discgrp.ksds` | 50 | `DIS-ACCT-GROUP-ID` X(10) @1 + `DIS-TRAN-TYPE-CD` X(2) @11 + `DIS-TRAN-CAT-CD` 9(4) @13 = **16-byte key** · `DIS-INT-RATE` S9(4)V99 @17 (annual %, e.g. `00150{` = 15.00) · FILLER X(28) | fixture |
| TRANTYPES → TRANTYPE | `trantype.dat` → `trantype.ksds` | 60 | `TRAN-TYPE` X(2) **key** · `TRAN-TYPE-DESC` X(50) · FILLER X(8) | fixture |
| TRANCATGS → TRANCATG | `trancatg.dat` → `trancatg.ksds` | 60 | `TRAN-TYPE-CD` X(2) + `TRAN-CAT-CD` 9(4) = **6-byte key** · `TRAN-CAT-TYPE-DESC` X(50) · FILLER X(4) | fixture |
| DALYTRAN | `dailytran.dat` | 350 | `DALYTRAN-ID` X(16) @1 · `TYPE-CD` X(2) @17 · `CAT-CD` 9(4) @19 · `SOURCE` X(10) @23 · `DESC` X(100) @33 · `AMT` S9(9)V99 @133 · `MERCHANT-ID` 9(9) @144 · `MERCHANT-NAME` X(50) @153 · `MERCHANT-CITY` X(50) @203 · `MERCHANT-ZIP` X(10) @253 · `CARD-NUM` X(16) @263 · `ORIG-TS` X(26) @279 · `PROC-TS` X(26) @305 · FILLER X(20) @331 | fixture |
| DATEPARM | `dateparm.dat` | 80 | `WS-START-DATE` X(10) @1 · FILLER X(1) · `WS-END-DATE` X(10) @12 · spaces | fixture |
| PARM (INTCALC) | env `PARM` | 10 | `2022071800` → `PARM-DATE` X(10); `PARM-LENGTH` = 10 | `job.json` |
| Clock | env `COB_CURRENT_DATE` | — | `2022/07/18 00:00:00.00` → every `FUNCTION CURRENT-DATE` returns `2022071800000000` + zone | `job.json` |

DD mapping per step is the `dd` map of each step in `job.json` (§8 of `DEPENDENCIES.md`).

---

## 4. Per-step processing

### 4.1 SETUP — `LOAD-<DS>` (generated, `src/ksds/LOAD-*.cbl`)

For every record of `SEQIN`: `WRITE` it into the empty KSDS (`OPEN OUTPUT`, access RANDOM). A duplicate key displays `LOAD-<DS>: DUPLICATE KEY <key> STATUS 22` and sets RC 8 (not exercised). At the end: `LOAD-<DS>: LOADED nnnnnnnnn RECORDS` (9 digits, zero-padded). RC 0.

### 4.2 Step 1 — POSTTRAN (`CBTRN02C.cbl`)

```
display 'START OF EXECUTION OF PROGRAM CBTRN02C'                       (194)
open DALYTRAN in, TRANSACT out (created/truncated), XREFFILE in,
     DALYREJS out, ACCTFILE i-o, TCATBALF i-o                          (195-200)
for each DALYTRAN record (status 10 = end)                              (201-219, 345-369)
    count += 1
    reason := 0, reason-text := spaces
    VALIDATE  (§5)                                                      (370-423)
    if reason = 0 then POST else REJECT
display 'TRANSACTIONS PROCESSED :' count   (9 digits)                   (227)
display 'TRANSACTIONS REJECTED  :' rejects (9 digits)                   (228)
RETURN-CODE := 4 if rejects > 0                                         (229-231)
display 'END OF EXECUTION OF PROGRAM CBTRN02C'                          (232)
```

**POST** (`2000-POST-TRANSACTION`, 424-445): copy the 12 business fields of the daily record into a transaction record; `TRAN-PROC-TS` := DB2-format timestamp from the pinned clock (`2022-07-18-00.00.00.000000`, §6.4); then

- `2700-UPDATE-TCATBAL` (467-544): key = account id from XREF + daily type + daily category. `READ` the balance row; if **not found** (status 23) display `TCATBAL record not found for key : <17-byte key>.. Creating.` and `WRITE` a new row = key + amount (`INITIALIZE` then `ADD`); otherwise `ADD` the amount to the balance and `REWRITE`.
- `2800-UPDATE-ACCOUNT-REC` (545-561): `ADD` amount to `ACCT-CURR-BAL`; if amount ≥ 0 `ADD` it to `ACCT-CURR-CYC-CREDIT` else to `ACCT-CURR-CYC-DEBIT` (debits accumulate as a **negative** number); `REWRITE` the account. An INVALID KEY on the rewrite sets reason 109 but the transaction is already posted and is not counted as a reject (not exercised).
- `2900-WRITE-TRANSACTION-FILE` (562-581): `WRITE` the record to TRANSACT (key TRAN-ID).

**REJECT** (`2500-WRITE-REJECT-REC`, 446-466): rejects += 1; write 430 bytes to DALYREJS = the daily record (350) + reason `9(4)` + reason text `X(76)`.

### 4.3 TRANBKP — `UNLD-TRANSACT`

Read the KSDS in key order (`READ NEXT`), write each record to `SEQOUT`. Display `UNLD-TRANSACT: UNLOADED nnnnnnnnn RECORDS`. Output is therefore **sorted by TRAN-ID**.

### 4.4 Step 2 — INTCALC (`INTCALC.cbl` → `CBACT04C.cbl`)

Driver: `PARM` env → `EXTERNAL-PARMS` (length 10, date `2022071800`), `CALL 'CBACT04C'`.

```
display 'START OF EXECUTION OF PROGRAM CBACT04C'                       (181)
open TCATBALF in (sequential, key order), XREFFILE in, DISCGRP in,
     ACCTFILE i-o, TRANSACT (= SYSTRAN) out                             (182-186)
last-acct := spaces, first := 'Y', total-int := 0, suffix := 0
for each TCATBAL record in key order (status 10 = end)                  (187-227)
    display the raw 50-byte record                                      (193)
    if account id ≠ last-acct                                           (194)
        if not first: UPDATE-ACCOUNT (for the previous account)         (195-196)   ← see D1
        first := 'N'; total-int := 0; last-acct := account id
        READ ACCTFILE by account id                                      (372-392)  'ACCOUNT NOT FOUND: ' + abend if missing
        READ XREFFILE by alternate key (account id) → card number        (393-414)
    rate := GET-INTEREST-RATE(group = ACCT-GROUP-ID, type, category)    (415-461, §5.3)
    if rate ≠ 0                                                          (213)
        COMPUTE-INTEREST and WRITE-TX                                    (462-517, §6.1)
        COMPUTE-FEES (empty)                                             (518-521)
(the ELSE UPDATE-ACCOUNT at 219-221 never runs — D1)
close files; display 'END OF EXECUTION OF PROGRAM CBACT04C'             (222-232)
```

**UPDATE-ACCOUNT** (`1050`, 350-371): `ADD total-int TO ACCT-CURR-BAL`; `ACCT-CURR-CYC-CREDIT := 0`; `ACCT-CURR-CYC-DEBIT := 0`; `REWRITE`.

**WRITE-TX** (`1300-B`, 473-517): suffix += 1; `TRAN-ID` := PARM-DATE (10) + suffix `9(6)`; type `'01'`; category `'05'` → `0005`; source `'System'`; description `'Int. for a/c ' + ACCT-ID` (24 chars, rest of the 100 untouched = spaces); amount := monthly interest; merchant id 0, merchant name/city/zip spaces; card := the XREF card; ORIG-TS and PROC-TS := pinned DB2 timestamp; `WRITE` to SYSTRAN (sequential, in processing order).

### 4.5 Step 3 — COMBTRAN

`CBSORT01`: `SORT` the concatenation of `tranbkp.dat` and `systran.dat` on `TRAN-ID` ascending → `combined.dat`; display `CBSORT01: SORT COMPLETE`. `LOAD-TRANSACT`: reload `transact.ksds` from it (truncating), display `LOAD-TRANSACT: LOADED nnnnnnnnn RECORDS`.

### 4.6 Step 4 — TRANREPT

`UNLD-TRANSACT` → `tranbkp2.dat` (key order). `CBSORT02`: read DATEPARM; keep records whose `TRAN-PROC-TS(1:10)` is between start and end dates inclusive (string compare); sort on `TRAN-CARD-NUM` then `TRAN-ID` → `trandaly.dat`; display `CBSORT02: SELECTED nnnnnnnnn OF nnnnnnnnn RECORDS FOR <start> TO <end>`.

`CBTRN03C`:
```
display 'START OF EXECUTION OF PROGRAM CBTRN03C'                       (158)
open 6 files; READ DATEPARM → display 'Reporting from <start> to <end>'  (159-165, 220-246)
line := 0, page-size := 20, page-total := account-total := grand-total := 0,
first := 'Y', current-card := spaces
loop until EOF                                                          (166-209)
    READ next transaction INTO TRAN-RECORD (status 10 → EOF; record area keeps the previous record)
    (date filter 171-176: always true after CBSORT02)
    if not EOF:
        display the raw 350-byte record                                 (178)
        if card ≠ current-card:                                         (179-185)
            if not first: WRITE-ACCOUNT-TOTALS
            current-card := card; READ XREFFILE by card → account id    (484-492; INVALID KEY → abend)
        READ TRANTYPE by type → description; READ TRANCATG by type+category → description   (186-195; INVALID KEY → abend)
        WRITE-TRANSACTION-REPORT                                        (274-292, §7.4)
    else (EOF):                                                         (198-204)
        display 'TRAN-AMT ' amount  and  'WS-PAGE-TOTAL' page-total     (GnuCOBOL formats, §7.1)
        ADD amount (of the LAST record, stale) TO page-total AND account-total   ← D2
        WRITE-PAGE-TOTALS; WRITE-GRAND-TOTALS
close files; display 'END OF EXECUTION OF PROGRAM CBTRN03C'             (211-217)
```

### 4.7 CAPTURE — `UNLD-ACCTFILE`, `UNLD-TCATBALF`

Always run (even after a failed step). Key-order unload of the two in-place-updated files to `acctfile.unl` / `tcatbal.unl`.

---

## 5. Validation rules (`CBTRN02C` 370-423)

Checks run **in this order and all of them run**; a later failure overwrites an earlier reason (the reason is a single field). Only the final reason is written.

| # | Rule | Reason | Text (76 chars, space-padded) | COBOL |
|---|---|---|---|---|
| 1 | The card must exist in XREFFILE | 100 | `INVALID CARD NUMBER FOUND` | 380-392 (stops here: rules 2-4 need the account) |
| 2 | The account named by the XREF row must exist in ACCTFILE | 101 | `ACCOUNT RECORD NOT FOUND` | 393-397 (stops here) |
| 3 | Over limit: `temp := ACCT-CURR-CYC-CREDIT − ACCT-CURR-CYC-DEBIT + amount` must satisfy `ACCT-CREDIT-LIMIT ≥ temp`. Cycle debit is stored negative, so `credit − debit` is the cycle's **gross** activity. `temp` is `S9(09)V99`: an 11-digit intermediate is truncated on the left (§6.3) | 102 | `OVERLIMIT TRANSACTION` | 399-412 |
| 4 | Not expired: `ACCT-EXPIRAION-DATE ≥ ORIG-TS(1:10)` as a plain string comparison (`yyyy-mm-dd`) | 103 | `TRANSACTION RECEIVED AFTER ACCT EXPIRATION` | 414-421 |

Precedence example (fixture 02, account 4): over limit **and** expired → written reason is 103.
Not validated at all: type, category, merchant, amount sign, duplicate TRAN-ID (a duplicate would abend on the WRITE, status 22).

### 5.3 Interest-rate lookup (`CBACT04C` 415-461)

Key = (`ACCT-GROUP-ID`, type, category). If the row is **missing** (status 23): display `DISCLOSURE GROUP RECORD MISSING` and `TRY WITH DEFAULT GROUP CODE`, then read (`'DEFAULT'`, type, category). If that is missing too: display `ERROR READING DEFAULT DISCLOSURE GROUP`, `FILE STATUS IS: NNNN0023`, `ABENDING PROGRAM`, then the abend stub prints `CEE3ABD: USER ABEND U+000000999` and the step ends with RC 12 (fixture 06). Rate 0 (e.g. DEFAULT 03/0001) means "no interest, no interest transaction".

---

## 6. Numeric calculations

Every numeric is `BigDecimal` on the Java side with the scale of the PIC. The rules below name the rounding mode explicitly.

### 6.1 Monthly interest (`CBACT04C` 464-467)
`monthly := (TRAN-CAT-BAL × DIS-INT-RATE) / 1200` stored into `S9(09)V99` **without ROUNDED** → `RoundingMode.DOWN` (truncation toward zero), scale 2. Evidence (fixture 03): 7.66 × 15.00 / 1200 = 0.09575 → **0.09**; −919.00 × 15.00 / 1200 = −11.4875 → **−11.48** (not −11.49). Then `total-int += monthly` (exact, scale 2).
Account update: `ACCT-CURR-BAL += total-int` (exact; `S9(10)V99`, no SIZE ERROR → §6.3).

### 6.2 Posting arithmetic (`CBTRN02C` 508, 527, 547-552)
`ADD amount TO TRAN-CAT-BAL / ACCT-CURR-BAL / ACCT-CURR-CYC-CREDIT / ACCT-CURR-CYC-DEBIT` — exact, scale 2, no rounding.

### 6.3 Overflow and truncation (no `ON SIZE ERROR` anywhere)
`ADD` into a field too small keeps the **low-order** digits (COBOL standard truncation; ADR-12). Evidence (fixture 03): `9999999999.00 + 5.00` into `S9(10)V99` → `0000000004.00`. Java: `result.remainder(10^digits)` with the sign preserved.
`COMPUTE WS-TEMP-BAL` (`S9(09)V99`) from `S9(10)V99` operands: same low-order retention → `1000000050.00` becomes `000000050.00`, so a 50.00 purchase passes a 100.00 limit (fixture 03, account 5).

### 6.4 Timestamps (`Z-GET-DB2-FORMAT-TIMESTAMP`, CBTRN02C 692-706 / CBACT04C 613-627)
`CURRENT-DATE` (21 chars `YYYYMMDDhhmmsshh±zzzz`) → `YYYY-MM-DD-hh.mm.ss.hh0000` (26). With the pinned clock: `2022-07-18-00.00.00.000000`.

### 6.5 Report totals (`CBTRN03C`)
`WS-PAGE-TOTAL`, `WS-ACCOUNT-TOTAL`, `WS-GRAND-TOTAL` are `S9(09)V99`; `ADD` exact. Counters `WS-LINE-COUNTER 9(9) COMP-3`, `WS-PAGE-SIZE 9(3) COMP-3 = 20` — `BigDecimal`/integer semantics, no money.

### 6.6 Sort keys
`CBSORT01`: ascending `TRAN-ID` (16 chars, byte order). `CBSORT02`: ascending `TRAN-CARD-NUM` (16) then `TRAN-ID`. Java: `String.compareTo` on the padded fields (ASCII byte order; all keys are digits).

---

## 7. Outputs (the byte-exact contract)

### 7.1 stdout (GnuCOBOL `DISPLAY` formats)
Per step, captured to `out/steps/<nn>-<NAME>.stdout.txt`; `stdout.txt` is their concatenation with `=== <nn>-<NAME> RC=<rrrr> ===` headers (built by `run-job.py` on both sides). Lines end with `\n`. Formats:
- unsigned `9(9)`: 9 digits, e.g. `TRANSACTIONS PROCESSED :000000300`
- signed `S9(9)V99` (`DISPLAY TRAN-AMT`, `WS-PAGE-TOTAL`): sign + 9 digits + `.` + 2 decimals, e.g. `TRAN-AMT +000000020.43`, `WS-PAGE-TOTAL+000001644.09` (no space after the literal)
- `S9(9) BINARY` (`ABCODE`): `+000000999`
- raw records: `DISPLAY TRAN-CAT-BAL-RECORD` (50 bytes) in CBACT04C, `DISPLAY TRAN-RECORD` (350 bytes) in CBTRN03C — the bytes as stored, overpunch included
- `FILE STATUS IS: NNNN0023` (`9910-DISPLAY-IO-STATUS`: numeric status → `0000` with the two digits at positions 3-4)

### 7.2 Return codes
POSTTRAN: 4 if any reject else 0. Abend: 12. Everything else 0. Job exit code = MAXRC.

### 7.3 Datasets (all captured, all fixed-length, no terminators)

| File | LRECL | Content and order |
|---|---|---|
| `dalyrejs.dat` | 430 | rejected daily records in input order + `9(4)` reason + `X(76)` text; empty file when nothing is rejected |
| `tranbkp.dat` | 350 | posted transactions, **TRAN-ID order** (KSDS unload); `PROC-TS` = pinned timestamp, FILLER = spaces |
| `systran.dat` | 350 | interest transactions, in TCATBAL key order; `TRAN-ID` = `2022071800` + 6-digit suffix; `ORIG-TS` = `PROC-TS` = pinned timestamp |
| `combined.dat` | 350 | `tranbkp` + `systran` sorted by TRAN-ID |
| `tranbkp2.dat` | 350 | = `combined.dat` (reload + unload in key order) |
| `trandaly.dat` | 350 | records of `tranbkp2` with `PROC-TS(1:10)` in range, sorted by card then TRAN-ID |
| `tranrept.dat` | 133 | the report, §7.4 |
| `acctfile.unl` | 300 | all accounts in key order, after both updates (D1: the last account of TCATBALF keeps its cycle totals) |
| `tcatbal.unl` | 50 | all category balances in key order, including rows created by POSTTRAN |

### 7.4 Report layout (`CVTRA07Y`, 133-byte lines)
- Headers (4 lines, written first and after every page total): `REPORT-NAME-HEADER` (`DALYREPT` X(38) · `Daily Transaction Report` X(41) · `Date Range: ` X(12) · start X(10) · ` to ` · end X(10) · spaces), a blank line, `TRANSACTION-HEADER-1` (column titles), `TRANSACTION-HEADER-2` (133 × `-`).
- Detail: `TRAN-ID` X(16) · ` ` · account id X(11) · ` ` · type X(2) · `-` · type desc X(15) · ` ` · category `9(4)` · `-` · category desc X(29) · ` ` · source X(10) · 4 spaces · amount `-ZZZ,ZZZ,ZZZ.ZZ` · 2 spaces · (rest spaces). Descriptions are truncated to 15 / 29 chars. Edited amount: fixed leading sign position (`-` or space), zero suppression with floating commas; a zero amount prints as `           .00` (digits suppressed, point kept).
- Page break: before writing a detail, if `MOD(line-counter, 20) = 0` → `Page Total ` X(11) + 86 × `.` + `+ZZZ,ZZZ,ZZZ.ZZ` (explicit `+`/`-`), then header line 2, then the 4 header lines. The line counter counts every written line (headers included); page totals are added to the grand total and reset.
- Account change: `Account Total` X(13) + 84 × `.` + `+ZZZ,ZZZ,ZZZ.ZZ`, then header line 2.
- End of file: page total line + header line 2, then `Grand Total` X(11) + 86 × `.` + `+ZZZ,ZZZ,ZZZ.ZZ`. **No account total for the last card** and the last amount is counted twice (D2).

### 7.5 Job log `out/run-log.txt`
`JOB NIGHTLY RUN n` / `STEP nn NAME RC=rrrr` / `STEP nn NAME SKIPPED (COMPLETED IN RUN m)` / `STEP nn NAME NOT RUN (JOB FAILED)` / `ABEND AFTER NAME (injected)` / `JOB NIGHTLY END MAXRC=rrrr`. Byte-identical on both sides.

---

## 8. Side effects

- `acctfile.ksds` and `tcatbal.ksds` are **updated in place** by steps 1 and 2 (REWRITE / WRITE); only their unloads are diffed.
- `transact.ksds` is created by step 1 (`OPEN OUTPUT` truncates an existing file) and recreated by COMBLOAD.
- A failed step (RC outside `rc_ok`) stops the business steps; CAPTURE steps still run.
- Restart: a resumed run skips steps already completed; outputs must equal an unbroken run (fixture 05 invariant).
- The pinned clock makes every timestamp identical; nothing else is time-dependent.

---

## 9. Out of scope

CICS online programs; DB2; GDG generation numbers; DFSORT `OPTION EQUALS`, `ZD` vs `CH` collation (identical on all-digit keys); EBCDIC collation (keys are digits); file-error branches (open/close/read/write failures); TRANREPT abends on missing type/category rows; performance.

---

## 10. Traceability

| Java symbol | COBOL |
|---|---|
| `PostTranTasklet` | `CBTRN02C.cbl:193-234` main loop |
| `TransactionValidator.validate` | `CBTRN02C.cbl:370-423` |
| `TransactionPoster.post` / `.reject` | `CBTRN02C.cbl:424-581` |
| `CobolTimestamp.db2Format` | `CBTRN02C.cbl:692-706`, `CBACT04C.cbl:613-627` |
| `IntCalcTasklet` | `INTCALC.cbl`, `CBACT04C.cbl:181-232` |
| `InterestCalculator.monthlyInterest` | `CBACT04C.cbl:462-467` |
| `InterestCalculator.rateFor` | `CBACT04C.cbl:415-461` |
| `InterestCalculator.interestTransaction` | `CBACT04C.cbl:473-517` |
| `InterestCalculator.updateAccount` | `CBACT04C.cbl:350-371` |
| `MergeSortTasklet` | `CBSORT01.cbl` |
| `CardSortTasklet` | `CBSORT02.cbl` |
| `TranReptTasklet` / `ReportWriter` | `CBTRN03C.cbl:157-375` |
| `PicEditor` (`-ZZZ,ZZZ,ZZZ.ZZ`, `+ZZZ,ZZZ,ZZZ.ZZ`) | `CVTRA07Y.cpy` |
| `ZonedDecimal` | `-fsign=EBCDIC` overpunch convention |
| `KsdsLoadTasklet` / `KsdsUnloadTasklet` | `src/ksds/LOAD-*.cbl`, `UNLD-*.cbl` |
| `AbendException` (RC 12) | `CEE3ABD.cbl` |
| `CobolDisplay.signed` (`+000000020.43`) | GnuCOBOL `DISPLAY` of `S9(9)V99` |

---

## 11. SME checklist

1. Is it intended that the **last account** in category-balance order never has its interest applied nor its cycle totals reset (D1)? Today's mainframe output has this behaviour.
2. The report's **grand total** exceeds the sum of its detail lines by the last line's amount, and the last card gets no account total (D2). Is anyone reconciling it?
3. The over-limit check adds the cycle **debit** (stored negative) to the cycle credit, i.e. it limits gross activity, not net balance. Confirm this is the business rule.
4. The over-limit check silently drops the highest digit of 10-digit cycle totals (D6). Confirm no account can reach 10-digit cycle totals in production.
5. Rejection 103 (expiry) overrides 102 (over limit) when both apply. Is that the intended reason code for reporting?
6. Interest is truncated toward zero at the cent (never rounded). Confirm against the product disclosures.
7. Categories without a DEFAULT rate abend the whole job (fixture 06). Is that the desired operational behaviour, or should they be skipped?
8. Transactions are never validated for type/category at posting time; the report would abend on an unknown type or category. Acceptable?

---

## 12. Faithful defects register

See `cobol/nightly-batch/README.md` §7 (D1-D6). The Java translation reproduces D1, D2, D6 and documents D3-D5; each carries a `// COBOL: … (faithful defect Dn, CLAUDE.md rule 5)` comment.
