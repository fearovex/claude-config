# Technical Design: 2026-03-20-sdd-archive-move-incomplete

Date: 2026-03-20
Proposal: openspec/changes/2026-03-20-sdd-archive-move-incomplete/proposal.md

## General Approach

This is a targeted two-file textual fix. Step 4 of `skills/sdd-archive/SKILL.md` will receive three additional prose sentences: a semantic anchor restoring the "move" intent, an explicit deletion instruction for the source directory, and a verification sentence requiring confirmation before continuing to Step 5. A new requirement covering move semantics will be written as a delta spec in this change's `specs/sdd-archive-execution/spec.md` for eventual merging into the master spec. No orchestration, no new files beyond the delta spec, and no changes to adjacent steps.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|---|---|---|---|
| Instruction placement in Step 4 | Insert after the existing `I create openspec/changes/archive/` sentence — append before Step 5 begins | Inserting before the pre-flight date-stripping block | The pre-flight block must run first to derive the destination path; insertion after the copy instructions is the only semantically safe position |
| Instruction phrasing | Imperative prose using "I MUST delete" and "The source MUST NOT exist" | Conditional language ("if successful, delete") | The proposal explicitly calls for imperative language consistent with spec conventions; it removes ambiguity for the sub-agent |
| Precondition guard | Require confirmation that all files are at destination before deletion is described | Attempting deletion in parallel with copy | Proposal risk analysis identifies partial-copy + delete as the highest-impact failure mode; the precondition guard eliminates this path |
| Delta spec location | `openspec/changes/2026-03-20-sdd-archive-move-incomplete/specs/sdd-archive-execution/spec.md` | Editing master spec directly | SDD convention requires delta specs; master spec is updated only at archive time via Step 3 merge |
| No ADR | Skip ADR generation | Generate ADR for the spec gap fix | No cross-cutting architectural pattern is introduced; this change fills a previously undocumented behavioral gap in one skill step — it is implementation-level, not architecture-level |

## Data Flow

```
sdd-archive Step 4 execution flow (updated):

1. Pre-flight: strip date prefix from slug → derive archive_slug
2. Construct destination: openspec/changes/archive/YYYY-MM-DD-<archive_slug>/
3. Create destination directory if absent
4. Copy all files from openspec/changes/<change-name>/ → destination/
5. [NEW] Confirm all files exist at destination (verification precondition)
6. [NEW] Delete openspec/changes/<change-name>/ and all its contents
7. [NEW] Verify source directory no longer exists before continuing
8. Continue to Step 5 (CLOSURE.md creation)

Precondition dependency:
  Step 6 (delete source) MUST NOT execute unless Step 5 (destination verification) is confirmed.
  If Step 5 cannot be confirmed: halt and report error. Do NOT delete source.
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-archive/SKILL.md` | Modify | Add three sentences to Step 4 after the archive directory creation instruction: (1) semantic anchor "I move the change folder:", (2) source-deletion instruction, (3) verification sentence |
| `openspec/changes/2026-03-20-sdd-archive-move-incomplete/specs/sdd-archive-execution/spec.md` | Create | Delta spec with one new requirement: move semantics — source directory MUST be deleted after all files confirmed at destination; source MUST NOT exist after Step 4 completes |

## Interfaces and Contracts

No new interfaces or type definitions. The behavioral contract is:

```
Step 4 post-condition (new):
  GIVEN: all files from openspec/changes/<change-name>/ have been written to destination
  MUST: openspec/changes/<change-name>/ no longer exists on the filesystem
  MUST NOT: source deletion execute before destination files are confirmed
  ON FAILURE to confirm destination: halt, report error, do NOT delete source
```

## Testing Strategy

| Layer | What to test | Tool |
|---|---|---|
| Manual inspection | Run `/sdd-archive` on a test change; verify `openspec/changes/<test-change>/` is absent after the operation | Manual + verify-report.md |
| Regression inspection | Confirm Step 4 pre-flight date-stripping block is unchanged | Code review of diff |
| Verify criterion | `verify-report.md` for this change records `[x]` for "source directory absent after archive" | verify-report.md |

No automated test runner exists for SKILL.md files. Testing is behavioral (run the skill, observe outcome).

## Migration Plan

No data migration required. Ghost duplicates already present in `openspec/changes/` from prior archive runs are explicitly out of scope (see proposal Excluded section). They may be cleaned up manually or via a separate `/sdd-archive` pass if desired.

## Open Questions

None.
