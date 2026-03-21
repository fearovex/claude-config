# ADR-037: Cross-Session FF Handoff Convention — Orchestrator Seeds proposal.md Before Deferring to New Session

## Status

Proposed

## Context

When the orchestrator recommends a `/sdd-ff` cycle that the user will run in a new session (due to context compaction or explicit deferral), the next session's `sdd-explore` sub-agent starts cold — it has no record of the conversational reasoning that motivated the change. The explore phase runs without the "why" and the constraints from the originating session, producing generic exploration output that loses the original intent. The existing Rule 5 (Feedback persistence) addresses the analogous case for feedback sessions, but the common mid-conversation deferral case is not covered. The `sdd-explore` Step 0 already has an established non-blocking sub-step pattern (spec context preload) that reads supplemental context before investigation begins — this pattern can be extended to consume a pre-seeded proposal.md.

## Decision

We will introduce a two-part convention:

1. **Rule 6 in CLAUDE.md Unbreakable Rules (supply side)**: When recommending a `/sdd-ff` that the user will run in a new session, the orchestrator MUST first create `openspec/changes/<slug>/proposal.md` capturing the decision rationale, goal, explore targets, and constraints. The rule includes the proposal path in the recommendation and offers to run `/memory-update`. The rule does NOT apply to same-session `/sdd-ff` cycles.

2. **sdd-explore Step 0 sub-step — Handoff context preload (demand side)**: Before investigating the codebase, `sdd-explore` checks for a pre-seeded `openspec/changes/<slug>/proposal.md`. If present, it reads the file and treats it as supplemental intent enrichment — informing what to prioritize, without overriding live codebase findings. The loaded context is surfaced as a `## Handoff Context` section at the top of `exploration.md`. If absent, the sub-step skips silently (INFO note only). The sub-step is non-blocking.

The existing `proposal.md` artifact type is reused — no new artifact type is introduced. `sdd-propose` will overwrite the seeded proposal.md with its synthesized output, which is acceptable: the seeded file's value is consumed by explore before propose runs.

## Consequences

**Positive:**

- The "cold explore" gap is closed: intent from the originating session is directly consumed by the explore sub-agent in the new session.
- Additive-only change: no existing behaviors are modified or removed; Rule 6 is scoped to explicit cross-session signals only.
- Consistent with established patterns: mirrors Rule 5 (Feedback persistence) on the supply side and the Spec context preload sub-step pattern on the demand side.
- The proposal.md artifact type already exists — no new conventions to learn or enforce.

**Negative:**

- Rule 6 depends on orchestrator judgment to detect the cross-session signal ("new session", "next chat", context compaction) — imprecise triggers may cause over-application or under-application.
- The seeded proposal.md is overwritten by sdd-propose; if the originating session's context needs to be preserved long-term, it must be in `ai-context/changelog-ai.md` separately.
- Two files must be kept in sync after apply: `CLAUDE.md` (repo) and `~/.claude/CLAUDE.md` (runtime), mediated by `install.sh`.
