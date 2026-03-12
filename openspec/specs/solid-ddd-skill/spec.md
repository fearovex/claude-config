# Spec: solid-ddd-skill

*Created: 2026-03-04 by change "solid-ddd-quality-enforcement"*

## Requirements

---

### Requirement: solid-ddd skill exists as a reference-format skill with correct structure

A new skill directory `skills/solid-ddd/` MUST exist in the `agent-config` repo containing exactly one `SKILL.md` entry point. The file MUST declare `format: reference` in its YAML frontmatter and satisfy the reference format section contract: `**Triggers**` (or `## Triggers`), `## Patterns` or `## Examples`, and `## Rules`.

#### Scenario: skill file is created with correct frontmatter

- **GIVEN** the `skills/solid-ddd/` directory does not exist before this change
- **WHEN** the sdd-apply phase creates the new skill
- **THEN** `skills/solid-ddd/SKILL.md` exists on disk
- **AND** the YAML frontmatter block at the top of the file contains `format: reference`
- **AND** the frontmatter contains `name: solid-ddd`

#### Scenario: reference format section contract is fully satisfied

- **GIVEN** `skills/solid-ddd/SKILL.md` exists after the change
- **WHEN** `project-audit` D4b or `claude-folder-audit` P2-C scans the file for the reference section contract
- **THEN** the scanner finds `**Triggers**` (a line starting with `**Triggers**`) or `## Triggers`
- **AND** the scanner finds `## Patterns` or `## Examples`
- **AND** the scanner finds `## Rules`
- **AND** no MEDIUM or HIGH finding is raised for this skill's section contract

#### Scenario: skill body meets minimum length threshold

- **GIVEN** `skills/solid-ddd/SKILL.md` has been written
- **WHEN** the body line count is measured (all non-frontmatter lines)
- **THEN** the line count is >= 30
- **AND** no LOW finding for insufficient body length is raised by the audit tools

---

### Requirement: solid-ddd skill documents all five SOLID principles

The `solid-ddd` skill MUST document all five SOLID principles: Single Responsibility (SRP), Open/Closed (OCP), Liskov Substitution (LSP), Interface Segregation (ISP), and Dependency Inversion (DIP). For each principle, the skill MUST provide at least one concrete do/don't pattern or code example.

#### Scenario: all five SOLID principles are present

- **GIVEN** `skills/solid-ddd/SKILL.md` has been created
- **WHEN** an agent reads the file looking for SOLID principle coverage
- **THEN** the file contains an identifiable section or pattern entry for SRP
- **AND** the file contains an identifiable section or pattern entry for OCP
- **AND** the file contains an identifiable section or pattern entry for LSP
- **AND** the file contains an identifiable section or pattern entry for ISP
- **AND** the file contains an identifiable section or pattern entry for DIP

#### Scenario: each principle has a concrete do/don't example

- **GIVEN** a sub-agent reads the `solid-ddd` skill to understand a principle
- **WHEN** the sub-agent looks for actionable guidance on any of the five SOLID principles
- **THEN** it finds at least one clear positive pattern ("DO" or equivalent) for that principle
- **AND** it finds at least one anti-pattern or negative example ("DON'T" or equivalent) for that principle
- **AND** no principle is described with only vague prose and no concrete example

---

### Requirement: solid-ddd skill documents core DDD tactical patterns

The `solid-ddd` skill MUST document the following DDD tactical patterns: Entity, Value Object, Aggregate, Repository, Domain Service, and Application Service. The skill SHOULD document the Ports & Adapters (Hexagonal Architecture) pattern as it relates to DDD layering.

#### Scenario: all required DDD patterns are covered

- **GIVEN** `skills/solid-ddd/SKILL.md` has been created
- **WHEN** an agent reads the file looking for DDD tactical pattern coverage
- **THEN** the file contains an identifiable entry for Entity
- **AND** the file contains an identifiable entry for Value Object
- **AND** the file contains an identifiable entry for Aggregate
- **AND** the file contains an identifiable entry for Repository
- **AND** the file contains an identifiable entry for Domain Service
- **AND** the file contains an identifiable entry for Application Service

#### Scenario: DDD patterns include distinguishing signals

- **GIVEN** a sub-agent reads the DDD patterns section
- **WHEN** the sub-agent needs to decide whether a concept is an Entity or a Value Object
- **THEN** the skill provides observable signals or criteria that distinguish them (e.g., identity vs. structural equality)
- **AND** the sub-agent can make the determination without external references

---

### Requirement: solid-ddd skill documents common anti-patterns to avoid

The `solid-ddd` skill MUST identify the primary structural anti-patterns that violate SOLID and DDD principles, including at minimum: God Class, Anemic Domain Model, and Service as God Object. For each anti-pattern, the skill MUST describe why it is problematic and how to detect it.

#### Scenario: god class anti-pattern is described

- **GIVEN** a sub-agent reads the `solid-ddd` skill
- **WHEN** looking for guidance on God Class detection
- **THEN** the skill describes the observable signals of a God Class (e.g., one class with more than one responsibility, high method/field count, multiple unrelated change reasons)
- **AND** the skill states that God Class violates SRP
- **AND** the skill suggests a corrective direction (e.g., extract responsibilities into focused classes)

#### Scenario: anemic domain model anti-pattern is described

- **GIVEN** a sub-agent reads the `solid-ddd` skill
- **WHEN** looking for guidance on Anemic Domain Model detection
- **THEN** the skill describes the observable signal (domain objects are pure data containers with no behavior — all logic lives in service classes)
- **AND** the skill explains why this violates DDD (domain logic leaks into the application layer)
- **AND** the skill suggests moving business behavior into the domain object itself

#### Scenario: service as god object anti-pattern is described

- **GIVEN** a sub-agent reads the `solid-ddd` skill
- **WHEN** looking for guidance on Service as God Object
- **THEN** the skill identifies the pattern (a single service class that orchestrates all domain logic with no delegation to domain objects)
- **AND** the skill explains the relationship to anemic domain model and SRP violation

---

### Requirement: solid-ddd skill documents the relationship with hexagonal-architecture-java

The `solid-ddd` skill MUST explicitly document its relationship with the `hexagonal-architecture-java` skill to prevent confusion about their intended scopes.

#### Scenario: relationship note is present

- **GIVEN** `skills/solid-ddd/SKILL.md` has been created
- **WHEN** a sub-agent reads the file
- **THEN** the file contains a note clarifying that `solid-ddd` covers language-agnostic principles
- **AND** the note clarifies that `hexagonal-architecture-java` covers Java-specific Hexagonal implementation idioms
- **AND** the note confirms that both skills may be loaded simultaneously without conflict — they are complementary, not competing

---

### Requirement: solid-ddd skill is deployed to the runtime via install.sh

After the change is applied and `install.sh` is run, `skills/solid-ddd/SKILL.md` MUST be present at `~/.claude/skills/solid-ddd/SKILL.md` so that `sdd-apply` can locate and load it during Step 0.

#### Scenario: install.sh deploys the skill to the runtime

- **GIVEN** `skills/solid-ddd/SKILL.md` exists in the repo
- **WHEN** `bash install.sh` is executed from the `agent-config` root
- **THEN** `~/.claude/skills/solid-ddd/SKILL.md` exists on disk after the command completes
- **AND** the file contents are identical to the repo source

#### Scenario: sdd-apply can load solid-ddd from the runtime path

- **GIVEN** `~/.claude/skills/solid-ddd/SKILL.md` exists at runtime
- **WHEN** `sdd-apply` Step 0 executes its Stack-to-Skill Mapping Table lookup for the solid-ddd entry
- **THEN** the skill file is found at the expected path
- **AND** its contents are loaded into the sub-agent's implementation context

---

## Rules

- The `solid-ddd` skill MUST be language-agnostic — no language-specific syntax in pattern descriptions
- Code examples (if included) MUST be labeled with their language and MUST be illustrative, not production code
- The skill MUST NOT duplicate the section contracts of `hexagonal-architecture-java` — its scope is principles and tactical DDD, not Hexagonal Architecture mechanics
- The skill MUST satisfy the `reference` format section contract before archiving; a failing contract check MUST block the archive step
