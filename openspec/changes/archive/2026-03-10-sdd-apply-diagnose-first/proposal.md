# Proposal: sdd-apply-diagnose-first

Date: 2026-03-10
Status: Draft

## Intent

Add a mandatory diagnosis phase to `sdd-apply` that captures the initial state of the problem (current behavior, relevant data, error outputs, related code) before making any changes, ensuring the AI understands the starting point before attempting a fix.

## Motivation

The current `sdd-apply` pattern is: read task → make change → run verification → observe result → iterate. This skips a critical step: understanding the current state before changing it.

The consequence is the change-fail-change-fail loop: the AI modifies code based on the task description alone, without verifying its understanding of the current system behavior. When the first attempt fails, the AI lacks a baseline to reason from.

Root cause: the AI does not know:
1. What the system currently does (actual behavior, not spec)
2. What data exists in the current state that is relevant to the task
3. Which existing code paths are exercised by the scenario being fixed

Diagnosis before change addresses this by front-loading information gathering.

## Scope

### Included

- Add a mandatory **Diagnosis Step** at the start of each task execution in `sdd-apply`:
  1. Read the files that will be modified (understand current implementation)
  2. Run relevant read-only commands to observe current behavior (test output, query results, log entries)
  3. Formulate an explicit hypothesis: "The current behavior is X because Y. The expected behavior is Z. I will change W to achieve Z."
  4. Record the hypothesis in a `diagnosis` block in the task notes
- The agent may not proceed to making changes without completing the diagnosis step
- If diagnosis reveals the task description is incorrect or the problem is different from what was expected: flag as `MUST_RESOLVE` warning before proceeding
- Add `diagnosis_commands` optional key to `openspec/config.yaml` for project-specific read-only diagnostic commands

### Excluded

- Automated data collection beyond what is achievable via read-only commands
- Changes to `sdd-tasks` or `sdd-verify`
- Retroactive diagnosis of already-applied tasks

## Proposed Approach

### Diagnosis step structure

Before each task's implementation:

```
DIAGNOSIS — Task X.Y:
  1. Read files to be modified: [list]
  2. Run read-only diagnostic commands:
     - [command]: [output summary]
  3. Current behavior observation: [what the code actually does now]
  4. Relevant data state: [key data values, config, environment state]
  5. Hypothesis: "The bug/issue is [X] because [Y].
     Changing [Z] will achieve [expected behavior] because [rationale]."
  6. Risk: [what could go wrong with this change]
```

Only after writing the hypothesis does the agent proceed to the change.

### When diagnosis reveals unexpected state

If the diagnostic output contradicts the task description:

```
⚠️ MUST_RESOLVE — Diagnosis finding:
  Task X.Y assumes [A], but current state shows [B].

  This may indicate the task description is based on incorrect assumptions.

  Confirm how to proceed:
  Option 1: [proceed with updated understanding]
  Option 2: [revise task description]
```

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-apply/SKILL.md` | Modified | High — diagnosis step added to task execution loop |
| `openspec/config.yaml` schema | Modified | Low — `diagnosis_commands` key documented |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Diagnosis step increases time per task significantly | High | Low | Acceptable tradeoff — diagnosis prevents multiple failed attempts |
| Diagnostic commands have side effects (not truly read-only) | Low | Medium | `diagnosis_commands` are user-defined; default auto-detected commands are read-only (test --dry-run, query) |
| Hypothesis is wrong despite diagnosis | Medium | Low | Retry limit (sdd-apply-retry-limit) is the backstop |

## Success Criteria

- [ ] `sdd-apply` includes a diagnosis step before each task's implementation
- [ ] The diagnosis step produces a written hypothesis recorded in task notes
- [ ] The agent does not make file changes before completing the diagnosis step
- [ ] A diagnosis that contradicts the task description triggers a `MUST_RESOLVE` warning
- [ ] `verify-report.md` has at least one [x] criterion checked
