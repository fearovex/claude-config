# Task Plan: 2026-03-26-ai-context-maintenance-skill

Date: 2026-03-26
Design: openspec/changes/2026-03-26-ai-context-maintenance-skill/design.md

## Progress: 10/10 tasks

---

## Phase 1: Foundation — Skill Creation

- [x] 1.1 Create `skills/memory-maintain/SKILL.md` with YAML frontmatter (`name: memory-maintain`, `description`, `format: procedural`), `**Triggers**` line, `## Process` section (7 steps per design data flow), and `## Rules` section
  Files: `skills/memory-maintain/SKILL.md` (CREATE)
  Acceptance: File exists; YAML frontmatter declares `format: procedural`; all required sections present; triggers include `/memory-maintain`, `maintain memory`, `memory housekeeping`, `clean ai-context`

---
Phase 2 MUST NOT begin until Phase 1 is complete.
---

## Phase 2: Skill Process Steps

- [x] 2.1 Implement Step 0 (Load project context) in `skills/memory-maintain/SKILL.md` — read `ai-context/stack.md`, `architecture.md`, `conventions.md`, project `CLAUDE.md`; emit governance log line; skip silently if files absent
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Step 0 matches the non-blocking contract from the spec; governance log line format matches sdd-tasks Step 0 pattern

- [x] 2.2 Implement Step 1 (Changelog archiving scan) in `skills/memory-maintain/SKILL.md` — count entries in `ai-context/changelog-ai.md` using `ENTRY_BOUNDARY_REGEX = /^##\s+\[/`; mark entries 31+ for archival; skip silently if file absent or has ≤30 entries
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Entry boundary heuristic matches design spec exactly (`## [` heading-based); ≤30 entries scenario produces no planned action; absent file is skipped silently

- [x] 2.3 Implement Step 2 (Known-issues separation scan) in `skills/memory-maintain/SKILL.md` — scan `ai-context/known-issues.md` for items with `(FIXED)` or `(RESOLVED)` markers (case-insensitive) in H2 headings; mark matched sections for move; skip silently if file absent or no matches
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Uses `RESOLVED_MARKER_REGEX = /\(FIXED\)|\(RESOLVED\)/i` against H2 headings; no matches scenario produces no planned action

- [x] 2.4 Implement Step 3 (Index generation scan) in `skills/memory-maintain/SKILL.md` — walk `ai-context/` directory; read each `.md` file's first H1 heading and `Last updated:` date; exclude `index.md` and files beginning with `_`; build index table data
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Index table covers all `.md` files in `ai-context/` (excluding `index.md`); shows "Unknown" for files without `Last updated:` field; always marked as planned action (idempotent regeneration)

- [x] 2.5 Implement Step 4 (CLAUDE.md gap detection) in `skills/memory-maintain/SKILL.md` — read project-root `CLAUDE.md`; check for `## Active Constraints` section (case-sensitive); emit INFO advisory if absent; skip silently if CLAUDE.md not found
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Only project-local CLAUDE.md is checked; no write to CLAUDE.md under any circumstance; INFO advisory text matches spec exactly: "No Active Constraints section found in CLAUDE.md — consider adding one to document active behavioral overrides"

- [x] 2.6 Implement Step 5 (Dry-run report + confirmation gate) in `skills/memory-maintain/SKILL.md` — present dry-run report using the format from design.md (changelog archiving, known-issues separation, index generation, CLAUDE.md gap detection sections); ask for explicit confirmation; exit without writing if user declines
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Dry-run report format matches design spec; confirmation gate is explicit (user must reply "yes" to proceed); no files are written before confirmation; decline exits cleanly with "no changes were made" message

- [x] 2.7 Implement Step 6 (Execute writes) in `skills/memory-maintain/SKILL.md` — after confirmation: (a) truncate `changelog-ai.md` to 30 entries appending overflow to `changelog-ai-archive.md`; (b) remove FIXED/RESOLVED items from `known-issues.md` appending to `known-issues-archive.md` with archival date; (c) write/overwrite `ai-context/index.md` using index table format from design.md; respect `[auto-updated]` marker boundaries in all files
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Each write step only executes when its planned action was listed in the dry-run; archive files are appended (not overwritten) if they already exist; `[auto-updated]` markers are never removed or repositioned; archival date is included with each moved known-issue item

- [x] 2.8 Implement Step 7 (Maintenance report) in `skills/memory-maintain/SKILL.md` — produce post-write summary listing each step (executed vs. skipped with reason), count of files written, and any INFO advisories from Step 4
  Files: `skills/memory-maintain/SKILL.md` (MODIFY)
  Acceptance: Report distinguishes executed vs. skipped steps; total files-written count displayed; Active Constraints advisory included when applicable

---

## Phase 3: Registration

- [x] 3.1 Modify `CLAUDE.md` — add `~/.claude/skills/memory-maintain/SKILL.md` entry under `### Meta-tools` in the Skills Registry section (after the `memory-update` entry); add `/memory-maintain — perform ai-context/ housekeeping (archive old changelog entries, separate resolved known-issues, regenerate index)` to the Commands section (append to the meta-tools command line)
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: `memory-maintain` appears under `### Meta-tools` in the Skills Registry; `/memory-maintain` appears in the Commands section with a brief description; no other content in CLAUDE.md is altered

- [x] 3.2 Modify `openspec/specs/index.yaml` — add `maintain`, `maintenance`, `archive`, `housekeeping` keywords to the existing `memory-management` domain entry's `keywords` array
  Files: `openspec/specs/index.yaml` (MODIFY)
  Acceptance: The `memory-management` domain entry contains the four new keywords; no other domain entries are modified; YAML is valid

---

## Implementation Notes

- The skill must follow the dry-run-first pattern established by `sdd-spec-gc` and `project-claude-organizer`. Review those skills if the interaction pattern is unclear.
- Entry boundary detection uses `ENTRY_BOUNDARY_REGEX = /^##\s+\[/` — this matches the actual `changelog-ai.md` format where each entry begins with `## [YYYY-MM-DD]`. The file header (H1 heading, blockquote, first `---`) is preserved and never archived.
- Known-issues detection applies `RESOLVED_MARKER_REGEX = /\(FIXED\)|\(RESOLVED\)/i` against H2 headings. A section spans from the matched H2 to the next H2 (or end of file).
- `[auto-updated]` ... `[/auto-updated]` blocks MUST be treated as atomic units — no content inside these blocks is moved or repositioned. If a write step would corrupt a marker block, that step MUST be aborted and flagged.
- The index format uses a Markdown table with columns: File, Purpose, Last Updated. The `features/` subdirectory appears as a single row with "(directory)" in the Last Updated column.
- CLAUDE.md registration: the Skills Registry entry goes after `memory-update`; the Commands addition goes on the first command line (meta-tools), after `/codebase-teach`.
- After sdd-apply completes, run `bash install.sh` to deploy the new skill to `~/.claude/`.

## Blockers

None.
