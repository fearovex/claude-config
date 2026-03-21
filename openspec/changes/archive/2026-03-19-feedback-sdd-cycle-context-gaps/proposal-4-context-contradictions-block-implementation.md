# Proposal: SDD Cycles Must Detect and Surface Context Contradictions Before Implementing
> ⚠️ SUPERSEDED — This proposal has been consolidated into proposal-5b-explore-must-detect-prior-attempts-and-contradictions.md, which includes contradiction detection + prior attempts scan + the hybrid gate for sdd-ff (Option C). Implement 5b instead of this one.

## Problem Statement

When a user requests a change, the SDD cycle sometimes silently fails to implement it because `ai-context/` files, `changelog-ai.md`, or archived specs contain notes that contradict the request. The agent reads those notes as business rules and treats them as constraints — blocking the implementation without telling the user why.

### Concrete Example

The user requested: "Make the Mark Complete button do the real SharePoint write-back instead of simulating state in memory."

The agent did NOT implement this because:
- `changelog-ai.md` says: *"Provisional button (no watch-time gate) — will be replaced by EWP automatic completion"*
- `changelog-ai.md` says: *"The Mark Complete button will be removed/hidden when EWP integration goes live"*
- Archived spec `fy-video-wiring` likely has a requirement protecting the provisional behavior

The agent read "will be replaced by EWP" as "do not implement SP write-back until EWP is ready", and silently preserved the old in-memory simulation — even though the user explicitly asked for the SP write-back NOW, as a temporary state until EWP is ready.

The agent implemented adjacent changes (dialog unification, etc.) without ever telling the user: "I didn't add the SP write-back because the spec says this is provisional pending EWP."

## Root Cause

`sdd-explore` and `sdd-propose` do not have a step that:
1. Searches `ai-context/`, `changelog-ai.md`, and `openspec/specs/` for notes that contradict or restrict the requested change
2. Surfaces those contradictions explicitly to the user: "I found X that says Y — does your request supersede this?"
3. Waits for user confirmation before treating those notes as constraints

Instead, the agent silently inherits all prior context as immutable constraints.

## Proposed Solution

Add a **Contradiction Detection** step to `sdd-explore`:

**Step: Prior context contradiction scan**

Search the following for content that restricts or contradicts the user's stated intent:
- `ai-context/changelog-ai.md` — look for "provisional", "temporary", "will be replaced", "deferred", "pending X", "TODO", "when X is ready"
- `ai-context/known-issues.md` — look for constraints or blockers related to the topic
- `openspec/specs/<relevant-domain>/spec.md` — look for requirements that protect current behavior
- `ai-context/features/<relevant-domain>.md` — look for architectural constraints

Produce a `## Context Contradictions` section in `exploration.md` with:

```markdown
## Context Contradictions

The following prior context may conflict with the requested change:

| Source | Location | Content | Disposition |
|--------|----------|---------|-------------|
| changelog-ai.md | 2026-03-19 fy-video-mark-complete-button | "Provisional button — will be replaced by EWP" | SUPERSEDED_BY_THIS_REQUEST |
| fy-video-wiring/spec.md | REQ-7 | "Mark Complete is provisional pending EWP integration" | SUPERSEDED_BY_THIS_REQUEST |
```

Disposition values:
- `SUPERSEDED_BY_THIS_REQUEST` — user's current request explicitly overrides this note
- `STILL_APPLIES` — constraint is still valid and should be respected
- `UNCERTAIN` — agent cannot determine; must ask user before proceeding

**Rule:** The agent MUST NOT treat a prior note as a binding constraint without surfacing it. If disposition is `UNCERTAIN`, the explore summary must ask the user to clarify before propose proceeds.

Additionally, `sdd-propose` must read `## Context Contradictions` from `exploration.md` and:
- Include a `## Supersedes Context` section listing all `SUPERSEDED_BY_THIS_REQUEST` items
- Explicitly state: "The following prior notes are no longer binding for this change"

## Success Criteria

- [ ] `exploration.md` always includes `## Context Contradictions` when prior context contains restrictive notes relevant to the topic
- [ ] `UNCERTAIN` items trigger a user confirmation gate before propose proceeds
- [ ] `proposal.md` includes `## Supersedes Context` listing overridden prior notes
- [ ] The agent never silently inherits a "provisional/deferred/pending" note as a constraint
- [ ] In a re-run of the SP write-back request, the agent surfaces the "provisional" notes and asks: "Your request supersedes these — shall I proceed with the SP write-back now?"

## Files to Target

- `~/.claude/skills/sdd-explore/SKILL.md` — add contradiction detection step
- `~/.claude/skills/sdd-propose/SKILL.md` — add Supersedes Context section, read from exploration contradictions
- `~/.claude/skills/sdd-ff/SKILL.md` — add note: if explore returns UNCERTAIN contradictions, pause before launching propose and ask user

## Notes

This proposal is distinct from Proposal 1 (branch-local implementation scan). That proposal finds prior CODE. This proposal finds prior CONTEXT NOTES (changelog entries, spec requirements, architectural decisions) that restrict what the agent is willing to implement.

Both are needed: Proposal 1 handles "what code exists that should be removed", this proposal handles "what documented constraints exist that should be overridden".
