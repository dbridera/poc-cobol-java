# Spec: BCTITSCV — CCI ↔ Cuenta Comercial Converter

**Source of truth:** `cobol/cci-account-converter/src/BCTITSCV-RUN.cbl` (inner `BCTITSCV` program). If this spec disagrees with the COBOL, the COBOL wins. Update the spec.

**Provenance:** adapted from `cobol/cci-account-converter/original/BCTITSCV.COB` (Banco de Crédito del Perú, Feb 2015). Four surgical CICS removals to run standalone — see [cobol/cci-account-converter/README.md §1 "Provenance"](../cobol/cci-account-converter/README.md). No business-logic changes.

## 1. Purpose

Bidirectional converter between the Peruvian **CCI** (Código de Cuenta Interbancario, 20-byte interbank code) and the bank's internal **commercial-account** format. Used by the online interbank-transfer system to (a) decode a received CCI into an IMPACS / SAVING / CTS account the core systems can post to, or (b) build a CCI to send to another bank, including the two **mod-10 check digits** that the CCI standard requires. One call processes one account; one request line = one call.

## 2. Inputs

### 2.1 Request file (`requests.dat`, line-sequential, whitespace-separated)

Each line is one call to BCTITSCV. The driver parses 6 tokens (`UNSTRING DELIMITED BY ALL SPACES`) and loads them into the 200-byte `TI-YRCV-PARAMETROS` commarea (defined in `copybooks/BCTIYRCV.cpy`).

| # | Token | COBOL field | PIC | Width | Java type | Notes |
|---|---|---|---|---|---|---|
| 1 | `IND-CONV` | `TI-YRCV-IND-CONV` | `X(01)` | 1 | `String` | `1` = CCI→BCP, `2` = BCP→CCI. Any other value → RC=99 `COD. CONV.NO VALIDO` |
| 2 | `COD-INTFZ` | `TI-YRCV-COD-INTFZ` | `X(04)` | 4 | `String` | Interface code (caller identifier, not validated) |
| 3 | `BSC-COD-FAM` | `TI-YRCV-BSC-COD-FAM` | `X(03)` | 3 | `String` | Account family. Must be `004`/`007` (IMPACS) or `005`/`009` (SAVING/CTS). Anything else → RC=99 |
| 4 | `BSC-COD-PRO` | `TI-YRCV-BSC-COD-PRO` | `X(03)` | 3 | `String` (validated numeric) | Product code, must satisfy `IS NUMERIC` |
| 5 | `BSC-COD-SPR` | `TI-YRCV-BSC-COD-SPR` | `X(03)` | 3 | `String` | Subproduct code (not validated, pass-through) |
| 6 | `COD-CTA-CCI` | `TI-YRCV-COD-CTA-CCI` | `X(20)` | 20 | `String` | The 20-byte account string. **Dual-purpose**: CCI when `IND-CONV='1'`, commercial-account layout when `IND-CONV='2'`. See §2.2 for the byte layout |

### 2.2 The dual-purpose 20-byte input `COD-CTA-CCI`

The same 20 bytes are accessed via two layered REDEFINES groups (`TI-YRCV-BCP-EDIT-IM` / `TI-YRCV-BCP-EDIT-ST`):

**Direct (CCI) view — used when `IND-CONV='1'`:**

| Bytes | Sub-field | PIC | Meaning |
|---|---|---|---|
| 1–3 | `TI-YRCV-COD-BCO` | `X(03)` | CCI bank ID |
| 4–6 | `TI-YRCV-COD-OFI` | `X(03)` | CCI office |
| 7 | `TI-YRCV-IDT-CTA` | `X(01)` | Product marker: `0`=IMPACS, `1`=SAVING, `2`=CTS (drives `0600-CALCULA-CTA-COMERCIAL` `EVALUATE`) |
| 8–15 | `TI-YRCV-NRO-CTA` | `X(08)` | CCI account number |
| 16 | `TI-YRCV-COD-MON` | `X(01)` | CCI currency |
| 17–18 | `TI-YRCV-DIG-INT1` | `X(02)` | First check digit pair |
| 19–20 | `TI-YRCV-DIG-INT2` | `X(02)` | Second check digit pair |

**IMPACS (BCP-EDIT-IM) REDEFINES view — used during `1500` validation and read for `IND-CONV='2'` with family `004`/`007`:**

| Bytes | Sub-field | PIC | Meaning |
|---|---|---|---|
| 1–7 | (FILLER) | `X(07)` | ignored |
| 8–10 | `TI-YRCV-OFI-BCP-IM` | `X(03)` | IMPACS office |
| 11–17 | `TI-YRCV-NUM-BCP-IM` | `X(07)` | IMPACS account number (7 digits) |
| 18 | `TI-YRCV-MON-BCP-IM` | `X(01)` | currency |
| 19–20 | `TI-YRCV-DIG-BCP-IM` | `X(02)` | BCP-side check digits |

**SAVING/CTS (BCP-EDIT-ST) REDEFINES view — used during `1500` validation and read for `IND-CONV='2'` with family `005`/`009`:**

| Bytes | Sub-field | PIC | Meaning |
|---|---|---|---|
| 1–6 | (FILLER) | `X(06)` | ignored |
| 7–9 | `TI-YRCV-OFI-BCP-ST` | `X(03)` | SAVING/CTS office |
| 10–17 | `TI-YRCV-NUM-BCP-ST` | `X(08)` | SAVING/CTS account number (8 digits) |
| 18 | `TI-YRCV-MON-BCP-ST` | `X(01)` | currency |
| 19–20 | `TI-YRCV-DIG-BCP-ST` | `X(02)` | BCP-side check digits |

**Translation rule**: in Java, model `COD-CTA-CCI` as a single `String` field plus a `sealed interface` with two view classes (`ImpacsView`, `SavingView`) that each expose typed accessors over the same 20-byte string. Never a single nullable bag. (CLAUDE.md mapping cheatsheet for `REDEFINES`.)

## 3. Per-record processing (mirror of the `PROCEDURE DIVISION USING TI-YRCV-PARAMETROS` body)

```
PERFORM 0100-INICIO            # was CICS HANDLE ABEND; now a no-op CONTINUE
PERFORM 0500-EVALUA-PROCESO    # main dispatch
PERFORM 3000-FINAL             # was CICS RETURN; now GOBACK
```

`0500-EVALUA-PROCESO`:

```
MOVE COD-CTA-CCI TO BCP-EDIT-IM             # lay the 20 bytes over the REDEFINES view
PERFORM 1000-VALIDA-ARGUMENTOS THRU 1000-FINVALIDA   # may GOBACK on failure (§4)
EVALUATE TRUE
    WHEN IND-CONV = '1'  -> PERFORM 0600-CALCULA-CTA-COMERCIAL     # CCI → BCP
    WHEN IND-CONV = '2'  -> PERFORM 1500-CALCULA-CHEQUEO-INT       # BCP → CCI (§5)
    WHEN OTHER           -> RC=99 'COD. CONV.NO VALIDO' + GOBACK
END-EVALUATE
```

The validate / dispatch chain is **short-circuit**. A failing `1000-VALIDA` rule `GOBACK`s the entire program — control does NOT reach 3000-FINAL.

## 4. Validation rules (`1000-VALIDA-ARGUMENTOS`)

Evaluated **in order**; the **first** matching rule sets RC=`99`, writes the reason to `TI-YRCV-MSG-RETURN`, and `GOBACK`s. All pass → RC=`00`, no message written.

| Order | Condition (truthy = pass) | RC | `TI-YRCV-MSG-RETURN` text (verbatim) |
|---|---|---|---|
| 1 | `BSC-COD-FAM` ∈ {`004`, `007`} (88-level `BSC-COD-FAM-IM`) ∪ {`005`, `009`} (88-level `BSC-COD-FAM-ST`) | `99` | `COD. SIST.NO VALIDO` |
| 2 | `BSC-COD-PRO IS NUMERIC` | `99` | `ACCT.TYPE NO NUMRIC` |
| 3a (when FAM ∈ IM) | `OFI-BCP-IM` AND `NUM-BCP-IM` AND `MON-BCP-IM` AND `DIG-BCP-IM` all `IS NUMERIC` | `99` | `DATOS NO NUMERICOS ` *(trailing space verbatim)* |
| 3b (when FAM ∈ ST) | `OFI-BCP-ST` AND `NUM-BCP-ST` AND `MON-BCP-ST` AND `DIG-BCP-ST` all `IS NUMERIC` | `99` | `DATOS NO NUMERICOS ` |

After `1000-VALIDA` passes (and only then), `0500-EVALUA-PROCESO`'s `EVALUATE TRUE` is evaluated. If `IND-CONV` is neither `1` nor `2`, the `WHEN OTHER` branch fires:

| Order | Condition | RC | Text |
|---|---|---|---|
| 4 | `IND-CONV` ∈ {`1`, `2`} | `99` | `COD. CONV.NO VALIDO` |

Rule 3a is `IS NUMERIC` on the REDEFINES view over `BCP-EDIT-IM` (bytes 8–20 of the input). Rule 3b is `IS NUMERIC` on `BCP-EDIT-ST` (bytes 7–20). For `IND-CONV='1'` (CCI→BCP), the rule effectively requires that the matching bytes of the CCI input are also valid digits. **Note:** the validation is the same for both conversion directions; only the family selects which REDEFINES view is checked.

## 5. CCI construction (`1500-CALCULA-CHEQUEO-INT`)

Run only when `IND-CONV='2'` (BCP → CCI). Two sub-steps: build the `CUENTA-ITE-EDIT` body (3 + 3 + 12 = 18 of the 20 bytes), then compute the two check digits.

### 5.1 Body construction

```
TI-YRCV-BCO-ITE := '002'                           # hard-coded bank ID (BCP)
if FAM ∈ {'004','007'} (IMPACS):
    TI-YRCV-PRO-ITE := '0'
    TI-YRCV-OFI-ITE := OFI-BCP-IM                  # 3-byte office
    TI-YRCV-NUM-ITE := '0' || NUM-BCP-IM            # leading '0' + 7-byte IMPACS account = 8 bytes
    TI-YRCV-MON-ITE := MON-BCP-IM                   # currency
    TI-YRCV-DIG-INT := DIG-BCP-IM                   # 2-byte BCP-side check
else (FAM ∈ {'005','009'}):
    TI-YRCV-PRO-ITE := '1'                          # SAVING default
    if FAM = '009':  TI-YRCV-PRO-ITE := '2'          # CTS override
    TI-YRCV-OFI-ITE := OFI-BCP-ST
    TI-YRCV-NUM-ITE := NUM-BCP-ST                   # already 8 bytes
    TI-YRCV-MON-ITE := MON-BCP-ST
    TI-YRCV-DIG-INT := DIG-BCP-ST
```

The result so far is 18 bytes laid out as:

| Bytes | Sub-field | Width |
|---|---|---|
| 1–3 | `TI-YRCV-BCO-ITE` | 3 (always `002`) |
| 4–6 | `TI-YRCV-OFI-ITE` | 3 |
| 7 | `TI-YRCV-PRO-ITE` | 1 |
| 8–15 | `TI-YRCV-NUM-ITE` | 8 |
| 16 | `TI-YRCV-MON-ITE` | 1 |
| 17–18 | `TI-YRCV-DIG-INT` | 2 |

### 5.2 Check-digit calculation (`2000-CALCULA-DIGCHEQ-BANOFI` and `3000-CALCULA-DIGCHEQ-CUENTA`)

Two independent mod-10 calculations:

- **`DIG-ITE1`** (byte 19) is computed over `OFIBAN-ITE` = `BCO-ITE` ‖ `OFI-ITE` (6 digits).
- **`DIG-ITE2`** (byte 20) is computed over `NUMERO-ITE` = `PRO-ITE` ‖ `NUM-ITE` ‖ `MON-ITE` ‖ `DIG-INT` (12 digits).

Both use the same algorithm. Let `d[i]` be the i-th decimal digit (1-indexed). Let `digitSum(x)` = `(x / 10) + (x mod 10)` — the sum of the tens and units of a 2-digit number.

```
sum := 0
for i in odd positions [1, 3, 5, ... , N-1]:
    sum += digitSum( d[i] * 1 )
for i in even positions [2, 4, 6, ... , N]:
    sum += digitSum( d[i] * 2 )

check := ((sum / 10) * 10 + 10) - sum
       = 10 - (sum mod 10)            # mathematically equivalent
       = (10 - (sum mod 10)) mod 10   # i.e., 0 if sum is a multiple of 10
```

**N = 6** for `DIG-ITE1`, **N = 12** for `DIG-ITE2`. The result is one digit `0..9`.

### 5.3 Numeric types, scales, rounding mode

| COBOL field | PIC | Java type | Notes |
|---|---|---|---|
| `WS-TRES-NUMERO` | `9(03)` | `BigDecimal` scale 0 | Accumulator, max 999, observed max in fixtures `42` |
| `WS-DOS-NUMERO` | `9(02)` | `BigDecimal` scale 0 | Product holder, max 99 |
| `WS-DOS-NUMERO-DEC` / `-UNI` | `9(01)` each | `BigDecimal` scale 0 | REDEFINES split of `WS-DOS-NUMERO` — tens and units extraction |
| `WS-UNO-NUMERO` | `9(01)` | `BigDecimal` scale 0 | Computed check digit, **relies on `9(01)` truncation** for `sum % 10 == 0` |
| `WS-I1` | `S9(03) COMP` | `BigDecimal` scale 0 | Loop index (1..12) |
| `WS-INICIAL` / `WS-INICIAL2` | `9(06)` / `9(12)` | `BigDecimal` scale 0 | Digit buffers, REDEFINES into single-digit arrays |

**All arithmetic is scale 0.** The two scale-bearing operations:

1. **`WS-DOS-NUMERO := WS-TRES-NUMERO / 10`** — integer truncation. The result is stored into a `PIC 9(02)` field which discards any fractional part. Java: `dividend.divide(TEN, 0, RoundingMode.DOWN)`. **`HALF_UP` here will give wrong check digits when the units digit of `sum` is ≥ 5.**

2. **`WS-UNO-NUMERO := ((WS-DOS-NUMERO * 10) + 10) - WS-TRES-NUMERO`** — pure subtraction, no rounding. But the result is stored into `PIC 9(01)`, so when the value is exactly `10` (i.e., `sum mod 10 == 0`), the high digit is truncated leaving `0`. **This truncation is load-bearing**: it's the mathematical equivalent of `(10 - sum%10) % 10`. Java must reproduce: `result.remainder(TEN)` or `if (result.intValue() == 10) result = ZERO`.

There is **no `ON SIZE ERROR`** anywhere. The PIC truncation of `WS-UNO-NUMERO = 10 → 0` is the design, not an overflow condition. The maximum `WS-TRES-NUMERO` for the 12-digit case is `12 × 18 = 216`, safely under the `9(03) = 999` cap.

### 5.4 Empirically verified

For fixture `02-bcp-to-cci-saving` with input `00000021512345678112` (FAM=`005`):
- After §5.1: `OFIBAN-ITE` = `'002215'`, `NUMERO-ITE` = `'112345678112'`.
- **`DIG-ITE1`** hand-sum: odd positions `(0×1) + (2×1) + (1×1) = 3`, even positions `(0×2)=0 + (2×2)=4 + (5×2)=10→1+0=1` ⇒ total `8`. `check = (0×10+10) - 8 = 2`. Captured stdout: `DIG-ITE1='2'` ✓
- **`DIG-ITE2`** hand-sum: odd positions `1+2+4+6+8+1 = 22`, even positions (with digitSum of doubles) `(1·2=2)+(3·2=6)+(5·2=10→1)+(7·2=14→5)+(1·2=2)+(2·2=4) = 20`. Total `42`. `check = (4×10+10) - 42 = 8`. Captured: `DIG-ITE2='8'` ✓.
- Output CCI: `00221511234567811228`. Captured: matches ✓.

## 6. CCI decoding (`0600-CALCULA-CTA-COMERCIAL`)

Run only when `IND-CONV='1'` (CCI → BCP). Branches on the CCI's `IDT-CTA` byte (position 7 of the input):

| `IDT-CTA` | Family written to `FAM-RET` | Target REDEFINES view | Mapping |
|---|---|---|---|
| `0` | `004` (IMPACS) | `BCP-EDIT-IM` | `OFI-BCP-IM := COD-OFI`, `NUM-BCP-IM := NRO-CTA(2:7)`, `MON-BCP-IM := COD-MON`, `DIG-BCP-IM := DIG-INT1` |
| `1` | `005` (SAVING) | `BCP-EDIT-ST` | `OFI-BCP-ST := COD-OFI`, `NUM-BCP-ST := NRO-CTA` (all 8), `MON-BCP-ST := COD-MON`, `DIG-BCP-ST := DIG-INT1` |
| `2` | `009` (CTS) | `BCP-EDIT-ST` | identical to SAVING |
| other | (no `WHEN` matches) | — | `EVALUATE` falls through silently; output fields unchanged |

Note `NRO-CTA(2:7)` for IMPACS — COBOL reference modifier, positions 2..8 of the 8-byte NRO-CTA (7 bytes, dropping the first byte). For SAVING/CTS, the full 8 bytes are used.

`FAM-RET` is the ONLY field of the output set by 0600 — `BCP-EDIT-IM` is updated in place via the REDEFINES, but the visible output (`CUENTA-ITE-EDIT`) is **not touched**. For CCI→BCP, the BCP-side commercial account ends up in `BCP-EDIT-IM`/`BCP-EDIT-ST` (overlaid bytes 1–7 / 1–6 still hold the leading bytes of the original CCI).

## 7. Outputs

Driver-emitted stdout, one block per call, terminator line `---`:

```
RC: <2-byte COD-RETURN>
MSG: <trimmed MSG-RETURN, no trailing spaces, may be empty>
FAM-RET: <3-byte BSC-COD-FAM-RET>
BCP-EDIT: <20-byte BCP-EDIT-IM>
CUENTA-ITE: <20-byte CUENTA-ITE-EDIT>
---
```

Width contract:
- `RC` is exactly 2 characters (always set: `00`, `99`).
- `MSG` is `FUNCTION TRIM` of the 80-byte field — empty for happy paths.
- `FAM-RET`, `BCP-EDIT`, `CUENTA-ITE` are emitted **at full PIC width** with COBOL `DISPLAY`'s natural space-padding. **Trailing spaces matter** — the diff harness compares byte-for-byte.

No file output. No DB writes. No `error.log`.

### 7.1 Exit code

`STOP RUN RETURNING 0` always (the driver). The inner BCTITSCV uses `GOBACK` (returns control to the driver), so a "validation error" does not change the process exit code. The driver only returns 1 if the `requests.dat` file cannot be opened.

## 8. Side effects

- None. `requests.dat` is the only file touched (read-only). No DB. No locks. No counters survive between calls — the driver re-initializes the commarea before each call (`MOVE SPACES TO TI-YRCV-PARAMETROS`).
- The original CICS program registers an abend handler (`EXEC CICS HANDLE ABEND LABEL(3000-FINAL)`) — removed in adaptation 2. No equivalent needed standalone.

## 9. Things this spec does NOT cover (deferred / out of scope)

- **CICS transactional context.** The original ran inside a CICS task with an attached commarea. We replaced this with direct `USING` binding (adaptation 3); the `EIBCALEN` length check is unreachable standalone and now a no-op `CONTINUE` (`0120-RECIBE-COMMAREA`).
- **The `'ERROR AL RECIBIR COMMAREA'` error path** — only reachable in CICS when EIBCALEN=0; standalone caller always binds correctly. No fixture covers it. Java translation can omit the unreachable branch but should comment-cite the original.
- **Families other than `004`/`005`/`007`/`009`.** The COBOL silently falls through `EVALUATE TI-YRCV-IDT-CTA` for IDT-CTA values other than `0`/`1`/`2`. Spec preserves the silent fall-through; Java must replicate (output fields left at whatever 0500's line-106 MOVE put there).
- **Encoding of accented Spanish characters** in `MSG-RETURN` (e.g., the comment says "C�DIGO INTERBANCARIO"). Output messages are ASCII-only ("COD. SIST.NO VALIDO" etc.) so no encoding work needed at the Java boundary.
- **CTS-family fixture and IMPACS-encode fixture** — flagged in [cobol/cci-account-converter/README.md §8](../cobol/cci-account-converter/README.md). Phase D should add these before declaring full coverage.

## 10. Traceability

| Java | COBOL paragraph | COBOL line range (in `src/BCTITSCV-RUN.cbl`) |
|---|---|---|
| `BatchRunner.run` | driver `MAIN-DRIVER` + `READ-INPUT` loop | 31–47 |
| `BatchRunner.callBctitscv` | driver `CALL-BCTITSCV` | 50–63 |
| `BatchRunner.displayResult` | driver `DISPLAY-RESULT` | 66–73 |
| `BctitscvService.run` | inner `PROCEDURE DIVISION` body | 138–142 |
| `BctitscvService.iniciar` | `0100-INICIO` + `0120-RECIBE-COMMAREA` | 144–155 |
| `BctitscvService.evaluaProceso` | `0500-EVALUA-PROCESO` | 157–171 |
| `CciDecoder.decode` | `0600-CALCULA-CTA-COMERCIAL` | 173–196 |
| `BctitscvValidator.validate` | `1000-VALIDA-ARGUMENTOS` THRU `1000-FINVALIDA` | 198–245 |
| `CciEncoder.encode` | `1500-CALCULA-CHEQUEO-INT` THRU `1500-FININT` | 247–270 |
| `CheckDigitCalculator.calcOfiban` | `2000-CALCULA-DIGCHEQ-BANOFI` + `2500` + `2550` | 272–283, 292–298 |
| `CheckDigitCalculator.calcCuenta` | `3000-CALCULA-DIGCHEQ-CUENTA` + `3500` + `3550` | 285–292, 299–306 |
| `BctitscvService.final` | `3000-FINAL` | 308–312 |

## 11. SME review checklist

A non-COBOL banking analyst should be able to confirm, from this spec alone:

- [ ] The four `BSC-COD-FAM` codes (`004` IMPACS, `005` SAVING, `007`, `009` CTS) are the complete set the production system accepts. (Should `007` and `009` get the same special-case treatment as `004`/`005` and `2`-CTS in `1500`?)
- [ ] The hard-coded bank ID `002` in `1500` is intended (BCP). Other banks calling this program would need a different value.
- [ ] The mod-10 check-digit algorithm in §5.2 matches the one published by the Peruvian SBS / interbank clearing system.
- [ ] The leading `'0'` prepended to `NUM-BCP-IM` in `1500` IMPACS branch (`'0' || 7-byte → 8-byte NUM-ITE`) is the correct way to pad a 7-digit IMPACS account into the 8-digit CCI slot.
- [ ] The `WHEN OTHER` for `IDT-CTA` in `0600` (silent fall-through, no RC set) is intentional — a CCI with `IDT-CTA='3'` or higher returns `RC=00` with empty output fields rather than a validation error.
- [ ] The `BCP-EDIT-IM` output for the CCI→BCP direction (bytes 1–7 unchanged from the input CCI, bytes 8–20 overwritten) is what the calling system expects.
- [ ] `0600` does not set `CUENTA-ITE-EDIT` (it only updates `BCP-EDIT-IM`). The downstream consumer of a CCI→BCP call should read `BCP-EDIT-IM` and ignore `CUENTA-ITE-EDIT`.
