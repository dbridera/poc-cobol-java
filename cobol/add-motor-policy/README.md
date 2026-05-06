# Module zero: add-motor-policy

## Provenance

Adapted from [`cics-genapp`](https://github.com/cicsdev/cics-genapp) `LGAPDB01` (ADD-MOTOR-POLICY business logic).

**What was kept verbatim:**
- `copybooks/lgpolicy.cpy` — GenApp's policy/motor/house data dictionary (REDEFINES, group items, `PIC S9(...) COMP`, `PIC 9(...)`).
- The shape of the ADD-POLICY → INSERT-POLICY → INSERT-MOTOR flow.
- The return-code convention (`00` OK, `90` IO error, `99` unknown request).

**What was adapted (and why):**
- `EXEC CICS LINK / RETURN / ASKTIME / ABEND` removed — CICS is replaced by Spring Boot in the Java target, and not available under GnuCOBOL.
- `EXEC SQL INSERT INTO POLICY/MOTOR` replaced with `WRITE` to flat files (`policy.dat`, `motor.dat`). Same record layout as the DB2-POLICY / DB2-MOTOR groups.
- `EXEC SQL INCLUDE LGPOLICY` replaced with standard `COPY LGPOLICY.`.
- Input commarea (`DFHCOMMAREA`) replaced with line-sequential input file `requests.dat` whose record layout mirrors the relevant subset of `CA-MOTOR` from `lgcmarea.cpy`.
- Policy number assignment: GenApp uses DB2 `IDENTITY_VAL_LOCAL()`. We use a working-storage counter starting at 1 per run (deterministic for golden-master replay).

**What was added (and why):**
- A `CALC-MOTOR-PREMIUM` paragraph (the GenApp public sample receives premium pre-calculated; real banking COBOL would compute it). The rules are synthetic but representative:
  - Base premium by engine size (CC bracket): ≤1000→200.00, ≤1600→350.00, ≤2000→500.00, >2000→800.00
  - + 0.5 % of vehicle value
  - + 50.00 per past accident
  - Rounded half-even to whole-currency for the DB2-M-PREMIUM `PIC 9(6)` field.
- Level-88 condition names on return code and on validation outcomes (GenApp itself uses 88s sparsely; the methodology's Java mapping rule for 88s needs a real example).

## I/O

Input: `requests.dat` — line-sequential, one request per line, fixed-width 143 chars.
Output: `policy.dat` (parent), `motor.dat` (child), `error.log`, plus stdout summary.
Layouts are documented in `src/ADDMPOL.cbl` near the FILE SECTION.

## Run

```
./tools/run-cobol.sh add-motor-policy
```

Golden master lands in `golden-master/add-motor-policy/<fixture>/`.
