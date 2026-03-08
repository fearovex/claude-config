# Proposal: clean-skill-template-noise

## Problem

The active skill catalog still contains a small amount of documentation noise after the
contract-normalization work:

1. `skills/project-audit/SKILL.md` contains a malformed nested fenced example in the report
   template, which makes the active template harder to read and maintain.
2. `skills/project-fix/SKILL.md` and `skills/project-claude-organizer/SKILL.md` still embed raw
   `TODO` placeholders inside scaffold examples that are active reference content, which creates
   avoidable audit noise even though the examples are not executable logic.

The remaining debt is low-risk, but it lives in active skill files rather than archived artifacts.

## Proposed Solution

Make one narrow, non-functional cleanup pass:

- balance the nested fenced example in `project-audit`
- replace raw `TODO` placeholders in active scaffold examples with explicit scaffold wording that
  makes the placeholder status clear without looking like unfinished live content

This change does not alter command names, execution flow, or mutation authority.

## Success Criteria

- [ ] The `## Report Format` example in `skills/project-audit/SKILL.md` uses one clean, balanced
      nested fence structure.
- [ ] The active scaffold examples in `skills/project-fix/SKILL.md` and
      `skills/project-claude-organizer/SKILL.md` no longer contain raw `TODO` markers.
- [ ] The replacement wording makes it explicit that the example text is scaffold content to be
      replaced before real use.
- [ ] No behavioral instructions, command names, or mutation scopes change.

## Scope

In scope:

- `skills/project-audit/SKILL.md`
- `skills/project-fix/SKILL.md`
- `skills/project-claude-organizer/SKILL.md`
- SDD artifacts for this small cleanup change

Out of scope:

- Changing real command behavior
- Rewriting archived artifacts
- Introducing new linting or audit tooling