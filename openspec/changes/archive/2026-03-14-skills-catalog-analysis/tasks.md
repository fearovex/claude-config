# Task Plan: skills-catalog-analysis

Date: 2026-03-14
Design: openspec/changes/skills-catalog-analysis/design.md

## Progress: 8/8 tasks

## Phase 1: Format Contract Extension and Hard Violation Fixes

- [x] 1.1 Modify `docs/format-types.md` — extend the `reference` format contract section (lines 115–127) to explicitly document `## Critical Patterns` and `## Code Examples` as valid variant headings, with a note explaining their origin in the Gentleman-Skills corpus
- [x] 1.2 Modify `skills/project-audit/SKILL.md` section D4b (Skill Format Compliance, line ~320) — update the section detection rule to recognize both standard and variant heading names using regex patterns: `^## (Patterns|Critical Patterns)` and `^## (Examples|Code Examples)` for reference format; `^## (Anti-patterns|Critical Patterns)` for anti-pattern format
- [x] 1.3 Modify `skills/elixir-antipatterns/SKILL.md` — rename the section heading on line 28 from `## Critical Patterns` to `## Anti-patterns` (no content changes, heading only)
- [x] 1.4 Modify `skills/claude-code-expert/SKILL.md` — remove the duplicate `## Description` heading on line 13 and the redundant `**Triggers**:` occurrence on line 23; rename `## File Structure for Claude Code` (line 27) to `## Patterns` to conform to reference format contract

## Phase 2: Consistency and Documentation

- [x] 2.1 Modify `skills/sdd-verify/SKILL.md` — insert a Step 0 governance loading block after the `**Triggers**` line (after line 14); copy the exact Step 0 template from `skills/sdd-propose/SKILL.md` or `skills/sdd-design/SKILL.md`, trimmed to read-only context loading, including the non-blocking governance summary log line
- [x] 2.2 Create `docs/sdd-slug-algorithm.md` — new file documenting the STOP_WORDS algorithm used by `sdd-ff` and `sdd-new` for inferring change slugs from user descriptions; include overview, algorithm steps, examples (at least 3), usage context, and notes on determinism and collision handling
- [x] 2.3 Modify `skills/sdd-ff/SKILL.md` — add a reference note to the slug algorithm documentation (e.g., in the Step 2 or Process section introduction) directing readers to `docs/sdd-slug-algorithm.md` for the authoritative algorithm definition
- [x] 2.4 Modify `skills/sdd-new/SKILL.md` — add a reference note to the slug algorithm documentation matching the structure and placement as in `sdd-ff/SKILL.md` (e.g., orchestration section or Step 2)

---

## Implementation Notes

- **Phase 1 priority:** Format contract extension (1.1–1.2) must be applied before or simultaneously with hard violation fixes (1.3–1.4) to keep documentation and enforcement in sync.
- **Phase 2 governance block:** Step 0 in `sdd-verify` must be **non-blocking** (all missing files emit INFO-level notes, no `status: blocked` output). Copy the exact structure from another phase skill to ensure consistency.
- **Phase 2 slug algorithm documentation:** The algorithm is already implemented in `sdd-ff` and `sdd-new`—this task captures existing behavior, not new logic. No behavior changes are permitted.
- **Verification checkpoints:** After Phase 1 completion, run `/project-audit` to confirm zero MEDIUM findings for the 19 tech skills using variant headings and that `elixir-antipatterns` and `claude-code-expert` pass format checks. After Phase 2 completion, verify that all four files have been modified and that `/sdd-verify` executes without blocking on governance loading.
- **Deployment:** Phase 1 and Phase 2 should be committed separately (`git commit`) to allow independent rollback if needed.

## Blockers

None. All changes are straightforward markdown edits with no external dependencies or behavioral implications.
