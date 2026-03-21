# Delta Spec: format-contract

Change: 2026-03-20-remove-gentleman-programming
Date: 2026-03-20
Base: openspec/specs/format-contract/spec.md

## MODIFIED — Modified Requirements

### Requirement: Format Contract Documentation Update (Requirement 1 — source attribution note)

**New description**: The format contract documentation in `docs/format-types.md` MUST recognize and accept variant section heading names for externally-sourced skills. The explanatory notes referencing the source corpus MUST NOT name a specific external brand or organization — they MUST use the neutral label "externally-sourced skills".

_(Before: Documentation noted that variants "originate from high-quality, externally-sourced documentation (Gentleman-Skills corpus)")_

#### Scenario: format-types.md accepts variant headings without brand reference

- **GIVEN** `docs/format-types.md` documents the accepted variant headings (`## Critical Patterns`, `## Code Examples`)
- **WHEN** the file is read after this change is applied
- **THEN** the explanatory notes MUST use the phrase "externally-sourced skills" (or equivalent neutral phrasing)
- **AND** the notes MUST NOT contain the strings "Gentleman-Skills", "Gentleman-Programming", or "Gentleman" in any form
- **AND** the variant heading acceptance logic MUST remain fully intact (no functional change)

#### Scenario: variant heading exception still accepted after rephrasing

- **GIVEN** a skill with `format: reference` and a `## Critical Patterns` section
- **WHEN** `project-audit` evaluates the skill's structural compliance after this change
- **THEN** the skill MUST NOT trigger a D4b finding (variant acceptance is preserved)

#### Scenario: implementation notes section updated

- **GIVEN** the Implementation Notes section of the spec at `openspec/specs/format-contract/spec.md` references "Gentleman-Skills corpus"
- **WHEN** the master spec is updated to reflect this change
- **THEN** the reference MUST be rephrased to "externally-sourced skills" or equivalent neutral phrasing
- **AND** the functional explanation (variants are restricted to explicitly recognized patterns from well-vetted external sources) MUST remain semantically equivalent

## REMOVED — Removed Requirements

### Requirement: Gentleman-Skills corpus attribution in format-contract spec

_(Reason: The implementation notes in `openspec/specs/format-contract/spec.md` contain a brand-specific attribution to "Gentleman-Skills corpus". This attribution is cosmetic metadata with no functional role. The requirement to document the source name is removed; the functional rule (variants from well-vetted external sources are accepted) is preserved under MODIFIED.)_
