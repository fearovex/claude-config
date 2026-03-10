# Task Plan: sdd-apply-retry-limit

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-apply-retry-limit/design.md

## Progress: 8/8 tasks

## Phase 1: Foundation — Configuration and Data Structures

- [x] 1.1 Modify `~/.claude/skills/sdd-apply/SKILL.md` Step 0 — Add retry counter initialization block that reads `apply_max_retries` from `openspec/config.yaml` with default value of 3 ✓
- [x] 1.2 Modify `~/.claude/skills/sdd-apply/SKILL.md` Step 0 — Add inline documentation explaining the circuit breaker behavior and max_attempts configuration ✓

## Phase 2: Core Retry Logic — Task Execution Loop

- [x] 2.1 Modify `~/.claude/skills/sdd-apply/SKILL.md` task execution loop — Add attempt counter check at loop start: if `attempt_counter[task_id] >= max_attempts`, mark task `[BLOCKED]` and halt phase ✓
- [x] 2.2 Modify `~/.claude/skills/sdd-apply/SKILL.md` task execution loop — Increment `attempt_counter[task_id]` before each implementation attempt ✓
- [x] 2.3 Modify `~/.claude/skills/sdd-apply/SKILL.md` task execution loop — Add success path: on task completion, mark `[x]` and optionally reset counter ✓
- [x] 2.4 Modify `~/.claude/skills/sdd-apply/SKILL.md` task execution loop — Add failure path: on task failure, compare current attempt with previous attempt using same-strategy detection ✓

## Phase 3: Same-Strategy Detection and BLOCKED State

- [x] 3.1 Modify `~/.claude/skills/sdd-apply/SKILL.md` — Implement same-strategy detection function: collect files modified in current attempt, compare with previous attempt snapshot ✓
- [x] 3.2 Modify `~/.claude/skills/sdd-apply/SKILL.md` — Add BLOCKED state generation logic: format `[BLOCKED]` marker and append attempt summary (what was tried, error output, resolution instruction) ✓
- [x] 3.3 Modify `~/.claude/skills/sdd-apply/SKILL.md` — Add phase halt logic: when a task is marked `[BLOCKED]`, immediately halt the current phase and report to user ✓

## Phase 4: User Reporting and Resume Path

- [x] 4.1 Modify `~/.claude/skills/sdd-apply/SKILL.md` — Add BLOCKED state report format: output `⛔ Task X.Y BLOCKED after N attempts`, include attempt summary, last error, and resume instruction ✓
- [x] 4.2 Modify `~/.claude/skills/sdd-apply/SKILL.md` — Document resume path in output: user must edit `tasks.md` to change `[BLOCKED]` back to `[TODO]`, then re-run `/sdd-apply <change-name>` ✓

## Phase 5: Configuration and Documentation

- [x] 5.1 Optionally modify `openspec/config.yaml` — Add `apply_max_retries: 3` entry (optional; if absent, default is used) ✓
- [x] 5.2 Modify `ai-context/architecture.md` — Document the new retry limit feature and its configuration in the SDD apply-phase architecture section ✓

---

## Implementation Notes

- The retry counter is **in-memory, per invocation**: each call to `/sdd-apply` starts with a fresh counter. If a task fails after 1 attempt and the user resumes, the counter resets to 0 for that task.
- Same-strategy detection must be conservative: if two attempts modify the same files with the same content, count as identical strategy. If unsure, count as different.
- The phase must **halt immediately** when `[BLOCKED]` is encountered — do not continue to the next task.
- `openspec/config.yaml` key `apply_max_retries` is optional. If absent, default to 3.
- The BLOCKED marker and attempt summary must be appended to `tasks.md` **before** reporting to the user and halting the phase.

## Blockers

- None. All required infrastructure (SKILL.md read/write capability, tasks.md format, project config) is already in place.
