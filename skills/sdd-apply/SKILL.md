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
4. `openspec/config.yaml` — project rules
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

### Step 4 — Implement task by task

#### If TDD mode is NOT active (standard flow):

For each assigned task:

1. **I read the task** in tasks.md
2. **I consult the specs** for the affected domain (success criteria)
3. **I consult the design** (interfaces, decisions, patterns)
4. **I read existing code** in related files (to follow the pattern)
5. **I write the code** following all of the above
6. **I mark the task as complete** in tasks.md: `- [x]`

#### If TDD mode is active (RED-GREEN-REFACTOR flow):

For each assigned task:

1. **I read the task** in tasks.md
2. **I consult the specs** for the affected domain — identify the Given/When/Then scenarios this task covers
3. **I consult the design** (interfaces, decisions, patterns)
4. **I read existing code** in related files (to follow the pattern)
5. **RED — Write a failing test:**
   - I write a test that captures the expected behavior from the spec scenario(s)
   - The test name or description SHOULD reference the spec scenario name
   - I run the test to confirm it fails. If it passes unexpectedly, I report a DEVIATION noting the behavior was already implemented
6. **GREEN — Write minimum code to pass:**
   - I write only the minimum code necessary to make the test pass
   - I do NOT add extra features, optimizations, or abstractions in this phase
   - I run the test to confirm it passes
7. **REFACTOR — Clean up while tests stay green:**
   - I clean up the code (remove duplication, improve naming, etc.)
   - I run the tests after refactoring to confirm they still pass
   - If a test breaks during refactoring, I fix the code (not the test) to restore the green state
8. **I mark the task as complete** in tasks.md: `- [x]` — only after REFACTOR is done

### Step 5 — Respect the design

If during implementation I find that the design has a problem:

- **I do NOT fix it silently**
- I note it in my report as "DEVIATION: [what and why]"
- If it is a blocker, I stop and report `status: blocked`

### Step 6 — Update progress in tasks.md

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
