# Technical Design: project-claude-organizer-memory-layer

Date: 2026-03-04
Proposal: openspec/changes/project-claude-organizer-memory-layer/proposal.md

## General Approach

Extend `skills/project-claude-organizer/SKILL.md` with a fourth classification bucket (`DOCUMENTATION_CANDIDATES`) inserted into the existing 6-step procedural flow. The extension adds logic to Steps 3, 4, 5, and 6 only — the guard, enumeration, and path-resolution steps (Steps 1–2) are unchanged. The heuristic is purely filename-based (primary signal) with an optional heading-presence fallback (secondary signal). All file operations remain strictly additive (copy only, source preserved). No new files are created beyond the updated SKILL.md.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Heuristic strategy | Filename stem matching (primary) + heading presence (secondary) | NLP content analysis, YAML frontmatter detection | Filename matching is deterministic and zero-dependency; heading presence requires only a grep-style scan of the file content. Both signals are already within Claude's reading capability during skill execution. NLP analysis is out of scope and would introduce unpredictable classification. |
| Copy vs. move | Copy only (source preserved in `.claude/`) | Move (source deleted), symlink | The proposal explicitly prohibits moves. Preserving the source makes the operation fully reversible without any rollback procedure. Symlinks introduce cross-platform complexity on Windows. |
| Idempotency convention | Skip on destination-exists, record as `skipped (destination exists)` | Overwrite, diff-and-merge | Overwriting risks destroying user content in `ai-context/`. Merging is out of scope. Skip-and-record is safe and transparent, consistent with the existing `CLAUDE.md` stub idempotency pattern already in Step 5.3. |
| Classification bucket placement | Fourth category, inserted between `UNEXPECTED` promotion step and the dry-run display | New standalone step before Step 3, post-apply cleanup | Inserting within Step 3 (classification) and Step 4 (display) is the minimal-impact pattern — it follows the existing three-bucket structure and avoids restructuring the step numbering. |
| Canonical filename list scope | 8 known ai-context filenames: `stack`, `architecture`, `conventions`, `known-issues`, `changelog-ai`, `onboarding`, `quick-reference`, `scenarios` | Auto-discovery from `ai-context/`, open-ended list | The 8 filenames map directly to the documented ai-context/ file set in `architecture.md`. Using a closed list prevents false promotions and is stable against future `ai-context/` growth (new files would require an explicit list update). |
| Secondary heading signal | 6 heading patterns (`## Tech Stack`, `## Architecture`, `## Known Issues`, `## Conventions`, `## Changelog`, `## Domain Overview`) | No secondary signal, arbitrary heading patterns | These 6 headings directly correspond to the memory-layer file purposes. The secondary signal covers non-standard filenames that contain recognizable memory-layer content. The list is closed to prevent over-promotion. |
| Step numbering — copy step | Step 5.x inserted between existing 5.3 and 5.4 | Renumber all existing steps, add as Step 6 | Additive insertion as `5.x` (concrete: `5.4`, shifting existing 5.4/5.5 to 5.5/5.6) preserves the existing step numbering semantics and minimizes diff noise. The pattern is consistent with how Step 5.3 was added in V1. |
| Report section placement | New section `### Documentation copied to ai-context/` inside `## Plan Executed`, after `### Created` | Separate `## Documentation` top-level section | Keeping it inside `## Plan Executed` mirrors the existing three-subsection structure (Created, Unexpected, Already correct). It is the most consistent convention for a fourth apply outcome. |
| Scope enforcement — one level deep only | Reuse existing Step 2 observation (one level deep, `OBSERVED_ITEMS`) | Recurse into subdirectories | The proposal explicitly excludes recursive scanning. `OBSERVED_ITEMS` is already collected at one level deep in Step 2 — the classification step simply inspects that existing set. No new filesystem enumeration is needed. |

## Data Flow

```
Step 2 (OBSERVED_ITEMS — one level deep, unchanged)
      │
      ▼
Step 3 — Classification
      │
      ├── PRESENT (in canonical expected set)
      │
      ├── MISSING_REQUIRED (CLAUDE.md, skills/ absent)
      │
      ├── UNEXPECTED (not in canonical set) ──► scan each .md file
      │                                               │
      │                       filename stem in KNOWN_TARGETS? ──YES──► DOCUMENTATION_CANDIDATES
      │                                               │                 (with destination path)
      │                                               NO
      │                                               │
      │                       heading pattern found?  ──YES──► DOCUMENTATION_CANDIDATES
      │                                               │         (with destination = ai-context/<name>.md)
      │                                               NO → stays in UNEXPECTED
      │
      ▼
Step 4 — Dry-run plan display
      │
      ├── To be created: [MISSING_REQUIRED items]
      ├── Documentation to migrate → ai-context/: [DOCUMENTATION_CANDIDATES]
      │     (shows source → destination, notes copy-only and source-preserved)
      ├── Unexpected items: [remaining UNEXPECTED]
      └── Already correct: [PRESENT]
      │
      ▼ (user confirms: yes/no)
      │
Step 5 — Apply
      │
      ├── 5.1 Create skills/ (if missing)
      ├── 5.2 Create hooks/ (if missing)
      ├── 5.3 Create CLAUDE.md stub (if missing)
      ├── 5.4 Copy DOCUMENTATION_CANDIDATES ──► ai-context/<filename>.md
      │         • ensure ai-context/ exists (mkdir if absent)
      │         • skip if destination exists → record as skipped
      │         • copy → record as copied
      │         • NEVER delete/modify source
      ├── 5.5 Flag UNEXPECTED items (unchanged, was 5.4)
      └── 5.6 Acknowledge PRESENT items (unchanged, was 5.5)
      │
      ▼
Step 6 — Write claude-organizer-report.md
      (adds "### Documentation copied to ai-context/" section)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-claude-organizer/SKILL.md` | Modify | Step 3: add `DOCUMENTATION_CANDIDATES` bucket with filename + heading heuristics; Step 4: add fourth dry-run category; Step 5: insert new Step 5.4 copy operation (shift 5.4→5.5, 5.5→5.6); Step 6: add `### Documentation copied to ai-context/` report section |
| `ai-context/architecture.md` | Modify | Update `claude-organizer-report.md` artifact entry to reflect the new report section |

## Interfaces and Contracts

The skill operates on implicit data structures defined within the SKILL.md procedural text. The relevant contracts for the new bucket:

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

DOCUMENTATION_CANDIDATES = [
  {
    source:      "<PROJECT_CLAUDE_DIR>/<filename>.md",
    destination: "<PROJECT_ROOT>/ai-context/<filename>.md",
    reason:      "filename-match" | "heading-match"
  },
  ...
]

Copy result record (per candidate):
  "<filename>.md" → "copied to ai-context/<filename>.md"
  "<filename>.md" → "skipped (destination exists — review manually)"
  "<filename>.md" → "excluded by user"
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual walkthrough | Run `/project-claude-organizer` in a test project with `stack.md` and `architecture.md` placed directly under `.claude/`; verify they appear in the fourth plan category, are copied to `ai-context/`, and remain in `.claude/` | Claude Code session |
| Idempotency check | Run the skill twice; second run must record all candidates as `skipped (destination exists)` | Claude Code session |
| Non-promotion check | Place a `.md` file with an unrecognized filename and no known headings under `.claude/`; verify it remains in `UNEXPECTED`, not promoted | Claude Code session |
| Secondary signal check | Place a file named `notes.md` under `.claude/` containing `## Tech Stack`; verify it is promoted to `DOCUMENTATION_CANDIDATES` | Claude Code session |
| No-candidate run | Run against a `.claude/` with no `.md` files at root level; verify the fourth category is omitted from the plan entirely | Claude Code session |

## Migration Plan

No data migration required. The change is a procedural skill modification. Existing `claude-organizer-report.md` files written by the V1 skill are runtime artifacts (never committed); they are overwritten on the next run.

## Open Questions

None.
