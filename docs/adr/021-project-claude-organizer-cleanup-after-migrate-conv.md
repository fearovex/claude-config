# ADR-021: Project Claude Organizer Cleanup Convention — Confirmed-Deletion Post-Migration Pattern

## Status

Proposed

## Context

The `project-claude-organizer` skill migrates legacy `.claude/` directories to their
SDD-aligned destinations (`ai-context/`, `openspec/`, `docs/`, etc.). Prior to this change,
the skill's core invariant was "source files are NEVER deleted, moved, or modified" — an
unconditional guarantee that simplified the skill's mental model but left users with
duplicate content: original `.claude/` directories remained intact after migration, requiring
manual cleanup to complete the reorganization.

The skill was extended (smart-migration pattern, ADR-020) to support 7 distinct migration
strategies, two of which are advisory-only (`delegate`) or section-level (`section-distribute`).
For the remaining strategies (`copy`, `append`, `scaffold`, `user-choice`), actual file writes
occur. These are the only categories where post-migration cleanup is meaningful.

A design tension exists: cleanup is useful but risks data loss if applied prematurely (before
successful migration) or to files that were not fully transferred. The user must be the
decision-maker — the skill cannot infer intent on their behalf.

## Decision

We will add a post-migration cleanup sub-step after each applicable migration strategy in
Step 5.7 of the `project-claude-organizer` skill. The cleanup sub-step:

1. Applies ONLY to strategies that perform actual file writes: `copy`, `append`, `scaffold`,
   and `user-choice`. The `delegate` and `section-distribute` strategies are permanently
   excluded from cleanup.
2. Triggers ONLY when at least one file in the category was successfully migrated (i.e., not
   all files were skipped or failed).
3. Presents the user with two explicit lists before prompting: files that will be deleted
   (successful migrations) and files that will be preserved (skipped or failed migrations).
4. Requires explicit `yes` confirmation before deleting any file. A `no` response leaves all
   source files intact.
5. Deletes ONLY the individually listed source files — never the parent source directory.
6. Records all deletion outcomes in the report under a "Deleted from .claude/" subsection.

The new invariant replacing the unconditional "never delete" for applicable strategies is:
**source files MUST NOT be deleted without BOTH conditions being true: (a) the file was
successfully migrated, AND (b) the user explicitly confirmed the cleanup prompt for that
category.**

## Consequences

**Positive:**

- Users can complete the `.claude/` reorganization in a single skill run without manual cleanup
- The confirmation-gate pattern (already established for the migration prompt) is reused for
  the cleanup prompt, making the UX consistent and predictable
- Partial migrations are handled safely: only successfully migrated files are offered for
  deletion; skipped and failed files are preserved
- The report provides a full audit trail of what was deleted vs. preserved

**Negative:**

- The skill now involves more interactive prompts per run (up to 2 prompts per eligible
  category: migration + cleanup), which can feel verbose for users with many legacy categories
- The unconditional "source files are never deleted" guarantee is no longer globally true for
  all strategies — users and future skill authors must consult the updated Rules section to
  understand which strategies are exempt
- Deleted files cannot be recovered by the skill; users must rely on version control for
  recovery if they confirm deletion in error
