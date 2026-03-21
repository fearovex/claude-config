# Delta Spec: Format Contract

Change: `2026-03-13-fix-format-contract`
Date: 2026-03-13
Base: `docs/format-types.md` (format contract definitions)

---

## ADDED — New Requirements

### Requirement 1 — Format Contract Documentation Update

The format contract documentation in `docs/format-types.md` MUST be updated to explicitly recognize and accept variant section heading names for externally-sourced skills.

#### Scenario: Reference format with standard Patterns section

- **GIVEN** a skill with `format: reference` and a `## Patterns` section
- **WHEN** `project-audit` evaluates the skill's structural compliance
- **THEN** the skill MUST NOT trigger a D4b finding for missing patterns/examples

#### Scenario: Reference format with variant Critical Patterns section

- **GIVEN** a skill with `format: reference` and a `## Critical Patterns` section (no `## Patterns` or `## Examples`)
- **WHEN** `project-audit` evaluates the skill's structural compliance
- **THEN** the skill MUST NOT trigger a D4b finding for missing patterns/examples (variant is accepted)

#### Scenario: Reference format with standard Examples section

- **GIVEN** a skill with `format: reference` and a `## Examples` section
- **WHEN** `project-audit` evaluates the skill's structural compliance
- **THEN** the skill MUST NOT trigger a D4b finding for missing patterns/examples

#### Scenario: Reference format with variant Code Examples section

- **GIVEN** a skill with `format: reference` and a `## Code Examples` section (no `## Patterns` or `## Examples`)
- **WHEN** `project-audit` evaluates the skill's structural compliance
- **THEN** the skill MUST NOT trigger a D4b finding for missing patterns/examples (variant is accepted)

#### Scenario: Anti-pattern format with standard Anti-patterns section

- **GIVEN** a skill with `format: anti-pattern` and a `## Anti-patterns` section
- **WHEN** `project-audit` evaluates the skill's structural compliance
- **THEN** the skill MUST NOT trigger a D4b finding for missing anti-patterns

#### Scenario: Anti-pattern format with variant Critical Patterns section

- **GIVEN** a skill with `format: anti-pattern` and a `## Critical Patterns` section (no `## Anti-patterns`)
- **WHEN** `project-audit` evaluates the skill's structural compliance
- **THEN** the skill MUST NOT trigger a D4b finding for missing anti-patterns (variant is accepted in anti-pattern context)

---

### Requirement 2 — Audit Validation Logic Update

The project-audit skill's D4b (format contract) validation logic MUST be updated to accept both standard and variant section heading names as compliant with the format contract.

#### Scenario: D4b validation accepts standard reference patterns

- **GIVEN** a reference skill with a `## Patterns` section
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST match the section and declare the skill compliant (no MEDIUM finding)

#### Scenario: D4b validation accepts variant reference critical patterns

- **GIVEN** a reference skill with a `## Critical Patterns` section and NO `## Patterns` or `## Examples`
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST match the variant section heading and declare the skill compliant (no MEDIUM finding)

#### Scenario: D4b validation accepts standard reference examples

- **GIVEN** a reference skill with a `## Examples` section
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST match the section and declare the skill compliant (no MEDIUM finding)

#### Scenario: D4b validation accepts variant reference code examples

- **GIVEN** a reference skill with a `## Code Examples` section and NO `## Patterns` or `## Examples`
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST match the variant section heading and declare the skill compliant (no MEDIUM finding)

#### Scenario: D4b validation rejects reference with no patterns or examples (standard or variant)

- **GIVEN** a reference skill with no `## Patterns`, `## Examples`, `## Critical Patterns`, or `## Code Examples` section
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST emit a MEDIUM finding: `"reference skill [name] missing ## Patterns or ## Examples section"`

#### Scenario: D4b validation accepts standard anti-pattern section

- **GIVEN** an anti-pattern skill with a `## Anti-patterns` section
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST match the section and declare the skill compliant (no MEDIUM finding)

#### Scenario: D4b validation accepts variant anti-pattern critical patterns

- **GIVEN** an anti-pattern skill with a `## Critical Patterns` section and NO `## Anti-patterns`
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST match the variant section heading and declare the skill compliant (no MEDIUM finding)

#### Scenario: D4b validation rejects anti-pattern with no anti-patterns or critical patterns

- **GIVEN** an anti-pattern skill with no `## Anti-patterns` or `## Critical Patterns` section
- **WHEN** the D4b validation check reads the skill's content
- **THEN** it MUST emit a MEDIUM finding: `"anti-pattern skill [name] missing ## Anti-patterns section"`

---

## MODIFIED — Modified Requirements

### Requirement: Format-to-section Mapping quick reference

**Previous description**:
```
| `reference` | Patterns or Examples | `## Patterns`, `## Examples` |
| `anti-pattern` | Anti-patterns | `## Anti-patterns` |
```

**New description**:
```
| `reference` | Patterns or Examples | `## Patterns`, `## Examples`, `## Critical Patterns`, `## Code Examples` |
| `anti-pattern` | Anti-patterns | `## Anti-patterns`, `## Critical Patterns` |
```

_(Before: The quick reference table listed only standard section headings without acknowledging externally-sourced variants)_

**Justification**: The mapping MUST document all accepted variants to reflect the actual contract enforced by the validation logic.

---

## Implementation Notes

### Scope of variant acceptance

Variant section headings (`## Critical Patterns`, `## Code Examples`) are semantic equivalents of their standard counterparts and are accepted because:

1. They originate from high-quality, externally-sourced documentation
2. They preserve reader-facing clarity without affecting the functional validation logic
3. They represent production-quality reference documentation that should not be renamed

Variants are **NOT** general guidance for new skills. New skills created via `skill-creator` will continue to generate standard section names (`## Patterns`, `## Examples`, `## Anti-patterns`). Variants are restricted to explicitly recognized patterns from well-vetted external sources.

_(Modified in: 2026-03-20 by change "remove-gentleman-programming" — changed "Gentleman-Skills corpus" to "externally-sourced skills" for brand neutrality)_

### Affected skills count

The change resolves MEDIUM findings for 21 skills in the global catalog:
- 20 `format: reference` skills using `## Critical Patterns` or `## Code Examples`
- 1 `format: anti-pattern` skill (`elixir-antipatterns`) using `## Code Examples`

After this change, `/project-audit` will report 0 MEDIUM D4b findings for these skills.

---

## Acceptance Criteria

1. **Documentation is clear**: `docs/format-types.md` explicitly lists standard and variant section headings with explanation that variants are from externally-sourced skills
2. **Validation logic updated**: The D4b check in project-audit SKILL.md recognizes both standard and variant headings
3. **No false negatives**: Skills with no required sections (standard OR variant) still trigger a MEDIUM finding as expected
4. **Audit score improves**: After apply, running `/project-audit` on the project shows 0 MEDIUM findings for D4b format contract violations on the 21 affected skills
5. **No regressions**: All other audit dimensions continue to pass; no new findings are introduced

---

## Edge Cases and Clarifications

### Edge case: Skill has both standard and variant sections

- **GIVEN** a reference skill with both `## Patterns` and `## Critical Patterns` sections
- **THEN** the skill is compliant (both are accepted)

### Edge case: Multiple variant sections of the same type

- **GIVEN** a reference skill with both `## Code Examples` and `## Examples` sections
- **THEN** the skill is compliant (at least one variant is present)

### Edge case: Unknown section headings (not standard or variant)

- **GIVEN** a reference skill with a custom section like `## Usage Notes` (not `## Patterns`, `## Examples`, `## Critical Patterns`, or `## Code Examples`)
- **WHEN** D4b validation runs
- **THEN** it MUST emit a MEDIUM finding (custom heading is not an accepted variant)

---
