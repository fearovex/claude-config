# Closure: sdd-archive-orphan-validation

Start date: 2026-03-19
Close date: 2026-03-19

## Summary

Added a completeness validation step to `sdd-archive` (Step 1) that detects missing SDD artifacts before irreversible archive actions are taken. Uses a two-tier severity model: CRITICAL (blocks with no proceed option) for `proposal.md` / `tasks.md`, and WARNING (two-option acknowledgment prompt) for `design.md` / empty `specs/`. When the user acknowledges skipped phases, `CLOSURE.md` records them in a `Skipped phases:` field.

## Modified Specs

| Domain                  | Action   | Change                                                                                     |
| ----------------------- | -------- | ------------------------------------------------------------------------------------------ |
| sdd-archive-execution   | Modified | Three new requirements added: completeness validation, CLOSURE.md skipped phases, and exploration.md/prd.md exclusion; 12 new scenarios |

## Modified Code Files

- `skills/sdd-archive/SKILL.md` — Step 1 expanded with Completeness Check block (CRITICAL gate, WARNING gate, two-option prompt, skipped phases tracking); two new Rules entries added
- `openspec/specs/sdd-archive-execution/spec.md` — three new requirements and 12 scenarios appended with attribution

## Key Decisions Made

- **CRITICAL vs WARNING two-tier model**: `proposal.md` and `tasks.md` are present in 100% of valid archived cycles → hard block. `design.md` and `specs/` at ~86% → soft gate with acknowledgment option. This prevents over-engineering while surfacing incomplete cycles.
- **Completeness check placement**: runs at the top of Step 1, before `verify-report.md` read and before the irreversibility confirmation prompt — ensures the check happens regardless of verify-report state.
- **CRITICAL takes precedence**: when CRITICAL artifacts are missing, WARNING artifacts are not evaluated. Prevents confusing mixed-severity output.
- **`Skipped phases:` is conditional**: field appears in CLOSURE.md only when the user selected option 2 (acknowledgment). Happy-path archives keep the standard template unchanged.
- **`exploration.md` and `prd.md` explicitly excluded**: optional by convention; their absence must never produce output.

## Lessons Learned

The change was clean with no deviations. All 7 tasks completed in one apply cycle. The verify-report confirmed 13/13 scenarios COMPLIANT. The apply sub-agent correctly merged the delta spec into the master spec and updated the SKILL.md atomically.

## User Docs Reviewed

NO — this change modifies internal `sdd-archive` behavior only. No new commands, no renamed skills, no onboarding workflow changes. No update to scenarios.md, quick-reference.md, or onboarding.md required.
