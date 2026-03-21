# ADR 039: Orphan Change Disposition Convention — 7-day threshold, three disposal options, and MUST_RESOLVE gate in sdd-archive

Date: 2026-03-19
Status: Proposed

---

## Context

Over time, the `openspec/changes/` directory accumulates change directories that were never completed. These fall into two categories:

1. **Missing date prefix**: directories named without the required `YYYY-MM-DD-<slug>` convention (e.g., `spec-hygiene/`), making their age and status ambiguous in the active changes listing.
2. **Stalled exploration-only entries**: directories that contain only an `exploration.md` with no follow-on `proposal.md`, indicating the exploration concluded without triggering an SDD cycle. These become invisible to the system — they are neither active nor archived.

Without a formal convention, these orphan directories accumulate silently. They create noise in the changes listing, mislead future operators about what is active, and violate the date-prefix convention established for all change directories.

The immediate trigger for this ADR is the cleanup of two orphaned entries discovered in the `openspec/changes/` directory:
- `spec-hygiene/` — exploration-only, no date prefix, > 7 days old
- `2026-03-14-specs-sqlite-store/` — superseded by an accepted architectural direction (ADR 034, index.yaml), no longer relevant

A systematic convention is needed so that future orphans are caught and disposed of as part of the normal SDD archive flow rather than discovered ad hoc.

---

## Decision

### Orphan Definition

A change directory under `openspec/changes/` is an **orphan** when it meets ALL four criteria:

1. **Age threshold**: exists for more than **7 days** (measured from the earliest git commit introducing any file in the directory, or filesystem ctime when git history is unavailable).
2. **Missing date prefix**: directory name does not follow `YYYY-MM-DD-<slug>`.
3. **Stalled state**: contains no `tasks.md`, no `verify-report.md`, and has not been modified within the last 7 days — OR contains only `exploration.md` with no `proposal.md`.
4. **No cross-reference**: no active `tasks.md` in any other change directory references this directory by path.

The 7-day threshold aligns with the `ai-context/` staleness warning already used in `sdd-design` Step 0, creating a consistent system-wide staleness signal.

### Three Disposal Options

Every orphan MUST receive an explicit disposition. The valid options are:

| Disposition | Action |
|-------------|--------|
| **revive** | Add a `proposal.md` with a target review date; rename to include `YYYY-MM-DD-` prefix if missing; directory re-enters the active SDD cycle |
| **archive** | Move to `openspec/changes/archive/YYYY-MM-DD-<slug>/`; write a `CLOSURE.md` recording the original path, disposition, reason, and date |
| **delete** | Remove from the working tree; MUST only be used when full content is preserved in git history; the preserving commit hash MUST be recorded in the session's `ai-context/changelog-ai.md` entry |

No other dispositions are valid. `CLOSURE.md` is required for archive dispositions but not for delete dispositions — deletion is its own record in git history.

### MUST_RESOLVE Gate in sdd-archive

The orphan detection check runs as **Step 0** of the `sdd-archive` phase, before any other archive action. If orphans are found, `sdd-archive` MUST present a MUST_RESOLVE prompt listing each orphan with its age and stall reason, and MUST pause for operator input until all orphans have received a disposition. If no orphans are found, Step 0 emits an INFO-level note and execution continues immediately.

The check MUST NOT block the archive of the current change — it is a cleanup gate, not a hard blocker.

---

## Consequences

- `sdd-archive` gains a **Step 0** (orphan pre-check) that runs before all existing steps. Existing step numbering is unchanged.
- The `sdd-archive-execution` master spec gains a new `## Orphan Precondition` section documenting the definition, disposal options, and behavioral scenarios.
- Operators archiving a change will be prompted to dispose of any lingering orphan sibling directories before the archive proceeds. This adds a brief interactive step but prevents orphan accumulation.
- Future exploratory changes that do not yield a proposal MUST either be revived (with a `proposal.md`) or explicitly archived/deleted within 7 days of the exploration date.
- The `YYYY-MM-DD-` date prefix convention is reinforced as a hard requirement — undated directories are automatically candidates for orphan classification.
