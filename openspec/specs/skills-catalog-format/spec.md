# Spec: skills-catalog-format

Change: skills-catalog-analysis
Date: 2026-03-14

## Requirements

### Requirement: Format contract extension recognizes variant section names

Description: The format contract and tooling MUST accept `## Critical Patterns` as a valid alternative to `## Patterns` in `reference` format skills, and `## Code Examples` as a valid alternative to `## Examples` in `reference` format skills. The contract and tooling MUST also accept `## Critical Patterns` as a valid alternative to `## Anti-patterns` in `anti-pattern` format skills. This resolves format compliance violations for 19 externally-sourced tech skills without requiring content changes.

**RFC 2119 Keywords**: The terms "MUST", "MUST NOT", "SHOULD" appear in the following scenarios.

#### Scenario: reference skill with ## Critical Patterns and ## Code Examples passes audit

- **GIVEN** a skill is declared `format: reference` and contains both `## Critical Patterns` and `## Code Examples` sections (no `## Patterns` or `## Examples` sections)
- **WHEN** `project-audit` dimension D4b (Skill Format Compliance) is executed
- **THEN** the skill MUST NOT produce a MEDIUM audit finding for format contract violation
- **AND** the audit report MUST note that variant heading names were accepted
- **AND** all 19 externally-sourced tech skills (those using variant names) MUST pass the same audit check

#### Scenario: anti-pattern skill with ## Critical Patterns passes audit

- **GIVEN** a skill is declared `format: anti-pattern` and contains `## Critical Patterns` section (no `## Anti-patterns` section)
- **WHEN** `project-audit` dimension D4b is executed
- **THEN** the skill MUST NOT produce a MEDIUM audit finding for missing anti-patterns section
- **AND** the audit report MUST note that the `## Critical Patterns` variant was accepted as equivalent

#### Scenario: documentation reflects the accepted variant names

- **GIVEN** that `docs/format-types.md` defines the authoritative contract
- **WHEN** the file is read after this requirement is satisfied
- **THEN** it MUST document that `## Critical Patterns` and `## Code Examples` are accepted variant names in the Format B (reference) contract section (lines 115–127 expected location)
- **AND** it MUST document that `## Critical Patterns` is an accepted variant in the Format C (anti-pattern) contract section (lines 195–202 expected location)
- **AND** the documentation MUST include a note explaining that variants appear in externally-sourced skills from the Gentleman-Skills corpus and are equally valid

### Requirement: project-audit section detection rule updated

Description: The section detection rule in `project-audit/SKILL.md` MUST be updated to recognize variant section names when validating format compliance. The rule MUST be uniform across all format checks and MUST match the contract defined in `docs/format-types.md`.

#### Scenario: project-audit correctly detects variant headings

- **GIVEN** a skill with `## Critical Patterns` as its main section
- **WHEN** the project-audit skill runs its section detection phase (Step 4d — Skill Format Compliance)
- **THEN** the detection rule MUST identify `## Critical Patterns` as a valid patterns section
- **AND** the rule MUST NOT produce a false-positive MEDIUM finding
- **AND** the same rule MUST apply identically to `## Code Examples` headings

#### Scenario: section detection regex matches across all sections

- **GIVEN** the section detection rule is updated with a regex or equivalent pattern-matching logic
- **WHEN** the rule is applied to all three formats (procedural, reference, anti-pattern)
- **THEN** it MUST detect standard headings (`## Process`, `## Patterns`, `## Examples`, `## Anti-patterns`)
- **AND** it MUST detect variant headings (`## Critical Patterns`, `## Code Examples`) with equal accuracy
- **AND** the detection MUST be consistent regardless of whitespace variations (e.g., extra spaces around heading)

### Requirement: elixir-antipatterns skill structure corrected

Description: The `skills/elixir-antipatterns/SKILL.md` skill MUST have its main section renamed from `## Critical Patterns` to `## Anti-patterns`. This is a hard format contract violation requiring content relocation, not just acceptance of the variant.

#### Scenario: elixir-antipatterns contains ## Anti-patterns section

- **GIVEN** that the skill is declared `format: anti-pattern`
- **WHEN** the file is read after this requirement is satisfied
- **THEN** it MUST contain a section heading `## Anti-patterns` (exact match)
- **AND** the `## Critical Patterns` heading MUST be removed or renamed
- **AND** the anti-pattern content (catalogs of bad practices) MUST remain under the new heading

#### Scenario: elixir-antipatterns passes audit after fix

- **GIVEN** the skill has been corrected
- **WHEN** `project-audit` is run on the skill catalog
- **THEN** the elixir-antipatterns skill MUST NOT produce a MEDIUM finding for missing anti-patterns section
- **AND** its overall compliance score MUST be equal to or higher than a reference anti-pattern skill in the catalog

### Requirement: claude-code-expert duplicate headings removed

Description: The `skills/claude-code-expert/SKILL.md` skill MUST have its duplicate `## Description` sections removed. The section is replaced by `## Patterns` as the primary content heading, leaving zero `## Description` headings. Redundant `**Triggers**` occurrences must also be removed, leaving exactly one.

#### Scenario: claude-code-expert has no ## Description heading

- **GIVEN** the file is read
- **WHEN** counting occurrences of lines starting with `## Description`
- **THEN** there MUST be exactly 0 occurrences (section replaced by ## Patterns)

#### Scenario: claude-code-expert has exactly one ## Triggers trigger definition

- **GIVEN** the file is read
- **WHEN** counting occurrences of lines starting with `**Triggers**`
- **THEN** there MUST be exactly 1 occurrence (not 0, not 2 or more)

#### Scenario: claude-code-expert passes audit without structure violations

- **GIVEN** the skill has been corrected
- **WHEN** `project-audit` dimension D4b is executed
- **THEN** the skill MUST NOT produce a MEDIUM finding for duplicate sections
- **AND** all other format contract checks (Triggers presence, Rules section, etc.) MUST continue to pass

## Risks and clarifications

### No breaking changes to existing valid skills

The acceptance of variant headings is additive only — it does not alter the contract for skills using standard heading names. All currently compliant skills remain compliant.

### Regex or pattern-matching complexity

The implementation of variant heading detection in `project-audit` MUST ensure that the regex or pattern-matching logic does not incorrectly match similar-named headings (e.g., `## Critical Pattern Analysis` should not match the variant). The exact matching strategy is deferred to the design phase.
