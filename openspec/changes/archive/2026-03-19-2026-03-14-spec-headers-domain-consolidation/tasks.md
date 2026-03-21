# Task Plan: 2026-03-14-spec-headers-domain-consolidation

Date: 2026-03-14
Design: openspec/changes/2026-03-14-spec-headers-domain-consolidation/design.md

## Progress: 0/9 tasks

## Phase 1: Header Backfill — Legacy Spec Files

- [ ] 1.1 Modify `openspec/specs/sdd-apply/spec.md` — replace the legacy `*Created: ...*` italic header line with the two-line canonical block `Change: 2026-03-03-tech-skill-auto-activation\nDate: 2026-03-03` immediately after the `# Spec:` title and blank line; leave all remaining content unchanged
- [ ] 1.2 Modify `openspec/specs/sdd-verify-execution/spec.md` — replace `*Created: 2026-02-28 by change "close-p1-gaps-sdd-apply-verify"*` with `Change: 2026-02-28-close-p1-gaps-sdd-apply-verify\nDate: 2026-02-28`; leave all remaining content unchanged
- [ ] 1.3 Modify `openspec/specs/smart-commit/spec.md` — replace the entire bare-key-lines + horizontal-rule block (`Last updated: 2026-03-03\nCreated by change: smart-commit-functional-split\n\n---`) with the canonical two-line block `Change: 2026-03-03-smart-commit-functional-split\nDate: 2026-03-03`; leave all remaining content unchanged
- [ ] 1.4 Modify `openspec/specs/solid-ddd-skill/spec.md` — replace `*Created: 2026-03-04 by change "solid-ddd-quality-enforcement"*` with `Change: 2026-03-04-solid-ddd-quality-enforcement\nDate: 2026-03-04`; leave all remaining content unchanged

## Phase 2: Merge sdd-apply-execution into sdd-apply

- [ ] 2.1 Read `openspec/specs/sdd-apply-execution/spec.md` in full and verify its content is intact before any destructive step; record its line count for post-merge verification
- [ ] 2.2 Append to `openspec/specs/sdd-apply/spec.md` — add a horizontal rule (`---`) followed by `## Part 2: TDD Mode and Output` heading, then the full verbatim content of `openspec/specs/sdd-apply-execution/spec.md`; verify post-merge line count is >= (pre-change sdd-apply line count + sdd-apply-execution line count)

## Phase 3: Retire sdd-apply-execution Directory

- [ ] 3.1 Delete `openspec/specs/sdd-apply-execution/spec.md` — only after Phase 2 is confirmed complete and post-merge line count verified; then remove the now-empty `openspec/specs/sdd-apply-execution/` directory
  Warning: Deletion is irreversible without git. Phase 2 (merge + line count verification) MUST be complete before this task executes.
  Reason: dependency ordering — spec rules require directory deletion only after successful merge

## Phase 4: Update References in architecture.md

- [ ] 4.1 Modify `ai-context/architecture.md` — find and replace both occurrences of `openspec/specs/sdd-apply-execution/spec.md` with `openspec/specs/sdd-apply/spec.md` (in key decision 19 and the D13 artifact table row); verify no remaining occurrences of `sdd-apply-execution/spec.md` after the edit

## Phase 5: Verification and Documentation

- [ ] 5.1 Verify all 4 backfilled spec files (`sdd-apply`, `sdd-verify-execution`, `smart-commit`, `solid-ddd-skill`) — read the first 5 lines of each file and confirm line 1 is `# Spec: <title>`, line 2 is blank, line 3 is `Change: <slug>`, line 4 is `Date: YYYY-MM-DD`
- [ ] 5.2 Update `ai-context/changelog-ai.md` — append a session entry recording: header backfill on 4 spec files, sdd-apply-execution merge into sdd-apply/spec.md as Part 2, directory deletion of sdd-apply-execution/, and architecture.md path reference update

---

## Implementation Notes

- The smart-commit spec has a near-canonical format (bare key lines + `---` separator rather than italic prose); the apply agent must replace the entire key-lines + `---` block, not just the italic line
- The deletion in Task 3.1 MUST NOT be executed before Task 2.2 is complete and the merged file's line count is verified
- Originating slugs in backfilled headers come verbatim from the legacy header text — no inference permitted
- The `## Part 2: TDD Mode and Output` heading MUST appear exactly once in `sdd-apply/spec.md` after the change
- No file other than the six identified targets may be modified

## Blockers

None.
