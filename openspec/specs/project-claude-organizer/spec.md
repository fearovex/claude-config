# Spec: project-claude-organizer

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

*(Modified in: 2026-03-04 by change "project-claude-organizer-cleanup-after-migrate")*

Source files MUST NOT be deleted without BOTH conditions being true:
1. The file was successfully migrated (copied, appended, scaffolded, or user-choice applied)
2. The user explicitly confirmed the deletion prompt for that category

The "never delete" invariant remains fully in force for:
- The `delegate` strategy (`commands/`)
- The `section-distribute` strategy (`project.md`, `readme.md`)
- Any file with a failed or skipped migration outcome

#### Scenario: Source file exists after apply (when no cleanup confirmed)

- **GIVEN** any file was processed as a documentation candidate (copied or skipped)
- **AND** the user did not confirm cleanup deletion for that category
- **WHEN** Step 5 apply is complete
- **THEN** the original source file at `PROJECT_CLAUDE_DIR/<filename>.md` still exists and is
  unmodified

#### Scenario: Copy failure does not delete source

- **GIVEN** a copy operation fails (e.g., permission error)
- **WHEN** the error is handled
- **THEN** the source file remains at its original path
- **AND** the outcome is recorded as `failed — <error reason>` in the report
- **AND** the skill continues processing remaining candidates

#### Scenario: Source file preserved when migration failed

- **GIVEN** a `docs/` migration where `auth.md` failed during copy
- **WHEN** the cleanup prompt is presented (for successfully migrated files only)
- **THEN** `auth.md` is NOT included in the deletable list
- **AND** `.claude/docs/auth.md` is never deleted regardless of user input

#### Scenario: Source files preserved for delegate strategy regardless of any setting

- **GIVEN** `commands/` is processed via delegate strategy
- **WHEN** the delegate strategy completes
- **THEN** all files in `.claude/commands/` are unconditionally preserved — no prompt is issued, no deletion occurs

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

---

### Requirement: Post-migration cleanup prompt per applicable strategy

*(Added in: 2026-03-04 by change "project-claude-organizer-cleanup-after-migrate")*

After each legacy migration category is applied in Step 5.7, and only for strategies that
perform actual file writes (`copy`, `append`, `scaffold`, `user-choice`), the skill MUST
offer the user an opportunity to delete the successfully migrated source files.

The cleanup prompt MUST:
- Be presented AFTER the migration for the category has completed
- List the source files that were successfully migrated (those with `applied`, `copied`, `appended`, or `scaffolded` outcomes) and would be eligible for deletion
- List separately any source files that were skipped (due to destination-exists or other reasons) and would NOT be deleted
- Prompt: `Delete source files from .claude/<category>/? (yes/no)`
- Wait for explicit user input before performing any deletion

The cleanup prompt MUST NOT be presented:
- For the `delegate` strategy (`commands/`) — no actual file writes occurred
- For the `section-distribute` strategy (`project.md`, `readme.md`) — the source file may contain additional sections not distributed

#### Scenario: cleanup prompt presented after successful copy migration (docs/)

- **GIVEN** the user confirmed `docs/` migration and all files were successfully copied
- **WHEN** the migration for `docs/` completes
- **THEN** the skill presents a prompt listing all successfully copied files
- **AND** the prompt is: `Delete source files from .claude/docs/? (yes/no)`
- **AND** the skill waits for user confirmation before deleting anything

#### Scenario: cleanup prompt shows two lists for partial migration

- **GIVEN** the user confirmed `docs/` migration
- **AND** `auth.md` was copied successfully but `payments.md` was skipped (destination exists)
- **WHEN** the migration for `docs/` completes
- **THEN** the skill presents a prompt listing:
  - "Will be deleted: auth.md"
  - "Will be preserved (skipped — destination exists): payments.md"
- **AND** the prompt is: `Delete source files from .claude/docs/? (yes/no)`

#### Scenario: cleanup prompt NOT presented for delegate strategy

- **GIVEN** the user confirmed `commands/` migration (delegate strategy)
- **WHEN** the migration for `commands/` completes
- **THEN** NO deletion prompt is presented for `commands/`
- **AND** the source files in `.claude/commands/` are never offered for deletion

#### Scenario: cleanup prompt NOT presented for section-distribute strategy

- **GIVEN** the user confirmed `project.md` migration (section-distribute strategy)
- **WHEN** the section-distribute migration completes
- **THEN** NO deletion prompt is presented for `project.md`
- **AND** the source file `.claude/project.md` is never offered for deletion

#### Scenario: cleanup prompt NOT presented when no files were successfully migrated

- **GIVEN** the user confirmed `docs/` migration
- **AND** all files in `docs/` were skipped (destination-exists for each)
- **WHEN** the migration for `docs/` completes
- **THEN** the skill does NOT present a deletion prompt for `docs/`
- **AND** no source files are deleted

---

### Requirement: Deletion executes only on explicit user confirmation, targeting only successfully migrated files

*(Added in: 2026-03-04 by change "project-claude-organizer-cleanup-after-migrate")*

When the user responds affirmatively to the cleanup prompt, the skill MUST:
- Delete ONLY the source files that were successfully migrated (appear in the "will be deleted" list)
- NOT delete any file that was skipped, failed, or excluded
- NOT delete the parent source directory itself (only the individual files)
- Record each deletion outcome in the report

When the user declines the cleanup prompt, the skill MUST:
- Perform zero deletions for that category
- Record the skip in the report

#### Scenario: user confirms deletion — only successful files are deleted

- **GIVEN** the cleanup prompt for `docs/` lists `auth.md` (will be deleted) and `payments.md` (will be preserved)
- **WHEN** the user responds `yes`
- **THEN** `.claude/docs/auth.md` is deleted
- **AND** `.claude/docs/payments.md` is NOT deleted
- **AND** the `.claude/docs/` directory itself is NOT deleted

#### Scenario: user declines deletion — no files removed

- **GIVEN** the cleanup prompt for `templates/` is displayed
- **WHEN** the user responds `no`
- **THEN** zero files are deleted from `.claude/templates/`
- **AND** the report records `templates/ — cleanup declined by user`

#### Scenario: failed migrations are never offered for deletion

- **GIVEN** `docs/` migration ran and `auth.md` failed (e.g., copy error) and `events.md` was copied successfully
- **WHEN** the cleanup prompt is presented
- **THEN** only `events.md` appears in the "will be deleted" list
- **AND** `auth.md` does NOT appear in the "will be deleted" list
- **AND** `auth.md` is never deleted regardless of user input

---

### Requirement: Report MUST record all deletion outcomes in a new subsection

*(Added in: 2026-03-04 by change "project-claude-organizer-cleanup-after-migrate")*

When at least one deletion occurred (across any category), the report MUST include a
"Deleted from .claude/" subsection under "Legacy migrations". The subsection MUST list
every file that was deleted along with its full original source path.

When no deletions occurred (all declined or no eligible files), the subsection MAY be
omitted, or included as empty — either is acceptable.

#### Scenario: deletion subsection records deleted paths

- **GIVEN** the user confirmed deletion for `docs/` category (deleting `auth.md`)
- **AND** the user declined deletion for `templates/` category
- **WHEN** the report is written
- **THEN** the report includes a "Deleted from .claude/" subsection under Legacy migrations
- **AND** it lists: `.claude/docs/auth.md — deleted`
- **AND** it lists: `templates/ — cleanup declined by user`

#### Scenario: deletion subsection omitted when no deletions occurred

- **GIVEN** the user declined all cleanup prompts during the run
- **WHEN** the report is written
- **THEN** the "Deleted from .claude/" subsection MAY be omitted from the report

---

### Requirement: Active scaffold strategy for qualifying commands/ files

The skill MUST replace the advisory-only `delegate` strategy for `commands/` with an active
`scaffold` strategy. For each `.md` file in `.claude/commands/` that passes the existing
qualification signals, the skill MUST generate a minimal but valid `SKILL.md` under
`.claude/skills/<stem>/SKILL.md` without requiring any additional user commands.

**Qualification signals:**
- Signal 1 — step-numbered sections: the source file contains at least one heading matching
  `### Step N` or `## Step N` (where N is a digit)
- Signal 2 — patterns/examples headings: the source file contains a heading starting with
  `## Patterns` or `## Examples`
- Signal 3 — anti-pattern headings: the source file contains a heading starting with
  `## Anti-patterns` or `# Anti-patterns`
- Default: infer `procedural` when no signal matches

**Scaffold generation rules:**
1. Derive the skill name from the filename stem using kebab-case normalization.
2. Infer the format type from the qualification signals.
3. Generate a `SKILL.md` that includes valid frontmatter with `name`, `description`, and `format`; `**Triggers**`; `## Rules`; and the format-required main section.
4. Copy recognizable source content into the format-required main section.
5. Write the generated skeleton to `.claude/skills/<stem>/SKILL.md`.

**Idempotency invariant:** If `.claude/skills/<stem>/SKILL.md` already exists, the skill MUST skip generation and record `[already exists — not overwritten]`. The source file MUST NOT be modified or deleted.

**Non-qualifying files:** Files that do not pass any qualification signal MUST remain advisory-only in the report and are NOT scaffolded.

#### Scenario: Qualifying file is scaffolded as a procedural skill

- **GIVEN** `.claude/commands/deploy-review.md` exists and contains a `### Step 1` heading
- **WHEN** the scaffold strategy runs
- **THEN** `.claude/skills/deploy-review/SKILL.md` is created
- **AND** the generated skill contains `format: procedural`
- **AND** the generated skill contains `**Triggers**`, `## Process`, and `## Rules`

#### Scenario: Qualifying file is scaffolded as a reference skill

- **GIVEN** `.claude/commands/api-patterns.md` exists and contains `## Patterns`
- **WHEN** the scaffold strategy runs
- **THEN** `.claude/skills/api-patterns/SKILL.md` is created
- **AND** the generated skill contains `format: reference`
- **AND** the generated skill contains `**Triggers**`, `## Patterns`, and `## Rules`

#### Scenario: Qualifying file is scaffolded as an anti-pattern skill

- **GIVEN** `.claude/commands/react-antipatterns.md` exists and contains `## Anti-patterns`
- **WHEN** the scaffold strategy runs
- **THEN** `.claude/skills/react-antipatterns/SKILL.md` is created
- **AND** the generated skill contains `format: anti-pattern`
- **AND** the generated skill contains `**Triggers**`, `## Anti-patterns`, and `## Rules`

#### Scenario: Non-qualifying file remains advisory-only

- **GIVEN** `.claude/commands/notes.md` exists and contains no qualifying signal
- **WHEN** the scaffold strategy runs
- **THEN** `.claude/skills/notes/SKILL.md` is NOT created
- **AND** the report lists `notes.md` as advisory-only

#### Scenario: Existing generated target is not overwritten

- **GIVEN** `.claude/commands/deploy-review.md` qualifies for scaffolding
- **AND** `.claude/skills/deploy-review/SKILL.md` already exists
- **WHEN** the scaffold strategy runs
- **THEN** `.claude/skills/deploy-review/SKILL.md` is not modified
- **AND** the report records `[already exists — not overwritten]`

---

### Requirement: Skills audit for project-local skills

The skill MUST execute a skills-audit pass over immediate subdirectories of `.claude/skills/`
and collect findings into `SKILL_AUDIT_FINDINGS`.

**Detection rules:**
- Scope-tier overlap — HIGH severity when a project-local skill directory name also appears in the project's CLAUDE.md Skills Registry as `~/.claude/skills/<name>/SKILL.md`
- Broken shell — MEDIUM severity when a project-local skill directory exists without `SKILL.md`
- Suspicious name — LOW severity when a project-local skill directory begins with `_`, `test-`, or `draft-`

Each finding MUST record skill name, rule triggered, severity, and a short human-readable reason.
If `.claude/skills/` does not exist, the step is skipped and `SKILL_AUDIT_FINDINGS` remains empty.
Multiple rules MAY fire for the same directory, producing multiple findings.

#### Scenario: Scope-tier overlap detected

- **GIVEN** `.claude/skills/react-19/SKILL.md` exists
- **AND** the project CLAUDE.md references `~/.claude/skills/react-19/SKILL.md`
- **WHEN** the skills audit runs
- **THEN** a HIGH-severity finding is recorded for `react-19`

#### Scenario: Broken shell detected

- **GIVEN** `.claude/skills/my-tool/` exists without `SKILL.md`
- **WHEN** the skills audit runs
- **THEN** a MEDIUM-severity finding is recorded for `my-tool`

#### Scenario: Suspicious name detected

- **GIVEN** `.claude/skills/test-util/SKILL.md` exists
- **WHEN** the skills audit runs
- **THEN** a LOW-severity finding is recorded for `test-util`

#### Scenario: Multiple rules produce multiple findings

- **GIVEN** `.claude/skills/draft-react-19/` exists without `SKILL.md`
- **AND** the project CLAUDE.md references `~/.claude/skills/draft-react-19/SKILL.md`
- **WHEN** the skills audit runs
- **THEN** separate HIGH, MEDIUM, and LOW findings may be recorded for the same directory

---

### Requirement: Skills audit report section

When `.claude/skills/` exists in the project, `claude-organizer-report.md` MUST include a
`### Skills audit` section.

- If `SKILL_AUDIT_FINDINGS` is non-empty, the section MUST list each finding with skill name, severity, rule, and reason.
- If `SKILL_AUDIT_FINDINGS` is empty, the section MUST contain `No issues detected in .claude/skills/.`
- If `.claude/skills/` does not exist, the section MUST be omitted.

#### Scenario: Report includes skills audit findings

- **GIVEN** `SKILL_AUDIT_FINDINGS` contains findings for `react-19` and `test-util`
- **WHEN** the report is written
- **THEN** the report contains `### Skills audit`
- **AND** it lists both findings with severity and reason

#### Scenario: Report includes a no-issues message

- **GIVEN** `.claude/skills/` exists and `SKILL_AUDIT_FINDINGS` is empty
- **WHEN** the report is written
- **THEN** the report contains `No issues detected in .claude/skills/.`

---

### Requirement: Commands scaffold outcomes appear in the report

When `.claude/commands/` existed during the run, the report MUST include a
`### Commands scaffolded` section listing every processed source file with one of these outcomes:

- `<filename>.md -> .claude/skills/<stem>/SKILL.md — scaffolded (format: <format>)`
- `<filename>.md — [already exists — not overwritten]`
- `<filename>.md — advisory only (no qualifying signals)`

When `.claude/commands/` was absent, the section MUST be omitted.

#### Scenario: Report lists scaffold outcomes per file

- **GIVEN** `.claude/commands/` contained `deploy-review.md`, `notes.md`, and `ci-helper.md`
- **WHEN** the report is written
- **THEN** the report contains `### Commands scaffolded`
- **AND** it lists scaffolded, advisory-only, and already-exists outcomes as applicable

#### Scenario: Commands scaffolded section omitted when commands/ is absent

- **GIVEN** no `.claude/commands/` directory exists
- **WHEN** the report is written
- **THEN** `### Commands scaffolded` is absent

---

### Requirement: commands/ source preservation remains unconditional after scaffold

The source preservation invariant MUST continue to apply to the `commands/` category even
when the scaffold strategy generates output. No deletion prompt or source modification is ever
allowed for files under `.claude/commands/`.

#### Scenario: commands/ files remain after scaffold

- **GIVEN** qualifying files in `.claude/commands/` were scaffolded to `.claude/skills/`
- **WHEN** the scaffold operation completes
- **THEN** the source files under `.claude/commands/` still exist
- **AND** no deletion prompt is issued for `commands/`

---

### Requirement: Emoji-normalized heading matching in section-distribute strategy

The `section-distribute` strategy used for `project.md` MUST normalize heading text before
matching against route signal lists. Normalization strips leading and trailing emoji characters
and surrounding whitespace from the heading text used for comparison, but the original heading
text is preserved in prompts and source content.

If zero routeable headings are found after normalization, the organizer MUST emit a clear
advisory recommending manual migration.

#### Scenario: Emoji-prefixed heading matches a stack signal

- **GIVEN** a `project.md` heading `## 🎯 Tech Stack`
- **WHEN** section-distribute runs
- **THEN** the normalized heading matches the stack signal list
- **AND** the section is routed to `ai-context/stack.md`

#### Scenario: Original heading text remains visible to the user

- **GIVEN** a `project.md` heading `## 🏗️ Architecture`
- **WHEN** the organizer presents the routing confirmation prompt
- **THEN** the prompt shows the original heading text including the emoji

---

### Requirement: readme.md is an explicit legacy migration category

`readme.md` found at the immediate `.claude/` level MUST be recognized as a
`LEGACY_MIGRATION` candidate with strategy `user-choice` rather than being classified as
`UNEXPECTED`.

Two migration options MUST be presented:
- Option A: append the file's content to `CLAUDE.md` under the marker `<!-- .claude/readme.md -->`
- Option B: copy the file to `docs/README-claude.md`

If the user skips the category, the report MUST record `readme.md — skipped by user. Recommend manual review.`
If `CLAUDE.md` already contains the marker, the organizer MUST record `readme.md — already integrated (skipped)`.
The source file MUST NOT be deleted unless the standard cleanup flow is later offered and explicitly confirmed.

#### Scenario: readme.md classified as legacy migration

- **GIVEN** `.claude/readme.md` exists at the immediate `.claude/` level
- **WHEN** classification runs
- **THEN** `readme.md` is classified as `LEGACY_MIGRATION`
- **AND** it is not classified as `UNEXPECTED`

#### Scenario: Option A appends content to CLAUDE.md

- **GIVEN** `.claude/readme.md` exists
- **AND** the user selects Option A
- **WHEN** the migration is applied
- **THEN** the file content is appended to `CLAUDE.md` under the marker `<!-- .claude/readme.md -->`

#### Scenario: Option B copies file to docs/README-claude.md

- **GIVEN** `.claude/readme.md` exists
- **AND** the user selects Option B
- **WHEN** the migration is applied
- **THEN** `docs/README-claude.md` is created from the source content

---

### Requirement: project-claude-organizer exposes an explicit organizer kernel

The `project-claude-organizer` skill MUST describe its command flow as a stable organizer kernel with four stages: detect, classify, propose, and apply additive migrations.

The kernel is a product-level contract. Existing migration strategies may evolve, but they operate inside this four-stage flow rather than redefining the command.

#### Scenario: Skill documents the organizer kernel as a top-level contract

- **GIVEN** a developer reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they read the top-level structure before the detailed steps
- **THEN** they find an explicit section describing the organizer kernel
- **AND** that section names detect, classify, propose, and apply additive migrations as the core stages

#### Scenario: Organizer kernel does not replace existing migration details

- **GIVEN** `skills/project-claude-organizer/SKILL.md` has been updated by this change
- **WHEN** the migration strategy sections are read
- **THEN** the existing detailed handlers are still present
- **AND** the kernel acts as an umbrella contract rather than a replacement for detailed strategy logic

---

### Requirement: project-claude-organizer classifies behavior by scope boundary

The `project-claude-organizer` skill MUST distinguish between three behavior classes:

- **Core additive migrations** — safe create/copy/append operations that remain in organizer core behavior
- **Explicit opt-in operations** — scaffolding, user-choice branches, and cleanup deletions that require either category-level confirmation or post-migration confirmation
- **Advisory-only outcomes** — unexpected items, skills-audit findings, non-qualifying files, and ambiguous routing cases that do not trigger organizer mutations automatically

#### Scenario: Core additive migrations are described separately from advisory outcomes

- **GIVEN** a developer reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they inspect the top-level contract sections
- **THEN** they can identify which outcomes are core additive migrations
- **AND** they can identify which outcomes are advisory only

#### Scenario: Cleanup deletion is not treated as core organizer behavior

- **GIVEN** the organizer skill has been updated by this change
- **WHEN** a developer reads the scope-boundary contract
- **THEN** cleanup deletion is described as an explicit opt-in follow-up to successful migration
- **AND** it is not described as part of the organizer kernel itself

---

### Requirement: skills audit remains advisory and does not expand mutation scope

The skills-audit portion of `project-claude-organizer` MUST remain diagnostic only.

Even when it reports HIGH-severity findings such as scope overlap, it MUST NOT expand the organizer's automatic mutation scope to rewrite or delete project-local skills.

#### Scenario: Skills audit finding does not authorize mutation

- **GIVEN** the organizer detects a HIGH-severity `scope_overlap` finding in `.claude/skills/`
- **WHEN** the organizer applies the plan
- **THEN** the finding is reported in the output artifact
- **AND** no project-local skill file is rewritten or deleted solely because of that finding

---

### Requirement: ambiguous or unsupported structures remain manual-review outcomes

When `project-claude-organizer` encounters an item that does not map cleanly to a supported migration path, it MUST preserve the existing advisory-first posture.

Ambiguous routing cases, non-qualifying command files, unsupported legacy items, and unexpected structures MUST remain reportable manual-review outcomes rather than speculative organizer mutations.

#### Scenario: Unexpected structure remains advisory-only

- **GIVEN** an item under `.claude/` does not match the canonical set or any supported legacy pattern
- **WHEN** the organizer classifies the project
- **THEN** the item remains reported as unexpected/manual review
- **AND** the organizer does not invent a new migration path for it automatically

#### Scenario: Non-qualifying commands file remains advisory-only

- **GIVEN** `.claude/commands/misc-notes.md` contains no qualifying scaffold signals
- **WHEN** the organizer processes the `commands/` category
- **THEN** the file is reported as advisory-only
- **AND** the organizer does not scaffold or modify it

## Rules

- This change is contractual and scoping-oriented; it MUST NOT rename `/project-claude-organizer`
- This change MUST preserve the additive-first mutation model already established in organizer behavior
- Skills-audit findings remain advisory regardless of severity unless a future dedicated command is introduced for remediation
- Cleanup deletion remains a post-migration opt-in path, not part of the organizer kernel itself

## Rules

- `commands/` scaffolding is additive only; source files under `.claude/commands/` MUST never be modified or deleted
- Skills audit findings are advisory diagnostics; this change does not grant organizer permission to delete or rewrite project-local skills automatically
- `readme.md` is handled as an explicit user-choice migration, not as generic unexpected content
- Emoji normalization affects heading matching only; it MUST NOT alter source content or user-visible heading text in prompts
