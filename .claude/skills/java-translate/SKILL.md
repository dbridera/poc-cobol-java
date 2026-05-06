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

## Verification before declaring "done"

1. `mvn -q test` is green (unit tests for calculator, validator, codec).
2. `tools/run-java.sh <module>` produces output under `java-run/`.
3. `tools/compare-outputs.py <module>` returns exit 0 with `[OK ]` for every fixture.
4. The byte-exact diff INCLUDES at least one fixture exercising every PIC numeric boundary defined in the spec.
5. A negative-control test passes: deliberately switching one BigDecimal calculation to `double` reproduces a real diff failure (proves the harness has teeth).

## Common pitfalls

- Spring Boot's banner/logs leaking into stdout — set the three properties above.
- Capturing the input file as part of the run-output — script bug, not COBOL bug.
- "Smart" Java reformatting that drops trailing spaces in DISPLAY-style stdout lines — preserves the bug forever.
- BigDecimal `.toString()` for output (uses scientific notation, scale-preserving) instead of `.toBigInteger().toString()` for zero-padded fixed-width fields.
- Forgetting to truncate output files at start of run — leftover state from previous runs makes diffs spurious.
