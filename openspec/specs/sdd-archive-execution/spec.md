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

---

### Requirement: sdd-archive maintains the spec index when a new domain spec is created

_(Added in: 2026-03-14 by change "specs-search-optimization")_

When the `sdd-archive` skill merges delta specs and the operation creates a new domain directory
under `openspec/specs/` (i.e., the domain did not previously exist in the master spec store),
`sdd-archive` MUST append a new entry to `openspec/specs/index.yaml`.

The appended entry MUST conform to the index schema:
- `domain`: the new directory name
- `summary`: a one-line description derived from the spec content (MUST NOT be left blank)
- `keywords`: 3–8 terms derived from the spec's domain vocabulary and requirement language
- `related`: zero or more related domain names (omit the field if no clear relations exist)

If `openspec/specs/index.yaml` does not exist (e.g., the change pre-dates this feature),
`sdd-archive` MUST create a minimal `index.yaml` with the standard file header, the `domains:`
root key, and the new domain as the first (and only) entry — then continue as if the file existed.

This index maintenance step MUST be non-blocking: a failure to append (parse error, write error)
MUST NOT prevent the archive from completing or set `status: failed`.

#### Scenario: Archive creates a new domain and appends an index entry

- **GIVEN** the delta spec being merged introduces a new domain `spec-index`
- **AND** `openspec/specs/index.yaml` already exists with N entries
- **WHEN** `sdd-archive` completes the spec merge (Step 3) for this change
- **THEN** `openspec/specs/index.yaml` MUST be updated with a new entry for `spec-index`
- **AND** the entry MUST contain `domain`, `summary`, and `keywords` fields
- **AND** the total entry count in the index MUST be N + 1

#### Scenario: Archive merges delta into existing domain — index is not modified

- **GIVEN** the delta spec updates an existing domain `sdd-archive-execution`
- **AND** `openspec/specs/index.yaml` exists
- **WHEN** `sdd-archive` merges the delta
- **THEN** the existing `sdd-archive-execution` entry in `index.yaml` MUST NOT be changed
- **AND** no new entry is appended
- **AND** the index entry count remains the same

#### Scenario: index.yaml is absent — sdd-archive creates a minimal index.yaml

- **GIVEN** the delta spec introduces a new domain
- **AND** `openspec/specs/index.yaml` does not exist
- **WHEN** `sdd-archive` completes the spec merge
- **THEN** `sdd-archive` MUST create `openspec/specs/index.yaml` with the standard file header and `domains:` root key
- **AND** the new domain MUST be written as the first (and only) entry in the file
- **AND** the archive completes with `status: ok`

#### Scenario: Index append failure does not block archive

- **GIVEN** `openspec/specs/index.yaml` exists but cannot be written (permissions error)
- **AND** the delta introduces a new domain
- **WHEN** `sdd-archive` attempts to append the new index entry
- **THEN** it MUST log a WARNING-level note that the index could not be updated
- **AND** the archive MUST still complete successfully
- **AND** `status` MUST be `ok` or `warning`, NEVER `failed` due to this step alone

#### Scenario: Appended entry keywords are derived from spec content

- **GIVEN** a new domain spec covers behavioral contracts for "spec-index" with requirements
  about YAML structure, keyword scoring, and fallback selection
- **WHEN** `sdd-archive` authors the index entry for this domain
- **THEN** the `keywords` list MUST include terms from the spec's subject area
  (e.g., `index`, `spec`, `yaml`, `keywords`, `search`, `selection`, `fallback`)
- **AND** MUST NOT include generic filler terms (`misc`, `other`, `general`, `stuff`)
- **AND** MUST contain between 3 and 8 keyword strings

---

### Requirement: Completeness validation runs before verify-report check

_(Added in: 2026-03-19 by change "sdd-archive-orphan-validation")_

Before `sdd-archive` reads `verify-report.md` or presents the irreversibility confirmation
prompt, it MUST run a completeness validation check on the change directory to detect missing
required SDD artifacts. This check uses a two-tier severity model: CRITICAL (blocks with no
proceed option) and WARNING (user may acknowledge and continue).

The check MUST run at the top of Step 1 ("Verify it is archivable"), before any existing
Step 1 logic.

#### Scenario: Happy path — all required artifacts present

- **GIVEN** an SDD change directory at `openspec/changes/<name>/` contains `proposal.md`,
  `tasks.md`, `design.md`, and a non-empty `specs/` directory
- **WHEN** `sdd-archive` executes Step 1
- **THEN** the completeness check produces no output and no prompts
- **AND** execution continues immediately to the existing `verify-report.md` check
- **AND** no additional user interaction is required for the completeness check itself

#### Scenario: CRITICAL block — proposal.md is absent

- **GIVEN** a change directory that does NOT contain `proposal.md`
- **WHEN** `sdd-archive` executes the completeness check in Step 1
- **THEN** the output displays a CRITICAL block listing `proposal.md` as missing
- **AND** the block MUST NOT include any option for the user to proceed or acknowledge
- **AND** `sdd-archive` halts immediately — the existing verify-report check and
  confirmation prompt MUST NOT be reached
- **AND** the output instructs the user to return and complete the missing phase before
  attempting to archive again

#### Scenario: CRITICAL block — tasks.md is absent

- **GIVEN** a change directory that does NOT contain `tasks.md`
- **WHEN** `sdd-archive` executes the completeness check in Step 1
- **THEN** the output displays a CRITICAL block listing `tasks.md` as missing
- **AND** no proceed option is presented
- **AND** `sdd-archive` halts — the existing Step 1 verify-report logic is NOT executed

#### Scenario: CRITICAL block — both proposal.md and tasks.md are absent

- **GIVEN** a change directory that contains neither `proposal.md` nor `tasks.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** both files are listed in a single CRITICAL block
- **AND** the archive halts with no proceed option

#### Scenario: WARNING — design.md is absent

- **GIVEN** a change directory that contains `proposal.md` and `tasks.md` but does NOT
  contain `design.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** the output displays a WARNING block listing `design.md` as missing
- **AND** the block presents exactly two options:
  - Option 1: Return and complete the missing phases
  - Option 2: Archive anyway with explicit acknowledgment that `design.md` was intentionally
    skipped
- **AND** the archive does NOT proceed until the user selects one of the two options

#### Scenario: WARNING — specs/ directory is absent or empty

- **GIVEN** a change directory that contains `proposal.md` and `tasks.md` but either has no
  `specs/` directory or has a `specs/` directory that contains no `.md` files
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** the output displays a WARNING block listing the missing specs as absent/empty
- **AND** exactly two options (return to complete / acknowledge and proceed) are presented

#### Scenario: WARNING — both design.md and specs/ are absent

- **GIVEN** a change directory with `proposal.md` and `tasks.md`, but without `design.md`
  and with an absent or empty `specs/` directory
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** a single WARNING block lists both `design.md` and `specs/` as missing
- **AND** the same two-option prompt is presented once (not twice)

#### Scenario: CRITICAL takes precedence over WARNING in the same check

- **GIVEN** a change directory where `proposal.md` is absent AND `design.md` is absent
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** only the CRITICAL block is presented (listing `proposal.md` as missing)
- **AND** the WARNING for `design.md` is NOT displayed alongside the CRITICAL block
- **AND** the archive halts without any proceed option

---

### Requirement: CLOSURE.md records skipped phases when option 2 is selected

_(Added in: 2026-03-19 by change "sdd-archive-orphan-validation")_

When a user selects option 2 (archive with explicit acknowledgment) during a WARNING-level
completeness check, the `CLOSURE.md` file created in Step 5 MUST include a `Skipped phases:`
field that lists each phase whose artifact was absent and acknowledged.

#### Scenario: CLOSURE.md includes Skipped phases field after WARNING acknowledgment

- **GIVEN** the user has selected option 2 (acknowledge and archive) for a WARNING that
  listed `design.md` as absent
- **WHEN** `sdd-archive` creates the `CLOSURE.md` in Step 5
- **THEN** `CLOSURE.md` contains a `Skipped phases:` field
- **AND** the field lists `design` as a skipped phase
- **AND** the field appears as a distinct line or section in the closure note (not buried in
  the summary paragraph)

#### Scenario: CLOSURE.md includes Skipped phases field for multiple WARNING artifacts

- **GIVEN** the user has acknowledged a WARNING listing both `design.md` and `specs/` as absent
- **WHEN** `sdd-archive` creates `CLOSURE.md`
- **THEN** the `Skipped phases:` field lists both `design` and `spec` as skipped phases
- **AND** the field is present regardless of whether any other closure sections are populated

#### Scenario: CLOSURE.md does NOT contain Skipped phases field when all artifacts are present

- **GIVEN** a happy-path archive where all required artifacts were present (no WARNING was
  triggered)
- **WHEN** `sdd-archive` creates `CLOSURE.md`
- **THEN** `CLOSURE.md` does NOT contain a `Skipped phases:` field
- **AND** the closure note structure is unchanged from the standard template

---

### Requirement: exploration.md and prd.md are never checked

_(Added in: 2026-03-19 by change "sdd-archive-orphan-validation")_

The completeness validation MUST NOT check for `exploration.md` or `prd.md`. These files are
optional by project convention and their absence MUST NOT trigger any CRITICAL or WARNING
output.

#### Scenario: Archive proceeds normally when exploration.md is absent

- **GIVEN** a change directory that has all CRITICAL and WARNING artifacts but no `exploration.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** no warning or block is produced for the absent `exploration.md`
- **AND** execution continues as if the file were present

#### Scenario: Archive proceeds normally when prd.md is absent

- **GIVEN** a change directory that has all CRITICAL and WARNING artifacts but no `prd.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** no warning or block is produced for the absent `prd.md`
- **AND** execution continues as if the file were present

---

## Rules

- These specs describe observable outcomes only -- not how the skill files are structured internally
- All scenarios marked with MUST are non-negotiable for this change to be considered complete
- The `memory-update` skill's internal logic is explicitly out of scope -- only its invocation point and error handling are specified here
- The non-blocking behavior of Step 7 is a critical safety property: archive success must never depend on memory-update success
- The completeness check is purely terminal — it runs only in `sdd-archive`, never in any other SDD phase skill
- CRITICAL artifacts (`proposal.md`, `tasks.md`) MUST block with no user escape path
- WARNING artifacts (`design.md`, non-empty `specs/`) MUST always offer option 2 (acknowledge and proceed) — they MUST NOT silently block
- The `Skipped phases:` field in `CLOSURE.md` is informational only; it does not alter archive success status
- Completeness validation MUST run before `verify-report.md` is read and before the irreversibility confirmation prompt
- `exploration.md` and `prd.md` are explicitly excluded from the check and MUST NOT appear in any block output

---

## Orphan Precondition

_(Added in: 2026-03-19 by change "2026-03-19-cleanup-orphan-changes")_

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

### Orphan Precondition — Rules

- The orphan definition (4 inclusion criteria + exclusion list) is authoritative; changes to the threshold values (e.g., 7-day age) require a new delta spec
- The three disposition options (revive, archive, delete) are exhaustive — no other dispositions are valid
- `CLOSURE.md` is required for archive dispositions but not for delete dispositions
- The orphan check is Step 0 of `sdd-archive` — it runs before all existing steps (existing steps retain their numbering)
- Orphan detection MUST NOT affect the archive of the current change; it is a cleanup gate, not a blocking condition

---

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
