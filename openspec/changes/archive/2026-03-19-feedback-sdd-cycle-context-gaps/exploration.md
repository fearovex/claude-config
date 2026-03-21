# Exploration: SDD Cycle Context Gaps — System Failures in Handling Replacements and Contradictions

> **Type**: Feedback session — exploring multiple interconnected system failures in the SDD orchestrator and phase skills.

## Current State

The `agent-config` project implements the Claude Code SDD meta-system: a specification-driven development workflow that guides Claude through exploration, proposal, specification, design, task breakdown, and implementation. The orchestrator coordinates phase execution; phase skills define the mechanics of each step.

During recent sessions, three critical failures emerged when users requested changes that:
1. Replaced prior implementations on the current branch
2. Contradicted documented constraints in ai-context or archived specs
3. Required explicit removal of prior artifacts, not just addition of new ones

### Concrete Failures Observed

**Session 1 (Auth flow replacement):**
- User: "Redirect to login on 401, and remove the periodic membership refresh hook"
- `sdd-explore`: Found the current auth flow but did NOT identify `usePeriodicMembershipRefresh` as a prior implementation
- `sdd-propose`: Generated a proposal about redirecting, with zero mention of removing the hook
- `sdd-spec`: Invented a requirement to KEEP the hook ("Membership Polling Unaffected")
- User had to argue against their own specs to get the removal they requested

**Session 2 (Mark Complete button):**
- User: "Make the Mark Complete button do SharePoint write-back instead of in-memory simulation"
- `sdd-explore`: Did NOT surface prior context notes saying "provisional pending EWP integration"
- `sdd-propose`: Omitted mobile constraints that user mentioned in conversation
- Result: Agent silently refused to implement because specs protected the provisional behavior; user never learned why

**Session 3 (Cross-session repeat):**
- User (new session): "Implement feature X"
- `sdd-explore`: Did NOT check `openspec/changes/archive/` for prior failed attempts on feature X
- Outcome: Agent repeated the same approach that already failed in a previous cycle

## Affected Areas

| System | Issue | Scope |
|--------|-------|-------|
| `sdd-explore` SKILL.md | No branch-local diff scan; no prior attempts detection; no context contradiction scan | Blocks all three failures |
| `sdd-propose` SKILL.md | No `## Supersedes` section in proposal template; cannot enumerate removals; no rule to preserve conversation context | Blocks failures 1 & 2 |
| `sdd-ff` SKILL.md | No pre-population of proposal.md before launching explore; no gate for UNCERTAIN contradictions | Blocks failures 1 & 2 |
| `sdd-spec` SKILL.md | No rule preventing unconfirmed preservation requirements; no cross-check against Supersedes section | Blocks failure 1 |
| `sdd-tasks` SKILL.md | No rule to generate removal tasks from Supersedes section | Supports failure 1 |
| `CLAUDE.md` (global) | Orchestrator has no instruction to extract conversation context before confirming /sdd-ff launch | Blocks failure 2 |

## Analyzed Approaches

### Approach A: Six Separate Targeted Fixes

**Description**: Implement each of the six feedback proposals as independent changes, updating one skill at a time.

**Pros:**
- Smallest scope per change; easiest to review each proposal individually
- Allows phased rollout if some fixes are more urgent

**Cons:**
- High coordination cost: changes are tightly coupled (explore output feeds propose, propose output feeds spec, etc.)
- Risk of inconsistent artifact contracts (e.g., spec expects Supersedes section but propose never writes it)
- Testing each in isolation misses integration failures

**Estimated effort**: High (six separate SDD cycles, six separate applies, six separate archival steps)
**Risk**: High (integration regressions between loosely coordinated changes)

### Approach B: Consolidate into Two Phases

**Description**:
- **Phase 1**: sdd-explore + sdd-propose + sdd-spec improvements (Proposals 1, 2, 3, 4/5b, and spec-level fixes)
- **Phase 2**: sdd-ff + orchestrator conversation context handling (Proposals 5a + orchestrator rule injection)

**Pros:**
- Splits the work into logically coherent bundles
- Phase 1 concentrates on artifact generation and contract fixing
- Phase 2 adds the upstream conversation bridge
- Each phase can be tested end-to-end within its scope

**Cons:**
- Phase 1 alone leaves the system partially broken (proposal.md exists but orchestrator never pre-populates it)
- Phase 2 has a hard dependency on Phase 1 contracts being settled first

**Estimated effort**: Medium–High (two SDD cycles with 3–4 skills each)
**Risk**: Medium (manageable if Phase 1 artifacts are clearly specified before Phase 2 starts)

### Approach C: Unified SDD Cycle for All Proposals (Recommended)

**Description**:
- Create a single `/sdd-ff context-gaps-system-overhaul` or similar change
- The proposal consolidates all six feedback items as part of one architectural overhaul
- Spec defines the unified artifact contracts: proposal.md structure, exploration.md sections, proposal/spec/task flow
- Design provides a unified skill-update plan
- Tasks break down all six skill files and CLAUDE.md in dependency order
- Apply executes all updates in a single coordinated batch
- Verify checks that all skills work together correctly

**Pros:**
- Forces unified artifact contract design upfront (no integration surprises)
- Guarantees coordinated rollout: all skills updated together, all tested together
- Single archive step ensures the full system is coherent
- Clearer narrative: "context gaps overhaul" as one architectural change

**Cons:**
- Largest single change to the system at once
- Requires careful sequencing in apply phase (propose updates must finalize before spec/tasks)
- Higher stakes if something goes wrong (but easier to rollback as one unit)

**Estimated effort**: Medium (one SDD cycle, but tasks are extensive; apply needs orchestration)
**Risk**: Low–Medium (unified contracts reduce integration risk; careful apply sequencing mitigates execution risk)

## Recommendation

**Approach C (Unified Overhaul)** is the strongest choice.

**Why:**
1. The six proposals are not independent — they form a coherent system: explore → propose → spec → design → tasks → apply. Trying to fix them separately will leave the system temporarily incoherent.
2. The root cause is architectural: the SDD phase flow was not designed to handle replacement changes and context contradictions. Fixing this requires unified artifact contracts.
3. Consolidating into one change makes the architectural intent explicit in the proposal and allows a single verify step to confirm the whole system works.

**Sequencing in apply:**
1. Update `sdd-explore` SKILL.md (reads and scans)
2. Update `sdd-propose` SKILL.md (consumes explore output, writes new sections)
3. Update `sdd-spec` SKILL.md (consumes proposal sections, writes spec)
4. Update `sdd-tasks` SKILL.md (consumes proposal, writes removal tasks)
5. Update `sdd-ff` SKILL.md (orchestration changes, gates)
6. Update `CLAUDE.md` (global orchestrator rule for conversation context extraction)

## Identified Risks

1. **Integration gap if sequencing is wrong**: If apply updates spec before propose is finalized, specs will fail reading Supersedes section. → Mitigation: Apply must follow the sequence above; phase dependencies enforced in tasks.md.

2. **Backwards compatibility with existing openspec/changes/**: Archived proposal.md and exploration.md files won't have the new sections. → Mitigation: New sections are optional (backfill not required); explore and propose are designed to tolerate missing prior sections.

3. **Breaking existing ongoing SDD cycles**: If a user has an active `/sdd-ff` in progress when the overhaul is installed, the new contracts may break during apply. → Mitigation: Changes to skills are live immediately; users' in-progress cycles inherit the new rules. This is acceptable (sdd-ff is re-startable).

4. **Proposal verification complexity**: The verify step must test that explore, propose, spec, tasks, and apply all work together correctly with the new sections. → Mitigation: Create a test scenario in verify that includes a proposal with Supersedes, context contradictions, and prior attempts.

5. **Documentation lag**: CLAUDE.md global instructions need to stay in sync with skill updates. → Mitigation: The proposal explicitly lists which CLAUDE.md rules need injection; sdd-design should surface this as a documentation action item.

## Open Questions

1. **Should prior attempts (from archive) trigger a user gate in sdd-ff?**
   - Proposal 5b says to gate only on UNCERTAIN contradictions, not on mere presence of prior attempts.
   - Should we also present prior attempts to the user for awareness? (Informational, not a gate)
   - → Recommend: Gate only on UNCERTAIN, but log prior attempts as INFO and include them in exploration.md for the user to see.

2. **How much of the conversation context should orchestrator extract?**
   - Proposal 5a is vague about this. "Clarifications, restrictions, constraints" — how do we operationalize this?
   - → Recommend: Expand in sdd-ff SKILL.md with explicit patterns to extract (e.g., "remove X", "careful with Y", "mobile must not...").

3. **Should Supersedes section be required or optional in proposal.md?**
   - Proposal 2 says it should always exist, but that adds burden for purely additive changes.
   - → Recommend: Always exists, but if nothing is superseded it should say "None — this is a purely additive change" (explicit, not missing).

4. **What is the scope of "mobile must not be affected"?**
   - Proposal 5a mentions this as a constraint to extract, but constraints can be vague. How specific should the proposal.md entry be?
   - → Recommend: Proposal includes the constraint as stated by user; spec phase elaborates the technical implications.

## Ready for Proposal

**Yes.** The feedback reveals real architectural gaps that require a coordinated fix. Proceeding to propose phase with Approach C (unified overhaul) is the right path.

The six proposals provide sufficient detail and rationale to move forward. The proposal phase should consolidate them into a single problem statement, unify the success criteria, and lay out the artifact contracts that bind all six skill updates together.
