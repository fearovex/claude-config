# Closure: sdd-project-context-awareness

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Added a mandatory Step 0 (Load project context) block to all six SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`). The step reads `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, and the project Skills Registry before any analysis or output generation. A reference doc `docs/sdd-context-injection.md` was created for future skill authors.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| sdd-phase-context-loading | Modified + Added | Appended mandatory context loading requirement, Skills Registry cross-reference requirement, dual-block (Step 0a/0b) requirement, and placement clarification for sdd-spec |
| skill-authoring-conventions | Created | New master spec covering the context injection documentation requirement |

## Modified Code Files

- `skills/sdd-explore/SKILL.md` — Step 0 added
- `skills/sdd-propose/SKILL.md` — Step 0a + 0b structure added
- `skills/sdd-spec/SKILL.md` — Step 0a + 0b structure added
- `skills/sdd-design/SKILL.md` — Step 0 + Skills Registry cross-reference added
- `skills/sdd-tasks/SKILL.md` — Step 0 added
- `skills/sdd-apply/SKILL.md` — Step 0a sub-step added inside existing Step 0
- `docs/sdd-context-injection.md` — New reference documentation for skill authors

## Key Decisions Made

- Context loading is **non-blocking**: absent `ai-context/` files emit INFO-level notes and execution continues. This preserves the optional-by-design nature of the memory layer.
- `sdd-propose` and `sdd-spec` use a dual-step structure (Step 0a = global context, Step 0b = domain feature preload) to avoid conflicting with the existing feature-preload step numbering.
- `sdd-apply` inserts context loading as a named sub-step (Step 0a) inside the existing Step 0 (Technology Skill Preload), before the scope guard.
- A staleness check warns when context files have a `Last updated:` date older than 7 days — signal to the user to run `/project-analyze`, non-blocking.
- `sdd-design` must cross-reference the project Skills Registry when recommending tools; unregistered global skills are marked `[optional — not registered in project]`.

## Lessons Learned

All 8 verification criteria passed on the first verify run. The dual-block approach for `sdd-propose` and `sdd-spec` cleanly solved the numbering conflict without renumbering existing steps. The canonical Step 0 template in `docs/sdd-context-injection.md` provides a reusable pattern for any future SDD phase skills.

## User Docs Reviewed

NO — this change modifies internal SDD phase skill behavior, not user-facing workflows. No updates to `scenarios.md`, `quick-reference.md`, or `onboarding.md` are required.
