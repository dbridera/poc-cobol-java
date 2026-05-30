# cobol/cci-account-converter — Phase A (BCTITSCV)

CCI ↔ Cuenta Comercial converter for IMPACS / SAVING / CTS accounts. Adapted from a real Banco de Crédito del Perú COBOL program (Feb 2015) to demonstrate the framework on a non-GenApp banking package.

**Phase**: A — Discovery + adaptation + golden-master capture. Spec (Phase B), Java translation (Phase C), and equivalence validation (Phase D) come in follow-up sessions.

---

## 1. Provenance

### Kept verbatim
- `original/BCTITSCV.COB` — the program as received (270 lines, fixed format, Spanish comments retained). Audit trail; never edited.
- `original/BCTIYRCV.CPY` — the 200-byte `TI-YRCV-PARAMETROS` commarea copybook. Audit trail.
- `copybooks/BCTIYRCV.cpy` — runtime copy, identical bytes to original (lowercase filename for case-sensitive `-I` lookup).
- All business logic in `src/BCTITSCV-RUN.cbl`'s **inner** `BCTITSCV` program: paragraph names, `EVALUATE` chains, `COMPUTE` chains, mid-`EVALUATE` `GOBACK` in `0500-EVALUA-PROCESO`, the `1000-VALIDA-ARGUMENTOS` chain with its three short-circuit `GOBACK`s, the digit-sum check-digit algorithm in `2000`/`3000-CALCULA-DIGCHEQ-*`. Per [CLAUDE.md](../../CLAUDE.md) rule 5: don't refine the COBOL.

### Adapted (load-bearing — every change is annotated in `src/BCTITSCV-RUN.cbl`)
Four surgical edits to make the program runnable under GnuCOBOL standalone. Each cites the original line range:

| Original line | Original code | Adapted to | Reason |
|---|---|---|---|
| 69 | `01 DFHCOMMAREA PIC X(01).` (LINKAGE) | (removed) | Standalone caller binds via `USING` directly; no CICS commarea pointer needed |
| 82–85 (`0100-INICIO`) | `EXEC CICS HANDLE ABEND LABEL(3000-FINAL) END-EXEC` | (removed) | GnuCOBOL has no CICS runtime; no abend handler to register |
| 93–100 (`0120-RECIBE-COMMAREA`) | `IF EIBCALEN GREATER 0 SET ADDRESS OF TI-YRCV-PARAMETROS TO ADDRESS OF DFHCOMMAREA ELSE MOVE '99' ... 'ERROR AL RECIBIR COMMAREA' ... END-IF` | `CONTINUE.` | `EIBCALEN` is a CICS field; the "no commarea" branch is unreachable when called standalone (the caller's commarea is bound via `PROCEDURE DIVISION USING`) |
| 265–267 (`3000-FINAL`) | `EXEC CICS RETURN END-EXEC` | `GOBACK.` | Standard COBOL subroutine return |

### Added
- `src/BCTITSCV-RUN.cbl`'s **outer** `DRIVER-BCTITSCV` program — reads `requests.dat` line by line, parses 6 whitespace-separated tokens into the commarea, `CALL`s the nested `BCTITSCV`, `DISPLAY`s the result. Mirrors the nested-PROGRAM-ID pattern used in [cobol/add-policy-facade/src/ADDPFCD.cbl](../add-policy-facade/src/ADDPFCD.cbl).

### Removed (out-of-scope CICS plumbing)
- The `EIBCALEN` / `DFHCOMMAREA` pointer dance — replaced with direct `USING` binding (see Adaptation 3).
- The `EXEC CICS HANDLE ABEND` / `EXEC CICS RETURN` calls — see Adaptations 2 and 4.

The four adaptations together remove **all** CICS API surface; the remaining program is pure standard COBOL.

---

## 2. Inventory

| File | Role |
|---|---|
| `src/BCTITSCV-RUN.cbl` | Single compile unit: outer `DRIVER-BCTITSCV` + nested `BCTITSCV` (adapted) |
| `copybooks/BCTIYRCV.cpy` | 200-byte commarea (`01 TI-YRCV-PARAMETROS`) — used in both WORKING-STORAGE (driver) and LINKAGE (BCTITSCV) |
| `original/BCTITSCV.COB` | Verbatim original, do not edit |
| `original/BCTIYRCV.CPY` | Verbatim original copybook, do not edit |

No JCL. No shell drivers. No external file I/O beyond `requests.dat` (input only).

---

## 3. Data dictionary

### Commarea `TI-YRCV-PARAMETROS` (200 bytes, defined in [copybooks/BCTIYRCV.cpy](./copybooks/BCTIYRCV.cpy))

Driving fields:

| Field | PIC | Width | Meaning | Java target |
|---|---|---|---|---|
| `TI-YRCV-COD-INTFZ` | `X(04)` | 4 | Interface code (caller identifier, free-text) | `String` |
| `TI-YRCV-IND-CONV` | `X(01)` | 1 | Conversion direction: `1`=CCI→BCP, `2`=BCP→CCI. 88-levels: `TI-YRCV-88-CCI-BCP`, `TI-YRCV-88-BCP-CCI` | `String` + boolean predicates |
| `TI-YRCV-BSC-COD-FAM` | `X(03)` | 3 | Account family. 88-levels: `BSC-COD-FAM-IM` (values `004` IMPACS, `007`) and `BSC-COD-FAM-ST` (values `005` SAVING, `009` CTS) | `String` + boolean predicates |
| `TI-YRCV-BSC-COD-PRO` | `X(03)` | 3 | Product code, must be numeric (validation rule 2) | `String` (validated numeric) |
| `TI-YRCV-BSC-COD-SPR` | `X(03)` | 3 | Subproduct code (not validated) | `String` |

The 20-byte `TI-YRCV-COD-CTA-CCI` group — the **dual-purpose input**:

| Sub-field | PIC | Offset | Width | Meaning when `IND-CONV='1'` (CCI input) | Meaning when `IND-CONV='2'` (BCP input via REDEFINES) |
|---|---|---|---|---|---|
| `TI-YRCV-COD-BCO` | `X(03)` | 1–3 | 3 | CCI bank ID | FILLER (overlapped by `BCP-EDIT-IM` FILLER 1–7 / `BCP-EDIT-ST` FILLER 1–6) |
| `TI-YRCV-COD-OFI` | `X(03)` | 4–6 | 3 | CCI office | FILLER |
| `TI-YRCV-IDT-CTA` | `X(01)` | 7 | 1 | Product marker: `0`=IMPACS, `1`=SAVING, `2`=CTS (drives `0600` `EVALUATE`) | FILLER |
| `TI-YRCV-NRO-CTA` | `X(08)` | 8–15 | 8 | CCI account number | overlaps `OFI-BCP-IM`(8–10)+`NUM-BCP-IM`(11–15) for IM, or `OFI-BCP-ST`(7–9)+`NUM-BCP-ST`(10–15) for ST |
| `TI-YRCV-COD-MON` | `X(01)` | 16 | 1 | CCI currency | overlaps `NUM-BCP-IM`(end) / `NUM-BCP-ST`(end) |
| `TI-YRCV-DIG-INT1` | `X(02)` | 17–18 | 2 | First check digit pair (for `0600` direction) | overlaps `MON-BCP-*`+`DIG-BCP-*` |
| `TI-YRCV-DIG-INT2` | `X(02)` | 19–20 | 2 | Second check digit pair | overlaps `DIG-BCP-*` (end) |

Output fields (set by BCTITSCV):

| Field | PIC | Width | Set when | Meaning | Java target |
|---|---|---|---|---|---|
| `TI-YRCV-COD-RETURN` | `X(02)` | 2 | every call | RC: `00`=OK, `99`=error | `String` (codified enum) |
| `TI-YRCV-MSG-RETURN` | `X(80)` | 80 | RC≠00 | Error message text | `String` |
| `TI-YRCV-BSC-COD-FAM-RET` | `X(03)` | 3 | CCI→BCP only | Family of the decoded account | `String` |
| `TI-YRCV-BCP-EDIT-IM` / `-ST` REDEFINES | `X(20)` | 20 | every call | BCP-side commercial account view (per family) | `String` + sealed view classes |
| `TI-YRCV-CUENTA-ITE-EDIT` | `X(20)` | 20 | BCP→CCI only | Output CCI: `BCO(3)` + `OFI(3)` + `PRO(1)` + `NUM(8)` + `MON(1)` + `DIG-INT(2)` + `DIG-ITE1(1)` + `DIG-ITE2(1)` | `String` (composed from a record) |

### Working storage — numeric (in `BCTITSCV`)

These four fields drive the check-digit calculation. Per [CLAUDE.md](../../CLAUDE.md) rule 1, all map to `BigDecimal` in the Phase C translation even though they're loop indices / digit accumulators (the rule is unconditional: every COBOL `PIC 9...` or `COMP` field becomes `BigDecimal`). This forced application should produce a glossary entry in Phase E.

| Field | PIC | USAGE | Range | Role |
|---|---|---|---|---|
| `WS-TRES-NUMERO` | `9(03)` | DISPLAY | 0–999 | Running digit-sum accumulator |
| `WS-DOS-NUMERO` | `9(02)` | DISPLAY | 0–99 | Product-of-digit holder; REDEFINED as `WS-DOS-NUMERO-DEC` (tens) + `WS-DOS-NUMERO-UNI` (units) for the digit-sum split |
| `WS-UNO-NUMERO` | `9(01)` | DISPLAY | 0–9 | Computed check digit (relies on PIC truncation: `10 mod 10 = 0`) |
| `WS-I1` | `S9(03) COMP` | binary | -999..999 (used 1..12) | Loop index for `PERFORM VARYING` over digit positions |
| `WS-INICIAL` | `9(06)` | DISPLAY | 0..999999 | 6-digit OFIBAN buffer; REDEFINED as `WS-INICIAL-9 OCCURS 6` for per-digit access |
| `WS-INICIAL2` | `9(12)` | DISPLAY | 0..10¹²-1 | 12-digit NUMERO buffer; REDEFINED as `WS-INICIAL-8 OCCURS 12` |

---

## 4. External I/O

- **Input** — `requests.dat` (LINE SEQUENTIAL, ASCII). Each line is one call to BCTITSCV with 6 whitespace-separated tokens: `IND-CONV COD-INTFZ BSC-COD-FAM BSC-COD-PRO BSC-COD-SPR COD-CTA-CCI`.
- **Output** — stdout only. No files, no DB. Format: one block per call:
  ```
  RC: <2 chars>
  MSG: <trimmed, ≤80 chars>
  FAM-RET: <3 chars>
  BCP-EDIT: <20 chars>
  CUENTA-ITE: <20 chars>
  ---
  ```
- **Side effects** — none (no file writes, no SQL).

---

## 5. Control flow

Paragraph map (entry `BCTITSCV` PROCEDURE DIVISION USING `TI-YRCV-PARAMETROS`):

```
0100-INICIO
  └─ 0120-RECIBE-COMMAREA (now a no-op CONTINUE — Adaptation 3)

0500-EVALUA-PROCESO
  ├─ MOVE TI-YRCV-COD-CTA-CCI → TI-YRCV-BCP-EDIT-IM       (layer REDEFINES view)
  ├─ PERFORM 1000-VALIDA-ARGUMENTOS THRU 1000-FINVALIDA  (may GOBACK on failure)
  └─ EVALUATE TRUE
       WHEN 88-CCI-BCP  → 0600-CALCULA-CTA-COMERCIAL     (CCI → commercial account)
       WHEN 88-BCP-CCI  → 1500-CALCULA-CHEQUEO-INT  ↓
                           ├─ build OFIBAN-ITE + NUMERO-ITE
                           ├─ 2000-CALCULA-DIGCHEQ-BANOFI ↓
                           │    ├─ 2500-SUMA-NUM-IMP (varying ×1, positions 1,3,5)
                           │    └─ 2550-SUMA-NUM-PAR (varying ×2, positions 2,4,6)
                           └─ 3000-CALCULA-DIGCHEQ-CUENTA ↓
                                ├─ 3500-SUMA-NUM-IMP2 (×1, positions 1,3,5,7,9,11)
                                └─ 3550-SUMA-NUM-PAR2 (×2, positions 2,4,6,8,10,12)
       WHEN OTHER       → set RC=99 'COD. CONV.NO VALIDO' + GOBACK

3000-FINAL → GOBACK (Adaptation 4)
```

**Paragraph-name collision (preserved)**: the original has both `3000-FINAL` (program exit, originally `EXEC CICS RETURN`) and `3000-CALCULA-DIGCHEQ-CUENTA` (digit-check sub-routine). Both kept verbatim; COBOL resolves them by name.

**Short-circuit `GOBACK`s** (3 places in `1000-VALIDA-ARGUMENTOS`, 1 inside `0500` `WHEN OTHER`, plus `3000-FINAL`) all exit the entire BCTITSCV program — not just the paragraph. This means a failed validation skips `3000-FINAL` entirely; control returns straight to the driver.

---

## 6. Validation rules (`1000-VALIDA-ARGUMENTOS`)

Ordered, short-circuit. First failure wins → `RC='99'` + message + `GOBACK`. All pass → `RC='00'`, no message set.

| # | Condition (truthy = pass) | RC | Message on fail |
|---|---|---|---|
| 1 | `BSC-COD-FAM` in 88-level set `BSC-COD-FAM-IM` (`004`, `007`) OR `BSC-COD-FAM-ST` (`005`, `009`) | `99` | `COD. SIST.NO VALIDO` |
| 2 | `BSC-COD-PRO IS NUMERIC` | `99` | `ACCT.TYPE NO NUMRIC` |
| 3 (IM branch) | for IMPACS/`007`: `OFI-BCP-IM` AND `NUM-BCP-IM` AND `MON-BCP-IM` AND `DIG-BCP-IM` all `IS NUMERIC` (REDEFINES view over `BCP-EDIT-IM`, bytes 8–20 of input) | `99` | `DATOS NO NUMERICOS ` (trailing space verbatim) |
| 3 (ST branch) | for SAVING/CTS: `OFI-BCP-ST` AND `NUM-BCP-ST` AND `MON-BCP-ST` AND `DIG-BCP-ST` all `IS NUMERIC` (REDEFINES view over `BCP-EDIT-ST`, bytes 7–20 of input) | `99` | `DATOS NO NUMERICOS ` |
| (`0500` `WHEN OTHER`) | `IND-CONV` not in {`1`, `2`} | `99` | `COD. CONV.NO VALIDO` |

The last row is checked **after** `1000-VALIDA` and inside the `EVALUATE TRUE` in `0500-EVALUA-PROCESO` — not part of the `1000` chain. It only fires if validation rule 1–3 pass but the conversion direction byte is invalid.

---

## 7. Numerics

### Check-digit calculation (Luhn-like mod-10)

For both `2000-CALCULA-DIGCHEQ-BANOFI` (over the 6-digit `OFIBAN-ITE`) and `3000-CALCULA-DIGCHEQ-CUENTA` (over the 12-digit `NUMERO-ITE`), the pattern is:

```
WS-TRES-NUMERO := 0
for odd position p in [1, 3, 5, ...]:
    product := digit(p) * 1                  // implicit
    WS-TRES-NUMERO += (product/10) + (product%10)   // tens + units
for even position p in [2, 4, 6, ...]:
    product := digit(p) * 2
    WS-TRES-NUMERO += (product/10) + (product%10)
WS-DOS-NUMERO := WS-TRES-NUMERO / 10          // integer truncation; WS-DOS is PIC 9(02)
WS-UNO-NUMERO := ((WS-DOS-NUMERO * 10) + 10) - WS-TRES-NUMERO
check_digit := WS-UNO-NUMERO                  // PIC 9(01) — relies on truncation: 10 mod 10 = 0
```

This is the classic mod-10 (10 - sum%10) % 10 check digit, but realized through COBOL's:
1. `9(02)` REDEFINES split (`-DEC` / `-UNI`) to access tens + units of a product without a divmod operator.
2. `9(02) = X / 10` integer truncation (BigDecimal `divide(BigDecimal.TEN, 0, RoundingMode.DOWN)` or `setScale(0, HALF_DOWN)` — **not** `HALF_UP`).
3. `9(01)` truncation of the final result when the formula evaluates to 10 (i.e., sum is a multiple of 10).

### Phase B / C flags

- **All `COMPUTE` operands have implicit scale 0** (no `V` in any PIC). For Java: `setScale(0, RoundingMode.DOWN)` after the division. Using `HALF_UP` here will differ for inputs whose sum lands on 5 in the units place.
- **`WS-UNO-NUMERO` overflow is load-bearing**: when the formula yields 10 (sum % 10 == 0), the assignment to `PIC 9(01)` silently truncates to 0 — which is the correct check digit. Java must replicate this with `result.mod(BigDecimal.TEN)` or an explicit `if (result == 10) result = 0`.
- The `WS-TRES-NUMERO` PIC `9(03)` cap is 999. The maximum theoretical sum for the 12-digit case with all 9s is `12 × 18 = 216` — safely under 999. No overflow concern.
- `STRING '0' DELIMITED BY SIZE, TI-YRCV-NUM-BCP-IM DELIMITED BY SIZE INTO TI-YRCV-NUM-ITE` (line in `1500-CALCULA-CHEQUEO-INT` IM branch) — this concatenates a leading `'0'` with the 7-digit IMPACS account into the 8-digit `NUM-ITE` field. Java: `"0" + numBcpIm`.

### Empirically verified (this Phase A run)

For fixture `02-bcp-to-cci-saving` with input `00000021512345678112`:
- `OFIBAN-ITE` = `002215`. Hand sum: odd `(0+2+1)=3`, even `(0+4+1)=5`, total `8`. Check digit `(0×10+10)-8 = 2`. **Captured stdout:** `DIG-ITE1 = '2'` ✓
- `NUMERO-ITE` = `112345678112`. Hand sum: odd `(1+2+4+6+8+1)=22`, even `(2+6+1+5+2+4)=20`, total `42`. Check digit `(4×10+10)-42 = 8`. **Captured stdout:** `DIG-ITE2 = '8'` ✓

The algorithm is preserved by the adaptation. The full output CCI is `00221511234567811228`.

---

## 8. Fixture inventory

3 fixtures, each one call. Output captured to `golden-master/cci-account-converter/<fixture>/`.

| Fixture | `IND-CONV` | `BSC-COD-FAM` | `COD-CTA-CCI` (20 bytes) | Path exercised | Expected stdout summary |
|---|---|---|---|---|---|
| `01-cci-to-bcp-impacs` | `1` (CCI→BCP) | `004` (IMPACS) | `00221501234567811234` | `0500` → `1000-VALIDA` (all pass) → `0600-CALCULA-CTA-COMERCIAL` `WHEN '0'` | `RC=00`, `FAM-RET=004`, `BCP-EDIT=00221502152345678112` |
| `02-bcp-to-cci-saving` | `2` (BCP→CCI) | `005` (SAVING) | `00000021512345678112` | `0500` → `1000-VALIDA` (all pass, ST branch) → `1500-CALCULA-CHEQUEO-INT` → `2000` + `3000-CALCULA-DIGCHEQ-CUENTA` | `RC=00`, `CUENTA-ITE=00221511234567811228` (full CCI with mod-10 check digits `28`) |
| `03-validation-error` | `1` | `999` (invalid) | `00000000000000000000` | `0500` → `1000-VALIDA` rule 1 fails → `GOBACK` | `RC=99`, `MSG=COD. SIST.NO VALIDO`, output fields unset |

**Coverage**: every paragraph except `0600 WHEN '1'` (SAVING decode), `0600 WHEN '2'` (CTS decode), and the IM branch of `1500` (IMPACS encode) is exercised. **Recommended additions before Phase D**: a CTS-family fixture (`009`) to cover the `IF TI-YRCV-BSC-COD-FAM EQUAL '009'` branch at line 209, and an IMPACS encode fixture (`IND-CONV='2'`, family `004`) to cover the IM branch of `1500`.

---

## How to run

```bash
./tools/run-cobol.sh cci-account-converter
```

This compiles `src/BCTITSCV-RUN.cbl` to `bin/BCTITSCV-RUN` and runs each fixture. Outputs land in `golden-master/cci-account-converter/<fixture>/{stdout.txt, exit_code, stderr.txt}`.

The build emits one harmless warning: `AUTHOR is obsolete in GnuCOBOL [-Wobsolete]` — kept because it's verbatim from the original.

---

## Next phases

- **B — Spec**: invoke `cobol-spec` skill, produce `specs/cci-account-converter.md`. Pay special attention to documenting the mod-10 algorithm with explicit scale-0 / `RoundingMode.DOWN` so the Java translation can't drift.
- **C — Translation**: `java-translate` + `copybook-to-entity` (the commarea becomes a record DTO, not a JPA entity — no DB). Mirror the `add-policy-facade` Spring Boot layout. The check-digit math must use `BigDecimal` per [CLAUDE.md](../../CLAUDE.md) rule 1 even though no monetary value is involved.
- **D — Validation**: `equivalence-validator` subagent over all 3 fixtures (+ the 2 recommended additions). Negative control: change one `BigDecimal.divide` to use `HALF_UP` instead of `DOWN` for a check-digit input where it makes a difference, confirm diff fails, revert.
- **E — Crystallization**: glossary entries likely needed for (1) mod-10 check digit pattern, (2) PIC 9(N) truncation as a load-bearing semantic, (3) the "BigDecimal for non-monetary integers" forced rule application.
