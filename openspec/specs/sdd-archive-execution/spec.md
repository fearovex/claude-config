# Spec: sdd-archive-execution

Change: integrate-memory-into-sdd-cycle
Date: 2026-02-28

## Overview

This spec defines the observable behavior of the `sdd-archive` skill after integrating an automatic `/memory-update` invocation as its final step. It also covers the informational updates to `sdd-ff` and `sdd-new` summaries.

---

## Requirements

### Requirement: Automatic memory update after archive completion

The `sdd-archive` skill MUST automatically invoke `/memory-update` as a new Step 7, after the archive operation (move + closure note) is complete. This ensures `ai-context/` files are always current after every archived SDD change.

#### Scenario: Successful archive triggers memory update automatically

- **GIVEN** an SDD change has completed all prior phases and the user has confirmed archive
- **WHEN** `sdd-archive` finishes moving the change directory to `openspec/changes/archive/` and writing the closure note (Steps 1-6)
- **THEN** `sdd-archive` automatically invokes the `memory-update` skill (reads and executes `~/.claude/skills/memory-manager/SKILL.md`)
- **AND** the change name and archive path are passed as context to `memory-update`
- **AND** no manual user action is required to trigger the memory update

#### Scenario: Memory update receives the archived change context

- **GIVEN** `sdd-archive` has completed the archive of change "my-feature"
- **WHEN** it invokes `memory-update` in Step 7
- **THEN** the invocation includes the change name ("my-feature") as context
- **AND** the invocation includes the archive path (`openspec/changes/archive/YYYY-MM-DD-my-feature/`) as context
- **AND** `memory-update` uses this context to record what was changed in `ai-context/`

#### Scenario: Memory update result is reported in archive output

- **GIVEN** `sdd-archive` has invoked `memory-update` in Step 7
- **WHEN** `memory-update` completes successfully
- **THEN** the archive output includes a confirmation that `ai-context/` was updated
- **AND** the confirmation appears as part of the standard archive output (not a separate message)

---

### Requirement: Memory update failure MUST NOT block archive completion

The `memory-update` invocation in Step 7 MUST be non-blocking. If `memory-update` fails for any reason, the archive itself MUST still be considered successful.

#### Scenario: Memory update fails but archive succeeds

- **GIVEN** `sdd-archive` has completed Steps 1-6 successfully (change is already archived)
- **WHEN** `memory-update` in Step 7 fails (e.g., file write error, skill not found, context window exceeded)
- **THEN** the archive is still reported as successful
- **AND** the output includes a warning indicating that `memory-update` failed
- **AND** the warning suggests the user run `/memory-update` manually

#### Scenario: Memory update skill file is missing

- **GIVEN** `~/.claude/skills/memory-manager/SKILL.md` does not exist or is unreadable
- **WHEN** Step 7 attempts to invoke `memory-update`
- **THEN** the archive is still reported as successful
- **AND** the output includes a warning that the memory-update skill could not be found

---

### Requirement: Step 6 text recommendation replaced with auto-update confirmation

The existing Step 6 in `sdd-archive/SKILL.md` that prints a manual recommendation to run `/memory-update` MUST be replaced. The manual recommendation is no longer needed because Step 7 performs the update automatically.

#### Scenario: No manual memory-update recommendation in output

- **GIVEN** `sdd-archive` is executing on any change
- **WHEN** the archive process completes all steps
- **THEN** the output does NOT contain a text recommendation saying "Run /memory-update"
- **AND** instead, the output contains either a confirmation (if Step 7 succeeded) or a warning (if Step 7 failed)

#### Scenario: Step numbering is consistent

- **GIVEN** the updated `sdd-archive/SKILL.md` is read
- **WHEN** a developer reviews the process steps
- **THEN** the steps are numbered sequentially from 1 through 7
- **AND** Step 7 is titled to clearly indicate it performs automatic memory update

---

### Requirement: sdd-ff final summary mentions auto memory update

The `sdd-ff` skill's final summary (presented after tasks are ready) MUST mention that `/sdd-archive` will automatically update `ai-context/` when the cycle completes.

#### Scenario: sdd-ff summary includes memory update note

- **GIVEN** a user has run `/sdd-ff` for a change and all phases (propose, spec, design, tasks) have completed
- **WHEN** `sdd-ff` presents its final summary asking "Ready to implement with /sdd-apply?"
- **THEN** the summary includes a note indicating that `/sdd-archive` will auto-update `ai-context/` at the end of the cycle
- **AND** the note is informational only (not a new step or action item for the user)

#### Scenario: sdd-ff note does not change the approval flow

- **GIVEN** `sdd-ff` presents its final summary with the memory update note
- **WHEN** the user reviews the summary
- **THEN** the approval question remains "Ready to implement with /sdd-apply?" (unchanged)
- **AND** no additional confirmation is required for the memory update behavior

---

### Requirement: sdd-new final summary mentions auto memory update

The `sdd-new` skill's flow description or final summary MUST mention that `/sdd-archive` will automatically update `ai-context/` when the cycle completes.

#### Scenario: sdd-new summary includes memory update note

- **GIVEN** a user is in an `sdd-new` cycle and the archive phase is approaching or being described
- **WHEN** `sdd-new` presents information about the archive phase
- **THEN** it mentions that archive will auto-update `ai-context/`
- **AND** the note is informational only

#### Scenario: sdd-new archive gate still requires user confirmation

- **GIVEN** `sdd-new` has reached the archive confirmation gate
- **WHEN** it asks the user whether to proceed with archiving
- **THEN** the confirmation prompt mentions that memory will be auto-updated as part of the archive
- **AND** the user still has the option to decline archiving (archive remains irreversible and requires explicit consent)

---

## Rules

- These specs describe observable outcomes only -- not how the skill files are structured internally
- All scenarios marked with MUST are non-negotiable for this change to be considered complete
- The `memory-update` skill's internal logic is explicitly out of scope -- only its invocation point and error handling are specified here
- The non-blocking behavior of Step 7 is a critical safety property: archive success must never depend on memory-update success
