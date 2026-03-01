# Delta Spec: audit-scoring

Change: audit-improvements
Date: 2026-03-01
Base: openspec/specs/audit-scoring/spec.md

---

## Overview

This delta describes the observable scoring behavior changes introduced by the
`audit-improvements` change. The two new dimensions (D12 ADR Coverage, D13 Spec Coverage)
are additive — they produce actionable findings that feed into `project-fix`, but their
findings do NOT reduce the maximum attainable base score of 100 points. The D7 staleness
penalty modifies the D7 score within its existing 5-point ceiling.

---

## ADDED — New requirements

---

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

### Requirement: Adding D12 and D13 does not regress the audit score on the claude-config repo

Running `/project-audit` on the claude-config repo after this change MUST yield a score
greater than or equal to the pre-change baseline.

#### Scenario: Score on claude-config does not decrease after audit-improvements

- **GIVEN** the current `audit-report.md` in the claude-config repo records a baseline
  score before this change is applied
- **WHEN** `/project-audit` is run on claude-config after this change is applied and
  `install.sh` has been run
- **THEN** the new score is >= the baseline score
- **AND** any difference is attributable only to legitimate D1–D9 improvements or
  regressions, not to D12 or D13 being applied with score penalties

---

## MODIFIED — Modified requirements

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

## Rules

- D12 and D13 MUST NOT change the 100-point maximum for Dimensions 1–9
- D12 and D13 findings that are HIGH or MEDIUM ARE placed in `required_actions` (they
  are actionable), but they do not reduce the base score — they are post-100-point
  additions
- The D7 staleness penalty operates within D7's existing 5-point ceiling — it does not
  add new max points or change the total ceiling of 100
- Score regression on the claude-config repo is a hard acceptance criterion; any change
  that reduces the score below the pre-change baseline MUST be reverted or explained
