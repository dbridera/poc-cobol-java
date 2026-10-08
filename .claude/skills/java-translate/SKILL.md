---
name: java-translate
description: Phase C — translate a COBOL module to Spring Boot 3 + JPA + BigDecimal. Use after the spec exists and golden-master is captured.
---

# COBOL → Java translation (Phase C)

The Java target is **Spring Boot 3.3, Java 21, Spring Data JPA, PostgreSQL**. Module zero (`java/add-motor-policy/`) is the canonical example — copy its layout for new modules.

## Project layout

```
java/<module>/
├── pom.xml                              Spring Boot parent, Java 21
├── src/main/java/com/example/poc/<module>/
│   ├── <Module>Application.java         @SpringBootApplication, exclude DataSource for module zero
│   ├── batch/
│   │   ├── BatchRunner.java             mirror MAIN-LOGIC + per-record loop
│   │   └── RecordCodec.java             fixed-width parse + encode
│   ├── domain/
│   │   ├── <X>Entity.java               JPA @Entity (one per output table / file record)
│   │   └── <X>Request.java              record DTO mirroring input layout
│   └── service/
│       ├── <X>Calculator.java           mirror CALC-* paragraphs (BigDecimal)
│       ├── <X>Validator.java            mirror VALIDATE / EVALUATE TRUE chains
│       └── <X>Exception.java            typed exceptions for ON SIZE ERROR / file status
└── src/main/resources/application.properties
```

## Hard rules (NON-NEGOTIABLE — these have all been validated empirically)

### Numerics

- **Every** COBOL numeric → `java.math.BigDecimal`. NEVER `double`/`float`/`long`/`int` for values that came from a `PIC 9...` field.
- **Rounding mode**: default COBOL `ROUNDED` is `RoundingMode.HALF_UP`. Use `HALF_EVEN` only if the COBOL explicitly says `ROUNDED MODE IS NEAREST-EVEN`.
- **`ON SIZE ERROR`** → `if (raw.compareTo(CAP) >= 0) throw new <Module>OverflowException(EXACT_COBOL_REASON);` Pre-check or catch `ArithmeticException`, but do it inside the SAME paragraph so the RC remains granular. A single top-level `catch` loses the RC mapping.

### Output formatting (when stdout / files are part of the equivalence diff)

- **Suppress Spring Boot banner + logs**. `application.properties` must contain:
  ```
  spring.main.banner-mode=off
  spring.main.log-startup-info=false
  logging.level.root=OFF
  ```
- Numeric `PIC 9(n)` → zero-pad on the left: `String.format("%0nd", value.toBigInteger())` (or use `RecordCodec.num`).
- Alphanumeric `PIC X(n)` → space-pad on the right.
- LINE SEQUENTIAL output files: trim trailing spaces from the WHOLE record before writing (matches COBOL's `WRITE` for LINE SEQUENTIAL). For records whose last field is numeric, this is a no-op.
- DISPLAY of a `PIC X(n)` group in the middle of a line preserves trailing spaces. Use `padRight` — DO NOT `stripTrailing`.
- File open mode for outputs: `TRUNCATE_EXISTING` (matches COBOL `OPEN OUTPUT`).

### Control flow

- Preserve **paragraph order** as method order. One paragraph → one method.
- Preserve **EVALUATE TRUE short-circuit**. Do NOT collect errors; return on first failure.
- Preserve **PERFORM THRU fall-through**. Do NOT collapse.
- Preserve **level-88 condition names** as `boolean` predicate methods named after the 88.
- Each method gets a traceability comment: `// COBOL: <file>.cbl:<startLine>-<endLine>`.

### Data layer

- One `@Entity` per output table / file record. Fields use the same names (camelCase) as the COBOL group items.
- Module zero may skip JPA persistence (writes go to flat files). Module 1+ must wire `@Transactional` boundaries to replace the COBOL paragraph that did `EXEC CICS ABEND` to roll back.

## Multi-step batch (JCL) modules — module 3 pattern

When `cobol/<module>/job.json` exists (see `cobol-analyze` §3.5), the Java target is **Spring Boot 3 + Spring Batch 5 + JDBC (H2 file database in the sandbox)**, canonical example `java/nightly-batch/`:

- The application takes `--manifest`, `--workdir`, `--fixture`, `--run`, `--last-run`, `--abend-after`, `--parm.STEP`, `--env.VAR` (what `tools/run-job.py --side java` passes) and exits with MAXRC. Build the `Job` from the manifest: one **Tasklet per step** (ADR-15 — never chunk-oriented for read-modify-rewrite loops), a decider per position for the injected abend, `RunLogListener` writing `out/run-log.txt` in the harness format, per-step stdout to `out/steps/nn-NAME.stdout.txt` and the RC to `nn-NAME.rc`.
- Failure semantics are the harness's (ADR-14): RC outside `rc_ok` → job failed → later non-`always` steps record `NOT RUN (JOB FAILED)`; `AbendException` → RC 12 after printing the `CEE3ABD` stub line.
- KSDS files → `KsdsTable` over `JdbcTemplate` (ADR-13): DDL generated from the copybook `Layout`, padded `VARCHAR` keys, `DECIMAL` amounts, FILLER columns; `READ`/`WRITE`/`REWRITE`/`READ NEXT`/`OPEN OUTPUT` have one SQL twin each. JPA is for online services, not for this.
- Records → `CobolRecord` over a `Layout` (field names = COBOL data names): `get` returns padded bytes, `decimal` a scaled `BigDecimal`, `set`/`setDecimal`/`add` apply COBOL store rules (scale truncation toward zero, low-order digit retention, no SIZE ERROR), `initialize()` leaves FILLER alone, `moveFrom` is a group MOVE. Keep the **working-storage records alive across the loop** exactly as the COBOL does (a failed `READ … INTO` leaves the previous record; EOF branches may use it).
- Sequential files → `FixedRecordFile` (ISO-8859-1, exact LRECL, no terminators). Signed DISPLAY fields → `ZonedDecimal` (EBCDIC overpunch). `DISPLAY` formats → `CobolDisplay` (`+000000020.43`). Edited pictures → `PicEditor` (zero prints as all spaces when every digit is `Z`).
- The clock comes from the manifest env (`COB_CURRENT_DATE`), never `now()`.
- **Paragraph trace (ADR-17).** When the manifest has `"trace": true`, call `io.entry(PROGRAM)` where the COBOL program starts (and again for a CALLed program) and `io.paragraph(PROGRAM, NAME)` at **every** paragraph entry, in the order the COBOL enters them — opens, the read that returns status 10, each PERFORMed paragraph (also the empty ones like `1400-COMPUTE-FEES`), closes, the error paragraphs `9910`/`9999`, the called `CEE3ABD`, and compiler labels GnuCOBOL traces (`L$0` after the main `PERFORM`). The trace is diffed against GnuCOBOL's: a missing or extra entry is red with the paragraph named. Look at `golden-master/<m>/<f>/out/steps/*.trace.txt` before writing the calls.
- Cite the COBOL precisely enough for the viewer: one `// COBOL: FILE.cbl:a-b` per translated paragraph, several ranges or files in one comment are fine (`CBTRN02C.cbl:221-226, 582-691`; `CBTRN02C.cbl:714-727, CBACT04C.cbl:635-648`). `./tools/render-traceability.py <m>` shows which paragraphs nothing cites.
- The viewer is built **once the translation is done** (green diff), not before: run `./tools/render-traceability.py <m>` as the last step of Phase C and make sure `cobol/<m>/PARAGRAPHS.md` explains every paragraph the viewer shows (including fallback sources such as `genapp-source/*.cbl`); `check-module.sh` warns on paragraphs without a "Qué hace" line. Before that point the page is COBOL with empty badges and confuses reviewers.
- Faithful defects are reproduced with a comment `// COBOL: <file>.cbl:<a>-<b> … (faithful defect Dn, CLAUDE.md rule 5)`; harness-infrastructure classes (manifest, job state, log writer) carry `// cobol-trace-exempt: <why>` instead of a paragraph reference.

## Verification before declaring "done"

1. `mvn -q test` is green (unit tests for calculator, validator, codec).
2. `tools/run-java.sh <module>` produces output under `java-run/`.
3. `tools/compare-outputs.py <module>` returns exit 0 with `[OK ]` for every fixture.
4. The byte-exact diff INCLUDES at least one fixture exercising every PIC numeric boundary defined in the spec.
5. Two negative controls pass: (a) deliberately switching one rounding mode (or a BigDecimal to `double`) reproduces a real diff failure at a named record/column; (b) "fixing" a documented faithful defect goes red too. Revert both.
6. `./tools/check-module.sh <module>` reports CONFORMANT.

## Common pitfalls

- Spring Boot's banner/logs leaking into stdout — set the three properties above.
- Capturing the input file as part of the run-output — script bug, not COBOL bug.
- "Smart" Java reformatting that drops trailing spaces in DISPLAY-style stdout lines — preserves the bug forever.
- BigDecimal `.toString()` for output (uses scientific notation, scale-preserving) instead of `.toBigInteger().toString()` for zero-padded fixed-width fields.
- Forgetting to truncate output files at start of run — leftover state from previous runs makes diffs spurious.
