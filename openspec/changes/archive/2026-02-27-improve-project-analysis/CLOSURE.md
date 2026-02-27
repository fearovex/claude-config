# Closure: improve-project-analysis

Start date: 2026-02-27
Close date: 2026-02-27

## Summary

Created a new `project-analyze` skill for deep, framework-agnostic codebase analysis that produces `analysis-report.md` and updates `ai-context/` using `[auto-updated]` section markers. Refactored `project-audit` D7 to read `analysis-report.md` instead of sampling source files directly, making architecture compliance checking framework-agnostic.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| project-analysis | Created | New master spec covering project-analyze skill, analysis-report.md format, [auto-updated] markers, and D7 delta behavior |
| audit-dimensions | Modified (in SKILL.md) | D7 rewritten to read analysis-report.md instead of sampling source files; 5-condition scoring table (absent=0, no-baseline=2, no-drift=5, minor=3, significant=0) |
| audit-execution | Modified (in SKILL.md) | Phase A extended with ANALYSIS_REPORT_EXISTS and ANALYSIS_REPORT_DATE variables; Phase A extension sub-section documented |

## Modified Code Files

- `skills/project-analyze/SKILL.md` — new skill created with 6 process steps, manifest-first stack detection (9 manifests), [auto-updated] marker strategy, 3 Bash call maximum
- `skills/project-audit/SKILL.md` — D7 rewritten, Phase A extended with analysis-report.md checks, D7 output template updated
- `CLAUDE.md` — /project-analyze added to command table, execution map, and Skills Registry
- `ai-context/architecture.md` — analysis-report.md row added to artifact table
- `openspec/config.yaml` — analysis optional key documented (max_sample_files, exclude_dirs, analysis_targets)

## Key Decisions Made

- `project-analyze` is strictly observation-only: NEVER scores, NEVER produces FIX_MANIFEST entries, NEVER creates ai-context/ if absent
- File-based artifact handoff: analysis-report.md is produced by project-analyze and consumed by project-audit D7 (mirrors audit-report.md → project-fix pattern)
- project-audit does NOT automatically invoke project-analyze — treats analysis-report.md as external input; D7 scores 0 with instruction when absent
- [auto-updated] HTML comment markers protect human-edited sections in ai-context/ files
- Staleness guard: warning-only (no score deduction) if analysis-report.md is older than 7 days
- Maximum 3 Bash calls per project-analyze execution

## Lessons Learned

- The live execution test (running /project-analyze on a real project) was deferred — a gap acknowledged in verify-report.md warnings. Recommended as the first post-archive action.
- project-audit score on claude-config was not verified before archiving (also noted as a warning). Running /project-audit after install.sh deploy is recommended.
- All 10 success criteria passed; 2 warnings remained unresolved (both non-critical, both live-execution related).

## User Docs Reviewed

N/A — pre-dates this requirement (User docs review checkbox absent from verify-report.md).
