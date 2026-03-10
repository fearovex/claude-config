# ADR-026: sdd-verify Enforcement Convention — Tool Execution Gate and Evidence-Based Criteria

## Status

Proposed

## Context

The `sdd-verify` skill produces a `verify-report.md` with checklist criteria but has no mechanism to enforce that checked criteria (`[x]`) are backed by actual tool output. Claude can mark a criterion as satisfied based on code inspection alone, which is abstract verification — the AI describes what it believes is correct without executing the project's tooling.

Additionally, `sdd-apply` suggests `/commit` alongside `/sdd-verify` in its final output, making it possible to commit unverified implementations. This creates a process gap where the SDD cycle appears complete but actual verification was never performed.

Two conventions are introduced:
1. Every `verify-report.md` MUST contain a `## Tool Execution` section with actual command output.
2. `sdd-apply` MUST NOT suggest `/commit` — only `/sdd-verify` is permitted as a next step.

A new `verify_commands` config key in `openspec/config.yaml` allows projects to override auto-detected test runners with explicit commands, following the same pattern as `diagnosis_commands`.

## Decision

We will enforce that `sdd-verify` runs at least one project tooling command and records its output in a mandatory `## Tool Execution` section of `verify-report.md`. A criterion in `verify-report.md` may only be marked `[x]` when backed by tool output or explicit user-provided evidence. `sdd-apply` final output will contain only a `/sdd-verify` pointer — no `/commit` suggestion. The `verify_commands` key in `openspec/config.yaml` overrides auto-detection when present.

## Consequences

**Positive:**

- Verification is grounded in actual execution evidence, not AI inference
- The SDD cycle enforces a clear gate: apply → verify (with tool output) → commit
- `verify_commands` gives projects with non-standard tooling a first-class configuration path
- Consistent with the `diagnosis_commands` pattern already established in ADR-025

**Negative:**

- Projects with no detectable test runner will have all criteria marked `[ ]` unless the user provides explicit evidence, which requires manual effort
- `sdd-apply` users who previously relied on the `/commit` prompt must now explicitly run `/sdd-verify` — small friction increase for simple changes
