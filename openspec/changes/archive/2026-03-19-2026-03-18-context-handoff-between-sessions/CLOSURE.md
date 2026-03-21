# Closure: 2026-03-18-context-handoff-between-sessions

Start date: 2026-03-18
Close date: 2026-03-19

## Summary

Added Unbreakable Rule 6 to CLAUDE.md requiring the orchestrator to seed a `proposal.md` before recommending a `/sdd-ff` that will execute in a new session. Updated `sdd-explore` Step 0 with a non-blocking sub-step that reads the pre-seeded `proposal.md` when present, enriching the exploration scope without overriding codebase findings.

## Modified Specs

| Domain   | Action   | Change        |
| -------- | -------- | ------------- |
| N/A      | N/A      | No delta specs — change was documentation/convention only |

## Modified Code Files

- `CLAUDE.md` (repo) — added Unbreakable Rule 6: Cross-session ff handoff
- `skills/sdd-explore/SKILL.md` — added Step 0 sub-step: Handoff context preload
- `~/.claude/CLAUDE.md` (deployed via install.sh)
- `~/.claude/skills/sdd-explore/SKILL.md` (deployed via install.sh)

## Key Decisions Made

- Rule 6 is triggered only when user explicitly defers a `/sdd-ff` to a new session (trigger signals: "new session", "next chat", "context reset", or context compaction imminent). Same-session cycles are explicitly excluded.
- The pre-seeded `proposal.md` is consumed by `sdd-explore` as supplemental intent context, not a final proposal. `sdd-propose` may overwrite it with a proper proposal built from exploration findings — this is by design.
- No dedicated `/context-handoff` skill was created; Rule 6 in CLAUDE.md is sufficient. A new skill would add friction for what is an orchestrator behavioral convention.
- `sdd-propose` was not modified — the handoff context reaches it indirectly via `exploration.md`.

## Lessons Learned

The change itself was proof of the gap it addressed: the originating session manually seeded a `proposal.md` that enabled the explore phase to orient correctly. Formalizing this as a rule ensures the pattern is repeatable and not accidental.

## User Docs Reviewed

N/A — pre-dates this requirement or change does not affect user-facing workflows in scenarios.md / quick-reference.md / onboarding.md.

Skipped phases: spec
