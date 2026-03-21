# Proposal: cleanup-orphan-changes

Date: 2026-03-19
Status: Draft

## Intent

Remove and archive two orphaned SDD change directories from `openspec/changes/` to prevent future sessions from treating superseded or incomplete work as active, and introduce a formal orphan-detection convention to prevent recurrence.

## Motivation

Two change directories have been present in `openspec/changes/` without ever reaching the archive:

1. `spec-hygiene/` — an exploration-only artifact from a 2026-03-14 side investigation. The exploration concluded "no action needed," so no proposal was ever created. The directory also lacks the required `YYYY-MM-DD-` date prefix.
2. `2026-03-14-specs-sqlite-store/` — a proposal for an SQLite-backed spec store that was superseded in the same session by the `index.yaml` approach (archived as `specs-search-optimization`). ADR 034 already documents the SQLite/FTS5 migration as a deferred path for 100+ domains.

Both directories are stale ambiguity sources: future sessions may mistake them for active work, triggering unintended `/sdd-apply` cycles or re-investigating already-resolved questions. Additionally, no convention exists to define what constitutes an "orphan" or what to do about one — meaning orphans will continue to accumulate silently.

## Scope

### Included

- Archive `openspec/changes/spec-hygiene/` into `openspec/changes/archive/2026-03-14-spec-hygiene/` with a `CLOSURE.md` noting it as a completed informational audit with no action taken
- Delete `openspec/changes/2026-03-14-specs-sqlite-store/` (superseded — preserved in git at commit `6a9b1d4`)
- Write an orphan-detection convention into `openspec/specs/sdd-archive-execution/spec.md` as a precondition for the archive phase

### Excluded (explicitly out of scope)

- Any modification to `2026-03-14-spec-headers-domain-consolidation/` or `2026-03-18-context-handoff-between-sessions/` — these are complete or in-progress, not orphans
- Modifying `CLAUDE.md` Plan Mode Rules with the orphan convention — the spec is the authoritative source; CLAUDE.md would only be updated if a separate change determines it belongs there
- Any new SDD cycle for the SQLite store — ADR 034 already marks that as a deferred proposed path

## Proposed Approach

Three sequential operations:

1. **Archive `spec-hygiene/`**: rename/move the directory to `openspec/changes/archive/2026-03-14-spec-hygiene/`, write a brief `CLOSURE.md` inside it explaining its status (informational audit, no action taken, archived without a full SDD cycle because the recommendation was "no action required").

2. **Delete `specs-sqlite-store/`**: remove `openspec/changes/2026-03-14-specs-sqlite-store/` entirely. The content is preserved in git history at commit `6a9b1d4`.

3. **Write orphan convention**: update `openspec/specs/sdd-archive-execution/spec.md` to add an Orphan Precondition section defining what constitutes an orphan and requiring explicit disposition before archiving the host change.

## Affected Areas

| Area/Module | Type of Change | Impact |
| --- | --- | --- |
| `openspec/changes/spec-hygiene/` | Removed (archived) | Low — artifact moved to archive |
| `openspec/changes/2026-03-14-specs-sqlite-store/` | Removed (deleted) | Low — superseded; git preserves content |
| `openspec/changes/archive/2026-03-14-spec-hygiene/` | New (archive entry) | Low — new archive directory |
| `openspec/specs/sdd-archive-execution/spec.md` | Modified (new section) | Low — additive spec change |

## Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| Deleting `specs-sqlite-store/proposal.md` causes loss of useful content | Low | Low | ADR 034 already documents the SQLite migration path; git preserves full content at `6a9b1d4` |
| `sdd-archive-execution/spec.md` does not exist yet | Low | Low | If absent, create it with the orphan convention as the first entry |
| Archive date prefix for `spec-hygiene/` is inferred (2026-03-14) rather than canonical | Low | Low | Commit `6a9b1d4` confirms the date; the prefix is accurate |
| Orphan convention threshold (7-day age) may need tuning | Low | Low | Convention is a spec-level document — easy to update via a future change |

## Rollback Plan

- **For the archive operation**: `spec-hygiene/` is moved, not deleted. To revert: move `openspec/changes/archive/2026-03-14-spec-hygiene/` back to `openspec/changes/spec-hygiene/` and delete `CLOSURE.md`.
- **For the deletion**: `git checkout 6a9b1d4 -- openspec/changes/2026-03-14-specs-sqlite-store/` restores the directory from git history.
- **For the spec update**: revert the `sdd-archive-execution/spec.md` modification via `git checkout HEAD -- openspec/specs/sdd-archive-execution/spec.md`.

All rollback operations are single-command git operations.

## Dependencies

- Git history at commit `6a9b1d4` must be intact (confirmed — this is a committed change in the repo)
- `openspec/specs/sdd-archive-execution/spec.md` must exist or be creatable (check during apply)
- No other active changes depend on either orphaned directory

## Success Criteria

- [ ] `openspec/changes/spec-hygiene/` no longer exists as an active change directory
- [ ] `openspec/changes/archive/2026-03-14-spec-hygiene/` exists and contains `exploration.md` + `CLOSURE.md`
- [ ] `openspec/changes/2026-03-14-specs-sqlite-store/` no longer exists
- [ ] `openspec/specs/sdd-archive-execution/spec.md` contains an Orphan Precondition section with at least: definition of "orphan", age/state threshold, and required disposition options (revive, archive, delete)
- [ ] `openspec/changes/` contains only the three non-orphan active directories after cleanup

## Effort Estimate

Low (hours) — 3 file operations (move, delete, write CLOSURE.md) + 1 spec update
