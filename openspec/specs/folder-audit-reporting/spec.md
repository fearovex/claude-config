# Spec: folder-audit-reporting

Change: claude-folder-audit
Date: 2026-03-03

## Overview

This spec describes the observable structure and content contract of the report produced
by the `claude-folder-audit` skill. It covers: the report file location, the required
sections, finding severity levels, remediation hints, and the CLAUDE.md registration
requirement.

---

## Requirements

### Requirement: report MUST be written to a mode-specific, predictable location

*(Modified in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `global-config` and `global` modes the report path MUST remain
`~/.claude/claude-folder-audit-report.md` (tilde expanded at runtime). In `project` mode
the report MUST be written to `.claude/claude-folder-audit-report.md` relative to CWD
(i.e., inside the project's own `.claude/` directory). The report MUST NOT be written to
`~/.claude/` when in `project` mode.

#### Scenario: global-config and global modes — report path unchanged

- **GIVEN** execution mode is `global-config` or `global`
- **WHEN** the skill writes its output
- **THEN** the file `~/.claude/claude-folder-audit-report.md` is created or overwritten
- **AND** no report file is written to any project `.claude/` directory

#### Scenario: project mode — report written to .claude/ inside the project

- **GIVEN** execution mode is `project`
- **AND** the project root is `<cwd>`
- **WHEN** the skill writes its output
- **THEN** the file `<cwd>/.claude/claude-folder-audit-report.md` is created or overwritten
- **AND** no report file is written to `~/.claude/`
- **AND** the skill emits a message: "Report written to: <cwd>/.claude/claude-folder-audit-report.md"

#### Scenario: project mode — .claude/ directory exists (guaranteed by mode detection)

- **GIVEN** execution mode is `project`
- **AND** mode detection already confirmed `.claude/` exists at CWD
- **WHEN** the skill writes the report
- **THEN** the write succeeds without needing to create the `.claude/` directory
- **AND** a pre-existing `claude-folder-audit-report.md` from a previous run is overwritten

#### Scenario: report path is displayed to the user at the end of execution

- **GIVEN** the skill has finished writing the report
- **WHEN** skill execution concludes
- **THEN** the skill emits a message to the user that includes the full expanded path
  to the report (mode-appropriate path)

---

### Requirement: report MUST contain a structured header with metadata

The report MUST begin with a header block containing: run date, execution mode, relevant
path fields for the active mode, and a one-line summary of finding counts by severity.

*(Modified in: 2026-03-03 by change "claude-folder-audit-project-mode")*

#### Scenario: header block is present and complete on a successful run — global-config/global modes

- **GIVEN** execution mode is `global-config` or `global`
- **WHEN** the report is read
- **THEN** the report begins with a section containing:
  - `Run date:` in ISO 8601 format (YYYY-MM-DD HH:MM UTC or local)
  - `Mode:` — either `global-config` or `global`
  - `Runtime root:` — expanded path to `~/.claude/`
  - `Source root:` — expanded path to the source repo root, or "Not detected" if in global mode
  - `Summary:` — e.g., "2 HIGH, 1 MEDIUM, 3 LOW, 2 INFO"

#### Scenario: project mode header block is present and complete

- **GIVEN** execution mode is `project`
- **AND** the skill completes all 5 project checks (P1–P5) without aborting
- **WHEN** the report is read
- **THEN** the report begins with a header block containing:
  - `Run date:` in ISO 8601 format
  - `Mode: project`
  - `Project root:` — the expanded absolute path to CWD
  - `CLAUDE.md:` — the expanded absolute path to `<cwd>/.claude/CLAUDE.md`
  - `Summary:` — e.g., "1 HIGH, 2 MEDIUM, 0 LOW, 3 INFO"

#### Scenario: project mode header does not include Source root field

- **GIVEN** execution mode is `project`
- **WHEN** the report header is read
- **THEN** the header does NOT contain a `Source root:` field
- **AND** the header DOES contain `Project root:` and `CLAUDE.md:` fields instead

---

### Requirement: report MUST use exactly three severity levels and one informational level

All findings in the report MUST be classified as exactly one of: `HIGH`, `MEDIUM`,
`LOW`, or `INFO`. No other severity labels are permitted.

| Level | Meaning |
|-------|---------|
| HIGH | Action required — system is likely broken or dangerously out of sync |
| MEDIUM | Should be reviewed — degraded or potentially inconsistent state |
| LOW | Informational concern — acceptable in many cases, verify intent |
| INFO | Observation only — no action required |

#### Scenario: every finding in the report carries exactly one severity label

- **GIVEN** the report contains one or more findings
- **WHEN** the report is parsed
- **THEN** every finding line or block is prefixed with exactly one of: `HIGH`, `MEDIUM`, `LOW`, `INFO`
- **AND** no finding uses a different label (e.g., CRITICAL, WARNING, ERROR)

#### Scenario: a category with no findings still appears in the report with a "No findings" note

- **GIVEN** Check N produces zero findings of any severity
- **WHEN** the report is written
- **THEN** the section for Check N still appears with the text "No findings"
- **AND** the section header identifies the check name (e.g., "Check 1 — Runtime Structure")

---

### Requirement: each finding MUST include a remediation hint

Every HIGH, MEDIUM, and LOW finding in the report MUST include a `Remediation:` line
immediately following the finding description. INFO observations MAY include a
`Note:` line but are not required to include a remediation.

#### Scenario: HIGH finding includes a mandatory remediation command

- **GIVEN** a HIGH finding is recorded (e.g., a missing required directory)
- **WHEN** the report is written
- **THEN** the finding block contains a `Remediation:` line with a specific, actionable
  command or instruction (e.g., "Run install.sh from the agent-config repo")

#### Scenario: INFO observation appears without a remediation line

- **GIVEN** an INFO observation is recorded (e.g., "Source repo not detected — check skipped")
- **WHEN** the report is written
- **THEN** the finding block MAY omit the `Remediation:` line
- **AND** it MAY include an optional `Note:` line instead

---

### Requirement: report MUST include a prioritized findings table as a summary

Before the per-check detail sections, the report MUST include a findings summary table
listing all non-INFO findings sorted by severity (HIGH first, then MEDIUM, then LOW).

#### Scenario: findings table appears before per-check detail sections

- **GIVEN** the skill has collected findings from all 5 checks
- **WHEN** the report is written
- **THEN** a section titled "## Findings Summary" appears before "## Check 1 — ..." sections
- **AND** it contains a Markdown table with columns: Severity, Check, Description, Remediation

#### Scenario: findings table is empty when no non-INFO findings exist

- **GIVEN** all 5 checks produce only INFO observations or no findings at all
- **WHEN** the report is written
- **THEN** the "## Findings Summary" table contains a single row: "No HIGH / MEDIUM / LOW findings"

---

### Requirement: report MUST conclude with a recommended next steps section

The report MUST end with a "## Recommended Next Steps" section. If HIGH findings
exist, the first recommended action MUST be to run `install.sh`. If no HIGH or MEDIUM
findings exist, the section MUST state that the runtime appears healthy.

#### Scenario: HIGH findings present — install.sh is the first recommended step

- **GIVEN** the report contains one or more HIGH findings
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first item is: "1. Run install.sh from the agent-config repo to re-sync
  the runtime with the source"
- **AND** additional items MAY follow for MEDIUM or LOW findings

#### Scenario: no HIGH or MEDIUM findings — healthy state confirmed

- **GIVEN** the report contains zero HIGH findings and zero MEDIUM findings
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Runtime appears healthy — no required actions detected"
- **AND** any LOW or INFO findings are listed as optional review items below

---

### Requirement: the new skill MUST be registered in CLAUDE.md under a "System Audits" section

After the skill is created and deployed, CLAUDE.md MUST contain a registry entry for
`claude-folder-audit` under a new "System Audits" section in the Skills Registry block.

#### Scenario: CLAUDE.md Skills Registry contains the claude-folder-audit entry after apply

- **GIVEN** the `sdd-apply` phase has completed for the `claude-folder-audit` change
- **WHEN** `CLAUDE.md` is read
- **THEN** the Skills Registry section contains an entry:
  `~/.claude/skills/claude-folder-audit/SKILL.md` with a one-line description
- **AND** the entry is grouped under a "### System Audits" subsection header

#### Scenario: project-audit D1 passes after install.sh is run post-apply

- **GIVEN** `sdd-apply` has written `skills/claude-folder-audit/SKILL.md`
- **AND** the CLAUDE.md registry entry has been added
- **AND** `install.sh` has been run
- **WHEN** `/project-audit` is run
- **THEN** D1 (Skills Registry integrity) passes without a finding for `claude-folder-audit`

---

### Requirement: project-onboard skill MUST include a non-blocking hint to run claude-folder-audit

After this change, `project-onboard/SKILL.md` MUST include a hint that tells users to
run `/claude-folder-audit` when they suspect installation drift. This hint MUST be
non-blocking — it MUST NOT interrupt the standard onboarding flow.

#### Scenario: project-onboard output references claude-folder-audit for drift cases

- **GIVEN** a user runs `/project-onboard` on a project that shows signs of installation drift
  (e.g., skills referenced in CLAUDE.md are not found at their declared paths)
- **WHEN** project-onboard produces its output
- **THEN** the output includes a non-blocking note recommending the user run
  `/claude-folder-audit` to diagnose the runtime installation state
- **AND** this note does NOT prevent project-onboard from completing its normal analysis

---

---

### Requirement: project mode report MUST use project-specific check section labels

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*
*(Modified in: 2026-03-03 by change "enhance-claude-folder-audit" — extended to include P6, P7, P8)*

The per-check sections in the report MUST use project-mode labels (P1–P8) to distinguish
them from the global-mode check labels (Check 1–Check 5).

#### Scenario: project mode report uses P1–P8 section headers *(modified)*

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all 8 checks
- **WHEN** the report is read
- **THEN** the per-check sections are labeled:
  - `## Check P1 — CLAUDE.md Presence and Skills Registry`
  - `## Check P2 — Global Skill Registrations Reachability`
  - `## Check P3 — Local Skill Registrations Reachability`
  - `## Check P4 — Orphaned Local Skills`
  - `## Check P5 — Scope Tier Overlap`
  - `## Check P6 — Memory Layer (ai-context/)`
  - `## Check P7 — Feature Domain Knowledge Layer (ai-context/features/)`
  - `## Check P8 — .claude/ Folder Inventory`
- **AND** no section uses any other label

#### Scenario: all 8 check sections appear in the report even when they have no findings *(modified)*

- **GIVEN** execution mode is `project`
- **AND** one or more of Checks P1–P8 produce zero findings of any severity
- **WHEN** the report is written
- **THEN** all 8 check sections appear in the report
- **AND** each section with no findings shows "No findings" under its header

---

### Requirement: project mode report MUST include labeled section headers for all 8 checks (P1–P8)

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

The existing requirement covers P1–P5 section labels. This change extends the contract to
cover the three new checks P6, P7, and P8.

#### Scenario: project mode report includes section headers for P6, P7, and P8

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all 8 checks
- **WHEN** the report is read
- **THEN** in addition to the existing P1–P5 section headers, the report contains:
  - `## Check P6 — Memory Layer (ai-context/)`
  - `## Check P7 — Feature Domain Knowledge Layer (ai-context/features/)`
  - `## Check P8 — .claude/ Folder Inventory`
- **AND** no section uses a label not in the set P1–P8

#### Scenario: each new check section appears even when it has no findings

- **GIVEN** execution mode is `project`
- **AND** Check P6, P7, or P8 produces zero findings of any severity
- **WHEN** the report is written
- **THEN** the section for the check still appears with the text "No findings"

---

### Requirement: report header summary line MUST reflect all 8 checks

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

When the report is written in project mode, the summary line in the header MUST count
findings from all 8 checks (P1 through P8), not just 5.

#### Scenario: header summary includes counts from P6, P7, P8

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all 8 checks
- **WHEN** the report header is read
- **THEN** the `Summary:` line reflects the total finding counts from checks P1 through P8
- **AND** findings from P6, P7, and P8 are included in the HIGH/MEDIUM/LOW/INFO totals

---

### Requirement: project mode Findings Summary table MUST include P6, P7, and P8 findings

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

The existing Findings Summary table requirement covers all check findings without explicitly
restricting to P1–P5. This requirement makes the inclusion of P6–P8 explicit.

#### Scenario: Findings Summary table includes P6, P7, P8 rows when those checks produce findings

- **GIVEN** execution mode is `project`
- **AND** one or more of Checks P6, P7, P8 produced a non-INFO finding
- **WHEN** the "## Findings Summary" table is read
- **THEN** each non-INFO finding from P6, P7, P8 appears as a row in the table
- **AND** each row identifies the check (e.g., "P6", "P7", "P8") in the Check column

---

### Requirement: report findings MUST collapse INFO-only check sections to a one-line summary

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

To prevent report length explosion on healthy projects, check sections that produce only
INFO observations MUST be collapsible — all INFO notes MUST appear under the check section
but MUST NOT be listed in the Findings Summary table (which shows only HIGH/MEDIUM/LOW).

#### Scenario: P7 section produces only INFO notes — not listed in Findings Summary

- **GIVEN** execution mode is `project`
- **AND** Check P7 produces only INFO notes (e.g., ai-context/features/ absent, or only template present)
- **WHEN** the report is read
- **THEN** the P7 section appears with the INFO observations listed under it
- **AND** no P7 row appears in the "## Findings Summary" table (which covers HIGH/MEDIUM/LOW only)

---

### Requirement: project mode Findings Summary table MUST reference project-specific remediation actions

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the Findings Summary table MUST be present and MUST reference
project-specific remediation actions rather than global `install.sh` instructions.

#### Scenario: Findings Summary table uses project-appropriate remediation hints

- **GIVEN** execution mode is `project`
- **AND** one or more HIGH or MEDIUM findings are present
- **WHEN** the report's "## Findings Summary" table is read
- **THEN** remediation hints in the table reference project-local actions for P3 and P4 findings
- **AND** for P2 findings (global skill not deployed), the hint "Run install.sh from the agent-config repo" IS appropriate and MUST appear

---

### Requirement: project mode Recommended Next Steps MUST be project-context-aware

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the "## Recommended Next Steps" section MUST provide actions
relevant to fixing the project's Claude configuration, not the global runtime.

#### Scenario: P1 HIGH finding — first recommended step is to fix .claude/CLAUDE.md

- **GIVEN** execution mode is `project`
- **AND** Check P1 produced a HIGH finding
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first item references: "Create or update .claude/CLAUDE.md — ensure it contains a ## Skills Registry section"

#### Scenario: no HIGH or MEDIUM findings in project mode — healthy state confirmed

- **GIVEN** execution mode is `project`
- **AND** the report contains zero HIGH findings and zero MEDIUM findings
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Project Claude configuration appears healthy — no required actions detected"

---

### Requirement: project mode Recommended Next Steps MUST reference new check remediations

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

When the highest-severity finding comes from P6, P7, or P8, the Recommended Next Steps
section MUST provide an appropriate first action that is specific to the finding source.

#### Scenario: P6 MEDIUM finding (ai-context/ absent) — first step references /memory-init

- **GIVEN** execution mode is `project`
- **AND** the highest-severity finding is a MEDIUM from Check P6 (ai-context/ directory absent)
- **AND** no HIGH findings exist
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first recommended action is: "Run /memory-init to generate the ai-context/ memory layer for this project"

#### Scenario: P8 MEDIUM finding (unexpected .claude/ item) — first step references manual review

- **GIVEN** execution mode is `project`
- **AND** the highest-severity finding is a MEDIUM from Check P8 (unexpected item in .claude/)
- **AND** no HIGH findings exist
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first recommended action references reviewing the unexpected .claude/ item manually

#### Scenario: no HIGH or MEDIUM findings across all 8 checks — healthy state confirmed

- **GIVEN** execution mode is `project`
- **AND** the report contains zero HIGH findings and zero MEDIUM findings across all 8 checks
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Project Claude configuration appears healthy — no required actions detected"

---

### Requirement: project mode report MUST NOT be committed to the project repository

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

The report file `.claude/claude-folder-audit-report.md` is a runtime audit artifact.
The skill MUST note in the report footer that this file should be excluded from git.

#### Scenario: report footer includes a git-exclusion reminder

- **GIVEN** execution mode is `project`
- **AND** the report has been written to `.claude/claude-folder-audit-report.md`
- **WHEN** the report's footer is read
- **THEN** it includes a note: "This file is a runtime artifact. Add .claude/claude-folder-audit-report.md to .gitignore to prevent accidental commits."

#### Scenario: skill does not modify .gitignore itself

- **GIVEN** execution mode is `project`
- **WHEN** the skill completes execution
- **THEN** the skill does NOT modify `.gitignore` — it remains strictly read-only except for the report output

---

## Rules

- The report file MUST be overwritten (not appended) on every run
- The report MUST be valid Markdown — all sections use `##` headers, all findings use
  `**HIGH**` / `**MEDIUM**` / `**LOW**` / `**INFO**` bold labels
- The report MUST NOT contain any content suggesting destructive operations
  (file deletion, directory removal) without explicit human review as a prerequisite
- The CLAUDE.md registry entry MUST use the global path `~/.claude/skills/claude-folder-audit/SKILL.md`
  because `claude-folder-audit` is a meta-system skill (deployed from `agent-config` itself, not a project)
- The "System Audits" section header MUST be added to CLAUDE.md only if it does not already exist;
  if it exists, the new entry MUST be appended under it
- In `project` mode, the report MUST be written to `<cwd>/.claude/claude-folder-audit-report.md` — never to `~/.claude/`
- The report file path MUST always be shown to the user at the end of execution (expanded absolute path)
- The `.claude/` directory is guaranteed to exist when project mode is active (mode detection precondition); the skill MUST NOT attempt to create it
- INFO findings from check sections MUST NOT appear in the "## Findings Summary" table — that table covers HIGH, MEDIUM, and LOW only; INFO observations remain in their check section body
- The project-mode report MUST include all 8 check sections (P1–P8) regardless of findings; sections with no findings show "No findings"
