# Spec: folder-organizer-execution

Change: project-claude-folder-organizer
Date: 2026-03-04

## Overview

This spec describes the observable behavior of the `project-claude-organizer` skill when it
executes against a project's `.claude/` folder. It covers: project root resolution, canonical
structure comparison, dry-run plan presentation, user confirmation gate, additive-only apply
behavior, and the relationship to the companion `claude-folder-audit` skill.

---

## Requirements

### Requirement: skill MUST resolve the project root before executing any check

When `/project-claude-organizer` is invoked, the skill MUST determine the project root as the
current working directory (CWD). The `.claude/` folder under that root is the audit target.
The skill MUST NOT operate on `~/.claude/` (the user-level runtime) under any circumstances.

#### Scenario: project root resolved to CWD — .claude/ is the target

- **GIVEN** the user invokes `/project-claude-organizer` from a project directory that contains a `.claude/` folder
- **WHEN** the skill resolves its target
- **THEN** it sets `PROJECT_ROOT = CWD` and `PROJECT_CLAUDE_DIR = CWD/.claude`
- **AND** all subsequent checks and writes operate relative to `PROJECT_CLAUDE_DIR`

#### Scenario: invoked from a directory with no .claude/ folder

- **GIVEN** the user invokes `/project-claude-organizer` from a directory that does NOT contain a `.claude/` folder
- **WHEN** the skill attempts to resolve its target
- **THEN** it outputs a clear error: "No .claude/ folder found at <CWD>. This skill requires a project with an existing .claude/ directory."
- **AND** it exits without writing any files or performing any checks

#### Scenario: skill MUST NOT target ~/.claude/

- **GIVEN** the user invokes `/project-claude-organizer` from the `claude-config` source repo (which has `install.sh` and `skills/` at root but no `.claude/`)
- **WHEN** the skill resolves its target
- **THEN** it outputs: "No .claude/ folder found at <CWD>. This skill targets project .claude/ folders only — not the ~/.claude/ runtime."
- **AND** it exits without writing any files

---

### Requirement: skill MUST enumerate the observed .claude/ contents against the canonical expected set

The skill MUST enumerate all items (files and directories) one level deep under `PROJECT_CLAUDE_DIR`
and compare them against the canonical expected item set. The canonical expected set MUST be
consistent with the set used by `claude-folder-audit` Check P8.

**Canonical expected item set:**
```
CLAUDE.md
skills/
audit-report.md
claude-folder-audit-report.md
claude-organizer-report.md
settings.json
settings.local.json
openspec/
ai-context/
hooks/
```

#### Scenario: all expected items present — inventory clean

- **GIVEN** `PROJECT_CLAUDE_DIR` contains exactly the items in the canonical expected set (or a subset of them)
- **WHEN** the skill completes its enumeration step
- **THEN** no items are classified as "unexpected"
- **AND** any absent expected items are classified as "missing"

#### Scenario: unexpected item found in .claude/

- **GIVEN** `PROJECT_CLAUDE_DIR` contains an item `custom-notes.md` that is not in the canonical expected set
- **WHEN** the skill completes its enumeration step
- **THEN** `custom-notes.md` is classified as an "unexpected item" in the plan
- **AND** it is NOT classified as "missing"

#### Scenario: missing required item detected

- **GIVEN** `PROJECT_CLAUDE_DIR` does not contain a `skills/` directory
- **WHEN** the skill completes its enumeration step
- **THEN** `skills/` is classified as "missing" in the plan

---

### Requirement: skill MUST produce a human-readable reorganization plan before applying any changes

After enumeration and comparison, the skill MUST produce a reorganization plan and present it
to the user. The plan MUST clearly list three categories: items to create (missing), items
flagged as unexpected, and items already correct. The skill MUST NOT apply any changes before
the user has seen the plan.

#### Scenario: plan lists missing items to create

- **GIVEN** the enumeration step found that `CLAUDE.md` and `skills/` are missing from `.claude/`
- **WHEN** the plan is presented to the user
- **THEN** the plan contains a "To be created" section listing `CLAUDE.md` (stub file) and `skills/` (empty directory)
- **AND** the plan clearly states these items do not yet exist

#### Scenario: plan lists unexpected items to flag

- **GIVEN** the enumeration step found `commands/` directory under `.claude/` (a legacy artifact)
- **WHEN** the plan is presented to the user
- **THEN** the plan contains an "Unexpected items (will be flagged, not deleted)" section listing `commands/`
- **AND** the plan explicitly states: "These items will NOT be deleted or moved — they will receive a warning comment in the report"

#### Scenario: plan lists already-correct items

- **GIVEN** the enumeration step found `CLAUDE.md` and `hooks/` both present and expected
- **WHEN** the plan is presented to the user
- **THEN** the plan contains an "Already correct" section listing `CLAUDE.md` and `hooks/`

#### Scenario: plan is presented before any file writes

- **GIVEN** the skill has completed enumeration and built the plan
- **WHEN** the plan is displayed
- **THEN** no files have been created or modified yet
- **AND** the plan is followed immediately by a confirmation prompt

---

### Requirement: skill MUST wait for explicit user confirmation before applying any changes

After presenting the reorganization plan, the skill MUST pause and request explicit user
confirmation before executing any writes. The confirmation gate MUST be a clear yes/no prompt.
If the user does not confirm, the skill MUST exit without making any changes.

#### Scenario: user confirms — skill proceeds to apply

- **GIVEN** the plan has been presented to the user
- **WHEN** the user responds with an affirmative confirmation (e.g., "yes", "proceed", "apply")
- **THEN** the skill proceeds to the apply step
- **AND** it applies exactly the changes listed in the plan — no more, no less

#### Scenario: user declines — skill exits without changes

- **GIVEN** the plan has been presented to the user
- **WHEN** the user responds with a negative answer (e.g., "no", "cancel", "abort") or provides no answer
- **THEN** the skill exits without writing any files
- **AND** it outputs: "Reorganization cancelled. No changes were made."

#### Scenario: empty plan — no changes needed

- **GIVEN** all items in `.claude/` match the canonical expected set with no missing items
- **WHEN** the enumeration step completes
- **THEN** the skill outputs: "No reorganization needed — .claude/ already matches the canonical SDD structure."
- **AND** the skill exits without a confirmation prompt (nothing to confirm)
- **AND** it still writes a report noting the clean state

---

### Requirement: skill apply step MUST be strictly additive — it MUST NOT delete or move any files

When the user confirms the plan, the skill MUST apply only additive operations:
- **Create** directories and stub files for items classified as "missing"
- **Flag** items classified as "unexpected" by noting them in the report (never by touching the files themselves)

The skill MUST NOT delete, rename, move, or overwrite any existing file or directory.

#### Scenario: missing CLAUDE.md — stub file created

- **GIVEN** `PROJECT_CLAUDE_DIR/CLAUDE.md` does not exist
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** a stub `CLAUDE.md` file is created at `PROJECT_CLAUDE_DIR/CLAUDE.md`
- **AND** the stub contains at minimum a `## Skills Registry` section heading to satisfy P1-C audit checks

#### Scenario: missing skills/ directory — empty directory created

- **GIVEN** `PROJECT_CLAUDE_DIR/skills/` does not exist
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** an empty `skills/` directory is created at `PROJECT_CLAUDE_DIR/skills/`
- **AND** no files are placed inside it

#### Scenario: unexpected item present — item is NOT touched

- **GIVEN** `PROJECT_CLAUDE_DIR/commands/` exists (legacy artifact, not in expected set)
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** `PROJECT_CLAUDE_DIR/commands/` remains untouched — not moved, not renamed, not deleted
- **AND** the unexpected item is documented in the report with a warning note

#### Scenario: already-correct items are not re-created or modified

- **GIVEN** `PROJECT_CLAUDE_DIR/hooks/` already exists and is in the expected set
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** `PROJECT_CLAUDE_DIR/hooks/` is not modified in any way
- **AND** no write operation is performed on it

#### Scenario: existing content in CLAUDE.md is never overwritten

- **GIVEN** `PROJECT_CLAUDE_DIR/CLAUDE.md` already exists with content
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** the skill does NOT create or overwrite `PROJECT_CLAUDE_DIR/CLAUDE.md`
- **AND** the existing file is left exactly as it was

---

### Requirement: skill MUST register in global CLAUDE.md under the correct sections

After the skill is created and deployed, CLAUDE.md MUST contain:
1. A command entry for `/project-claude-organizer` in the Available Commands table under "Meta-tools"
2. A registry entry in the Skills Registry under a "Meta-tool Skills" or "System Audits" sub-section

#### Scenario: CLAUDE.md Available Commands table contains the new command

- **GIVEN** `sdd-apply` has completed for this change
- **AND** `install.sh` has been run
- **WHEN** `CLAUDE.md` is read
- **THEN** the Available Commands table contains an entry for `/project-claude-organizer`
- **AND** the description reads: "Reads the project .claude/ folder, compares against canonical SDD structure, and applies reorganization after user confirmation"

#### Scenario: CLAUDE.md Skills Registry contains the new skill entry

- **GIVEN** `sdd-apply` has completed and `install.sh` has been run
- **WHEN** `CLAUDE.md` Skills Registry is read
- **THEN** it contains an entry: `~/.claude/skills/project-claude-organizer/SKILL.md`
- **AND** the entry is grouped under the "Meta-tool Skills" sub-section

#### Scenario: project-audit D1 passes after install.sh for the new skill

- **GIVEN** `skills/project-claude-organizer/SKILL.md` has been written
- **AND** the CLAUDE.md registry entry has been added
- **AND** `install.sh` has been run
- **WHEN** `/project-audit` is run on `claude-config`
- **THEN** D1 passes without a finding for `project-claude-organizer`

---

### Requirement: skill MUST pass project-audit P3-C structural compliance checks

The new `SKILL.md` MUST satisfy the format contract for `procedural` format.

#### Scenario: SKILL.md passes P3-C structural compliance

- **GIVEN** `skills/project-claude-organizer/SKILL.md` has been created with `format: procedural`
- **WHEN** `project-audit` or `claude-folder-audit` runs P3-C checks
- **THEN** the scanner finds:
  - YAML frontmatter with `---` block present
  - `format: procedural` declared
  - A `**Triggers**` bold marker line present
  - A `## Process` section (or `### Step N` steps) present
  - A `## Rules` section present
  - Body length of at least 30 lines
- **AND** no MEDIUM or HIGH findings are raised for this skill

---

### Requirement: skill behavior MUST be clearly differentiated from project-fix and claude-folder-audit

The skill MUST NOT be a duplicate or extension of `project-fix` or `claude-folder-audit`. Its
SKILL.md MUST clearly state its scope boundary.

#### Scenario: SKILL.md states that it reads .claude/ live state, not audit-report.md

- **GIVEN** a user reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they look for scope clarification
- **THEN** the SKILL.md contains an explicit note stating: this skill reads the live `.claude/` folder state directly and does NOT read from `audit-report.md`
- **AND** it states: `project-fix` is the skill that reads `audit-report.md` and applies its corrections

#### Scenario: SKILL.md states it does NOT target ~/.claude/

- **GIVEN** a user reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they look for target path clarification
- **THEN** the SKILL.md explicitly states: this skill targets project `.claude/` folders only — it MUST NOT be run against `~/.claude/`

---

## Rules

- The skill targets ONLY `PROJECT_ROOT/.claude/` — never `~/.claude/`
- Apply step is strictly additive: create missing items and flag unexpected ones in the report — never delete, move, or overwrite
- The user confirmation gate MUST NOT be skipped under any circumstances
- The canonical expected item set MUST remain consistent with `claude-folder-audit` Check P8
- Windows path resolution MUST follow the same `$HOME` / `$USERPROFILE` / `$HOMEDRIVE$HOMEPATH` priority chain used by `claude-folder-audit` Step 1 (for CWD resolution only — not for `~/.claude/`)
- The plan MUST be shown in full before any file writes occur
- The skill MUST write `claude-organizer-report.md` to `PROJECT_CLAUDE_DIR` after successful apply (see folder-organizer-reporting spec)
- The skill MUST NOT invoke or depend on `claude-folder-audit` at runtime — it may reference P8's expected set as a shared reference but operates independently
