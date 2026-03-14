# Closure: 2026-03-14-specs-as-subagent-background

Start date: 2026-03-14
Close date: 2026-03-14

## Summary

Implemented spec context preload functionality in five SDD phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks) to ensure sub-agents load master specs from `openspec/specs/` as authoritative background context. Updated three master specs with new requirements, created comprehensive documentation, and ensured fallback behavior with self-selection and non-blocking error handling.

## Modified Specs

| Domain   | Action                 | Change        |
| -------- | ---------------------- | ------------- |
| sdd-phase-context-loading | Added | Six new requirements for spec context loading in all five phase skills with 5-scenario coverage for self-selection, fallback, and non-blocking contracts. |
| system-documentation | Added | One new requirement for `docs/SPEC-CONTEXT.md` convention documentation with 9 required sections and 2 discoverable-from-companion-doc scenarios. |
| sdd-orchestration | Modified | Updated by follow-up change "fix-sdd-orchestration-delta-spec" to describe Approach B (phase-skill self-selection) instead of discarded Approach A (orchestrator injection). |

## Modified Code Files

Core implementation:
- `skills/sdd-explore/SKILL.md` — Added Step 0 sub-step for spec context preload
- `skills/sdd-propose/SKILL.md` — Added Step 0c for spec context preload
- `skills/sdd-spec/SKILL.md` — Added Step 0c for spec context preload
- `skills/sdd-design/SKILL.md` — Added Step 0 sub-step for spec context preload
- `skills/sdd-tasks/SKILL.md` — Added Step 0 sub-step for spec context preload

Documentation:
- `docs/SPEC-CONTEXT.md` — Created new convention reference with 9 sections
- `docs/sdd-context-injection.md` — Updated with cross-reference to SPEC-CONTEXT.md

Project artifacts:
- `ai-context/changelog-ai.md` — Recorded change with 8 files modified

## Key Decisions Made

- **Phase-skill self-selection over orchestrator injection (Approach B)**: Chose cleaner separation of concerns where each sub-agent independently loads relevant specs. Reduces orchestrator complexity and allows new phase skills to opt in without modifying the orchestrator.
- **Stem-based matching with hard cap at 3**: Implemented deterministic matching algorithm that splits change slugs into tokens and matches against domain names, with a hard cap at 3 files per sub-agent to balance context richness against prompt size constraints.
- **Non-blocking contract throughout**: All Step 0c implementations treat missing or unreadable spec files as INFO-level events, never blocking phase execution. This ensures graceful degradation when `openspec/specs/` is empty or a project is in early stages.
- **Fallback to self-selection when SPEC CONTEXT absent**: Sub-agents do not require orchestrator injection to function. The self-selection mechanism allows the system to work even if the orchestrator is not modified to include SPEC CONTEXT blocks.

## Lessons Learned

- Design approach convergence timing: The sdd-spec phase authored Approach A requirements before sdd-design finalized Approach B. This divergence was caught and resolved post-verification via a targeted fix, demonstrating the value of verification gates.
- Spec context matters more than ai-context/: Master specs (55 files, precise, domain-organized) provide superior behavioral grounding compared to ai-context/ (high-level summaries). Sub-agents should prefer specs as primary context.
- Documentation conventions prevent future confusion: `docs/SPEC-CONTEXT.md` provides the canonical reference for skill authors, reducing the chance of inconsistent implementations or missed edge cases in future phase skills.

## User Docs Reviewed

NO — change does not affect user-facing workflows. The spec context loading is transparent to end users; it only affects sub-agent prompting and internal SDD infrastructure.
