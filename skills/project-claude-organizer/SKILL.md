---
name: project-claude-organizer
description: >
  Reads the project .claude/ folder, compares observed contents against the canonical SDD
  structure, presents a dry-run reorganization plan, and applies it additively after user
  confirmation. After successful migration, offers to delete source files from
  .claude/<category>/ with explicit user confirmation. Produces claude-organizer-report.md.
  Trigger: /project-claude-organizer, organize .claude folder, fix project claude structure,
  align project .claude to canonical SDD layout.
format: procedural
---

# project-claude-organizer

> Reads the project `.claude/` folder, compares it against the canonical SDD structure,
> presents a reorganization plan, applies migrations after user confirmation, and optionally
> deletes source files from `.claude/` after successful migration with explicit user confirmation.

**Triggers**: `/project-claude-organizer`, organize .claude folder, fix project claude structure, align .claude to canonical SDD layout, project claude organizer

> **Scope note**: This skill reads the **live `.claude/` folder state** directly — it does NOT
> read from `audit-report.md`. The skill that reads `audit-report.md` and applies its
> corrections is `project-fix`. This skill targets `PROJECT_ROOT/.claude/` only — it MUST
> NOT be run against `~/.claude/` (the user-level runtime).

---

## Process

### Step 1 — Resolve paths

Determine the project root and the target `.claude/` directory.

**1.1 — Resolve CWD as project root:**

`PROJECT_ROOT` = current working directory (absolute path).

Normalize all paths to forward slashes for display.

**1.2 — Resolve home directory (Windows-compatible):**

Use the following priority chain (same as `install.sh` and `claude-folder-audit`):

1. If `$HOME` is set and non-empty → `HOME_DIR = $HOME`
2. Else if `$USERPROFILE` is set and non-empty → `HOME_DIR = $USERPROFILE`
3. Else if `$HOMEDRIVE` and `$HOMEPATH` are both set → `HOME_DIR = $HOMEDRIVE$HOMEPATH`
4. Else → output error: "Cannot resolve home directory." and stop.

**1.3 — Set target directory:**

`PROJECT_CLAUDE_DIR = PROJECT_ROOT/.claude`

**1.4 — Guard: verify `.claude/` exists:**

Check whether `PROJECT_CLAUDE_DIR` exists as a directory.

If it does NOT exist:
```
No .claude/ folder found at <PROJECT_ROOT>.
This skill targets project .claude/ folders only — not the ~/.claude/ runtime.
It requires a project with an existing .claude/ directory.
Exiting without changes.
```
Stop. Do not write any files.

**1.5 — Guard: prevent targeting `~/.claude/`:**

If `PROJECT_CLAUDE_DIR` resolves to the same path as `HOME_DIR/.claude`, output:
```
This skill targets project .claude/ folders only — not the ~/.claude/ runtime.
Exiting without changes.
```
Stop.

---

### Step 2 — Enumerate observed items

List all items (files and directories) **one level deep** under `PROJECT_CLAUDE_DIR`.
Do not recurse into subdirectories.

Record each item as:
- `<name>` — for files
- `<name>/` — for directories

Collect the result as `OBSERVED_ITEMS`.

---

### Step 3 — Compare against canonical expected item set

The canonical expected item set for a project `.claude/` folder is defined below.
This set is cross-referenced to `claude-folder-audit` Check P8 and MUST remain consistent with it.

**Canonical expected item set (V1):**

```
# Cross-reference: claude-folder-audit Check P8
#
# Required (absence triggers a create action):
CLAUDE.md
skills/
#
# Optional (absence is informational only — not an error):
hooks/
audit-report.md
claude-folder-audit-report.md
claude-organizer-report.md
settings.json
settings.local.json
openspec/
ai-context/
```

**Classification rules:**

- `MISSING_REQUIRED` = items in the Required subset that are NOT in `OBSERVED_ITEMS`
  - Required items: `CLAUDE.md`, `skills/`
- `UNEXPECTED` = items in `OBSERVED_ITEMS` that are NOT in the full canonical expected set
- `PRESENT` = items in `OBSERVED_ITEMS` that ARE in the canonical expected set

**DOCUMENTATION_CANDIDATES classification (runs after the three-bucket classification above):**

```
KNOWN_AI_CONTEXT_TARGETS = [
  "stack",
  "architecture",
  "conventions",
  "known-issues",
  "changelog-ai",
  "onboarding",
  "quick-reference",
  "scenarios"
]

KNOWN_HEADING_PATTERNS = [
  "## Tech Stack",
  "## Architecture",
  "## Known Issues",
  "## Conventions",
  "## Changelog",
  "## Domain Overview"
]

DOCUMENTATION_CANDIDATES = []
```

For each `.md` file currently in `UNEXPECTED`:

**(a) Signal 1 — Filename stem match (case-insensitive):**
Extract the file's stem (filename without `.md` extension). If the stem matches any entry in `KNOWN_AI_CONTEXT_TARGETS` (case-insensitive):
- Add to `DOCUMENTATION_CANDIDATES` with `source = PROJECT_CLAUDE_DIR/<filename>.md`, `destination = PROJECT_ROOT/ai-context/<filename>.md`, `reason = "filename-match"`.
- Remove from `UNEXPECTED`.
- Do NOT apply Signal 2 for this file.

**(b) Signal 2 — Content heading match (for remaining `.md` files in UNEXPECTED only):**
Read the file's content. If any line starts with one of the `KNOWN_HEADING_PATTERNS` entries (case-sensitive, line-starts-with match):
- Add to `DOCUMENTATION_CANDIDATES` with `source = PROJECT_CLAUDE_DIR/<filename>.md`, `destination = PROJECT_ROOT/ai-context/<filename>.md`, `reason = "heading-match"`.
- Remove from `UNEXPECTED`.

Files matching neither signal remain in `UNEXPECTED` — no false promotion.

> **Scope note**: Only root-level `.md` files from `OBSERVED_ITEMS` are eligible. Subdirectory entries (e.g. `extra/`) are not scanned recursively — only the top-level directory entry is considered.

---

### Step 3b — Legacy Directory Intelligence

After the DOCUMENTATION_CANDIDATES classification completes, run a second pass over the remaining
items in `UNEXPECTED`. For each item whose name matches a known legacy directory or file pattern,
reclassify it into `LEGACY_MIGRATIONS` and remove it from `UNEXPECTED`. Items that match no known
pattern are left in `UNEXPECTED` unchanged — the existing "review manually" behavior is preserved
for genuinely unknown items.

```
LEGACY_MIGRATIONS = []
```

Items reclassified into `LEGACY_MIGRATIONS` are removed from `UNEXPECTED`. Each entry in
`LEGACY_MIGRATIONS` carries: `source` (absolute path), `destination` (one or more proposed
destination paths), `strategy` (see table below), and `confirmation_required = true`.

**LEGACY_PATTERN_TABLE** — quick-scan index (match order top-to-bottom, name match first):

| Pattern name | Match condition | Migration strategy | Destination summary |
|---|---|---|---|
| `commands/` | Directory named `commands` (case-insensitive) | `delegate` — advisory only | Skill creation advisory via `/skill-create` per qualifying `.md` file; no files written |
| `docs/` | Directory named `docs` (case-insensitive) | `copy` — per `.md` file | `ai-context/features/<name>.md` for each `.md` at immediate `docs/` level |
| `system/` | Directory named `system` (case-insensitive) | `append` — route by filename | `architecture.md` → `ai-context/architecture.md`; `database.md` + `api-overview.md` → `ai-context/stack.md` |
| `plans/` | Directory named `plans` (case-insensitive) | `copy` — route by status | Active plans → `openspec/changes/<plan-name>/`; archived plans → `openspec/changes/archive/<plan-name>/` |
| `requirements/` | Directory named `requirements` (case-insensitive) | `scaffold` — idempotent | `openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md` per `.md` file at immediate level |
| `sops/` | Directory named `sops` (case-insensitive) | `user-choice` — per file | Option A: append section to `ai-context/conventions.md`; Option B: copy to `docs/sops/<filename>` |
| `templates/` | Directory named `templates` (case-insensitive) | `copy` | `docs/templates/<filename>` for each file at immediate `templates/` level |
| `project.md` | Root-level `.md` file named `project.md` (case-insensitive) | `section-distribute` | Sections routed to `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/known-issues.md` by heading signal |
| `readme.md` | Root-level `.md` file named `readme.md` (case-insensitive) | `section-distribute` | Sections routed to `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/known-issues.md` by heading signal |

**Classification loop:**

For each item in `UNEXPECTED`:
- Match item name (case-insensitive) against `LEGACY_PATTERN_TABLE` (top-to-bottom):
  - **On hit**: add entry to `LEGACY_MIGRATIONS` (`source`, `destination(s)`, `strategy`, `confirmation_required = true`); remove item from `UNEXPECTED`.
  - **On miss**: item stays in `UNEXPECTED` — "review manually" behavior unchanged.

> **Scope rule**: Only top-level items (directories and root-level files enumerated in
> `OBSERVED_ITEMS`) are evaluated. Step 3b MUST NOT recurse into subdirectories — a directory
> named `commands/` nested inside another unexpected directory (e.g. `extra/commands/`) is NOT
> matched by the pattern.

#### Pattern detail blocks

##### Pattern: `commands/`

- **Match condition**: Directory named `commands` (case-insensitive)
- **Strategy**: `delegate` — SKILL_ADVISORY
- **Destination**: Advisory only — no file writes under any circumstance

**Content analysis procedure** (runs when `commands/` category is confirmed in Step 5.7):

1. List all `.md` files at the **immediate** `commands/` level only (no recursion into subdirectories).
2. If no `.md` files are found → output:
   `commands/ — no .md files found at immediate level; nothing to advise`
   Stop; no further processing for this category.
3. For each `.md` file found, apply the **4 qualifying markers** (any one marker is sufficient to qualify):
   - **(a) Step-numbered sections**: the file contains lines matching `### Step N`, `- Step N`, or `N.` where N is a number (numbered/bulleted process sections)
   - **(b) Trigger / invocation patterns**: the file contains lines starting with `/command-name` (slash-command references) or lines containing `**Triggers**` or `trigger:` (trigger definitions)
   - **(c) Process headings**: the file contains a section heading that is exactly `## Process`, `## Steps`, `## How to`, or `## Instructions`
   - **(d) Filename-stem keyword match**: the file's stem (case-insensitive) matches one of: `deploy`, `rollback`, `setup`, `onboard`, `audit`, `install`, `release`, `build`, `migrate`, `sync`
4. **Qualifying file** (at least one marker matched):
   Output advisory:
   `<filename> — qualifying workflow detected. Suggested skill name: <stem>. Suggested format: procedural. To scaffold: /skill-create <stem>`
   Do NOT create any file or directory. Do NOT invoke `/skill-create`.
5. **Non-qualifying file** (no marker matched):
   Record: `<filename> — non-qualifying (no structured workflow detected). Recommend manual archival.`
   Do NOT create or modify any file.

> **Invariant**: The delegate strategy produces **zero file writes**. Any write operation during `commands/` processing is a violation of this invariant. Source files are NEVER deleted, moved, or modified.

---

##### Pattern: `docs/`

- **Match condition**: Directory named `docs` (case-insensitive)
- **Strategy**: `copy` — per `.md` file
- **Destination**: `PROJECT_ROOT/ai-context/features/<name>.md` for each `*.md` file at the immediate `docs/` level

**Copy procedure** (runs when `docs/` category is confirmed in Step 5.7):

1. List all `.md` files at the **immediate** `docs/` level only (no recursion).
2. Ensure `PROJECT_ROOT/ai-context/features/` directory exists; create it if absent before copying.
3. For each `.md` file:
   - Derive `<name>` = filename including `.md` extension.
   - Destination = `PROJECT_ROOT/ai-context/features/<name>.md`.
   - **If destination exists**: record `<name> — skipped (destination exists)`. Do NOT overwrite.
   - **If destination does not exist**: copy source to destination; record `<name> — copied to ai-context/features/<name>.md`.
4. Source files are NEVER deleted, moved, or modified.

---

##### Pattern: `system/`

- **Match condition**: Directory named `system` (case-insensitive)
- **Strategy**: `append` — route by filename to appropriate `ai-context/` file
- **Routing table**:
  - `architecture.md` → `PROJECT_ROOT/ai-context/architecture.md`
  - `database.md` → `PROJECT_ROOT/ai-context/stack.md`
  - `api-overview.md` → `PROJECT_ROOT/ai-context/stack.md`
  - All other files at the immediate `system/` level → record as `<filename> — no routing rule; skipped`

**Append procedure** (runs when `system/` category is confirmed in Step 5.7):

1. List all files at the **immediate** `system/` level only (no recursion).
2. For each file matched by the routing table:
   - Destination = the mapped `ai-context/` file.
   - **If destination does not exist**: create it with the appended content.
   - **Merge strategy**: append the entire file content to the destination, preceded by the labeled separator:
     `<!-- appended from .claude/system/<filename> YYYY-MM-DD -->`
     (Replace `YYYY-MM-DD` with the current date at apply time.)
   - Record: `<filename> — appended to <destination> (separator added)`.
3. Source files are NEVER deleted, moved, or modified.

---

##### Pattern: `plans/`

- **Match condition**: Directory named `plans` (case-insensitive)
- **Strategy**: `copy` — route by active / archived status
- **Routing**:
  - Active plans → `PROJECT_ROOT/openspec/changes/<plan-name>/`
  - Archived plans → `PROJECT_ROOT/openspec/changes/archive/<plan-name>/`

**Active vs. archived determination**: The skill does NOT apply any heuristic to classify a plan item as active or archived. For **each item** at the immediate `plans/` level, the skill MUST ask the user at apply time:
`Is "<plan-name>" an active plan or an archived plan? (active/archived)`

**Copy procedure** (runs when `plans/` category is confirmed in Step 5.7):

1. List all items at the **immediate** `plans/` level only (no recursion).
2. For each item, prompt the user to classify it as active or archived (per item).
3. Determine destination directory:
   - Active → `PROJECT_ROOT/openspec/changes/<plan-name>/`
   - Archived → `PROJECT_ROOT/openspec/changes/archive/<plan-name>/`
4. **If destination directory already exists**: record `<plan-name> — skipped (destination exists)`. Do NOT overwrite.
5. **If destination directory does not exist**: create the directory; copy the item's contents into it; record `<plan-name> — copied to <destination>`.
6. Source files and directories are NEVER deleted, moved, or modified.

---

##### Pattern: `requirements/`

- **Match condition**: Directory named `requirements` (case-insensitive)
- **Strategy**: `scaffold` — idempotent
- **Destination**: `openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md` — one proposal stub per `.md` file at the immediate `requirements/` level. `<slug>` is derived from the filename stem (filename without the `.md` extension). `<YYYY-MM-DD>` is the current date at apply time.

**Scaffold procedure** (runs when `requirements/` category is confirmed in Step 5.7):

1. List all `.md` files at the **immediate** `requirements/` level only (no recursion into subdirectories).
2. For each `.md` file:
   - Derive `<slug>` = filename stem (case-preserved, e.g. `auth-requirements.md` → `auth-requirements`).
   - Construct scaffold path: `PROJECT_ROOT/openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md`.
   - **If `proposal.md` already exists at that path**: record `<slug> — scaffold skipped (proposal.md already exists)`. Do NOT overwrite.
   - **If `proposal.md` does not exist**: create the directory `openspec/changes/<YYYY-MM-DD>-<slug>/` and write the following minimal scaffold:

     ```markdown
     # Proposal: <slug>

     ## Problem Statement

     <!-- Describe the problem to be solved. -->

     ## Proposed Solution

     <!-- Describe the proposed approach. -->

     ## Success Criteria

     - [ ]
     ```

   - Record: `<slug> — scaffolded to openspec/changes/<date>-<slug>/proposal.md`.
3. Source files are NEVER deleted, moved, or modified.

---

##### Pattern: `sops/`

- **Match condition**: Directory named `sops` (case-insensitive)
- **Strategy**: `user-choice` — per file
- **Destinations**:
  - **Option A**: Append file content as a named section to `PROJECT_ROOT/ai-context/conventions.md`. Section heading: `## <stem>` (filename stem). If `ai-context/conventions.md` does not exist, create it. Append under labeled separator: `<!-- appended from .claude/sops/<filename> YYYY-MM-DD -->`.
  - **Option B**: Copy file to `PROJECT_ROOT/docs/sops/<filename>`. Create `docs/sops/` directory if absent. If destination already exists: record `<filename> — skipped (destination exists)`. Do NOT overwrite.

**User-choice procedure** (runs when `sops/` category is confirmed in Step 5.7):

1. List all `.md` files at the **immediate** `sops/` level only (no recursion).
2. Present the list to the user with both destination options.
3. The user selects per file, or can use global shortcuts:
   - `apply option A to all` — applies Option A to all files in `sops/`
   - `apply option B to all` — applies Option B to all files in `sops/`
4. Execute the selection for each file according to the chosen option.
5. Source files are NEVER deleted, moved, or modified.

---

##### Pattern: `templates/`

- **Match condition**: Directory named `templates` (case-insensitive)
- **Strategy**: `copy`
- **Destination**: `PROJECT_ROOT/docs/templates/<filename>` — one copy per file at the immediate `templates/` level (no recursion into subdirectories of `templates/`).

**Copy procedure** (runs when `templates/` category is confirmed in Step 5.7):

1. List all files at the **immediate** `templates/` level only (no recursion).
2. Ensure `PROJECT_ROOT/docs/templates/` directory exists; create it if absent before copying.
3. For each file:
   - Destination = `PROJECT_ROOT/docs/templates/<filename>`.
   - **If destination exists**: record `<filename> — skipped (destination exists)`. Do NOT overwrite.
   - **If destination does not exist**: copy source to destination; record `<filename> — copied to docs/templates/<filename>`.
4. Source files are NEVER deleted, moved, or modified.

---

##### Pattern: `project.md` and `readme.md`

- **Match condition**: Root-level `.md` file named `project.md` or `readme.md` (case-insensitive match on the full filename).
- **Strategy**: `section-distribute`
- **Section routing heuristic**: read the file's section headings and route each section to a destination using the following signal lists:

  ```
  STACK_HEADING_SIGNALS    = ["## Tech Stack", "## Stack", "## Dependencies", "## Tools"]
  ARCH_HEADING_SIGNALS     = ["## Architecture", "## System Design", "## Overview"]
  ISSUES_HEADING_SIGNALS   = ["## Known Issues", "## Issues", "## Gotchas", "## Limitations"]
  ```

  - A heading matching any entry in `STACK_HEADING_SIGNALS` → routes that section to `ai-context/stack.md`
  - A heading matching any entry in `ARCH_HEADING_SIGNALS` → routes that section to `ai-context/architecture.md`
  - A heading matching any entry in `ISSUES_HEADING_SIGNALS` → routes that section to `ai-context/known-issues.md`
  - Headings matching no signal list are not routed and not appended to any file.

**Section-distribute procedure** (runs when `project.md` / `readme.md` category is confirmed in Step 5.7):

1. Read the file's section headings.
2. For each heading matched by a signal list, extract the section content (from the heading to the next same-level or higher heading).
3. **Per-section user confirmation**: present each matched section's content to the user and request explicit confirmation before appending. Do NOT append any section that the user does not confirm.
4. **Append strategy**: append each confirmed section to the destination file under the labeled separator:
   `<!-- appended from .claude/<filename> YYYY-MM-DD -->`
   (Replace `<filename>` with the actual filename, e.g. `project.md`. Replace `YYYY-MM-DD` with the current date.)
   If the destination file does not exist, create it with the appended content.
5. Source file is NEVER deleted or modified.

---

### Step 4 — Build and present dry-run plan

Build the reorganization plan from the three categories above.

**If `MISSING_REQUIRED` is empty AND `UNEXPECTED` is empty AND `DOCUMENTATION_CANDIDATES` is empty AND `LEGACY_MIGRATIONS` is empty:**

Output:
```
No reorganization needed — .claude/ already matches the canonical SDD structure.
```

Proceed directly to Step 6 to write the report (no confirmation prompt needed).

**Otherwise**, display the plan in this format:

```
Reorganization Plan for: <PROJECT_CLAUDE_DIR>
─────────────────────────────────────────────

To be created (missing required items):
  + CLAUDE.md    — stub file (5 section headings)
  + skills/      — empty directory

Documentation to migrate → ai-context/:
  → stack.md      → ai-context/stack.md       (copy only — source preserved)
  → notes.md      → ai-context/notes.md       (copy only — source preserved)

  Note: individual files can be excluded before confirmation — list them as
  exclusions when responding to the prompt below.

Legacy migrations (source files offered for deletion after successful migration):
  ~ commands/    — strategy: delegate — advisory for /skill-create per qualifying .md file
  ~ docs/        — strategy: copy — each .md file → ai-context/features/<name>.md
  ~ system/      — strategy: append — architecture.md → ai-context/architecture.md;
                   database.md + api-overview.md → ai-context/stack.md
  ~ plans/       — strategy: copy — active → openspec/changes/<name>/;
                   archived → openspec/changes/archive/<name>/
  ~ requirements/ — strategy: scaffold — openspec/changes/<date>-<slug>/proposal.md per .md file
  ~ sops/        — strategy: user-choice — Option A: ai-context/conventions.md section;
                   Option B: docs/sops/<filename>
  ~ templates/   — strategy: copy — each file → docs/templates/<filename>
  ~ project.md   — strategy: section-distribute → ai-context/stack.md,
                   ai-context/architecture.md, ai-context/known-issues.md

  Note: each legacy migration category requires explicit per-category confirmation in Step 5.7
  before any write occurs. Source files are offered for deletion after successful migration —
  deletion requires explicit user confirmation. delegate and section-distribute strategies
  are exempt from cleanup prompts.

Unexpected items (will be flagged, NOT deleted or moved):
  ! commands/    — not part of canonical SDD .claude/ structure (review manually)

Already correct:
  ✓ hooks/
  ✓ ai-context/
  ✓ openspec/

These items will NOT be deleted or moved — unexpected items receive a warning
comment in the report only.
```

Omit any category that has zero items (applies to all four categories).

After displaying the plan, prompt:
```
Apply this plan? (yes/no)
```

Wait for user input before proceeding.

- If the user responds with `yes`, `y`, `proceed`, or `apply` (case-insensitive) → proceed to Step 5.
- If the user responds with `no`, `n`, `cancel`, or `abort`, or provides no answer → output:
  ```
  Reorganization cancelled. No changes were made.
  ```
  Stop. Do not write any files (including the report).

---

### Step 5 — Apply plan (strictly additive)

Apply ONLY the operations listed in the plan. No additional operations.

**5.1 — Create missing `skills/` directory:**

If `skills/` is in `MISSING_REQUIRED`:
- Create an empty directory at `PROJECT_CLAUDE_DIR/skills/`.
- Do NOT place any files inside it.
- Record: `skills/ — directory created`.

**5.2 — Create missing `hooks/` directory:**

If `hooks/` is in `MISSING_REQUIRED` (hooks/ is optional, but if explicitly listed in plan):
- Create an empty directory at `PROJECT_CLAUDE_DIR/hooks/`.
- Record: `hooks/ — directory created`.

**5.3 — Create missing `CLAUDE.md` stub:**

If `CLAUDE.md` is in `MISSING_REQUIRED`:
- Verify `PROJECT_CLAUDE_DIR/CLAUDE.md` does NOT already exist (idempotency guard).
  If it already exists → skip this operation, record as `CLAUDE.md — already exists (skipped)`.
- Write the following minimal stub to `PROJECT_CLAUDE_DIR/CLAUDE.md`:

```markdown
# [Project Name] — Claude Configuration

## Tech Stack

<!-- Add your project tech stack here. -->

## Architecture

<!-- Describe the project architecture here. -->

## Unbreakable Rules

<!-- Add project-specific rules here. -->

## Plan Mode Rules

<!-- Add plan mode rules here. -->

## Skills Registry

<!-- List skills used by this project here.
     Global skills: ~/.claude/skills/<name>/SKILL.md
     Local skills:  .claude/skills/<name>/SKILL.md
     Run /project-setup for full initialization. -->
```

- Record: `CLAUDE.md — stub file created`.

**5.4 — Copy documentation candidates to ai-context/:**

Process each file in `DOCUMENTATION_CANDIDATES`:

**(a) Ensure `PROJECT_ROOT/ai-context/` exists:**
If the directory does not exist, create it before attempting any copy.

**(b) For each file NOT excluded by the user:**
- Check whether the destination (`PROJECT_ROOT/ai-context/<filename>.md`) already exists.
  - If destination **exists**: do not write anything. Record: `<filename>.md — skipped (destination exists — review manually)`. Leave both source and destination untouched.
  - If destination **does not exist**: copy source to destination. After the copy, verify that the source file still exists at `PROJECT_CLAUDE_DIR/<filename>.md`.
    - If source still exists → record: `<filename>.md — copied to ai-context/<filename>.md`.
    - If source no longer exists after copy → record: `<filename>.md — failed — source missing after copy` and do NOT mark as success.
  - On any other copy failure: record `<filename>.md — failed — <error reason>` and continue processing remaining candidates.

**(c) For each file excluded by the user:**
- Do NOT copy or modify the file.
- Record: `<filename>.md — excluded by user`.

**Source preservation invariant**: NEVER delete or modify the source file under any circumstance. The source file at `PROJECT_CLAUDE_DIR/<filename>.md` must exist and be unmodified after this step completes.

**5.5 — Flag unexpected items:**

For each item in `UNEXPECTED`:
- Do NOT touch the file or directory in any way.
- Record it as `<name> — unexpected item flagged in report (not modified)`.

**5.6 — Acknowledge already-correct items:**

For each item in `PRESENT`:
- No operation performed.
- Record it as `<name> — already correct (no change)`.

**5.7 — Apply legacy migrations (per-category confirmation gates):**

Process categories in strategy execution order: delegate → section-distribute → copy → append → scaffold → user-choice.

For each category in `LEGACY_MIGRATIONS` (grouped by strategy, processed in the order above):
1. Present the full list of files in the category and their proposed destinations.
2. Prompt: `Apply <category> migrations? (yes/no/all)`
3. If the user responds `no`: skip the category entirely; record `<category> — skipped by user (no files written)`. Do NOT write any files for this category.
4. If the user responds `yes` or `all`: apply the strategy for this category (see sub-steps below). The `all` response also confirms all remaining unprocessed categories — no further per-category prompts are required for those.

**5.7.1 — delegate strategy (`commands/`):**

1. List all `.md` files at the **immediate** `commands/` level (no recursion into subdirectories).
2. If no `.md` files are found at the immediate level:
   Output: `commands/ — no .md files found at immediate level; nothing to advise`
   Stop processing this category.
3. For each `.md` file found, apply the **4 qualifying markers** (any one is sufficient to qualify):
   - **(a) Step-numbered sections**: the file contains lines matching `### Step N`, `- Step N`, or `N.` where N is a number
   - **(b) Trigger / invocation patterns**: the file contains lines starting with `/command-name` or lines containing `**Triggers**` or `trigger:`
   - **(c) Process headings**: the file contains a section heading that is exactly `## Process`, `## Steps`, `## How to`, or `## Instructions`
   - **(d) Filename-stem keyword match**: the file's stem (case-insensitive) matches one of: `deploy`, `rollback`, `setup`, `onboard`, `audit`, `install`, `release`, `build`, `migrate`, `sync`
4. **Qualifying file** (at least one marker matched):
   Output advisory: `<filename> — qualifying workflow detected. Suggested skill name: <stem>. Suggested format: procedural. To scaffold: /skill-create <stem>`
   Do NOT create any file or directory. Do NOT invoke `/skill-create`.
5. **Non-qualifying file** (no marker matched):
   Record: `<filename> — non-qualifying (no structured workflow detected). Recommend manual archival.`
   Do NOT create or modify any file.

> **Invariant**: The delegate strategy produces **zero file writes**. Source files are NEVER touched.

**5.7.2 — section-distribute strategy (`project.md`, `readme.md`):**

1. Read the file's section headings.
2. Map each heading to a destination file using the signal lists:
   - `STACK_HEADING_SIGNALS = ["## Tech Stack", "## Stack", "## Dependencies", "## Tools"]` → `ai-context/stack.md`
   - `ARCH_HEADING_SIGNALS = ["## Architecture", "## System Design", "## Overview"]` → `ai-context/architecture.md`
   - `ISSUES_HEADING_SIGNALS = ["## Known Issues", "## Issues", "## Gotchas", "## Limitations"]` → `ai-context/known-issues.md`
   - Headings matching no signal list are not routed.
3. **Per-section user confirmation**: for each mapped section, present the section content to the user and request explicit confirmation before appending. Do NOT append any section the user does not confirm.
4. **Append strategy**: append each confirmed section to the destination file under the labeled separator:
   `<!-- appended from .claude/<filename> YYYY-MM-DD -->`
   (Replace `<filename>` with the actual filename, e.g. `project.md`. Replace `YYYY-MM-DD` with the current date.)
   If the destination file does not exist, create it with the appended content.
5. Source file is NEVER deleted or modified.

**5.7.3 — copy strategy (`docs/` and `templates/`):**

For **`docs/`**:
1. List all `.md` files at the **immediate** `docs/` level only (no recursion).
2. Ensure `PROJECT_ROOT/ai-context/features/` directory exists; create it if absent before copying.
3. For each `.md` file:
   - Destination = `PROJECT_ROOT/ai-context/features/<name>.md`.
   - **If destination exists**: record `<name>.md — skipped (destination exists)`. Do NOT overwrite.
   - **If destination does not exist**: copy source to destination; record `<name>.md — copied to ai-context/features/<name>.md`.
4. Source files are NEVER deleted, moved, or modified.

For **`templates/`**:
1. List all files at the **immediate** `templates/` level only (no recursion).
2. Ensure `PROJECT_ROOT/docs/templates/` directory exists; create it if absent before copying.
3. For each file:
   - Destination = `PROJECT_ROOT/docs/templates/<filename>`.
   - **If destination exists**: record `<filename> — skipped (destination exists)`. Do NOT overwrite.
   - **If destination does not exist**: copy source to destination; record `<filename> — copied to docs/templates/<filename>`.
4. Source files are NEVER deleted, moved, or modified.

**5.7.3-cleanup — source file cleanup after copy strategy (`docs/` and `templates/`):**

For each category processed by 5.7.3 (`docs/` and `templates/`):

1. **Guard — strategy eligibility**: copy strategy is eligible for cleanup. Proceed.
2. **Guard — success count**: count files with outcome "copied to ...". If count = 0 (all files were skipped or failed), skip cleanup for this category — do NOT present a prompt.
3. **Build lists**:
   - `WILL_DELETE` = files whose outcome was "copied to ..." (successful migration)
   - `WILL_PRESERVE` = files whose outcome was "skipped (destination exists)", "failed", or any non-success outcome
4. **Present both lists to the user**:
   ```
   Cleanup available for .claude/<category>/:
     Will be deleted (successfully migrated): <filename>, <filename>, ...
     Will be preserved (skipped — destination exists): <filename>, ...
   ```
5. **Prompt**: `Delete source files from .claude/<category>/? (yes/no)`
6. **If user responds `yes`**: delete each file in `WILL_DELETE` from its source path under `PROJECT_CLAUDE_DIR/<category>/`. Record each deletion as `.claude/<category>/<filename> — deleted`. Do NOT delete the parent directory.
7. **If user responds `no`**: record `<category>/ — cleanup declined by user`. Do NOT delete any file.

> **Invariant**: Only files in `WILL_DELETE` (confirmed successful migration) may be deleted. `WILL_PRESERVE` files are NEVER deleted regardless of user input.

**5.7.4 — append strategy (`system/`):**

1. List all files at the **immediate** `system/` level only (no recursion).
2. Apply routing table:
   - `architecture.md` → `PROJECT_ROOT/ai-context/architecture.md`
   - `database.md` → `PROJECT_ROOT/ai-context/stack.md`
   - `api-overview.md` → `PROJECT_ROOT/ai-context/stack.md`
   - All other files → record as `<filename> — no routing rule; skipped`
3. For each file matched by the routing table:
   - **If destination does not exist**: create it with the appended content.
   - **Append block**: append the entire file content to the destination, preceded by:
     `<!-- appended from .claude/system/<filename> YYYY-MM-DD -->`
     (Replace `YYYY-MM-DD` with the current date at apply time.)
   - Record: `<filename> — appended to <destination> (separator added)`.
4. Source files are NEVER deleted, moved, or modified.

**5.7.4-cleanup — source file cleanup after append strategy (`system/`):**

1. **Guard — strategy eligibility**: append strategy is eligible for cleanup. Proceed.
2. **Guard — success count**: count files with outcome "appended to ...". If count = 0, skip cleanup — do NOT present a prompt.
3. **Build lists**:
   - `WILL_DELETE` = files whose outcome was "appended to ... (separator added)"
   - `WILL_PRESERVE` = files whose outcome was "no routing rule; skipped" or any non-success outcome
4. **Present both lists to the user**:
   ```
   Cleanup available for .claude/system/:
     Will be deleted (successfully appended): <filename>, ...
     Will be preserved (no routing rule or skipped): <filename>, ...
   ```
5. **Prompt**: `Delete source files from .claude/system/? (yes/no)`
6. **If user responds `yes`**: delete each file in `WILL_DELETE` from `PROJECT_CLAUDE_DIR/system/<filename>`. Record each deletion as `.claude/system/<filename> — deleted`. Do NOT delete the `system/` directory itself.
7. **If user responds `no`**: record `system/ — cleanup declined by user`. Do NOT delete any file.

> **Invariant**: Only files in `WILL_DELETE` (confirmed successful append) may be deleted. `WILL_PRESERVE` files are NEVER deleted.

**5.7.5 — scaffold strategy (`requirements/`):**

1. List all `.md` files at the **immediate** `requirements/` level only (no recursion).
2. For each `.md` file:
   - Derive `<slug>` = filename stem (filename without the `.md` extension).
   - Construct scaffold path: `PROJECT_ROOT/openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md` (use current date).
   - **If `proposal.md` already exists at that path**: record `<slug> — scaffold skipped (proposal.md already exists)`. Do NOT overwrite.
   - **If `proposal.md` does not exist**: create the directory `openspec/changes/<YYYY-MM-DD>-<slug>/` and write the following minimal scaffold:

     ```markdown
     # Proposal: <slug>

     ## Problem Statement

     <!-- Describe the problem to be solved. -->

     ## Proposed Solution

     <!-- Describe the proposed approach. -->

     ## Success Criteria

     - [ ]
     ```

   - Record: `<slug> — scaffolded to openspec/changes/<date>-<slug>/proposal.md`.
3. Source files are NEVER deleted, moved, or modified.

**5.7.5-cleanup — source file cleanup after scaffold strategy (`requirements/`):**

1. **Guard — strategy eligibility**: scaffold strategy is eligible for cleanup. Proceed.
2. **Guard — success count**: count files with outcome "scaffolded to ...". If count = 0, skip cleanup — do NOT present a prompt.
3. **Build lists**:
   - `WILL_DELETE` = files whose outcome was "scaffolded to ..."
   - `WILL_PRESERVE` = files whose outcome was "scaffold skipped (proposal.md already exists)" or any non-success outcome
4. **Present both lists to the user**:
   ```
   Cleanup available for .claude/requirements/:
     Will be deleted (successfully scaffolded): <filename>.md, ...
     Will be preserved (scaffold skipped — proposal already exists): <filename>.md, ...
   ```
5. **Prompt**: `Delete source files from .claude/requirements/? (yes/no)`
6. **If user responds `yes`**: delete each file in `WILL_DELETE` from `PROJECT_CLAUDE_DIR/requirements/<filename>`. Record each deletion as `.claude/requirements/<filename> — deleted`. Do NOT delete the `requirements/` directory itself.
7. **If user responds `no`**: record `requirements/ — cleanup declined by user`. Do NOT delete any file.

> **Invariant**: Only files in `WILL_DELETE` (confirmed successful scaffold) may be deleted. `WILL_PRESERVE` files are NEVER deleted.

**5.7.6 — user-choice strategy (`sops/`):**

1. List all `.md` files at the **immediate** `sops/` level only (no recursion).
2. Present the list to the user with both destination options:
   - **Option A**: Append file content as a named section (`## <stem>`) to `ai-context/conventions.md` under labeled separator `<!-- appended from .claude/sops/<filename> YYYY-MM-DD -->`; create `ai-context/conventions.md` if absent.
   - **Option B**: Copy file to `docs/sops/<filename>`; create `docs/sops/` directory if absent; skip if destination exists and record.
3. The user selects per file, or can use global shortcuts:
   - `apply option A to all` — applies Option A to all files in `sops/`
   - `apply option B to all` — applies Option B to all files in `sops/`
4. Execute the selection for each file according to the chosen option. Record each operation outcome.
5. Source files are NEVER deleted, moved, or modified.

**5.7.6-cleanup — source file cleanup after user-choice strategy (`sops/`):**

1. **Guard — strategy eligibility**: user-choice strategy is eligible for cleanup. Proceed.
2. **Guard — success count**: count files with outcome "copied to ..." (Option B) or "appended to ..." (Option A). If count = 0, skip cleanup — do NOT present a prompt.
3. **Build lists**:
   - `WILL_DELETE` = files whose outcome was "copied to ..." or "appended to ..."
   - `WILL_PRESERVE` = files whose outcome was "skipped (destination exists)" or any non-success outcome
4. **Present both lists to the user**:
   ```
   Cleanup available for .claude/sops/:
     Will be deleted (successfully processed): <filename>.md, ...
     Will be preserved (skipped — destination exists): <filename>.md, ...
   ```
5. **Prompt**: `Delete source files from .claude/sops/? (yes/no)`
6. **If user responds `yes`**: delete each file in `WILL_DELETE` from `PROJECT_CLAUDE_DIR/sops/<filename>`. Record each deletion as `.claude/sops/<filename> — deleted`. Do NOT delete the `sops/` directory itself.
7. **If user responds `no`**: record `sops/ — cleanup declined by user`. Do NOT delete any file.

> **Invariant**: Only files in `WILL_DELETE` (confirmed successful user-choice migration) may be deleted. `WILL_PRESERVE` files are NEVER deleted.

**5.7.7 — copy strategy (`plans/`):**

1. List all items at the **immediate** `plans/` level only (no recursion).
2. For each item, present it to the user and ask:
   `Is "<plan-name>" an active plan or an archived plan? (active/archived)`
3. Determine destination directory:
   - Active → `PROJECT_ROOT/openspec/changes/<plan-name>/`
   - Archived → `PROJECT_ROOT/openspec/changes/archive/<plan-name>/`
4. **If destination directory already exists**: record `<plan-name> — skipped (destination exists)`. Do NOT overwrite.
5. **If destination directory does not exist**: create the directory; copy the item's contents into it; record `<plan-name> — copied to <destination>`.
6. Source files and directories are NEVER deleted, moved, or modified.

**5.7.7-cleanup — source file cleanup after copy strategy (`plans/`):**

1. **Guard — strategy eligibility**: copy strategy is eligible for cleanup. Proceed.
2. **Guard — success count**: count items with outcome "copied to ...". If count = 0 (all items were skipped), skip cleanup — do NOT present a prompt.
3. **Build lists**:
   - `WILL_DELETE` = items whose outcome was "copied to ..." (successful migration)
   - `WILL_PRESERVE` = items whose outcome was "skipped (destination exists)" or any non-success outcome
4. **Present both lists to the user**:
   ```
   Cleanup available for .claude/plans/:
     Will be deleted (successfully migrated): <plan-name>, <plan-name>, ...
     Will be preserved (skipped — destination exists): <plan-name>, ...
   ```
5. **Prompt**: `Delete source files from .claude/plans/? (yes/no)`
6. **If user responds `yes`**: delete each item in `WILL_DELETE` from `PROJECT_CLAUDE_DIR/plans/<plan-name>`. Record each deletion as `.claude/plans/<plan-name> — deleted`. Do NOT delete the parent `plans/` directory.
7. **If user responds `no`**: record `plans/ — cleanup declined by user`. Do NOT delete any file.

> **Invariant**: Only items in `WILL_DELETE` (confirmed successful migration) may be deleted. `WILL_PRESERVE` items are NEVER deleted regardless of user input.

---

### Step 6 — Write report

Write `claude-organizer-report.md` to `PROJECT_CLAUDE_DIR`. Overwrite any previous file.

Use this format:

```markdown
# Claude Organizer Report

Run date: <YYYY-MM-DD>
Project root: <PROJECT_ROOT>
Target: <PROJECT_CLAUDE_DIR>
Summary: <N> item(s) created, <N> documentation file(s) copied, <N> legacy migration(s) applied, <N> unexpected item(s) flagged, <N> already correct

---

## Plan Executed

### Created

<!-- List items created, or state "Nothing to create — no required items were missing." -->
- `skills/` — empty directory created
- `CLAUDE.md` — stub file created with 5 section headings (Tech Stack, Architecture, Unbreakable Rules, Plan Mode Rules, Skills Registry)

> CLAUDE.md stub note: the file contains the 5 required section headings only.
> Populate this file with project-specific SDD configuration.
> Run /project-setup for full initialization.

### Documentation copied to ai-context/

<!-- Omit this subsection entirely when DOCUMENTATION_CANDIDATES was empty for the run. -->
<!-- List each candidate with its outcome: -->
- `stack.md` — copied to ai-context/stack.md
- `architecture.md` — skipped (destination exists — review manually)
- `notes.md` — excluded by user

### Legacy migrations

<!-- Omit this subsection entirely when LEGACY_MIGRATIONS was empty for the run. -->
<!-- List each legacy category processed with per-file outcome lines. -->
<!-- Valid outcome labels: applied, skipped, advisory, non-qualifying, user-skipped -->

**commands/** (strategy: delegate — advisory only):
- `deploy.md` — qualifying workflow detected. Suggested skill name: deploy. To scaffold: /skill-create deploy
- `misc.md` — non-qualifying (no structured workflow detected). Recommend manual archival.

**docs/** (strategy: copy):
- `auth.md` — copied to ai-context/features/auth.md
- `payments.md` — skipped (destination exists)

**system/** (strategy: append):
- `architecture.md` — appended to ai-context/architecture.md (separator added)
- `database.md` — appended to ai-context/stack.md (separator added)

**requirements/** (strategy: scaffold):
- `auth-requirements` — scaffolded to openspec/changes/2026-03-04-auth-requirements/proposal.md

**sops/** (strategy: user-choice):
- `deployment.md` — copied to docs/sops/deployment.md (Option B)

**templates/** (strategy: copy):
- `prd-template.md` — copied to docs/templates/prd-template.md

**project.md** (strategy: section-distribute):
- `## Tech Stack` section — appended to ai-context/stack.md
- `## Architecture` section — appended to ai-context/architecture.md

<!-- Source-preservation footer — CONDITIONAL:
     - When NO files were deleted: display the preservation note below.
     - When files WERE deleted: omit the preservation note; the "Deleted from .claude/" subsection below serves as the deletion summary. -->
> All source files in legacy categories were preserved — no files were deleted or moved

### Deleted from .claude/

<!-- Omit this subsection entirely when no cleanup prompts were presented during the run. -->
<!-- List each deleted file and each declined cleanup category. -->

- `.claude/docs/auth.md` — deleted
- `templates/ — cleanup declined by user`

### Unexpected items (not modified)

<!-- List unexpected items, or state "None." -->
- `commands/` — This item is not part of the canonical SDD .claude/ structure.
  Review manually — it was NOT deleted or moved.

### Already correct

<!-- List items that were already present and expected, or state "None." -->
- `hooks/`
- `ai-context/`
- `openspec/`

---

## Recommended Next Steps

<!-- Conditional content — include only the applicable items: -->

1. Review the unexpected item(s) listed above — if intentional, document them in
   .claude/CLAUDE.md; if not, remove them manually.
2. Populate the created stub files with project-specific content.
3. Review skipped documentation files — a file was skipped because its destination in
   ai-context/ already exists. Compare source and destination manually and merge if needed.
4. Project .claude/ structure is now aligned with the canonical SDD layout.

<!-- Legacy migration conditional guidance — include only when the condition was true for this run: -->
<!-- If commands/ delegate advisories were produced: -->
5. Review the commands/ advisory list above — invoke /skill-create <name> for each qualifying
   file to scaffold a new skill.
<!-- If section-distribute applied to project.md or readme.md: -->
6. Review the distributed sections in the destination ai-context/ files — verify content is
   correctly placed.
<!-- If append applied to system/: -->
7. Review the appended content in the ai-context/ destination file(s) — merge or deduplicate
   manually if the appended section overlaps with existing content.
<!-- If scaffold produced proposals from requirements/: -->
8. Populate the scaffold proposals in openspec/changes/ before running /sdd-apply.
<!-- If sops/ was processed: -->
9. Verify the conventions section or docs/sops/ directory was correctly populated.

<!-- For a no-op run where nothing was missing: -->
<!-- No action required — .claude/ is already canonical. -->

---

> This file is a runtime artifact. Add `.claude/claude-organizer-report.md` to `.gitignore`
> to prevent accidental commits.
```

After writing the report, emit:
```
Report written to: <PROJECT_CLAUDE_DIR>/claude-organizer-report.md
```

Use the expanded absolute path (no tilde or relative segments).

---

## Rules

1. **Target is `PROJECT_ROOT/.claude/` only — NEVER `~/.claude/`.**
   This skill MUST NOT be invoked against the user-level runtime directory. If the resolved
   `PROJECT_CLAUDE_DIR` matches `~/.claude/`, the skill MUST exit immediately without changes.

2. **Apply step is strictly additive.**
   Only `mkdir` for missing directories and write stubs for missing files. No delete, move,
   rename, or overwrite operations are permitted under any circumstances. Existing files and
   directories are never touched, regardless of content.

3. **User confirmation gate MUST NOT be skipped.**
   The plan MUST be presented in full before any file write occurs. The skill MUST pause and
   wait for explicit user confirmation. If the user does not confirm affirmatively, the skill
   exits without writing any files (including the report).

4. **Canonical expected item set MUST remain consistent with `claude-folder-audit` Check P8.**
   The inline expected set defined in Step 3 is the single source of truth for this skill.
   Whenever `claude-folder-audit` Check P8 expected items are updated, this skill's inline
   set MUST be updated in sync to prevent false-positive MEDIUM findings.

5. **Source files MUST NOT be deleted without BOTH conditions being true:**
   **(a)** The file was successfully migrated (copied, appended, scaffolded, or user-choice applied) AND **(b)** the user explicitly confirmed the deletion prompt for that category.
   The `delegate` strategy (`commands/`) and the `section-distribute` strategy (`project.md`, `readme.md`) are permanently exempt from cleanup prompts — their source files are unconditionally preserved.
   Any file whose migration outcome was "skipped", "failed", or "excluded" MUST NOT be offered for deletion regardless of user input.
