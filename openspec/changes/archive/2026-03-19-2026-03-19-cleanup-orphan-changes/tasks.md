# Task Plan: 2026-03-19-cleanup-orphan-changes

Date: 2026-03-19
Design: openspec/changes/2026-03-19-cleanup-orphan-changes/design.md

## Progress: 8/8 tasks

## Phase 1: Archive spec-hygiene orphan

- [x] 1.1 Create directory `openspec/changes/archive/2026-03-14-spec-hygiene/` and move `openspec/changes/spec-hygiene/exploration.md` into it ✓
- [x] 1.2 Create `openspec/changes/archive/2026-03-14-spec-hygiene/CLOSURE.md` with the exact content specified in the design (original directory, disposition "archive", reason "informational exploration — recommendation: no action required", date 2026-03-19) ✓
- [x] 1.3 Verify `openspec/changes/spec-hygiene/` no longer exists (source directory removed after move) ✓

## Phase 2: Delete specs-sqlite-store orphan

- [x] 2.1 Delete the entire `openspec/changes/2026-03-14-specs-sqlite-store/` directory from the working tree [WARNING: ADVISORY] ✓
  Warning: Directory deletion is irreversible in the working tree; recovery depends on git history at commit 6a9b1d4.
  Reason: performance consideration — does not affect correctness; git history fully preserves content and the design explicitly authorizes this disposal

## Phase 3: Update master spec — Orphan Precondition

- [x] 3.1 Append the new `## Orphan Precondition` section to `openspec/specs/sdd-archive-execution/spec.md` — content must exactly match the section defined in the delta spec at `openspec/changes/2026-03-19-cleanup-orphan-changes/specs/sdd-archive-execution/spec.md` (orphan definition, three disposition options, non-blocking check behavior, and associated scenarios) ✓

## Phase 4: Create ADR 039

- [x] 4.1 Create `docs/adr/039-orphan-change-disposition-convention.md` using the Nygard ADR template — title "Orphan Change Disposition Convention — 7-day threshold, three disposal options, and MUST_RESOLVE gate in sdd-archive", status "Proposed", date 2026-03-19; Context must explain the problem (undated, stalled change dirs); Decision must state the 7-day threshold, three options (revive/archive/delete), CLOSURE.md requirement; Consequences must include the mandatory Step 0 addition to sdd-archive ✓
- [x] 4.2 Modify `docs/adr/README.md` — confirm row for ADR 039 is present (it was already added in the design phase); if absent, add row: `| [039](039-orphan-change-disposition-convention.md) | Orphan Change Disposition Convention — 7-day threshold, three disposal options, and MUST_RESOLVE gate in sdd-archive | Proposed | 2026-03-19 |` ✓

## Phase 5: Verification and memory update

- [x] 5.1 Verify final state of `openspec/changes/`: must contain only date-prefixed active directories and `archive/`; run `ls openspec/changes/` mentally and confirm `spec-hygiene/` and `2026-03-14-specs-sqlite-store/` are absent ✓
- [x] 5.2 Update `ai-context/changelog-ai.md` — add session entry recording: (a) archived `spec-hygiene/` → `archive/2026-03-14-spec-hygiene/`, (b) deleted `2026-03-14-specs-sqlite-store/` (content preserved in git at `6a9b1d4`), (c) appended Orphan Precondition section to `sdd-archive-execution/spec.md`, (d) created ADR 039 ✓

---

## Implementation Notes

- The move in task 1.1 must produce both the destination file and the absence of the source directory; git will track this as a rename
- The CLOSURE.md in task 1.2 must follow the exact structure in `design.md` (## Status, ## Reason, ## Disposition sections)
- Task 2.1 deletion requires no CLOSURE.md — the design explicitly states "deletion is its own record in git history"; the changelog entry (task 5.2) is the required deletion record
- Task 3.1 is an append-only operation — existing content in `sdd-archive-execution/spec.md` must remain unchanged
- ADR 039 row was already added to `docs/adr/README.md` during the design phase (visible at line 93 of README.md); task 4.2 is a verification task, not a creation task

## Blockers

None.
