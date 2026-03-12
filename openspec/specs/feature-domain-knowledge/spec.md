# Spec: feature-domain-knowledge

Change: feature-domain-knowledge-layer
Date: 2026-03-03

---

## Requirements

### Requirement: Template existence and canonical section structure

The system MUST provide a canonical template file at `ai-context/features/_template.md` that defines all required sections for any feature knowledge file. Every feature file authored in `ai-context/features/` MUST follow this template.

The template MUST contain the following six named sections, in order:

1. **Domain Overview** — one-paragraph description of what the bounded context is, what problem it solves, and its primary role in the system
2. **Business Rules and Invariants** — explicit statements of rules the domain enforces that are always true regardless of code path
3. **Data Model Summary** — key entities, their relationships, and any critical field constraints (not a full schema; narrative + key fields only)
4. **Integration Points** — other domains, services, or external APIs this domain depends on or exposes interfaces to
5. **Decision Log** — chronological record of significant design or implementation decisions made for this domain, with rationale
6. **Known Gotchas** — unexpected behaviors, operational hazards, historical defects, or non-obvious constraints that a developer working in this domain MUST be aware of

#### Scenario: Template file exists with all six sections

- **GIVEN** the `agent-config` repository after this change is applied
- **WHEN** a developer opens `ai-context/features/_template.md`
- **THEN** the file exists and contains all six section headers: Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas
- **AND** each section contains placeholder text explaining what to write there
- **AND** the file header includes a comment clarifying that `_template.md` is not a feature file and MUST NOT be loaded by SDD phases

#### Scenario: Feature file authored from template is structurally valid

- **GIVEN** a developer copies `_template.md` to `ai-context/features/payments.md` and fills in the sections
- **WHEN** the file is reviewed for structural completeness
- **THEN** any file containing all six section headers is considered structurally valid
- **AND** the system does not enforce mandatory content for any section — sections MAY be left with placeholder text when the domain is not yet understood

#### Scenario: Template is skipped by the preload heuristic

- **GIVEN** the `ai-context/features/` directory contains `_template.md` and `payments.md`
- **WHEN** an SDD phase searches for a feature file matching a domain slug
- **THEN** `_template.md` MUST NOT be returned as a match regardless of any slug heuristic
- **AND** only `payments.md` is considered a candidate for preloading

---

### Requirement: Feature file naming and domain discovery convention

Feature knowledge files MUST follow a consistent naming convention to enable heuristic domain matching by SDD phases.

- Files MUST be named `<domain-slug>.md` where `<domain-slug>` is a lowercase, hyphen-separated identifier for the bounded context (e.g., `auth.md`, `payments.md`, `notifications.md`)
- The `ai-context/features/` directory MUST NOT contain subdirectories — all feature files live at the top level of the directory
- No file other than `_template.md` may use a leading underscore prefix

#### Scenario: Domain slug matches a feature file

- **GIVEN** `ai-context/features/` contains `payments.md`
- **WHEN** an SDD phase needs to determine whether a feature file exists for the slug `payments`
- **THEN** the phase reads `ai-context/features/payments.md`
- **AND** the phase uses the file's content to enrich its context

#### Scenario: Domain slug does not match any feature file

- **GIVEN** `ai-context/features/` contains only `auth.md` and `_template.md`
- **WHEN** an SDD phase evaluates whether a file exists for the slug `payments`
- **THEN** no feature file is loaded
- **AND** the phase proceeds normally without domain context enrichment
- **AND** no error or warning is produced

#### Scenario: Feature file directory is absent

- **GIVEN** the project does not have an `ai-context/features/` directory
- **WHEN** an SDD phase evaluates the domain context preload step
- **THEN** the phase MUST skip the preload step silently
- **AND** proceed to its next step without error

---

### Requirement: New feature-domain-expert skill

A new skill MUST be created at `skills/feature-domain-expert/SKILL.md` with `format: reference`. The skill serves as the authoritative guide for authoring and consuming feature knowledge files.

The skill MUST satisfy the `reference` format contract:
- YAML frontmatter with `name:`, `description:`, `format: reference`
- `**Triggers**` section
- `## Patterns` section (the main reference content)
- `## Rules` section

The skill MUST document:
- What a feature knowledge file is and what it is NOT (contrast with `openspec/specs/<domain>/spec.md`)
- When to create a new feature file
- What belongs in each of the six template sections
- How SDD phases consume feature files (domain slug matching heuristic)
- How to update a feature file after a session (via `/memory-update`)
- One worked example demonstrating a realistic feature knowledge file (either real or illustrative)

#### Scenario: feature-domain-expert skill is accessible and structurally valid

- **GIVEN** the change is applied and `install.sh` has been run
- **WHEN** `~/.claude/skills/feature-domain-expert/SKILL.md` is opened
- **THEN** the file exists with `format: reference` declared in YAML frontmatter
- **AND** it contains `**Triggers**`, `## Patterns`, and `## Rules` sections

#### Scenario: Skill clearly distinguishes feature docs from domain specs

- **GIVEN** a developer reads `feature-domain-expert/SKILL.md`
- **WHEN** they look for guidance on what to put in a feature file vs. an `openspec/specs/` file
- **THEN** the skill MUST explicitly state that `openspec/specs/<domain>/spec.md` encodes observable behavior (GIVEN/WHEN/THEN scenarios)
- **AND** `ai-context/features/<domain>.md` encodes business rules, invariants, integration context, and domain history
- **AND** neither file duplicates the other's content

#### Scenario: Worked example is present and realistic

- **GIVEN** a developer reads the skill to understand the feature doc format
- **WHEN** they look at the examples section
- **THEN** at least one complete worked example of a feature file MUST be present
- **AND** the example MUST demonstrate all six template sections with realistic (not placeholder) content

---

### Requirement: Worked example feature file in repository

The repository MUST contain at least one real or illustrative feature file in `ai-context/features/` (other than `_template.md`) to demonstrate the format in use.

#### Scenario: Example feature file exists after apply

- **GIVEN** the change is applied
- **WHEN** `ai-context/features/` is listed
- **THEN** at least one file other than `_template.md` exists with a valid domain slug name
- **AND** the file contains content in all six sections (not placeholder text)

#### Scenario: Example feature file does not interfere with SDD phases

- **GIVEN** the example feature file exists (e.g., `ai-context/features/sdd-meta-system.md`)
- **WHEN** an SDD phase runs for a change whose name does not match the example domain slug
- **THEN** the example file is NOT loaded
- **AND** the phase proceeds normally

