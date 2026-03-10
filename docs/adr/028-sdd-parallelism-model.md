# ADR-028: SDD Parallelism Model

## Status

Accepted

## Context

The SDD orchestration cycle delegates each phase to a Task sub-agent. As the cycle evolved, a pattern emerged where two phases — `sdd-spec` and `sdd-design` — are launched in parallel by convention (documented in CLAUDE.md Fast-Forward section). No formal rule existed to explain:

- Why exactly two Tasks are run in parallel and not more.
- What prevents a third or fourth Task from being launched simultaneously.
- Whether `sdd-apply` batches targeting independent bounded contexts could also be parallelized.
- What happens if two parallel Tasks attempt to write to the same file.

Without a documented model, future contributors extending the SDD cycle (e.g., adding a new parallel pair) had no principled basis for deciding whether a parallelism change was safe. File write conflicts between parallel Tasks produce silent data loss or partial overwrites in Claude Code's execution model — a failure mode that is hard to detect and reproduce.

This ADR documents the current parallelism model based on observed behavior, establishes a file conflict boundary rule, and evaluates bounded-context parallel apply as a future option.

## Decision

We will limit simultaneously running Task sub-agents to a maximum of **2** within a single SDD cycle invocation.

**File conflict boundary rule:** Tasks that write to non-overlapping files MAY run in parallel. Tasks that write to the same file MUST NOT run in parallel.

**Rationale for the limit of 2:**
The current observed-safe parallel pair is `sdd-spec` + `sdd-design`. These two Tasks write to different files (`specs/<domain>/spec.md` vs `design.md`), satisfying the file conflict boundary rule. Running 3–4 Tasks in parallel on the same change has not been validated; the risk of context-window pressure and output quality degradation increases with Task count in Claude Code's orchestration model. The limit of 2 reflects the highest validated safe value, not a hard technical ceiling.

**Current safe parallel pair:**
`sdd-spec` and `sdd-design` are the only validated parallel pair. They write to different files and produce independent artifacts that `sdd-tasks` then consumes. All other phase pairs in the current cycle are sequential.

**Bounded-context parallel apply:**
Running multiple `sdd-apply` batches in parallel is conditionally feasible when all of the following conditions are met:

1. Each batch targets a distinct bounded context with no shared domain files.
2. No batch writes to cross-domain shared files: `CLAUDE.md`, `ai-context/*.md`, `openspec/config.yaml`, or `openspec/changes/<change>/tasks.md`.
3. The total number of parallel Tasks does not exceed 2 (the validated limit).

Implementation of parallel apply is deferred to a separate change. This ADR records the position only.

**CLAUDE.md update:**
The current CLAUDE.md Fast-Forward and Apply Strategy sections accurately reflect this model. No modification to CLAUDE.md is required by this ADR.

All conclusions in this ADR are based on **observed behavior** in Claude Code's orchestration model, not on hard technical constraints derived from a specification. The limits may be revised upward if empirical evidence from validated experiments supports a higher safe count.

## Consequences

**Positive:**

- Clear parallel Task limit (2) prevents quality degradation from over-parallelism.
- File conflict boundary rule makes it safe to evaluate new parallel phase pairs in the future — any proposal can be checked against the rule.
- Bounded-context parallel apply has a documented checklist, enabling future implementation without re-litigating the core question.
- The observed-behavior basis is explicit, so the ADR can be revised as the system is tested at higher parallelism.

**Negative:**

- Conservative limit of 2 may under-utilise available parallelism in larger SDD cycles.
- Bounded-context parallel apply remains unimplemented; changes touching multiple independent domains still run sequentially.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| 3–4 parallel Tasks | Unvalidated; risk of context-window pressure and output quality degradation. May be revisited with empirical evidence. |
| No restriction on parallelism | Silent file write conflicts produce data loss when two Tasks write to the same path. Explicit rules are required. |
| Parallel apply without conditions | Cross-domain shared files (CLAUDE.md, ai-context/*.md, tasks.md) impose a sequential constraint that cannot be ignored. Parallel apply is only safe under strict isolation conditions. |
| Update CLAUDE.md to add parallelism notes | Not needed. The current Fast-Forward and Apply Strategy sections already accurately describe the model (spec+design parallel, everything else sequential). |

## Parallelism Limits Table

| Phase pair | Safe to parallelize? | Reason |
|------------|---------------------|--------|
| sdd-spec + sdd-design | Yes | Write to different files: `specs/<domain>/spec.md` vs `design.md`. Known safe pair. |
| sdd-propose + any other phase | No | sdd-propose produces `proposal.md`; spec and design depend on it. Must complete first. |
| sdd-tasks + any other phase | No | `tasks.md` is written by sdd-tasks and read by sdd-apply. Must complete before apply. |
| sdd-apply batches (same bounded context) | No | Tasks in the same domain write to the same domain files; file conflict rule applies. |
| sdd-apply batches (different bounded contexts, no shared files) | Conditionally yes | Safe only if no batch writes to shared cross-domain files and total parallel Task count ≤ 2. Implementation deferred. |
| sdd-apply + sdd-verify | No | sdd-verify reads the complete output of all apply tasks. Must run after apply completes. |
| sdd-verify + sdd-archive | No | sdd-archive is irreversible. Must run after verify produces a result for user confirmation. |
