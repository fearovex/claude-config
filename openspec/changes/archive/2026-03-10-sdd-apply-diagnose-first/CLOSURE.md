# Closure: sdd-apply-diagnose-first

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Added a mandatory Diagnosis Step to `sdd-apply/SKILL.md` that requires sub-agents to read current files, run read-only diagnostic commands, and write a structured `DIAGNOSIS` block (with hypothesis) before making any file changes. When diagnostic findings contradict the task description, a `MUST_RESOLVE` warning is raised and execution pauses for user confirmation.

## Modified Specs

| Domain    | Action  | Change                                                                 |
| --------- | ------- | ---------------------------------------------------------------------- |
| sdd-apply | Added   | Requirement: Mandatory Diagnosis Step before each task implementation  |
| sdd-apply | Added   | Requirement: Diagnosis findings that contradict task assumptions trigger MUST_RESOLVE warning |
| sdd-apply | Added   | Requirement: diagnosis_commands optional key in openspec/config.yaml   |
| sdd-apply | Added   | 5 additional Rules entries (Diagnosis Step constraints)                |

## Modified Code Files

- `skills/sdd-apply/SKILL.md` — new Step 4 (Diagnosis Step) inserted between Step 3 (verify scope) and the implementation step; old Steps 4–6 renumbered to 5–7; `diagnosis_commands` config key documented; `MUST_RESOLVE` warning protocol added
- `openspec/config.yaml` — `diagnosis_commands` optional key documented with commented example block

## Key Decisions Made

- **Diagnosis Step placement**: inserted as new Step 4 between Step 0 (tech skill preload) and the existing implementation step — front-loading ensures technology skills are already loaded as context before diagnosis runs
- **Structured prose DIAGNOSIS block**: 5 mandatory fields + Risk field; consistent with how other sdd-apply outputs are formatted (DEVIATION, QUALITY_VIOLATION)
- **MUST_RESOLVE pause mechanism**: sub-agent writes warning block and halts until user confirms — auto-proceed was rejected; a contradicting assumption is high-risk and warrants explicit user confirmation
- **diagnosis_commands in openspec/config.yaml**: follows established convention for project-level sdd-apply behavior config (e.g., `tdd`, `apply_max_retries`)
- **Universal applicability**: applies to every task including new-file creation tasks — universal ensures the invariant holds without requiring the sub-agent to classify tasks

## Lessons Learned

- The change was documentation-only (single `.md` file + `.yaml` comment block), making automated testing inapplicable; verification was done entirely via spec scenario inspection — this is the expected and correct approach for procedural SKILL.md changes
- No deviations from design during implementation; the step numbering renaming was clean
- Open question deferred by design: per-task `[skip-diagnosis]` annotation — explicitly out of scope; a future proposal can add it if needed

## User Docs Reviewed

NO — this change modifies `sdd-apply/SKILL.md` (an internal procedural skill), not user-facing workflows. No updates to `scenarios.md`, `quick-reference.md`, or `onboarding.md` are required.
