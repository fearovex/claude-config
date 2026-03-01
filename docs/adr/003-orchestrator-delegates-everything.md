# Orchestrator (CLAUDE.md) never executes work inline

**Status:** Accepted (retroactive)

> This decision predates the ADR system and is recorded retroactively.

---

## Context

`CLAUDE.md` is the global orchestrator: it receives user commands, coordinates the SDD phase DAG, and manages the overall development cycle. A simpler design would have the orchestrator execute each phase directly in its own context window — writing proposals, specs, designs, and implementation code as a monolith.

This approach has critical failure modes:

- **Context overflow**: a full SDD cycle (explore → propose → spec → design → tasks → apply → verify → archive) can involve dozens of files and thousands of lines. Running everything in one context window exhausts the limit on non-trivial changes.
- **Poor separation of concerns**: when the orchestrator both coordinates and executes, it is impossible to update one phase's behavior without risking interference with others. Each phase has specialized knowledge; conflating them leads to confusion.
- **No parallelism**: the `spec` and `design` phases are independent and can run simultaneously. A monolithic context window serializes them unnecessarily.
- **Opaque failure isolation**: if one phase fails in a monolith, the root cause is buried in a single long context. When phases are separate agents, failure is localized.

The delegation pattern was adopted to address all of these at once.

---

## Decision

The global CLAUDE.md orchestrator never executes SDD phase work in its own context. For every phase — propose, spec, design, tasks, apply, verify, archive — it spawns a dedicated sub-agent via the Task tool and provides only the minimal context that sub-agent needs (project path, change name, artifact file paths).

The orchestrator:
- NEVER writes specs, proposals, designs, or implementation code directly
- NEVER reads source code for analysis
- ALWAYS delegates to a sub-agent with a reference to the corresponding phase SKILL.md
- ALWAYS maintains only file paths between phases, not document contents
- ALWAYS presents a summary to the user and asks for approval before continuing to the next gate

Sub-agents launched in parallel (spec + design) each receive independent context and write their output to separate artifact files.

---

## Consequences

**Positive:**
- Each phase runs in a fresh context window, eliminating context overflow on complex changes.
- Phases can be updated, replaced, or re-run independently without affecting the orchestrator or other phases.
- Spec and design phases execute in parallel, reducing total cycle time.
- Failure is localized: a blocked sub-agent returns a status of `blocked` or `failed`; the orchestrator can report the exact phase without ambiguity.
- The orchestrator itself stays small and readable — it is coordination logic, not implementation logic.

**Negative:**
- Requires discipline in orchestrator skill files: any inline execution attempt violates this decision and is treated as a bug.
- The Task tool delegation pattern adds a layer of indirection that can be confusing to contributors new to the system.
- Sub-agent launch overhead adds latency per phase compared to inline execution.
