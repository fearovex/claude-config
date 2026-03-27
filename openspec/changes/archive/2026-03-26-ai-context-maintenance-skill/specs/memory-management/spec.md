# Delta Spec: memory-management

Change: 2026-03-26-ai-context-maintenance-skill
Date: 2026-03-26
Base: openspec/specs/memory-management/spec.md

---

## ADDED — New requirements

### Requirement: memory-maintain skill existence and structure

A `memory-maintain` skill MUST exist at `skills/memory-maintain/SKILL.md` with procedural format.

The skill MUST:
- Declare `format: procedural` in its YAML frontmatter
- Include `name`, `description`, and `format` fields in its YAML frontmatter
- Include a `**Triggers**` line
- Include a `## Process` section
- Include a `## Rules` section

#### Scenario: SKILL.md is structurally valid

- **GIVEN** the `skills/memory-maintain/` directory exists
- **WHEN** `skills/memory-maintain/SKILL.md` is read
- **THEN** the file MUST contain valid YAML frontmatter with `format: procedural`
- **AND** the file MUST contain `**Triggers**`, `## Process`, and `## Rules` sections

---

### Requirement: memory-maintain dry-run-first interaction pattern

`memory-maintain` MUST present a dry-run preview of all planned changes before writing any files.

The dry-run step:
- MUST compute all planned changes (entries to archive, issues to move, index to generate, advisory notes)
- MUST display a summary table or list of planned actions
- MUST ask for explicit user confirmation before writing any file
- MUST NOT write any files before receiving confirmation
- If the user declines, the skill MUST exit without modifying any file

#### Scenario: User views dry-run preview and confirms

- **GIVEN** `ai-context/changelog-ai.md` has more than 30 entries
- **AND** `ai-context/known-issues.md` has items marked FIXED or RESOLVED
- **WHEN** the user runs `/memory-maintain`
- **THEN** the skill presents a list of planned actions (e.g., "Archive 45 changelog entries", "Move 3 resolved issues")
- **AND** the skill asks for confirmation before writing
- **AND** only after confirmation are any files written

#### Scenario: User declines dry-run — no files are written

- **GIVEN** the dry-run preview has been presented
- **WHEN** the user responds with a negative or "no"
- **THEN** the skill exits without writing any file
- **AND** a message confirms that no changes were made

---

### Requirement: changelog archiving

`memory-maintain` MUST archive `changelog-ai.md` entries beyond the last 30 to `ai-context/changelog-ai-archive.md`.

The changelog archiving step:
- MUST count entries in `changelog-ai.md`. An "entry" is a contiguous block that begins with a line starting with `### ` or `## ` (heading markers) — everything until the next heading of the same or higher level constitutes one entry
- MUST keep the last 30 entries in `changelog-ai.md`
- MUST move all older entries (beyond the 30th) to `changelog-ai-archive.md`
- MUST append to an existing `changelog-ai-archive.md` if it exists, or create it if absent
- MUST NOT corrupt or remove the `[auto-updated]` section boundary markers in `changelog-ai.md`
- If `changelog-ai.md` has 30 or fewer entries, this step MUST be skipped (no write)
- If `changelog-ai.md` does not exist, this step MUST be skipped silently

#### Scenario: Changelog has more than 30 entries — older entries are archived

- **GIVEN** `ai-context/changelog-ai.md` contains 45 entries (each a heading block)
- **WHEN** the user confirms the dry-run
- **THEN** the last 30 entries remain in `changelog-ai.md`
- **AND** the 15 older entries are moved to `changelog-ai-archive.md`
- **AND** `[auto-updated]` markers in `changelog-ai.md` remain intact and unmodified

#### Scenario: Changelog archive file exists — entries are appended

- **GIVEN** `ai-context/changelog-ai-archive.md` already contains 20 archived entries
- **AND** `ai-context/changelog-ai.md` has 35 entries
- **WHEN** the user confirms the dry-run
- **THEN** the 5 overflow entries are APPENDED to the existing `changelog-ai-archive.md`
- **AND** the archive file contains 25 total entries

#### Scenario: Changelog has 30 or fewer entries — step is skipped

- **GIVEN** `ai-context/changelog-ai.md` has exactly 30 entries
- **WHEN** the skill computes the dry-run
- **THEN** the changelog archiving step is NOT listed as a planned action
- **AND** no archive file is written

---

### Requirement: known-issues separation

`memory-maintain` MUST move resolved items from `known-issues.md` to `ai-context/known-issues-archive.md`.

The known-issues separation step:
- MUST scan `known-issues.md` for items containing FIXED or RESOLVED markers (case-insensitive: `FIXED`, `fixed`, `RESOLVED`, `resolved`)
- MUST move each matching item to `known-issues-archive.md` under a `## Resolved Issues` section
- MUST record the date of archival inline with the moved item
- MUST NOT modify items that do not contain FIXED or RESOLVED markers
- MUST NOT corrupt or remove the `[auto-updated]` section boundary markers in `known-issues.md`
- If `known-issues.md` does not exist, this step MUST be skipped silently
- If no items contain FIXED or RESOLVED markers, this step MUST be skipped (no write)
- MUST append to an existing `known-issues-archive.md` if it exists, or create it if absent

#### Scenario: Known issues with resolved markers are moved to archive

- **GIVEN** `ai-context/known-issues.md` contains 5 items, 2 of which are marked FIXED
- **WHEN** the user confirms the dry-run
- **THEN** the 2 FIXED items are removed from `known-issues.md`
- **AND** the 2 items are appended to `known-issues-archive.md` under `## Resolved Issues`
- **AND** each archived item includes the archival date
- **AND** the 3 remaining unresolved items in `known-issues.md` are unchanged

#### Scenario: No resolved items — step is skipped

- **GIVEN** `ai-context/known-issues.md` contains 4 items, none marked FIXED or RESOLVED
- **WHEN** the skill computes the dry-run
- **THEN** the known-issues separation step is NOT listed as a planned action
- **AND** `known-issues-archive.md` is not created or modified

---

### Requirement: ai-context index generation

`memory-maintain` MUST generate or regenerate `ai-context/index.md` as an entry-point table of contents for the memory layer.

The index generation step:
- MUST walk the `ai-context/` directory and list every `.md` file (excluding `index.md` itself and any file whose name begins with an underscore)
- For each file, MUST include: filename, first H1 heading, and `Last updated:` date extracted from file content
- If a file has no `Last updated:` field, MUST show "Unknown" in the date column
- MUST generate `ai-context/index.md` on every run (idempotent — always reflects current state)
- The index MUST be presented as a Markdown table with columns: File, Purpose, Last Updated

#### Scenario: Index is generated on first run

- **GIVEN** `ai-context/index.md` does not exist
- **AND** `ai-context/` contains `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`
- **WHEN** the user confirms the dry-run
- **THEN** `ai-context/index.md` is created
- **AND** it contains a Markdown table listing all 5 files with their first headings and last-updated dates

#### Scenario: Index is regenerated on subsequent runs (idempotent)

- **GIVEN** `ai-context/index.md` already exists
- **AND** a new file `ai-context/known-issues-archive.md` was created since the last run
- **WHEN** the user confirms the dry-run
- **THEN** `ai-context/index.md` is regenerated to include the new archive file
- **AND** the regenerated index accurately reflects the current state of `ai-context/`

---

### Requirement: CLAUDE.md Active Constraints gap detection

`memory-maintain` MUST check the project-root `CLAUDE.md` for an "Active Constraints" section and emit an INFO advisory if absent.

The gap detection step:
- MUST read the project-root `CLAUDE.md` (same directory as where the skill is invoked, or the nearest parent CLAUDE.md)
- MUST check for the presence of an `## Active Constraints` section (case-sensitive match)
- If absent, MUST emit an INFO advisory note in the maintenance report: "No Active Constraints section found in CLAUDE.md — consider adding one to document active behavioral overrides"
- MUST NOT write to CLAUDE.md under any circumstances
- If CLAUDE.md is not found, this step MUST be skipped silently
- This step applies to the project-local CLAUDE.md only — the global `~/.claude/CLAUDE.md` is out of scope

#### Scenario: Active Constraints section is absent — advisory is emitted

- **GIVEN** the project-root `CLAUDE.md` does not contain an `## Active Constraints` section
- **WHEN** the maintenance report is generated
- **THEN** the report includes an INFO note: "No Active Constraints section found in CLAUDE.md"
- **AND** CLAUDE.md is not modified

#### Scenario: Active Constraints section is present — no advisory

- **GIVEN** the project-root `CLAUDE.md` contains an `## Active Constraints` section
- **WHEN** the maintenance report is generated
- **THEN** no advisory is emitted for this check
- **AND** CLAUDE.md is not modified

---

### Requirement: maintenance report

`memory-maintain` MUST produce a maintenance report summarizing all actions taken.

The maintenance report:
- MUST list each step executed and its outcome (e.g., "Changelog: archived 15 entries", "Known issues: moved 2 resolved items", "Index: regenerated", "CLAUDE.md: no Active Constraints section detected")
- MUST include a count of files written
- MUST be displayed to the user after all writes complete
- MUST distinguish between steps that were executed vs. steps that were skipped (with reason for skipping)

#### Scenario: All steps execute successfully

- **GIVEN** changelog has overflow, known-issues has resolved items, and CLAUDE.md has no Active Constraints
- **WHEN** `memory-maintain` completes all writes
- **THEN** the maintenance report lists each completed action with counts
- **AND** the report lists the INFO advisory about Active Constraints
- **AND** the total count of files written is displayed

#### Scenario: All steps are skipped

- **GIVEN** `changelog-ai.md` has 20 entries, no resolved issues, `ai-context/index.md` is up to date, and CLAUDE.md has an Active Constraints section
- **WHEN** the dry-run is computed
- **THEN** the dry-run preview indicates all steps will be skipped
- **AND** after confirmation (or if user cancels), no files are written

---

### Requirement: CLAUDE.md registration

The `memory-maintain` skill MUST be registered in the project `CLAUDE.md` (agent-config repository).

Registration MUST include:
- An entry under `### Meta-tools` in the Skills Registry section: `- ~/.claude/skills/memory-maintain/SKILL.md`
- A command entry in the Commands section: `/memory-maintain — perform ai-context/ housekeeping (archive old changelog entries, separate resolved known-issues, regenerate index)`

#### Scenario: CLAUDE.md Skills Registry includes memory-maintain

- **GIVEN** the `memory-maintain` skill has been created
- **WHEN** the agent-config CLAUDE.md is read
- **THEN** `~/.claude/skills/memory-maintain/SKILL.md` MUST appear under `### Meta-tools`

#### Scenario: CLAUDE.md Commands section includes /memory-maintain

- **GIVEN** the `memory-maintain` skill has been created
- **WHEN** the agent-config CLAUDE.md Commands section is read
- **THEN** `/memory-maintain` MUST appear with a brief description

---

### Requirement: auto-updated marker preservation

`memory-maintain` MUST preserve `[auto-updated]` and `[/auto-updated]` section boundary markers in all files it modifies.

- MUST NOT remove, reorder, or modify content between `[auto-updated]` markers
- MUST NOT write content between `[auto-updated]` markers unless the content was already inside that block in the source file
- If a file modification would corrupt an `[auto-updated]` block, the step for that file MUST be aborted and the dry-run MUST flag the issue

#### Scenario: Changelog archiving preserves auto-updated markers

- **GIVEN** `changelog-ai.md` contains an `[auto-updated]` ... `[/auto-updated]` block after the first 5 entries
- **WHEN** entries beyond the 30th are archived
- **THEN** the `[auto-updated]` block remains in `changelog-ai.md` intact and in its original position
- **AND** no content from inside the `[auto-updated]` block is moved to the archive
