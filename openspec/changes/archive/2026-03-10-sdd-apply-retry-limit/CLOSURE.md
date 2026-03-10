# Closure: sdd-apply-retry-limit

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Added a retry limit and circuit breaker to `sdd-apply`: when the AI gets stuck on a task after a configurable number of attempts (default 3), it stops automatically, marks the task `[BLOCKED]` in `tasks.md` with attempt details, and halts the phase until the user manually resolves the block and resumes.

## Modified Specs

| Domain    | Action | Change                                                                 |
| --------- | ------ | ---------------------------------------------------------------------- |
| sdd-apply | Added  | 6 new requirements: Retry Counter per Task, Same Strategy Detection, User Resume Path, Configuration of Max Retries, BLOCKED State Marking, Agent Stop Behavior on BLOCKED |

## Modified Code Files

- `skills/sdd-apply/SKILL.md` — Step 0b (retry counter initialization), Step 5 (task execution loop with attempt tracking, BLOCKED state, same-strategy detection, phase halt)
- `openspec/config.yaml` — added optional `apply_max_retries` key documentation

## Key Decisions Made

- **In-memory counter per invocation**: retry counter is not persisted; it resets each time `/sdd-apply` is invoked. Counter is cumulative only within a single run.
- **Default max_attempts = 3**: conservative default; surfacing manual intervention early is preferred over allowing long loops.
- **Config key `apply_max_retries` in `openspec/config.yaml`**: keeps project config in one place; absent key defaults to 3 (non-breaking).
- **Hash-based same-strategy detection**: compares files modified + content delta between attempts; conservative (if unsure, counts as different attempt).
- **`[BLOCKED]` inline in tasks.md**: discoverable, human-readable, single source of truth. No separate file.
- **Phase halt on BLOCKED (fail-fast)**: context degradation is worse than stopping early; user must explicitly resolve and resume.
- **Manual resume via `[BLOCKED]` → `[TODO]`**: gives user explicit control; auto-retry could loop indefinitely on environmental issues.

## Lessons Learned

- Verification was PASS WITH WARNINGS. The only warning was absence of automated tests — consistent with the project's `audit-as-integration-test` strategy. All scenarios were verified via code inspection of `sdd-apply/SKILL.md`.
- A suggestion was raised to uncomment `apply_max_retries: 3` in `openspec/config.yaml` to make the default explicit; deferred to a future session.

## User Docs Reviewed

N/A — this change modifies `sdd-apply/SKILL.md` internal execution logic. It does not add new commands, rename skills, or change onboarding workflows. No update to `scenarios.md`, `quick-reference.md`, or `onboarding.md` is required.
