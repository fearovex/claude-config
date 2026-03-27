# Technical Design: 2026-03-26-ai-context-maintenance-skill

Date: 2026-03-26
Proposal: openspec/changes/2026-03-26-ai-context-maintenance-skill/proposal.md

## General Approach

Create a standalone procedural skill `memory-maintain` in `skills/memory-maintain/SKILL.md` that performs periodic housekeeping on the `ai-context/` memory layer. The skill follows a dry-run-first interaction pattern (compute planned changes, present to user, write only after confirmation) and executes 5 sequential steps: changelog archiving, known-issues separation, index generation, CLAUDE.md gap detection, and maintenance report. The skill is complementary to `memory-init` and `memory-update` — it handles backlog cleanup that neither addresses. Registration in CLAUDE.md (Skills Registry + Commands) and a delta spec complete the change.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| --- | --- | --- | --- |
| Skill placement | New `skills/memory-maintain/` directory with `SKILL.md` | Extend `memory-update` with housekeeping step; extend `project-audit` with memory dimension | Separation of concerns: `memory-update` records session changes, `memory-maintain` does backlog cleanup. Mixing them increases regression risk and makes independent invocation impossible. Mirrors `sdd-spec-gc` pattern for periodic cleanup. |
| Interaction pattern | Dry-run-first with single confirmation gate | Per-step confirmation; fully automatic (no confirmation) | Single gate after dry-run preview balances safety with usability. Per-step would be tedious for 5 steps. Fully automatic risks unwanted writes. Pattern established by `sdd-spec-gc` and `project-claude-organizer`. |
| Changelog entry boundary | H2/H3 heading-based: `## [` or `### [` at line start marks a new entry | Date-based (keep last 90 days); blank-line-separated blocks; `---` separator-based | Actual `changelog-ai.md` uses `## [YYYY-MM-DD]` headings consistently. Heading detection is robust and matches observed format. Date-based parsing is fragile. Separator-based misses entries without `---`. |
| Archive threshold | Keep last 30 entries (count-based) | Keep last 50; keep last 100; date-based (90 days) | 30 entries covers approximately 4-6 weeks of active development. Small enough to keep context window cost low, large enough to provide useful recent history. Count-based is simpler than date parsing. |
| Archive file convention | `changelog-ai-archive.md` and `known-issues-archive.md` in `ai-context/` | Separate `archive/` subdirectory; date-stamped archive files | Flat files in `ai-context/` are simplest. Archive files are rarely loaded — they exist for historical reference only. No need for date-stamped rotation until archives themselves grow very large (deferred concern). |
| Known-issues detection | Scan for `(FIXED)` or `(RESOLVED)` markers in H2 headings or inline text | Status field in YAML frontmatter; checkbox `[x]` convention | Actual `known-issues.md` already uses `(FIXED)` inline markers (e.g., "CRLF line endings break bash scripts (FIXED)"). Detecting existing convention is zero-migration. |
| Index generation | Always regenerate `ai-context/index.md` from scratch (idempotent) | Incremental update; generate once and maintain | Idempotent regeneration eliminates stale-index risk. The index is small (one row per file) — regeneration cost is negligible. |
| CLAUDE.md gap detection | Project-local CLAUDE.md only; INFO-level advisory | Global + project CLAUDE.md; WARNING level | Project-local is the actionable scope — the global CLAUDE.md is maintained directly by the user. INFO level avoids alarm for an optional convention. |
| Spec domain | Delta spec appended to existing `memory-management` domain | New `memory-maintenance` domain | The maintenance skill is part of the memory management family. Adding to the existing domain keeps related requirements together and avoids domain proliferation. |

## Data Flow

```
User invokes /memory-maintain
        |
        v
Step 0: Load project context (ai-context/, CLAUDE.md)
        |
        v
Step 1: Scan changelog-ai.md
        |-- Count entries (heading-based boundary)
        |-- If > 30: mark entries 31+ for archival
        v
Step 2: Scan known-issues.md
        |-- Find items with (FIXED) or (RESOLVED) markers
        |-- Mark them for move to archive
        v
Step 3: Walk ai-context/ directory
        |-- Read each .md file: first heading + Last updated date
        |-- Build index table
        v
Step 4: Read project CLAUDE.md
        |-- Check for "Active Constraints" section
        |-- If absent: note INFO advisory
        v
Step 5: Dry-run report
        |-- Present all planned changes
        |-- Wait for user confirmation
        |
   [User confirms]
        |
        v
Step 6: Execute writes
        |-- Truncate changelog-ai.md to 30 entries
        |-- Append older entries to changelog-ai-archive.md
        |-- Move FIXED/RESOLVED items to known-issues-archive.md
        |-- Write/overwrite ai-context/index.md
        v
Step 7: Maintenance report (summary of actions taken)
```

## File Change Matrix

| File | Action | What is added/modified |
| --- | --- | --- |
| `skills/memory-maintain/SKILL.md` | Create | New procedural skill: 7 steps, dry-run-first pattern, 5 maintenance operations |
| `CLAUDE.md` (project root) | Modify | Add `memory-maintain` to Skills Registry under Meta-tools; add `/memory-maintain` to Commands section |
| `openspec/specs/memory-management/spec.md` | Modify | Append delta requirements for changelog archiving, known-issues separation, index generation, CLAUDE.md gap detection, dry-run interaction |
| `openspec/specs/index.yaml` | Modify | Add `memory-maintenance` keywords to existing `memory-management` domain entry (or add as alias keywords: `maintain`, `maintenance`, `archive`, `housekeeping`) |

**Files written by the skill at runtime (not part of this change's apply phase):**

| File | Runtime Action | Description |
| --- | --- | --- |
| `ai-context/changelog-ai.md` | Truncated | Retains only the last 30 entries |
| `ai-context/changelog-ai-archive.md` | Created/Appended | Receives entries beyond the 30th |
| `ai-context/known-issues.md` | Modified | FIXED/RESOLVED items removed |
| `ai-context/known-issues-archive.md` | Created/Appended | Receives resolved items with archival date |
| `ai-context/index.md` | Created/Overwritten | Table of contents for ai-context/ files |

## Interfaces and Contracts

### SKILL.md Frontmatter

```yaml
---
name: memory-maintain
description: >
  Performs periodic housekeeping on ai-context/: archives old changelog entries,
  separates resolved known-issues, generates an index, and detects CLAUDE.md gaps.
  Trigger: /memory-maintain, maintain memory, memory housekeeping, clean ai-context.
format: procedural
---
```

### Entry Boundary Heuristic (changelog-ai.md)

```
ENTRY_BOUNDARY_REGEX = /^##\s+\[/
```

An entry is a contiguous block of text starting at an `ENTRY_BOUNDARY_REGEX` match and ending just before the next match (or end of file). The file header (H1 heading, blockquote description, first `---` separator) is preserved and never archived.

### Known-Issues Resolution Detection

```
RESOLVED_MARKER_REGEX = /\(FIXED\)|\(RESOLVED\)/i
```

Applied to H2 headings (`## ...`) in `known-issues.md`. A section starting with a matched H2 heading and ending at the next H2 heading (or end of file) is considered a resolved item.

### Index Table Format (ai-context/index.md)

```markdown
# ai-context/ Index

> Auto-generated by /memory-maintain on YYYY-MM-DD. Regenerated on each run.

| File | Purpose | Last Updated |
| --- | --- | --- |
| `stack.md` | Tech stack, versions, key tools | 2026-03-06 |
| `architecture.md` | Architectural decisions and rationale | 2026-03-08 |
| ... | ... | ... |
| `features/` | Bounded-context domain knowledge files | (directory) |
```

### Dry-Run Report Format

```
=== memory-maintain — Dry Run ===

Changelog archiving:
  - Total entries found: [N]
  - Entries to keep (last 30): [N or "all — no archiving needed"]
  - Entries to archive: [M]
  - Archive target: ai-context/changelog-ai-archive.md [new file | append to existing]

Known-issues separation:
  - Total items found: [N]
  - Resolved items detected: [M] — [list of H2 headings]
  - Items remaining (open): [N-M]
  - Archive target: ai-context/known-issues-archive.md [new file | append to existing]

Index generation:
  - Files to index: [N]
  - Target: ai-context/index.md [new file | overwrite existing]

CLAUDE.md gap detection:
  - "Active Constraints" section: [present | absent — INFO: consider adding]

Confirm? Reply **yes** to apply or **no** to cancel.
```

### Sub-Agent Output Contract

```json
{
  "status": "ok|warning|blocked|failed",
  "summary": "Maintenance complete: [N] changelog entries archived, [M] resolved issues separated, index.md [generated|updated], [advisory notes].",
  "artifacts": ["skills/memory-maintain/SKILL.md"],
  "next_recommended": ["Run /memory-maintain on the project to verify behavior"],
  "risks": []
}
```

## Testing Strategy

| Layer | What to test | Tool |
| --- | --- | --- |
| Manual validation | Invoke `/memory-maintain` on agent-config project; verify dry-run output shows correct entry counts | Manual — Claude Code session |
| Manual validation | Confirm writes after approval: changelog-ai.md truncated, archive created, known-issues separated | Manual — file inspection |
| Manual validation | Verify `ai-context/index.md` lists all files with correct dates | Manual — file inspection |
| Manual validation | Re-run `/memory-maintain` immediately after — verify idempotent (no further archiving if already at 30 entries) | Manual — Claude Code session |
| Structural audit | Run `/project-audit` after apply — verify no D4b violations, skill registered in CLAUDE.md | `/project-audit` |

## Migration Plan

No data migration required. The skill creates new files at runtime; no existing files are structurally changed by the apply phase (only CLAUDE.md registry entries and spec additions).

## Open Questions

None. All open questions from the exploration were resolved in the proposal:
- Operates on project-local `ai-context/` (wherever invoked)
- Count-based threshold (30 entries)
- "Active Constraints" is project-local CLAUDE.md only, INFO level
- `index.md` is always regenerated (idempotent)
- Registered in both global catalog and project CLAUDE.md
