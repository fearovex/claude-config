# Spec: folder-organizer-execution

Change: project-claude-folder-organizer
Date: 2026-03-04

## Overview

This spec describes the observable behavior of the `project-claude-organizer` skill when it
executes against a project's `.claude/` folder. It covers: project root resolution, canonical
structure comparison, dry-run plan presentation, user confirmation gate, additive-only apply
behavior, and the relationship to the companion `claude-folder-audit` skill.

---

## Requirements

### Requirement: skill MUST resolve the project root before executing any check

When `/project-claude-organizer` is invoked, the skill MUST determine the project root as the
current working directory (CWD). The `.claude/` folder under that root is the audit target.
The skill MUST NOT operate on `~/.claude/` (the user-level runtime) under any circumstances.

#### Scenario: project root resolved to CWD — .claude/ is the target

- **GIVEN** the user invokes `/project-claude-organizer` from a project directory that contains a `.claude/` folder
- **WHEN** the skill resolves its target
- **THEN** it sets `PROJECT_ROOT = CWD` and `PROJECT_CLAUDE_DIR = CWD/.claude`
- **AND** all subsequent checks and writes operate relative to `PROJECT_CLAUDE_DIR`

#### Scenario: invoked from a directory with no .claude/ folder

- **GIVEN** the user invokes `/project-claude-organizer` from a directory that does NOT contain a `.claude/` folder
- **WHEN** the skill attempts to resolve its target
- **THEN** it outputs a clear error: "No .claude/ folder found at <CWD>. This skill requires a project with an existing .claude/ directory."
- **AND** it exits without writing any files or performing any checks

#### Scenario: skill MUST NOT target ~/.claude/

- **GIVEN** the user invokes `/project-claude-organizer` from the `agent-config` source repo (which has `install.sh` and `skills/` at root but no `.claude/`)
- **WHEN** the skill resolves its target
- **THEN** it outputs: "No .claude/ folder found at <CWD>. This skill targets project .claude/ folders only — not the ~/.claude/ runtime."
- **AND** it exits without writing any files

---

### Requirement: skill MUST enumerate the observed .claude/ contents against the canonical expected set

The skill MUST enumerate all items (files and directories) one level deep under `PROJECT_CLAUDE_DIR`
and compare them against the canonical expected item set. The canonical expected set MUST be
consistent with the set used by `claude-folder-audit` Check P8.

**Canonical expected item set:**
```
CLAUDE.md
skills/
audit-report.md
claude-folder-audit-report.md
claude-organizer-report.md
settings.json
settings.local.json
openspec/
ai-context/
hooks/
```

#### Scenario: all expected items present — inventory clean

- **GIVEN** `PROJECT_CLAUDE_DIR` contains exactly the items in the canonical expected set (or a subset of them)
- **WHEN** the skill completes its enumeration step
- **THEN** no items are classified as "unexpected"
- **AND** any absent expected items are classified as "missing"

#### Scenario: unexpected item found in .claude/

- **GIVEN** `PROJECT_CLAUDE_DIR` contains an item `custom-notes.md` that is not in the canonical expected set
- **WHEN** the skill completes its enumeration step
- **THEN** `custom-notes.md` is classified as an "unexpected item" in the plan
- **AND** it is NOT classified as "missing"

#### Scenario: missing required item detected

- **GIVEN** `PROJECT_CLAUDE_DIR` does not contain a `skills/` directory
- **WHEN** the skill completes its enumeration step
- **THEN** `skills/` is classified as "missing" in the plan

---

### Requirement: skill MUST produce a human-readable reorganization plan before applying any changes

After enumeration and comparison, the skill MUST produce a reorganization plan and present it
to the user. The plan MUST clearly list three categories: items to create (missing), items
flagged as unexpected, and items already correct. The skill MUST NOT apply any changes before
the user has seen the plan.

#### Scenario: plan lists missing items to create

- **GIVEN** the enumeration step found that `CLAUDE.md` and `skills/` are missing from `.claude/`
- **WHEN** the plan is presented to the user
- **THEN** the plan contains a "To be created" section listing `CLAUDE.md` (stub file) and `skills/` (empty directory)
- **AND** the plan clearly states these items do not yet exist

#### Scenario: plan lists unexpected items to flag

- **GIVEN** the enumeration step found `commands/` directory under `.claude/` (a legacy artifact)
- **WHEN** the plan is presented to the user
- **THEN** the plan contains an "Unexpected items (will be flagged, not deleted)" section listing `commands/`
- **AND** the plan explicitly states: "These items will NOT be deleted or moved — they will receive a warning comment in the report"

#### Scenario: plan lists already-correct items

- **GIVEN** the enumeration step found `CLAUDE.md` and `hooks/` both present and expected
- **WHEN** the plan is presented to the user
- **THEN** the plan contains an "Already correct" section listing `CLAUDE.md` and `hooks/`

#### Scenario: plan is presented before any file writes

- **GIVEN** the skill has completed enumeration and built the plan
- **WHEN** the plan is displayed
- **THEN** no files have been created or modified yet
- **AND** the plan is followed immediately by a confirmation prompt

---

### Requirement: skill MUST wait for explicit user confirmation before applying any changes

After presenting the reorganization plan, the skill MUST pause and request explicit user
confirmation before executing any writes. The confirmation gate MUST be a clear yes/no prompt.
If the user does not confirm, the skill MUST exit without making any changes.

#### Scenario: user confirms — skill proceeds to apply

- **GIVEN** the plan has been presented to the user
- **WHEN** the user responds with an affirmative confirmation (e.g., "yes", "proceed", "apply")
- **THEN** the skill proceeds to the apply step
- **AND** it applies exactly the changes listed in the plan — no more, no less

#### Scenario: user declines — skill exits without changes

- **GIVEN** the plan has been presented to the user
- **WHEN** the user responds with a negative answer (e.g., "no", "cancel", "abort") or provides no answer
- **THEN** the skill exits without writing any files
- **AND** it outputs: "Reorganization cancelled. No changes were made."

#### Scenario: empty plan — no changes needed

- **GIVEN** all items in `.claude/` match the canonical expected set with no missing items
- **WHEN** the enumeration step completes
- **THEN** the skill outputs: "No reorganization needed — .claude/ already matches the canonical SDD structure."
- **AND** the skill exits without a confirmation prompt (nothing to confirm)
- **AND** it still writes a report noting the clean state

---

### Requirement: skill apply step MUST be strictly additive — it MUST NOT delete or move any files

When the user confirms the plan, the skill MUST apply only additive operations:
- **Create** directories and stub files for items classified as "missing"
- **Flag** items classified as "unexpected" by noting them in the report (never by touching the files themselves)

The skill MUST NOT delete, rename, move, or overwrite any existing file or directory.

#### Scenario: missing CLAUDE.md — stub file created

- **GIVEN** `PROJECT_CLAUDE_DIR/CLAUDE.md` does not exist
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** a stub `CLAUDE.md` file is created at `PROJECT_CLAUDE_DIR/CLAUDE.md`
- **AND** the stub contains at minimum a `## Skills Registry` section heading to satisfy P1-C audit checks

#### Scenario: missing skills/ directory — empty directory created

- **GIVEN** `PROJECT_CLAUDE_DIR/skills/` does not exist
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** an empty `skills/` directory is created at `PROJECT_CLAUDE_DIR/skills/`
- **AND** no files are placed inside it

#### Scenario: unexpected item present — item is NOT touched

- **GIVEN** `PROJECT_CLAUDE_DIR/commands/` exists (legacy artifact, not in expected set)
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** `PROJECT_CLAUDE_DIR/commands/` remains untouched — not moved, not renamed, not deleted
- **AND** the unexpected item is documented in the report with a warning note

#### Scenario: already-correct items are not re-created or modified

- **GIVEN** `PROJECT_CLAUDE_DIR/hooks/` already exists and is in the expected set
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** `PROJECT_CLAUDE_DIR/hooks/` is not modified in any way
- **AND** no write operation is performed on it

#### Scenario: existing content in CLAUDE.md is never overwritten

- **GIVEN** `PROJECT_CLAUDE_DIR/CLAUDE.md` already exists with content
- **AND** the user has confirmed the plan
- **WHEN** the apply step runs
- **THEN** the skill does NOT create or overwrite `PROJECT_CLAUDE_DIR/CLAUDE.md`
- **AND** the existing file is left exactly as it was

---

### Requirement: skill MUST register in global CLAUDE.md under the correct sections

After the skill is created and deployed, CLAUDE.md MUST contain:
1. A command entry for `/project-claude-organizer` in the Available Commands table under "Meta-tools"
2. A registry entry in the Skills Registry under a "Meta-tool Skills" or "System Audits" sub-section

#### Scenario: CLAUDE.md Available Commands table contains the new command

- **GIVEN** `sdd-apply` has completed for this change
- **AND** `install.sh` has been run
- **WHEN** `CLAUDE.md` is read
- **THEN** the Available Commands table contains an entry for `/project-claude-organizer`
- **AND** the description reads: "Reads the project .claude/ folder, compares against canonical SDD structure, and applies reorganization after user confirmation"

#### Scenario: CLAUDE.md Skills Registry contains the new skill entry

- **GIVEN** `sdd-apply` has completed and `install.sh` has been run
- **WHEN** `CLAUDE.md` Skills Registry is read
- **THEN** it contains an entry: `~/.claude/skills/project-claude-organizer/SKILL.md`
- **AND** the entry is grouped under the "Meta-tool Skills" sub-section

#### Scenario: project-audit D1 passes after install.sh for the new skill

- **GIVEN** `skills/project-claude-organizer/SKILL.md` has been written
- **AND** the CLAUDE.md registry entry has been added
- **AND** `install.sh` has been run
- **WHEN** `/project-audit` is run on `agent-config`
- **THEN** D1 passes without a finding for `project-claude-organizer`

---

### Requirement: skill MUST pass project-audit P3-C structural compliance checks

The new `SKILL.md` MUST satisfy the format contract for `procedural` format.

#### Scenario: SKILL.md passes P3-C structural compliance

- **GIVEN** `skills/project-claude-organizer/SKILL.md` has been created with `format: procedural`
- **WHEN** `project-audit` or `claude-folder-audit` runs P3-C checks
- **THEN** the scanner finds:
  - YAML frontmatter with `---` block present
  - `format: procedural` declared
  - A `**Triggers**` bold marker line present
  - A `## Process` section (or `### Step N` steps) present
  - A `## Rules` section present
  - Body length of at least 30 lines
- **AND** no MEDIUM or HIGH findings are raised for this skill

---

### Requirement: skill behavior MUST be clearly differentiated from project-fix and claude-folder-audit

The skill MUST NOT be a duplicate or extension of `project-fix` or `claude-folder-audit`. Its
SKILL.md MUST clearly state its scope boundary.

#### Scenario: SKILL.md states that it reads .claude/ live state, not audit-report.md

- **GIVEN** a user reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they look for scope clarification
- **THEN** the SKILL.md contains an explicit note stating: this skill reads the live `.claude/` folder state directly and does NOT read from `audit-report.md`
- **AND** it states: `project-fix` is the skill that reads `audit-report.md` and applies its corrections

#### Scenario: SKILL.md states it does NOT target ~/.claude/

- **GIVEN** a user reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they look for target path clarification
- **THEN** the SKILL.md explicitly states: this skill targets project `.claude/` folders only — it MUST NOT be run against `~/.claude/`

---

---

### Requirement: Step 3b — Legacy Directory Intelligence layer classifies 8 known legacy patterns before fallthrough to UNEXPECTED

*(Added in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

After the three-bucket classification (MISSING_REQUIRED / UNEXPECTED / PRESENT) completes in
Step 3 and after the DOCUMENTATION_CANDIDATES classification runs, the skill MUST execute a
Legacy Directory Intelligence layer (Step 3b). This layer MUST inspect every remaining item
in `UNEXPECTED` and, for each item whose name matches a known legacy directory or file pattern,
reclassify it into a new `LEGACY_MIGRATIONS` collection, removing it from `UNEXPECTED`.

Items that match no known legacy pattern MUST remain in `UNEXPECTED` — the existing "review
manually" behavior is preserved for genuinely unknown items.

**The 8 known legacy patterns and their migration strategies:**

| Pattern name | Match condition | Migration strategy | Destination |
|---|---|---|---|
| `commands/` | Directory named `commands` | Delegate (advisory) | Skill creation via `/skill-create` |
| `docs/` | Directory named `docs` | Copy per file | `ai-context/features/<name>.md` |
| `system/` | Directory named `system` | Route by filename + append | `ai-context/architecture.md`, `ai-context/stack.md` |
| `plans/` | Directory named `plans` | Route by status | `openspec/changes/<name>/` or `openspec/changes/archive/<name>/` |
| `requirements/` | Directory named `requirements` | Scaffold only | `openspec/changes/<date>-<slug>/proposal.md` |
| `sops/` | Directory named `sops` | User choice per file | `ai-context/conventions.md` section OR `docs/sops/` |
| `templates/` | Directory named `templates` | Copy | `docs/templates/` |
| `project.md` | Root `.md` file named `project.md` | Section-distribute | `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/known-issues.md` |
| `readme.md` | Root `.md` file named `readme.md` (case-insensitive) | Section-distribute | `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/known-issues.md` |

Each entry in `LEGACY_MIGRATIONS` MUST carry:
- `source`: the absolute source path
- `destination`: one or more proposed destination paths
- `strategy`: one of `copy` / `append` / `scaffold` / `delegate` / `section-distribute` / `user-choice`
- `confirmation_required`: always `true`

#### Scenario: commands/ directory is reclassified as LEGACY_MIGRATIONS with delegate strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `commands/` directory
- **AND** `commands/` is in the `UNEXPECTED` bucket after initial classification
- **WHEN** Step 3b runs
- **THEN** `commands/` is removed from `UNEXPECTED`
- **AND** `commands/` is added to `LEGACY_MIGRATIONS` with strategy `delegate` and destination advisory "invoke /skill-create per qualifying file"

#### Scenario: docs/ directory is reclassified as LEGACY_MIGRATIONS with copy strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `docs/` directory
- **AND** `docs/` is in the `UNEXPECTED` bucket
- **WHEN** Step 3b runs
- **THEN** `docs/` is removed from `UNEXPECTED`
- **AND** `docs/` is added to `LEGACY_MIGRATIONS` with strategy `copy` and destination `ai-context/features/<name>.md` per file

#### Scenario: system/ directory is reclassified with route-and-append strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `system/` directory
- **WHEN** Step 3b runs
- **THEN** `system/` is removed from `UNEXPECTED`
- **AND** `system/` is added to `LEGACY_MIGRATIONS` with strategy `append`, mapping `architecture.md` → `ai-context/architecture.md` and `database.md` + `api-overview.md` → `ai-context/stack.md`

#### Scenario: plans/ directory is reclassified with route-by-status strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `plans/` directory
- **WHEN** Step 3b runs
- **THEN** `plans/` is removed from `UNEXPECTED`
- **AND** `plans/` is added to `LEGACY_MIGRATIONS` with strategy `copy`, routing active plans → `openspec/changes/<name>/` and archived plans → `openspec/changes/archive/<name>/`

#### Scenario: requirements/ directory is reclassified with scaffold-only strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `requirements/` directory
- **WHEN** Step 3b runs
- **THEN** `requirements/` is removed from `UNEXPECTED`
- **AND** `requirements/` is added to `LEGACY_MIGRATIONS` with strategy `scaffold`, destination `openspec/changes/<date>-<slug>/proposal.md` per file

#### Scenario: sops/ directory is reclassified with user-choice strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `sops/` directory
- **WHEN** Step 3b runs
- **THEN** `sops/` is removed from `UNEXPECTED`
- **AND** `sops/` is added to `LEGACY_MIGRATIONS` with strategy `user-choice`, offering dual destinations per file: `ai-context/conventions.md` (append to section) or `docs/sops/<filename>`

#### Scenario: templates/ directory is reclassified with copy strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a `templates/` directory
- **WHEN** Step 3b runs
- **THEN** `templates/` is removed from `UNEXPECTED`
- **AND** `templates/` is added to `LEGACY_MIGRATIONS` with strategy `copy` and destination `docs/templates/`

#### Scenario: project.md at .claude/ root is reclassified with section-distribute strategy

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a file `project.md` at its root
- **AND** `project.md` is in the `UNEXPECTED` bucket (no documentation-candidate signal fired)
- **WHEN** Step 3b runs
- **THEN** `project.md` is removed from `UNEXPECTED`
- **AND** `project.md` is added to `LEGACY_MIGRATIONS` with strategy `section-distribute`, targeting `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/known-issues.md` based on section headings

#### Scenario: readme.md at .claude/ root is reclassified with section-distribute strategy (case-insensitive)

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a file `README.md` at its root
- **WHEN** Step 3b runs
- **THEN** `README.md` is matched case-insensitively as a `readme.md` legacy pattern
- **AND** it is reclassified as a `LEGACY_MIGRATIONS` entry with strategy `section-distribute`

#### Scenario: unknown directory remains in UNEXPECTED after Step 3b

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a directory named `old-stuff/`
- **AND** `old-stuff/` is in the `UNEXPECTED` bucket
- **WHEN** Step 3b runs
- **THEN** `old-stuff/` is NOT matched by any of the 8 known legacy patterns
- **AND** `old-stuff/` remains in `UNEXPECTED` with the "review manually" flag

#### Scenario: Step 3b does not scan subdirectories — only top-level UNEXPECTED items

- **GIVEN** `PROJECT_CLAUDE_DIR` contains a directory `extra/` with a subdirectory `commands/` inside it
- **WHEN** Step 3b runs
- **THEN** the inner `commands/` directory is NOT matched by the legacy pattern
- **AND** only the top-level `extra/` is evaluated (and it does not match, so it stays in UNEXPECTED)

---

### Requirement: Step 4 dry-run plan MUST display a "Legacy migrations" section when LEGACY_MIGRATIONS is non-empty

*(Added in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

When `LEGACY_MIGRATIONS` is non-empty, the dry-run plan MUST display a new section titled
`Legacy migrations` between the "Documentation to migrate" section (if present) and the
"Unexpected items" section. This section MUST list each legacy item with:
- The source path (relative to `PROJECT_CLAUDE_DIR`)
- The proposed destination path(s)
- The migration strategy label
- A note that source files are never deleted

The "Unexpected items" section that follows MUST contain only the genuinely unknown items
that were NOT reclassified by Step 3b.

#### Scenario: Legacy migrations section appears in dry-run plan when legacy items exist

- **GIVEN** `LEGACY_MIGRATIONS` contains `commands/` (delegate) and `docs/` (copy)
- **WHEN** the dry-run plan is displayed in Step 4
- **THEN** the plan contains a section labeled `Legacy migrations`
- **AND** it lists `commands/` with strategy "delegate — advisory for /skill-create"
- **AND** it lists `docs/` with strategy "copy — each .md file → ai-context/features/<name>.md"
- **AND** the section notes that source files are preserved (never deleted or moved)

#### Scenario: Unexpected items section shows only genuinely unknown items

- **GIVEN** `LEGACY_MIGRATIONS` contains `docs/` and `UNEXPECTED` still contains `old-stuff/`
- **WHEN** the dry-run plan is displayed
- **THEN** `docs/` does NOT appear in the "Unexpected items" section
- **AND** `old-stuff/` appears in the "Unexpected items" section with the "review manually" flag

#### Scenario: Legacy migrations section absent when no legacy items detected

- **GIVEN** `LEGACY_MIGRATIONS` is empty
- **WHEN** the dry-run plan is displayed
- **THEN** no `Legacy migrations` section appears in the output

#### Scenario: Per-category user confirmation prompt precedes each legacy category in Step 4

- **GIVEN** the plan displays a `Legacy migrations` section with items from multiple categories
- **WHEN** the plan is shown to the user
- **THEN** the plan notes that each legacy migration category requires explicit user confirmation before any write occurs
- **AND** the top-level `Apply this plan? (yes/no)` prompt is still shown after the full plan

---

### Requirement: Step 5.7 — Legacy migrations apply with per-category confirmation gates

*(Added in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

After the existing Step 5.6 (acknowledge already-correct items), a new sub-step 5.7 MUST
apply legacy migrations in strategy order. Each category of legacy migration MUST be
presented to the user separately with a per-category confirmation gate before any write
for that category occurs.

**Strategy execution order:** delegate → section-distribute → copy → append → scaffold → user-choice

**Per-category gate behavior:**
- The skill presents the full list of files in the category and their proposed destinations
- The user responds with `yes/no` (or `all` to confirm all remaining categories at once)
- If the user responds `no`, that category is skipped entirely; all source files remain untouched
- If the user responds `yes` or `all`, the migration is applied for that category

**Category-specific behaviors:**

**delegate (`commands/`):**
- Read each `.md` file at the immediate `commands/` level (no recursion)
- Analyze content for "reusable workflow" markers (step-by-step process sections, trigger definitions, named command patterns)
- For qualifying files: output an advisory message naming the recommended skill and suggesting invocation of `/skill-create <suggested-name>` — do NOT auto-create anything
- For non-qualifying files: record as "non-qualifying — recommend archival"
- No files are written during the delegate strategy

**section-distribute (`project.md`, `readme.md`):**
- Read the file's section headings
- Map headings to destination files:
  - Tech-stack headings → `ai-context/stack.md`
  - Architecture headings → `ai-context/architecture.md`
  - Known-issues headings → `ai-context/known-issues.md`
- For each mapped section: present the section content to the user and request per-section confirmation before appending to destination
- Source file is NEVER deleted or modified

**copy (`docs/`, `templates/`):**
- `docs/`: copy each `.md` file at the immediate `docs/` level to `ai-context/features/<name>.md`; skip if destination exists (record as skipped)
- `templates/`: copy each file at the immediate `templates/` level to `docs/templates/<filename>`; skip if destination exists
- Source files are NEVER deleted

**append (`system/`):**
- Route `architecture.md` → append to `ai-context/architecture.md` under a labeled section separator `<!-- appended from .claude/system/architecture.md YYYY-MM-DD -->`
- Route `database.md` and `api-overview.md` → append to `ai-context/stack.md` under a labeled section separator
- If a destination file does not exist, create it with the appended content
- Source files are NEVER deleted

**scaffold (`requirements/`):**
- For each `.md` file at the immediate `requirements/` level: generate a scaffold path `openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md` where `<slug>` is derived from the filename stem
- Create the directory and write a scaffold `proposal.md` only if the destination does NOT already exist
- The scaffold contains a minimal header: `# Proposal: <slug>` and empty sections matching the proposal template
- Source files are NEVER deleted

**user-choice (`sops/`):**
- For each `.md` file at the immediate `sops/` level: present a choice of destination:
  - Option A: append as a named section in `ai-context/conventions.md`
  - Option B: copy to `docs/sops/<filename>` (creating the directory if needed)
- User selects per file OR can choose "apply option A to all" / "apply option B to all"
- Source files are NEVER deleted

#### Scenario: delegate strategy produces advisory output, writes nothing

- **GIVEN** `commands/` contains `deploy.md` with step-by-step workflow content
- **AND** the user confirms the `commands/` category
- **WHEN** Step 5.7 applies the delegate strategy
- **THEN** the skill outputs an advisory: "deploy.md — recommended skill name: deploy; invoke /skill-create deploy to scaffold the SKILL.md"
- **AND** no file is created or modified by this step
- **AND** the source `commands/deploy.md` is untouched

#### Scenario: delegate strategy marks non-qualifying file for archival

- **GIVEN** `commands/` contains `notes.md` with no workflow markers
- **AND** the user confirms the `commands/` category
- **WHEN** Step 5.7 applies the delegate strategy
- **THEN** the skill records `notes.md — non-qualifying — recommend archival`
- **AND** no file is created or modified

#### Scenario: copy strategy skips files where destination already exists

- **GIVEN** `docs/` contains `auth.md`
- **AND** `ai-context/features/auth.md` already exists
- **AND** the user confirms the `docs/` category
- **WHEN** Step 5.7 applies the copy strategy
- **THEN** `ai-context/features/auth.md` is NOT overwritten
- **AND** the outcome is recorded as `auth.md — skipped (destination exists)`
- **AND** the source `docs/auth.md` is untouched

#### Scenario: append strategy uses labeled section separators

- **GIVEN** `system/` contains `architecture.md`
- **AND** `ai-context/architecture.md` already exists
- **AND** the user confirms the `system/` category
- **WHEN** Step 5.7 applies the append strategy
- **THEN** the content of `system/architecture.md` is appended to `ai-context/architecture.md`
- **AND** the appended block begins with a separator comment: `<!-- appended from .claude/system/architecture.md YYYY-MM-DD -->`
- **AND** the source `system/architecture.md` is untouched

#### Scenario: scaffold strategy creates proposal scaffold only when destination absent

- **GIVEN** `requirements/` contains `auth-requirements.md`
- **AND** `openspec/changes/<date>-auth-requirements/proposal.md` does NOT exist
- **AND** the user confirms the `requirements/` category
- **WHEN** Step 5.7 applies the scaffold strategy
- **THEN** a directory `openspec/changes/<date>-auth-requirements/` is created
- **AND** a minimal `proposal.md` scaffold is written with a `# Proposal: auth-requirements` header
- **AND** the source `requirements/auth-requirements.md` is untouched

#### Scenario: scaffold strategy is idempotent — no overwrite when destination exists

- **GIVEN** `requirements/` contains `auth-requirements.md`
- **AND** `openspec/changes/<date>-auth-requirements/proposal.md` already exists
- **WHEN** Step 5.7 applies the scaffold strategy
- **THEN** the existing `proposal.md` is NOT overwritten
- **AND** the outcome is recorded as `auth-requirements.md — scaffold skipped (proposal.md already exists)`

#### Scenario: user-choice strategy respects per-file selection

- **GIVEN** `sops/` contains `deployment-sop.md` and `onboarding-sop.md`
- **AND** the user selects Option A for `deployment-sop.md` and Option B for `onboarding-sop.md`
- **WHEN** Step 5.7 applies the user-choice strategy
- **THEN** `deployment-sop.md` content is appended as a named section in `ai-context/conventions.md`
- **AND** `onboarding-sop.md` is copied to `docs/sops/onboarding-sop.md`
- **AND** both source files are untouched

#### Scenario: skipped category — source files remain untouched

- **GIVEN** `docs/` is in `LEGACY_MIGRATIONS`
- **AND** the user responds `no` to the per-category confirmation for `docs/`
- **WHEN** Step 5.7 processes the `docs/` category
- **THEN** no write operations are performed for `docs/`
- **AND** all files under `docs/` remain at their original paths
- **AND** the skip is recorded in the report

#### Scenario: all source files remain untouched after any migration strategy

- **GIVEN** any legacy migration category was processed (confirmed or skipped)
- **WHEN** Step 5.7 completes
- **THEN** every source file or directory in `LEGACY_MIGRATIONS` still exists at its original path under `PROJECT_CLAUDE_DIR`
- **AND** no source file has been deleted, moved, or overwritten

---

### Requirement: "unexpected items receive a warning" behavior is now a fallthrough, not the primary bucket

*(Modified in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

*(Before: All items not in the canonical expected set and not in DOCUMENTATION_CANDIDATES fell into UNEXPECTED and received only a "review manually" flag.)*

The UNEXPECTED bucket now serves as the fallthrough for items that match neither the
DOCUMENTATION_CANDIDATES classification nor any of the 8 known legacy patterns in
LEGACY_MIGRATIONS. The "review manually" flag behavior for items in UNEXPECTED is unchanged —
only the scope of UNEXPECTED is narrowed.

#### Scenario: UNEXPECTED bucket contains only genuinely unknown items after Step 3b

- **GIVEN** `PROJECT_CLAUDE_DIR` contains `commands/`, `old-stuff/`, and `docs/`
- **WHEN** Step 3 and Step 3b classification completes
- **THEN** `commands/` and `docs/` are in `LEGACY_MIGRATIONS`
- **AND** `old-stuff/` is the only item in `UNEXPECTED`
- **AND** `old-stuff/` receives the "review manually" flag in Step 4 and Step 5.5

---

## Rules

- The skill targets ONLY `PROJECT_ROOT/.claude/` — never `~/.claude/`
- Apply step is strictly additive: create missing items and flag unexpected ones in the report — never delete, move, or overwrite
- The user confirmation gate MUST NOT be skipped under any circumstances
- The canonical expected item set MUST remain consistent with `claude-folder-audit` Check P8
- Windows path resolution MUST follow the same `$HOME` / `$USERPROFILE` / `$HOMEDRIVE$HOMEPATH` priority chain used by `claude-folder-audit` Step 1 (for CWD resolution only — not for `~/.claude/`)
- The plan MUST be shown in full before any file writes occur
- The skill MUST write `claude-organizer-report.md` to `PROJECT_CLAUDE_DIR` after successful apply (see folder-organizer-reporting spec)
- The skill MUST NOT invoke or depend on `claude-folder-audit` at runtime — it may reference P8's expected set as a shared reference but operates independently
- Step 3b MUST run after Step 3 DOCUMENTATION_CANDIDATES classification and before Step 4 plan presentation
- Step 3b MUST only inspect items currently in the `UNEXPECTED` bucket — it MUST NOT reclassify items already in `MISSING_REQUIRED`, `PRESENT`, or `DOCUMENTATION_CANDIDATES`
- Pattern matching in Step 3b is case-insensitive for directory names and file names
- Step 3b MUST NOT scan subdirectories — only top-level items in `OBSERVED_ITEMS` are eligible
- Each legacy migration category MUST have its own per-category confirmation gate in Step 5.7 — blanket confirmation does NOT bypass per-category gates unless the user explicitly selects "all"
- All migration strategies are strictly additive — source files MUST NEVER be deleted, moved, or overwritten
- The `commands/` delegate strategy MUST produce advisory output only — it MUST NOT auto-invoke `/skill-create` or create any files
- Append strategy (`system/`) MUST use labeled section separators — raw concatenation without a separator comment is not permitted
- Scaffold strategy (`requirements/`) MUST be idempotent — if the destination `proposal.md` already exists, the scaffold MUST be skipped
