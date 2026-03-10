# ADR-024: SDD Phase Skills Load Project Context Before Producing Output

## Status

Proposed

## Context

SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) execute from the global `~/.claude/skills/` catalog without reliably loading the project's `ai-context/` memory layer. As a result, generated artifacts (specs, design, tasks) do not consistently reflect the project's actual tech stack, architectural decisions, or code conventions — forcing users to re-explain context in every session. The `ai-context/` layer already exists as the project memory contract, but there was no enforced convention requiring phase skills to read it.

A single named step is needed to make context loading discoverable, auditable, and consistent across all six SDD phase skills. The step must be non-blocking: `ai-context/` is optional by design, and graceful degradation is the established pattern in this system.

## Decision

We will add a mandatory **Step 0 — Load project context** block as the first step of every SDD phase SKILL.md (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`). The block reads `ai-context/stack.md`, `ai-context/architecture.md`, and `ai-context/conventions.md` before any analysis or output. Missing files are noted at INFO level and execution continues. Files older than 7 days trigger a staleness warning suggesting `/memory-update`. The block template is documented in `docs/sdd-context-injection.md` for future skill authors.

## Consequences

**Positive:**

- SDD phase outputs consistently reflect the project's actual stack, architecture, and conventions without requiring the user to re-explain context
- Convention is uniform: all six skills use the same named step and the same non-blocking contract
- The pattern is documented and discoverable for future skill authors via `docs/sdd-context-injection.md`
- Staleness detection encourages timely `/memory-update` runs

**Negative:**

- Slight increase in token usage per sub-agent invocation (three small file reads); acceptable given that `ai-context/` files are intentionally kept concise
- Skills with an existing Step 0 (`sdd-propose`, `sdd-spec`) require a rename to `Step 0a` / `Step 0b` to preserve backward reference to existing step numbers
