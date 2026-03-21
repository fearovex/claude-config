# Proposal: sdd-explore Must Detect Prior Attempts and Context Contradictions (with Hybrid Gate for sdd-ff)

## Problem Statement

This proposal consolidates two related explore failures:

### Failure A — Prior attempts not detected (new session problem)

When a user opens a new session and runs `/sdd-ff` on a topic that was already attempted in previous cycles, `sdd-explore` reads the codebase but does not look at `openspec/changes/archive/` for prior cycles on the same topic. As a result:
- The agent repeats the same approach that already failed
- Restrictions that blocked prior cycles are inherited again silently
- The user must re-explain context they already explained in a previous session

### Failure B — Context contradictions not surfaced (Proposal 4 consolidated here)

`ai-context/changelog-ai.md`, `openspec/specs/`, and `ai-context/features/` often contain notes like:
- "provisional pending EWP"
- "will be replaced when X is ready"
- "temporary scaffold — remove when Y goes live"
- "deferred to follow-up change"

The agent reads these as binding constraints and silently refuses to implement changes that contradict them — without telling the user why.

## Root Cause

`sdd-explore` SKILL.md has no instructions to:
1. Search `openspec/changes/archive/` for prior cycles related to the current topic
2. Search context files for restrictive/provisional notes that conflict with the request

## Proposed Solution

### New Step A: Prior Attempts Scan

Add to `sdd-explore`:

```
Search openspec/changes/archive/ for directories whose name contains keywords from the change slug.
For each match found:
  - Read proposal.md and tasks.md (summary of what was attempted)
  - Note what was completed and what was left pending
  - Note any explicit "deferred" or "out of scope" items

Produce ## Prior Attempts section in exploration.md:

## Prior Attempts

| Cycle | Date | What was done | What was left pending |
|-------|------|--------------|----------------------|
| fy-video-mark-complete-button | 2026-03-19 | Provisional button wired to in-memory state | SP write-back explicitly deferred |
| unify-fy-video-dialog-flow | 2026-03-19 | Dialog unified | "provisional" note preserved |

If no prior attempts found: omit section.
```

### New Step B: Context Contradiction Scan

Add to `sdd-explore`:

```
Search the following for notes that restrict or contradict the requested change:
- ai-context/changelog-ai.md: keywords "provisional", "temporary", "will be replaced",
  "deferred", "pending", "TODO", "when X is ready", "out of scope", "follow-up"
- openspec/specs/<relevant-domain>/spec.md: requirements that protect current behavior
- ai-context/features/<relevant-domain>.md: architectural constraints or deferral notes
- ai-context/known-issues.md: blockers or restrictions related to the topic

Produce ## Context Contradictions section in exploration.md:

## Context Contradictions

| Source | Content | Disposition |
|--------|---------|-------------|
| changelog-ai.md 2026-03-19 | "Provisional button — will be replaced by EWP" | UNCERTAIN |
| fy-video-wiring/spec.md REQ-7 | "Mark Complete is provisional pending EWP" | UNCERTAIN |

Disposition values:
- SUPERSEDED: user's request clearly overrides this (e.g., user said "implement the SP write-back now")
- STILL_APPLIES: constraint is still valid (e.g., user said "keep the mobile guard")
- UNCERTAIN: agent cannot determine from available context — must ask user
```

### Hybrid Gate in sdd-ff (Option C)

Modify `sdd-ff` to check explore output after Step 0:

```
After explore completes, read exploration.md:

IF ## Context Contradictions exists AND any row has Disposition = UNCERTAIN:
  → PAUSE sdd-ff
  → Present contradictions to user:
    "⚠️ Before proposing, I found context that may conflict with your request:
     [table of UNCERTAIN items]
     Do these notes still apply, or does your request supersede them?"
  → Wait for user response
  → Update disposition in exploration.md based on response
  → Then continue to sdd-propose

IF all contradictions are SUPERSEDED or STILL_APPLIES (no UNCERTAIN):
  → Continue to sdd-propose automatically (no gate)
  → sdd-propose reads contradictions and documents them in ## Supersedes Context
```

This preserves the fluidity of sdd-ff in the normal case, and only interrupts when there is genuine ambiguity.

### Rule for sdd-propose

`sdd-propose` MUST read `## Context Contradictions` from `exploration.md`:
- Items marked `SUPERSEDED` → list in `## Supersedes Context` in proposal.md
- Items marked `STILL_APPLIES` → carry forward as constraints into the proposal
- Items marked `UNCERTAIN` → should never reach propose (gate handles them)

## Success Criteria

- [ ] `exploration.md` includes `## Prior Attempts` when archive contains related cycles
- [ ] `exploration.md` includes `## Context Contradictions` when restrictive notes are found
- [ ] `UNCERTAIN` contradictions trigger a pause in sdd-ff before propose launches
- [ ] `SUPERSEDED` contradictions appear in `proposal.md ## Supersedes Context`
- [ ] In a re-run of the Mark Complete session (new session): explore finds the two prior archived cycles and surfaces "SP write-back explicitly deferred" as a prior pending item
- [ ] In a re-run of the Mark Complete session: explore finds "provisional pending EWP" notes and marks them UNCERTAIN, sdd-ff pauses and asks the user

## Files to Target

- `~/.claude/skills/sdd-explore/SKILL.md` — add Prior Attempts scan + Context Contradiction scan steps
- `~/.claude/skills/sdd-ff/SKILL.md` — add hybrid gate: check for UNCERTAIN contradictions after explore, pause if found
- `~/.claude/skills/sdd-propose/SKILL.md` — add: read contradictions from exploration.md, write ## Supersedes Context

## Relationship to Other Proposals

- **Proposal 1** — explore scans branch diff for prior CODE to remove → complementary
- **Proposal 4** — originally proposed contradiction detection → consolidated into this proposal (Proposal 4 is superseded by this one)
- **Proposal 5a** — orchestrator pre-populates proposal.md from conversation → complementary; 5a handles same-session context, this proposal handles cross-session context
