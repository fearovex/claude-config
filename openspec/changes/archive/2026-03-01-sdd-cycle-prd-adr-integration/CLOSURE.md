# Closure: sdd-cycle-prd-adr-integration

Start date: 2026-03-01
Close date: 2026-03-01

## Summary

Integrated PRD and ADR as optional auto-generated artifacts into the SDD cycle. `sdd-propose` now generates a `prd.md` shell when a template is present and no `prd.md` exists; `sdd-design` now auto-creates an ADR when a significant architectural decision is detected in the Technical Decisions table.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| sdd-propose-prd-integration | Created | New master spec defining PRD shell auto-creation behavior, idempotency, artifact reporting, and user note requirements |
| sdd-design-adr-integration | Created | New master spec defining ADR auto-creation heuristic, slug format, Nygard format compliance, numbering, and non-blocking failure behavior |
| openspec-config-documentation | Created | New master spec defining optional_artifacts key in config.yaml and CLAUDE.md artifact storage section update requirements |

## Modified Code Files

- `skills/sdd-propose/SKILL.md` — added Step 5: PRD shell auto-creation (idempotent, skips gracefully if template absent or prd.md already exists)
- `skills/sdd-design/SKILL.md` — added Step 5: ADR auto-creation (keyword heuristic on Technical Decisions table, numbering via filesystem count, non-blocking)
- `openspec/config.yaml` — added `optional_artifacts` section documenting prd.md and docs/adr/NNN-*.md as optional per-change outputs
- `CLAUDE.md` — updated SDD Artifact Storage section to show prd.md (optional) in per-change directory tree and docs/adr/NNN-*.md (optional, produced by sdd-design)

## Key Decisions Made

- PRD creation is idempotent and non-blocking: if `prd.md` already exists or the template is absent, the step skips without failing the cycle
- ADR uses a keyword heuristic on the Technical Decisions table in `design.md` to detect architectural significance (cross-cutting concerns, patterns not in `ai-context/architecture.md`, changed conventions)
- ADR numbering is derived from the filesystem count of existing files in `docs/adr/` to ensure collision-free sequential numbers
- Both PRD and ADR creation steps are optional: missing prerequisites (template or README.md) produce a warning and a `status: ok` or `status: warning` return, never `status: blocked` or `status: failed`
- Explicit Step 5 heading added to `sdd-design` for structural symmetry with `sdd-propose` — a deliberate deviation that improved readability with no semantic impact

## Lessons Learned

- Deviation in `sdd-design` (adding an explicit Step 5 heading for structural symmetry) improved skill readability with no semantic impact — this class of deviation should be accepted without escalation
- Keyword-based heuristics for "architectural significance" are inherently fuzzy; the spec documents the heuristics explicitly so future cycles can refine or replace them with a more formal detection mechanism if needed

## User Docs Reviewed

NO — this change affects internal SDD skill behavior (sdd-propose and sdd-design). It does not add new user-facing commands, rename skills, or change the onboarding workflow. `scenarios.md`, `quick-reference.md`, and `onboarding.md` do not require updates.
