# Closure: 2026-03-19-cleanup-orphan-changes

Start date: 2026-03-19
Close date: 2026-03-19

## Summary

Cleaned up two orphaned SDD change directories (`spec-hygiene/` and `2026-03-14-specs-sqlite-store/`) and introduced a formal orphan-detection convention as a precondition section in `openspec/specs/sdd-archive-execution/spec.md`.

## Modified Specs

| Domain                  | Action   | Change                                                                      |
| ----------------------- | -------- | --------------------------------------------------------------------------- |
| sdd-archive-execution   | Modified | Appended Orphan Precondition section with definition, disposition options, and non-blocking check at archive phase entry |

## Modified Code Files

- `openspec/specs/sdd-archive-execution/spec.md` — Orphan Precondition section added (lines 354–471)
- `openspec/changes/archive/2026-03-14-spec-hygiene/` — created (archive of exploration-only orphan)
- `openspec/changes/archive/2026-03-14-spec-hygiene/CLOSURE.md` — created
- `docs/adr/039-orphan-change-disposition-convention.md` — created
- `docs/adr/README.md` — updated (ADR 039 row added)
- `ai-context/changelog-ai.md` — updated with session actions

## Key Decisions Made

- Orphan detection is a Step 0 precondition in `sdd-archive` — non-blocking to the current archive but requires operator disposition before proceeding.
- Three valid dispositions: revive, archive, delete. No others permitted.
- Delete disposition requires git commit hash evidence in changelog; no CLOSURE.md required.
- Archive disposition requires CLOSURE.md with original dir, disposition, reason, and date.
- 7-day age threshold for orphan classification; tunable via a future delta spec.
- Convention is spec-level (not CLAUDE.md) — `sdd-archive-execution/spec.md` is authoritative.
- ADR 039 documents the orphan disposition convention as an architecture decision.

## Lessons Learned

- Orphan directories accumulate silently without a detection convention. Adding the check as Step 0 of sdd-archive ensures cleanup happens naturally at the next archive cycle.
- The sdd-archive SKILL.md was not modified in this change — enforcement depends on the sub-agent reading the updated spec. A future change could embed explicit Step 0 instructions directly in SKILL.md for direct enforcement (noted as a suggestion in verify-report).

## User Docs Reviewed

N/A — pre-dates this requirement
