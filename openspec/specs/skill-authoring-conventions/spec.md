# Spec: skill-authoring-conventions

Change: sdd-project-context-awareness
Date: 2026-03-10

---

## Requirements

### Requirement: Context injection pattern documented for skill authors

A documentation file describing the Step 0 context loading pattern MUST exist at `docs/sdd-context-injection.md`. This file MUST be created as part of the `sdd-project-context-awareness` change.

The documentation MUST cover:
- The purpose of Step 0 (why project context must be loaded before phase output)
- The four sources: `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, project `CLAUDE.md` Skills Registry
- The optional domain context preload (Sub-step B) from the base `sdd-phase-context-loading` spec
- Graceful degradation behavior when files are absent
- The staleness warning threshold (7 days)
- A code block showing the canonical Step 0 template that skill authors MUST copy when creating new SDD phase skills

#### Scenario: docs/sdd-context-injection.md exists after apply

- **GIVEN** the `sdd-project-context-awareness` change has been applied
- **WHEN** the project root is inspected
- **THEN** `docs/sdd-context-injection.md` MUST exist
- **AND** the file MUST contain at minimum: a purpose section, a Step 0 template code block, and a graceful degradation section

#### Scenario: New SDD phase skill can copy Step 0 from the documentation

- **GIVEN** a skill author creates a new SDD phase skill (e.g., `sdd-refactor`)
- **WHEN** they refer to `docs/sdd-context-injection.md`
- **THEN** they MUST find a ready-to-copy Step 0 template block that satisfies the context loading requirement
- **AND** the template MUST be presented in Markdown as a fenced code block

#### Scenario: Documentation does not prescribe implementation technology

- **GIVEN** `docs/sdd-context-injection.md` describes the Step 0 pattern
- **WHEN** a skill author reads it
- **THEN** the instructions MUST be expressed in plain language and Markdown
- **AND** MUST NOT assume a specific programming language or shell tool for file reading
