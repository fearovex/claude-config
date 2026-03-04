# ADR-019: Project Claude Organizer Memory Layer Conventi

## Status

Proposed

## Context

Overwriting risks destroying user content in `ai-context/`. Merging is out of scope. The `project-claude-organizer` skill must handle the case where a documentation candidate's destination path already exists in `ai-context/`. A consistent, transparent outcome must be defined so users can understand and predict the skill's behavior across repeated invocations.

## Decision

We will skip copying any documentation candidate whose destination path already exists in `ai-context/`, record the outcome as `skipped (destination exists — review manually)`, and never overwrite or merge existing content. This convention is consistent with the existing CLAUDE.md stub idempotency pattern in Step 5.3 of the same skill.

## Consequences

**Positive:**

- No user content in `ai-context/` is ever destroyed by the skill
- The operation is fully idempotent: running the skill twice with the same inputs produces identical outcomes
- The skip outcome is transparent in both the dry-run plan and the report

**Negative:**

- Users who intend to refresh `ai-context/` content from a `.claude/` source file must manually delete the destination before re-running the skill
- Destination-exists collisions require manual review; the skill provides no merge or diff assistance
