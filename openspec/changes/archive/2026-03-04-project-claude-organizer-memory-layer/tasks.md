# Task Plan: project-claude-organizer-memory-layer

Date: 2026-03-04
Design: openspec/changes/project-claude-organizer-memory-layer/design.md

## Progress: 8/8 tasks

---

## Phase 1: Classification Extension (Step 3)

- [x] 1.1 Modify `skills/project-claude-organizer/SKILL.md` — extend Step 3 classification block: add `DOCUMENTATION_CANDIDATES` bucket declaration with the closed `KNOWN_AI_CONTEXT_TARGETS` list (`stack`, `architecture`, `conventions`, `known-issues`, `changelog-ai`, `onboarding`, `quick-reference`, `scenarios`) and `KNOWN_HEADING_PATTERNS` list (`## Tech Stack`, `## Architecture`, `## Known Issues`, `## Conventions`, `## Changelog`, `## Domain Overview`); add classification logic that (a) scans `OBSERVED_ITEMS` for `.md` files whose stem (case-insensitive) matches `KNOWN_AI_CONTEXT_TARGETS` and promotes them from `UNEXPECTED` to `DOCUMENTATION_CANDIDATES` with destination `PROJECT_ROOT/ai-context/<filename>.md`, then (b) for remaining `.md` files in `UNEXPECTED`, reads file content and promotes any file containing at least one `KNOWN_HEADING_PATTERNS` line to `DOCUMENTATION_CANDIDATES` with destination `ai-context/<original-filename>.md`; files matching neither signal remain in `UNEXPECTED` ✓

## Phase 2: Dry-Run Plan Extension (Step 4)

- [x] 2.1 Modify `skills/project-claude-organizer/SKILL.md` — extend Step 4 plan display: update the no-op condition guard to also require `DOCUMENTATION_CANDIDATES` is empty before outputting `No reorganization needed`; add a fourth display category `Documentation to migrate → ai-context/` rendered after the existing three categories, listing each candidate as `<source-relative-path> → ai-context/<filename>.md (copy only — source preserved)` with a clarifying note that individual files can be excluded before confirmation; update the `Omit any category that has zero items` rule to cover all four categories ✓

## Phase 3: Apply Step Extension (Step 5)

- [x] 3.1 Modify `skills/project-claude-organizer/SKILL.md` — insert new Step 5.4 between the existing Step 5.3 (`CLAUDE.md` stub) and the existing Step 5.4 (flag unexpected), renumbering the old 5.4 to 5.5 and the old 5.5 to 5.6; the new Step 5.4 MUST: (a) ensure `PROJECT_ROOT/ai-context/` exists, creating it if absent; (b) for each file in `DOCUMENTATION_CANDIDATES` not excluded by the user: check if destination exists → if yes, record `<filename>.md — skipped (destination exists — review manually)` and leave source and destination untouched; if no, copy source to destination, verify source still exists after copy, record `<filename>.md — copied to ai-context/<filename>.md`; (c) for each file excluded by the user, record `<filename>.md — excluded by user`; (d) NEVER delete or modify the source file under any circumstance; (e) on copy failure, record `<filename>.md — failed — <error reason>` and continue processing remaining candidates ✓

## Phase 4: Report Extension (Step 6)

- [x] 4.1 Modify `skills/project-claude-organizer/SKILL.md` — extend Step 6 report template: update the `Summary:` line to include the count of documentation files copied (e.g., `<N> item(s) created, <N> documentation file(s) copied to ai-context/, <N> unexpected item(s) flagged, <N> item(s) already correct`); add a `### Documentation copied to ai-context/` subsection inside `## Plan Executed` (placed after `### Created` and before `### Unexpected items`) listing each candidate with its outcome (`copied to ai-context/<filename>.md`, `skipped (destination exists — review manually)`, or `excluded by user`); when `DOCUMENTATION_CANDIDATES` was empty for the entire run, omit this subsection entirely; update the recommended next steps section to conditionally include guidance for reviewing skipped files when any candidate was skipped ✓

## Phase 5: Memory and Cleanup

- [x] 5.1 Modify `ai-context/architecture.md` — locate the artifact table entry for `claude-organizer-report.md` (line ~106) and update its description to reflect the new report section: change `contains plan executed (items created, items flagged, items already correct)` to `contains plan executed (items created, documentation files copied to ai-context/, unexpected items flagged, items already correct) and recommended next steps` ✓

---

## Implementation Notes

- The `DOCUMENTATION_CANDIDATES` bucket is populated during Step 3 AFTER the initial three-bucket classification completes. Files promoted from `UNEXPECTED` must be removed from the `UNEXPECTED` bucket before Step 4 displays the plan.
- Case-insensitive filename matching for `KNOWN_AI_CONTEXT_TARGETS` means `Architecture.md` and `architecture.md` both match — the destination path uses the original filename as-is.
- The secondary heading-match signal requires reading file content. The skill already has read access to `.claude/` during execution — no new filesystem capability is needed.
- Step 5.4 runs BEFORE the existing Step 5.4 (flag unexpected) and Step 5.5 (acknowledge present). After renumbering: flag unexpected becomes 5.5, acknowledge present becomes 5.6.
- The user-exclusion mechanism (per the spec) allows the user to remove files from `DOCUMENTATION_CANDIDATES` before confirming the plan. The prompt/confirmation flow already handles this via the Step 4 confirmation gate — the instructions must explicitly state that candidates can be excluded by listing them as exclusions before confirming.
- The no-op condition guard in Step 4 must be updated: the existing check (`MISSING_REQUIRED` is empty AND `UNEXPECTED` is empty) must also require `DOCUMENTATION_CANDIDATES` is empty. Otherwise a run that only has documentation candidates would display `No reorganization needed`, which is incorrect.
- Source preservation invariant: verify source existence after every successful copy. If source is not found after copy, record as failure and do NOT record as success.

## Blockers

None.
