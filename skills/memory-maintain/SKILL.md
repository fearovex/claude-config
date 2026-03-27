---
name: memory-maintain
description: >
  Performs periodic housekeeping on ai-context/: archives old changelog entries,
  separates resolved known-issues, generates an index, and detects CLAUDE.md gaps.
  Trigger: /memory-maintain, maintain memory, memory housekeeping, clean ai-context.
format: procedural
---

# memory-maintain

> Periodic housekeeping for the ai-context/ memory layer: archive old changelog entries, separate resolved known-issues, regenerate the index, and detect CLAUDE.md configuration gaps.

**Triggers**: `/memory-maintain`, maintain memory, memory housekeeping, clean ai-context, ai-context cleanup

---

## Purpose

The `ai-context/` memory layer has no automatic cleanup mechanism. Over time, `changelog-ai.md` grows unbounded (expensive context window cost), `known-issues.md` accumulates resolved items without formal separation, and there is no single-page index explaining what files exist. `memory-maintain` handles this periodic backlog cleanup. It is complementary to `memory-init` (generates from scratch) and `memory-update` (records session changes) — neither does backlog cleanup.

**Run cadence**: whenever `changelog-ai.md` feels long, when resolved issues clutter `known-issues.md`, or at the start of a new project phase.

---

## Process

### Step 0 — Load project context

This step is **non-blocking**: any failure produces at most an INFO-level note; missing files are skipped silently.

1. Read `ai-context/stack.md` — tech stack, key tools
2. Read `ai-context/architecture.md` — architectural decisions
3. Read `ai-context/conventions.md` — naming patterns
4. Read project `CLAUDE.md` — governance and unbreakable rules; extract governance log line:
   `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`

For each file: if absent, log `INFO: [filename] not found — proceeding without it.`

---

### Step 1 — Changelog archiving scan

**Entry boundary heuristic**: an entry is a contiguous block that begins with a line matching `ENTRY_BOUNDARY_REGEX = /^##\s+\[/` (i.e., a heading starting with `## [`). Each such line starts a new entry; the entry spans until the next matching line or end of file. The file header (H1 heading, blockquote description, first `---` separator before the first entry) is preserved and never archived.

1. If `ai-context/changelog-ai.md` is absent → skip silently. No planned action.
2. Read the file. Identify all `[auto-updated]` ... `[/auto-updated]` blocks; treat each as an atomic unit — entries inside a marker block MUST NOT be counted or moved individually.
3. Count entries outside `[auto-updated]` blocks using `ENTRY_BOUNDARY_REGEX`.
4. If total entry count ≤ 30 → no planned action for this step.
5. If total entry count > 30:
   - Entries 1–30 (most recent, counting from the top) stay in `changelog-ai.md`
   - Entries 31+ are marked for archival to `ai-context/changelog-ai-archive.md`
   - Note whether `changelog-ai-archive.md` exists (append) or does not (new file)
   - **If any `[auto-updated]` block falls within the entries to be archived**: abort this step and flag it in the dry-run report as: `WARN: [auto-updated] block detected in entries to be archived — changelog archiving step cannot execute safely. Review manually.`

---

### Step 2 — Known-issues separation scan

**Resolution detection heuristic**: apply `RESOLVED_MARKER_REGEX = /\(FIXED\)|\(RESOLVED\)/i` against H2 headings (`## ...`) in `known-issues.md`. A section starts at the matched H2 heading and ends just before the next H2 heading (or end of file).

1. If `ai-context/known-issues.md` is absent → skip silently. No planned action.
2. Read the file. Identify all `[auto-updated]` ... `[/auto-updated]` blocks; treat each as an atomic unit.
3. Scan H2 headings for `RESOLVED_MARKER_REGEX` matches (case-insensitive).
4. If no matches → no planned action for this step.
5. If matches found:
   - Each matched section (H2 heading + body until next H2 or EOF) is marked for move to `ai-context/known-issues-archive.md`
   - Note whether `known-issues-archive.md` exists (append) or does not (new file)
   - **If any matched section falls inside an `[auto-updated]` block**: abort this step and flag it in the dry-run report as: `WARN: Resolved item found inside [auto-updated] block — known-issues separation step cannot execute safely. Review manually.`

---

### Step 3 — Index generation scan

1. Walk the `ai-context/` directory. Collect all `.md` files.
2. Exclude `index.md` itself and any file whose name begins with `_`.
3. For each file:
   - Read the file content
   - Extract the first H1 heading (`# ...`) as "Purpose" — if absent, use the filename without extension
   - Extract the `Last updated:` date — scan for `> Last updated: YYYY-MM-DD` or `Last updated: YYYY-MM-DD` pattern; if absent, record "Unknown"
4. Check whether `features/` is a subdirectory of `ai-context/` — if yes, add a single row for `features/` with purpose "Bounded-context domain knowledge files" and last updated "(directory)"
5. Index generation always produces a planned action (idempotent regeneration on every run)

---

### Step 4 — CLAUDE.md gap detection

1. If project-root `CLAUDE.md` is absent → skip silently. No advisory.
2. Read the project-root `CLAUDE.md` (same directory as where the skill is invoked).
3. Check for the presence of an `## Active Constraints` section (case-sensitive match against the literal string `## Active Constraints`).
4. If absent → note INFO advisory: `No Active Constraints section found in CLAUDE.md — consider adding one to document active behavioral overrides`
5. If present → no advisory.
6. **MUST NOT write to CLAUDE.md under any circumstances.**

---

### Step 5 — Dry-run report and confirmation gate

Present the dry-run report using the following format. **No files are written at this step.**

```
=== memory-maintain — Dry Run ===

Changelog archiving:
  - Total entries found: [N]
  - Entries to keep (last 30): [N or "all — no archiving needed"]
  - Entries to archive: [M or "none"]
  - Archive target: ai-context/changelog-ai-archive.md [new file | append to existing | N/A]
  [WARN: ... if auto-updated block conflict detected]

Known-issues separation:
  - Total items found: [N]
  - Resolved items detected: [M] — [list of H2 headings, or "none"]
  - Items remaining (open): [N-M]
  - Archive target: ai-context/known-issues-archive.md [new file | append to existing | N/A]
  [WARN: ... if auto-updated block conflict detected]

Index generation:
  - Files to index: [N]
  - Target: ai-context/index.md [new file | overwrite existing]

CLAUDE.md gap detection:
  - "Active Constraints" section: [present | absent — INFO: consider adding]

Confirm? Reply yes to apply or no to cancel.
```

Wait for user response.

- If user replies `yes` → proceed to Step 6
- If user replies `no`, `cancel`, or anything other than an affirmative → exit without writing any file; output: `No changes were made.`

---

### Step 6 — Execute writes

Execute only the write steps that had a planned action in the dry-run. Steps with no planned action or with a WARN flag are skipped.

#### 6a — Changelog archiving (only if entries > 30 and no WARN flag)

1. Read `ai-context/changelog-ai.md`
2. Parse the file: separate the header section (everything before the first `ENTRY_BOUNDARY_REGEX` match), the entry blocks (one per `## [` match), and any `[auto-updated]` blocks (treated as atomic units)
3. Entries 1–30 (most recent) remain in `changelog-ai.md` along with the header and all `[auto-updated]` blocks
4. Entries 31+ are moved to `changelog-ai-archive.md`:
   - If `ai-context/changelog-ai-archive.md` exists: APPEND the overflow entries at the end of the file
   - If absent: create it with the overflow entries
5. Write the truncated content back to `changelog-ai.md`
6. Verify `[auto-updated]` markers are intact in the written file; if not, abort and report error

#### 6b — Known-issues separation (only if resolved items found and no WARN flag)

1. Read `ai-context/known-issues.md`
2. For each matched resolved section:
   - Prepare the archive entry: prepend `> Archived: YYYY-MM-DD` (today's date) above the H2 heading
   - Remove the section from `known-issues.md`
3. If `ai-context/known-issues-archive.md` exists: APPEND each archived section under `## Resolved Issues` at the end of the file; if the file has no `## Resolved Issues` heading, add one before appending
4. If absent: create `ai-context/known-issues-archive.md` with a `## Resolved Issues` section containing the archived items
5. Write the modified content back to `known-issues.md`
6. Verify `[auto-updated]` markers are intact in the written file; if not, abort and report error

#### 6c — Index generation (always executed after confirmation)

Write `ai-context/index.md` with the following format:

```markdown
# ai-context/ Index

> Auto-generated by /memory-maintain on YYYY-MM-DD. Regenerated on each run.

| File | Purpose | Last Updated |
| --- | --- | --- |
| `stack.md` | [first H1 or filename] | [Last updated date or Unknown] |
| `architecture.md` | [first H1 or filename] | [Last updated date or Unknown] |
| ... | ... | ... |
| `features/` | Bounded-context domain knowledge files | (directory) |
```

Overwrite `ai-context/index.md` if it exists; create it if absent.

---

### Step 7 — Maintenance report

After all writes complete, present a summary:

```
=== memory-maintain — Maintenance Report ===

Steps executed:
  Changelog archiving:  [Archived N entries to changelog-ai-archive.md | Skipped — ≤30 entries | Skipped — WARN: reason]
  Known-issues separation: [Moved N resolved items to known-issues-archive.md | Skipped — no resolved items | Skipped — WARN: reason]
  Index generation:     [Generated ai-context/index.md (N files indexed) | No-op (index regenerated but content unchanged)]

Advisory:
  CLAUDE.md gap:  [No Active Constraints section found — consider adding one | Active Constraints section present]

Files written: [N]
  [list of written files]
```

---

## Rules

- **Dry-run first**: MUST NOT write any file before presenting the dry-run report and receiving explicit `yes` confirmation
- **Confirmation required**: user MUST reply `yes` to proceed; any other response exits without writing
- **auto-updated markers**: MUST NOT remove, reorder, or modify content between `[auto-updated]` ... `[/auto-updated]` markers; if a write step would corrupt a marker block, that step MUST be aborted and flagged
- **Archive files are append-only**: if an archive file already exists, MUST append to it — never overwrite
- **No CLAUDE.md writes**: MUST NOT write to CLAUDE.md under any circumstances (gap detection is advisory only)
- **Skip silently**: if `changelog-ai.md` or `known-issues.md` is absent, skip the corresponding step with no error
- **Threshold check**: if changelog has ≤30 entries, no archiving write is performed even after confirmation
- **Archival date**: each moved known-issue item MUST include the archival date inline
- **Scope**: operates on project-local `ai-context/` (wherever the skill is invoked); does not touch global `~/.claude/`
- **Index is always regenerated**: `ai-context/index.md` is written on every confirmed run (idempotent)
- **Count-based threshold**: the 30-entry threshold is count-based, not date-based
