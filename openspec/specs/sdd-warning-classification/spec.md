# Spec: SDD Warning Classification and Blocking

Change: sdd-blocking-warnings
Date: 2026-03-10

## Requirements

### Requirement: Warning Classification System

The SDD system MUST classify each warning raised during task planning into one of two categories:
- `MUST_RESOLVE`: A warning that blocks progress until explicitly answered by the user
- `ADVISORY`: A warning that is logged but does not block progress

Each warning classification MUST include a reason statement explaining why it belongs in its category.

#### Scenario: Business rule decision flagged as MUST_RESOLVE
- **GIVEN** that `sdd-tasks` is analyzing a task involving a choice between multiple external system field options
- **WHEN** the task description includes ambiguity about which field to use (e.g., "Stripe invoice field for failure date")
- **THEN** the warning MUST be classified as `MUST_RESOLVE`
- **AND** the reason MUST state "business rule decision — external system behavior is ambiguous"

#### Scenario: Performance consideration flagged as ADVISORY
- **GIVEN** that `sdd-tasks` is analyzing a task involving potential performance concerns
- **WHEN** the performance concern does not affect functional correctness
- **THEN** the warning MUST be classified as `ADVISORY`
- **AND** the reason MUST state "performance consideration — does not affect correctness"

#### Scenario: Style preference flagged as ADVISORY
- **GIVEN** that `sdd-tasks` is analyzing a task involving a naming or code style question
- **WHEN** the question is a preference not required for current task completion
- **THEN** the warning MUST be classified as `ADVISORY`
- **AND** the reason MUST state "style or naming preference — no impact on current task"

### Requirement: Warning Documentation in tasks.md

Every warning raised during task planning MUST be recorded in `tasks.md` with its classification and reason visible.

#### Scenario: MUST_RESOLVE warning documented in tasks.md
- **GIVEN** that a task has a `MUST_RESOLVE` warning
- **WHEN** the task is listed in `tasks.md`
- **THEN** the task entry MUST include a `[WARNING: MUST_RESOLVE]` marker
- **AND** the warning text and reason MUST be recorded below the task
- **AND** once the user answers the question, the reason and answer MUST be recorded in `tasks.md` before the task is marked in-progress

#### Scenario: ADVISORY warning documented in tasks.md
- **GIVEN** that a task has an `ADVISORY` warning
- **WHEN** the task is listed in `tasks.md`
- **THEN** the task entry MUST include an `[WARNING: ADVISORY]` marker
- **AND** the warning text and reason MUST be recorded below the task

### Requirement: Blocking Gate in sdd-apply

Before `sdd-apply` executes a task flagged with `MUST_RESOLVE`, the agent MUST present the unresolved warning to the user and wait for an explicit answer. The agent MUST NOT offer an option to skip or proceed without answering.

#### Scenario: Blocked task presentation in sdd-apply
- **GIVEN** that `sdd-apply` is processing a task marked `MUST_RESOLVE`
- **WHEN** the agent begins processing that task
- **THEN** the agent MUST present a blocking message:
  ```
  ⛔ BLOCKED — Task X.Y has an unresolved MUST_RESOLVE warning:
    [warning text]
  
  You must answer before implementation can proceed:
    → [question derived from warning]
  
  Type your answer to continue.
  ```
- **AND** the agent MUST NOT continue to the next step until an answer is received
- **AND** the agent MUST NOT offer "Ready to continue?" or any other continuation prompt that allows bypassing the answer

#### Scenario: Answer recorded and task execution resumes
- **GIVEN** that the user has typed an answer to a `MUST_RESOLVE` question
- **WHEN** the agent receives the answer
- **THEN** the agent MUST record the answer in `tasks.md` under the task entry
- **AND** the recorded entry MUST preserve the timestamp and user's exact answer text
- **AND** the agent MUST then proceed with executing the task

### Requirement: ADVISORY warnings do not interrupt apply flow

When `sdd-apply` encounters a task flagged with `ADVISORY`, the agent MUST log the warning but MUST NOT interrupt the execution flow or request input.

#### Scenario: ADVISORY warning logged and apply continues
- **GIVEN** that `sdd-apply` is processing a task marked `ADVISORY`
- **WHEN** the agent encounters the warning
- **THEN** the agent MUST log the warning text to the progress output
- **AND** the agent MUST NOT request user input
- **AND** the agent MUST continue execution of the task immediately
- **AND** the warning text MUST appear in the task progress notes but not block the task

---

## Open Questions

None.
