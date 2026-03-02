# Technical Design: skill-format-types

Date: 2026-03-01
Proposal: openspec/changes/skill-format-types/proposal.md

## General Approach

Introduce a `format:` key in SKILL.md YAML frontmatter to let each skill self-declare its structural type. Validation logic in `project-audit` (D4b and D9-3) reads this key before evaluating which sections are required. `project-fix` (Phase 5, `add_missing_section` handler) generates format-correct stubs. `skill-creator` adds a format-selection step before generating the skeleton. A new reference document (`docs/format-types.md`) defines the canonical contracts and acts as the single authoritative source for all tooling.

No existing SKILL.md file is modified in this change — the migration of the 44 existing skills to add `format:` declarations is a separate downstream task.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Where to declare format type | YAML frontmatter `format:` field in SKILL.md | Separate sidecar file (e.g., `skill.yaml`); section-based detection heuristic | Frontmatter is already the convention for all metadata in SKILL.md files (name, description). Reading a single block is simpler than scanning the entire file body for heuristic signals, and a sidecar file adds unnecessary directory clutter. |
| Default when `format:` is absent | Treat as `procedural` | Treat as `reference`; require explicit declaration; hard-error | Backwards-compatible: all existing procedural skills without a declaration continue to pass audit unchanged. This preserves the current score for any project that has not yet migrated. |
| Format C (anti-pattern) — include or merge | Include as a distinct type (`anti-pattern`) | Merge into `reference` | Only one skill currently uses this structure (`elixir-antipatterns`). However, the anti-pattern format has a distinct required section (`## Anti-patterns`) that is semantically different from `## Patterns`/`## Examples`. Keeping it as a named type is explicit and future-proof. |
| Authoritative definition location | `docs/format-types.md` (new file in repo) | Inline in CLAUDE.md; inline in project-audit SKILL.md | A dedicated file is easier to reference from multiple skills, can be updated independently, and does not bloat the global CLAUDE.md. This is the same pattern used for the ADR system (`docs/adr/README.md`). |
| How project-audit reads format | Parse YAML frontmatter block (between first `---` pair) and extract `format:` value | Regex scan of full file | Frontmatter parsing is already a documented pattern in the codebase (D11 does this for `description:`). Re-using the same technique is consistent with the convention pattern. |
| Section requirements per format | Procedural: `## Process` or `### Step`; Reference: `## Patterns` or `## Examples`; Anti-pattern: `## Anti-patterns` | Require ALL formats to have `## Process` | The root motivation of this change: reference skills intentionally omit `## Process`. Relaxing the requirement per declared format resolves the false positives without losing validation coverage for procedural skills. |

---

## Data Flow

### Audit flow (D4b and D9-3 with format awareness)

```
project-audit reads SKILL.md
        │
        ▼
Parse YAML frontmatter (between --- markers)
        │
        ├── format: procedural  (or absent / unknown) ──► require "## Process" or "### Step"
        │
        ├── format: reference   ──► require "## Patterns" or "## Examples"
        │
        └── format: anti-pattern ──► require "## Anti-patterns"
        │
        ▼
If required section absent → record finding (missing_sections[])
        │
        ▼
FIX_MANIFEST: add_missing_section action with format-tagged stub key
```

### Fix flow (Phase 5.3 with format-aware stubs)

```
project-fix reads skill_quality_actions[add_missing_section]
        │
        ▼
Read target SKILL.md → parse frontmatter → extract format:
        │
        ├── format: procedural  (or absent) ──► stub: "## Process\n> TODO: add step-by-step process instructions."
        │
        ├── format: reference   ──► stub: "## Patterns\n> TODO: document core patterns and examples."
        │
        └── format: anti-pattern ──► stub: "## Anti-patterns\n> TODO: document anti-patterns to avoid."
        │
        ▼
Append stub with AUDIT comment marker (idempotent guard unchanged)
```

### skill-creator flow (format selection)

```
User: /skill-create <name>
        │
        ▼
Step 1 — Gather information (existing)
        │
        ▼
Step 1b (NEW) — Format selection
  "What kind of skill is this?
   1. Procedural — orchestrates a sequence of steps (SDD phases, meta-tools)
   2. Reference  — provides patterns and examples for a technology or library
   3. Anti-pattern — catalogs things to avoid (rare; use for anti-pattern-focused skills)"
        │
        ▼
Step 3 — Generate skeleton based on selected format:
  procedural   → ## Process skeleton
  reference    → ## Patterns + ## Examples skeleton
  anti-pattern → ## Anti-patterns skeleton
  (all formats include ## Rules at the end)
        │
        ▼
Frontmatter includes: format: [selected-value]
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `docs/format-types.md` | Create | New canonical reference document defining the 3 format types, their required sections, and frontmatter syntax |
| `CLAUDE.md` | Modify | Unbreakable Rule §2 — replace current single-structure requirement with format-aware reference; link to `docs/format-types.md` |
| `skills/project-audit/SKILL.md` | Modify | D4b check: add frontmatter parsing + format-aware section validation; D9-3 check: same pattern applied to local skills |
| `skills/project-fix/SKILL.md` | Modify | Phase 5.3 `add_missing_section` handler: parse format from frontmatter before selecting stub template; add `## Patterns` and `## Anti-patterns` stub templates |
| `skills/skill-creator/SKILL.md` | Modify | Step 1b (new): format-selection prompt; Step 3: branch skeleton generation by format; frontmatter of generated file includes `format:` |

No deletions. No renames. No migrations of existing SKILL.md files.

---

## Interfaces and Contracts

### SKILL.md frontmatter — new `format:` field

```yaml
---
name: react-19
description: >
  React 19 patterns with React Compiler...
format: reference       # NEW — valid values: procedural | reference | anti-pattern
---
```

Valid values:
- `procedural` — skill orchestrates a sequence of steps
- `reference` — skill provides patterns and examples
- `anti-pattern` — skill catalogs things to avoid
- _(absent)_ — treated as `procedural` (backwards-compatible default)

### Format-to-required-section mapping

| `format:` value | Required section(s) | Accepted heading variants |
|-----------------|---------------------|--------------------------|
| `procedural` (or absent) | Process section | `## Process`, `### Step N` |
| `reference` | Patterns or examples section | `## Patterns`, `## Examples` |
| `anti-pattern` | Anti-patterns section | `## Anti-patterns` |

All formats retain the `**Triggers**` requirement and the `## Rules` requirement (unchanged from current convention).

### FIX_MANIFEST `add_missing_section` — format-tagged stub keys

The `missing_sections[]` array in `skill_quality_actions` entries already exists. With this change, the values it may contain expand from:

| Before | After (additional values) |
|--------|--------------------------|
| `"## Rules"`, `"## Process"`, `"**Triggers**"` | + `"## Patterns"`, `"## Examples"`, `"## Anti-patterns"` |

No change to the FIX_MANIFEST schema — only the set of valid string values in `missing_sections[]` expands.

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual integration | Run `/project-audit` on the global-config repo itself after changes — confirm D4/D9 produce no false positives for reference skills when `format: reference` is declared | `/project-audit` |
| Manual integration | Declare `format: reference` in `react-19/SKILL.md` frontmatter (test only, revert after) and re-run audit — confirm D4b and D9-3 pass without flagging missing `## Process` | `/project-audit` |
| Manual integration | Run `/project-fix` on a project with a reference skill that has no `## Patterns` section — confirm stub generated is `## Patterns` not `## Process` | `/project-fix` |
| Manual | Create a new skill with `/skill-create` — confirm format-selection prompt appears and generated file has correct `format:` in frontmatter | `/skill-create` |

No automated test framework is applicable (this is a Markdown + YAML skill system). Verification is handled by the SDD `verify` phase with a `verify-report.md`.

---

## Migration Plan

No data migration required.

The `format:` field is optional in this change. Existing SKILL.md files without a `format:` declaration continue to be validated as `procedural` (the backwards-compatible default). The migration of all 44 existing skills to add explicit `format:` declarations is tracked as a separate downstream change and does not block this change.

---

## Open Questions

- **Should `format: unknown` be a valid escape hatch?** A skill author might be uncertain which format applies. Decision deferred to implementation: if the value is unrecognized (not one of the three valid values), treat it as `procedural` (same as absent) and emit an INFO-level audit finding. This avoids hard failures during migration.

- **Should D4b score deductions change with format awareness?** Currently D4b is part of the 10-point registry+content score. A reference skill missing `## Patterns` is a structural deficiency just as a procedural skill missing `## Process` is. The severity and scoring weight remain unchanged — only the section name being checked changes. This is confirmed by the proposal's success criteria (no score impact on compliant skills).
