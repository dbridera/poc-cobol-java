# Spec: ADDMPOL — Add Motor Policy

**Source of truth:** `cobol/add-motor-policy/src/ADDMPOL.cbl`. If this spec disagrees with the COBOL, the COBOL wins. Update the spec.

**Provenance:** adapted from `cicsdev/cics-genapp` `LGAPDB01`. See `cobol/add-motor-policy/README.md` for kept/adapted/added.

## 1. Purpose

For each motor-policy add request in an input file, validate it, calculate the premium, and append two rows: one to a parent `policy` store and one to a child `motor` store. Reject invalid or arithmetically overflowing requests with a structured return code and a one-line error log entry. Print a per-record outcome and a summary line to stdout.

## 2. Inputs

### 2.1 Request file (`requests.dat`, line-sequential, fixed-width 143 chars/record)

| # | Field | COBOL PIC | Width | Java type | Notes |
|---|---|---|---|---|---|
| 1 | request_id | X(6) | 6 | String | must equal `01AMOT`, otherwise RC=99 |
| 2 | customer_num | 9(10) | 10 | `BigDecimal` (scale 0) | must be > 0, otherwise RC=10 |
| 3 | policy_num | 9(10) | 10 | `BigDecimal` (scale 0) | input value ignored — always assigned by ADDMPOL |
| 4 | issue_date | X(10) | 10 | String | non-blank required |
| 5 | expiry_date | X(10) | 10 | String | non-blank required |
| 6 | broker_id | 9(10) | 10 | `BigDecimal` (scale 0) | passed through unchanged |
| 7 | brokers_ref | X(10) | 10 | String | passed through unchanged |
| 8 | payment | 9(6) | 6 | `BigDecimal` (scale 0) | passed through unchanged |
| 9 | make | X(15) | 15 | String | passed through |
| 10 | model | X(15) | 15 | String | passed through |
| 11 | value | 9(6) | 6 | `BigDecimal` (scale 0) | must be > 0, otherwise RC=10 |
| 12 | regnumber | X(7) | 7 | String | passed through |
| 13 | colour | X(8) | 8 | String | passed through |
| 14 | cc | 9(4) | 4 | `BigDecimal` (scale 0) | must be > 0, otherwise RC=10 |
| 15 | manufactured | X(10) | 10 | String | passed through |
| 16 | accidents | 9(6) | 6 | `BigDecimal` (scale 0) | passed through |

### 2.2 Run state

- Policy number generator: starts at `1` per run, increments by 1 only when an insert succeeds. (COBOL: `WS-NEXT-POLICYNUM PIC 9(10) VALUE 1`. Real GenApp uses DB2 `IDENTITY_VAL_LOCAL()`; we use a counter so golden-master replay is deterministic.)

## 3. Per-record processing (mirror of `HANDLE-ONE-REQUEST`)

```
SET RC = 0
CHECK-REQUEST-ID         (RC := 99 if request_id != '01AMOT')
if RC == 0: VALIDATE-REQUEST    (see §4)
if RC == 0: CALC-MOTOR-PREMIUM  (see §5)
if RC == 0: INSERT-POLICY       (RC := 90 on I/O error)
if RC == 0: INSERT-MOTOR        (RC := 90 on I/O error)
if RC == 0: emit OK line, increment counter
else:       emit ERR line, write error.log entry
```

The check chain is **short-circuit** — once any step sets RC ≠ 0, downstream steps are skipped. Java translation MUST preserve this order.

## 4. Validation rules (`VALIDATE-REQUEST`, EVALUATE TRUE)

Rules are evaluated **in order**; the **first** matching rule sets RC=10 and stops.

| Order | Condition | Reason text |
|---|---|---|
| 1 | `customer_num == 0` | `customer number is zero` |
| 2 | `cc == 0` | `engine cc is zero` |
| 3 | `value == 0` | `vehicle value is zero` |
| 4 | `issue_date` is all spaces | `issue date is blank` |
| 5 | `expiry_date` is all spaces | `expiry date is blank` |

If none match, RC stays 0.

## 5. Premium calculation (`CALC-MOTOR-PREMIUM`)

All arithmetic uses `BigDecimal`. Working scale = 2.

```
base = case cc of
  cc <= 1000  -> 200.00
  cc <= 1600  -> 350.00
  cc <= 2000  -> 500.00
  otherwise   -> 800.00
value_load    = value      * 0.005
accident_load = accidents  * 50
premium_raw   = base + value_load + accident_load        # PIC 9(6)V99
premium_int   = round(premium_raw)                        # PIC 9(6)
```

### 5.1 Rounding mode

`RoundingMode.HALF_UP`. **Empirically verified** on the happy-small fixture: input record 2 (`cc=1500, value=22500, accidents=1`) yields `350 + 112.50 + 50 = 512.50 → 513`, not 512. Default COBOL `ROUNDED` (no `MODE` clause) is round-to-nearest-ties-away-from-zero, which equals `HALF_UP` for non-negative values.

### 5.2 Overflow

- `premium_raw` overflowing PIC 9(6)V99 (i.e., ≥ 1,000,000.00) → RC=11, reason `premium overflowed PIC 9(6)V99`. **Verified** on 03-numeric-boundaries record 6 (999,999 accidents × 50 = 49,999,950 — overflows the value_load+acc_load addition).
- `premium_int` overflow on rounding (≥ 1,000,000) → RC=11, reason `premium overflow on round`.

Java implementation must wrap each arithmetic step in a try/catch around `ArithmeticException` (or check `compareTo` against bounds) and translate to RC=11 with the **exact** reason string above. A single top-level catch loses granularity.

## 6. Outputs

### 6.1 stdout (per record + summary)

OK line:
```
OK  CUST=<custnum:9(10)> POL=<polnum:9(10)> PREM=<premium:9(6)>
```
Note: **two spaces after `OK`**. All numerics zero-padded to their PIC width.

ERR line:
```
ERR CUST=<custnum:9(10)> RC=<rc:9(2)> <reason text padded with spaces to 106 chars>
```
The reason is `EM-REASON PIC X(106)` — DISPLAY emits trailing spaces. Java must reproduce. (Confirmed via golden master.)

Summary line (last):
```
SUMMARY processed=<count:9(6)> inserted=<count:9(6)> rejected=<count:9(6)>
```

### 6.2 `policy.dat` (line-sequential, 67 chars/record)

| # | Field | PIC | Width |
|---|---|---|---|
| 1 | POLICYNUMBER | 9(10) | 10 |
| 2 | CUSTOMERNUMBER | 9(10) | 10 |
| 3 | POLICYTYPE | X | 1 |
| 4 | ISSUEDATE | X(10) | 10 |
| 5 | EXPIRYDATE | X(10) | 10 |
| 6 | BROKERID | 9(10) | 10 |
| 7 | BROKERSREF | X(10) | 10 |
| 8 | PAYMENT | 9(6) | 6 |

POLICYTYPE is always `M` for this module.

### 6.3 `motor.dat` (line-sequential, 87 chars/record)

| # | Field | PIC | Width |
|---|---|---|---|
| 1 | POLICYNUMBER | 9(10) | 10 |
| 2 | MAKE | X(15) | 15 |
| 3 | MODEL | X(15) | 15 |
| 4 | VALUE | 9(6) | 6 |
| 5 | REGNUMBER | X(7) | 7 |
| 6 | COLOUR | X(8) | 8 |
| 7 | CC | 9(4) | 4 |
| 8 | MANUFACTURED | X(10) | 10 |
| 9 | PREMIUM | 9(6) | 6 |
| 10 | ACCIDENTS | 9(6) | 6 |

### 6.4 `error.log` (line-sequential)

One line per rejected record:
```
<custnum:9(10)> <rc:9(2)> <reason text>
```
COBOL `LINE SEQUENTIAL` trims trailing spaces on WRITE. Java must trim to match.

### 6.5 Exit code

The COBOL program returns 0 on normal completion (even when records are rejected). It returns 90 only if the input file cannot be opened. Java should match.

## 7. Side effects

- Files `policy.dat`, `motor.dat`, `error.log` are opened with `OPEN OUTPUT` — i.e., **truncated** at start of run. Java must replicate (do not append).
- Counters (processed/inserted/rejected) are reset at run start.
- Policy number counter resets to 1 at run start.

## 8. Things this spec does NOT cover (deferred)

- DB2 transactional rollback on insert failure (the original `LGAPDB01` issues `EXEC CICS ABEND ABCODE('LGSQ')` to roll back). Our flat-file form has no rollback; a successful policy.dat write followed by a failed motor.dat write would leave an orphan policy. Acceptable for module zero; module 1 should add a Spring `@Transactional` boundary.
- Endowment / House / Commercial policy types (the original `EVALUATE CA-REQUEST-ID` had four branches; we kept only `01AMOT`).
- The `WRITE-ERROR-MESSAGE` paragraph from `LGAPDB01` (CICS-only, used `EXEC CICS ASKTIME / FORMATTIME`).

## 9. Traceability

| Java | COBOL paragraph | COBOL line range |
|---|---|---|
| `BatchRunner.run` | `MAIN-LOGIC SECTION` | (whole program) |
| `BatchRunner.processOne` | `HANDLE-ONE-REQUEST` | ~165–195 |
| `RequestValidator.validate` | `CHECK-REQUEST-ID` + `VALIDATE-REQUEST` | ~199–225 |
| `MotorPremiumCalculator.calculate` | `CALC-MOTOR-PREMIUM` | ~232–264 |
| `PolicyWriter.write` | `INSERT-POLICY` | ~268–283 |
| `MotorWriter.write` | `INSERT-MOTOR` | ~287–303 |
| `ErrorReporter.report` | `REPORT-ERROR` | ~308–315 |

Line numbers refer to `cobol/add-motor-policy/src/ADDMPOL.cbl` after the comment-divider fix.

## 10. SME review checklist

A non-COBOL banking analyst should be able to confirm, from this spec alone:

- [ ] The premium formula matches what the bank actually charges (synthetic in this PoC; replace with real rules in real modules).
- [ ] The validation rules are complete (do we need negative-customer-num check? What about future-dated issue?).
- [ ] The short-circuit ordering is intentional (does the bank want the *first* error or *all* errors?).
- [ ] The HALF_UP rounding matches the bank's accounting convention (some use HALF_EVEN — banker's rounding — for fee calculations).
- [ ] The overflow at 999,999.99 is the right ceiling (would the bank ever charge a million?).
- [ ] Orphan-policy risk on partial write is acceptable until the JPA/transactional version arrives.
