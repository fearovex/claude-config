# Delta Spec: audit-scoring

Change: feature-docs-dimension
Date: 2026-02-26
Base: openspec/specs/audit-scoring/spec.md

---

## ADDED — New requirements

### Requirement: D10 row appears in the score table as N/A and contributes zero points

The score table in `project-audit/SKILL.md` and in every generated `audit-report.md` MUST include a D10 row whose value is always displayed as "N/A" and whose contribution to the total score is exactly zero.

#### Scenario: Score table in SKILL.md contains a D10 row

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the Detailed Scoring table
- **THEN** there is a row for "Feature Docs Coverage" (or "Dimension 10") with a value of "N/A" in the Max Points column
- **AND** the TOTAL row still shows 100
- **AND** no other row's Max Points value has changed

#### Scenario: Score table in generated audit-report.md contains a D10 row

- **GIVEN** `/project-audit` is run on any project (with or without feature docs)
- **WHEN** `audit-report.md` is written
- **THEN** the score summary table in the report contains a D10 row labeled "Feature Docs Coverage" with value "N/A"
- **AND** the TOTAL row in the report score table shows the same numeric score as if D10 did not exist

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

#### Scenario: Max score remains 100 after adding D10

- **GIVEN** a fully compliant project that scores 100/100 before this change
- **WHEN** `/project-audit` is run after this change
- **THEN** the project still scores 100/100
- **AND** the D10 row appears as "N/A" in the score table without affecting the total

---

## Rules

- The N/A designation for D10 is non-negotiable — it must be visible in both the SKILL.md template and every generated report
- The TOTAL row in every score table MUST sum only D1–D9 contributions
- Any future change that proposes to convert D10 from informational to scored requires a new SDD change with a dedicated scoring spec
