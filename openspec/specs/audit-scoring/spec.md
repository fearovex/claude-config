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

### Requirement: Audit score on agent-config itself does not decrease after the change

Running `/project-audit` on the agent-config repo after applying this change MUST yield a score greater than or equal to the score recorded in the current `audit-report.md`.

#### Scenario: Score regression check

- **GIVEN** the current `audit-report.md` in the agent-config repo records a baseline score
- **WHEN** `/project-audit` is run on agent-config after this change is applied and `install.sh` has been run
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

#### Scenario: Score on agent-config does not decrease after this change

- **GIVEN** the current `audit-report.md` in the agent-config repo records a baseline score
- **WHEN** `/project-audit` is run on agent-config after this change is applied and `install.sh` has been run
- **THEN** the new score is >= the baseline score
- **AND** any score difference is attributable only to legitimate D1–D9 changes, not to D10

---

## ADDED in audit-improvements (2026-03-01)

### Requirement: D7 score reflects staleness penalty within the existing 5-point maximum

The D7 scoring rubric MUST document the staleness penalty tiers alongside the existing
drift-based tiers. The combined score MUST NOT go below 0.

#### Scenario: D7 scoring table documents staleness deductions

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the D7 scoring section
- **THEN** the scoring table or scoring description includes two staleness tiers:
  - 31–60 days old: −1 point
  - > 60 days old: −2 points
- **AND** a note states "staleness penalty stacks with drift penalty; floor is 0"

#### Scenario: D7 maximum remains 5 points

- **GIVEN** the Detailed Scoring table at the bottom of `project-audit/SKILL.md` is read
- **WHEN** the Architecture row is examined
- **THEN** the Max Points value for Architecture / D7 is still 5
- **AND** the TOTAL row still sums to 100

#### Scenario: D7 cannot go below zero from combined penalties

- **GIVEN** `analysis-report.md` exists and is 90 days old (−2 staleness)
- **AND** the drift summary is `significant` (which yields 0 from drift scoring)
- **WHEN** `/project-audit` runs D7
- **THEN** D7 reports 0/5 (not a negative value)

---

### Requirement: D12 (ADR Coverage) HIGH findings appear in required_actions but do not change the base score maximum

D12 HIGH and MEDIUM findings MUST be actionable (listed in `required_actions`) so that
`/project-fix` can resolve them. However, D12 MUST NOT be assigned a numeric max-points
value that changes the total from 100.

#### Scenario: Score table shows D12 row as N/A

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the Detailed Scoring table
- **THEN** there is a row for "ADR Coverage" (D12) with "N/A" in the Max Points column
- **AND** the TOTAL row still shows 100

#### Scenario: D12 findings are actionable despite N/A score

- **GIVEN** D12 has emitted a HIGH finding (e.g., `docs/adr/README.md` is missing)
- **WHEN** the audit report's FIX_MANIFEST is read
- **THEN** the finding appears in `required_actions.high`
- **AND** the base score (from D1–D9) is unchanged by the D12 finding
- **AND** a human or `/project-fix` can resolve the finding without altering the
  base score

#### Scenario: Projects with no docs/adr/ reference get full base score

- **GIVEN** a project whose `CLAUDE.md` does not reference `docs/adr/`
- **WHEN** `/project-audit` runs
- **THEN** D12 is skipped
- **AND** the project's final score is computed from D1–D9 only
- **AND** the project does NOT lose points for lacking an ADR system

---

### Requirement: D13 (Spec Coverage) MEDIUM findings appear in required_actions but do not change the base score maximum

D13 MEDIUM findings for missing spec files MUST be listed in `required_actions.medium`
so that `/project-fix` can create stub spec files. D13 INFO findings (stale paths) appear
only in `violations[]`. D13 MUST NOT be assigned a numeric max-points value.

#### Scenario: Score table shows D13 row as N/A

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** the Detailed Scoring table is read
- **THEN** there is a row for "Spec Coverage" (D13) with "N/A" in the Max Points column
- **AND** the TOTAL row still shows 100

#### Scenario: Missing spec.md triggers required_action but no score penalty

- **GIVEN** `openspec/specs/payments/` exists but contains no `spec.md`
- **AND** `/project-audit` has run and detected the missing spec
- **WHEN** the FIX_MANIFEST is read
- **THEN** `required_actions.medium` contains an entry for creating `openspec/specs/payments/spec.md`
- **AND** the base score from D1–D9 is identical to what it would be if `openspec/specs/`
  did not exist at all (no penalty for the absence of the spec file)

#### Scenario: Projects with no openspec/specs/ get full base score

- **GIVEN** a project with no `openspec/specs/` directory
- **WHEN** `/project-audit` runs
- **THEN** D13 is skipped
- **AND** the final score is computed from D1–D9 only

---

### Requirement: Adding D12 and D13 does not regress the audit score on the agent-config repo

Running `/project-audit` on the agent-config repo after this change MUST yield a score
greater than or equal to the pre-change baseline.

#### Scenario: Score on agent-config does not decrease after audit-improvements

- **GIVEN** the current `audit-report.md` in the agent-config repo records a baseline
  score before this change is applied
- **WHEN** `/project-audit` is run on agent-config after this change is applied and
  `install.sh` has been run
- **THEN** the new score is >= the baseline score
- **AND** any difference is attributable only to legitimate D1–D9 improvements or
  regressions, not to D12 or D13 being applied with score penalties

---

## MODIFIED in audit-improvements (2026-03-01)

### Requirement: D7 scoring table documents the staleness penalty
*(Before: D7 staleness was informational only — it emitted a warning but did not reduce the score)*

D7 scoring MUST now deduct points when `analysis-report.md` is older than 30 days. The
table in SKILL.md and the score block in every generated `audit-report.md` MUST reflect
the actual points awarded (which may be less than the maximum due to staleness).

#### Scenario: D7 score block in audit-report.md reflects the staleness deduction

- **GIVEN** `analysis-report.md` exists and is 45 days old with no drift
- **WHEN** `/project-audit` generates the report
- **THEN** the D7 row in the score table shows "4/5" (not 5/5)
- **AND** the D7 section in the report body explains: "1-point staleness deduction
  applied (analysis-report.md is 45 days old)"
- **AND** the TOTAL score reflects this 1-point reduction compared to a project with a
  fresh report

---

## Rules (updated in audit-improvements 2026-03-01)

- D12 and D13 MUST NOT change the 100-point maximum for Dimensions 1–9
- D12 and D13 findings that are HIGH or MEDIUM ARE placed in `required_actions` (they
  are actionable), but they do not reduce the base score — they are post-100-point
  additions
- The D7 staleness penalty operates within D7's existing 5-point ceiling — it does not
  add new max points or change the total ceiling of 100
- Score regression on the agent-config repo is a hard acceptance criterion; any change
  that reduces the score below the pre-change baseline MUST be reverted or explained
