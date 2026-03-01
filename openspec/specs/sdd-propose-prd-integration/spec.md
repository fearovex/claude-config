# Spec: sdd-propose-prd-integration

Change: sdd-cycle-prd-adr-integration
Date: 2026-03-01

## Requirements

### Requirement: PRD shell auto-creation during sdd-propose

When `sdd-propose` runs and `proposal.md` has been written, it MUST check whether a
`prd.md` file already exists at `openspec/changes/<change-name>/prd.md`. If the file does
not exist and `docs/templates/prd-template.md` is present, the skill MUST create a pre-filled
`prd.md` shell at that path. The shell MUST populate the frontmatter (title from change-name,
date from today, a related-change pointer to the change name) and leave the body sections as
template placeholders for the user to fill in. If the template is absent, the skill MUST log a
warning and skip creation without failing the cycle.

#### Scenario: PRD shell created when no prd.md exists and template is present
- **GIVEN** `sdd-propose` has just written `proposal.md` for change "my-feature"
- **AND** `openspec/changes/my-feature/prd.md` does NOT exist
- **AND** `docs/templates/prd-template.md` exists in the repository
- **WHEN** the post-proposal PRD step executes
- **THEN** `openspec/changes/my-feature/prd.md` is created
- **AND** its frontmatter contains a `title` derived from "my-feature"
- **AND** its frontmatter contains today's date
- **AND** its frontmatter contains a `related-change` field pointing to "my-feature"
- **AND** the body sections are copied from the template (problem statement, user stories, etc.) with placeholders intact

#### Scenario: Existing prd.md is not overwritten
- **GIVEN** `sdd-propose` has just written `proposal.md` for change "my-feature"
- **AND** `openspec/changes/my-feature/prd.md` already exists with user-written content
- **WHEN** the post-proposal PRD step executes
- **THEN** `openspec/changes/my-feature/prd.md` is NOT modified
- **AND** its existing content remains intact

#### Scenario: PRD step skipped gracefully when template is absent
- **GIVEN** `sdd-propose` has just written `proposal.md` for change "my-feature"
- **AND** `openspec/changes/my-feature/prd.md` does NOT exist
- **AND** `docs/templates/prd-template.md` does NOT exist in the repository
- **WHEN** the post-proposal PRD step executes
- **THEN** no `prd.md` file is created
- **AND** a warning is reported in the skill output (e.g., "PRD template not found — skipping PRD shell creation")
- **AND** the proposal phase is NOT marked as failed or blocked

#### Scenario: Proposal cycle completes when PRD is skipped
- **GIVEN** `sdd-propose` runs for any change
- **AND** PRD shell creation is skipped (either template absent or prd.md already exists)
- **WHEN** the proposal phase finishes
- **THEN** the orchestrator receives `status: ok` (not `blocked` or `failed`)
- **AND** the artifact list in the output contains `proposal.md` as the required artifact
- **AND** `prd.md` is listed only if it was created in this run

### Requirement: PRD shell is listed in skill output artifacts

When `sdd-propose` creates a `prd.md` shell, the skill output MUST include the path to `prd.md`
in its `artifacts` list alongside `proposal.md`. If no `prd.md` was created, only `proposal.md`
MUST appear in the artifacts list.

#### Scenario: Artifacts list includes prd.md when created
- **GIVEN** a successful `sdd-propose` run that created a `prd.md` shell
- **WHEN** the orchestrator receives the skill output
- **THEN** the `artifacts` field contains `openspec/changes/<change-name>/proposal.md`
- **AND** the `artifacts` field also contains `openspec/changes/<change-name>/prd.md`

#### Scenario: Artifacts list excludes prd.md when not created
- **GIVEN** a successful `sdd-propose` run where PRD creation was skipped
- **WHEN** the orchestrator receives the skill output
- **THEN** the `artifacts` field contains only `openspec/changes/<change-name>/proposal.md`
- **AND** `prd.md` does NOT appear in the artifacts list

### Requirement: User is informed that prd.md is optional

After creating the PRD shell, `sdd-propose` MUST include a note in its summary informing
the user that `prd.md` is optional and intended to be filled in for product-level changes.
The note MUST NOT imply that the SDD cycle depends on the PRD being completed.

#### Scenario: Summary contains an explanatory note about prd.md
- **GIVEN** `sdd-propose` has created a `prd.md` shell
- **WHEN** the summary is presented to the user or returned to the orchestrator
- **THEN** the summary states that `prd.md` is optional
- **AND** the summary instructs the user to fill it in if the change is product-facing
- **AND** the summary does NOT say the cycle is blocked pending PRD completion
