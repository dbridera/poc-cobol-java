---
name: copybook-to-entity
description: Convert a COBOL copybook to JPA @Entity / record DTO classes. Use when starting Phase C for a module whose copybooks haven't been mapped yet.
---

# Copybook → Java entities

A copybook is a record-layout description. Two outputs are typical:

1. **JPA `@Entity`** — when the copybook represents a DB2 table or VSAM file (persistence layer).
2. **`record` DTO** — when the copybook is a transfer/buffer layout (e.g., a CICS commarea, a request/response record).

Pick by USE, not by file: the same copybook can produce both if it's used both ways in different programs.

## Group → Java mapping

| COBOL | Java |
|---|---|
| `01 X.` (top-level group) | class boundary (Entity or record) |
| `03 FIELD PIC X(n)` | `String FIELD` (length-validated) |
| `03 FIELD PIC 9(n)` | `BigDecimal FIELD` (scale 0) |
| `03 FIELD PIC S9(n) COMP / COMP-3` | `BigDecimal FIELD` (scale 0; can be negative) |
| `03 FIELD PIC 9(m)V9(n)` | `BigDecimal FIELD` (scale = n) |
| `03 SUBGROUP. 05 ...` | nested record / `@Embedded` value type |
| `OCCURS n TIMES` | `List<T>` of size n (or `T[n]` if random access) |
| `OCCURS n DEPENDING ON FIELD` | `List<T>`, validate size against `FIELD` at construction |
| `REDEFINES` | sealed interface OR two view classes — see below |
| `88 NAME VALUE 'Y'` | `boolean isName()` predicate method |

## REDEFINES — the trap

A `REDEFINES` is *two interpretations of the same bytes*. NEVER collapse them into one Java type.

Two safe patterns:

### Pattern A — sealed interface for tagged unions

When the redefining group is selected by a discriminator:

```java
public sealed interface PolicySpecific
        permits Endowment, House, Motor, Commercial, Claim {}

public record Motor(String make, String model, BigDecimal value, ...)
        implements PolicySpecific {}
```

Plus a `PolicyRequest` record carrying `requestId` (the discriminator) and `PolicySpecific specific`.

### Pattern B — two view records over a byte buffer

When both interpretations may be in use without a single discriminator (rare, but happens with file-format unions):

```java
public record CustomerView(byte[] bytes) { ... parsing accessors ... }
public record SecurityView(byte[] bytes) { ... parsing accessors ... }
```

Plus an explicit converter that asserts the discriminator.

**Never** create a single class with all union fields nullable. That loses the structural guarantee and lets stale fields leak through.

## OCCURS DEPENDING ON

Validate the actual length against the depending field at construction:

```java
public record Quotes(int count, List<Quote> entries) {
    public Quotes {
        if (entries.size() != count) {
            throw new IllegalArgumentException("entries.size != count");
        }
    }
}
```

## Naming

- Class name = copybook name in PascalCase, drop redundant prefixes: `lgpolicy.cpy` → `Policy*` classes (not `LgPolicy*`).
- Field name = COBOL data name in camelCase, dropping trailing `-` segments (e.g., `DB2-M-VALUE` → `value`, scoped within a `Motor` class so the prefix is unnecessary).
- Java packages follow `docs/methodology/glossary.yaml` `naming.java_packages`.

## Persistence vs DTO decision

- If the copybook fields appear as `EXEC SQL INSERT/SELECT` columns → JPA `@Entity`.
- If the copybook is a CICS commarea / file record / parameter buffer → `record` DTO.
- If both, generate two classes and a converter.

## Reference example

`java/add-motor-policy/src/main/java/com/example/poc/addmotorpolicy/domain/PolicyEntity.java` and `MotorEntity.java` are the JPA pattern. `MotorPolicyRequest.java` is the DTO pattern.
