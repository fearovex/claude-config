# Delta Spec: sdd-archive-execution

Change: 2026-03-19-cleanup-orphan-changes
Date: 2026-03-19
Base: openspec/specs/sdd-archive-execution/spec.md

## ADDED — New requirements

### Requirement: Orphan Precondition — definition and detection

An **orphan** is an SDD change directory under `openspec/changes/` that meets ALL of the following criteria:

1. **Age threshold**: the directory has existed for more than 7 days (measured by the earliest commit that introduced any file inside it, or by filesystem ctime when git history is unavailable).
2. **Missing date prefix**: the directory name does not follow the `YYYY-MM-DD-<slug>` convention required by the conventions doc.
3. **Stalled state**: the directory contains no `tasks.md`, no `verify-report.md`, and has not been modified (any file inside) within the last 7 days — OR it contains only an `exploration.md` with no `proposal.md` (indicating the exploration concluded without a follow-on cycle).
4. **No cross-reference**: no active `tasks.md` in any other change directory references this directory by path.

A directory that meets **any** of the following criteria is NOT an orphan regardless of age:
- It contains a `tasks.md` with at least one `[TODO]` or `[IN PROGRESS]` task.
- It is referenced by an in-progress change.
- It has been explicitly marked as "on hold" in its `proposal.md` with a target review date that has not yet passed.

#### Scenario: Directory is correctly classified as an orphan

- **GIVEN** a change directory `openspec/changes/spec-hygiene/` exists with no date prefix
- **AND** it contains only `exploration.md` (no `proposal.md`, no `tasks.md`)
- **AND** its content has not been modified in the last 7 days
- **WHEN** the orphan detection criteria are evaluated
- **THEN** the directory MUST be classified as an orphan
- **AND** it MUST require explicit disposition before the parent session is archived

#### Scenario: Directory is correctly excluded from orphan classification

- **GIVEN** a change directory `openspec/changes/2026-03-18-context-handoff-between-sessions/` exists with a valid date prefix
- **AND** it contains a `tasks.md` with at least one `[TODO]` task
- **WHEN** the orphan detection criteria are evaluated
- **THEN** the directory MUST NOT be classified as an orphan
- **AND** it MUST NOT be affected by any orphan disposition operation

---

### Requirement: Orphan Precondition — required disposition options

Before any SDD change may be archived, any orphan directories discovered during the pre-archive review MUST receive an explicit disposition. Valid dispositions are:

| Disposition | Action |
|-------------|--------|
| **revive** | Operator confirms the orphan is still needed; adds a `proposal.md` with a target date; the directory is no longer an orphan after this action |
| **archive** | Directory is moved to `openspec/changes/archive/YYYY-MM-DD-<slug>/` and a `CLOSURE.md` is written explaining the reason for archiving without completing the SDD cycle |
| **delete** | Directory is deleted entirely; MUST only be used when all content is preserved in git history and the proposal explicitly references the preserving commit |

No other disposition options are permitted. The operator MUST choose one disposition per orphan. The disposition decision MUST be recorded in `CLOSURE.md` (for archive) or in the current session's `ai-context/changelog-ai.md` entry (for delete).

#### Scenario: Archive disposition is executed for an exploration-only orphan

- **GIVEN** `openspec/changes/spec-hygiene/` is classified as an orphan
- **AND** the operator chooses the "archive" disposition
- **WHEN** the disposition is executed
- **THEN** the directory MUST be moved to `openspec/changes/archive/2026-03-14-spec-hygiene/`
- **AND** a `CLOSURE.md` file MUST be written inside the archived directory containing:
  - the original directory name
  - the disposition chosen ("archive")
  - the reason (e.g., "informational exploration with recommendation: no action required")
  - the date of archiving
- **AND** the source directory `openspec/changes/spec-hygiene/` MUST no longer exist

#### Scenario: Delete disposition requires git preservation evidence

- **GIVEN** `openspec/changes/2026-03-14-specs-sqlite-store/` is classified as an orphan
- **AND** the operator chooses the "delete" disposition
- **WHEN** the disposition is recorded
- **THEN** the deletion record MUST include the git commit hash where the content is preserved
- **AND** the directory MUST be removed from the filesystem
- **AND** no `CLOSURE.md` is required (deletion is its own record in git history)
- **AND** the session's changelog entry MUST note: "deleted [directory], content preserved in git at [commit-hash]"

#### Scenario: Revive disposition re-activates an orphan

- **GIVEN** a change directory is classified as an orphan
- **AND** the operator chooses the "revive" disposition
- **WHEN** the revive action is completed
- **THEN** the operator MUST add a `proposal.md` to the directory (or update the existing one)
- **AND** the `proposal.md` MUST include a target review date
- **AND** the directory MUST be renamed to include the `YYYY-MM-DD-` date prefix if it was missing
- **AND** no `CLOSURE.md` is created for revived directories

---

### Requirement: Orphan Precondition — non-blocking check at archive phase entry

The orphan detection check is a precondition of the `sdd-archive` phase, run as **Step 0** before any other archive action. Its outcome MUST NOT block the archive of the current change.

- If orphans are found: the operator is presented with the list and MUST choose a disposition for each before proceeding.
- If no orphans are found: Step 0 emits an INFO-level note and execution continues immediately.
- The check MUST NOT fail with `status: blocked` due to orphan presence alone — it is a gate that pauses for operator input, not a hard blocker.

#### Scenario: No orphans found — archive proceeds immediately

- **GIVEN** all directories under `openspec/changes/` (excluding `archive/`) either have in-progress tasks or have been modified within 7 days
- **WHEN** `sdd-archive` executes Step 0
- **THEN** Step 0 emits: `INFO: No orphan changes detected — proceeding with archive.`
- **AND** execution continues to Step 1 without any operator prompt

#### Scenario: Orphans found — operator must dispose before archive continues

- **GIVEN** `openspec/changes/` contains one or more orphan directories
- **WHEN** `sdd-archive` executes Step 0
- **THEN** Step 0 lists each orphan with its age and stall reason
- **AND** presents the three disposition options (revive, archive, delete) for each orphan
- **AND** pauses for operator input
- **AND** only proceeds to Step 1 after all orphans have received a disposition

---

## Rules

- The orphan definition (4 inclusion criteria + exclusion list) is authoritative; changes to the threshold values (e.g., 7-day age) require a new delta spec
- The three disposition options (revive, archive, delete) are exhaustive — no other dispositions are valid
- `CLOSURE.md` is required for archive dispositions but not for delete dispositions
- The orphan check is Step 0 of `sdd-archive` — it runs before all existing steps (existing steps retain their numbering)
- Orphan detection MUST NOT affect the archive of the current change; it is a cleanup gate, not a blocking condition
