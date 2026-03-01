# Spec: prd-system

Change: proposal-prd-and-adr-system
Date: 2026-03-01

## Requirements

### Requirement: PRD template artifact

A PRD template file MUST exist at `docs/templates/prd-template.md`. It MUST contain the following
sections in order: problem statement, target users, user stories (MoSCoW priority), non-functional
requirements, and acceptance criteria. Each section MUST include a placeholder or brief instruction
so a user can fill it in without external guidance.

#### Scenario: Template file exists with all required sections
- **GIVEN** the repository has been updated with the PRD system
- **WHEN** a user opens `docs/templates/prd-template.md`
- **THEN** the file contains a "Problem Statement" section
- **AND** a "Target Users" section
- **AND** a "User Stories" section with MoSCoW (Must/Should/Could/Won't) notation
- **AND** a "Non-Functional Requirements" section
- **AND** an "Acceptance Criteria" section

#### Scenario: Template is self-explanatory without external docs
- **GIVEN** the `docs/templates/prd-template.md` file exists
- **WHEN** a user reads it for the first time with no prior context
- **THEN** each section contains a placeholder comment or instruction (e.g., `<!-- describe the problem here -->`)
- **AND** no section is empty or unlabeled

#### Scenario: Template does not enforce PRD as a mandatory gate
- **GIVEN** a developer wants to start an SDD cycle directly with `/sdd-ff`
- **WHEN** they skip creating a PRD document
- **THEN** no SDD skill or hook blocks or rejects the cycle
- **AND** the PRD remains an optional advisory artifact

### Requirement: PRD usage guidance in conventions

`ai-context/conventions.md` MUST contain a paragraph that clarifies when a PRD is appropriate
versus going directly to `/sdd-ff`. The guidance MUST state that a PRD is optional, that it is
most useful for user-facing or product-level changes, and that it feeds into `proposal.md` rather
than replacing it.

#### Scenario: Conventions file documents PRD usage
- **GIVEN** `ai-context/conventions.md` has been updated
- **WHEN** a user reads the file
- **THEN** there is a section or paragraph titled "PRD usage" (or equivalent)
- **AND** it states that PRD is optional for purely technical changes
- **AND** it states that PRD precedes `proposal.md` for product-level changes

#### Scenario: Guidance does not conflict with existing SDD workflow description
- **GIVEN** the PRD guidance paragraph is added to `ai-context/conventions.md`
- **WHEN** the full SDD workflow section is read alongside it
- **THEN** the two sections do not contradict each other
- **AND** the existing minimum SDD workflow (`/sdd-ff → apply → commit`) is unchanged

### Requirement: CLAUDE.md references the PRD convention

The project `CLAUDE.md` (and the global `~/.claude/CLAUDE.md` after `install.sh`) MUST reference
the existence of the PRD template so that Claude sessions are aware of it when starting work on
user-facing changes. The reference MUST be brief — a pointer to the file, not a full reproduction.

#### Scenario: CLAUDE.md contains a pointer to the PRD template
- **GIVEN** `CLAUDE.md` has been updated
- **WHEN** a user or Claude session reads the CLAUDE.md
- **THEN** the file mentions `docs/templates/prd-template.md` or the `docs/` directory
- **AND** the reference is in a documentation or conventions section (not buried in an unrelated section)

#### Scenario: install.sh deploys the CLAUDE.md change to runtime
- **GIVEN** `CLAUDE.md` references the PRD template
- **WHEN** `bash install.sh` is executed
- **THEN** the updated `CLAUDE.md` is present at `~/.claude/CLAUDE.md`
- **AND** the `docs/` directory is deployed to `~/.claude/docs/`
