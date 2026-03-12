---
name: project-onboard
description: >
  Diagnoses the current project state and recommends the exact command sequence for one of 6 onboarding cases.
  Trigger: /project-onboard, what do I run first, project setup help, diagnose project state.
format: procedural
---

# project-onboard

> Reads the current project's file system and determines which of 6 onboarding cases applies, then recommends the exact command sequence.

**Triggers**: `/project-onboard`, onboard project, diagnose project state, what do I run first, project setup help

---

## Process

I run a 5-check waterfall in strict priority order. I read real files — I never ask the user questions. The first failing check determines the primary case assignment. Check 4 is non-blocking: a project can simultaneously be Case 6 (healthy) and have local skill issues.

### Check 1 — CLAUDE.md exists

Read `.claude/CLAUDE.md` (also accept `CLAUDE.md` at project root for global-config repos).

**If absent → Case 1: Brand-new project**

```
## Diagnosis

Project state: Case 1 — Brand-New Project

Detected:
- .claude/CLAUDE.md: NOT FOUND
- No Claude configuration present in this project

Warnings:
- None

## Recommended Command Sequence

1. /project-setup     — creates .claude/CLAUDE.md, openspec/config.yaml, ai-context/ skeleton
2. /memory-init       — generates ai-context/ files from real project content
3. /project-audit     — produces audit-report.md with score and findings
4. /project-fix       — applies all corrections from the audit report

## Notes
After /project-fix, re-run /project-audit to verify score ≥ 75 and SDD Readiness = FULL or PARTIAL.
See ai-context/scenarios.md → Case 1 for failure modes and recovery steps.
```

Stop here if Case 1.

---

### Check 2 — openspec/config.yaml exists

Read `openspec/config.yaml`.

**If absent → Case 2: CLAUDE.md present but no SDD infrastructure**

```
## Diagnosis

Project state: Case 2 — CLAUDE.md Without SDD Infrastructure

Detected:
- .claude/CLAUDE.md: FOUND
- openspec/config.yaml: NOT FOUND
- SDD cannot function without openspec/

Warnings:
- [list any ai-context/ files found or note if ai-context/ is absent]

## Recommended Command Sequence

1. /project-audit     — diagnose the full scope of what is missing
2. /project-fix       — creates openspec/ structure, adds SDD section to CLAUDE.md
3. /memory-init       — if ai-context/ is empty or absent
4. /project-audit     — verify score improved

## Notes
project-fix will ask before every change — review each proposed action carefully.
See ai-context/scenarios.md → Case 2 for failure modes and recovery steps.
```

Stop here if Case 2.

---

### Check 3 — ai-context/ has ≥ 3 populated files

Read `ai-context/` directory. Count files that exist AND have more than 10 lines.
Expected files: `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`.

**If fewer than 3 populated files → Case 3: Partial SDD, sparse memory layer**

```
## Diagnosis

Project state: Case 3 — Partial SDD (ai-context/ is sparse)

Detected:
- .claude/CLAUDE.md: FOUND
- openspec/config.yaml: FOUND
- ai-context/ populated files: [N] of 5 (minimum needed: 3)
- Missing or empty: [list each absent/stub file]

Warnings:
- [list any other issues found, e.g. stale onboarding.md]

## Recommended Command Sequence

1. /memory-init       — regenerates all ai-context/ files from real project state
2. /project-audit     — verify D2 score improved
3. /project-fix       — address any remaining findings

## Notes
/memory-init does not overwrite files that already have substantial content.
See ai-context/scenarios.md → Case 3 for failure modes and recovery steps.
```

Stop here if Case 3.

---

### Check 4 — Local skills review (non-blocking)

Read `.claude/skills/` directory. If it exists and has any subdirectories, record a warning for the diagnosis output. **Do not stop — continue to Check 5.**

Local skills warning (append to any case diagnosis):
```
Warnings:
- .claude/skills/ found with [N] local skill(s): [list names]
  Run /project-audit to see Dimension 9 findings (duplicate detection, structural completeness, language compliance).
  Run /project-fix Phase 5 to apply corrections after auditing.
```

---

### Check 5 — Orphaned SDD changes

Read `openspec/changes/` directory, excluding `archive/`. For each subdirectory, check whether `tasks.md` and `verify-report.md` exist.

**If any change is missing `tasks.md` OR `verify-report.md` → Case 5: Orphaned or stale changes**

```
## Diagnosis

Project state: Case 5 — Orphaned SDD Changes

Detected:
- .claude/CLAUDE.md: FOUND
- openspec/config.yaml: FOUND
- ai-context/: adequate ([N] populated files)
- Orphaned changes:
  - [change-name]: missing [tasks.md | verify-report.md]
  - [change-name]: missing [tasks.md | verify-report.md]

Warnings:
- [local skills warning if Check 4 triggered]

## Recommended Command Sequence

1. /sdd-status        — see all active changes and their current phase
2. For each orphaned change, one of:
   /sdd-apply <name>  — if tasks.md is missing (change never implemented)
   /sdd-verify <name> — if implemented but never verified
   /sdd-archive <name> — if complete but never archived
3. /project-audit    — verify D3 shows no orphaned changes

## Notes
To discard a dead-end change: manually move its folder to openspec/changes/archive/YYYY-MM-DD-<name>/
See ai-context/scenarios.md → Case 5 for failure modes and recovery steps.
```

Stop here if Case 5.

---

### Check 6 — All healthy (default)

All checks passed. The project is fully configured.

```
## Diagnosis

Project state: Case 6 — Fully Configured

Detected:
- .claude/CLAUDE.md: FOUND
- openspec/config.yaml: FOUND
- ai-context/: adequate ([N] populated files)
- openspec/changes/: no orphaned changes

Warnings:
- [local skills warning if Check 4 triggered]
- [stale onboarding.md warning if Last verified > 90 days: "Run /project-update to refresh user docs"]

## Recommended Command Sequence

For a well-understood change:
  1. /sdd-ff <change-name>       — fast-forward: propose → spec+design → tasks
  2. /sdd-apply <change-name>    — implement the task plan

For a complex or vague change:
  1. /sdd-new <change-name>      — full SDD cycle with optional explore + confirmation gates
  2. /sdd-apply <change-name>    — implement the task plan

## Notes
Use /sdd-ff when requirements are clear. Use /sdd-new when the change is complex or you want to review
the proposal before proceeding. See ai-context/quick-reference.md for the /sdd-ff vs /sdd-new decision rule.
```

---

### Check 7 — Runtime sync hint (non-blocking, global-config mode only)

If `install.sh` AND `skills/` exist at the project root (i.e., the cwd is the `agent-config` meta-repo), append the following line to the `Warnings:` section of the case diagnosis output — regardless of which case was assigned:

```
- Run /claude-folder-audit to verify ~/.claude/ is in sync with this repo (installation drift check).
```

This check MUST NOT change the case assignment, alter the Recommended Command Sequence, or interrupt the existing 6-check waterfall. It is a hint only.

---

## Stale docs warning logic

After determining the primary case, check `ai-context/onboarding.md`, `ai-context/scenarios.md`, and `ai-context/quick-reference.md` for the `> Last verified:` field. If any file's date is more than 90 days from today, append to the Warnings section:

```
- [filename] is stale ([N] days since last verification). Run /project-update to refresh.
```

---

## Rules

- Do not ask the user any questions — detection is fully automatic from file-system state
- Detection is derived from real file presence/absence — no hardcoded case IDs or lookup tables
- Priority order is strict: once a case is assigned at check N, do not also assign a lower-priority case (exception: Check 4 local skill flag is always surfaced as a warning, non-blocking)
- Emit structured output only — no raw directory listings, no stack traces, no internal file dumps
- Make no file-system changes — this skill is 100% read-only
- Always include a `## Notes` section pointing to the relevant case in `ai-context/scenarios.md` for failure modes
