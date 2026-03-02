# Closure: skill-format-types

Start date: 2026-03-01
Close date: 2026-03-01

## Summary

Formalized three canonical SKILL.md format types (`procedural`, `reference`, `anti-pattern`)
via a `format:` frontmatter field. This eliminated 19 false-positive audit findings in D4/D9
for technology/reference skills that intentionally lack `## Process`.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| `skill-format-types` | Created (new master spec) | Canonical format type system: `docs/format-types.md`, `format:` frontmatter field, CLAUDE.md Rule 2 |
| `audit-dimensions` | ADDED (appended to master spec) | D4 and D9 format-aware structural validation; project-fix format-aware skeleton repair |
| `skill-creation` | Created (new master spec) | skill-creator format-selection Step 1b and branched skeleton generation |

## Modified Code Files

| File | Change |
|------|--------|
| `docs/format-types.md` | Created — canonical contract for 3 format types with required sections, skeletons |
| `CLAUDE.md` | Rule 2 updated — format-aware, references `docs/format-types.md` |
| `skills/project-audit/SKILL.md` | D4b and D9-3 updated — parse `format:` frontmatter, format-aware section check |
| `skills/project-fix/SKILL.md` | Phase 5.3 updated — format-aware stub selection at repair time |
| `skills/skill-creator/SKILL.md` | Step 1b added, Step 3 branched by format, Rules extended |
| `ai-context/architecture.md` | Skill format type system documented |
| `ai-context/conventions.md` | SKILL.md structure convention updated with format mapping table |
| `ai-context/changelog-ai.md` | Session entry added |

## Key Decisions Made

- `format:` absent defaults to `procedural` — backwards-compatible, no existing skills break
- 3 valid values: `procedural` | `reference` | `anti-pattern`
- `docs/format-types.md` is the single authoritative source — tooling must not duplicate the contract
- Migration of 44 existing skills to add `format:` declarations is a separate downstream change
- ADR 007 generated: `docs/adr/007-skill-format-types-convention.md`

## Lessons Learned

- The 44-skill catalog review exposed a systemic false-positive problem that was completely invisible
  to `/project-audit` — the audit only checked for `## Process` unconditionally.
- Two-format (A/B) distinction was initially proposed; a third (anti-pattern / Format C) was added
  during design based on `elixir-antipatterns`. The design phase correctly identified this edge case.
- The default-to-procedural rule for absent `format:` declarations is the key backwards-compatibility
  invariant — it ensures zero regression for all 25 existing procedural skills.

## User Docs Reviewed

N/A — this change modifies internal tooling (audit validation rules and skill creation). It does not
add, remove, or rename user-facing skills or change onboarding workflows.
