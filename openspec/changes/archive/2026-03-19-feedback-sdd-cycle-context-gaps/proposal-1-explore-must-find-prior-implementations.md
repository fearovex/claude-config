# Proposal: sdd-explore Must Detect and Surface Prior Implementations

## Problem Statement

When a user says "remove the previous implementation and apply this new one", the `sdd-explore` phase fails to find what was previously implemented on the current branch. In the observed session, the explore agent found the current auth flow but did NOT identify `usePeriodicMembershipRefresh` as a prior implementation that the user explicitly wanted removed.

As a result, the propose/spec phases made a decision to KEEP the prior implementation — and even wrote a spec requirement explicitly protecting it (`Requirement: Membership Polling Unaffected`). This turned `sdd-explore`'s blind spot into a spec-level constraint that blocked the user's actual intent.

The user had to argue against their own specs to get the implementation they wanted.

## Root Cause

`sdd-explore` is not instructed to:
1. Scan the current git branch diff (`git diff main...HEAD`) to identify what was added/changed in this branch
2. Treat branch-local additions as "prior implementations" that the new cycle may need to supersede
3. Surface a "what exists on this branch that may conflict with the requested change" section

## Proposed Solution

Add an explicit step to `sdd-explore` SKILL.md:

**Step: Branch-local implementation scan**
- Run `git diff <base>...HEAD --name-only` to list files changed on this branch
- For each changed file relevant to the topic, describe what was added/modified
- Produce a `## Prior Implementations on This Branch` section in `exploration.md`
- Flag each prior implementation with one of: `superseded_by_this_change` | `unrelated` | `uncertain`

The explore agent must NOT make the call of "keep vs remove" — it surfaces the information. The propose agent then decides based on user intent.

## Success Criteria

- [ ] `exploration.md` includes a `## Prior Implementations on This Branch` section when branch diff is non-empty
- [ ] Items flagged as `superseded_by_this_change` are carried forward into `proposal.md` as explicit removals
- [ ] The spec phase does NOT write requirements protecting prior implementations unless the proposal explicitly says to keep them
- [ ] In a re-run of the observed session, `usePeriodicMembershipRefresh` would appear as a candidate for removal in `exploration.md`

## Files to Target

- `~/.claude/skills/sdd-explore/SKILL.md` — add branch-local scan step
- `openspec/changes/*/exploration.md` template structure (implicit via skill instructions)
