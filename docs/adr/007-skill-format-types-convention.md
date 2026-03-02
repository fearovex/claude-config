# ADR-007: Skill Format Types Convention

## Status

Proposed

## Context

The global skill catalog contains two structurally distinct categories of skills that have grown organically: procedural skills (SDD phases, meta-tools) that orchestrate step-by-step processes, and reference skills (technology and library guides) that provide patterns and examples rather than sequential procedures. The unbreakable Rule §2 in CLAUDE.md requires every SKILL.md to have a "process steps" section, but 19 of 44 skills (the reference skills) intentionally omit `## Process` because their purpose is contextual reference knowledge, not orchestration. This mismatch produces false positive audit findings and risks automated tooling incorrectly "fixing" valid reference skills by adding stub `## Process` sections.

Without a formalized type system, validation tools cannot distinguish between a procedural skill that is missing its process (a real deficiency) and a reference skill that correctly omits it (intended structure). The catalog will continue to grow inconsistently, and the audit/fix cycle will remain misaligned with actual conventions.

## Decision

We will introduce a `format:` key in SKILL.md YAML frontmatter to let each skill self-declare its structural type. Three canonical formats are defined: `procedural` (requires `## Process` or `### Step`), `reference` (requires `## Patterns` or `## Examples`), and `anti-pattern` (requires `## Anti-patterns`). All formats retain the `**Triggers**` and `## Rules` requirements. When `format:` is absent, the skill is treated as `procedural` to preserve backwards compatibility with all existing skills that do not yet declare a format. A canonical reference document (`docs/format-types.md`) is the single authoritative source for format contracts and is referenced by all tooling (project-audit, project-fix, skill-creator).

## Consequences

**Positive:**

- Eliminates false positive D4/D9 audit findings for reference skills, making the audit score reflect real structural deficiencies rather than intentional format differences
- Provides explicit guidance to skill authors and automated tooling about which sections are required for each skill type
- The backwards-compatible default (absent `format:` = procedural) means no existing skill breaks after this change is deployed
- skill-creator gains a format-selection step, preventing new skills from being created with the wrong structural skeleton

**Negative:**

- A one-time migration effort is required to add explicit `format:` declarations to the 44 existing skills (tracked as a separate downstream change)
- Three valid format types must be kept in sync across four files (CLAUDE.md Rule §2, docs/format-types.md, project-audit D4b/D9-3, project-fix Phase 5.3 stubs) — any new format type requires coordinated updates
- Skills with unrecognized `format:` values (typos, future formats) will silently fall back to `procedural` validation, which may produce confusing audit results until the value is corrected
