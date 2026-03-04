# Spec: project-claude-organizer (memory-layer extension)

Change: project-claude-organizer-memory-layer
Date: 2026-03-04

---

## Requirements

### Requirement: Documentation candidate classification (Step 3 extension)

The skill MUST classify `.md` files observed at the root of `PROJECT_CLAUDE_DIR` into a
`DOCUMENTATION_CANDIDATES` bucket when at least one of the two detection signals fires:

**Signal 1 — Filename match:** The file's stem (filename without `.md` extension) matches any entry
in the known ai-context target list: `stack`, `architecture`, `conventions`, `known-issues`,
`changelog-ai`, `onboarding`, `quick-reference`, `scenarios`.

**Signal 2 — Content heading match:** The file contains at least one of the following heading
patterns (case-sensitive, line-starts-with): `## Tech Stack`, `## Architecture`,
`## Known Issues`, `## Conventions`, `## Changelog`, `## Domain Overview`.

Files promoted to `DOCUMENTATION_CANDIDATES` MUST be removed from the `UNEXPECTED` bucket.
Files in `DOCUMENTATION_CANDIDATES` MUST have a mapped destination path:
`PROJECT_ROOT/ai-context/<filename>.md`.

Files that match neither signal MUST remain in the `UNEXPECTED` bucket — no false promotion.

#### Scenario: Filename match promotes file to DOCUMENTATION_CANDIDATES

- **GIVEN** a project `.claude/` folder containing `stack.md` at its root
- **WHEN** Step 3 classification runs
- **THEN** `stack.md` is placed into `DOCUMENTATION_CANDIDATES` with destination `PROJECT_ROOT/ai-context/stack.md`
- **AND** `stack.md` does NOT appear in the `UNEXPECTED` bucket

#### Scenario: Content heading match promotes non-standard filename

- **GIVEN** a project `.claude/` folder containing `notes.md` at its root
- **AND** `notes.md` contains a line that starts with `## Tech Stack`
- **WHEN** Step 3 classification runs
- **THEN** `notes.md` is placed into `DOCUMENTATION_CANDIDATES` with destination `PROJECT_ROOT/ai-context/notes.md`
- **AND** `notes.md` does NOT appear in the `UNEXPECTED` bucket

#### Scenario: No signal — file stays UNEXPECTED

- **GIVEN** a project `.claude/` folder containing `commands.md` at its root
- **AND** `commands.md` does not have a stem matching any known ai-context target filename
- **AND** `commands.md` does not contain any of the known memory-layer heading patterns
- **WHEN** Step 3 classification runs
- **THEN** `commands.md` remains in the `UNEXPECTED` bucket
- **AND** `commands.md` does NOT appear in `DOCUMENTATION_CANDIDATES`

#### Scenario: Filename match is case-insensitive against the known list

- **GIVEN** a project `.claude/` folder containing `Architecture.md` at its root
- **WHEN** Step 3 classification runs
- **THEN** `Architecture.md` is classified as a documentation candidate (stem matches `architecture` case-insensitively)

#### Scenario: Only root-level files are scanned (no recursion)

- **GIVEN** a project `.claude/` folder with a subdirectory `extra/` that contains `stack.md`
- **WHEN** Step 3 classification runs
- **THEN** `extra/stack.md` is NOT classified as a documentation candidate
- **AND** `extra/` is evaluated only as the top-level entry `extra/` (directory)

---

### Requirement: Dry-run plan displays a fourth category (Step 4 extension)

When `DOCUMENTATION_CANDIDATES` is non-empty, the dry-run plan MUST display a fourth
category after the existing three, labeled `Documentation to migrate → ai-context/`.

For each candidate the display MUST show:
- The source path (relative to `PROJECT_CLAUDE_DIR`)
- The proposed destination path (relative to `PROJECT_ROOT`)
- A note that the source is preserved (copy, not move)

The category MUST clarify that individual files can be excluded by the user before confirmation.

#### Scenario: Fourth category displayed when candidates exist

- **GIVEN** `DOCUMENTATION_CANDIDATES` contains `stack.md` → `ai-context/stack.md`
- **WHEN** the dry-run plan is displayed in Step 4
- **THEN** a section titled `Documentation to migrate → ai-context/` appears in the output
- **AND** it lists `stack.md` with source `.claude/stack.md` and destination `ai-context/stack.md`
- **AND** the output notes that the original file is preserved (copy only)

#### Scenario: Fourth category omitted when no candidates

- **GIVEN** `DOCUMENTATION_CANDIDATES` is empty
- **WHEN** the dry-run plan is displayed
- **THEN** no `Documentation to migrate → ai-context/` section appears in the output

#### Scenario: Confirmation prompt is shown when any category has items

- **GIVEN** the plan has at least one item (in any category, including DOCUMENTATION_CANDIDATES)
- **WHEN** Step 4 finishes displaying the plan
- **THEN** the skill prompts `Apply this plan? (yes/no)` and waits for explicit user input

---

### Requirement: Copy operation for confirmed documentation candidates (Step 5 extension)

After user confirmation, the skill MUST process each file in `DOCUMENTATION_CANDIDATES` with
a copy-only operation. Moving and deleting the source MUST NOT occur.

**5.x.1 — Ensure ai-context/ directory exists:** If `PROJECT_ROOT/ai-context/` does not exist,
create it before attempting any copy.

**5.x.2 — Idempotency check:** If the destination file already exists, skip the copy and record
the file as `skipped (destination exists — review manually)`. The source file MUST NOT be modified.

**5.x.3 — Copy operation:** If the destination does not exist, copy the source file to the
destination. Record the outcome as `copied to ai-context/<filename>.md`.

**5.x.4 — Source preservation invariant:** After the copy step, the source file MUST still exist at
its original location in `PROJECT_CLAUDE_DIR`. Verification of source existence is REQUIRED before
recording a successful copy.

#### Scenario: Successful copy when destination does not exist

- **GIVEN** `DOCUMENTATION_CANDIDATES` contains `stack.md`
- **AND** `PROJECT_ROOT/ai-context/stack.md` does not exist
- **AND** `PROJECT_ROOT/ai-context/` exists (or is created in step 5.x.1)
- **WHEN** Step 5 apply runs after user confirmation
- **THEN** `stack.md` is copied to `PROJECT_ROOT/ai-context/stack.md`
- **AND** the original `PROJECT_CLAUDE_DIR/stack.md` still exists
- **AND** the outcome is recorded as `copied to ai-context/stack.md`

#### Scenario: Copy skipped when destination already exists

- **GIVEN** `DOCUMENTATION_CANDIDATES` contains `architecture.md`
- **AND** `PROJECT_ROOT/ai-context/architecture.md` already exists
- **WHEN** Step 5 apply runs
- **THEN** no write operation is performed on `ai-context/architecture.md`
- **AND** the original `PROJECT_CLAUDE_DIR/architecture.md` is not modified or deleted
- **AND** the outcome is recorded as `skipped (destination exists — review manually)`

#### Scenario: ai-context/ directory is created when absent

- **GIVEN** `PROJECT_ROOT/ai-context/` does not exist
- **AND** `DOCUMENTATION_CANDIDATES` is non-empty
- **WHEN** Step 5 apply runs
- **THEN** `PROJECT_ROOT/ai-context/` is created before any copy is attempted
- **AND** the copy proceeds normally

#### Scenario: Idempotency — second run skips already-copied files

- **GIVEN** the skill was previously run and copied `stack.md` to `ai-context/stack.md`
- **WHEN** the skill is run again with the same `.claude/stack.md` present
- **THEN** the copy is skipped and recorded as `skipped (destination exists — review manually)`
- **AND** neither the source nor the destination file is modified

#### Scenario: User-excluded files are not copied

- **GIVEN** `DOCUMENTATION_CANDIDATES` contains `stack.md` and `architecture.md`
- **AND** the user excludes `architecture.md` from the plan before confirming
- **WHEN** Step 5 apply runs
- **THEN** only `stack.md` is copied
- **AND** `architecture.md` remains in `.claude/` untouched
- **AND** `architecture.md` is recorded in the report as `excluded by user`

---

### Requirement: Report section for documentation migration (Step 6 extension)

The `claude-organizer-report.md` MUST include a `Documentation migrated to ai-context/` section
when `DOCUMENTATION_CANDIDATES` was non-empty.

The section MUST list, for each candidate:
- Files successfully copied: `<filename> — copied to ai-context/<filename>.md`
- Files skipped due to existing destination: `<filename> — skipped (destination exists — review manually)`
- Files excluded by the user before confirmation: `<filename> — excluded by user`

#### Scenario: Report includes migration section after successful copy

- **GIVEN** `stack.md` was copied to `ai-context/stack.md` during Step 5
- **WHEN** the report is written in Step 6
- **THEN** the report contains a section `## Documentation migrated to ai-context/`
- **AND** it lists `stack.md — copied to ai-context/stack.md`

#### Scenario: Report reflects skip outcome

- **GIVEN** `architecture.md` was skipped because `ai-context/architecture.md` already existed
- **WHEN** the report is written in Step 6
- **THEN** the section lists `architecture.md — skipped (destination exists — review manually)`

#### Scenario: Report section absent when no candidates existed

- **GIVEN** `DOCUMENTATION_CANDIDATES` was empty for the entire run
- **WHEN** the report is written in Step 6
- **THEN** the report does NOT contain a `Documentation migrated to ai-context/` section

---

### Requirement: Source file preservation invariant (cross-cutting)

The skill MUST NEVER delete, move, or overwrite the source `.md` file in `PROJECT_CLAUDE_DIR`
during any part of the documentation candidate processing.

#### Scenario: Source file exists after apply

- **GIVEN** any file was processed as a documentation candidate (copied or skipped)
- **WHEN** Step 5 apply is complete
- **THEN** the original source file at `PROJECT_CLAUDE_DIR/<filename>.md` still exists and is
  unmodified

#### Scenario: Copy failure does not delete source

- **GIVEN** a copy operation fails (e.g., permission error)
- **WHEN** the error is handled
- **THEN** the source file remains at its original path
- **AND** the outcome is recorded as `failed — <error reason>` in the report
- **AND** the skill continues processing remaining candidates

---

### Requirement: No-change path remains correct (regression guard)

When `DOCUMENTATION_CANDIDATES` is empty and `MISSING_REQUIRED` is empty and `UNEXPECTED` is
empty, the skill MUST output the existing no-op message and write the report without prompting
for confirmation — identical to V1 behavior.

#### Scenario: No-op run with no candidates, no missing, no unexpected

- **GIVEN** the `.claude/` folder contains only items in the canonical expected set
- **AND** none of those items are `.md` files matching a documentation candidate signal
- **WHEN** the skill runs
- **THEN** it outputs `No reorganization needed — .claude/ already matches the canonical SDD structure.`
- **AND** the report is written without showing a confirmation prompt
- **AND** no `Documentation to migrate → ai-context/` section appears in the report
