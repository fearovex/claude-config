# Proposal: sdd-propose Must Have Explicit Removals Section

## Problem Statement

When a change supersedes a prior implementation, `sdd-propose` generates a proposal that describes only what to ADD — it does not enumerate what must be REMOVED. This causes downstream phases (spec, design, tasks, apply) to treat the new implementation as purely additive, even when the user's intent was a replacement.

In the observed session, the proposal said "redirect to login on 401" but never mentioned "remove usePeriodicMembershipRefresh". The spec phase then invented a requirement to KEEP the hook, directly contradicting the user's stated intent.

## Root Cause

`sdd-propose` SKILL.md has no required section for artifacts to remove or supersede. The proposal template only structures:
- Problem
- Proposed solution
- Success criteria

There is no `## Supersedes` or `## Artifacts to Remove` section.

## Proposed Solution

Add a required `## Supersedes` section to the proposal template in `sdd-propose` SKILL.md:

```markdown
## Supersedes

List prior implementations that this change replaces, with disposition:

| Artifact | File | Disposition | Reason |
|----------|------|-------------|--------|
| usePeriodicMembershipRefresh | hooks/usePeriodicMembershipRefresh.js | REMOVE | Replaced by redirect-on-expiry approach |
| AuthWeb.js polling mount | AuthWeb.js line 204 | MODIFY | Remove hook import and mount call |
```

**Rules for this section:**
- If `exploration.md` has a `## Prior Implementations on This Branch` section, every item flagged `superseded_by_this_change` MUST appear here
- If the user explicitly mentioned removing something, it MUST appear here regardless of explore output
- If nothing is superseded, the section should say "None — this is a purely additive change"
- This section is BINDING for spec, design, tasks, and apply phases — they must not contradict it

## Success Criteria

- [ ] `proposal.md` always contains a `## Supersedes` section
- [ ] Items in `## Supersedes` are propagated to spec as negative requirements ("MUST NOT retain X")
- [ ] Items in `## Supersedes` appear as explicit tasks in `tasks.md` (e.g., "Task: Remove usePeriodicMembershipRefresh")
- [ ] `sdd-apply` removes the listed artifacts — not just adds the new ones
- [ ] In a re-run of the observed session, the proposal would list `usePeriodicMembershipRefresh` as REMOVE

## Files to Target

- `~/.claude/skills/sdd-propose/SKILL.md` — add Supersedes section to template and rules
- `~/.claude/skills/sdd-spec/SKILL.md` — read Supersedes section and generate negative requirements
- `~/.claude/skills/sdd-tasks/SKILL.md` — generate removal tasks from Supersedes section
