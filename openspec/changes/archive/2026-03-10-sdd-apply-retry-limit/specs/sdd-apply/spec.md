# Spec: sdd-apply Retry Limit and Circuit Breaker

Change: sdd-apply-retry-limit
Date: 2026-03-10

## Requirements

### Requirement: Retry Counter per Task

The `sdd-apply` skill MUST track the number of retry attempts per task and enforce a maximum number of attempts before marking a task as BLOCKED.

#### Scenario: Task completes within max attempts

- **GIVEN** a task is scheduled in the `tasks.md` with status `[TODO]` or `[x]` (marked for re-attempt)
- **WHEN** the agent attempts the task once and the task succeeds (all file operations complete, no tool errors, output is as expected)
- **THEN** the task is marked `[x]` (complete) and the retry counter is reset for the next task
- **AND** the agent proceeds to the next task in the phase

#### Scenario: Task fails on first attempt, succeeds on second attempt

- **GIVEN** a task is scheduled in `tasks.md` with status `[TODO]`
- **WHEN** the agent attempts the task, encounters an error (tool failure, validation error, or unexpected output)
- **THEN** the retry counter increments to 1/3
- **AND** the agent re-attempts the task with a different approach or clarification
- **AND** the second attempt succeeds
- **THEN** the task is marked `[x]` and the agent proceeds to the next task

#### Scenario: Task fails three times consecutively

- **GIVEN** a task is scheduled in `tasks.md` with status `[TODO]`
- **WHEN** the agent attempts the task three times and all three attempts fail (each with different error output or the same error)
- **THEN** the retry counter reaches 3/3 (max_attempts exceeded)
- **AND** the agent MUST NOT attempt a fourth time
- **AND** the task is marked `[BLOCKED]` in `tasks.md` with:
  - Attempt summary: what was tried in each of the three attempts
  - Last error output: the error from the third attempt
  - Resolution required: a specific question or action for the user to unblock
- **AND** the agent halts the current phase (does not process subsequent tasks)
- **AND** the agent reports to the user with the BLOCKED state message

### Requirement: Same Strategy Detection

The agent MUST detect when two consecutive retry attempts use the same strategy (produce identical file changes) and count that as a single attempt, not two separate attempts.

#### Scenario: Same change attempted twice is counted as one attempt

- **GIVEN** a task is scheduled in `tasks.md` with status `[TODO]`
- **WHEN** the agent attempts the task by modifying file A at line X with content Y
- **AND** that first attempt fails with error E
- **THEN** the agent recognizes that the original approach was to modify file A at line X
- **WHEN** the agent then re-attempts and proposes the same modification (file A, line X, content Y) again
- **THEN** the agent logs this as "same strategy attempted twice" and does NOT increment the retry counter again
- **AND** the agent instead marks the task as `[BLOCKED]` after detecting the loop, with message "Identical strategy attempted twice — manual intervention required"
- **AND** the agent halts the phase

#### Scenario: Different approaches are counted as separate attempts

- **GIVEN** a task is scheduled in `tasks.md` with status `[TODO]`
- **WHEN** the agent attempts the task by modifying file A
- **AND** that fails
- **THEN** the agent attempts a different approach: modifying file B
- **AND** that also fails
- **THEN** two separate attempts are counted (not one)
- **AND** a third different approach (modifying file C) counts as the third attempt
- **AND** if all three approaches fail, the task is marked `[BLOCKED]`

### Requirement: User Resume Path

After a task is marked BLOCKED, the user MUST be able to resolve the block and resume the `sdd-apply` phase.

#### Scenario: User resolves block and updates tasks.md to TODO

- **GIVEN** a task is marked `[BLOCKED]` in `tasks.md` with a resolution instruction
- **WHEN** the user reads the instruction, takes the suggested action (e.g., clarifies requirements, fixes a dependency, prepares the environment)
- **THEN** the user updates the task status in `tasks.md` from `[BLOCKED]` back to `[TODO]`
- **AND** the user re-invokes `/sdd-apply <change-name>`
- **THEN** the agent resets the retry counter for that task to 0/3
- **AND** the agent re-attempts the task

#### Scenario: User clears all blocked tasks before resume

- **GIVEN** multiple tasks are marked `[BLOCKED]` in different phases or sub-sections
- **WHEN** the user updates all of them back to `[TODO]`
- **AND** the user re-invokes `/sdd-apply <change-name>`
- **THEN** the agent processes all updated tasks with reset retry counters

### Requirement: Configuration of Max Retries

The maximum number of retry attempts MUST be configurable via the project's SDD configuration.

#### Scenario: Default max attempts is 3

- **GIVEN** no explicit configuration is set in `openspec/config.yaml` for `apply_max_retries`
- **WHEN** `sdd-apply` is invoked
- **THEN** the default maximum attempts per task is 3

#### Scenario: Custom max attempts via openspec/config.yaml

- **GIVEN** the project's `openspec/config.yaml` contains an entry `apply_max_retries: 5`
- **WHEN** `sdd-apply` is invoked
- **THEN** the maximum attempts per task is 5
- **AND** the agent logs the configured value in its initial output

### Requirement: BLOCKED State Marking in tasks.md

When a task exceeds the maximum retry attempts, it MUST be clearly marked as BLOCKED in the `tasks.md` file with all relevant context.

#### Scenario: BLOCKED task format in tasks.md

- **GIVEN** a task has failed 3 times and must be marked BLOCKED
- **WHEN** the agent updates `tasks.md`
- **THEN** the task line is changed from `- [TODO] Task 2.3 — description` to `- [BLOCKED] Task 2.3 — description`
- **AND** below that line, the agent adds a block with:
  ```
  - Attempts: 3/3
  - Tried:
    1. [summary of first attempt: what was changed, what error occurred]
    2. [summary of second attempt]
    3. [summary of third attempt]
  - Last error: [the error message or output from the third attempt]
  - Resolution required: [specific question or action for the user]
  ```

### Requirement: Agent Stop Behavior on BLOCKED

When a task is marked BLOCKED, the agent MUST stop the current phase and report the block to the user.

#### Scenario: Phase halts after BLOCKED task

- **GIVEN** a task is marked `[BLOCKED]` after 3 failed attempts
- **WHEN** the agent updates `tasks.md`
- **THEN** the agent immediately reports the BLOCKED state to the user with:
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
- **AND** the agent does NOT continue to the next task in the phase
- **AND** the agent does NOT proceed to the next phase

---

## Rules

- Retry counter is per-task, not per-phase. Each task starts with a clean counter.
- Default max_attempts is 3, configurable via `openspec/config.yaml` with key `apply_max_retries`.
- "Same strategy" detection is conservative: if two attempts modify the same files in the same way, count as one. If unsure, count as different attempts.
- BLOCKED tasks MUST have a resolution instruction that is specific and actionable (not vague).
- Resume requires the user to explicitly change the status back to `[TODO]` — it is not automatic.
- The agent MUST NOT continue to the next task after a BLOCKED task — the phase stops.
- Retry counter MUST be reset when a task is successfully completed or when resume is triggered.
