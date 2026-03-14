# Closure: 2026-03-14-orchestrator-classification-edge-cases

Archived: 2026-03-14
Cycle: sdd-ff → sdd-apply → sdd-verify → sdd-archive

## Summary

Extended the orchestrator's intent classification decision table with 13 edge case examples covering four previously underspecified categories:

1. **Implicit change intent** — messages like "the login is broken" (no explicit fix/add verb) now classify as Change Request via implicit breakage signals ("is broken", "doesn't work", "is wrong", "is missing")
2. **Investigative phrasing** — "check the auth module", "look at the payment flow", "go through the retry logic" classify as Exploration, not Change Request
3. **Questions about broken behavior** — "why does login fail?", "what's wrong with the retry logic?", "is the payment system broken?" remain Question class
4. **Single-word / no-target inputs** — "login", "auth", "refactor" (no codebase target) default to Question

## Outcome

- CLAUDE.md decision table extended with 13 new examples (27 total ✓/✗ lines)
- Change Request trigger pattern updated to include implicit breakage signals
- Runtime deployed via install.sh; confirmed at ~/.claude/CLAUDE.md
- Master spec (openspec/specs/orchestrator-behavior/spec.md) updated with all new requirements and validation criteria

## Verify Verdict

PASS — 14/15 scenarios pass; 1 acknowledged design gap (compound-intent explicit example intentionally absent, covered by structural priority ordering)

## Artifacts

- `CLAUDE.md` — modified (decision table extended)
- `openspec/specs/orchestrator-behavior/spec.md` — updated with delta requirements
- `openspec/changes/archive/2026-03-14-orchestrator-classification-edge-cases/verify-report.md` — PASS
