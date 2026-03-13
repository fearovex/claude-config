# Closure: fix-format-contract

Start date: 2026-03-13
Close date: 2026-03-13

## Summary

Updated the skill format contract to accept semantically equivalent variant section heading names (`## Critical Patterns`, `## Code Examples`) from externally-sourced Gentleman-Skills, eliminating 21 false-positive D4b audit findings. Both `docs/format-types.md` and the `project-audit` D4b/D9-3 validation logic were updated to recognize standard and variant headings.

## Modified Specs

| Domain          | Action  | Change                                                                                              |
| --------------- | ------- | --------------------------------------------------------------------------------------------------- |
| format-contract | Created | New master spec documenting accepted standard and variant section headings for all three skill formats |

## Modified Code Files

- `docs/format-types.md` — Added variant heading names to reference and anti-pattern format sections and quick-reference table
- `skills/project-audit/SKILL.md` — Updated D4b and D9-3 validation tables to accept `## Critical Patterns`, `## Code Examples` as compliant headings via regex alternation

## Key Decisions Made

- Variant section headings are accepted for externally-sourced Gentleman-Skills only; new skills created via `skill-creator` continue to generate standard names
- D4b uses regex alternation (`^## (Patterns|Critical Patterns)` and `^## (Examples|Code Examples)`) to validate both standard and variant headings in a single check
- Anti-pattern format also accepts `## Critical Patterns` as a valid variant (not only reference format)
- `django-drf` non-compliance (custom domain-specific headings) is a pre-existing known issue, out of scope for this change

## Lessons Learned

- When integrating externally-sourced skill corpuses, audit validation logic must be updated in parallel with format contract documentation to prevent false positives
- The delta spec's MODIFIED section was the primary driver — the quick-reference table update was essential for documentation clarity
- Verify-report's spot-check approach (manual inspection of 4 representative skills) was sufficient evidence for a documentation-only change with no test runner

## User Docs Reviewed

N/A — pre-dates this requirement (no `## User Documentation` checkbox in verify-report)
