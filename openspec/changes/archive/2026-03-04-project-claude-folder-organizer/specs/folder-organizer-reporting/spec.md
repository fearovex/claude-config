# Spec: folder-organizer-reporting

Change: project-claude-folder-organizer
Date: 2026-03-04

## Overview

This spec describes the observable structure and content contract of the report produced
by the `project-claude-organizer` skill. It covers: the report file location, required
sections, content per section, runtime-artifact classification, and the architecture.md
artifact table update.

---

## Requirements

### Requirement: report MUST be written to a fixed, predictable path inside the project .claude/

After a successful apply (or after a no-op run confirming a clean state), the skill MUST
write a report to `PROJECT_CLAUDE_DIR/claude-organizer-report.md`. The report MUST be
overwritten on every run (not appended).

#### Scenario: report path is PROJECT_CLAUDE_DIR/claude-organizer-report.md

- **GIVEN** the skill has completed execution (apply or no-op)
- **WHEN** the report is written
- **THEN** the file `<cwd>/.claude/claude-organizer-report.md` is created or overwritten
- **AND** no report file is written to `~/.claude/` or anywhere else

#### Scenario: report is overwritten on re-run

- **GIVEN** a `claude-organizer-report.md` already exists from a previous run
- **WHEN** the skill runs again and completes execution
- **THEN** the existing file is overwritten with the new report content
- **AND** no content from the previous run persists in the new report

#### Scenario: skill emits the report path to the user

- **GIVEN** the skill has finished writing the report
- **WHEN** skill execution concludes
- **THEN** the skill emits a message: "Report written to: <cwd>/.claude/claude-organizer-report.md"
- **AND** the path shown is the expanded absolute path (no tilde or relative segments)

---

### Requirement: report MUST contain a structured header with run metadata

The report MUST begin with a header block containing: run date, project root path, and a
one-line summary of the actions taken.

#### Scenario: report header is present and complete

- **GIVEN** the skill has completed execution
- **WHEN** the report is read
- **THEN** the report begins with a section containing:
  - `Run date:` in ISO 8601 format (YYYY-MM-DD)
  - `Project root:` — the expanded absolute path to CWD
  - `Target:` — the expanded absolute path to `PROJECT_CLAUDE_DIR`
  - `Summary:` — a one-line description, e.g., "3 items created, 1 unexpected item flagged, 4 items already correct" or "No changes needed — .claude/ is already canonical"

---

### Requirement: report MUST contain a Plan section listing all three item categories

The report MUST include a section that documents what the plan found and what action was
taken for each category: missing items (created), unexpected items (flagged), and already-
correct items (unchanged).

#### Scenario: report Plan section covers all three categories

- **GIVEN** the plan found 2 missing items, 1 unexpected item, and 3 already-correct items
- **WHEN** the report is read
- **THEN** the report contains a `## Plan Executed` section (or equivalent) with:
  - A "Created" subsection listing the 2 items that were created
  - An "Unexpected items (not modified)" subsection listing the 1 unexpected item with a warning note
  - An "Already correct" subsection listing the 3 items

#### Scenario: report Plan section reflects a no-op run

- **GIVEN** the enumeration found all items present and no unexpected items
- **WHEN** the report is read
- **THEN** the `## Plan Executed` section states: "No changes were needed — all expected items were already present"
- **AND** it lists the items that were verified as correct

#### Scenario: report documents unexpected items with a warning note

- **GIVEN** the plan found `commands/` as an unexpected item
- **WHEN** the report is read
- **THEN** the report lists `commands/` under "Unexpected items (not modified)"
- **AND** includes a note: "This item is not part of the canonical SDD .claude/ structure. Review manually — it was NOT deleted or moved."

---

### Requirement: report MUST include a stub content description for any files created

When the skill creates a stub file (e.g., `CLAUDE.md`), the report MUST document what
content was placed in the stub so the user knows what was added.

#### Scenario: created CLAUDE.md stub is documented in the report

- **GIVEN** the skill created a stub `CLAUDE.md` at `PROJECT_CLAUDE_DIR/CLAUDE.md`
- **WHEN** the report is read
- **THEN** the report contains a note: "CLAUDE.md stub created with a ## Skills Registry section heading"
- **AND** it advises: "Populate this file with project-specific SDD configuration"

---

### Requirement: report MUST conclude with a recommended next steps section

The report MUST end with a "## Recommended Next Steps" section. If unexpected items were
found, the first recommendation MUST advise the user to review them manually. If the state
is clean post-apply, the section MUST confirm the project is structurally aligned.

#### Scenario: unexpected items present — review recommendation is first

- **GIVEN** the report documents one or more unexpected items
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first item is: "Review the unexpected item(s) listed above — if intentional, document them in .claude/CLAUDE.md; if not, remove them manually"

#### Scenario: stub files created — populate recommendation is included

- **GIVEN** the report documents stub files that were created (e.g., `CLAUDE.md`)
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** it includes: "Populate the created stub files with project-specific content"

#### Scenario: clean state post-apply — healthy confirmation

- **GIVEN** the apply step created all missing items and no unexpected items were found
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Project .claude/ structure is now aligned with the canonical SDD layout"

#### Scenario: no-op run — canonical structure confirmed

- **GIVEN** no changes were needed and the state was already clean
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "No action required — .claude/ is already canonical"

---

### Requirement: report is a runtime artifact and MUST NOT be committed to the project repository

The report file `.claude/claude-organizer-report.md` is a runtime audit artifact. The report
MUST include a footer note advising the user to add this file to `.gitignore`.

#### Scenario: report footer includes a git-exclusion reminder

- **GIVEN** the report has been written to `PROJECT_CLAUDE_DIR/claude-organizer-report.md`
- **WHEN** the report's footer is read
- **THEN** it includes a note: "This file is a runtime artifact. Add .claude/claude-organizer-report.md to .gitignore to prevent accidental commits."

#### Scenario: skill does not modify .gitignore

- **GIVEN** the skill has completed execution
- **WHEN** the project `.gitignore` is checked
- **THEN** the skill has NOT modified `.gitignore` — the suggestion is informational only

---

### Requirement: architecture.md artifact table MUST be updated to document the new report artifact

After `sdd-apply` completes, `ai-context/architecture.md` MUST contain a new row in the
artifact table for `claude-organizer-report.md`.

#### Scenario: architecture.md artifact table contains the new report artifact row

- **GIVEN** `sdd-apply` has completed for this change
- **WHEN** `ai-context/architecture.md` is read
- **THEN** the artifact table contains a row for `claude-organizer-report.md` with:
  - Producer: `project-claude-organizer`
  - Consumer: humans / operators
  - Location: `.claude/claude-organizer-report.md` in the target project (runtime artifact, never committed)

---

### Requirement: report artifact MUST be included in the canonical P8 expected item set

The file `claude-organizer-report.md` MUST be treated as an expected item in `PROJECT_CLAUDE_DIR`
by `claude-folder-audit` Check P8. This prevents false-positive MEDIUM findings after the
organizer has run.

#### Scenario: claude-folder-audit P8 does not flag claude-organizer-report.md as unexpected

- **GIVEN** the project `.claude/` folder contains `claude-organizer-report.md`
- **AND** the file was produced by a previous `/project-claude-organizer` run
- **WHEN** `/claude-folder-audit` runs Check P8
- **THEN** `claude-organizer-report.md` is NOT classified as an unexpected item
- **AND** no MEDIUM finding is raised for its presence

---

## Rules

- The report MUST be valid Markdown — all sections use `##` headers
- The report MUST be overwritten (not appended) on every run
- The report MUST include the three-category plan summary (created / unexpected / already-correct)
- The report MUST include a footer with a `.gitignore` reminder
- The report MUST NOT suggest or describe any destructive operations (deletion, moves) — it is informational
- The report path MUST always be shown to the user at the end of execution as an expanded absolute path
- `claude-organizer-report.md` MUST be listed in the canonical P8 expected item set (consistent with `claude-folder-audit` SKILL.md)
- The `ai-context/architecture.md` artifact table row MUST be added during `sdd-apply` — it is not optional
