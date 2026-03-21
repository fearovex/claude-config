# Exploration: Context Handoff Between Sessions

## Current State

The system has no mechanism for persisting the conversational context that informed an orchestrator recommendation when a `/sdd-ff` cycle will execute in a new session.

### What exists

**Context persistence layer (ai-context/):**
- `ai-context/changelog-ai.md` — session-level log of changes; manually updated via `/memory-update`
- `ai-context/architecture.md`, `stack.md`, `conventions.md` — static project knowledge
- No field captures "pending change intent" or "why this change was decided"

**SDD artifact layer (openspec/changes/):**
- `openspec/changes/<slug>/proposal.md` — written by `sdd-propose` as part of the ff cycle
- `openspec/changes/<slug>/exploration.md` — written by `sdd-explore` as Step 0 of the ff cycle
- Both are written *after* `/sdd-ff` is triggered, not *before* — they live inside the cycle, not outside it

**CLAUDE.md orchestrator rules:**
- Unbreakable Rule 5 (Feedback persistence): orchestrator MUST write `proposal.md` before any SDD cycle in feedback sessions
- No equivalent rule for cross-session ff handoff
- Fast-Forward section describes the ff flow (Steps 0–6) but has no "pre-flight" step for handoff context

**sdd-ff SKILL.md:**
- Step 0: infer slug + launch sdd-explore (no user gate)
- Step 1: launch sdd-propose (reads `exploration.md`)
- No step reads a pre-existing `proposal.md` if one was seeded manually before the cycle

**sdd-explore SKILL.md:**
- Step 0: reads `ai-context/stack.md`, `architecture.md`, `conventions.md`, project `CLAUDE.md`
- Step 0 sub-step: reads matching spec files from `openspec/specs/`
- No step reads a pre-existing `proposal.md` in the change directory before investigating

### The gap

When the orchestrator recommends `/sdd-ff fix-foo` and the user runs it in a new session:
1. The new session starts with only ai-context/ and CLAUDE.md — no record of the conversational reasoning
2. `sdd-explore` runs cold, without the "why" or the constraints from the originating session
3. `sdd-propose` synthesizes from exploration alone — it cannot recover the original decision context

The `proposal.md` written by the feedback-session Rule 5 pattern *does* address this — but only for explicit feedback sessions. The common case (orchestrator recommends a fix mid-conversation, user defers to a new session) is not covered.

## Affected Areas

| File/Module | Impact | Notes |
| --- | --- | --- |
| `CLAUDE.md` (global + repo) | High | New rule added: cross-session ff handoff gate |
| `skills/sdd-ff/SKILL.md` | Medium | Step 0 gains a "read proposal.md if present" sub-step before launching explore |
| `skills/sdd-explore/SKILL.md` | Low–Medium | Step 0 gains a sub-step: read `openspec/changes/<slug>/proposal.md` if it exists before investigation |
| `openspec/changes/2026-03-18-context-handoff-between-sessions/proposal.md` | Reference | Already seeded by the originating session — this is the artifact the new rule produces |

## Analyzed Approaches

### Approach A: CLAUDE.md rule only (no skill changes)

**Description**: Add Unbreakable Rule 6 to CLAUDE.md: when a `/sdd-ff` recommendation is for a new session, the orchestrator MUST first write a `proposal.md` in the change directory with decision context, then remind the user. No changes to sdd-ff or sdd-explore skills.

**Pros**:
- Minimal footprint — one file change
- Consistent with the existing feedback-session rule pattern (Rule 5 analogy)
- Behavior is already partially working: this very change has a seeded `proposal.md`

**Cons**:
- sdd-explore still ignores the pre-seeded `proposal.md` — the explore sub-agent won't use it
- sdd-ff ignores it too — propose will overwrite it if sdd-propose creates a new proposal.md
- Low enforcement: depends on orchestrator reading and following the rule; no structural guard

**Estimated effort**: Low
**Risk**: Low (additive rule only, no skill changes)

---

### Approach B: CLAUDE.md rule + sdd-explore reads pre-seeded proposal.md

**Description**: Add Rule 6 to CLAUDE.md AND update `sdd-explore` Step 0 to check for `openspec/changes/<slug>/proposal.md`. If present, treat it as **supplemental intent context** (not authoritative over what the codebase shows). The explore investigation still runs fully, but the proposal's constraints and goals orient the analysis.

**Pros**:
- Closes the "cold explore" gap — the pre-seeded context is actually consumed
- Non-destructive: existing explore logic unchanged; proposal.md is input enrichment only
- Consistent with the spec-context preload pattern (Step 0 sub-step model is already established)

**Cons**:
- Two-file change (CLAUDE.md + sdd-explore/SKILL.md)
- sdd-propose still creates its own proposal.md — the seeded one may be overwritten

**Estimated effort**: Low–Medium
**Risk**: Low (non-blocking, additive sub-step)

---

### Approach C: CLAUDE.md rule + sdd-explore reads proposal.md + sdd-ff preserves pre-seeded proposal.md

**Description**: Full approach — Rule 6 in CLAUDE.md, sdd-explore reads proposal.md, AND sdd-ff Step 1 (propose phase) gains a guard: if `openspec/changes/<slug>/proposal.md` already exists and contains a non-template marker (e.g. `## Context for Next Session`), the propose sub-agent is instructed to ENRICH rather than REPLACE it.

**Pros**:
- Complete end-to-end handoff: context is seeded, consumed by explore, and preserved through propose
- The pre-seeded `proposal.md` is not overwritten — the originating session's intent survives

**Cons**:
- Three-file change (CLAUDE.md + sdd-explore + sdd-ff/sdd-propose)
- More complex: propose must detect pre-existing proposals and switch to enrich mode
- Risk of corner cases: what if the seeded proposal is incomplete or wrong?

**Estimated effort**: Medium
**Risk**: Medium (sdd-ff orchestration change)

---

### Approach D: New skill — `context-handoff` explicit command

**Description**: Create a `/context-handoff <slug>` skill that the orchestrator calls before closing a session with a pending ff recommendation. The skill writes a structured handoff artifact and updates changelog-ai.md.

**Pros**:
- Explicit, discoverable action — user knows a handoff was created
- Does not touch existing skills

**Cons**:
- Friction: requires users to know and remember to call it
- Adds a skill for what is essentially an orchestrator behavior rule
- Over-engineered for the problem size

**Estimated effort**: Medium
**Risk**: Low (isolated skill)

## Recommendation

**Approach B** — CLAUDE.md rule + sdd-explore reads pre-seeded proposal.md.

Rationale:
- The core gap is that `sdd-explore` runs cold. Approach B closes this gap directly and cheaply.
- Rule 6 in CLAUDE.md creates the supply side (seeded proposal.md). The sdd-explore change creates the demand side (consumes it). Together they form a closed loop.
- Approach C's sdd-ff/propose enrichment logic adds complexity with unclear ROI: the seeded proposal's primary value is consumed by explore, not by propose (which rewrites it from exploration findings anyway).
- Approach A alone is insufficient — the rule exists but the artifact is never used.
- Approach D adds unnecessary friction and a new skill for what is an orchestrator-level behavioral convention.

**Scope of changes:**
1. `CLAUDE.md` (global + repo): Add Rule 6 — Cross-session ff handoff
2. `skills/sdd-explore/SKILL.md`: Add sub-step to Step 0 — read pre-seeded `proposal.md` if present as intent context

The rule in CLAUDE.md should specify:
- Trigger condition: orchestrator recommends a `/sdd-ff` the user will run in a new session (explicit signal: "in a new session", "when context resets", or context compaction imminent)
- Required action: create `openspec/changes/<slug>/proposal.md` before closing the recommendation
- Required content: decision rationale, specific goal, explore targets, constraints/do-not-do items
- Reminder: suggest `/memory-update` and include the proposal path in the recommendation

## Identified Risks

- **sdd-propose overwrites pre-seeded proposal.md**: If sdd-propose creates a new `proposal.md`, the originating session's context is lost. Mitigation: document in the rule that the seeded proposal is input to explore, not to propose — explore's output is what propose consumes. The seeded proposal is advisory context, not the final proposal.md. (Low risk — propose reads from exploration.md, not proposal.md at its current implementation.)
- **Rule clarity — when does the handoff trigger?**: "Will run in a new session" is subjective. The rule must have a specific signal (explicit user statement or compaction warning). Ambiguous trigger could cause over-application. Mitigation: spec must define trigger signals precisely.
- **Two CLAUDE.md files to update**: Both `~/.claude/CLAUDE.md` (runtime) and `claude-config/CLAUDE.md` (repo) must stay in sync. install.sh handles this, but the SDD apply step must target the repo file.

## Open Questions

- Should the seeded `proposal.md` survive after `sdd-propose` runs? Currently sdd-propose would overwrite it. Options: (a) accept overwrite — explore already consumed the context; (b) rename seeded file to `handoff-context.md` to avoid collision; (c) sdd-propose reads and merges. Recommended: (a) — simple, already sufficient.
- Should the sdd-explore sub-step emit the proposal content in exploration.md under a "Handoff context" section? This would make the intent visible in explore output and ensure sdd-propose consumes it indirectly.

## Ready for Proposal

Yes — `proposal.md` is already seeded in this change directory by the originating session. It accurately captures the decision context and success criteria. The sdd-propose phase should enrich it rather than replace it from scratch.
