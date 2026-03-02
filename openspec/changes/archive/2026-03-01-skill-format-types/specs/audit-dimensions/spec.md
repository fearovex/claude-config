# Delta Spec: audit-dimensions

Change: skill-format-types
Date: 2026-03-01
Base: openspec/specs/audit-dimensions/spec.md

## Overview

This delta covers format-aware changes to D4 (Global Skills Quality) and D9 (Project
Skills Quality) in `project-audit`. It also covers the corresponding update to
`project-fix` (format-aware skeleton repair). All other dimensions are unchanged.

---

## ADDED — New requirements

### Requirement: D4 reads the format: field from SKILL.md frontmatter before structural validation

When auditing global skills (D4), `project-audit` MUST read the `format:` field from
each skill's YAML frontmatter (if present) and apply the structural check matching the
declared format. If no `format:` field is present, D4 MUST default to the `procedural`
check.

#### Scenario: D4 passes a reference skill that declares format: reference

- **GIVEN** a skill in the global skills catalog (e.g., `react-19/SKILL.md`) has
  `format: reference` in its YAML frontmatter
- **AND** the skill has `## Patterns` or `## Examples` but no `## Process` section
- **WHEN** `project-audit` runs D4
- **THEN** D4 applies the `reference` structural check for that skill
- **AND** D4 emits no MEDIUM or HIGH finding for the absence of `## Process`
- **AND** D4 verifies that the skill has `## Patterns` or `## Examples` — if neither
  is present, D4 emits a MEDIUM finding: "reference skill missing ## Patterns or
  ## Examples section"

#### Scenario: D4 passes a procedural skill with no format: declaration (default)

- **GIVEN** a skill (e.g., `sdd-apply/SKILL.md`) has no YAML frontmatter
  or no `format:` key
- **WHEN** `project-audit` runs D4
- **THEN** D4 applies the `procedural` structural check
- **AND** behavior is identical to pre-change behavior for this skill
- **AND** if the skill is missing `## Process`, D4 emits a MEDIUM finding as before

#### Scenario: D4 passes an anti-pattern skill that declares format: anti-pattern

- **GIVEN** a skill (e.g., `elixir-antipatterns/SKILL.md`) has `format: anti-pattern`
  in its YAML frontmatter
- **AND** the skill has `## Anti-patterns` but no `## Process` section
- **WHEN** `project-audit` runs D4
- **THEN** D4 applies the `anti-pattern` structural check
- **AND** D4 emits no finding for the absence of `## Process`
- **AND** if `## Anti-patterns` is absent, D4 emits a MEDIUM finding: "anti-pattern
  skill missing ## Anti-patterns section"

#### Scenario: D4 emits an INFO finding for an unknown format: value

- **GIVEN** a `SKILL.md` has `format: experimental` (an unknown value) in its frontmatter
- **WHEN** `project-audit` runs D4
- **THEN** D4 emits an INFO finding: "Unknown format value 'experimental' — defaulting
  to procedural check"
- **AND** D4 applies the `procedural` structural check for that skill

---

### Requirement: D9 reads the format: field from SKILL.md frontmatter before structural validation

When auditing project-local skills (D9), `project-audit` MUST apply the same
format-aware structural check as D4. The `format:` field is read from each skill's
YAML frontmatter; absence defaults to `procedural`.

#### Scenario: D9 passes a project-local reference skill that declares format: reference

- **GIVEN** a project-local skill has `format: reference` in its YAML frontmatter
- **AND** the skill has `## Patterns` or `## Examples` but no `## Process`
- **WHEN** `project-audit` runs D9
- **THEN** D9 applies the `reference` structural check
- **AND** D9 emits no MEDIUM or HIGH finding for the absence of `## Process`

#### Scenario: D9 passes a project-local procedural skill with no format: declaration

- **GIVEN** a project-local skill has no `format:` declaration
- **WHEN** `project-audit` runs D9
- **THEN** D9 behavior is identical to pre-change behavior for that skill
- **AND** the D9 score for a fully compliant project does not change

#### Scenario: D9 format-aware check produces no false positives on the global-config repo

- **GIVEN** the global-config repo is the audit target
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=skills`
- **AND** technology skills such as `react-19`, `nextjs-15`, `typescript` have
  `format: reference` declared
- **WHEN** D9 runs format-aware validation on those skills
- **THEN** no D9 MEDIUM or HIGH finding is emitted for missing `## Process` in those skills
- **AND** the D9 score is the same as or higher than the pre-change baseline

---

### Requirement: project-fix applies format-aware skeleton repair

When `project-fix` reads the FIX_MANIFEST and encounters a skill with a missing
required section finding, it MUST generate the skeleton section matching the skill's
declared format, not unconditionally generate `## Process`.

#### Scenario: project-fix repairs a procedural skill by inserting ## Process

- **GIVEN** a FIX_MANIFEST entry identifies a procedural skill missing `## Process`
  (either by explicit `format: procedural` declaration or by default)
- **WHEN** `project-fix` applies the correction
- **THEN** it inserts a `## Process` skeleton section into the skill
- **AND** it does NOT insert `## Patterns` or `## Anti-patterns`

#### Scenario: project-fix repairs a reference skill by inserting ## Patterns

- **GIVEN** a FIX_MANIFEST entry identifies a `format: reference` skill missing
  `## Patterns` (and also missing `## Examples`)
- **WHEN** `project-fix` applies the correction
- **THEN** it inserts a `## Patterns` skeleton section into the skill
- **AND** it does NOT insert `## Process`

#### Scenario: project-fix repairs an anti-pattern skill by inserting ## Anti-patterns

- **GIVEN** a FIX_MANIFEST entry identifies a `format: anti-pattern` skill missing
  `## Anti-patterns`
- **WHEN** `project-fix` applies the correction
- **THEN** it inserts an `## Anti-patterns` skeleton section
- **AND** it does NOT insert `## Process`

#### Scenario: project-fix does not alter skills with no structural finding

- **GIVEN** a FIX_MANIFEST with no missing-required-section entries for a given skill
- **WHEN** `project-fix` processes that skill
- **THEN** the skill file is not modified for structural reasons

---

## MODIFIED — Modified requirements

### Requirement: D4 structural check (modified to be format-aware)

*(Before: D4 always checked for `## Process` in every skill file, regardless of type.
Missing `## Process` always produced a MEDIUM finding.)*

D4 structural check MUST now read `format:` from each skill's frontmatter before
evaluating structural compliance. The applicable required section is determined by the
declared format type (see skill-format-types spec). Missing the required section for
the declared format produces a MEDIUM finding. Missing `## Process` in a
`format: reference` or `format: anti-pattern` skill is NOT a finding.

### Requirement: D9 structural check (modified to be format-aware)

*(Before: D9 always checked for `## Process` in every project-local skill file.)*

D9 structural check MUST now apply the same format-aware logic as D4. Behavior for
skills without a `format:` declaration is unchanged.

---

## Rules

- Format-aware logic in D4 and D9 applies only to the structural section check
  (required section presence). All other D4/D9 checks (trigger presence, rules
  presence, file naming) are unchanged
- The D4 and D9 scoring thresholds are unchanged; the format-aware check replaces the
  old `## Process` check on a per-skill basis without altering the scoring formula
- `project-fix` MUST read the `format:` field from the skill's frontmatter at repair
  time — it MUST NOT rely solely on the FIX_MANIFEST entry, which may not carry the
  format value
- Format-aware validation logic in D4, D9, and project-fix MUST reference
  `docs/format-types.md` as the authoritative contract; it MUST NOT duplicate the
  contract inline
