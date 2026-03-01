# Closure: close-p1-gaps-sdd-apply-verify

Start date: 2026-02-28
Close date: 2026-02-28

## Summary

Closed two P1 gaps identified in the architecture comparison against agent-teams-lite v2.0: added TDD mode support (detection + RED-GREEN-REFACTOR cycle) to `sdd-apply` and added structured build/test execution plus a formal Spec Compliance Matrix to `sdd-verify`.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| sdd-apply-execution | Created | New master spec: TDD detection (3-source cascade), RED-GREEN-REFACTOR cycle, non-breaking fallback, output field |
| sdd-verify-execution | Created | New master spec: test runner detection/execution, build/type check, coverage validation, Spec Compliance Matrix, updated verify-report template |

## Modified Code Files

- `skills/sdd-apply/SKILL.md` -- inserted Step 2 (TDD detection), added TDD sub-flow in Step 4, renumbered Steps 2-5 to 3-6, updated output JSON
- `skills/sdd-verify/SKILL.md` -- added Steps 6-9 (Run Tests, Build & Type Check, Coverage Validation, Spec Compliance Matrix), renumbered old Step 6 to Step 10, updated report template and output JSON
- `openspec/config.yaml` -- added commented-out `tdd:` and `coverage:` configuration blocks

## Key Decisions Made

- TDD detection uses a three-source cascade: (1) explicit config, (2) testing skills in CLAUDE.md, (3) test file patterns. Requires explicit config OR at least 2 heuristic signals to reduce false positives.
- RED-GREEN-REFACTOR is a sub-flow of the task-by-task implementation step, not a separate step, to avoid duplicating the loop structure.
- Test runner and build command detection use file-based prioritized lookup tables (deterministic, no binary execution for detection).
- Coverage validation is strictly optional and advisory -- never produces CRITICAL status.
- Spec Compliance Matrix is always produced even without a test runner, using code inspection evidence.
- SKIPPED/INFO dimension statuses do not affect the verdict calculation, preserving identical behavior for projects without test infrastructure.

## Lessons Learned

- Both skills are Markdown-only, so verification was done entirely through code inspection against spec scenarios. The new Spec Compliance Matrix format proved useful even for this self-referential verification.
- The change was completed within a single session with no blockers or deviations from the design.

## User Docs Reviewed

N/A -- this change modifies SDD phase skills (internal tooling), not user-facing workflows or onboarding documentation.
