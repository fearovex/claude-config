# Closure: 2026-03-14-fix-sdd-orchestration-delta-spec

Start date: 2026-03-14
Close date: 2026-03-14

## Summary

Corrected the `sdd-orchestration` delta spec in the `specs-as-subagent-background` change to accurately describe the Approach B (phase-skill self-selection) implementation instead of the discarded Approach A (orchestrator injection) requirements. This resolved three PARTIAL entries in the verification report.

## Modified Specs

| Domain   | Action                 | Change        |
| -------- | ---------------------- | ------------- |
| sdd-orchestration | Modified | Replaced Approach A requirements with one Approach B requirement: "Orchestrators do not inject spec context — phase skills self-select". Added 5 scenarios covering absence-of-injection contract and self-selection behavior. |

## Modified Code Files

- `openspec/specs/sdd-orchestration/spec.md` — master spec updated to include new MODIFIED requirement
- `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` — delta spec rewritten (now archived with parent change)
- `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` — updated to show PASS with no warnings (3 PARTIAL rows changed to COMPLIANT)

## Key Decisions Made

- **Approach B as the authoritative design**: Recognized that the design phase chose phase-skill self-selection over orchestrator injection, and the implementation is already correct. The delta spec needed to match the design decision.
- **Absence contract in master spec**: Added a MODIFIED requirement to the master spec describing what the orchestrator domain constrains (no injection), not just what it does (which is unchanged).
- **No SKILL.md changes**: The implementation was already correct and complete — only documentation needed correction.

## Lessons Learned

- Design and spec phases can diverge when authored sequentially. The sdd-spec phase was authored before sdd-design finalized the approach.
- Approach A (orchestrator injection) vs Approach B (phase-skill self-selection) — both are technically valid, but Approach B was chosen for cleaner separation of concerns and simpler orchestrator logic.
- The verify-report correctly identified the divergence through PARTIAL entries, enabling a targeted fix rather than discovering the issue later.

## User Docs Reviewed

N/A — change does not affect user-facing workflows (internal specification correction only).
