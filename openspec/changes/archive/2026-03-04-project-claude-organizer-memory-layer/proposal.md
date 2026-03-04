# Proposal: project-claude-organizer-memory-layer

Date: 2026-03-04
Status: Draft

## Intent

Extend `project-claude-organizer` to detect `.md` documentation files inside `.claude/` that contain memory-layer content, surface them in the dry-run plan as a fourth category, and optionally copy (never move) them to the correct `ai-context/` destination after user confirmation.

## Motivation

The `project-claude-organizer` skill was designed to compare a project's `.claude/` folder against the canonical SDD structure and produce an additive reorganization plan. In its current V1 form, it handles three categories: missing required items (create), unexpected items (flag), and already-correct items (acknowledge).

A common real-world scenario is that developers place `.md` documentation files directly inside `.claude/` — files that contain content appropriate for the memory layer (`ai-context/`): stack descriptions, architecture decisions, coding conventions, known issues, changelog entries, or feature-level domain notes. The current skill either ignores these files or marks them as `UNEXPECTED`, offering no actionable guidance on where they belong.

This leaves a gap in the organizer's usefulness: users who have organically accumulated memory-layer content inside `.claude/` must manually identify, evaluate, and move each file. The skill has the information to automate this discovery and presentation step, reducing friction and preventing memory-layer content from being silently discarded or permanently orphaned.

## Scope

### Included

- Add a classification heuristic that identifies `.md` files directly under `.claude/` as "documentation candidates" based on filename pattern matching (filenames matching known ai-context targets) and optional content signal detection (key section headings)
- Add a fourth plan category to the dry-run display: `Documentation to migrate → ai-context/` with a specific destination path per file
- Add a corresponding apply step (Step 5.5, before the existing flag/acknowledge steps) that copies — never moves — each confirmed documentation file to its mapped `ai-context/` destination
- The copy is idempotent: if the destination file already exists, the copy is skipped and recorded as `skipped (destination exists)`
- Update `claude-organizer-report.md` to include the new "Documentation migrated to ai-context/" section
- Update the canonical expected item set in Step 3 to allow known ai-context filenames (e.g., `stack.md`, `architecture.md`, etc.) when they appear at the `.claude/` root, so they are classified as documentation candidates rather than `UNEXPECTED`

### Excluded (explicitly out of scope)

- Moving files: the skill MUST copy only, preserving the original in `.claude/`; manual removal of the source after verification remains the user's responsibility
- Merging content: if the destination `ai-context/` file already exists with different content, the skill skips the copy and flags it — no merge or diff is attempted
- Recursive scanning: only files directly under `.claude/` (one level deep, same as current Step 2) are evaluated — subdirectory `.md` files are not in scope
- Automatic detection of arbitrary `.md` files beyond the known ai-context target filenames — no NLP or content analysis beyond heading presence
- Changes to `claude-folder-audit` Check P8 or any other skill — this change is scoped to `project-claude-organizer/SKILL.md` only

## Proposed Approach

The approach extends the existing 6-step process with targeted additions to Steps 3, 4, 5, and 6:

**Step 3 extension — New classification bucket `DOCUMENTATION_CANDIDATES`:**
After classifying `PRESENT`, `MISSING_REQUIRED`, and `UNEXPECTED`, scan `OBSERVED_ITEMS` for `.md` files whose filename (stem) matches any of the known ai-context target filenames: `stack`, `architecture`, `conventions`, `known-issues`, `changelog-ai`, `onboarding`, `quick-reference`, `scenarios`. Files matching this list are moved from `UNEXPECTED` into `DOCUMENTATION_CANDIDATES` with their mapped destination: `PROJECT_ROOT/ai-context/<filename>.md`.

As a secondary signal, if a `.md` file in `UNEXPECTED` contains at least one of the heading patterns `## Tech Stack`, `## Architecture`, `## Known Issues`, `## Conventions`, `## Changelog`, or `## Domain Overview`, it is also promoted to `DOCUMENTATION_CANDIDATES` with destination `ai-context/<original-filename>.md`. This secondary signal handles non-standard filenames that clearly contain memory-layer content.

**Step 4 extension — Fourth category in the dry-run plan:**
Display the `DOCUMENTATION_CANDIDATES` bucket after the existing three categories, with the source and proposed destination for each file. Make clear in the display that this is a copy (source preserved) and that the user can skip individual files by editing the list before confirming.

**Step 5 extension — New copy operation (Step 5.x):**
For each file in `DOCUMENTATION_CANDIDATES`:
1. Check whether `PROJECT_ROOT/ai-context/` exists; if not, create it.
2. Check whether the destination path already exists: if yes, skip and record as `skipped (destination exists — review manually)`.
3. If the destination does not exist, copy the file to the destination. Record as `copied to ai-context/<filename>.md`.
4. Never delete or modify the source file.

**Step 6 extension — Report section:**
Add a "Documentation migrated to ai-context/" section listing copied files, skipped files, and any files the user excluded.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-claude-organizer/SKILL.md` | Modified — new classification bucket, plan display, apply step, report section | Medium |
| `ai-context/architecture.md` | Modified — update `claude-organizer-report.md` artifact entry to reflect new report section | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| False positives: a `.md` file matched by filename heuristic contains unrelated content | Medium | Low | The dry-run plan presents each candidate with its source path; user reviews before confirming. The copy is non-destructive (source preserved). |
| Destination collision: `ai-context/<file>.md` already exists and the user expects a merge | Low | Medium | Skill explicitly skips existing destinations and records `skipped (destination exists)`. Report instructs user to review manually. No content is lost. |
| Canonical expected set drift: `DOCUMENTATION_CANDIDATES` bucket removes files from `UNEXPECTED` silently | Low | Low | Files promoted to `DOCUMENTATION_CANDIDATES` are still shown in the plan under the new fourth category — they are never silently ignored. |
| Regression in P8 consistency: the known ai-context filenames at `.claude/` root are no longer flagged as `UNEXPECTED` | Low | Low | The known filenames list is small and stable. P8 expected set is unchanged (it operates on a different path). The skill's canonical expected set in Step 3 is updated to treat these filenames as documentation candidates, not errors. |

## Rollback Plan

The only file modified is `skills/project-claude-organizer/SKILL.md`. To revert:

1. `git revert` the commit that applied this change, OR
2. `git checkout <previous-commit> -- skills/project-claude-organizer/SKILL.md`
3. Run `install.sh` to redeploy the reverted skill to `~/.claude/skills/project-claude-organizer/SKILL.md`

No other files are modified at apply time. Any `ai-context/` files that were copied by the extended skill in a previous run remain in place; they are safe to keep or delete manually — no rollback procedure is needed for them since the source files in `.claude/` are preserved.

## Dependencies

- `skills/project-claude-organizer/SKILL.md` must already exist (it does — created in the immediately preceding change)
- No dependency on other in-flight SDD changes
- `install.sh` must be run after apply to deploy the updated skill to `~/.claude/`

## Success Criteria

- [ ] `project-claude-organizer` Step 3 classifies `.md` files at `.claude/` root whose filename matches a known ai-context target (e.g., `stack.md`, `architecture.md`) into `DOCUMENTATION_CANDIDATES` instead of `UNEXPECTED`
- [ ] The dry-run plan in Step 4 displays a fourth category `Documentation to migrate → ai-context/` listing each candidate with its source and proposed destination path
- [ ] Step 5 apply copies (not moves) each confirmed documentation candidate to `PROJECT_ROOT/ai-context/<filename>.md`, skipping files whose destination already exists
- [ ] The `claude-organizer-report.md` includes a "Documentation migrated to ai-context/" section with copy, skip, and exclusion outcomes
- [ ] A `.md` file at `.claude/` root that does NOT match any known ai-context filename and does NOT contain a known memory-layer heading remains in the `UNEXPECTED` category — no false promotion
- [ ] The source file in `.claude/` is present after the copy step (never deleted or moved)
- [ ] Running the skill twice with the same inputs is idempotent: second run skips already-present destinations and records them as `skipped (destination exists)`

## Effort Estimate

Low (hours) — the change is an additive extension to an existing procedural skill. No new files are created beyond the modified SKILL.md. The logic is deterministic and contained within the existing step structure.
