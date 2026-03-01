# Spec: sdd-design-adr-integration

Change: sdd-cycle-prd-adr-integration
Date: 2026-03-01

## Requirements

### Requirement: ADR auto-creation when a significant architectural decision is detected

After `sdd-design` writes `design.md`, it MUST scan the Technical Decisions table in that file
for entries that are architecturally significant. A decision is architecturally significant if it
meets at least one of the following heuristics: it affects a cross-cutting concern (e.g., error
handling strategy, skill communication protocol), it introduces a pattern not previously documented
in `ai-context/architecture.md`, or it changes a convention previously recorded in `ai-context/`.
If at least one such decision is found, `sdd-design` MUST create a new ADR file in `docs/adr/`
using `docs/templates/adr-template.md` and MUST append an entry to `docs/adr/README.md`. If no
significant decision is found, the step MUST be skipped silently.

#### Scenario: ADR created when design contains a significant architectural decision
- **GIVEN** `sdd-design` has written `design.md` for change "new-skill"
- **AND** the Technical Decisions table in `design.md` contains a decision flagged as architecturally significant
- **AND** `docs/templates/adr-template.md` exists
- **AND** `docs/adr/README.md` exists
- **WHEN** the post-design ADR step executes
- **THEN** a new file is created at `docs/adr/NNN-<slug>.md` where `NNN` is the next sequential number
- **AND** the file is pre-filled from the template with the decision's context, decision text, and consequences
- **AND** a new row is appended to `docs/adr/README.md` listing the ADR number, title, and status "Proposed"

#### Scenario: No ADR created when no significant decision is present
- **GIVEN** `sdd-design` has written `design.md` for change "minor-fix"
- **AND** the Technical Decisions table contains only non-architectural choices (e.g., variable naming, formatting)
- **WHEN** the post-design ADR step executes
- **THEN** no new file is created in `docs/adr/`
- **AND** `docs/adr/README.md` is NOT modified
- **AND** the skill does not report a warning or error about the missing ADR

#### Scenario: ADR numbering is sequential and collision-free
- **GIVEN** `docs/adr/README.md` lists existing ADRs up to number `NNN`
- **WHEN** `sdd-design` determines the next ADR number
- **THEN** the new ADR receives number `NNN+1` with zero-padded three-digit format
- **AND** no existing ADR file in `docs/adr/` shares the same numeric prefix

#### Scenario: ADR file follows the Nygard format from the template
- **GIVEN** `sdd-design` creates a new ADR file from `docs/templates/adr-template.md`
- **WHEN** the created file is opened
- **THEN** it contains all five Nygard sections: Title, Status, Context, Decision, Consequences
- **AND** Status is set to "Proposed"
- **AND** the Context and Decision sections are pre-filled with content derived from `design.md`, not left as raw template placeholders

#### Scenario: sdd-design completes normally when ADR creation is skipped
- **GIVEN** `sdd-design` runs for a change with no significant architectural decision
- **WHEN** the design phase finishes
- **THEN** the orchestrator receives `status: ok`
- **AND** `design.md` is in the artifacts list
- **AND** no ADR path appears in the artifacts list

### Requirement: ADR slug is derived from the change name and decision title

The ADR filename slug MUST be derived from the decision title (or the change name if no single
decision dominates), using lowercase kebab-case. The slug MUST NOT contain spaces, uppercase
letters, or special characters other than hyphens. The final filename MUST follow the pattern
`NNN-<slug>.md`.

#### Scenario: Slug is correctly formatted
- **GIVEN** a significant decision titled "Use file artifacts over in-memory state"
- **WHEN** `sdd-design` generates the ADR filename
- **THEN** the filename is `NNN-use-file-artifacts-over-in-memory-state.md` (or a reasonable abbreviation)
- **AND** no uppercase letters or spaces appear in the filename

#### Scenario: Slug falls back to change name when title is ambiguous
- **GIVEN** a significant decision without a clear short title
- **WHEN** `sdd-design` generates the ADR filename
- **THEN** the slug is derived from the change name instead
- **AND** the resulting filename still matches `[0-9]{3}-[a-z0-9-]+\.md`

### Requirement: Created ADR files are reported in skill output artifacts

When `sdd-design` creates one or more ADR files, all created paths MUST appear in its output
`artifacts` list alongside `design.md`. If no ADR was created, only `design.md` MUST appear.

#### Scenario: Artifacts list includes ADR paths when created
- **GIVEN** a successful `sdd-design` run that created an ADR
- **WHEN** the orchestrator receives the skill output
- **THEN** the `artifacts` field contains `openspec/changes/<change-name>/design.md`
- **AND** the `artifacts` field also contains `docs/adr/NNN-<slug>.md`
- **AND** `docs/adr/README.md` is noted as modified

#### Scenario: Artifacts list excludes ADR paths when none was created
- **GIVEN** a successful `sdd-design` run with no significant architectural decision
- **WHEN** the orchestrator receives the skill output
- **THEN** the `artifacts` field contains only `openspec/changes/<change-name>/design.md`

### Requirement: ADR creation does not block or fail the design phase

ADR creation is a best-effort, non-blocking step. If `docs/templates/adr-template.md` is
absent, if `docs/adr/README.md` is absent, or if any file operation fails, `sdd-design`
MUST log a warning and proceed to return `status: ok` (or `status: warning` if appropriate).
It MUST NOT return `status: blocked` or `status: failed` solely because of an ADR failure.

#### Scenario: Design phase succeeds even if ADR template is missing
- **GIVEN** `sdd-design` detects a significant architectural decision
- **AND** `docs/templates/adr-template.md` does NOT exist
- **WHEN** the post-design ADR step executes
- **THEN** no ADR file is created
- **AND** a warning is reported: "ADR template not found — skipping ADR creation"
- **AND** the skill returns `status: ok` or `status: warning`, not `status: blocked`

#### Scenario: Design phase succeeds even if ADR README is missing
- **GIVEN** `sdd-design` detects a significant architectural decision
- **AND** `docs/adr/README.md` does NOT exist
- **WHEN** the post-design ADR step executes
- **THEN** no ADR file is created
- **AND** a warning is reported: "docs/adr/README.md not found — skipping ADR creation"
- **AND** the skill returns `status: ok` or `status: warning`, not `status: blocked`
