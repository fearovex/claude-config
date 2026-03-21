# Proposal: sdd-spec Must Not Write Requirements That Protect Prior Implementations Without Explicit User Confirmation

## Problem Statement

`sdd-spec` invented a requirement to KEEP a prior implementation that the user wanted removed. The spec said:

> "Requirement: Membership Polling Unaffected — the usePeriodicMembershipRefresh hook MUST continue to function"

This requirement was never requested by the user. It was inferred by the spec agent from the explore output — which itself had a blind spot about branch-local implementations (see Proposal 1).

The effect was that the spec became an obstacle: it blocked `sdd-apply` from performing the removal, and the user had to explicitly fight against their own specs.

## Root Cause

`sdd-spec` has no rule preventing it from writing "preservation requirements" for existing code unless that preservation was explicitly requested. The spec agent treats "this thing exists and seems unrelated to the change" as grounds to write a requirement protecting it.

This is a category error: the spec should only describe the **desired state** the user requested, not serve as a preservation charter for all surrounding code.

## Proposed Solution

Add a rule to `sdd-spec` SKILL.md:

**Rule: No unconfirmed preservation requirements**

> The spec MUST NOT write a requirement that says existing code MUST be preserved unless:
> (a) the `proposal.md` explicitly lists the artifact as "KEEP" in the `## Supersedes` section, OR
> (b) the user explicitly confirmed in conversation that the artifact should remain
>
> If the spec agent is uncertain whether something should be kept or removed, it MUST flag it as an OPEN QUESTION in the spec — not write a requirement that assumes preservation.

Additionally, add a cross-check step:

> Before writing the spec, read `proposal.md ## Supersedes`. Any artifact listed as REMOVE must appear as a **negative requirement** in the spec (e.g., "The system MUST NOT retain usePeriodicMembershipRefresh after this change is applied").

## Success Criteria

- [ ] `sdd-spec` does not write preservation requirements for artifacts not mentioned in `proposal.md`
- [ ] Artifacts listed as REMOVE in `proposal.md ## Supersedes` appear as negative requirements in the spec
- [ ] Ambiguous cases appear as open questions, not as silent preservation requirements
- [ ] In a re-run of the observed session, the spec would NOT contain "Membership Polling Unaffected" — or would flag it as an open question for user confirmation

## Files to Target

- `~/.claude/skills/sdd-spec/SKILL.md` — add the no-unconfirmed-preservation rule and Supersedes cross-check step
