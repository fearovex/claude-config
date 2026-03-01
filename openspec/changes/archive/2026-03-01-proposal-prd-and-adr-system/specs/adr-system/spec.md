# Spec: adr-system

Change: proposal-prd-and-adr-system
Date: 2026-03-01

## Requirements

### Requirement: ADR directory convention

A `docs/adr/` directory MUST exist in the repository. All ADR files MUST follow the naming
convention `NNN-short-title.md` where `NNN` is a zero-padded three-digit sequential number and
`short-title` is a lowercase kebab-case summary of the decision.

#### Scenario: ADR directory exists after apply
- **GIVEN** the ADR system has been applied to the repository
- **WHEN** the `docs/adr/` path is inspected
- **THEN** the directory exists
- **AND** it contains at least one `README.md` and at least three ADR files

#### Scenario: ADR files follow the naming convention
- **GIVEN** ADR files are present in `docs/adr/`
- **WHEN** the filenames are listed
- **THEN** each ADR filename matches the pattern `[0-9]{3}-[a-z0-9-]+\.md`
- **AND** no two files share the same numeric prefix

#### Scenario: ADR directory is absent before this change is applied
- **GIVEN** the repository at the state prior to this SDD cycle
- **WHEN** `docs/adr/` is inspected
- **THEN** the directory does not exist
- **AND** creating it is safe (no naming conflict with existing structure)

### Requirement: ADR template

A Markdown template MUST exist at `docs/templates/adr-template.md` following the Nygard ADR
format. The template MUST contain these sections in order: Title, Status, Context, Decision,
Consequences. The Status field MUST list valid states: Proposed, Accepted, Deprecated, Superseded.

#### Scenario: Template file exists with all required Nygard sections
- **GIVEN** the repository has been updated with the ADR system
- **WHEN** a user opens `docs/templates/adr-template.md`
- **THEN** the file contains a "Title" section or heading
- **AND** a "Status" field with at least the values: Proposed, Accepted, Deprecated, Superseded
- **AND** a "Context" section
- **AND** a "Decision" section
- **AND** a "Consequences" section

#### Scenario: Template is usable as a copy-paste starting point
- **GIVEN** the `docs/templates/adr-template.md` file exists
- **WHEN** a user copies it to `docs/adr/NNN-new-decision.md` and opens it
- **THEN** each section has a placeholder or brief instruction
- **AND** the file renders correctly as Markdown (no broken syntax)

### Requirement: ADR README index

`docs/adr/README.md` MUST exist and serve as an index. It MUST explain the ADR convention (naming,
numbering, lifecycle) and list all existing ADRs with their number, title, and current status.

#### Scenario: README lists all ADRs with number, title, and status
- **GIVEN** `docs/adr/README.md` exists
- **WHEN** a user reads it
- **THEN** every ADR file in `docs/adr/` is represented as a row or list entry
- **AND** each entry shows: the ADR number, the decision title, and the current status
- **AND** the README is updated whenever a new ADR is added

#### Scenario: README explains the ADR lifecycle
- **GIVEN** `docs/adr/README.md` exists
- **WHEN** a user reads it for the first time
- **THEN** the file explains what ADR status values mean (Proposed, Accepted, Deprecated, Superseded)
- **AND** it explains the naming convention (`NNN-short-title.md`)

### Requirement: Retroactive ADRs for existing architectural decisions

At least three retroactive ADRs MUST be created, each capturing a key architectural decision
already embedded in the system. Each ADR MUST have Status set to "Accepted (retroactive)" and
MUST include a note that the decision predates the ADR system. The ADR content MUST be derived
from existing documentation in `ai-context/architecture.md`, not invented.

The following decisions MUST be covered at minimum:
- Skills as directories (one directory per skill, `SKILL.md` entry point)
- Artifacts over in-memory state (skills communicate via files, not conversation context)
- Orchestrator delegates everything (global CLAUDE.md never executes work, always spawns sub-agents)

#### Scenario: Each retroactive ADR follows the Nygard format
- **GIVEN** a retroactive ADR file in `docs/adr/`
- **WHEN** the file is opened
- **THEN** it contains all five Nygard sections: Title, Status, Context, Decision, Consequences
- **AND** Status is "Accepted (retroactive)"
- **AND** there is a note indicating the decision predates the ADR system

#### Scenario: ADR content is consistent with existing architecture documentation
- **GIVEN** a retroactive ADR describing an architectural decision
- **WHEN** its Decision and Context sections are compared to `ai-context/architecture.md`
- **THEN** no factual contradiction exists between the two documents
- **AND** the ADR does not introduce new architectural claims not present in existing documentation

#### Scenario: Retroactive ADR for "skills as directories" decision
- **GIVEN** ADR `001-skills-as-directories.md` exists
- **WHEN** its content is read
- **THEN** it explains that every skill is a directory with a single `SKILL.md` entry point
- **AND** it notes the rationale (allows co-locating templates, examples, or sub-skills)
- **AND** Status is "Accepted (retroactive)"

#### Scenario: Retroactive ADR for "artifacts over in-memory state" decision
- **GIVEN** ADR `002-artifacts-over-memory.md` (or similar) exists
- **WHEN** its content is read
- **THEN** it explains that skills pass state via file artifacts, never via conversation context alone
- **AND** it lists examples of artifact producers and consumers
- **AND** Status is "Accepted (retroactive)"

#### Scenario: Retroactive ADR for "orchestrator delegates everything" decision
- **GIVEN** ADR `003-orchestrator-delegates-everything.md` (or similar) exists
- **WHEN** its content is read
- **THEN** it explains that CLAUDE.md never executes work directly and always spawns sub-agents via Task tool
- **AND** Status is "Accepted (retroactive)"

### Requirement: CLAUDE.md references the ADR convention

The project `CLAUDE.md` MUST reference `docs/adr/` so that new Claude sessions are aware of the
ADR system when starting work on significant architectural changes. The reference MUST be brief
and placed in a documentation or conventions section.

#### Scenario: CLAUDE.md mentions the ADR directory
- **GIVEN** `CLAUDE.md` has been updated
- **WHEN** a Claude session reads `CLAUDE.md` at session start
- **THEN** the file references `docs/adr/` or the ADR convention
- **AND** the reference points to `docs/adr/README.md` or the ADR template for guidance

#### Scenario: install.sh deploys docs/ to runtime
- **GIVEN** `docs/` directory exists in the repo with ADR files
- **WHEN** `bash install.sh` is executed
- **THEN** `~/.claude/docs/` exists and contains the ADR files
- **AND** `~/.claude/docs/adr/README.md` is present

### Requirement: ADR system does not replace ai-context/architecture.md

The ADR system MUST complement, not replace, the existing `ai-context/architecture.md`. The
existing file MUST remain unchanged in its current form (prose-based architectural overview).
No existing content in `ai-context/architecture.md` MUST be deleted or migrated to ADRs.

#### Scenario: architecture.md remains intact after apply
- **GIVEN** the ADR system has been applied
- **WHEN** `ai-context/architecture.md` is read
- **THEN** all sections that existed before this change are still present and unmodified
- **AND** the file does not reference ADRs as its replacement

#### Scenario: ADRs and architecture.md can coexist without contradiction
- **GIVEN** both `ai-context/architecture.md` and `docs/adr/` exist
- **WHEN** a user reads both
- **THEN** the same decision is not described in contradictory terms across the two documents
- **AND** the ADRs offer structured decision records while architecture.md offers narrative context
