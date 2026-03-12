# Spec: folder-audit-execution

Change: claude-folder-audit
Date: 2026-03-03

## Overview

This spec describes the observable behavior of the `claude-folder-audit` skill when it
executes its audit checks against either the `~/.claude/` runtime folder or a project's
`.claude/` configuration. It covers mode detection, path normalization, all checks
(Checks 1–5 for global modes; Checks P1–P5 for project mode), and the read-only constraint.

---

## Requirements

### Requirement: skill MUST detect its execution mode before running any check

When `/claude-folder-audit` is invoked, the skill MUST determine its execution mode from a
three-branch priority evaluation. Mode priority order (highest to lowest):

1. `global-config` — both `install.sh` AND `skills/` directory are present at CWD root
2. `project` — a `.claude/` directory is present at CWD root (and condition 1 is false)
3. `global` — all other locations

The detected mode MUST be stated at the top of the generated report.

*(Modified in: 2026-03-03 by change "claude-folder-audit-project-mode")*

#### Scenario: global-config mode detected by presence of install.sh and skills/ at root

- **GIVEN** the current working directory contains both `install.sh` and a `skills/` directory
  at the root level
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global-config`
- **AND** it records `source_root = <cwd>` and `runtime_root = ~/.claude/` (normalized)
- **AND** the generated report header states "Mode: global-config"

#### Scenario: global-config mode wins even when .claude/ is also present at CWD

- **GIVEN** both `install.sh` and `skills/` are present at CWD root
- **AND** a `.claude/` directory also exists at CWD
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global-config` (NOT `project`)
- **AND** the report header states "Mode: global-config"

#### Scenario: project mode detected when .claude/ exists at CWD and global-config conditions are absent

- **GIVEN** the current working directory does NOT satisfy `global-config` conditions
- **AND** a `.claude/` directory exists at the current working directory root
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `project`
- **AND** it records `project_root = <cwd>` and `project_claude_dir = <cwd>/.claude/`
- **AND** the generated report header states "Mode: project"

#### Scenario: global mode detected when cwd lacks install.sh or skills/ and has no .claude/

- **GIVEN** the current working directory does NOT contain both `install.sh` and `skills/` at root
- **AND** no `.claude/` directory exists at the current working directory root
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global`
- **AND** it records `runtime_root = ~/.claude/` (normalized)
- **AND** the generated report header states "Mode: global"

---

### Requirement: skill MUST normalize OS-specific home paths at startup

The skill MUST expand `~` to the actual home directory path before any filesystem
reads. On Windows the home directory is `%USERPROFILE%`; on Unix/macOS it is `$HOME`.
All displayed paths in the report MUST use forward slashes.

#### Scenario: tilde is expanded to the actual home directory on Windows

- **GIVEN** the runtime OS is Windows 11
- **AND** `%USERPROFILE%` resolves to `C:\Users\juanp`
- **WHEN** the skill normalizes the runtime root path
- **THEN** `~/.claude/` is expanded to `C:/Users/juanp/.claude/` (forward slashes)
- **AND** all subsequent file reads use this expanded path

#### Scenario: tilde is expanded on Unix / macOS

- **GIVEN** the runtime OS is Unix or macOS
- **AND** `$HOME` resolves to `/home/juanp`
- **WHEN** the skill normalizes the runtime root path
- **THEN** `~/.claude/` is expanded to `/home/juanp/.claude/`

#### Scenario: path normalization failure is treated as a HIGH finding

- **GIVEN** neither `$HOME` nor `%USERPROFILE%` resolves to a valid path
- **WHEN** the skill attempts to expand the runtime root
- **THEN** it records a HIGH finding: "Cannot resolve home directory — path normalization failed"
- **AND** it halts further checks and writes a minimal report containing only that finding

---

### Requirement: Check 1 — runtime structure validation

The skill MUST verify that the required top-level directories exist inside `~/.claude/`.
Required directories: `skills/`, `openspec/`, `ai-context/`, `memory/`, `hooks/`.

#### Scenario: all required directories are present — no finding

- **GIVEN** `~/.claude/skills/`, `~/.claude/openspec/`, `~/.claude/ai-context/`,
  `~/.claude/memory/`, and `~/.claude/hooks/` all exist
- **WHEN** Check 1 runs
- **THEN** no finding is recorded for this check

#### Scenario: a required directory is absent — HIGH finding

- **GIVEN** one or more of the required directories does not exist in `~/.claude/`
- **WHEN** Check 1 runs
- **THEN** a HIGH finding is recorded for each missing directory:
  "Required directory missing: ~/.claude/<dir>/"
- **AND** the remediation hint reads: "Run install.sh from the agent-config repo"

#### Scenario: CLAUDE.md file absent from runtime root — HIGH finding

- **GIVEN** `~/.claude/CLAUDE.md` does not exist
- **WHEN** Check 1 runs
- **THEN** a HIGH finding is recorded: "CLAUDE.md missing from ~/.claude/"
- **AND** the remediation hint reads: "Run install.sh from the agent-config repo"

---

### Requirement: Check 2 — skill deployment completeness

For every skill directory found in the source repo's `skills/` folder, the skill MUST
verify that a corresponding directory exists in `~/.claude/skills/`. A skill is considered
deployed if its directory exists; the presence of `SKILL.md` inside it is MUST be verified too.

#### Scenario: all source skills are deployed — no finding

- **GIVEN** every directory under `skills/` (source) has a matching directory under
  `~/.claude/skills/`
- **AND** every matched directory contains a `SKILL.md` file
- **WHEN** Check 2 runs
- **THEN** no finding is recorded for this check

#### Scenario: a source skill directory is absent from runtime — HIGH finding

- **GIVEN** `skills/<name>/` exists in the source repo
- **AND** `~/.claude/skills/<name>/` does NOT exist
- **WHEN** Check 2 runs
- **THEN** a HIGH finding is recorded: "Skill '<name>' present in source but not deployed to ~/.claude/skills/"
- **AND** the remediation hint reads: "Run install.sh from the agent-config repo"

#### Scenario: a deployed skill directory is missing SKILL.md — MEDIUM finding

- **GIVEN** `~/.claude/skills/<name>/` exists
- **AND** `~/.claude/skills/<name>/SKILL.md` does NOT exist
- **WHEN** Check 2 runs
- **THEN** a MEDIUM finding is recorded: "Deployed skill '<name>' has no SKILL.md — directory may be empty or corrupt"
- **AND** the remediation hint reads: "Run install.sh to restore the skill file"

#### Scenario: Check 2 is skipped in global mode with no source repo detected

- **GIVEN** execution mode is `global`
- **AND** no source `skills/` directory is readable from the cwd
- **WHEN** Check 2 runs
- **THEN** it records an INFO note: "Source repo not detected — skill deployment completeness check skipped"
- **AND** no HIGH or MEDIUM findings are generated for this check

---

### Requirement: Check 3 — installation drift detection

The skill MUST compare the source repo's modification time with the runtime
`~/.claude/` directory's modification time to detect likely out-of-sync state.
Because no `.installed-at` metadata file currently exists, mtime is used as a proxy.
This check is explicitly imprecise; findings are capped at MEDIUM severity.

#### Scenario: source repo is newer than runtime — MEDIUM drift finding

- **GIVEN** the source repo root directory's mtime is more recent than `~/.claude/`'s mtime
- **WHEN** Check 3 runs
- **THEN** a MEDIUM finding is recorded: "Possible installation drift — source repo appears newer than ~/.claude/ (mtime proxy)"
- **AND** the finding includes both timestamps in ISO 8601 format
- **AND** the remediation hint reads: "Run install.sh to re-sync runtime with source repo"

#### Scenario: runtime is newer or equal — no finding

- **GIVEN** `~/.claude/`'s mtime is equal to or more recent than the source repo root's mtime
- **WHEN** Check 3 runs
- **THEN** no finding is recorded for this check

#### Scenario: mtime comparison fails due to filesystem access error — INFO finding

- **GIVEN** the mtime of either the source repo root or `~/.claude/` cannot be read
- **WHEN** Check 3 runs
- **THEN** an INFO finding is recorded: "Could not read directory mtime for drift comparison — check skipped"
- **AND** no MEDIUM or HIGH finding is generated for this check

#### Scenario: Check 3 is skipped in global mode — INFO note

- **GIVEN** execution mode is `global`
- **AND** no source repo root is detected
- **WHEN** Check 3 runs
- **THEN** an INFO note is recorded: "No source repo detected — drift check skipped"

---

### Requirement: Check 4 — orphaned artifact detection

The skill MUST identify files and directories in `~/.claude/` that are not traceable
to the source repo. An artifact is orphaned if its name matches none of the expected
top-level items derived from the source repo contents plus the known runtime-only
artifacts (`CLAUDE.md`, `settings.json`, `claude-folder-audit-report.md`,
`.installed-at` if introduced in future).

#### Scenario: no orphaned artifacts found — no finding

- **GIVEN** every file and directory directly under `~/.claude/` matches an expected
  source repo item or known runtime-only artifact
- **WHEN** Check 4 runs
- **THEN** no finding is recorded for this check

#### Scenario: unexpected file found at runtime root — MEDIUM finding

- **GIVEN** a file or directory exists directly under `~/.claude/` that does not match
  any source repo item or known runtime-only artifact
- **WHEN** Check 4 runs
- **THEN** a MEDIUM finding is recorded for each unexpected item:
  "Unexpected item in ~/.claude/: <name> — possible manual edit or stale artifact"
- **AND** the remediation hint reads: "Review manually; run install.sh if this file should not exist; do NOT delete without inspection"
- **AND** the severity is capped at MEDIUM regardless of how many unexpected items exist

#### Scenario: openspec/changes/ items in runtime are reported as work-in-progress, not orphans

- **GIVEN** `~/.claude/openspec/changes/` contains subdirectories not present in the source repo
- **WHEN** Check 4 runs
- **THEN** these are NOT classified as orphaned artifacts
- **AND** they are reported as an INFO note: "Work-in-progress SDD change directories found in runtime openspec/changes/"

---

### Requirement: Check 5 — scope tier compliance

The skill MUST detect skills duplicated across the global tier (`~/.claude/skills/`) and
project-local tier (`.claude/skills/` relative to the cwd). It MUST also detect any
project-local skills that are missing from the source repo.

#### Scenario: a skill exists in both global and project-local tiers — LOW finding

- **GIVEN** `~/.claude/skills/<name>/` exists (global tier)
- **AND** `.claude/skills/<name>/` exists relative to the current working directory (project-local tier)
- **WHEN** Check 5 runs
- **THEN** a LOW finding is recorded: "Skill '<name>' exists in both global (~/.claude/skills/) and project-local (.claude/skills/) tiers"
- **AND** the finding notes: "This is expected for intentional global overrides; verify the intended tier is active"
- **AND** the remediation hint reads: "Confirm which tier is authoritative for this project; consult ADR 008"

#### Scenario: no project-local .claude/skills/ directory exists — Check 5 partial skip

- **GIVEN** no `.claude/skills/` directory exists relative to the current working directory
- **WHEN** Check 5 runs
- **THEN** the skill records an INFO note: "No project-local .claude/skills/ found — scope tier compliance check skipped for project-local tier"
- **AND** only the global tier contents are listed (no findings generated)

#### Scenario: project-local skill not present in source repo skills/ — MEDIUM finding

- **GIVEN** `.claude/skills/<name>/` exists in the project-local tier
- **AND** `skills/<name>/` does NOT exist in the source repo (global catalog)
- **WHEN** Check 5 runs
- **THEN** a MEDIUM finding is recorded: "Project-local skill '<name>' has no counterpart in the global catalog (skills/)"
- **AND** the remediation hint reads: "If this is intentional, register the skill in CLAUDE.md; if not, consider adding it to skills/"

---

### Requirement: the skill MUST NOT create, modify, or delete any file other than the report

The `claude-folder-audit` skill is strictly read-only during its audit execution phase.
The only file write permitted is the report output to `~/.claude/claude-folder-audit-report.md`.

#### Scenario: skill execution creates no files except the report

- **GIVEN** the skill is invoked and completes all 5 checks successfully
- **WHEN** execution finishes
- **THEN** the only file written is `~/.claude/claude-folder-audit-report.md`
- **AND** no source repo file, no `~/.claude/` skill, no `CLAUDE.md`, and no other
  runtime file is modified or deleted

#### Scenario: report file overwrites previous run on re-execution

- **GIVEN** `~/.claude/claude-folder-audit-report.md` already exists from a previous run
- **WHEN** the skill is run again
- **THEN** the existing report is overwritten (not appended)
- **AND** the new report contains only findings from the current run

---

---

### Requirement: project mode — Check P1 — CLAUDE.md presence and Skills Registry

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the skill MUST verify that `.claude/CLAUDE.md` exists in the project
root AND that it contains a Skills Registry section (identified by the heading
`## Skills Registry` or the presence of a `~/.claude/skills/` or `.claude/skills/` path pattern).

#### Scenario: .claude/CLAUDE.md is present and contains a Skills Registry section — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists at the project root
- **AND** the file contains a line matching `## Skills Registry` or at least one path pattern `~/.claude/skills/` or `.claude/skills/`
- **WHEN** Check P1 runs
- **THEN** no finding is recorded for this check

#### Scenario: .claude/CLAUDE.md is absent — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` does NOT exist at the project root
- **WHEN** Check P1 runs
- **THEN** a HIGH finding is recorded: "Missing .claude/CLAUDE.md — project Claude configuration not found"
- **AND** the remediation hint reads: "Run /project-setup or create .claude/CLAUDE.md and register skills"

#### Scenario: .claude/CLAUDE.md exists but has no Skills Registry section — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the file contains no `## Skills Registry` heading and no `~/.claude/skills/` or `.claude/skills/` path patterns
- **WHEN** Check P1 runs
- **THEN** a HIGH finding is recorded: "Skills Registry section not found in .claude/CLAUDE.md"
- **AND** the remediation hint reads: "Add a ## Skills Registry section to .claude/CLAUDE.md and register all skills used by this project"

---

### Requirement: project mode — Check P2 — global-path skill registrations reachability

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the skill MUST read all global-path skill registrations from
`.claude/CLAUDE.md` (path pattern: `~/.claude/skills/<name>/SKILL.md`) and verify that
each referenced `SKILL.md` is actually present at the expanded runtime path.

#### Scenario: all globally-registered skills are present at runtime — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists one or more global-path skill entries
- **AND** each referenced `SKILL.md` exists at the expanded path on disk
- **WHEN** Check P2 runs
- **THEN** no finding is recorded for this check

#### Scenario: a globally-registered skill's SKILL.md is absent from the runtime path — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists `~/.claude/skills/<name>/SKILL.md`
- **AND** the file does NOT exist at the expanded path
- **WHEN** Check P2 runs
- **THEN** a HIGH finding is recorded: "Global skill '<name>' registered in .claude/CLAUDE.md is not deployed at ~/.claude/skills/<name>/SKILL.md"
- **AND** the remediation hint reads: "Run install.sh from the agent-config repo to deploy missing global skills"

#### Scenario: .claude/CLAUDE.md has no global-path registrations — P2 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` contains no `~/.claude/skills/` path patterns
- **WHEN** Check P2 runs
- **THEN** an INFO note is recorded: "No global-path skill registrations found in .claude/CLAUDE.md — Check P2 skipped"
- **AND** no HIGH or MEDIUM finding is generated

#### Scenario: P2 is skipped when P1 recorded that CLAUDE.md is absent — INFO note

- **GIVEN** execution mode is `project`
- **AND** Check P1 recorded a HIGH finding for missing `.claude/CLAUDE.md`
- **WHEN** Check P2 runs
- **THEN** an INFO note is recorded: "Check P2 skipped — .claude/CLAUDE.md not found (see P1 finding)"
- **AND** no HIGH or MEDIUM finding is generated

---

### Requirement: project mode — Check P3 — local-path skill registrations reachability

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the skill MUST read all local-path skill registrations from
`.claude/CLAUDE.md` (path pattern: `.claude/skills/<name>/SKILL.md`) and verify that
each referenced `SKILL.md` exists on disk relative to CWD.

#### Scenario: all locally-registered skills have their SKILL.md on disk — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists one or more local-path skill entries
- **AND** each referenced `SKILL.md` exists at `<cwd>/.claude/skills/<name>/SKILL.md`
- **WHEN** Check P3 runs
- **THEN** no finding is recorded for this check

#### Scenario: a locally-registered skill's SKILL.md is absent from disk — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists `.claude/skills/<name>/SKILL.md`
- **AND** the file does NOT exist at `<cwd>/.claude/skills/<name>/SKILL.md`
- **WHEN** Check P3 runs
- **THEN** a HIGH finding is recorded: "Local skill '<name>' registered in .claude/CLAUDE.md is missing on disk at .claude/skills/<name>/SKILL.md"
- **AND** the remediation hint reads: "Create the skill file at .claude/skills/<name>/SKILL.md or remove the registration from .claude/CLAUDE.md"

#### Scenario: .claude/CLAUDE.md has no local-path registrations — P3 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` contains no `.claude/skills/` path patterns
- **WHEN** Check P3 runs
- **THEN** an INFO note is recorded: "No local-path skill registrations found in .claude/CLAUDE.md — Check P3 skipped"
- **AND** no HIGH or MEDIUM finding is generated

#### Scenario: P3 is skipped when P1 recorded that CLAUDE.md is absent — INFO note

- **GIVEN** execution mode is `project`
- **AND** Check P1 recorded a HIGH finding for missing `.claude/CLAUDE.md`
- **WHEN** Check P3 runs
- **THEN** an INFO note is recorded: "Check P3 skipped — .claude/CLAUDE.md not found (see P1 finding)"
- **AND** no HIGH or MEDIUM finding is generated

---

### Requirement: project mode — Check P4 — orphaned local skills detection

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the skill MUST enumerate all SKILL.md files found under
`.claude/skills/*/SKILL.md` (relative to CWD) and verify that each is registered
in `.claude/CLAUDE.md`.

#### Scenario: all local skills on disk are registered in CLAUDE.md — no finding

- **GIVEN** execution mode is `project`
- **AND** one or more `SKILL.md` files exist under `.claude/skills/`
- **AND** every skill directory name has a corresponding path entry in `.claude/CLAUDE.md`
- **WHEN** Check P4 runs
- **THEN** no finding is recorded for this check

#### Scenario: a local skill on disk is not registered in CLAUDE.md — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/skills/<name>/SKILL.md` exists on disk
- **AND** there is no `.claude/skills/<name>/` path entry in `.claude/CLAUDE.md`
- **WHEN** Check P4 runs
- **THEN** a MEDIUM finding is recorded: "Local skill '<name>' exists on disk at .claude/skills/<name>/SKILL.md but is not registered in .claude/CLAUDE.md"
- **AND** the remediation hint reads: "Add .claude/skills/<name>/SKILL.md to the Skills Registry in .claude/CLAUDE.md, or remove the skill directory if it is no longer needed"

#### Scenario: no .claude/skills/ directory exists — P4 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** no `.claude/skills/` directory exists relative to CWD
- **WHEN** Check P4 runs
- **THEN** an INFO note is recorded: "No .claude/skills/ directory found — Check P4 skipped"
- **AND** no finding is generated

#### Scenario: .claude/skills/ directory is empty — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/skills/` directory exists but contains no subdirectories with a `SKILL.md`
- **WHEN** Check P4 runs
- **THEN** an INFO note is recorded: "No local skill files found under .claude/skills/ — nothing to check"
- **AND** no finding is generated

---

### Requirement: project mode — Check P5 — scope tier overlap detection

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*

In `project` mode, the skill MUST detect any skill name that appears in both the
project-local tier (`.claude/skills/<name>/`) and the global tier (`~/.claude/skills/<name>/`).
Such overlap is not an error but SHOULD be flagged as a LOW concern for intentional review.

#### Scenario: a skill name appears in both tiers — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/skills/<name>/` exists relative to CWD
- **AND** `~/.claude/skills/<name>/` also exists at the global runtime path
- **WHEN** Check P5 runs
- **THEN** a LOW finding is recorded: "Skill '<name>' exists in both project-local (.claude/skills/) and global (~/.claude/skills/) tiers"
- **AND** the finding notes: "Project-local skills shadow global ones; verify which tier is intentional for this project"
- **AND** the remediation hint reads: "Confirm intended tier; consult ADR 008 for the two-tier placement model"

#### Scenario: no overlap between tiers — no finding

- **GIVEN** execution mode is `project`
- **AND** every skill name under `.claude/skills/` is absent from `~/.claude/skills/`
- **WHEN** Check P5 runs
- **THEN** no finding is recorded for this check

#### Scenario: no .claude/skills/ directory — P5 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** no `.claude/skills/` directory exists relative to CWD
- **WHEN** Check P5 runs
- **THEN** an INFO note is recorded: "No .claude/skills/ directory found — Check P5 (scope tier overlap) skipped"
- **AND** no finding is generated

#### Scenario: global runtime path ~/.claude/skills/ cannot be read — INFO note

- **GIVEN** execution mode is `project`
- **AND** `~/.claude/skills/` is not accessible
- **WHEN** Check P5 runs
- **THEN** an INFO note is recorded: "Global tier ~/.claude/skills/ not accessible — P5 scope tier overlap check skipped"
- **AND** no LOW or higher finding is generated

---

### Requirement: project mode — checks MUST all execute even when earlier checks find HIGH issues

*(Added in: 2026-03-03 by change "claude-folder-audit-project-mode")*
*(Modified in: 2026-03-03 by change "enhance-claude-folder-audit" — extended to cover 8 checks P1–P8)*

In `project` mode, the skill MUST run all 8 checks (P1 through P8) regardless of
findings from earlier checks. The only exception is the explicit skip behavior when P1
detects a missing `.claude/CLAUDE.md` — subsequent checks that depend on parsing
CLAUDE.md MUST record an INFO skip note and continue.

#### Scenario: P1 produces HIGH but P4, P5, P6, P7, P8 still run *(modified)*

- **GIVEN** execution mode is `project`
- **AND** Check P1 records a HIGH finding (CLAUDE.md absent or missing Skills Registry)
- **WHEN** all checks complete
- **THEN** Checks P2 and P3 each record an INFO skip note
- **AND** Checks P4, P5, P6, P7, and P8 still execute against the filesystem
- **AND** the report includes output sections for all 8 checks (P1 through P8)

---

### Requirement: Check P1 MUST additionally validate CLAUDE.md content quality

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

After confirming `.claude/CLAUDE.md` exists and has a Skills Registry section (existing P1
requirement), the skill MUST read the file's content and perform sub-checks for mandatory
sections, minimum content length, and SDD command references. These sub-checks extend P1
and use the same check section in the report.

**Section detection rule**: a section is present when at least one line in the file starts
with `## <section-name>` (top-level markdown heading). This rule applies across all
content-quality checks in P1, P2, P3, P6, P7, and P8. Lines inside fenced code blocks
(```` ``` ````) are NOT considered section headers for this purpose.

#### Scenario: CLAUDE.md contains all mandatory sections — no finding from P1 sub-checks

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` is present and passes the existing P1 existence and Skills Registry check
- **AND** the file contains lines starting with `## Tech Stack`, `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`, and `## Skills Registry` (or `## Stack` as an accepted alias for `## Tech Stack`)
- **AND** the file has more than 50 lines
- **AND** the file contains at least one of `/sdd-ff` or `/sdd-new` anywhere in its content
- **WHEN** Check P1 runs
- **THEN** no finding is recorded from the content sub-checks
- **AND** the P1 section in the report notes all mandatory sections are present

#### Scenario: CLAUDE.md is missing a mandatory section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists and has a Skills Registry section
- **AND** one or more of the following section headings are absent: `## Tech Stack` (or `## Stack`), `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`
- **WHEN** Check P1 runs
- **THEN** a MEDIUM finding is recorded for each missing section: "CLAUDE.md is missing mandatory section: <section-name>"
- **AND** the remediation hint reads: "Add the missing section to .claude/CLAUDE.md — refer to the global CLAUDE.md in the agent-config repo as a template"

#### Scenario: CLAUDE.md has fewer than 30 lines — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the total line count of the file is fewer than 30
- **WHEN** Check P1 runs
- **THEN** a MEDIUM finding is recorded: "CLAUDE.md appears too short (<30 lines) — may be a stub or placeholder"
- **AND** the remediation hint reads: "Populate .claude/CLAUDE.md with at minimum a ## Tech Stack, ## Architecture, ## Unbreakable Rules, ## Plan Mode Rules, and ## Skills Registry section"

#### Scenario: CLAUDE.md has between 30 and 50 lines — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the total line count is between 30 and 50 (inclusive)
- **WHEN** Check P1 runs
- **THEN** a LOW finding is recorded: "CLAUDE.md is short (30–50 lines) — may not contain enough context"
- **AND** the remediation hint reads: "Consider expanding .claude/CLAUDE.md with richer context — aim for >50 lines"

#### Scenario: CLAUDE.md has no SDD command references — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the file contains neither `/sdd-ff` nor `/sdd-new` anywhere in its content
- **WHEN** Check P1 runs
- **THEN** a LOW finding is recorded: "CLAUDE.md has no SDD command references (/sdd-ff, /sdd-new) — SDD workflow may not be configured"
- **AND** the remediation hint reads: "Add SDD commands to the Available Commands section; consult the global CLAUDE.md for the standard SDD command table"

#### Scenario: Skills Registry section exists but contains no skill path entries — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` contains a `## Skills Registry` heading
- **AND** no line in the file matches `~/.claude/skills/` or `.claude/skills/` path patterns
- **WHEN** Check P1 runs
- **THEN** a LOW finding is recorded: "CLAUDE.md has a ## Skills Registry section but contains no skill path entries"
- **AND** the remediation hint reads: "Register skills by adding path entries under ## Skills Registry — use ~/.claude/skills/<name>/SKILL.md for global skills or .claude/skills/<name>/SKILL.md for local ones"

---

### Requirement: Check P2 and P3 MUST additionally validate SKILL.md frontmatter and section contracts

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

After confirming a SKILL.md exists (existing P2/P3 reachability requirement), the skill MUST read each SKILL.md file and apply two-stage content quality sub-checks:

- **Stage 1 — Frontmatter**: verify YAML frontmatter block is present, and `format:` field is present with a valid value.
- **Stage 2 — Section contract**: based on the detected (or defaulted) `format:` value, verify that all required sections are present using the section detection rule.

Section contracts (authoritative source: `docs/format-types.md`):
- `procedural` (or absent format): requires `**Triggers**` or `## Triggers`, `## Process` or at least one `### Step N` heading, and `## Rules`
- `reference`: requires `**Triggers**` or `## Triggers`, `## Patterns` or `## Examples`, and `## Rules`
- `anti-pattern`: requires `**Triggers**` or `## Triggers`, `## Anti-patterns`, and `## Rules`

These sub-checks apply to all SKILL.md files verified during P2 (global-path registrations) and P3 (local-path registrations). P4 orphan detection does NOT trigger these sub-checks — orphaned skills are structural findings, not content findings.

#### Scenario: SKILL.md has valid frontmatter and all required sections — no finding from sub-checks

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file passes the existing P2 or P3 reachability check
- **AND** the file begins with a `---` YAML frontmatter block
- **AND** the frontmatter contains a `format:` field with value `procedural`, `reference`, or `anti-pattern`
- **AND** the file contains all required sections for the declared format type
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** no finding is recorded from the content sub-checks for this SKILL.md

#### Scenario: SKILL.md has no YAML frontmatter block — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file passes the P2 or P3 reachability check
- **AND** the file does NOT begin with a `---` line
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a MEDIUM finding is recorded: "SKILL.md for skill '<name>' is missing YAML frontmatter — the file must begin with a '---' block"
- **AND** the remediation hint reads: "Add a YAML frontmatter block (---) with at minimum name:, description:, and format: fields"
- **AND** subsequent frontmatter and section contract sub-checks for this SKILL.md are skipped

#### Scenario: SKILL.md frontmatter is missing the format: field — LOW finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file has a valid frontmatter block
- **AND** the frontmatter does NOT contain a `format:` field
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a LOW finding is recorded: "SKILL.md for skill '<name>' has no 'format:' field in frontmatter — defaulting to 'procedural'"
- **AND** the remediation hint reads: "Add 'format: procedural' (or 'reference' or 'anti-pattern') to the SKILL.md frontmatter"
- **AND** the section contract check proceeds using `procedural` as the default format

#### Scenario: SKILL.md frontmatter has an unrecognized format: value — LOW finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file has a valid frontmatter block
- **AND** the frontmatter contains a `format:` field with a value other than `procedural`, `reference`, or `anti-pattern`
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a LOW finding is recorded: "SKILL.md for skill '<name>' has unrecognized format value '<value>' — defaulting to 'procedural'"
- **AND** the remediation hint reads: "Valid format values are: procedural, reference, anti-pattern"
- **AND** the section contract check proceeds using `procedural` as the default format

#### Scenario: procedural SKILL.md is missing a required section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md has `format: procedural` (or defaulted to procedural)
- **AND** one or more of `**Triggers**`/`## Triggers`, `## Process`/`### Step N`, `## Rules` are absent
- **WHEN** Checks P2/P3 run the section contract sub-check
- **THEN** a MEDIUM finding is recorded for each missing required element: "SKILL.md for skill '<name>' (procedural) is missing required section: <section>"
- **AND** the remediation hint reads: "Add the missing section to the SKILL.md — procedural format requires: **Triggers**, ## Process (or ### Step N steps), and ## Rules"

#### Scenario: reference SKILL.md is missing a required section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md has `format: reference`
- **AND** one or more of `**Triggers**`/`## Triggers`, `## Patterns`/`## Examples`, `## Rules` are absent
- **WHEN** Checks P2/P3 run the section contract sub-check
- **THEN** a MEDIUM finding is recorded for each missing required element: "SKILL.md for skill '<name>' (reference) is missing required section: <section>"
- **AND** the remediation hint reads: "Add the missing section to the SKILL.md — reference format requires: **Triggers**, ## Patterns or ## Examples, and ## Rules"

#### Scenario: anti-pattern SKILL.md is missing a required section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md has `format: anti-pattern`
- **AND** one or more of `**Triggers**`/`## Triggers`, `## Anti-patterns`, `## Rules` are absent
- **WHEN** Checks P2/P3 run the section contract sub-check
- **THEN** a MEDIUM finding is recorded for each missing required element: "SKILL.md for skill '<name>' (anti-pattern) is missing required section: <section>"
- **AND** the remediation hint reads: "Add the missing section to the SKILL.md — anti-pattern format requires: **Triggers**, ## Anti-patterns, and ## Rules"

#### Scenario: SKILL.md body (post-frontmatter) has fewer than 30 lines — LOW finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file passes the P2 or P3 reachability check
- **AND** after stripping the frontmatter block, the remaining lines number fewer than 30
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a LOW finding is recorded: "SKILL.md for skill '<name>' has very short body (<30 lines post-frontmatter) — may be a stub"
- **AND** the remediation hint reads: "Review and populate this SKILL.md — stubs should have a plan or be removed"

#### Scenario: SKILL.md body contains TODO: in a required section area — INFO note

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file contains one or more lines with `TODO:` anywhere in the file content
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** an INFO note is recorded: "SKILL.md for skill '<name>' contains TODO: markers — may be a work-in-progress"

---

### Requirement: Check P6 MUST verify the ai-context/ memory layer in project mode

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

The skill MUST check for the presence of the `ai-context/` directory and its five required
core files in project mode. If the directory is absent, a MEDIUM finding is recorded.
If the directory is present but missing core files, a LOW finding is recorded per missing file.

Required core files: `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`.

#### Scenario: ai-context/ directory is absent entirely — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/` does NOT exist
- **WHEN** Check P6 runs
- **THEN** a MEDIUM finding is recorded: "ai-context/ directory not found — project memory layer is absent"
- **AND** the remediation hint reads: "Run /memory-init to generate the ai-context/ layer for this project"
- **AND** the five core-file checks are skipped (the directory does not exist)

#### Scenario: ai-context/ exists and all five core files are present — no finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/` exists
- **AND** all five files `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md` exist under `<cwd>/ai-context/`
- **WHEN** Check P6 runs
- **THEN** no finding is recorded for this check

#### Scenario: ai-context/ exists but one or more core files are missing — LOW finding per missing file

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/` exists
- **AND** one or more of the five required core files are not present
- **WHEN** Check P6 runs
- **THEN** a LOW finding is recorded for each missing file: "ai-context/<filename> is missing"
- **AND** the remediation hint reads: "Run /memory-init or manually create ai-context/<filename> to restore the project memory layer"

#### Scenario: a core ai-context/ file has fewer than 10 lines — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/<filename>` exists
- **AND** the file has fewer than 10 lines of content
- **WHEN** Check P6 runs
- **THEN** an INFO note is recorded: "ai-context/<filename> is very short (<10 lines) — may not contain useful context"

---

### Requirement: Check P7 MUST verify the ai-context/features/ layer in project mode (ADR-015 V2)

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

The skill MUST check for the presence of `ai-context/features/` and the quality of any
non-template feature files found within it. The `_template.md` file and any file whose
name starts with an underscore MUST be excluded from all quality checks.

Required sections per feature file (authoritative source: `ai-context/features/_template.md`):
1. `## Domain Overview`
2. `## Business Rules and Invariants`
3. `## Data Model Summary`
4. `## Integration Points`
5. `## Decision Log`
6. `## Known Gotchas`

P7 is advisory — feature files are voluntarily authored. Absence of `ai-context/features/` is
an INFO observation, not a MEDIUM finding. Per ADR-015 non-blocking design intent, this
check MUST NOT produce findings above LOW severity.

#### Scenario: ai-context/features/ directory is absent — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/` does NOT exist
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "ai-context/features/ not found — feature-domain knowledge layer not initialized for this project"
- **AND** no LOW or higher finding is recorded

#### Scenario: ai-context/features/ exists but contains only the template file — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/` exists
- **AND** the only file present is `_template.md` (or all files start with `_`)
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "ai-context/features/ contains only the template file — no feature domain knowledge files authored yet"
- **AND** no LOW or higher finding is recorded

#### Scenario: a non-template feature file contains all six required sections — no finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/<name>.md` exists and does not start with `_`
- **AND** the file contains lines starting with `## Domain Overview`, `## Business Rules and Invariants`, `## Data Model Summary`, `## Integration Points`, `## Decision Log`, and `## Known Gotchas`
- **WHEN** Check P7 runs
- **THEN** no finding is recorded for this feature file

#### Scenario: a non-template feature file is missing one or more required sections — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/<name>.md` exists and does not start with `_`
- **AND** one or more of the six required sections are absent
- **WHEN** Check P7 runs
- **THEN** a LOW finding is recorded for each missing section: "Feature file 'ai-context/features/<name>.md' is missing section: <section-name>"
- **AND** the remediation hint reads: "Add the missing section to the feature file — refer to ai-context/features/_template.md for the required structure"

#### Scenario: a non-template feature file has fewer than 30 lines — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/<name>.md` exists and does not start with `_`
- **AND** the file has fewer than 30 lines
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "Feature file 'ai-context/features/<name>.md' is very short (<30 lines) — likely a stub not yet populated"

#### Scenario: _template.md is present — INFO note confirming template presence

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/_template.md` exists
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "ai-context/features/_template.md is present"
- **AND** the template file is NOT subjected to section quality checks

---

### Requirement: Check P8 MUST enumerate the .claude/ folder for unexpected items

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

The skill MUST list all items (files and directories) directly under `<cwd>/.claude/` and
compare them against the known expected set. Any item not in the expected set MUST be
flagged as MEDIUM. The `hooks/` directory, if present, must have non-empty script files.

Known expected items in `.claude/`:
`CLAUDE.md`, `skills/`, `audit-report.md`, `claude-folder-audit-report.md`,
`settings.json`, `settings.local.json`, `openspec/`, `ai-context/`, `hooks/`

#### Scenario: .claude/ contains only expected items — no finding

- **GIVEN** execution mode is `project`
- **AND** every item directly under `<cwd>/.claude/` is in the known expected set
- **WHEN** Check P8 runs
- **THEN** no finding is recorded
- **AND** the P8 section in the report notes the inventory count: "N item(s) found, all expected"

#### Scenario: .claude/ contains an item not in the expected set — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a file or directory exists directly under `<cwd>/.claude/` whose name does NOT appear in the known expected set
- **WHEN** Check P8 runs
- **THEN** a MEDIUM finding is recorded for each unexpected item: "Unexpected item in .claude/: '<name>' — possible manual edit or stale artifact"
- **AND** the remediation hint reads: "Review the item manually; if it should not be there, remove it; if it is intentional, consider documenting it in .claude/CLAUDE.md"

#### Scenario: hooks/ directory is present but contains empty script files — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/.claude/hooks/` exists
- **AND** one or more `.js` or `.sh` files within it have zero bytes (empty content)
- **WHEN** Check P8 runs
- **THEN** a LOW finding is recorded for each empty hook file: "Hook script '.claude/hooks/<filename>' is empty — likely a placeholder"
- **AND** the remediation hint reads: "Populate the hook script with valid logic or remove it if not needed"

#### Scenario: hooks/ directory is present with non-empty scripts — no finding from hooks sub-check

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/.claude/hooks/` exists
- **AND** all `.js` and `.sh` files within it are non-empty
- **WHEN** Check P8 runs
- **THEN** no finding is recorded from the hooks sub-check

#### Scenario: hooks/ directory is absent — no finding from hooks sub-check

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/.claude/hooks/` does NOT exist
- **WHEN** Check P8 runs
- **THEN** no finding is recorded for the hooks sub-check
- **AND** an INFO note is recorded: "No hooks/ directory found in .claude/ — hook execution is not configured for this project"

---

### Requirement: all project-mode checks MUST continue to run even if P1 content sub-checks fail

*(Added in: 2026-03-03 by change "enhance-claude-folder-audit")*

All 8 project-mode checks (P1 through P8) MUST run to completion regardless of findings
from earlier checks. The existing behavior — P2/P3 record an INFO skip note when CLAUDE.md
is absent — is preserved and is the ONLY exception to this rule.

#### Scenario: P1 MEDIUM content finding does not block P6, P7, P8

- **GIVEN** execution mode is `project`
- **AND** Check P1 records a MEDIUM finding (e.g., missing mandatory section in CLAUDE.md)
- **WHEN** all checks complete
- **THEN** Checks P6, P7, and P8 each still execute against the filesystem
- **AND** the report includes output sections for all 8 checks (P1 through P8)

---

## Rules

- The skill MUST run all checks even if earlier checks produce HIGH findings; it MUST NOT abort early
- Severity caps: drift check (Check 3) findings MUST NOT exceed MEDIUM; manual overrides (Check 4)
  MUST NOT exceed MEDIUM; Check P5 (scope tier overlap) MUST NOT exceed LOW; Check P6 MUST NOT exceed MEDIUM; Check P7 MUST NOT exceed LOW; Check P8 MUST NOT exceed MEDIUM; P1 Phase C content sub-checks MUST NOT exceed MEDIUM; P2/P3 Phase C content sub-checks MUST NOT exceed MEDIUM
- The skill MUST document all detected limitations inline in the report (mtime proxy, no .installed-at, etc.)
- Mode detection MUST run before any check; if mode cannot be determined, default to `global` mode
- The skill MUST NOT emit any finding that recommends deleting a file in `~/.claude/` without human review
- On Windows, all path operations MUST use the expanded `%USERPROFILE%` value; tilde expansion
  MUST NOT rely on shell interpretation (use explicit env var lookup)
- In `project` mode, the skill MUST NOT audit `~/.claude/` as the primary target; references to `~/.claude/` are only for P2 and P5 reachability checks
- All 8 project-mode checks (P1–P8) MUST run to completion; the skill MUST NOT abort after the first HIGH finding
- When `.claude/CLAUDE.md` is absent, P2 and P3 MUST each record an INFO skip note; P4, P5, P6, P7, and P8 MUST still execute against the filesystem
- Mode detection MUST remain deterministic: given the same CWD state, the skill MUST always select the same mode
- The `name:` field is NOT a required frontmatter check in P2/P3 content sub-checks — only `format:` field validity is validated in Stage 1
