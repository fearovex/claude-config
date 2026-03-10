# Closure: sdd-project-context-awareness

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Added a mandatory Step 0 — Load project context block to all six SDD phase skills (sdd-explore,
sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply). The block reads four project context
files before any phase analysis begins, ensuring sub-agents produce project-aligned artifacts.
Created docs/sdd-context-injection.md as the canonical reference for skill authors.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| sdd-context-loading | Created | New master spec at openspec/specs/sdd-context-loading/spec.md (5 requirements, 10 scenarios) |

## Modified Code Files

- skills/sdd-explore/SKILL.md — added Step 0 — Load project context block (standard variant)
- skills/sdd-propose/SKILL.md — already had Step 0a + Step 0b (dual-block) before this cycle
- skills/sdd-spec/SKILL.md — already had Step 0a + Step 0b (dual-block)
- skills/sdd-design/SKILL.md — already had Step 0
- skills/sdd-tasks/SKILL.md — already had Step 0
- skills/sdd-apply/SKILL.md — already had Step 0a (sub-section inside Step 0)
- docs/sdd-context-injection.md — created (canonical Step 0 template and reference guide)
- docs/adr/024-sdd-project-context-awareness-convention.md — created (ADR)
- docs/adr/README.md — updated (ADR 024 row added)
- ai-context/architecture.md — updated (decision 11 added)

## Key Decisions Made

- Per-skill Step 0 file reads chosen over Context Capsule (YAML object passed by orchestrator) — simpler, self-contained, no orchestrator changes required.
- Non-blocking contract: missing ai-context/ files emit INFO notes; execution never halts.
- 7-day staleness threshold for Last updated: date check.
- Dual-block structure (Step 0a + Step 0b) for sdd-propose and sdd-spec to preserve their existing domain feature preload step.
- Context Capsule approach deferred to a future change.

## Lessons Learned

- Most of the implementation was already done before this formal SDD cycle was initiated — only sdd-explore needed the Step 0 block. The spec, design, tasks, and verify-report artifacts were missing.
- The proposal described the more ambitious Context Capsule approach; the actual implementation took the simpler per-skill read pattern. Both are valid; the simpler pattern was sufficient for the core goal.

## User Docs Reviewed

YES — docs/sdd-context-injection.md serves as the primary user-facing reference. No changes to
ai-context/scenarios.md, ai-context/quick-reference.md, or ai-context/onboarding.md required.
