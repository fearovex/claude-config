# Closure: audit-improvements

Start date: 2026-03-01
Close date: 2026-03-01

## Summary

Enhanced `project-audit` with seven incremental checks across existing and two new dimensions: D2 placeholder detection, D3 hook script existence and conflict detection, D7 staleness score penalty, D1 template path verification, D12 ADR Coverage (new), and D13 Spec Coverage (new). All new checks are conditional and do not affect the existing 100-point scoring pool.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| audit-dimensions | Added | D2 placeholder detection requirements (4 scenarios) |
| audit-dimensions | Added | D3 hook script existence requirements (4 scenarios) |
| audit-dimensions | Added | D3 active-changes conflict detection requirements (4 scenarios) |
| audit-dimensions | Added | D7 staleness score penalty requirements (5 scenarios) |
| audit-dimensions | Added | D1 template path verification requirements (4 scenarios) |
| audit-dimensions | Added | D12 ADR Coverage dimension requirements (6 scenarios) |
| audit-dimensions | Added | D13 Spec Coverage dimension requirements (7 scenarios) |
| audit-scoring | Added | D7 staleness penalty scoring requirements (3 scenarios) |
| audit-scoring | Added | D12 informational scoring requirements (3 scenarios) |
| audit-scoring | Added | D13 informational scoring requirements (3 scenarios) |
| audit-scoring | Added | Non-regression requirement for claude-config score |
| audit-scoring | Modified | D7 now deducts points (was informational only) |

## Modified Code Files

- `skills/project-audit/SKILL.md` — sole modified skill; all 7 checks added as additive blocks; Phase A script extended with 6 new exported variables; D12 and D13 sections appended after D11; Detailed Scoring table updated with D12/D13 N/A rows
- `ai-context/changelog-ai.md` — entry added for this change (2026-03-01)
- `ai-context/architecture.md` — D12 (ADR Coverage) and D13 (Spec Coverage) rows added to artifact communication table

## Key Decisions Made

- D12 and D13 use informational scoring (N/A max points) to avoid shifting existing 100-point baselines — consistent with D9, D10, D11 pattern
- D7 staleness penalty uses two tiers (31–60 days = −1 pt; >60 days = −2 pts) with a floor of 0; stacks with drift penalty
- Phase A Bash script extended with 6 new variables (SETTINGS_JSON_EXISTS, SETTINGS_LOCAL_JSON_EXISTS, ROOT_SETTINGS_JSON_EXISTS, DOTCLAUDE_SETTINGS_JSON_EXISTS, ADR_DIR_EXISTS, ADR_README_EXISTS, OPENSPEC_SPECS_EXISTS) — keeps total Bash calls ≤ 3
- D3 conflict detection normalizes paths (lowercase + strip leading ./) before comparison
- D2 placeholder detection uses phrase list scan on the existing file read — zero additional Bash calls

## Lessons Learned

- The design had an open note about D7 penalty size ("1 or 2 points"). The implementation correctly resolved this by using two tiers per the spec rather than the single concrete value the design note suggested. In future, resolve open notes in the design phase before handoff to apply.
- Manual integration testing (live audit run on Audiio V3) was not performed during this cycle. Code inspection was used as a substitute per the project's `audit-as-integration-test` strategy. A live run is recommended before the next significant modification to project-audit.
- 44 spec compliance scenarios were evaluated in the verify phase — the highest scenario count in any cycle to date. This reflects the high complexity of the change and validates the value of structured spec writing.

## User Docs Reviewed

N/A — this change modifies the project-audit skill behavior only. It does not add, remove, or rename skills, change onboarding workflows, or introduce new user-facing commands. No updates to scenarios.md, quick-reference.md, or onboarding.md are needed.
