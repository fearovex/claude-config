---
name: sdd-apply
description: >
  Implements SDD plan tasks following specs and design, marking progress in tasks.md as it goes.
  Trigger: /sdd-apply <change-name>, implement change, apply SDD tasks, write code for change.
format: procedural
---

# sdd-apply

> Implements the plan tasks following specs and design, marking progress as it goes.

**Triggers**: sdd:apply, implement, write code, apply changes, sdd apply

---

## Purpose

The implementation phase converts the task plan into real code. The implementer follows the specs (WHAT to do) and the design (HOW to do it), marking tasks as completed in real time.

---

## Process

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

The detection step MUST NOT install test frameworks, create test files, or modify any configuration. Its only observable effect is the detection report line.

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

## Code standards

### I always follow project conventions
If `ai-context/conventions.md` exists, I apply it strictly.
If not, I observe the existing code and follow its patterns.

### I load technology skills if applicable
If I am implementing in a specific stack, I load the corresponding skill:
- TypeScript → `~/.claude/skills/typescript/SKILL.md` if it exists
- React → `~/.claude/skills/react-19/SKILL.md` if it exists
- etc.

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
  "deviations": [
    "DEVIATION in task 2.1: [description and reason]"
  ],
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
