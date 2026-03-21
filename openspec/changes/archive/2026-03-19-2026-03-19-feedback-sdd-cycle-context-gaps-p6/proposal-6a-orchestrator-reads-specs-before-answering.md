# Proposal: Orchestrator Must Read Relevant Specs Before Answering Questions

## Problem Statement

When the user asks a question about existing behavior in a project that has `openspec/specs/`, the orchestrator answers from source code alone — not from the specs. This causes two failure modes:

1. **Answer contradicts spec** — the code may have drift from the spec, and the orchestrator describes the code behavior as authoritative when the spec is the truth
2. **Answer ignores architectural decisions** — decisions documented in specs (e.g., "no mapper layer", "use SP types directly", "provisional pending X") are invisible to the orchestrator unless it reads them

In the observed session, the orchestrator described `handleMarkComplete("welcome")` as valid behavior and explained `toItemType()` as the correct lookup pattern — both of which contradicted archived specs and decisions that were documented but not read.

## Root Cause

The orchestrator (CLAUDE.md) has a rule: "At the start of each session, read relevant ai-context/ files." But it has no rule for reading `openspec/specs/` before answering questions about specific domains.

`openspec/specs/index.yaml` exists precisely to make specs discoverable by domain/keyword — but no skill or rule instructs the orchestrator to use it during Q&A.

## Proposed Solution

Add a rule to the orchestrator (CLAUDE.md) and to the Question routing path:

### Rule: Spec-first Q&A for project domains

Before answering any Question that references a named component, feature, flow, or behavior in a project that has `openspec/specs/index.yaml`:

1. Read `openspec/specs/index.yaml` to find domains whose keywords match the question topic
2. For each matching domain, read `openspec/specs/<domain>/spec.md`
3. Cross-check the answer against spec requirements — if the code behavior contradicts the spec, surface the discrepancy explicitly:
   ```
   ⚠️ Note: The current code does X, but the spec requires Y (openspec/specs/<domain>/spec.md REQ-N).
   This may indicate spec drift or an incomplete implementation.
   ```
4. Answer using spec as the authoritative source, not code

### When this rule applies

- Project has `openspec/specs/index.yaml` (spec index exists)
- Question references a named component, flow, hook, context, or behavior
- At least one domain in the index has keywords that match the question topic

### When this rule does NOT apply

- Project has no `openspec/specs/` directory
- Question is purely architectural ("how does SDD work?") — no project domain match
- Question is about a topic with no spec coverage (no matching domain in index.yaml)

### Keyword matching heuristic

The orchestrator reads `index.yaml` and checks if any domain's `keywords` array contains terms that appear in the user's question. If match found → read that spec. If no match → answer from code as today (no change).

## Success Criteria

- [ ] When user asks "what happens when the welcome video completes?", orchestrator reads `openspec/specs/fy-video-wiring/spec.md` before answering
- [ ] When code behavior contradicts spec, orchestrator surfaces the discrepancy — not just describes the code
- [ ] When user asks about a topic with no spec coverage, behavior is unchanged (no extra reads)
- [ ] Answer accuracy improves for questions about domains with mature specs

## Files to Target

- `CLAUDE.md` (global) — add Rule 8: spec-first Q&A when openspec/specs/index.yaml exists
- Project-level `CLAUDE.md` template — add the same rule as a recommended convention
- `~/.claude/skills/sdd-explore/SKILL.md` — explore already reads specs; this proposal adds the same behavior to the orchestrator's direct Q&A path

## Notes

This rule is additive — it does not change how the orchestrator handles Change Requests or Explorations, only Questions. It is also project-aware: it only triggers when the project has a spec index.
