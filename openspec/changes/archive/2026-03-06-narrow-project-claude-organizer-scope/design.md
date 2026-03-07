# Technical Design: narrow-project-claude-organizer-scope

Date: 2026-03-06
Proposal: openspec/changes/narrow-project-claude-organizer-scope/proposal.md

## General Approach

The change introduces a narrower top-level contract for `project-claude-organizer` without deleting existing migration handlers. The implementation adds three explicit sections near the top of the live skill: organizer kernel, scope boundaries, and compatibility policy. A small number of rule statements will be tightened so advisory-only outcomes and explicit opt-in behavior are named clearly.

The cumulative master spec for `project-claude-organizer` is updated on archive rather than replaced with a new standalone master domain.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Spec strategy | Use a delta spec against the existing `project-claude-organizer` domain | Create a brand-new organizer-scope master spec | Organizer already has an established cumulative master spec; another master domain would fragment it further |
| Rewrite strategy | Add top-level scope-contract sections and rule clarifications, preserve current handlers | Attempt to remove handlers in the same cycle | Contract clarity is lower-risk and should precede any future behavioral deletions |
| Behavior taxonomy | Classify organizer behavior as core additive, explicit opt-in, and advisory-only | Keep behavior classes implicit in each handler | The current maintenance problem is partly caused by policy being distributed only through handler text |
| Skills audit treatment | Keep skills audit diagnostic-only and explicitly outside organizer mutation scope | Let HIGH findings auto-trigger organizer cleanups | Skills audit is adjacent to organizer work but is still an audit concern, not a safe mutation authority |

## Data Flow

```text
project-claude-organizer
  -> detect live .claude state
  -> classify canonical items and legacy categories
  -> propose dry-run plan
  -> apply additive migrations
       -> core additive
       -> explicit opt-in
       -> advisory-only outcomes reported only
```

## File Change Matrix

| File | Action | What is added/modified |
| ---- | ------ | ---------------------- |
| `skills/project-claude-organizer/SKILL.md` | Modify | Add `## Organizer Kernel`, `## Scope Boundaries`, and `## Compatibility Policy`; tighten rule wording around advisory-only and opt-in behavior |
| `openspec/changes/narrow-project-claude-organizer-scope/specs/project-claude-organizer/spec.md` | Create | Delta spec describing the narrowed organizer contract |
| `openspec/specs/project-claude-organizer/spec.md` | Update on archive | Merge the narrowed-scope requirements into the cumulative master organizer spec |

## Interfaces and Contracts

```text
project-claude-organizer scope contract
  - Organizer Kernel: detect -> classify -> propose -> apply additive migrations
  - Scope Boundaries: core additive | explicit opt-in | advisory-only
  - Compatibility Policy: legacy structures remain compatibility paths, not canonical organizer scope
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Structural review | Presence of new top-level sections in `skills/project-claude-organizer/SKILL.md` | File inspection |
| Contract review | Presence of new narrowed-scope delta spec | File inspection |
| Regression review | Existing migration handlers and report sections remain present | File inspection |

## Migration Plan

No data migration required.

## Open Questions

None.