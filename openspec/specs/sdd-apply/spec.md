# Spec: sdd-apply — Technology Skill Auto-Activation

*Created: 2026-03-03 by change "tech-skill-auto-activation"*

## Requirements

### Requirement: Step 0 — Technology Skill Preload

`sdd-apply` MUST execute a technology skill preload step (Step 0) before reading the change context (Step 1). Step 0 MUST be non-blocking: its failure or partial execution MUST NOT change the overall apply `status` to `blocked` or `failed`.

#### Scenario: Stack detected from ai-context/stack.md — matching skills exist

- **GIVEN** `ai-context/stack.md` exists and contains the keyword `"react"`
- **AND** `~/.claude/skills/react-19/SKILL.md` exists on disk
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** it reads the contents of `~/.claude/skills/react-19/SKILL.md`
- **AND** it adds those contents as implementation context for subsequent steps
- **AND** it reports: `"Tech skill loaded: react-19 (source: ai-context/stack.md)"`

#### Scenario: Stack detected — multiple matching skills

- **GIVEN** `ai-context/stack.md` contains keywords `"typescript"`, `"react"`, and `"playwright"`
- **AND** all three corresponding skill files exist on disk
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** it loads all three skills: `typescript`, `react-19`, `playwright`
- **AND** it reports one detection line per skill loaded

#### Scenario: Detected technology skill absent from disk

- **GIVEN** `ai-context/stack.md` contains `"django"`
- **AND** `~/.claude/skills/django-drf/SKILL.md` does NOT exist on disk
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** the missing skill is silently skipped
- **AND** no `blocked` or `failed` status is produced
- **AND** apply proceeds normally with Step 1

#### Scenario: ai-context/stack.md absent

- **GIVEN** the project has no `ai-context/stack.md` file
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** Step 0 is skipped with an INFO-level note: `"Tech skill preload: skipped (ai-context/stack.md not found)"`
- **AND** apply continues normally with Step 1

#### Scenario: Documentation-only change (scope guard)

- **GIVEN** the design.md file change matrix contains ONLY `.md` and `.yaml` file extensions (no source code files)
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** Step 0 is skipped with note: `"Tech skill preload: skipped (documentation-only change)"`
- **AND** apply continues normally with Step 1

#### Scenario: openspec/config.yaml stack section used as secondary source

- **GIVEN** `ai-context/stack.md` is absent
- **AND** `openspec/config.yaml` contains a `project.stack` section with `language: "typescript"`
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** it reads the `project.stack` section from `openspec/config.yaml`
- **AND** it applies keyword matching against the Stack-to-Skill Mapping Table
- **AND** it reports: `"Tech skill loaded: typescript (source: openspec/config.yaml)"`

---

### Requirement: Stack-to-Skill Mapping Table

`sdd-apply` MUST contain an exhaustive Stack-to-Skill Mapping Table that maps technology keywords to their corresponding skill paths. The table MUST cover all technology skills in the global catalog.

#### Scenario: Complete mapping coverage

- **GIVEN** the Stack-to-Skill Mapping Table is embedded in `sdd-apply/SKILL.md`
- **WHEN** a developer inspects the table
- **THEN** every technology skill in the CLAUDE.md Skills Registry is represented by at least one keyword row
- **AND** the mapping is unambiguous: each keyword maps to exactly one skill path

#### Scenario: Keyword matching is case-insensitive

- **GIVEN** `ai-context/stack.md` contains `"TypeScript"` (capital T)
- **AND** the mapping table has keyword `"typescript"` → `typescript/SKILL.md`
- **WHEN** Step 0 runs the matching
- **THEN** it matches `"TypeScript"` to `typescript` (case-insensitive comparison)
- **AND** `typescript` skill is loaded

---

### Requirement: Detection Report

`sdd-apply` MUST produce a detection report in its Step 0 output. The report MUST list every skill that was loaded or explain why preload was skipped.

#### Scenario: Normal detection report

- **GIVEN** Step 0 loaded two skills: `typescript` and `react-19`
- **WHEN** `sdd-apply` produces its output
- **THEN** the output includes:
  ```
  Tech skill preload:
    - typescript loaded (source: ai-context/stack.md)
    - react-19 loaded (source: ai-context/stack.md)
  ```

#### Scenario: Skipped skills appear in report

- **GIVEN** Step 0 detected `"python"` in stack.md
- **AND** `~/.claude/skills/pytest/SKILL.md` does not exist
- **WHEN** Step 0 produces the detection report
- **THEN** the report notes: `"pytest: skipped (file not found)"`

---

### Requirement: Backward compatibility with existing Code Standards section *(modified in: 2026-03-04 by change "solid-ddd-quality-enforcement")*

The existing `## Code standards` or `## Code Standards` section MUST be replaced (not supplemented) by the new Quality Gate section. The reference to "I load technology skills if applicable" MUST remain, forwarding to Step 0 as previously required.

*(Before: the Code Standards section contained vague directives with no actionable checklist — "follow conventions", "no over-engineering" — and instructed sub-agents to load technology skills but provided no enforcement mechanism for their patterns.)*

#### Scenario: old Code Standards section is fully replaced

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** a developer searches for the old vague directives ("follow conventions", "no over-engineering" as standalone instructions)
- **THEN** those phrases do NOT appear as the sole content of a quality criterion
- **AND** they are either absent or appear only as context within a more specific verifiable criterion

#### Scenario: Quality Gate section references Step 0 for skill loading

- **GIVEN** the updated Quality Gate section
- **WHEN** an implementer reads it
- **THEN** it references Step 0 as the mechanism by which technology skills and solid-ddd are loaded
- **AND** it does NOT re-list the loading logic inline

---

### Requirement: solid-ddd unconditional preload for all non-documentation code changes

*(Added in: 2026-03-04 by change "solid-ddd-quality-enforcement")*

`sdd-apply` MUST load `~/.claude/skills/solid-ddd/SKILL.md` during Step 0 for every non-documentation code change, regardless of the project's technology stack. The scope guard (documentation-only exclusion) that already gates tech skill preloads MUST also gate the `solid-ddd` preload — when the scope guard skips tech skill preloads, it MUST also skip `solid-ddd` preload. For all other changes, `solid-ddd` is always loaded alongside any matched framework skills.

#### Scenario: solid-ddd is loaded for a code-touching change with no stack match

- **GIVEN** `ai-context/stack.md` exists but contains no keyword matching any technology skill
- **AND** the design.md change matrix contains at least one non-documentation file extension
- **WHEN** `sdd-apply` executes Step 0
- **THEN** `~/.claude/skills/solid-ddd/SKILL.md` is read
- **AND** the Step 0 report includes: `"solid-ddd loaded (unconditional — code change)"`
- **AND** the sub-agent's implementation context includes the solid-ddd patterns

#### Scenario: solid-ddd is loaded alongside framework skills for a code-touching change

- **GIVEN** `ai-context/stack.md` contains `"react"` and `"typescript"`
- **AND** `~/.claude/skills/react-19/SKILL.md` and `~/.claude/skills/typescript/SKILL.md` exist
- **AND** the design.md change matrix contains `.tsx` and `.ts` files
- **WHEN** `sdd-apply` executes Step 0
- **THEN** `react-19`, `typescript`, AND `solid-ddd` are all loaded
- **AND** each is reported in the Step 0 detection report

#### Scenario: solid-ddd is skipped for documentation-only changes

- **GIVEN** the design.md change matrix contains ONLY `.md` and `.yaml` file extensions
- **WHEN** `sdd-apply` executes Step 0
- **THEN** neither framework skills NOR `solid-ddd` is loaded
- **AND** Step 0 reports: `"Tech skill preload: skipped (documentation-only change)"`

#### Scenario: solid-ddd file absent from disk — silently skipped

- **GIVEN** `~/.claude/skills/solid-ddd/SKILL.md` does NOT exist on disk
- **AND** the change is non-documentation
- **WHEN** `sdd-apply` Step 0 attempts to load `solid-ddd`
- **THEN** the missing file is silently skipped (same non-blocking rule as other tech skills)
- **AND** no `blocked` or `failed` status is produced
- **AND** apply proceeds normally with Step 1

#### Scenario: Stack-to-Skill Mapping Table contains the solid-ddd entry

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** a developer reads the Stack-to-Skill Mapping Table
- **THEN** an entry for `solid-ddd` is present
- **AND** the entry is marked as unconditional (or "all code changes") rather than keyword-triggered
- **AND** the path in the entry resolves to `~/.claude/skills/solid-ddd/SKILL.md`

---

### Requirement: sdd-apply enforces a structured Quality Gate before task completion

*(Added in: 2026-03-04 by change "solid-ddd-quality-enforcement")*

`sdd-apply` MUST replace the vague "Code Standards" or "Code standards" section with a structured Quality Gate. The Quality Gate MUST contain a numbered checklist of at least 5 independently verifiable criteria. A sub-agent executing a code task MUST evaluate each criterion before marking the task `[x]` complete.

#### Scenario: Quality Gate checklist has at least 5 criteria

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** a developer reads the Quality Gate section
- **THEN** the section contains a numbered list with at least 5 items
- **AND** each item is independently verifiable (a reader can determine pass/fail without ambiguity)
- **AND** no item is a vague directive like "follow conventions" or "no over-engineering" without a concrete signal

#### Scenario: Quality Gate covers single responsibility verification

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion explicitly asks the sub-agent to verify that each new class, function, or module has a single well-defined responsibility
- **AND** the criterion provides a concrete signal (e.g., "could this be described in one sentence without using 'and'?")

#### Scenario: Quality Gate covers abstraction and dependency direction

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion addresses dependency direction (higher-level modules do not import lower-level details directly)
- **AND** at least one criterion addresses abstraction appropriateness (no leaking of implementation details through public interfaces)

#### Scenario: Quality Gate covers domain model integrity

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion addresses domain model integrity — specifically, that business logic lives in domain objects, not solely in service classes
- **AND** the criterion is marked N/A-eligible when the task does not touch domain model code

#### Scenario: Quality Gate covers over-engineering prevention

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion explicitly checks that no speculative abstractions, unnecessary layers, or unused interfaces have been introduced
- **AND** the criterion provides a concrete signal (e.g., "is there a real use case today for this abstraction, or is it speculative?")

#### Scenario: N/A-with-reason is an accepted Quality Gate outcome

- **GIVEN** a sub-agent is evaluating the Quality Gate for a task that does not touch domain model code
- **WHEN** the sub-agent reaches the domain model integrity criterion
- **THEN** the sub-agent MAY mark that criterion as N/A
- **AND** the sub-agent MUST record a brief reason for the N/A (e.g., "task adds a CLI flag — no domain model touched")
- **AND** the N/A designation does NOT prevent the task from being marked `[x]` complete

#### Scenario: Quality Gate violation produces QUALITY_VIOLATION note

- **GIVEN** a sub-agent evaluates the Quality Gate and finds that a new class has more than one clear responsibility (SRP violation)
- **WHEN** the sub-agent reaches that criterion
- **THEN** the sub-agent MUST NOT silently mark the task `[x]` complete
- **AND** the sub-agent records a `QUALITY_VIOLATION: <description>` note in the task output
- **AND** the violation is escalated to `DEVIATION` status if it contradicts an observable behavior defined in the spec
- **AND** the task SHOULD be reworked before being marked complete, unless the sub-agent documents a specific justification

#### Scenario: QUALITY_VIOLATION is non-blocking by default

- **GIVEN** a sub-agent records a `QUALITY_VIOLATION` note on a task
- **AND** the violation does NOT contradict any scenario in the spec
- **WHEN** the sub-agent decides whether to continue
- **THEN** the sub-agent MAY continue to the next task without blocking the entire apply phase
- **AND** the orchestrator MUST surface the QUALITY_VIOLATION notes in the phase summary for user review
- **AND** the overall apply status MUST be `warning` (not `failed`) when violations are present but non-contradicting

---

### Requirement: loaded technology skills and solid-ddd are treated as acceptance criteria, not reference

*(Added in: 2026-03-04 by change "solid-ddd-quality-enforcement")*

When `sdd-apply` loads technology skills and/or `solid-ddd` in Step 0, the sub-agent MUST treat the patterns in those skills as acceptance criteria to be checked before task completion — not as contextual reference material to be optionally consulted.

#### Scenario: tech skill pattern used as acceptance criterion

- **GIVEN** `react-19` was loaded in Step 0
- **AND** a task requires implementing a React component
- **WHEN** the sub-agent completes the task implementation
- **THEN** the sub-agent verifies that the component follows the patterns in `react-19/SKILL.md`
- **AND** if the implementation contradicts a pattern (e.g., uses a deprecated API), the sub-agent records a `QUALITY_VIOLATION` note

#### Scenario: solid-ddd patterns used as acceptance criteria

- **GIVEN** `solid-ddd` was loaded in Step 0
- **AND** a task requires introducing a new class
- **WHEN** the sub-agent completes the task implementation
- **THEN** the sub-agent checks the new class against the SOLID and DDD patterns in `solid-ddd/SKILL.md`
- **AND** any identified violation is recorded as `QUALITY_VIOLATION` with a specific principle reference (e.g., "QUALITY_VIOLATION: SRP — AuthService handles both authentication and user profile updates")

---

### Requirement: Mandatory Diagnosis Step before each task implementation

*(Added in: 2026-03-10 by change "sdd-apply-diagnose-first")*

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

*(Added in: 2026-03-10 by change "sdd-apply-diagnose-first")*

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

*(Added in: 2026-03-10 by change "sdd-apply-diagnose-first")*

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

*(Added in: 2026-03-04 by change "solid-ddd-quality-enforcement")*

- The Quality Gate checklist MUST use a numbered list format (not bullet points) so items can be referenced by number in QUALITY_VIOLATION notes
- Each Quality Gate criterion MUST include a "what to look for" signal or heuristic — vague criteria are non-conforming
- The solid-ddd entry in the Stack-to-Skill Mapping Table MUST appear in a visually distinct row or with a comment indicating it is unconditional (not keyword-matched)
- QUALITY_VIOLATION notes MUST use the exact format `QUALITY_VIOLATION: <principle> — <description>` when a specific SOLID or DDD principle is implicated
- The N/A-with-reason option MUST be documented in the Quality Gate section itself, not only implied; a sub-agent MUST be able to find it without consulting external docs

*(Added in: 2026-03-10 by change "sdd-apply-diagnose-first")*

- The Diagnosis Step is **mandatory** — it MUST NOT be skipped even for simple or low-risk tasks
- The `DIAGNOSIS` block MUST be written **before** any file modification is attempted
- `MUST_RESOLVE` warnings pause task execution — the agent MUST NOT proceed past them without user input
- `diagnosis_commands` are expected to be **read-only** by convention; the user is responsible for ensuring their configured commands are non-destructive
- Diagnosis does NOT replace the existing Quality Gate — both apply

---

### Requirement: Retry Counter per Task

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

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

---

### Requirement: Same Strategy Detection

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

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

---

### Requirement: User Resume Path

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

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

---

### Requirement: Configuration of Max Retries

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

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

---

### Requirement: BLOCKED State Marking in tasks.md

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

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

---

### Requirement: Agent Stop Behavior on BLOCKED

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

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

## Rules (retry-limit additions)

*(Added in: 2026-03-10 by change "sdd-apply-retry-limit")*

- Retry counter is per-task, not per-phase. Each task starts with a clean counter.
- Default max_attempts is 3, configurable via `openspec/config.yaml` with key `apply_max_retries`.
- "Same strategy" detection is conservative: if two attempts modify the same files in the same way, count as one. If unsure, count as different attempts.
- BLOCKED tasks MUST have a resolution instruction that is specific and actionable (not vague).
- Resume requires the user to explicitly change the status back to `[TODO]` — it is not automatic.
- The agent MUST NOT continue to the next task after a BLOCKED task — the phase stops.
- Retry counter MUST be reset when a task is successfully completed or when resume is triggered.
