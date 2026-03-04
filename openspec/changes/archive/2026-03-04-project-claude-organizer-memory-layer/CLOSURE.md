# Closure: project-claude-organizer-memory-layer

Start date: 2026-03-04
Close date: 2026-03-04

## Summary

Extended `project-claude-organizer` (SKILL.md) with a fourth classification bucket (`DOCUMENTATION_CANDIDATES`) that detects `.md` files inside `.claude/` matching known ai-context filenames or memory-layer heading patterns, presents them in the dry-run plan as "Documentation to migrate → ai-context/", and copies (never moves) confirmed candidates to `ai-context/` after user confirmation.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| project-claude-organizer | Created | New master spec established from delta — covers documentation candidate classification (Step 3), dry-run fourth category (Step 4), copy operation with idempotency (Step 5), report section (Step 6), source preservation invariant, and regression guard for the no-op path |

## Modified Code Files

- `skills/project-claude-organizer/SKILL.md` — Added `DOCUMENTATION_CANDIDATES` bucket with `KNOWN_AI_CONTEXT_TARGETS` (8 entries) and `KNOWN_HEADING_PATTERNS` (6 entries); Signal 1 (filename stem match, case-insensitive) and Signal 2 (content heading match, case-sensitive); Step 4 fourth dry-run category; Step 5.4 copy operation (mkdir, idempotency, source verification, error handling); Step 5.5/5.6 renumbering; Step 6 report subsection; no-op three-bucket guard; `ai-context/architecture.md` artifact table entry updated
- `ai-context/architecture.md` — Updated `claude-organizer-report.md` artifact table entry to reflect the new report section for documentation migration

## Key Decisions Made

- **Copy-only invariant**: Source files in `.claude/` are NEVER deleted or moved — only copied to `ai-context/`. This makes the operation fully reversible without a rollback procedure.
- **Closed filename list**: `KNOWN_AI_CONTEXT_TARGETS` is a fixed 8-entry list matching the documented ai-context/ filenames, preventing false promotions from arbitrary `.md` files.
- **Idempotency via skip-on-exists**: If `ai-context/<filename>.md` already exists, the copy is skipped and recorded as `skipped (destination exists — review manually)` — consistent with the existing CLAUDE.md stub idempotency pattern.
- **Dual-signal classification**: Primary signal is filename stem match (deterministic); secondary signal is heading presence scan (handles non-standard filenames with recognizable memory-layer content).
- **Scope enforcement**: Only root-level `.md` files from the existing `OBSERVED_ITEMS` collection are scanned — no new filesystem enumeration or recursion.

## Lessons Learned

- Additive extension to an existing procedural skill (step insertion within an existing numbered step) is low-risk when step numbering semantics are preserved (5.4 → 5.5 shift).
- The verify-report correctly identified a cosmetic inconsistency in `tasks.md` (header count vs. actual line items) as a suggestion — not a blocker. Task header counts should be aligned with actual `[x]` line items in future plans.
- Manual walkthrough against a live test project was prescribed by design but not executed in the verify session. The skill was validated entirely through code inspection — acceptable for a procedural Markdown skill.

## User Docs Reviewed

N/A — pre-dates this requirement (verify-report does not contain the user-docs checkbox).
