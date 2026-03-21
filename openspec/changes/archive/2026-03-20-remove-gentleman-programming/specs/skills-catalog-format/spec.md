# Delta Spec: skills-catalog-format

Change: 2026-03-20-remove-gentleman-programming
Date: 2026-03-20
Base: openspec/specs/skills-catalog-format/spec.md

## MODIFIED — Modified Requirements

### Requirement: documentation reflects the accepted variant names

**New description**: The authoritative format contract documentation in `docs/format-types.md` MUST document that `## Critical Patterns` and `## Code Examples` are accepted variant names. The documentation MUST explain that variants appear in externally-sourced skills. The documentation MUST NOT reference a specific external brand or organization by name.

_(Before: Requirement stated the documentation "MUST include a note explaining that variants appear in externally-sourced skills from the Gentleman-Skills corpus and are equally valid")_

#### Scenario: documentation includes neutral variant attribution

- **GIVEN** `docs/format-types.md` is read after this change is applied
- **WHEN** examining the section describing accepted variant headings
- **THEN** the document MUST state that variants appear in "externally-sourced skills" (neutral phrasing)
- **AND** the document MUST NOT contain the string "Gentleman-Skills" or "Gentleman-Programming"
- **AND** the statement that variants are equally valid MUST be preserved

#### Scenario: variant acceptance behavior is unchanged

- **GIVEN** an externally-sourced skill using `## Critical Patterns` as its main section
- **WHEN** `project-audit` D4b runs after this change
- **THEN** the skill MUST still pass format compliance (acceptance logic is not altered by removing the brand name)

## REMOVED — Removed Requirements

### Requirement: Gentleman-Skills corpus named in variant documentation

_(Reason: The requirement that `docs/format-types.md` MUST name "Gentleman-Skills corpus" as the source of variant headings is removed. The functional rule (variants from externally-sourced skills are accepted) is preserved; only the brand attribution is removed.)_
