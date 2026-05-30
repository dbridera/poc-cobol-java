# Skills guide — handoffs and extension

How the 5 skills + 1 subagent in `.claude/` fit together, what each consumes/produces, and how to add a new skill when you hit a pattern they don't cover.

This doc only covers what isn't already in the per-skill `SKILL.md` files. Each skill self-describes its rules; this doc covers the *contract between them*.

---

## 1. Phase → skill map

| Phase | Skill | Trigger to invoke |
|---|---|---|
| A — Discovery | [`cobol-analyze`](../../.claude/skills/cobol-analyze/SKILL.md) | Starting a new module, or the user names a COBOL program |
| B — Spec | [`cobol-spec`](../../.claude/skills/cobol-spec/SKILL.md) | After Phase A's `cobol/<m>/README.md` exists and `golden-master/<m>/` has been captured |
| C — Translation | [`java-translate`](../../.claude/skills/java-translate/SKILL.md) | After `specs/<m>.md` exists and SME has reviewed |
| C (data layer) | [`copybook-to-entity`](../../.claude/skills/copybook-to-entity/SKILL.md) | When starting Phase C for a module whose copybooks haven't been mapped yet |
| D — Validation | [`equivalence-validate`](../../.claude/skills/equivalence-validate/SKILL.md) | After every Phase C change; before declaring a module done |
| D (orchestration) | [`equivalence-validator`](../../.claude/agents/equivalence-validator.md) (subagent) | Proactively after any Phase C change — the subagent runs the three-step harness and reports green/red |

Phase E has no skill — it *produces* skills. See §4.

---

## 2. Handoff contracts — what each phase consumes and produces

The contracts are explicit so a future engineer (or LLM session) knows what file must exist before invoking the next skill, and what the next skill is allowed to assume.

### Phase A — `cobol-analyze`

| | |
|---|---|
| **Consumes** | `cobol/<module>/src/*.cbl`, `cobol/<module>/copybooks/*.cpy`, JCL/scripts if any, sample data |
| **Produces** | `cobol/<module>/README.md` populated with sections 1–7 of the skill; `cobol/<module>/fixtures/<name>/spec.json` per fixture |
| **Side effects** | After `tools/run-cobol.sh <module>`: `golden-master/<module>/<fixture>/{stdout.txt, exit_code, stderr.txt, out/...}` |
| **Done when** | Every paragraph is named in the README's control-flow map, every PIC is in the data dictionary, ≥3 fixtures cover happy path + validation errors + numeric boundaries, golden master captures cleanly |
| **Don't proceed if** | Any paragraph's purpose is "TBD" — get SME input first |

### Phase B — `cobol-spec`

| | |
|---|---|
| **Consumes** | Phase A outputs (`cobol/<m>/README.md`, golden master) and the COBOL source itself |
| **Produces** | `specs/<module>.md` with the 11 sections specified in the skill |
| **Done when** | SME has reviewed §2–§7; every `ROUNDED` clause has a documented mode; every `ON SIZE ERROR` has its reason string verbatim from COBOL |
| **Don't proceed if** | Spec disagrees with golden master on any byte-format detail (PIC width, padding direction, trailing-space rules) |

### Phase C — `java-translate` (+ `copybook-to-entity` as needed)

| | |
|---|---|
| **Consumes** | `specs/<m>.md`, `golden-master/<m>/`, [docs/glossary.yaml](./glossary.yaml), [CLAUDE.md](../../CLAUDE.md) hard rules |
| **Produces** | `java/<module>/` Spring Boot project with `pom.xml`, `src/main/java/com/example/poc/<module>/...`, `application.properties` with banner suppression |
| **Done when** | `mvn -B test` is green AND `tools/run-java.sh <module>` succeeds AND every method has a `// COBOL: <file>.cbl:<startLine>-<endLine>` traceability comment |
| **Don't proceed if** | Any `BigDecimal` could be `double`/`float` — reject the translation regardless of test status (see [ADR-3](./DECISIONS.md#adr-3--bigdecimal-is-mandatory-for-every-cobol-numeric)) |

`copybook-to-entity` is invoked *within* Phase C when the engineer encounters a copybook not already mapped. Its consumes/produces are local: copybook in, `domain/<X>Entity.java` or `domain/<X>Request.java` out, with `REDEFINES` mapped to a `sealed interface` (never a single nullable bag).

### Phase D — `equivalence-validate` + `equivalence-validator` subagent

| | |
|---|---|
| **Consumes** | Phase A's `golden-master/<m>/`, Phase C's Java build |
| **Produces** | `validation/reports/<module>.json` (per-fixture diff results), `java-run/<m>/<fixture>/` artifacts |
| **Done when** | All fixtures show `[OK ]`; report shows `"diffs": []` per fixture; negative-control test (deliberately break a `BigDecimal`, confirm diff fails) has run at least once |
| **Don't proceed if** | Any diff fails — fix Java/spec/harness; **never** weaken the comparator |

The `equivalence-validator` subagent is the read-only orchestrator: it runs the three commands, reads the JSON, and reports `RESULT: GREEN` / `RESULT: RED`. It cannot edit Java, COBOL, or the comparator. Use it after any Phase C edit; don't run the harness manually if you can avoid it.

### Phase E — framework capture

No skill consumes/produces. The output of Phase E is *itself* skill content:
- A new entry in [docs/glossary.yaml](./glossary.yaml) for an empirical rule discovered.
- A new section in an existing `SKILL.md` for a recurring pattern.
- A wholly new skill in `.claude/skills/<new-skill>/SKILL.md` for a recurring problem space.
- Optionally a new subagent in `.claude/agents/`.

Phase E runs *after* Phase D, never in parallel — see [METHODOLOGY.md §4](./METHODOLOGY.md#4-why-phase-e-exists).

---

## 3. The dependency graph

```
                       ┌──────────────────────────────────┐
                       │ docs/glossary.yaml (cross-cutting)│◄─── Phase E updates
                       │ CLAUDE.md (hard rules)            │
                       └──────────────────────────────────┘
                                       ▲
                                       │ consulted by every phase
                                       │
   COBOL source ──► A ──► B ──► C ──► D ──► (green) ──► E
                   │      │      │      │
                   │      │      │      └── equivalence-validator subagent
                   │      │      │          orchestrates the three-step harness
                   │      │      │
                   │      │      └── copybook-to-entity invoked per copybook
                   │      │
                   │      └── SME review surface (§2–§7 of the spec)
                   │
                   └── golden master is the contract from this point on
```

Each skill assumes its predecessor's outputs exist and are valid. There is no skip-ahead.

---

## 4. Extension recipe — adding a new skill

When to add a new skill (vs. adding a section to an existing one):
- The pattern recurs across modules and the existing skill files don't cover it.
- The pattern has its own consumes/produces contract (i.e., a phase boundary).
- An LLM session would reasonably look for a dedicated skill and not find it.

When NOT to add a new skill:
- It's a one-off observation — add to [docs/glossary.yaml](./glossary.yaml) instead.
- It's a refinement of an existing skill rule — edit that skill.
- It's a per-module note — belongs in `cobol/<module>/README.md` or `specs/<module>.md`.

### Recipe

1. Create the directory: `.claude/skills/<skill-name>/`.
2. Write `SKILL.md` with frontmatter:
   ```markdown
   ---
   name: <skill-name>
   description: <when to invoke — keep it short and trigger-oriented; this is what Claude reads to decide whether to call the skill>
   ---
   ```
3. Mirror the section structure of an adjacent skill if your skill is a phase variant. The five existing skills follow a rough shape: *purpose → required sections / hard rules → procedure → reference example*.
4. Cite evidence — link to a fixture, a glossary entry, or a line range in module zero. Skills without evidence become aspirational and decay.
5. Update [docs/glossary.yaml](./glossary.yaml) if the skill introduces new vocabulary, and cross-link from `METHODOLOGY.md` if the skill changes a phase's shape.
6. If the skill is read-only orchestration (not generation), make it a subagent instead — `.claude/agents/<name>.md` with `tools: Bash, Read, Grep` (no `Edit`/`Write`). The [equivalence-validator](../../.claude/agents/equivalence-validator.md) is the canonical example.

### Example — a hypothetical `cics-bms-to-rest` skill

A future module might be a CICS dialog program. None of the existing skills cover BMS map screens. The right move:

- New skill `cics-bms-to-rest` (Phase C variant): consumes `*.bms` + the program's `EXEC CICS SEND/RECEIVE MAP`; produces a Spring `@RestController` + a session-state model.
- New glossary section under `data_layer.bms_map`.
- New entry in this guide's §2 contracts table.
- An ADR in [DECISIONS.md](./DECISIONS.md) documenting why pseudo-conversational state maps to whichever session model was chosen.

Each step is small. The point is none of them are optional — skipping the glossary or the ADR strands the skill in isolation.

---

## 5. The subagent orchestration model

Why `equivalence-validator` is a subagent rather than a script:

- **Bounded scope.** The subagent has `tools: Bash, Read, Grep` only. It cannot edit the Java, the COBOL, or the comparator. This is an enforced boundary, not a convention.
- **Reads structured output.** The subagent reads `validation/reports/<module>.json` and reports a clean `RESULT: GREEN` / `RESULT: RED`. Useful when a parent agent or human is iterating on Phase C and wants a fast verdict without parsing diff output.
- **Fails loud, never relaxes.** [.claude/agents/equivalence-validator.md](../../.claude/agents/equivalence-validator.md) explicitly forbids speculating about causes when the failure mode is unfamiliar — quote the diff and stop.

Use it as the standard "is the diff still green?" check after any Phase C edit. Don't run the three commands manually when you can ask the subagent.

### When NOT to use it

- The diff is already known to be red and you're investigating — read the diff yourself.
- You're adding a fixture and want to see the new golden master — call `tools/run-cobol.sh` directly.
- You're modifying the harness — the subagent's contract assumes the harness is correct.

---

## See also

- Each skill's own `SKILL.md` for its hard rules and procedure.
- [METHODOLOGY.md §4](./METHODOLOGY.md#4-why-phase-e-exists) for why Phase E (and therefore this guide) exists at all.
- [DECISIONS.md ADR-8](./DECISIONS.md#adr-8--claude-code-skills--subagents-over-langchain--rag) for the decision to use Claude Code skills + subagents instead of LangChain.
