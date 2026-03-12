# Proposal: Orchestrator Always-On Behavior

## Problem Statement

Currently the orchestrator only activates when the user explicitly invokes slash commands (`/sdd-ff`, `/project-audit`, etc.). For any free-form request ("review this code", "fix this bug", "explain this feature"), Claude responds directly without applying SDD discipline — delegating to sub-agents, following the phase DAG, or applying the skills catalog.

This means the SDD system is only as good as the user's memory of which command to type.

## Proposed Solution

Add an **intent classification step** at the start of every conversation turn. Before responding to any user message, Claude (as orchestrator) must:

1. **Classify the intent** — is this a question, a change request, an exploration, or a meta-command?
2. **Map to the appropriate SDD phase or behavior**:
   - Change request / feature / bug fix → recommend `/sdd-ff` or `/sdd-new`
   - Exploration / "explain this" / "review this" → trigger `sdd-explore` behavior
   - Question about the system → answer directly
   - Slash command → execute as today
3. **Never execute implementation work directly** — always delegate via Task tool or recommend the appropriate SDD command

### Concrete behavior change

| User says | Current behavior | New behavior |
|-----------|-----------------|--------------|
| "fix this bug" | Claude fixes it inline | Orchestrator proposes `/sdd-ff fix-<slug>` or launches explore + propose |
| "review this code" | Claude reviews inline | Orchestrator launches `sdd-explore` sub-agent |
| "add feature X" | Claude writes code | Orchestrator proposes `/sdd-ff feature-x` |
| "explain this file" | Claude explains inline | Claude explains inline (questions are fine direct) |
| `/sdd-ff change` | Executes SDD ff | Same — no change |

### Implementation approach

Update `CLAUDE.md` (global) with an explicit **"Always-On Orchestrator"** section that defines:
- The intent classification rules
- The mapping table (intent → action)
- The rule: "I never write implementation code or specs inline — I always delegate or recommend an SDD command"

## Success Criteria

- [ ] CLAUDE.md has an "Always-On Orchestrator" section with intent classification rules
- [ ] For any change/bug/feature request, Claude recommends or launches the appropriate SDD phase
- [ ] Claude never writes implementation code inline (always delegates via Task tool)
- [ ] Questions and explanations are still answered directly (no over-engineering)
- [ ] Behavior is consistent across projects — both with and without a local CLAUDE.md
