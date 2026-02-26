# Spec: audit-dimensions

Change: deprecate-commands-normalize-skills
Date: 2026-02-26

## Overview

This spec describes the observable behavior of `project-audit` at the dimension level after the commands deprecation. It covers: removal of Dimension 5 entirely, removal of the "Has Commands registry" check from Dimension 1, and the addition of a passive INFO notice when a legacy `commands/` directory is detected.

---

## Requirements

### Requirement: Dimension 5 (Commands Quality) is fully removed from project-audit

`project-audit/SKILL.md` MUST NOT contain any Dimension 5 section, D5 checks, or commands-focused audit logic after this change.

#### Scenario: SKILL.md has no Dimension 5 section

- **GIVEN** `skills/project-audit/SKILL.md` has been updated
- **WHEN** a developer reads the file from top to bottom
- **THEN** there is no section heading "Dimension 5" or "Commands Quality"
- **AND** there are no sub-checks 5a or 5b in the file
- **AND** the file's dimension count is 8 explicitly numbered dimensions (1, 2, 3, 4, 6, 7, 8, 9) plus D9

#### Scenario: Report format has no D5 block

- **GIVEN** the report format section of `project-audit/SKILL.md` defines the structure of the generated report
- **WHEN** that section is read
- **THEN** there is no "Dimension 5 — Commands" block in the report format template
- **AND** there is no row for D5 in any score table template
- **AND** the FIX_MANIFEST YAML template within the report format does not reference any commands-related action types (e.g., `fix_commands_registry`)

---

### Requirement: Dimension 1 does not penalize absence of a commands registry

The "Has Commands registry" check MUST be removed from Dimension 1's check table. Its absence MUST NOT be reported as a finding or deduct from D1's score.

#### Scenario: D1 check table has no commands registry row

- **GIVEN** `skills/project-audit/SKILL.md` D1 section is read
- **WHEN** a developer reads the "Checks to run" table
- **THEN** the table has no row with text "Has Commands registry" or equivalent
- **AND** no severity value is assigned for a missing commands table in CLAUDE.md

#### Scenario: D1 report format has no commands registry row

- **GIVEN** the D1 block in the report format template is read
- **WHEN** the table of checks and statuses is examined
- **THEN** there is no "Commands registry present" row in the template table
- **AND** the template table contains a "Skills registry present" row (unchanged)

#### Scenario: Audit on a project whose CLAUDE.md has no commands table

- **GIVEN** a project whose `CLAUDE.md` contains a Skills registry table but no Commands registry table
- **WHEN** `/project-audit` is run
- **THEN** the D1 score is unaffected by the absence of a Commands registry
- **AND** no D1 finding of any severity is emitted for "missing Commands registry"

---

### Requirement: Legacy commands/ directory triggers a passive INFO notice

If the target project has a `.claude/commands/` directory, `project-audit` MUST emit exactly one LOW/INFO finding recommending migration to skills. This finding MUST carry zero score penalty.

#### Scenario: INFO notice emitted for a project with commands/ present

- **GIVEN** the target project has a `.claude/commands/` directory with at least one file
- **WHEN** `/project-audit` runs
- **THEN** exactly one LOW finding appears in the report with text that:
  - identifies that a legacy `.claude/commands/` directory was detected
  - recommends migrating to `.claude/skills/` following the official Claude Code standard
- **AND** the finding severity is LOW (informational only)
- **AND** the finding does NOT appear in the `required_actions.critical`, `required_actions.high`, or `required_actions.medium` blocks of the FIX_MANIFEST

#### Scenario: No INFO notice emitted for a project without commands/

- **GIVEN** the target project has NO `.claude/commands/` directory
- **WHEN** `/project-audit` runs
- **THEN** no finding related to commands/ is emitted anywhere in the report

#### Scenario: INFO notice does not affect score

- **GIVEN** two identical projects, one with `.claude/commands/` and one without
- **WHEN** `/project-audit` is run on each
- **THEN** both projects receive the same numeric score
- **AND** the only difference in the reports is the presence or absence of the LOW INFO finding about commands/

---

### Requirement: The commands deprecation change itself is not audited or penalized

`project-audit` MUST NOT, after this change, generate any FIX_MANIFEST actions that would cause `project-fix` to create, repair, or populate a `.claude/commands/` directory.

#### Scenario: FIX_MANIFEST contains no commands-related actions for a compliant project

- **GIVEN** a project that correctly uses only `.claude/skills/` and has no `.claude/commands/` directory
- **WHEN** `/project-audit` is run and a FIX_MANIFEST is generated
- **THEN** the FIX_MANIFEST `required_actions` blocks contain no action with a `target` pointing to `.claude/commands/`
- **AND** no action type of `fix_commands_registry` or similar is present

---

## Rules

- The INFO notice for legacy commands/ is observable behavior — its presence and wording in the report are verifiable criteria
- Score impact is verifiable by comparing scores between runs on identical projects with and without commands/
- These specs do not constrain how the commands/ detection is implemented internally — only that the observable output matches the scenarios above

---

## ADDED in feature-docs-dimension (2026-02-26)

### Requirement: Dimension 10 (Feature Docs Coverage) is present in project-audit

`project-audit/SKILL.md` MUST contain a Dimension 10 section that evaluates feature-level documentation coverage. Dimension 10 MUST run after Dimension 9 and MUST follow the detection logic defined below.

#### Scenario: SKILL.md contains a Dimension 10 section

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the file from top to bottom
- **THEN** there is a section heading "Dimension 10" or "Feature Docs Coverage" after the Dimension 9 section
- **AND** the section documents four sub-checks: D10-a (Coverage), D10-b (Structural Quality), D10-c (Code Freshness), D10-d (Registry Alignment)
- **AND** each sub-check has explicit pass/fail criteria documented

---

### Requirement: D10 detection phase — configured path

When `feature_docs` is present in `openspec/config.yaml`, D10 MUST use the declared convention, paths, and feature detection strategy to enumerate features.

#### Scenario: D10 uses configured feature_docs when present

- **GIVEN** the target project has an `openspec/config.yaml` containing a `feature_docs` section with `convention`, `paths`, and `feature_detection` keys
- **WHEN** `/project-audit` is run on that project
- **THEN** D10 enumerates features using the paths and strategy declared in `feature_docs`
- **AND** D10 does NOT fall back to heuristic detection
- **AND** the D10 coverage table in the report lists only features identified via the declared configuration

---

### Requirement: D10 detection phase — heuristic fallback

When `feature_docs` is absent from `openspec/config.yaml`, D10 MUST fall back to heuristic detection to discover features.

#### Scenario: D10 runs heuristic detection when feature_docs is absent

- **GIVEN** the target project has `openspec/config.yaml` but no `feature_docs` section (or no `openspec/config.yaml` at all)
- **WHEN** `/project-audit` is run
- **THEN** D10 applies the heuristic detection strategy, scanning the following locations in order:
  1. Non-SDD skills in `.claude/skills/` (skills whose names do not start with `sdd-`, `project-`, `memory-`, or `skill-`)
  2. Markdown files directly in `docs/features/` or `docs/modules/` (if those directories exist)
  3. Subdirectories of `src/features/`, `src/modules/`, or `app/` that contain their own `README.md`
- **AND** directories named `shared`, `utils`, `common`, or `lib` are excluded from heuristic detection even if they contain a `README.md`

#### Scenario: D10 emits INFO and skips checks when no features are detected

- **GIVEN** the target project has no `feature_docs` configured AND heuristic detection finds zero features
- **WHEN** `/project-audit` runs D10
- **THEN** the D10 section in the report contains exactly one line: "No feature docs detected — D10 skipped"
- **AND** no coverage table is emitted for D10
- **AND** no D10 findings of any severity are added to the FIX_MANIFEST

---

### Requirement: D10-a Coverage check

For each detected feature, D10 MUST verify that a corresponding documentation artifact (SKILL.md or markdown file) exists.

---

### Requirement: D10-b Structural Quality check

For each detected feature with a documentation artifact, D10 MUST verify that the artifact meets minimum structural quality standards.

---

### Requirement: D10-c Code Freshness check

For each detected feature with a documentation artifact, D10 MUST verify that file paths referenced in the doc still exist on disk.

---

### Requirement: D10-d Registry Alignment check

For each detected feature skill, D10 MUST verify that the skill is listed in the target project's `CLAUDE.md` Skills Registry.

---

### Requirement: D10 findings never appear in FIX_MANIFEST required_actions

D10 MUST NOT generate FIX_MANIFEST entries that would cause `/project-fix` to create or repair feature documentation.

#### Scenario: FIX_MANIFEST contains no D10 entries

- **GIVEN** D10 has detected features with ❌ findings (e.g., missing coverage, stale paths)
- **WHEN** the FIX_MANIFEST in `audit-report.md` is read
- **THEN** `required_actions.critical`, `required_actions.high`, and `required_actions.medium` contain no entries referencing D10 findings
- **AND** a note in the D10 section states that fixing feature documentation gaps is a human decision
