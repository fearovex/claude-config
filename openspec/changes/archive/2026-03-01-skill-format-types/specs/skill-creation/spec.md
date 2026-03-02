# Spec: skill-creation

Change: skill-format-types
Date: 2026-03-01

## Overview

This spec describes the observable behavior of the `skill-creator` skill after the
`skill-format-types` change. It covers: the format-selection step added at the start
of the creation process and its effect on the generated SKILL.md skeleton.

---

## Requirements

### Requirement: skill-creator prompts for format type before generating a SKILL.md skeleton

When `/skill-create <name>` is invoked, `skill-creator` MUST include a format-selection
step early in its process. This step MUST either prompt the user for the format type or
infer it from contextual signals (e.g., skill name, purpose description). The selected
or inferred format MUST determine which skeleton sections are included in the generated
`SKILL.md`.

#### Scenario: skill-creator asks for format type when no context allows inference

- **GIVEN** `/skill-create my-skill` is invoked with no additional context
- **WHEN** `skill-creator` executes its format-selection step
- **THEN** it presents the user with the available format types: `procedural`,
  `reference`, and `anti-pattern`
- **AND** it provides a brief description of each type (matching the contracts in
  `docs/format-types.md`)
- **AND** it waits for the user to select a format before proceeding

#### Scenario: skill-creator infers format: reference for a technology-named skill

- **GIVEN** `/skill-create vue-3` is invoked (a technology library name pattern)
- **WHEN** `skill-creator` applies inference heuristics
- **THEN** it infers `reference` as the likely format type
- **AND** it presents the inferred type to the user for confirmation before proceeding
  (inference is never silent — the user is always shown the selected format)

#### Scenario: skill-creator infers format: anti-pattern for an antipatterns-named skill

- **GIVEN** `/skill-create python-antipatterns` is invoked
- **WHEN** `skill-creator` applies inference heuristics
- **THEN** it infers `anti-pattern` as the likely format type
- **AND** it presents the inferred type to the user for confirmation

#### Scenario: skill-creator infers format: procedural for an action-named skill

- **GIVEN** `/skill-create deploy-preview` is invoked (an action/verb pattern)
- **WHEN** `skill-creator` applies inference heuristics
- **THEN** it infers `procedural` as the likely format type
- **AND** it presents the inferred type to the user for confirmation

---

### Requirement: skill-creator generates a format-correct SKILL.md skeleton

The generated `SKILL.md` skeleton MUST match the required section contract for the
selected format type. The skeleton MUST include `format: <type>` in the YAML frontmatter.

#### Scenario: procedural skeleton includes ## Process section

- **GIVEN** the user has selected or confirmed `procedural` as the format type
- **WHEN** `skill-creator` generates the `SKILL.md` skeleton
- **THEN** the skeleton contains a `## Process` section with placeholder steps
- **AND** the YAML frontmatter contains `format: procedural`
- **AND** the skeleton does NOT contain a `## Patterns`, `## Examples`,
  or `## Anti-patterns` section

#### Scenario: reference skeleton includes ## Patterns section (not ## Process)

- **GIVEN** the user has selected or confirmed `reference` as the format type
- **WHEN** `skill-creator` generates the `SKILL.md` skeleton
- **THEN** the skeleton contains a `## Patterns` section with placeholder content
- **AND** the YAML frontmatter contains `format: reference`
- **AND** the skeleton does NOT contain a `## Process` section

#### Scenario: anti-pattern skeleton includes ## Anti-patterns section

- **GIVEN** the user has selected or confirmed `anti-pattern` as the format type
- **WHEN** `skill-creator` generates the `SKILL.md` skeleton
- **THEN** the skeleton contains an `## Anti-patterns` section with placeholder content
- **AND** the YAML frontmatter contains `format: anti-pattern`
- **AND** the skeleton does NOT contain a `## Process` section

---

### Requirement: skill-creator references docs/format-types.md for format contract details

`skill-creator` MUST NOT embed a separate copy of the format type contracts. When
presenting format type options to the user, it MUST refer to `docs/format-types.md`
as the authoritative source.

#### Scenario: skill-creator cites docs/format-types.md in its format-selection step

- **GIVEN** `skill-creator` is executing its format-selection step
- **WHEN** it presents format type options or descriptions to the user
- **THEN** the presentation either directly quotes from `docs/format-types.md` or
  directs the user to read it for full contract details
- **AND** the SKILL.md instructions for `skill-creator` reference `docs/format-types.md`
  by path, not by duplicated inline content

---

## Rules

- The format-selection step MUST appear before the skeleton generation step in the
  `skill-creator` process — a skeleton is never generated without a known format type
- Inference is a convenience only — the user MUST always confirm or override the
  inferred type before the skeleton is written
- The `format:` field MUST be present in all SKILL.md files generated by `skill-creator`
  after this change; existing skills are not retroactively modified
- If `docs/format-types.md` does not exist when `skill-creator` runs, `skill-creator`
  MUST still function by defaulting all new skills to `procedural` and emitting a
  WARNING: "docs/format-types.md not found — skill-format-types change may not be applied"
