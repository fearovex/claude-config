---
name: sdd-apply
description: >
  Implements SDD plan tasks following specs and design, marking progress in tasks.md as it goes.
  Trigger: /sdd-apply <change-name>, implement change, apply SDD tasks, write code for change.
format: procedural
model: sonnet
thinking: enabled
---

# sdd-apply

> Implements the plan tasks following specs and design, marking progress as it goes.

**Triggers**: `/sdd-apply <change-name>`, implement change, write code, apply changes, sdd apply

---

## Purpose

The implementation phase converts the task plan into real code. The implementer follows the specs (WHAT to do) and the design (HOW to do it), marking tasks as completed in real time.

---

## Process

### Step 0 — Technology Skill Preload

#### Step 0a — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the project's `CLAUDE.md` (at project root) and extract the `## Skills Registry` section.

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`

Loaded context is used as enrichment throughout all subsequent steps. It informs architectural
coherence, naming consistency, and skill alignment checks—but does NOT override explicit
content in the proposal or design.

Before reading the change context, I load technology-specific skills to ensure their patterns and conventions are available throughout implementation.

#### Scope guard

I first check whether this is a documentation-only change by inspecting the File Change Matrix in `openspec/changes/<change-name>/design.md`. I scan every file listed in the matrix:

```
scope_guard_triggered = true
for each file in design.md file change matrix:
    if file extension not in [".md", ".yaml", ".yml"]:
        scope_guard_triggered = false
        break
if scope_guard_triggered:
    → report: "Tech skill preload: skipped (documentation-only change)"
    → skip remainder of Step 0
```

#### Stack detection

I detect the project technology stack using two sources in priority order:

**Primary — `ai-context/stack.md`:**
I read the file and extract all technology keywords (case-insensitive, free text).

**Secondary — `openspec/config.yaml` `project.stack` key:**
Used only when `ai-context/stack.md` is absent. I read `project.stack` and extract keywords from its values.

If neither source is available:
→ report: `"Tech skill preload: skipped (no stack source found — ai-context/stack.md absent and openspec/config.yaml has no project.stack)"`
→ skip remainder of Step 0

#### Stack-to-Skill Mapping Table

I match detected keywords (case-insensitive substring match) against the following table:

| Keyword(s)                    | Skill path                                              |
| ----------------------------- | ------------------------------------------------------- |
| always (non-doc changes)      | `~/.claude/skills/solid-ddd/SKILL.md`                   |
| react native, expo            | `~/.claude/skills/react-native/SKILL.md`                |
| react                         | `~/.claude/skills/react-19/SKILL.md`                    |
| next, nextjs, next.js         | `~/.claude/skills/nextjs-15/SKILL.md`                   |
| typescript, ts                | `~/.claude/skills/typescript/SKILL.md`                  |
| zustand                       | `~/.claude/skills/zustand-5/SKILL.md`                   |
| zod                           | `~/.claude/skills/zod-4/SKILL.md`                       |
| tailwind                      | `~/.claude/skills/tailwind-4/SKILL.md`                  |
| ai sdk, vercel ai, ai-sdk     | `~/.claude/skills/ai-sdk-5/SKILL.md`                    |
| electron                      | `~/.claude/skills/electron/SKILL.md`                    |
| django, drf                   | `~/.claude/skills/django-drf/SKILL.md`                  |
| spring boot, spring-boot      | `~/.claude/skills/spring-boot-3/SKILL.md`               |
| hexagonal, ports and adapters | `~/.claude/skills/hexagonal-architecture-java/SKILL.md` |
| java                          | `~/.claude/skills/java-21/SKILL.md`                     |
| playwright                    | `~/.claude/skills/playwright/SKILL.md`                  |
| pytest, python test           | `~/.claude/skills/pytest/SKILL.md`                      |
| github pr, pull request       | `~/.claude/skills/github-pr/SKILL.md`                   |
| jira task                     | `~/.claude/skills/jira-task/SKILL.md`                   |
| jira epic                     | `~/.claude/skills/jira-epic/SKILL.md`                   |
| elixir, phoenix               | `~/.claude/skills/elixir-antipatterns/SKILL.md`         |
| excel, xlsx, spreadsheet      | `~/.claude/skills/excel-expert/SKILL.md`                |
| ocr, image text, image ocr    | `~/.claude/skills/image-ocr/SKILL.md`                   |

> Note: `react native` and `expo` are matched before `react` to avoid the shorter keyword absorbing the longer one. Match order in the table is top-to-bottom; once a keyword matches a row, that row's skill is queued for loading.

> Note: The `always (non-doc changes)` row is evaluated after the scope guard. If `scope_guard_triggered` is `true` (documentation-only change), this row is also skipped — along with all other rows in the table.

#### Step 0b — Initialize retry counter

This step initializes the in-memory retry counter that the task execution loop uses to enforce the circuit breaker. It MUST run after the scope guard (regardless of whether the scope guard triggered) and before Step 1.

**Read `apply_max_retries` from `openspec/config.yaml`:**

```
if openspec/config.yaml exists and has key apply_max_retries:
    max_attempts = openspec/config.yaml.apply_max_retries
    → log: "Retry limit: max_attempts = [value] (source: openspec/config.yaml)"
else:
    max_attempts = 3   # default
    → log: "Retry limit: max_attempts = 3 (default — apply_max_retries not set in openspec/config.yaml)"
```

**Initialize attempt counter:**

```
attempt_counter = {}   # task_id → attempt count; starts empty; per-invocation only
```

The counter is **in-memory and per-invocation**. Each `/sdd-apply` invocation starts with a fresh counter. If a task was previously blocked and the user resumes by changing `[BLOCKED]` back to `[TODO]`, the counter resets to 0 for that task.

**Circuit breaker behavior:**

When `attempt_counter[task_id] >= max_attempts` before a new attempt, the task is immediately marked `[BLOCKED]` and the phase halts. The user must resolve the block and re-run `/sdd-apply <change-name>` to resume.

#### Skill loading

For each matched skill path:

- If the file exists on disk → read its contents and load its patterns into context
- If the file does not exist on disk → skip silently; note: `"<skill-name>: skipped (file not found at <path>)"`

This step MUST NOT produce `status: blocked` or `status: failed` under any circumstance. All failure modes degrade to INFO or skip.

#### Detection report

```
Tech skill preload:
  - <skill-name> loaded (source: ai-context/stack.md)
  - <skill-name> loaded (source: openspec/config.yaml)
  - <skill-name>: skipped (file not found at ~/.claude/skills/<skill-name>/SKILL.md)

[or, if entire step skipped:]
Tech skill preload: skipped (documentation-only change)
Tech skill preload: skipped (no stack source found — ai-context/stack.md absent and openspec/config.yaml has no project.stack)
```

The list of loaded skills is carried forward and included in the Step 2 detection output line:
`"Technology skills loaded: [typescript, react-19, playwright]"` (or `"none"` if preload was skipped or no matches).

---

### Step 1 — Read full context

I read in this order:

1. `openspec/changes/<change-name>/tasks.md` — which tasks are assigned
2. `openspec/changes/<change-name>/specs/` — the success criteria (WHAT it must do)
3. `openspec/changes/<change-name>/design.md` — how to implement it (technical decisions, interfaces)
4. `openspec/config.yaml` — project rules, including the optional `diagnosis_commands` key (see Step 4 — Diagnosis); key is optional, absent means auto-detection only, commands are expected to be read-only
5. `ai-context/conventions.md` — code conventions
6. Existing code files that I will modify or that serve as pattern references

### Step 2 — Detect Implementation Mode

Before implementing, I determine whether to use TDD (test-driven development) mode. I check three sources in priority order:

**Source 1 — Explicit config (highest priority):**
I read `openspec/config.yaml` and look for a `tdd` key:

- `tdd: true` or `tdd.enabled: true` → TDD mode is **ON**. Report: `"TDD mode: ON (source: config)"`
- `tdd: false` or `tdd.enabled: false` → TDD mode is **OFF**. Report: `"TDD mode: OFF (explicitly disabled in config)"`. Skip Sources 2 and 3.
- Key not present → continue to heuristic detection (Sources 2 and 3).

**Source 2 — Testing skills in project CLAUDE.md:**
I scan the project's CLAUDE.md skills registry for testing-related skills (e.g. `playwright`, `pytest`, `vitest`, `jest`, or any skill whose name or description indicates testing). If found → `signal_count++`.

**Source 3 — Test file patterns in the codebase:**
I search for existing test files matching common patterns: `*.test.*`, `*.spec.*`, `test_*`, `*_test.*`. If at least one match is found → `signal_count++`.

**Decision (when no explicit config):**

- `signal_count >= 2` → TDD mode is **ON**. Report: `"TDD mode: ON (source: testing skill + test files)"`
- `signal_count == 1` → TDD mode is **OFF**. Report: `"TDD mode: OFF ([signal found] but insufficient signals)"`
- `signal_count == 0` → TDD mode is **OFF**. Report: `"TDD mode: OFF"`

The detection step MUST NOT install test frameworks, create test files, or modify any configuration. Its only observable effect is the detection report line, which also includes the technology skills summary from Step 0.

### Step 3 — Verify work scope

The orchestrator tells me which tasks to implement (e.g. "Phase 1, tasks 1.1-1.3").
I implement ONLY those tasks. I do not advance to the next ones without confirmation.

### Step 4 — Diagnosis

Before making any file change for each assigned task, I MUST execute a Diagnosis Step. No file write or edit operation is permitted until the `DIAGNOSIS` block for that task has been written.

#### 4.1 — Read files to be modified

I read every file I intend to modify in its current state. For tasks that create new files, I read related files that serve as pattern references.

#### 4.2 — Run diagnostic commands

I check `openspec/config.yaml` for a `diagnosis_commands` key:

- **Present**: I run each listed command (expected to be read-only). I capture the output (or a summary) for inclusion in the `DIAGNOSIS` block. A command that exits non-zero is recorded as a failure; it MUST NOT block the Diagnosis Step — I note the failure in the Risk field and continue.
- **Absent**: I use only auto-detected read-only commands relevant to the task (or none). I note `"diagnosis_commands: not configured"` in the block.

#### 4.3 — Write DIAGNOSIS block

I write the following structured block in my task output before proceeding to implementation:

```
DIAGNOSIS — Task X.Y:
  1. Files to be modified: [list of paths]
  2. Diagnostic command outputs:
     - [command]: [output summary]
     (or "none applicable" / "diagnosis_commands: not configured")
  3. Current behavior observation: [what the code actually does now]
  4. Relevant data/state: [key data values, config, environment state]
  5. Hypothesis: "The bug/issue is [X] because [Y].
     Changing [Z] will achieve [expected behavior] because [rationale]."
  6. Risk: [what could go wrong with this change]
```

For file-creation tasks: field 3 describes the gap (what is absent), field 5 describes what the new file is intended to do and why.

#### 4.4 — Check for contradictions

If the Diagnosis Step reveals that the current system state contradicts the assumptions underlying the task description, I MUST produce a `MUST_RESOLVE` warning and pause for user confirmation before proceeding:

```
⚠️ MUST_RESOLVE — Diagnosis finding:
  Task X.Y assumes [A], but current state shows [B].

  This may indicate the task description is based on incorrect assumptions.

  Confirm how to proceed:
  Option 1: [proceed with updated understanding]
  Option 2: [revise task description]
```

If there are multiple contradictions, I MUST list each one as a separate item within the single `MUST_RESOLVE` block and wait for one combined user confirmation before proceeding.

If diagnosis confirms the expected state, I proceed immediately to Step 5.

### Step 5 — Implement task by task

#### Step 5a — Check for warnings before executing each task

Before executing any task, I inspect the task entry in `tasks.md` for a `[WARNING: MUST_RESOLVE]` or `[WARNING: ADVISORY]` marker.

**If `[WARNING: MUST_RESOLVE]` is present and no `Answer:` has been recorded yet:**

I MUST stop and present the following blocking gate to the user:

```
⛔ BLOCKED — Task X.Y has an unresolved MUST_RESOLVE warning:
  [warning text from tasks.md]

You must answer before implementation can proceed:
  → [Question from tasks.md or derived from warning]

Type your answer to continue.
```

I MUST NOT continue to the next step until an answer is received. I MUST NOT offer "Ready to continue?" or any other prompt that allows bypassing the answer.

**Answer recording:** Once the user provides an answer, I MUST append the following block to the task entry in `tasks.md`, immediately after the `Question:` line:

```markdown
  Answer: [exact text of the user's answer]
  Answered: [ISO 8601 timestamp, e.g., 2026-03-10T14:35:00Z]
```

After recording the answer, I proceed with task execution.

**If `[WARNING: MUST_RESOLVE]` is present AND an `Answer:` is already recorded:**

The warning has already been resolved. I proceed with task execution without presenting the blocking gate again.

**If `[WARNING: ADVISORY]` is present:**

I log the advisory warning to the progress output in the format:

```
ℹ️ ADVISORY — Task X.Y: [warning text]
```

I MUST NOT request user input. I continue execution of the task immediately after logging.

#### If TDD mode is NOT active (standard flow):

For each assigned task:

1. **I check for warnings** per Step 5a (MUST_RESOLVE blocks; ADVISORY is logged and continues)
2. **I read the task** in tasks.md — extract `task_id` (e.g., `1.1`, `2.3`)
3. **Check attempt counter BEFORE attempting the task:**
   - If `attempt_counter[task_id]` is undefined → set `attempt_counter[task_id] = 0`
   - If `attempt_counter[task_id] >= max_attempts`:
     - → Mark task `[BLOCKED]` in tasks.md (see BLOCKED State section below)
     - → Halt the current phase immediately
     - → Report BLOCKED state to user (see BLOCKED Reporting section below)
     - → **STOP — do NOT continue to the next task**
4. **Increment attempt counter:** `attempt_counter[task_id]++` — record the current strategy snapshot: `file_snapshot = list of all files this attempt will modify`
5. **I consult the specs** for the affected domain (success criteria)
6. **I consult the design** (interfaces, decisions, patterns)
7. **I read existing code** in related files (to follow the pattern)
8. **I implement the task** following specs and design
9. **Check success:**
   - **Success** (all file operations complete, output as expected, no tool errors):
     - Mark task `[x]` in tasks.md
     - Optionally reset `attempt_counter[task_id] = 0` (clean state)
     - Proceed to next task
   - **Failure** (tool error, validation error, unexpected output):
     - Capture current `file_snapshot_after` and the error output
     - **Same-strategy detection:** compare `file_snapshot_after` with the snapshot from the previous attempt (if any):
       - If both attempts modified the same files in the same way (see Same-Strategy Detection below):
         - → Mark task `[BLOCKED]` with message `"Identical strategy attempted twice — manual intervention required"`
         - → Halt the current phase
         - → Report BLOCKED state to user
         - → **STOP — do NOT continue to the next task**
       - Otherwise (different strategy):
         - Increment `attempt_counter[task_id]` again
         - If `attempt_counter[task_id] >= max_attempts`:
           - → Mark task `[BLOCKED]` (see BLOCKED State section below)
           - → Halt phase, report to user
           - → **STOP — do NOT continue to the next task**
         - Otherwise: re-attempt the task with a different approach (loop back to step 8)

#### Same-Strategy Detection

Two consecutive attempts are the **same strategy** if they modified exactly the same set of files AND the content changes to each file were identical:

```
def is_same_strategy(previous_attempt, current_attempt):
    files_prev = set(previous_attempt.files_modified.keys())
    files_curr = set(current_attempt.files_modified.keys())

    # Different files touched → different strategy
    if files_prev != files_curr:
        return False

    # Same files → compare content changes
    for file_path in files_prev:
        if previous_attempt.files_modified[file_path] != current_attempt.files_modified[file_path]:
            return False

    return True  # Same files, same content changes → same strategy
```

If unsure whether strategies match, count them as **different** (conservative default).

#### BLOCKED State — Marking tasks.md

When a task must be marked BLOCKED, I update `tasks.md` BEFORE halting or reporting. The task line is changed from `- [ ] X.Y description` to `- [BLOCKED] X.Y description`, and a block is appended immediately below:

```markdown
- [BLOCKED] Task X.Y — description
  - Attempts: N/max_attempts
  - Tried:
    1. [summary of first attempt: what files were modified, what error occurred]
    2. [summary of second attempt]
    3. [summary of third attempt]
  - Last error: [the error message or output from the final attempt]
  - Resolution required: [specific, actionable instruction for the user — not vague]
```

The attempt summary MUST include:
- What files were modified in that attempt
- What error or failure was observed
- For same-strategy detection blocks: note "Identical strategy detected"

#### BLOCKED Reporting — Output to user

After updating `tasks.md`, I report the BLOCKED state to the user:

```
⛔ Task X.Y BLOCKED after N attempts.

What was tried:
  1. [attempt 1 summary]
  2. [attempt 2 summary]
  3. [attempt 3 summary]

Last error: [error from final attempt]

tasks.md updated. Manual intervention required.
Resume after resolving: /sdd-apply <change-name>
```

I MUST NOT continue to the next task or the next phase after this report.

#### If TDD mode is active (RED-GREEN-REFACTOR flow):

For each assigned task:

1. **I check for warnings** per Step 5a (MUST_RESOLVE blocks; ADVISORY is logged and continues)
2. **I read the task** in tasks.md — extract `task_id`
3. **Check attempt counter BEFORE attempting the task** (same logic as standard flow step 3): if `attempt_counter[task_id] >= max_attempts`, mark `[BLOCKED]`, halt phase, report to user, STOP.
4. **Increment attempt counter:** `attempt_counter[task_id]++`
5. **I consult the specs** for the affected domain — identify the Given/When/Then scenarios this task covers
6. **I consult the design** (interfaces, decisions, patterns)
7. **I read existing code** in related files (to follow the pattern)
8. **RED — Write a failing test:**
   - I write a test that captures the expected behavior from the spec scenario(s)
   - The test name or description SHOULD reference the spec scenario name
   - I run the test to confirm it fails. If it passes unexpectedly, I report a DEVIATION noting the behavior was already implemented
9. **GREEN — Write minimum code to pass:**
   - I write only the minimum code necessary to make the test pass
   - I do NOT add extra features, optimizations, or abstractions in this phase
   - I run the test to confirm it passes
10. **REFACTOR — Clean up while tests stay green:**
    - I clean up the code (remove duplication, improve naming, etc.)
    - I run the tests after refactoring to confirm they still pass
    - If a test breaks during refactoring, I fix the code (not the test) to restore the green state
11. **I mark the task as complete** in tasks.md: `- [x]` — only after REFACTOR is done

### Step 6 — Respect the design

If during implementation I find that the design has a problem:

- **I do NOT fix it silently**
- I note it in my report as "DEVIATION: [what and why]"
- If it is a blocker, I stop and report `status: blocked`

### Step 7 — Update progress in tasks.md

I update the progress counter in tasks.md:

```markdown
## Progress: [completed]/[total] tasks
```

And I mark each completed task:

```markdown
- [x] 1.1 Create `src/types/auth.types.ts` ✓
- [x] 1.2 Create `src/schemas/auth.schema.ts` ✓
- [ ] 1.3 Modify `src/config/jwt.config.ts`
```

---

## Quality Gate

### I always follow project conventions

If `ai-context/conventions.md` exists, I apply it strictly.
If not, I observe the existing code and follow its patterns.

### I load technology skills if applicable

Technology skills and `solid-ddd` are loaded automatically in Step 0 — Technology Skill Preload. No manual judgment is required here.

### Quality Gate checklist

Before marking any code task `[x]`, I evaluate each criterion below. For each item I mark one of: ✅ (satisfied) | ❌ VIOLATION | N/A — [reason].

1. **Single Responsibility (SRP)**: Does each new or modified class, function, or module have exactly one reason to change? Signal: can it be described in one sentence without using "and"? If not → `QUALITY_VIOLATION: SRP — <description>`.
2. **Abstraction appropriateness (OCP)**: Is new behavior added via extension (new file/class/interface) rather than modification of existing stable code? Are abstractions justified by actual reuse or testability need today — not speculatively? Premature abstractions with no current consumer → `QUALITY_VIOLATION: OCP — <description>`.
3. **Dependency direction (DIP)**: Do high-level modules depend on abstractions (interfaces/ports), not on concrete implementations? Dependencies pointing inward toward stable abstractions → PASS. Outward dependencies on volatile implementations → `QUALITY_VIOLATION: DIP — <description>`.
4. **Domain model integrity**: Is business logic inside domain objects (entities, aggregates, value objects), not leaked into services or controllers? An anemic domain model (domain objects with only getters/setters and no behavior) → `QUALITY_VIOLATION: Domain model — <description>`. Mark N/A if the task does not touch domain model code.
5. **Layer separation**: Does the code respect the architectural layers defined in the design (e.g., domain → application → infrastructure)? Cross-layer leakage (e.g., infrastructure detail in a domain entity) → `QUALITY_VIOLATION: Layer separation — <description>`.
6. **No scope creep**: Does the implementation stay strictly within the task's defined scope (tasks.md + design.md)? Files or features outside the scope → `QUALITY_VIOLATION: Scope creep — <description>`, escalated to `DEVIATION` if it contradicts an observable behavior in the spec.
7. **Naming clarity**: Do names (classes, functions, variables) reveal intent without requiring a comment to explain them? If a name needs a comment to be understood, rename it first → `QUALITY_VIOLATION: Naming — <description>`.

**Reporting rules:**

- `N/A — [one-line reason]`: the criterion does not apply to this task (e.g., "task adds a CLI flag — no domain model touched").
- `QUALITY_VIOLATION: <principle> — <description>`: criterion fails. Fix the code BEFORE marking `[x]`. If fixing requires scope outside this task, report as `DEVIATION: <principle> — <description>` and set `status: warning`.
- Non-contradicting violations do NOT block the apply phase. The orchestrator MUST surface all `QUALITY_VIOLATION` notes in the phase summary.
- A violation that contradicts a scenario in the spec MUST be escalated to `DEVIATION` and MUST set `status: warning`.

### No over-engineering

- I implement the minimum necessary to pass the spec's scenarios
- I do not add features that are not in the proposal
- I do not refactor code that is not part of the change

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked|failed",
  "summary": "Implemented [N] tasks of [total]. Phase [X] complete. [TDD mode: active — RED/GREEN/REFACTOR cycle used per task.]",
  "tdd_mode": true,
  "artifacts": [
    "src/services/auth.service.ts — created",
    "src/types/auth.types.ts — created",
    "openspec/changes/<name>/tasks.md — updated"
  ],
  "deviations": ["DEVIATION in task 2.1: [description and reason]"],
  "next_recommended": ["sdd-apply (Phase 2)"],
  "risks": []
}
```

> The `tdd_mode` field is `true` when TDD mode was active, `false` otherwise. When `true`, the `summary` field mentions that TDD mode was used.

---

## Rules

- I read specs BEFORE writing code — they are my acceptance criteria
- I follow design decisions — I do not ignore or silently improve them
- I follow existing project patterns — I do not introduce new ones without justification
- I mark tasks as completed AT THE MOMENT I finish them
- If a task is blocked, I stop and report — I do not skip it
- I do not implement tasks outside my assigned scope
- I do not modify specs or design during implementation
- If something in the spec is ambiguous, I ask before assuming
- `MUST_RESOLVE` warnings MUST block execution until the user provides an explicit answer — there is no skip option
- `ADVISORY` warnings MUST be logged to output but MUST NOT interrupt the execution flow or request user input
