# Technical Design: 2026-03-19-cleanup-orphan-changes

Date: 2026-03-19
Proposal: openspec/changes/2026-03-19-cleanup-orphan-changes/proposal.md

## General Approach

Three sequential file-system operations plus one additive spec update. No new skills, no new architecture layers, and no code changes. The archive operation follows the existing convention (`openspec/changes/archive/YYYY-MM-DD-<name>/` + `CLOSURE.md`). The spec update is purely additive — existing scenarios in `sdd-archive-execution/spec.md` are untouched; a new `Orphan Precondition` section is appended. All operations are low-risk and fully reversible via git.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| --- | --- | --- | --- |
| Disposition of `spec-hygiene/` | Archive (move to `archive/2026-03-14-spec-hygiene/` + `CLOSURE.md`) | Delete entirely | The directory contains a valid `exploration.md` with full spec-corpus audit findings. Archiving preserves the knowledge and follows the convention for informational-only changes. |
| Disposition of `2026-03-14-specs-sqlite-store/` | Delete from working tree | Archive | Already superseded by an accepted architectural direction (index.yaml, ADR 034). Archiving would create a misleading entry. Git history at `6a9b1d4` preserves full content with no information loss. |
| Orphan convention placement | Additive section in `openspec/specs/sdd-archive-execution/spec.md` | New standalone spec domain; CLAUDE.md Plan Mode Rules | `sdd-archive-execution` is the authoritative behavioral spec for the archive phase — defining orphan preconditions there keeps them co-located with the skill that must enforce them. A standalone domain would fragment governance. CLAUDE.md modification is explicitly excluded from scope. |
| Orphan age threshold | 7 days without a proposal | 14 days; no threshold | 7 days aligns with the `ai-context/` staleness warning threshold already used in `sdd-design` Step 0, creating a consistent system-wide staleness signal. |
| Orphan disposition options | Three choices: Revive, Archive, Delete | Binary (keep/delete) | Matches the three real outcomes observed in this change: `spec-hygiene/` → Archive; `specs-sqlite-store/` → Delete; active changes → Revive. The options must cover all real cases. |

## Data Flow

```
sdd-apply executes three sequential operations:

1. Archive spec-hygiene/
   openspec/changes/spec-hygiene/
       exploration.md
   ──move──►
   openspec/changes/archive/2026-03-14-spec-hygiene/
       exploration.md          (moved, unchanged)
       CLOSURE.md              (new — written by apply)

2. Delete specs-sqlite-store/
   openspec/changes/2026-03-14-specs-sqlite-store/
       proposal.md
   ──delete──► (removed from working tree; preserved in git at 6a9b1d4)

3. Append orphan convention to master spec
   openspec/specs/sdd-archive-execution/spec.md
   ──append──►
   openspec/specs/sdd-archive-execution/spec.md
       [existing content unchanged]
       + ## Orphan Precondition (new section)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `openspec/changes/spec-hygiene/exploration.md` | Move | Moved to archive; content unchanged |
| `openspec/changes/archive/2026-03-14-spec-hygiene/` | Create (directory) | New archive entry |
| `openspec/changes/archive/2026-03-14-spec-hygiene/exploration.md` | Move destination | The moved exploration.md |
| `openspec/changes/archive/2026-03-14-spec-hygiene/CLOSURE.md` | Create | Closure note: informational audit, no action taken, archived without full SDD cycle |
| `openspec/changes/2026-03-14-specs-sqlite-store/` (entire directory) | Delete | Removed from working tree; git-recoverable at `6a9b1d4` |
| `openspec/specs/sdd-archive-execution/spec.md` | Modify (append) | New `## Orphan Precondition` section added after existing `## Rules` |
| `docs/adr/039-orphan-change-disposition-convention.md` | Create | ADR 039 documenting the orphan convention decision |
| `docs/adr/README.md` | Modify | Row added for ADR 039 |

## Interfaces and Contracts

### CLOSURE.md structure (for `spec-hygiene/`)

```markdown
# Closure: spec-hygiene

Date: 2026-03-19
Archived from: openspec/changes/spec-hygiene/
Archive path: openspec/changes/archive/2026-03-14-spec-hygiene/

## Status

Archived without a full SDD cycle.

## Reason

This directory was an exploration-only artifact from a 2026-03-14 spec-hygiene audit.
The exploration concluded "no action required" (Recommendation: Approach A).
No proposal was created, and no changes were made to the codebase.

The directory also lacked the required YYYY-MM-DD- date prefix, making it ambiguous
in the active changes listing.

## Disposition

Informational audit. All findings are preserved in exploration.md.
```

### Orphan Precondition section (to append to `sdd-archive-execution/spec.md`)

The new section defines:

- **Orphan definition**: a change directory in `openspec/changes/` that meets ALL of:
  1. Age ≥ 7 days (inferred from date prefix or git log)
  2. No `proposal.md` present (exploration-only or stub)
  3. No other active change references it as a dependency

- **Required disposition** (must be stated explicitly before archiving the parent change):
  - **Revive**: add a `proposal.md` and continue the SDD cycle
  - **Archive**: move to `archive/YYYY-MM-DD-<name>/` with a `CLOSURE.md`
  - **Delete**: remove from working tree (state git commit for recovery)

- **Enforcement**: `sdd-archive` MUST detect undisposed orphan siblings before completing Step 1 (move). If orphans exist, it MUST emit a MUST_RESOLVE warning listing them with their age and state.

## Testing Strategy

| Layer | What to test | Tool |
| --- | --- | --- |
| Manual verification | `openspec/changes/spec-hygiene/` no longer exists | `ls openspec/changes/` |
| Manual verification | `openspec/changes/archive/2026-03-14-spec-hygiene/` exists with `exploration.md` + `CLOSURE.md` | `ls openspec/changes/archive/2026-03-14-spec-hygiene/` |
| Manual verification | `openspec/changes/2026-03-14-specs-sqlite-store/` no longer exists | `ls openspec/changes/` |
| Manual verification | `sdd-archive-execution/spec.md` contains `## Orphan Precondition` section | `grep "Orphan Precondition" openspec/specs/sdd-archive-execution/spec.md` |
| Manual verification | `openspec/changes/` contains exactly the expected active directories | `ls openspec/changes/` — must show only date-prefixed active changes + archive/ |

No automated test runner applies. Verification is by filesystem inspection and spec content search.

## Migration Plan

No data migration required. This change operates on SDD artifact directories, not on any data store or schema.

## Open Questions

None. All decisions are resolved by the proposal and confirmed by the exploration artifacts.
