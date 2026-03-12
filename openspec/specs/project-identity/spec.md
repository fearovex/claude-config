# Spec: Project Identity

Change: 2026-03-12-rename-to-agent-config
Date: 2026-03-12

## Requirements

### Requirement: Project name references in user-facing documentation MUST be updated

All user-facing documentation files (README.md, CLAUDE.md) MUST identify the project as "agent-config" rather than "claude-config". The project title, description, and architecture diagram references MUST reflect the new name.

#### Scenario: README.md identifies the correct project name

- **GIVEN** README.md exists at the project root
- **WHEN** a user reads the file
- **THEN** the project title and description reference "agent-config", not "claude-config"
- **AND** no remaining instances of "claude-config" appear in project-identity positions (title, heading, description)

#### Scenario: CLAUDE.md architecture diagram reflects the new name

- **GIVEN** CLAUDE.md contains the architecture diagram with the repo name
- **WHEN** a user reads the diagram
- **THEN** the repo identifier in the diagram reads "agent-config (repo)", not "claude-config (repo)"
- **AND** any path example referencing `~/claude-config` reads `~/agent-config`

#### Scenario: Edge case — occurrences inside ADR historical content are preserved

- **GIVEN** a docs/adr/*.md file contains "claude-config" as part of the historical record of a decision
- **WHEN** the rename change is applied
- **THEN** those ADR body references are NOT changed, preserving historical accuracy
- **AND** only the ADR index (docs/adr/README.md) project-context references are updated if applicable

---

### Requirement: openspec/config.yaml project metadata MUST be updated

The `name` and `root` fields in openspec/config.yaml MUST reflect "agent-config".

#### Scenario: config.yaml name field updated

- **GIVEN** openspec/config.yaml contains `name: claude-config`
- **WHEN** the rename change is applied
- **THEN** the field reads `name: agent-config`

#### Scenario: config.yaml root field updated

- **GIVEN** openspec/config.yaml contains a `root` field with a value referencing "claude-config"
- **WHEN** the rename change is applied
- **THEN** the `root` field references "agent-config"

#### Scenario: Edge case — config.yaml does not contain root field

- **GIVEN** openspec/config.yaml has no `root` field
- **WHEN** the rename change is applied
- **THEN** only the `name` field is updated and no other fields are touched

---

### Requirement: ai-context/ project memory files MUST reference the new project name

The five ai-context/ files (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md) MUST reference "agent-config" wherever they refer to the project's own identity.

#### Scenario: stack.md project identity section is updated

- **GIVEN** ai-context/stack.md contains "claude-config" in its project identity heading or description
- **WHEN** the rename change is applied
- **THEN** the heading or description reads "agent-config"

#### Scenario: architecture.md project identity references are updated

- **GIVEN** ai-context/architecture.md contains "claude-config" as a project name reference
- **WHEN** the rename change is applied
- **THEN** those references read "agent-config"

#### Scenario: conventions.md project identity references are updated

- **GIVEN** ai-context/conventions.md contains "claude-config" in headings or project-context prose
- **WHEN** the rename change is applied
- **THEN** those references read "agent-config"

#### Scenario: known-issues.md and changelog-ai.md are updated

- **GIVEN** known-issues.md or changelog-ai.md reference "claude-config" as the project name
- **WHEN** the rename change is applied
- **THEN** those references read "agent-config"

#### Scenario: Edge case — references embedded in historical changelog entries

- **GIVEN** changelog-ai.md contains "claude-config" inside a historical session record that describes a past action
- **WHEN** the rename change is applied
- **THEN** the project-identity header/title of the file is updated but session-level prose MAY be left intact if ambiguous
- **AND** the decision is documented in the verify-report

---

### Requirement: SKILL.md files MUST be reviewed and project-name references updated

All SKILL.md files that contain "claude-config" in example paths, step descriptions, or project-context references MUST be updated to "agent-config". Files that do not reference the project name by name require no changes.

#### Scenario: A SKILL.md uses ~/claude-config in a path example

- **GIVEN** a SKILL.md file contains an example path such as `~/claude-config/`
- **WHEN** the rename change is applied
- **THEN** the path reads `~/agent-config/`

#### Scenario: A SKILL.md uses the project name in a descriptive step

- **GIVEN** a SKILL.md step description says "the claude-config repo"
- **WHEN** the rename change is applied
- **THEN** the description reads "the agent-config repo"

#### Scenario: Edge case — a SKILL.md references ~/.claude/ (runtime path)

- **GIVEN** a SKILL.md contains `~/.claude/` as a path reference
- **WHEN** the rename change is applied
- **THEN** the path `~/.claude/` is NOT changed (it is immutable — controlled by Claude Code)

#### Scenario: Edge case — a SKILL.md has no project-name reference

- **GIVEN** a SKILL.md file contains no occurrence of "claude-config"
- **WHEN** the rename change is applied
- **THEN** the file is not modified

---

### Requirement: Post-apply verification MUST confirm coverage

After applying all changes, a verification pass MUST confirm that the remaining occurrences of "claude-config" in the repository are only in intentional positions (examples, historical ADR content, or incidental non-identity references).

#### Scenario: grep search returns acceptable count

- **GIVEN** the rename change has been fully applied
- **WHEN** `grep -r "claude-config" .` is executed (excluding .git/)
- **THEN** the number of remaining matches is fewer than 5
- **AND** each remaining match is reviewed and confirmed to be an intentional non-identity reference

#### Scenario: install.sh and sync.sh continue to work unchanged

- **GIVEN** install.sh uses relative paths and sync.sh uses `$HOME/.claude`
- **WHEN** `bash install.sh` is executed after the rename change
- **THEN** the script completes without error
- **AND** the runtime directory `~/.claude/` is correctly populated

#### Scenario: Edge case — a remaining reference is ambiguous

- **GIVEN** a file contains "claude-config" and it is unclear whether it is project-identity or incidental
- **WHEN** the verification pass finds it
- **THEN** the implementer MUST make an explicit decision: update or preserve
- **AND** the decision MUST be recorded in verify-report.md
