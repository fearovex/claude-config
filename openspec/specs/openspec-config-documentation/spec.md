# Spec: openspec-config-documentation

Change: sdd-cycle-prd-adr-integration
Date: 2026-03-01

## Requirements

### Requirement: openspec/config.yaml documents optional artifacts

`openspec/config.yaml` MUST be updated to document `prd.md` and ADR files as optional artifacts
alongside the existing `required_artifacts_per_change` section. The additions MUST be placed under
a dedicated `optional_artifacts` key (or equivalent clearly named section) so that the distinction
between required and optional is unambiguous. The existing `required_artifacts_per_change` list
MUST remain unchanged.

#### Scenario: optional_artifacts key is present after apply
- **GIVEN** `openspec/config.yaml` has been updated
- **WHEN** the file is read
- **THEN** it contains an `optional_artifacts` key (or equivalent section)
- **AND** the key lists `prd.md` as an optional artifact for each change directory
- **AND** the key references ADR files (e.g., `docs/adr/NNN-*.md`) as optional artifacts produced by sdd-design
- **AND** each entry includes a brief annotation indicating which skill produces it

#### Scenario: required_artifacts_per_change is unchanged
- **GIVEN** `openspec/config.yaml` has been updated
- **WHEN** the `required_artifacts_per_change` key is read
- **THEN** it still lists exactly: `proposal.md`, `tasks.md`, `verify-report.md`
- **AND** no new entries have been added to the required list

#### Scenario: optional_artifacts are annotated as non-blocking
- **GIVEN** `openspec/config.yaml` lists optional artifacts
- **WHEN** a user or skill reads the file to determine what is required for archiving
- **THEN** the optional entries are clearly marked as optional (via comment or key name)
- **AND** nothing in the file implies that missing optional artifacts block archiving

### Requirement: CLAUDE.md artifact storage section reflects optional outputs

The `CLAUDE.md` SDD Artifact Storage section MUST be updated to show `prd.md` (marked optional)
under the per-change directory tree, and `docs/adr/NNN-*.md` (marked optional, produced by
sdd-design) in the overall artifact tree. The existing required artifacts MUST remain listed and
unchanged.

#### Scenario: CLAUDE.md shows prd.md as optional in the change directory tree
- **GIVEN** `CLAUDE.md` has been updated
- **WHEN** the SDD Artifact Storage section is read
- **THEN** the per-change directory tree includes `prd.md` with an "(optional)" annotation
- **AND** `proposal.md`, `specs/`, `design.md`, `tasks.md`, `verify-report.md` are still listed as before

#### Scenario: CLAUDE.md shows docs/adr/ as an optional output of sdd-design
- **GIVEN** `CLAUDE.md` has been updated
- **WHEN** the SDD Artifact Storage section is read
- **THEN** the artifact tree includes a reference to `docs/adr/NNN-*.md`
- **AND** the reference notes it is optional and produced by sdd-design

#### Scenario: CLAUDE.md changes are deployed by install.sh
- **GIVEN** `CLAUDE.md` has been updated in the repo
- **WHEN** `bash install.sh` is executed
- **THEN** `~/.claude/CLAUDE.md` reflects the updated artifact storage section
- **AND** no previously existing content in `~/.claude/CLAUDE.md` is lost
