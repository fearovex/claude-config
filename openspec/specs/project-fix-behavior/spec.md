# Spec: project-fix-behavior

Change: skill-scope-global-vs-project
Date: 2026-03-02

## Overview

This spec covers the observable behavior of `project-fix` with respect to skill placement.
Specifically, it defines the demoted behavior of the `move-to-global` disposition: it
transitions from an automated file-move operation to a purely informational recommendation.

---

## Requirements

### Requirement: project-fix does not automatically move local skills to the global catalog

`project-fix` MUST NOT automatically move or copy any skill file from `.claude/skills/`
to `~/.claude/skills/`. The `move-to-global` Phase 5 disposition MUST produce only a
human-readable recommendation comment in the fix output, with no file system side effects.

#### Scenario: project-fix produces a recommendation instead of moving a local skill

- **GIVEN** a project contains a skill at `.claude/skills/<name>/SKILL.md`
- **AND** the `audit-report.md` contains a `move-to-global` finding for that skill
- **WHEN** the user runs `/project-fix`
- **THEN** `project-fix` writes a recommendation in its output such as:
  "Skill '<name>' is project-local. To promote it to the global catalog, manually copy
  `.claude/skills/<name>/SKILL.md` to `~/.claude/skills/<name>/SKILL.md` in `agent-config`
  and run `install.sh`."
- **AND** no file is copied or moved by `project-fix`
- **AND** the skill file at `.claude/skills/<name>/SKILL.md` remains untouched

#### Scenario: project-fix fix output marks move-to-global items as informational

- **GIVEN** `audit-report.md` contains one or more `move-to-global` disposition entries
- **WHEN** `project-fix` generates its fix output
- **THEN** those entries are labeled as `[INFO]` or `[RECOMMENDATION]` rather than
  `[ACTION]` or `[FIX]`
- **AND** the fix summary does NOT count `move-to-global` items as automated corrections applied

#### Scenario: project-fix does not regress on its other automated fix behaviors

- **GIVEN** `audit-report.md` contains a mix of `move-to-global` entries and other
  correctable findings (missing sections, bad frontmatter, etc.)
- **WHEN** the user runs `/project-fix`
- **THEN** all non-`move-to-global` correctable findings are still applied automatically
- **AND** only the `move-to-global` entries are emitted as recommendations without action

---

### Requirement: project-fix informs the user of the two-tier model when move-to-global items are present

When `project-fix` encounters `move-to-global` items, it SHOULD include a brief explanation
of the two-tier skill model so the user can make an informed decision about promotion.

#### Scenario: project-fix explains the two-tier model alongside the recommendation

- **GIVEN** `audit-report.md` contains at least one `move-to-global` entry
- **WHEN** `project-fix` outputs its recommendations section
- **THEN** the output includes a note explaining that `.claude/skills/` is project-local
  (versioned in the repo) and `~/.claude/skills/` is machine-global (available across all
  projects but not visible to collaborators)
- **AND** the note is shown once per fix run, not once per skill

---

## Rules

- `project-fix` MUST NEVER write to `~/.claude/skills/` as part of an automated fix action
- The change applies only to the `move-to-global` disposition; all other `project-fix`
  Phase 5 automated behaviors are unchanged
- If the `move-to-global` disposition is removed from `audit-report.md` output entirely
  in a future change, this spec becomes superseded and should be archived
