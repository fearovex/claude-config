# Proposal: Orchestrator Must Pre-populate proposal.md from Conversation Context Before Launching sdd-ff

## Problem Statement

When the orchestrator recommends `/sdd-ff <slug>` and the user confirms, `sdd-propose` generates the proposal from scratch using only the change slug and whatever `sdd-explore` found in the codebase. All context from the conversation — user clarifications, restrictions, prior attempts, decisions made during discussion — is lost.

### Concrete Examples

- User says: "fix expired token redirect, and remove the previous implementation"
  → orchestrator recommends `/sdd-ff fix-expired-token-redirect`
  → user confirms
  → `sdd-propose` creates a proposal about redirecting on 401, with NO mention of removing the prior implementation
  → spec invents a requirement to KEEP the prior implementation

- User says: "make the Mark Complete button do SP write-back, careful with mobile"
  → orchestrator recommends `/sdd-ff fy-mark-complete-sp-writeback`
  → `sdd-propose` creates a proposal about SP write-back with NO mobile constraint
  → no mobile guard implemented

The conversation context exists — the orchestrator is in that conversation — but it never passes it to the sub-agents.

## Root Cause

The orchestrator delegates to `sdd-ff` with only the slug. `sdd-ff` launches `sdd-explore` and `sdd-propose` with minimal context. `sdd-propose` has no pre-existing `proposal.md` to read, so it generates from scratch.

There is no mechanism for the orchestrator to inject conversation-derived context into the SDD cycle before it starts.

## Proposed Solution

### Step: Orchestrator pre-populates proposal.md before launching sdd-ff

When the orchestrator is about to recommend `/sdd-ff <slug>` and the user confirms, the orchestrator MUST:

1. Extract from the current conversation:
   - The user's original request (verbatim or paraphrased)
   - Any clarifications, restrictions, or constraints mentioned ("careful with mobile", "remove the previous implementation", "EWP is not ready yet")
   - Any decisions made during the discussion
   - Any prior attempts mentioned by the user ("I've been trying this for several sessions")

2. Create `openspec/changes/<slug>/proposal.md` with a `## User Context` section pre-populated BEFORE launching sdd-ff:

```markdown
# Proposal: <slug>

## User Context (pre-populated by orchestrator)

**Original request**: "<verbatim user message>"

**Clarifications and constraints**:
- <constraint 1 extracted from conversation>
- <constraint 2 extracted from conversation>

**Explicit removals requested**:
- <artifact the user said should be removed>

**Known restrictions**:
- <e.g., "mobile WebView flows must not be affected">

**Prior attempts (user-reported)**:
- <e.g., "several sessions attempting this, agent keeps preserving old implementation">
```

3. Pass the proposal path to `sdd-ff` so `sdd-propose` reads and enriches it instead of creating from scratch.

### Rule for sdd-propose

`sdd-propose` MUST check if `proposal.md` already exists before writing. If it does:
- Read the `## User Context` section
- Treat every item in it as a hard constraint (not a suggestion)
- Enrich the proposal with technical detail, but NEVER contradict or omit items from `## User Context`

### Rule for sdd-ff orchestrator

The orchestrator MUST pre-populate `proposal.md` when ALL of the following are true:
- The user confirmed the `/sdd-ff` recommendation in the current conversation (not a new session)
- The conversation contains more context than just the slug (clarifications, restrictions, removal requests)

If the user just says `/sdd-ff fix-bug` with no prior conversation context, skip pre-population — there is nothing to inject.

## Success Criteria

- [ ] When user says "fix X and remove Y", proposal.md contains Y in `## Explicit Removals` before sdd-propose runs
- [ ] When user says "careful with mobile", proposal.md contains the mobile constraint before sdd-propose runs
- [ ] `sdd-propose` reads and respects pre-populated User Context — never contradicts it
- [ ] In a re-run of the expired-token session, the proposal would list `usePeriodicMembershipRefresh` as REMOVE from the start
- [ ] In a re-run of the Mark Complete session, the proposal would include the mobile guard constraint

## Files to Target

- `~/.claude/skills/sdd-ff/SKILL.md` — add pre-population step: orchestrator writes proposal.md before launching explore
- `~/.claude/skills/sdd-propose/SKILL.md` — add rule: read existing proposal.md User Context as hard constraints
- `CLAUDE.md` (global) — add orchestrator rule: extract conversation context before confirming sdd-ff launch
