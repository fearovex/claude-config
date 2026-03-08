# Spec: skill-template-noise

Change: clean-skill-template-noise
Date: 2026-03-08

## Requirements

### Requirement: active report templates use balanced nested fences

Active skill examples that show Markdown containing inner fenced blocks MUST use a balanced nested
fence structure so the example remains readable and mechanically unambiguous.

#### Scenario: project-audit report example uses one clean nested fence pattern

- **GIVEN** a developer reads `skills/project-audit/SKILL.md`
- **WHEN** they inspect the `## Report Format` example
- **THEN** the example opens one outer Markdown fence and one inner YAML fence
- **AND** the YAML fence closes exactly once
- **AND** the outer Markdown fence closes exactly once
- **AND** there are no stray extra fence-closure lines after the example body

---

### Requirement: scaffold examples use explicit placeholder wording

Active scaffold examples MAY contain placeholder guidance, but they SHOULD make the scaffold status
explicit without using raw `TODO` markers that look like unfinished live instructions.

#### Scenario: project-fix stub templates remain explicit without raw TODO markers

- **GIVEN** a developer reads the example stub templates in `skills/project-fix/SKILL.md`
- **WHEN** they inspect the placeholder text inside the example blocks
- **THEN** the text explains that the content is scaffold text to replace
- **AND** the targeted example lines do not contain raw `TODO` markers

#### Scenario: project-claude-organizer scaffolded SKILL examples remain explicit without raw TODO markers

- **GIVEN** a developer reads the generated SKILL examples in `skills/project-claude-organizer/SKILL.md`
- **WHEN** they inspect the scaffold placeholder text inside the example blocks
- **THEN** the text explains that the content is scaffold text to replace
- **AND** the targeted example lines do not contain raw `TODO` markers

## Rules

- This change MUST NOT alter command names or command triggers.
- This change MUST NOT alter execution behavior, mutation authority, or safety boundaries.
- The cleanup applies only to active example/template content in the targeted skills.