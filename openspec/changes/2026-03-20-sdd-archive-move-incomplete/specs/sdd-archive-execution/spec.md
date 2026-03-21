# Delta Spec: sdd-archive-execution

Change: 2026-03-20-sdd-archive-move-incomplete
Date: 2026-03-20
Base: openspec/specs/sdd-archive-execution/spec.md

## ADDED — New requirements

### Requirement: Step 4 MUST delete the source directory after successful copy

_(Added in: 2026-03-20 by change "sdd-archive-move-incomplete")_

The `sdd-archive` skill's Step 4 ("Move to archive") MUST delete the source directory
`openspec/changes/<change-name>/` and all its contents after ALL files have been confirmed
written to the archive destination `openspec/changes/archive/<date>-<change-name>/`.

Source deletion MUST occur only when the copy is confirmed complete. The source directory
MUST NOT exist after Step 4 completes successfully. If deletion fails after a successful
copy, `sdd-archive` MUST report a WARNING (not `status: failed`) and instruct the user to
delete the source directory manually before proceeding.

#### Scenario: Happy path — source directory is deleted after successful copy

- **GIVEN** all files from `openspec/changes/<change-name>/` have been written to
  `openspec/changes/archive/<date>-<change-name>/`
- **WHEN** Step 4 of `sdd-archive` executes the deletion instruction
- **THEN** `openspec/changes/<change-name>/` MUST be deleted along with all its contents
- **AND** the source directory MUST NOT exist after Step 4 completes
- **AND** execution proceeds to Step 5 without any prompt or user interaction

#### Scenario: Source deletion is gated on copy confirmation

- **GIVEN** `sdd-archive` is executing Step 4
- **WHEN** the copy of all files to the destination begins
- **THEN** the deletion instruction MUST NOT execute until all files are confirmed present
  at the destination path
- **AND** the skill MUST verify the destination before deleting the source
- **AND** no partial-copy + delete scenario MUST occur

#### Scenario: Deletion failure after successful copy does not block archive

- **GIVEN** all files have been copied to the archive destination
- **AND** the deletion of `openspec/changes/<change-name>/` fails (e.g., a file is locked
  or the LLM tool call returns an error)
- **WHEN** Step 4 attempts to delete the source directory
- **THEN** `sdd-archive` MUST continue to Step 5 (not halt)
- **AND** the output MUST include a WARNING stating the source could not be deleted
- **AND** the WARNING MUST include the exact path to delete manually
- **AND** `status` MUST be `warning`, NEVER `failed` due to this deletion step alone

#### Scenario: Ghost duplicate no longer exists after archive

- **GIVEN** an SDD change `example-feature` is successfully archived via `sdd-archive`
- **WHEN** the archive operation completes (Step 4 through Step 7)
- **THEN** `openspec/changes/example-feature/` MUST NOT exist
- **AND** `openspec/changes/archive/<date>-example-feature/` MUST exist with all
  previously present files
- **AND** no ghost duplicate remains under `openspec/changes/`

#### Scenario: Step 4 output confirms deletion before proceeding to Step 5

- **GIVEN** Step 4 has deleted the source directory successfully
- **WHEN** the step produces its output before transitioning to Step 5
- **THEN** the output MUST include a confirmation line stating that the source directory
  has been deleted (e.g., "Source directory deleted: openspec/changes/<change-name>/")
- **AND** this confirmation MUST appear before Step 5 begins

---

### Requirement: Step 4 MUST preserve the date-stripping pre-flight block

_(Added in: 2026-03-20 by change "sdd-archive-move-incomplete")_

The date-stripping pre-flight logic introduced by change `sdd-archive-orphan-validation`
(which removes an existing `YYYY-MM-DD-` prefix from the change name before prepending
the current date) MUST remain intact and unmodified in Step 4. The source-deletion
instruction is additive — it MUST NOT alter or remove any existing Step 4 logic.

#### Scenario: Existing date prefix is stripped before destination path is computed

- **GIVEN** a change name that already includes a date prefix (e.g., `2026-03-18-my-change`)
- **WHEN** Step 4 computes the archive destination path
- **THEN** the existing date prefix is stripped and replaced with the current date
- **AND** the destination path is `openspec/changes/archive/<today>-my-change/` (not
  `openspec/changes/archive/<today>-2026-03-18-my-change/`)
- **AND** the source deletion path uses the original change name
  `openspec/changes/2026-03-18-my-change/` (not the stripped version)

---

## Rules

- Source deletion is mandatory — it is not optional or advisory. Step 4 MUST delete the
  source unless the deletion itself fails (in which case WARNING + manual instruction).
- The precondition for deletion is destination confirmation. A deletion that precedes
  destination confirmation is a spec violation.
- The date-stripping pre-flight block is treated as immutable by this delta. Any future
  change to it requires its own SDD cycle.
- The `status: warning` floor for deletion failures ensures the archive is not re-run
  (which would attempt to copy already-archived files to the destination again).
