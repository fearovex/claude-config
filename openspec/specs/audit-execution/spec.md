# Spec: audit-execution

Change: batch-audit-bash-calls
Date: 2026-02-26

## Overview

This spec describes the observable execution behavior of the `project-audit` skill, specifically how it issues shell-based discovery calls. It does not cover scoring logic, report format, or dimension content — those are unchanged.

---

## Requirements

### Requirement: Batched shell discovery

The `project-audit` skill MUST consolidate all shell-based discovery (file existence checks, line counts, directory listings, grep searches, orphaned change detection) into the minimum number of Bash tool calls achievable, with an absolute ceiling of 3 Bash calls per audit run. The Phase A script MUST emit a `LOCAL_SKILLS_DIR` key in addition to all other required keys.

*(Modified in: 2026-02-27 by change "global-config-skill-audit" — added LOCAL_SKILLS_DIR key to Phase A output)*

#### Scenario: Full audit run on a project with all files present

- **GIVEN** Claude is executing `/project-audit` on a project that has `CLAUDE.md`, `openspec/`, `ai-context/`, and `.claude/skills/`
- **WHEN** the audit runs its discovery phase
- **THEN** all file existence checks, line counts, and directory listings are issued in a single Bash call that emits structured output
- **AND** that single Bash call returns without requiring user approval (pre-approved via settings.json)
- **AND** the total number of Bash calls for the entire audit run does not exceed 3

#### Scenario: Audit run on a minimal project (no openspec/, no ai-context/)

- **GIVEN** a project that has only a root `CLAUDE.md` and no other Claude config files
- **WHEN** the discovery Bash call runs
- **THEN** it still runs as a single call (not skipped) and returns "not found" indicators for absent paths
- **AND** Claude reads those indicators to fill in ❌ results without issuing further Bash calls per missing file

#### Scenario: Discovery script output format

- **GIVEN** the discovery Bash call is executing
- **WHEN** it completes
- **THEN** its stdout MUST consist of `key=value` lines (one per check) or a valid JSON object
- **AND** every key in the output is deterministic and matches a key that SKILL.md defines as part of its parsing specification
- **AND** no key is undefined or conditionally absent in the output schema

#### Scenario: No individual ad-hoc Bash calls during dimension evaluation

- **GIVEN** the audit has completed the discovery Bash call
- **WHEN** Claude evaluates each of the 9 dimensions
- **THEN** Claude MUST NOT issue individual `ls`, `grep`, `wc -l`, or `find` calls per dimension
- **AND** Claude reads content files for dimension analysis using the Read, Glob, and Grep tools (already pre-approved), not via Bash

#### Scenario: Discovery script output includes LOCAL_SKILLS_DIR key

- **GIVEN** Claude is executing `/project-audit` on any project
- **WHEN** the Phase A discovery Bash call completes
- **THEN** its stdout includes a line `LOCAL_SKILLS_DIR=<value>` where `<value>` is either `skills` or `.claude/skills`
- **AND** this line appears in the output regardless of whether the project is a global-config repo or a standard project
- **AND** the key is always present and never conditionally absent

#### Scenario: LOCAL_SKILLS_DIR resolves to "skills" on global-config repo

- **GIVEN** the target project has both `install.sh` and `sync.sh` at its root
- **WHEN** the `LOCAL_SKILLS_DIR` assignment logic executes within the Phase A script
- **THEN** `LOCAL_SKILLS_DIR` is set to `skills`

#### Scenario: LOCAL_SKILLS_DIR resolves to ".claude/skills" on a standard project

- **GIVEN** the target project does NOT have both `install.sh` and `sync.sh` at root
- **AND** `openspec/config.yaml` either does not exist or does not contain `Claude Code SDD meta-system`
- **WHEN** the `LOCAL_SKILLS_DIR` assignment logic executes
- **THEN** `LOCAL_SKILLS_DIR` is set to `.claude/skills`

#### Scenario: Total Bash call count still does not exceed 3

- **GIVEN** the Phase A script has been extended with the `LOCAL_SKILLS_DIR` logic
- **WHEN** `/project-audit` runs end-to-end on any project
- **THEN** the total number of Bash tool calls does not exceed 3
- **AND** adding `LOCAL_SKILLS_DIR` does not introduce a new Bash call — it is part of the existing Phase A script block

---

### Requirement: Batching rule documented in SKILL.md Execution Rules

The `project-audit` SKILL.md MUST contain an explicit rule in its Execution Rules section stating that all shell-based discovery MUST be batched.

#### Scenario: Execution Rules section contains the batching constraint

- **GIVEN** a developer or Claude reads `skills/project-audit/SKILL.md`
- **WHEN** they read the Execution Rules section
- **THEN** they find a rule that explicitly states shell discovery must be consolidated into a single Bash script call
- **AND** the rule states the maximum number of Bash calls allowed per audit run (≤ 3)
- **AND** the rule prohibits issuing individual `ls`/`grep`/`wc` calls separately

#### Scenario: SKILL.md provides a concrete script template

- **GIVEN** the updated SKILL.md is read
- **WHEN** Claude reaches the discovery phase instructions
- **THEN** it finds a concrete shell script template (inline, in a fenced code block) that collects all required structural facts
- **AND** the template outputs `key=value` lines for every check defined in the dimensions
- **AND** the template uses only read-only commands (`test -f`, `test -d`, `wc -l`, `find`, `grep -c`, etc.)

---

### Requirement: Audit output unchanged by batching

The batching change MUST NOT alter the report produced by `project-audit`.

#### Scenario: Report produced after batching is structurally identical to pre-change report

- **GIVEN** the same project is audited before and after this change is applied
- **WHEN** both reports are compared
- **THEN** the dimensions, scoring table, FIX_MANIFEST structure, and required actions sections are identical in format
- **AND** the score differs by no more than 0 points if the project state has not changed between runs

#### Scenario: Audit on claude-config itself scores at least as high after the change

- **GIVEN** the current `audit-report.md` in the claude-config project records a baseline score
- **WHEN** `/project-audit` is run on claude-config after this change is applied and `install.sh` has been run
- **THEN** the score is greater than or equal to the baseline score

---

### Requirement: Zero mid-run Bash approval prompts

When `Bash` is in `permissions.allow`, a full audit run MUST complete without any Bash tool approval interruptions.

#### Scenario: Complete audit run with Bash pre-approved

- **GIVEN** `settings.json` contains `"Bash"` in the `permissions.allow` array
- **AND** `/project-audit` is invoked on any project
- **WHEN** the audit runs end-to-end
- **THEN** no Bash tool approval dialog appears during the run
- **AND** the audit completes and writes `audit-report.md` without user interaction

#### Scenario: Audit run without Bash pre-approved (graceful degradation)

- **GIVEN** `settings.json` does NOT contain `"Bash"` in `permissions.allow` (e.g., after rollback)
- **WHEN** the audit runs
- **THEN** it still produces a valid report (fewer calls = fewer prompts), but MAY require up to 3 approval clicks
- **AND** it does not hang or error out — it functions with reduced automation

---

## Rules

- These specs describe observable outcomes only — not how the script is implemented
- All scenarios marked with MUST are non-negotiable for this change to be considered complete
- Scenarios for graceful degradation (without Bash pre-approved) are informational; they describe acceptable fallback behavior, not a required deliverable of this change
