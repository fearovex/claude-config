# Proposal: sdd-apply-retry-limit

Date: 2026-03-10
Status: Draft

## Intent

Add a retry limit and circuit breaker to `sdd-apply` so that when the AI gets stuck on a task (repeated attempt-fail cycles), it stops automatically, records the blocked state in `tasks.md`, and requests manual intervention instead of continuing indefinitely.

## Motivation

When `sdd-apply` encounters a failing task, the current behavior is to attempt another approach and retry. Without a limit, this produces loops:

- Attempt 1: make change → run tool → fail
- Attempt 2: make different change → run tool → fail
- Attempt 3: make another change → run tool → fail

Each iteration consumes context, degrades coherence, and may produce inconsistent file state. The user observes the AI "spinning" without progress. There is no automatic stop condition.

The root cause is typically: the AI lacks the initial state information needed to diagnose correctly (addressed separately in `sdd-apply-diagnose-first`). The retry limit is the safety net that stops the damage when diagnosis is insufficient.

## Scope

### Included

- Add a retry counter per task in `sdd-apply`: maximum 3 attempts per task
- On attempt 3 failure: mark task as `BLOCKED` in `tasks.md` with:
  - Attempt summary (what was tried, what failed)
  - Last error output
  - Explicit instruction: "Manual intervention required before resuming"
- After marking a task `BLOCKED`, the agent stops the current phase and reports to the user
- The agent must NOT continue to the next task after a `BLOCKED` — the phase halts
- Add a `RESUME` path: user resolves the block, updates `tasks.md` to `TODO`, and re-runs `/sdd-apply`
- Define "same strategy" detection: if two consecutive attempts make the same file change, count as one attempt (detect infinite loops)

### Excluded

- Automatic resolution of blocked tasks
- Changes to `sdd-verify` or `sdd-tasks`
- Retry limits for non-implementation operations (file reads, searches)

## Proposed Approach

### Retry tracking

Each task execution in `sdd-apply` tracks:

```
attempt_count: 0
max_attempts: 3
last_error: ""
```

Before each attempt: increment `attempt_count`. If `attempt_count > max_attempts`, trigger BLOCKED state.

### BLOCKED state in `tasks.md`

```markdown
- [BLOCKED] Task 2.3 — description
  - Attempts: 3/3
  - Tried: [summary of each attempt]
  - Last error: [error output]
  - Resolution required: [specific question or action needed]
```

### Agent stop behavior

On BLOCKED:
```
⛔ Task X.Y BLOCKED after 3 attempts.

What was tried:
  1. [attempt 1 summary]
  2. [attempt 2 summary]
  3. [attempt 3 summary]

Last error: [error]

tasks.md updated. Manual intervention required.
Resume after resolving: /sdd-apply <change-name>
```

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-apply/SKILL.md` | Modified | High — retry counter and BLOCKED state added |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| 3 attempts too few for legitimately complex tasks | Medium | Low | Max attempts is configurable via `openspec/config.yaml` `apply_max_retries` key |
| "Same strategy" detection is inaccurate | Medium | Low | Conservative: if unsure, count as different attempt — limit still applies |

## Success Criteria

- [ ] `sdd-apply` tracks attempt count per task and stops at max_attempts
- [ ] A task exceeding max_attempts is marked `[BLOCKED]` in `tasks.md` with attempt summary and last error
- [ ] The agent halts the phase after a BLOCKED task and does NOT continue to subsequent tasks
- [ ] The resume path is documented: user updates `tasks.md` to `TODO`, re-runs `/sdd-apply`
- [ ] `verify-report.md` has at least one [x] criterion checked
