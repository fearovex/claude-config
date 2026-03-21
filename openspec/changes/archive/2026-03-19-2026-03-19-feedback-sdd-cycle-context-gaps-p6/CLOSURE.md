# Closure: 2026-03-19-feedback-sdd-cycle-context-gaps-p6

Start date: 2026-03-19
Close date: 2026-03-19

## Summary

Added spec-first Q&A behavior to the orchestrator Question routing pathway and created a new `sdd-spec-gc` maintenance skill for discovering and removing stale requirements from master specs.

## Modified Specs

| Domain | Action | Change |
| --- | --- | --- |
| orchestrator-behavior | Modified | "Direct question is answered inline" requirement updated to include spec-first Q&A behavior |
| orchestrator-behavior | Added | New "Spec-first Q&A for Questions about project domains" requirement with three scenarios |
| spec-garbage-collection | Created | New domain spec defining all GC skill requirements: candidate detection (5 categories), dry-run report, confirmation gate, apply + record steps, project-agnostic mode, context loading |

## Modified Code Files

- `CLAUDE.md` — Question routing section extended with Step 8 (spec-first Q&A); sdd-spec-gc registered in Skills Registry and dispatch table
- `~/.claude/skills/sdd-spec-gc/SKILL.md` — New maintenance skill created
- `docs/SPEC-CONTEXT.md` — New section documenting spec-first Q&A behavior
- `docs/templates/sdd-spec-gc-report-template.md` — New template for GC reports
- `ai-context/architecture.md` — Decision #24 recorded
- `ai-context/changelog-ai.md` — Session entry recorded

## Key Decisions Made

- Spec-first Q&A is inline logic in CLAUDE.md Question routing (not a separate skill/delegation)
- Keyword matching uses stem-based case-insensitive matching against index.yaml keyword arrays; top-3 domain cap
- Contradiction surfacing format: ⚠️ inline with spec ref + REQ-N
- GC skill is a standalone maintenance skill (similar tier to project-audit, project-fix)
- GC detection covers 5 categories: PROVISIONAL, ORPHANED_REF, SUPERSEDED, DUPLICATE, CONTRADICTORY
- GC write mode: dry-run first → 3-option confirmation gate → conditional write
- ORPHANED_REF is best-effort (grep-based); uncertain candidates flagged as UNCERTAIN, not auto-removed
- GC record: `<!-- Last GC: YYYY-MM-DD -->` comment in spec header + changelog-ai.md entry

## Lessons Learned

- The repo copy of sdd-spec-gc (`skills/sdd-spec-gc/SKILL.md`) was not created in this cycle (only runtime `~/.claude/skills/`); this is a sync gap that should be addressed in a follow-up change
- The spec-first Q&A spec (6a) is a behavioral spec update to CLAUDE.md — it was implemented as inline logic per design, avoiding extra skill delegation overhead

## User Docs Reviewed

NO — change does not affect user-facing workflows (internal orchestrator behavior and maintenance tooling only)
