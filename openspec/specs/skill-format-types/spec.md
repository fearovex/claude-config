# Spec: skill-format-types

Change: skill-format-types
Date: 2026-03-01

## Overview

This spec describes the observable behavior of the skill format type system introduced
by the `skill-format-types` change. It covers: the canonical format type definitions,
the `format:` frontmatter field convention, and the reference document that serves as
the authoritative contract for all tooling.

---

## Requirements

### Requirement: docs/format-types.md exists and defines at least 2 canonical formats

`docs/format-types.md` MUST exist in the project and MUST define at least 2 canonical
skill format types with their formal names and required section contracts.

#### Scenario: docs/format-types.md is present after this change

- **GIVEN** `skills/skill-format-types` change has been applied
- **WHEN** a developer reads the repository at the project root
- **THEN** `docs/format-types.md` is present
- **AND** the file defines at least 2 canonical format types: `procedural` and `reference`
- **AND** each format type entry lists its formal name, its purpose, and the required
  sections a SKILL.md must contain when declared as that type

#### Scenario: docs/format-types.md defines Format A (Procedural) with required sections

- **GIVEN** `docs/format-types.md` exists
- **WHEN** the section for `procedural` format is read
- **THEN** the document states that a `procedural` skill MUST contain a `## Process` section
- **AND** the document states that `procedural` is the format for orchestrator,
  meta-tool, and SDD phase skills
- **AND** the document states that `procedural` is the default when `format:` is absent

#### Scenario: docs/format-types.md defines Format B (Reference) with required sections

- **GIVEN** `docs/format-types.md` exists
- **WHEN** the section for `reference` format is read
- **THEN** the document states that a `reference` skill MUST contain a `## Patterns`
  or `## Examples` section (at least one of the two)
- **AND** the document states that `reference` is the format for technology and
  library skills

#### Scenario: docs/format-types.md defines Format C (Anti-pattern) when it is included

- **GIVEN** `docs/format-types.md` exists
- **WHEN** the section for `anti-pattern` format is read (if present)
- **THEN** the document states that an `anti-pattern` skill MUST contain an
  `## Anti-patterns` section
- **AND** the document states that `anti-pattern` is the format for skills structured
  as catalogs of known bad practices
- **AND** if Format C is omitted from the file, the document notes that anti-pattern
  skills MAY declare `format: reference` as the nearest equivalent

---

### Requirement: SKILL.md files MAY declare a format: field in their YAML frontmatter

A `SKILL.md` file MUST be able to declare `format: procedural`, `format: reference`,
or `format: anti-pattern` in its YAML frontmatter. This declaration MUST be read by
validation tooling (project-audit D4/D9) to determine the applicable structural check.

#### Scenario: SKILL.md with format: procedural in frontmatter is recognized by tooling

- **GIVEN** a `SKILL.md` file begins with a YAML frontmatter block containing `format: procedural`
- **WHEN** `project-audit` runs D4 or D9 on that skill
- **THEN** the audit validates that the file has a `## Process` section
- **AND** the audit does NOT check for `## Patterns` or `## Examples`

#### Scenario: SKILL.md with format: reference in frontmatter is recognized by tooling

- **GIVEN** a `SKILL.md` file begins with a YAML frontmatter block containing `format: reference`
- **WHEN** `project-audit` runs D4 or D9 on that skill
- **THEN** the audit validates that the file has a `## Patterns` or `## Examples` section
- **AND** the audit does NOT check for `## Process` — its absence is NOT a finding

#### Scenario: SKILL.md with format: anti-pattern in frontmatter is recognized by tooling

- **GIVEN** a `SKILL.md` file begins with a YAML frontmatter block containing `format: anti-pattern`
- **WHEN** `project-audit` runs D4 or D9 on that skill
- **THEN** the audit validates that the file has an `## Anti-patterns` section
- **AND** the audit does NOT check for `## Process`

#### Scenario: SKILL.md without a format: field defaults to procedural validation

- **GIVEN** a `SKILL.md` file has no YAML frontmatter, or has frontmatter that does
  NOT include a `format:` key
- **WHEN** `project-audit` runs D4 or D9 on that skill
- **THEN** the audit applies the `procedural` check (requires `## Process`)
- **AND** this preserves backwards compatibility with all skills created before this change

#### Scenario: A reference skill with format: reference declared passes D4/D9

- **GIVEN** a `SKILL.md` (e.g., `react-19/SKILL.md`) has `format: reference` in its
  frontmatter
- **AND** the file has `## Patterns` or `## Examples` but no `## Process`
- **WHEN** `project-audit` runs D4 and D9 on that project
- **THEN** the skill passes structural validation — no finding is emitted for the
  absence of `## Process`
- **AND** no false-positive D4 or D9 MEDIUM/HIGH findings are generated for that skill

---

### Requirement: CLAUDE.md Rule 2 references the format type system

The unbreakable Rule 2 in both the global and project `CLAUDE.md` MUST be updated to
reference the format type system and the `format:` frontmatter field, so that the rule
accurately reflects the catalog's actual conventions.

#### Scenario: CLAUDE.md Rule 2 is updated after this change

- **GIVEN** the `skill-format-types` change has been applied and `install.sh` has been run
- **WHEN** `~/.claude/CLAUDE.md` is read and Rule 2 is found
- **THEN** Rule 2 states that every SKILL.md must declare a `format:` field (or defaults
  to `procedural`) and must meet the required section contract for its declared format
- **AND** Rule 2 references `docs/format-types.md` as the authoritative contract document
- **AND** Rule 2 no longer requires all skills unconditionally to have a `## Process` section

#### Scenario: Rule 2 change is backwards-compatible for procedural skills

- **GIVEN** an existing procedural skill (e.g., `sdd-apply/SKILL.md`) with no `format:`
  declaration
- **WHEN** Rule 2 is applied to that skill
- **THEN** the rule still passes because the default is `procedural`, which requires
  `## Process` — and the skill has it
- **AND** no corrective action is required for existing procedural skills

---

## Rules

- `docs/format-types.md` is the single source of truth for format type contracts;
  tooling MUST NOT embed a separate copy of the contract logic
- The `format:` field in SKILL.md frontmatter is optional — its absence MUST default
  to `procedural` for backwards compatibility
- Accepted values for `format:` are: `procedural`, `reference`, `anti-pattern`
  (any other value MUST be treated as `procedural` by tooling, with an INFO finding)
- Format declarations are advisory for skills with no frontmatter; tooling MUST NOT
  hard-block a skill from being used solely because `format:` is absent
- Adding `format:` declarations to all 44 existing skills is out of scope for this
  change — that migration is tracked separately
