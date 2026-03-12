# Spec: skill-placement

Change: skill-scope-global-vs-project
Date: 2026-03-02

## Overview

This spec describes the observable behavior of the two-tier skill placement model
introduced by the `skill-scope-global-vs-project` change.

The two tiers are:

| Tier | Path | Visibility |
|------|------|------------|
| Global | `~/.claude/skills/<name>/SKILL.md` | Owner's machine only |
| Project-local | `.claude/skills/<name>/SKILL.md` | Versioned in the repo — team-visible |

---

## Requirements

### Requirement: /skill-add defaults to project-local copy when invoked inside a project

When `/skill-add <name>` is invoked inside a project (any directory that is not
`agent-config`), `skill-add` MUST copy the skill file from the global catalog into
`.claude/skills/<name>/SKILL.md` within the current project directory by default.
The CLAUDE.md registry entry MUST use the local relative path `.claude/skills/<name>/SKILL.md`.

#### Scenario: /skill-add inside a project produces a local copy

- **GIVEN** the current working directory is a project (not `agent-config`)
- **AND** the skill `<name>` exists in the global catalog at `~/.claude/skills/<name>/SKILL.md`
- **WHEN** the user runs `/skill-add <name>` with no explicit strategy selection
- **THEN** the skill file is copied to `.claude/skills/<name>/SKILL.md` inside the project
- **AND** the CLAUDE.md Skills Registry receives a new entry whose path is `.claude/skills/<name>/SKILL.md`
- **AND** no entry pointing to `~/.claude/skills/<name>/SKILL.md` is added to CLAUDE.md

#### Scenario: /skill-add local copy is committed alongside project source code

- **GIVEN** `/skill-add <name>` has completed with a local copy at `.claude/skills/<name>/SKILL.md`
- **WHEN** the user runs `git add .claude/skills/<name>/SKILL.md && git commit`
- **THEN** the skill file is present in the repository history
- **AND** a collaborator who clones the repository finds the skill at `.claude/skills/<name>/SKILL.md`
  without any additional setup step

#### Scenario: /skill-add in agent-config does not produce a local copy

- **GIVEN** the current working directory is the `agent-config` meta-repo
- **WHEN** the user runs `/skill-add <name>`
- **THEN** `skill-add` follows its standard behavior for the meta-repo context
- **AND** no `.claude/skills/` directory is created inside `agent-config`

#### Scenario: /skill-add with explicit Option A still produces a global-path reference

- **GIVEN** the current working directory is a project (not `agent-config`)
- **AND** the user explicitly selects Option A (symbolic reference) during the `skill-add` interaction
- **WHEN** `skill-add` processes the explicit Option A selection
- **THEN** the CLAUDE.md registry entry uses `~/.claude/skills/<name>/SKILL.md`
- **AND** no file is copied into `.claude/skills/`
- **AND** `skill-add` SHOULD display a notice that the referenced skill will not be present
  for collaborators who clone the repository

#### Scenario: /skill-add when the skill does not exist in the global catalog

- **GIVEN** `~/.claude/skills/<name>/SKILL.md` does not exist
- **WHEN** the user runs `/skill-add <name>`
- **THEN** `skill-add` emits an error: "Skill '<name>' not found in global catalog at
  ~/.claude/skills/<name>/SKILL.md"
- **AND** no file is created and no CLAUDE.md entry is written

---

### Requirement: CLAUDE.md Skills Registry path format reflects the skill's tier

The Skills Registry section in CLAUDE.md MUST use path formats that accurately reflect
the placement of each skill:
- Project-local skills: `.claude/skills/<name>/SKILL.md` (relative path)
- Global-only references: `~/.claude/skills/<name>/SKILL.md`

Mixed path formats within the same registry are acceptable: a project may have both
local and global-reference entries.

#### Scenario: registry entry for a locally copied skill uses the local path

- **GIVEN** `/skill-add <name>` created a local copy at `.claude/skills/<name>/SKILL.md`
- **WHEN** Claude reads the Skills Registry in CLAUDE.md
- **THEN** the entry for `<name>` shows `.claude/skills/<name>/SKILL.md`
- **AND** Claude can load the skill from that path without requiring `~/.claude/`

#### Scenario: registry entries for global-only references retain the global path

- **GIVEN** a CLAUDE.md entry was created before this change with path `~/.claude/skills/<name>/SKILL.md`
- **WHEN** the user has not explicitly re-added the skill via the updated `skill-add`
- **THEN** the existing entry remains unchanged
- **AND** no automated migration alters existing registry entries

---

### Requirement: A collaborator cloning a project finds all locally added skills present

For any skill added via `/skill-add` using the default (local copy) strategy after this
change, a collaborator who clones the repository MUST be able to use the skill immediately
without installing the `agent-config` meta-repo or running `install.sh`.

#### Scenario: collaborator clone — skill available without install step

- **GIVEN** a repository contains `.claude/skills/<name>/SKILL.md` (added via the default strategy)
- **AND** the CLAUDE.md Skills Registry entry points to `.claude/skills/<name>/SKILL.md`
- **WHEN** a collaborator clones the repository and opens a Claude Code session
- **THEN** Claude can read `.claude/skills/<name>/SKILL.md` when the skill is triggered
- **AND** no "skill not found" or "file not found" error occurs for that skill

#### Scenario: collaborator clone — global-reference skills are not present locally

- **GIVEN** a repository contains a CLAUDE.md registry entry pointing to `~/.claude/skills/<name>/SKILL.md`
- **WHEN** a collaborator clones the repository and opens a Claude Code session
- **AND** the collaborator has not run `install.sh`
- **THEN** Claude will be unable to read that skill file
- **AND** this is the expected consequence of the explicit Option A choice by the original author

---

## Rules

- The default strategy for `/skill-add` inside any project (not `agent-config`) MUST produce
  a local copy — the user is never silently defaulted to Option A (global reference)
- The local copy operation MUST be idempotent: running `/skill-add <name>` a second time on a
  skill already present at `.claude/skills/<name>/SKILL.md` MUST NOT overwrite the existing file
  without explicit user confirmation
- Version drift between local copies and the global catalog is an accepted trade-off;
  `skill-add` SHOULD record the copy date (or the source global skill version) as a comment
  in the CLAUDE.md registry entry
- The `.claude/skills/` directory MUST be committed to the repository; no `.gitignore` rule
  should exclude it when skills are intentionally project-local
