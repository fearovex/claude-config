# ADR-025: sdd-apply Diagnosis-Before-Change Convention

## Status

Proposed

## Context

The `sdd-apply` skill executes tasks by reading the task description and immediately writing code changes. This skips a critical information-gathering step: understanding what the system currently does before attempting to change it.

The consequence is a change-fail-change-fail loop: the sub-agent modifies files based on the task description alone, without verifying its understanding of the current system state. When the first attempt fails, the agent lacks a baseline to reason from, making subsequent retries less informed rather than more.

A mandatory Diagnosis Step — front-loading file reads, read-only command execution, and a written hypothesis before any file modification — addresses this by ensuring the agent always understands the starting state.

## Decision

We will add a mandatory Diagnosis Step to `sdd-apply/SKILL.md` that executes before any file modification for every task. The Diagnosis Step requires the sub-agent to: (1) read all files to be modified, (2) run read-only diagnostic commands (project-configured via `diagnosis_commands` in `openspec/config.yaml` or auto-detected), (3) produce a structured `DIAGNOSIS` block containing a written hypothesis. No file writes are permitted before the `DIAGNOSIS` block is recorded. When diagnostic findings contradict the task description, a `MUST_RESOLVE` warning is raised and the agent halts until the user confirms how to proceed.

## Consequences

**Positive:**

- Sub-agents always have a verified understanding of the current state before making changes, reducing the probability of a change-fail loop
- The written hypothesis creates an auditable reasoning trace per task
- `MUST_RESOLVE` warnings surface incorrect task assumptions early, before expensive implementation attempts
- The pattern is consistent with how other `sdd-apply` safety mechanisms work (DEVIATION, QUALITY_VIOLATION)

**Negative:**

- Each task takes longer due to the mandatory read and hypothesis-writing step
- Sub-agents must produce structured `DIAGNOSIS` blocks for every task, including trivial ones (though the overhead is low for simple tasks)
- `MUST_RESOLVE` pauses require human interaction mid-apply, which breaks fully automated apply runs
