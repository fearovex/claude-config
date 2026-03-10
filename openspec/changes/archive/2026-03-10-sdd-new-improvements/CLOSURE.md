# Closure: sdd-new-improvements

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Improved `sdd-new` and `sdd-ff` orchestrator skills by: (1) automatically inferring the change slug from the user's description — no name-input gate — and (2) making exploration mandatory as the first step in both skills without prompting the user. CLAUDE.md Fast-Forward section was updated to document the new flow.

## Modified Specs

| Domain             | Action  | Change                                                      |
| ------------------ | ------- | ----------------------------------------------------------- |
| sdd-orchestration  | Created | New master spec covering slug inference, mandatory exploration in sdd-new and sdd-ff, and CLAUDE.md alignment |

## Modified Code Files

- `skills/sdd-new/SKILL.md` — Step 0 (slug inference) added; Step 1 (explore) made unconditional; name-input gate removed
- `skills/sdd-ff/SKILL.md` — Step 0 (slug inference + explore) added; name-input gate removed; all subsequent steps renumbered
- `CLAUDE.md` — Fast-Forward section updated to show new 6-step flow with mandatory exploration as Step 0

## Key Decisions Made

- Slug inference is duplicated in both SKILL.md files (not extracted to a utility skill) — acceptable duplication for a simple leaf operation
- Stop word list is hardcoded (stable, self-contained; external config adds complexity without value)
- Exploration gate removed entirely from both orchestrators — mandatory and unconditional removes decision fatigue and ensures code-grounded proposals
- Collision handling uses numeric suffix (`-2`, `-3`) for human-readable slug disambiguation

## Lessons Learned

- Manual integration tests (5.2–5.4) could not be automated; verified correctness via code inspection of explicit algorithm in SKILL.md files
- Tasks 6.1 (install.sh) and 6.2 (git commit) remain as post-archive housekeeping — follow the convention `install.sh → git commit`

## User Docs Reviewed

N/A — pre-dates this requirement
