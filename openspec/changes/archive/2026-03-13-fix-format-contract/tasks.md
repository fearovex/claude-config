# Task Plan: 2026-03-13-fix-format-contract

Date: 2026-03-13
Design: openspec/changes/2026-03-13-fix-format-contract/design.md

## Progress: 5/5 tasks

## Phase 1: Documentation Update

- [x] 1.1 Update `docs/format-types.md` lines 112–116 (reference format table) to expand "Accepted headings" column from `## Patterns`, `## Examples` to include variants `## Critical Patterns`, `## Code Examples` with explanation that each pair (standard + variant) satisfies the requirement ✓
- [x] 1.2 Update `docs/format-types.md` lines 255–261 (quick-reference table) to update the `reference` row to list all four accepted headings: `## Patterns`, `## Examples`, `## Critical Patterns`, `## Code Examples` ✓
- [x] 1.3 Add explanatory note after the quick-reference table clarifying that variant names (`## Critical Patterns`, `## Code Examples`) are approved for externally-sourced skills from Gentleman-Skills corpus, and that custom project skills created via `skill-creator` continue to use standard names ✓

## Phase 2: Validation Logic Update

- [x] 2.1 Update `~/.claude/skills/project-audit/SKILL.md` Dimension 4b (Skills Quality — Structural Format Compliance) validation logic to accept variant section headings for reference format: implement regex pattern matching to recognize both `## Patterns` and `## Critical Patterns` as valid pattern sections, AND both `## Examples` and `## Code Examples` as valid examples sections ✓
- [x] 2.2 Update `~/.claude/skills/project-audit/SKILL.md` Dimension 4b finding message to be more descriptive: change from `"reference skill [name] missing ## Patterns or ## Examples section"` to `"reference skill [name] missing (## Patterns or ## Critical Patterns) or (## Examples or ## Code Examples) section"` ✓
- [x] 2.3 Verify D4b validation also accepts `## Critical Patterns` as a variant for anti-pattern format (in addition to reference format), and update the anti-pattern row if needed to reflect that `## Critical Patterns` satisfies the anti-pattern requirement alongside `## Anti-patterns` ✓

## Implementation Notes

- **Semantic equivalence**: `## Critical Patterns` is semantically equivalent to `## Patterns`; `## Code Examples` is equivalent to `## Examples`. These variants exist in externally-sourced, high-quality reference documentation.
- **Regex pattern for validation**: Use alternation patterns like `^## (Patterns|Critical Patterns)` and `^## (Examples|Code Examples)` with case-sensitive matching (Markdown headings are case-sensitive).
- **Both conditions must be true**: A reference skill must have at least one pattern section (standard OR variant) AND at least one examples section (standard OR variant) to pass the D4b check.
- **Affected skills count**: 21 globally-sourced skills (20 reference format, 1 anti-pattern format) will transition from D4b MEDIUM findings to pass after this change.

## Blockers

None. All artifacts (exploration, proposal, spec, design) are complete and unambiguous. The change is purely documentation + validation logic with no external dependencies.
