# Proposal: narrow-project-claude-organizer-scope

Date: 2026-03-06
Status: Draft

## Intent

Refactor `project-claude-organizer` so its core contract is narrower, safer, and easier to reason about without changing the command name or removing the migrations that already exist.

## Motivation

`project-claude-organizer` is now the highest-churn `project-*` skill. It has grown from a folder-normalization helper into a broad migration engine with many strategy-specific rules, audit-style findings, and optional cleanup behavior.

The problem is not that the skill lacks value. The problem is that too much of its current policy is encoded as first-class organizer behavior:

- additive migrations and advisory analysis live in the same conceptual layer
- optional cleanup can make the organizer feel more destructive than its actual default posture
- edge cases accumulate as permanent organizer logic instead of being framed as explicit opt-in or manual-review outcomes

The next rewrite step should reduce conceptual scope first, not add more migration behavior.

## Scope

### Included

- Add an explicit organizer kernel that frames the command as four stages: detect, classify, propose, apply additive migrations
- Add explicit scope-boundary text that separates core additive migrations, explicit opt-in operations, and advisory-only outcomes
- Add explicit compatibility policy wording so legacy/ambiguous structures are handled as compatibility paths rather than as canonical organizer behavior
- Tighten the live skill rules so skills audit, unexpected items, non-qualifying command files, and ambiguous routing are clearly advisory-first concerns

### Excluded (explicitly out of scope)

- Removing existing migration handlers from the live skill
- Changing the `/project-claude-organizer` command name or report artifact path
- Replacing the cumulative `project-claude-organizer` master spec with a new domain
- Building a separate skills-audit command in this cycle

## Proposed Approach

Keep the existing live behavior largely intact, but rewrite the top-level contract so the command is described in three stable layers:

1. organizer kernel
2. scope boundaries
3. compatibility policy

This makes the organizer read as a conservative migration assistant rather than a generalized transformation engine. Existing handlers remain available, but the skill becomes clearer about which outcomes are core, which are opt-in, and which are advisory only.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `skills/project-claude-organizer/SKILL.md` | Modified | High |
| `openspec/changes/narrow-project-claude-organizer-scope/specs/project-claude-organizer/spec.md` | New delta spec | Medium |
| `openspec/specs/project-claude-organizer/spec.md` | Updated on archive | Medium |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Scope-narrowing wording may contradict existing handlers | Medium | Medium | Keep handlers intact and position the new text as umbrella contract language |
| Reviewers may assume this change removed capabilities rather than reframed them | Medium | Low | State explicitly in proposal, design, verification, and closure that this is a contract rewrite, not a handler deletion pass |
| The organizer may still feel too broad even after the rewrite | Medium | Medium | Treat this cycle as the contractual narrowing step before any future behavior removals |

## Rollback Plan

1. Restore `skills/project-claude-organizer/SKILL.md` to its pre-change version from git history.
2. Remove the narrowed-scope additions from the cumulative `openspec/specs/project-claude-organizer/spec.md` if they prove confusing.
3. Re-run `install.sh` to deploy the reverted skill.

## Dependencies

- The cumulative `project-claude-organizer` master spec remains the long-lived spec domain for organizer behavior.
- The previous organizer cycles for memory-layer handling and commands conversion remain valid and are complemented by this scope-narrowing pass.

## Success Criteria

- [ ] `skills/project-claude-organizer/SKILL.md` contains explicit sections for organizer kernel, scope boundaries, and compatibility policy
- [ ] The live skill clearly distinguishes core additive migrations from opt-in and advisory-only outcomes
- [ ] The rules section explicitly states that skills audit and ambiguous structures do not expand organizer mutation scope automatically
- [ ] The cumulative `openspec/specs/project-claude-organizer/spec.md` reflects the narrowed-scope contract after archive

## Effort Estimate

Medium (1 day)