# Delta Spec: sdd-apply

Change: 2026-03-10-sdd-apply-diagnose-first
Date: 2026-03-10
Base: openspec/specs/sdd-apply/spec.md

---

## ADDED — New requirements

### Requirement: Mandatory Diagnosis Step before each task implementation

`sdd-apply` MUST execute a Diagnosis Step at the start of each task's implementation, before making any file changes. The Diagnosis Step MUST:
1. Read the files that will be modified to understand the current implementation.
2. Run relevant read-only commands to observe current behavior (e.g., test output, dry-run results).
3. Formulate an explicit written hypothesis recording: current behavior, root cause, intended change, and expected outcome.
4. Record the hypothesis in a `DIAGNOSIS` block in the task notes before proceeding.

The agent MUST NOT make any file changes before the Diagnosis Step is complete and the hypothesis is written.

#### Scenario: Diagnosis step runs before any file modification

- **GIVEN** `sdd-apply` is assigned a task that modifies `skills/sdd-apply/SKILL.md`
- **WHEN** the agent starts implementing the task
- **THEN** it MUST first read `skills/sdd-apply/SKILL.md` in its current state
- **AND** it MUST produce a written `DIAGNOSIS` block before writing any changes to the file

#### Scenario: Hypothesis structure is complete

- **GIVEN** the Diagnosis Step is executing for a task
- **WHEN** the agent writes the `DIAGNOSIS` block
- **THEN** the block MUST contain all five fields:
  - Files to be modified (list)
  - Read-only diagnostic command outputs (or "none run" if not applicable)
  - Current behavior observation (what the code actually does now)
  - Relevant data/state (config, environment, key values)
  - Hypothesis: "The bug/issue is [X] because [Y]. Changing [Z] will achieve [expected behavior] because [rationale]."
- **AND** the block MUST include a Risk field noting what could go wrong with the change

#### Scenario: Task with no read-only commands applicable

- **GIVEN** `sdd-apply` is assigned a task that creates a new file with no existing counterpart
- **WHEN** the agent executes the Diagnosis Step
- **THEN** it MUST still read related files that serve as pattern references
- **AND** it MUST still write a `DIAGNOSIS` block with "Diagnostic commands: none applicable"
- **AND** the hypothesis MUST describe what the new file is intended to do and why

#### Scenario: File changes do not occur before diagnosis is written

- **GIVEN** a task execution is observed
- **WHEN** the file edit log is examined
- **THEN** no file write/edit operation MUST appear before the `DIAGNOSIS` block has been recorded for that task

---

### Requirement: Diagnosis findings that contradict task assumptions trigger a MUST_RESOLVE warning

If the Diagnosis Step reveals that the current system state contradicts the assumptions underlying the task description, `sdd-apply` MUST surface a `MUST_RESOLVE` warning and pause for user confirmation before proceeding with the implementation.

#### Scenario: Diagnosis reveals contradicting state — warning raised

- **GIVEN** a task description states "the function `applyTask()` does not handle retries"
- **AND** the Diagnosis Step reveals that `applyTask()` already implements a retry loop
- **WHEN** the agent completes the Diagnosis Step
- **THEN** it MUST produce a `MUST_RESOLVE` warning block:
  ```
  ⚠️ MUST_RESOLVE — Diagnosis finding:
    Task X.Y assumes [A], but current state shows [B].
    This may indicate the task description is based on incorrect assumptions.
    Confirm how to proceed:
    Option 1: [proceed with updated understanding]
    Option 2: [revise task description]
  ```
- **AND** the agent MUST NOT proceed to file changes until the user has confirmed a path forward

#### Scenario: Diagnosis confirms expected state — no warning needed

- **GIVEN** a task description accurately describes the current state of the system
- **WHEN** the agent completes the Diagnosis Step
- **THEN** it produces only the `DIAGNOSIS` block (no `MUST_RESOLVE`)
- **AND** it proceeds immediately to the implementation

#### Scenario: Multiple contradicting assumptions in one task

- **GIVEN** the Diagnosis Step reveals two separate contradictions with the task description
- **WHEN** the agent produces the `MUST_RESOLVE` warning
- **THEN** it MUST list each contradiction as a separate item within the single `MUST_RESOLVE` block
- **AND** the agent MUST wait for a single user confirmation before proceeding

---

### Requirement: diagnosis_commands optional key in openspec/config.yaml

`openspec/config.yaml` MAY contain a top-level `diagnosis_commands` key that lists project-specific read-only shell commands for the Diagnosis Step to run. When present, `sdd-apply` MUST read and execute these commands as part of the Diagnosis Step for every task.

#### Scenario: diagnosis_commands present — commands are run during diagnosis

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  diagnosis_commands:
    - "npm test -- --dry-run"
    - "cat openspec/config.yaml"
  ```
- **WHEN** the Diagnosis Step runs for any task
- **THEN** the agent MUST run each listed command
- **AND** include the output (or a summary) in the `DIAGNOSIS` block under "Diagnostic command outputs"

#### Scenario: diagnosis_commands absent — step uses auto-detected commands only

- **GIVEN** `openspec/config.yaml` does NOT contain a `diagnosis_commands` key
- **WHEN** the Diagnosis Step runs
- **THEN** the agent uses only auto-detected read-only commands relevant to the task (or none)
- **AND** the `DIAGNOSIS` block notes "diagnosis_commands: not configured"

#### Scenario: diagnosis_commands contains a command that fails

- **GIVEN** `openspec/config.yaml` contains a command that exits non-zero
- **WHEN** the Diagnosis Step runs that command
- **THEN** the agent records the failure output in the `DIAGNOSIS` block
- **AND** the agent MUST NOT treat the failed command as a blocker — the Diagnosis Step continues
- **AND** the agent notes the failure in the Risk field of the `DIAGNOSIS` block

---

## Rules

- The Diagnosis Step is **mandatory** — it MUST NOT be skipped even for simple or low-risk tasks
- The `DIAGNOSIS` block MUST be written **before** any file modification is attempted
- `MUST_RESOLVE` warnings pause task execution — the agent MUST NOT proceed past them without user input
- `diagnosis_commands` are expected to be **read-only** by convention; the user is responsible for ensuring their configured commands are non-destructive
- Diagnosis does NOT replace the existing Quality Gate — both apply
