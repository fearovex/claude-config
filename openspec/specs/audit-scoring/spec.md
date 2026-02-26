# Spec: audit-scoring

Change: deprecate-commands-normalize-skills
Date: 2026-02-26

## Overview

This spec describes the observable scoring behavior of `project-audit` after commands are removed as an audited dimension. The total score MUST still sum to 100. Dimension 4 (Skills Quality) absorbs the freed 10 points from Dimension 5 (Commands Quality), which is removed entirely.

---

## Requirements

### Requirement: Score table sums to 100 with no D5 row

The scoring table in `project-audit/SKILL.md` MUST reflect a maximum of 100 points across all remaining dimensions, with D4 capped at 20 points and no D5 row present.

#### Scenario: Scoring table structure after the change

- **GIVEN** `skills/project-audit/SKILL.md` has been updated
- **WHEN** a developer reads the Detailed Scoring table at the bottom of the file
- **THEN** the table has no row for "Commands" (previously D5)
- **AND** the "Skills" row (D4) shows a maximum of 20 points
- **AND** the sum of all "Max points" values in the table equals exactly 100
- **AND** no other row's maximum point value has changed from its previous value

#### Scenario: D4 scoring rubric reflects the redistributed 10 points

- **GIVEN** the D4 section of `project-audit/SKILL.md` is read
- **WHEN** a developer reads the scoring rubric for D4
- **THEN** D4 has two distinct sub-criteria worth 10 points each (registry accuracy + content depth, and recommended global skills coverage)
- **AND** the second sub-criterion (global skills coverage) is marked as scored, not merely informational
- **AND** the maximum obtainable score from D4 is 20 points

#### Scenario: Score table in report format reflects D4 at 20 pts and no D5

- **GIVEN** the report format block inside `project-audit/SKILL.md` defines the score summary table
- **WHEN** that table is read
- **THEN** the "Skills registry complete and functional" row shows max of 20
- **AND** there is no "Commands registry complete and functional" row
- **AND** the TOTAL row shows 100

---

### Requirement: Projects without commands/ receive no score penalty

After this change, a project that has no `.claude/commands/` directory MUST NOT lose any points due to the absence of commands.

#### Scenario: Audit run on a project with no commands/ directory

- **GIVEN** a project that has `.claude/skills/` with valid skills but NO `.claude/commands/` directory
- **WHEN** `/project-audit` is run on that project
- **THEN** the audit score is identical to what it would be if the "Commands" dimension had never existed
- **AND** no finding, penalty, or warning is emitted for the absence of `.claude/commands/`
- **AND** the score is the same or higher than it would have been under the old scoring model for the same project state

#### Scenario: Audit run on a project with commands/ directory present

- **GIVEN** a project that has `.claude/commands/` with legacy command files AND `.claude/skills/` with valid skills
- **WHEN** `/project-audit` is run
- **THEN** the presence of `.claude/commands/` does NOT contribute positively to the score
- **AND** a single LOW (INFO) finding is emitted recommending migration to skills (see audit-dimensions spec)
- **AND** the project's D4 score is determined solely by its skills content and registry accuracy

---

### Requirement: Audit score on claude-config itself does not decrease after the change

Running `/project-audit` on the claude-config repo after applying this change MUST yield a score greater than or equal to the score recorded in the current `audit-report.md`.

#### Scenario: Score regression check

- **GIVEN** the current `audit-report.md` in the claude-config repo records a baseline score
- **WHEN** `/project-audit` is run on claude-config after this change is applied and `install.sh` has been run
- **THEN** the new score is >= the baseline score
- **AND** any score increase is attributable to the removal of the false penalty from D5

---

## Rules

- Specs describe observable scoring outcomes, not implementation details of the scoring algorithm
- All MUST-level scenarios are non-negotiable for this change to be considered complete
- The redistribution of 10 points from D5 to D4 must be verifiable by reading the SKILL.md scoring table directly — it is not sufficient to only change runtime behavior

---

## ADDED in feature-docs-dimension (2026-02-26)

### Requirement: D10 row appears in the score table as N/A and contributes zero points

The score table in `project-audit/SKILL.md` and in every generated `audit-report.md` MUST include a D10 row whose value is always displayed as "N/A" and whose contribution to the total score is exactly zero.

#### Scenario: Score table in SKILL.md contains a D10 row

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the Detailed Scoring table
- **THEN** there is a row for "Feature Docs Coverage" (or "Dimension 10") with a value of "N/A" in the Max Points column
- **AND** the TOTAL row still shows 100
- **AND** no other row's Max Points value has changed

#### Scenario: D10 row is consistently N/A regardless of D10 findings

- **GIVEN** two projects: one where D10 detects features with ❌ findings and one where D10 detects no features
- **WHEN** `/project-audit` is run on each
- **THEN** in both reports, the D10 row in the score table shows "N/A" (not a numeric score)
- **AND** the total score is identical between the two projects if all other dimensions are equal

---

### Requirement: Existing 100-point scoring model is not altered by adding D10

Adding Dimension 10 to `project-audit/SKILL.md` MUST NOT change the maximum attainable score or the per-dimension point allocation for Dimensions 1–9.

#### Scenario: Score on claude-config does not decrease after this change

- **GIVEN** the current `audit-report.md` in the claude-config repo records a baseline score
- **WHEN** `/project-audit` is run on claude-config after this change is applied and `install.sh` has been run
- **THEN** the new score is >= the baseline score
- **AND** any score difference is attributable only to legitimate D1–D9 changes, not to D10
