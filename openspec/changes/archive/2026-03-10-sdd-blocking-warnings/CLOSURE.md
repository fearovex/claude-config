# Closure: sdd-blocking-warnings

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Implemented a two-tier warning classification system (`MUST_RESOLVE` / `ADVISORY`) in `sdd-tasks` and `sdd-apply` to prevent unresolved ambiguities from silently passing into implementation.

## Modified Specs

| Domain                      | Action  | Change                                                               |
| --------------------------- | ------- | -------------------------------------------------------------------- |
| sdd-warning-classification  | Created | New master spec: warning classification system and blocking gate behavior |

## Modified Code Files

- `skills/sdd-tasks/SKILL.md` — Added Step 4a (classification rules) and Step 4b (tasks.md warning format)
- `skills/sdd-apply/SKILL.md` — Added Step 5a blocking gate for MUST_RESOLVE; ADVISORY log-and-continue behavior

## Key Decisions Made

- Warnings are stored inline in `tasks.md` with `[WARNING: TYPE]` markers — keeps all context in one document
- Classification happens at sdd-tasks phase (planning), not sdd-apply (execution) — exposes risks upfront
- The blocking gate has no skip option — enforces resolution before implementation
- Answers are preserved permanently in `tasks.md` with ISO 8601 timestamps — serves as a design decision log

## Lessons Learned

- No E2E test was run on the Audiio V3 test project; runtime deployment was verified by inspecting `~/.claude/skills/` directly. Future cycles should include at least one real SDD cycle with a MUST_RESOLVE scenario to validate the gate end-to-end.

## User Docs Reviewed

N/A — this change modifies internal SDD orchestration skills, not user-facing onboarding workflows, scenarios, or quick-reference docs.
