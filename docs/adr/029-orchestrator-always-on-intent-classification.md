# ADR-029: Introduce Always-On Intent Classification as a Cross-Cutting Orchestration Layer

## Status

Accepted

## Context

The SDD orchestrator currently activates only when the user explicitly invokes a slash command (`/sdd-ff`, `/project-audit`, etc.). Free-form requests like "fix this bug" or "add feature X" bypass the SDD discipline entirely — Claude responds directly without delegating to sub-agents or following the phase DAG. This means the SDD system's effectiveness depends on the user remembering which command to type, creating an inconsistent experience where identical work requests produce disciplined or undisciplined outcomes based solely on phrasing.

The existing architectural decision (ADR-003) states that the orchestrator never executes work inline, but this rule is only enforced when a slash command triggers the orchestration path. A cross-cutting gate is needed to ensure SDD discipline applies regardless of how the user phrases their request.

## Decision

We will add an "Always-On Orchestrator" section to CLAUDE.md that introduces intent classification as a mandatory first step for every user message. The classifier uses a simple 4-category decision table (SLASH_CMD, CHANGE_REQUEST, EXPLORE_REQUEST, QUESTION) implemented as inline rules — not a separate skill. Change requests are routed to SDD command recommendations; exploration requests auto-launch `sdd-explore`; questions are answered directly; slash commands execute as today.

This is a global, cross-cutting behavioral change that affects how every user message is processed, introducing a new orchestration layer (intent classification) that did not previously exist.

## Consequences

**Positive:**

- SDD discipline applies consistently regardless of how the user phrases their request
- Eliminates the "command memory" burden — users get SDD routing without knowing the command catalog
- Exploration requests are handled automatically, reducing friction for code review and investigation tasks
- Questions and explanations remain fast — no unnecessary SDD overhead for simple queries

**Negative:**

- Adds cognitive overhead to CLAUDE.md — the intent classification rules increase the file's complexity
- Ambiguous requests require a default-to-QUESTION heuristic, which may miss opportunities for SDD routing
- The classification is heuristic-based (pattern matching on message content) and may misclassify edge cases
- Change requests are recommended (not auto-launched) to preserve user control, which means the user still needs to confirm — partial friction reduction only
