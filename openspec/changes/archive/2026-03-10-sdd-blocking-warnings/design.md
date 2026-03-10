# Technical Design: sdd-blocking-warnings

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-blocking-warnings/proposal.md

## General Approach

Implement a two-tier warning system in the SDD orchestration pipeline. The classification rules are applied at task planning time (sdd-tasks). The blocking gate is enforced at implementation time (sdd-apply). Warnings are persistent: recorded in tasks.md with classifications and reasons, and updated with user answers as they are resolved.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Warning storage | tasks.md inline entries with `[WARNING: TYPE]` markers | Separate warning manifest file; metadata in YAML | Warnings are most useful next to the tasks they describe; keeps all context in one document |
| Classification timing | sdd-tasks (planning phase) | sdd-apply (execution phase) | Allows user to see all risks upfront before execution; aligns with spec/design review gates |
| Gate presentation | Direct blocking message with no skip option | Yes/no confirmation prompt | Skip option undermines the blocking mechanism and could hide unresolved ambiguities in implementation |
| Answer recording | Append to task.md with timestamp and exact user text | Database table; separate answer log | Simple, inspectable, versioned with git; answers are part of the change record |
| Answer preservation | Keep all answers in tasks.md permanently | Archive after implementation | Answers document design decisions and assumptions — valuable for future context and retrospectives |

## Data Flow

```
sdd-tasks phase:
  Read design.md file matrix
    ↓
  For each task: scan for ambiguities/risks
    ↓
  Classify: MUST_RESOLVE or ADVISORY with reason
    ↓
  Write to tasks.md with [WARNING: TYPE] marker
    ↓
  Return tasks.md to user

sdd-apply phase:
  Read tasks.md
    ↓
  Begin task execution
    ↓
  Check for [WARNING: MUST_RESOLVE]
    ↓ (if present)
  Present blocking gate to user
    ↓
  Wait for explicit answer
    ↓
  Record answer in tasks.md + timestamp
    ↓
  Execute task
    ↓
  Check for [WARNING: ADVISORY]
    ↓ (if present)
  Log warning + continue (no wait)
    ↓
  Complete task execution
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-tasks/SKILL.md` | Modify | Add Step 4a — Warning Classification Rules and Step 4b — Record warnings in tasks.md format |
| `skills/sdd-apply/SKILL.md` | Modify | Add Step 3 — Check for MUST_RESOLVE warnings and present blocking gate; modify task execution loop to handle ADVISORY warnings inline |
| `openspec/changes/2026-03-10-sdd-blocking-warnings/specs/sdd-warning-classification/spec.md` | Create | Specification (observable behavior) for the warning classification system |
| `openspec/changes/2026-03-10-sdd-blocking-warnings/design.md` | Create | This file — technical design |
| `openspec/changes/2026-03-10-sdd-blocking-warnings/tasks.md` | Create | Task breakdown for implementation |

## Interfaces and Contracts

### tasks.md Warning Entry Format

```markdown
- [ ] X.Y Task description [WARNING: MUST_RESOLVE]
  Warning: [human-readable warning text]
  Reason: [classification reason, e.g., "business rule decision — external system field ambiguous"]
  Question: [clarifying question if not obvious from warning]
  
  Answer: [recorded after user provides input, with timestamp]
  ```
  Answered: [timestamp when answer was received]
  ```
```

### ADVISORY warning format (inline with task, no user input)

```markdown
- [ ] X.Y Task description [WARNING: ADVISORY]
  Warning: [human-readable warning text]
  Reason: [classification reason, e.g., "performance consideration — does not affect correctness"]
```

### sdd-apply blocking gate message contract

```
⛔ BLOCKED — Task X.Y has an unresolved MUST_RESOLVE warning:
  [warning text from tasks.md]

You must answer before implementation can proceed:
  → [Question from tasks.md or derived from warning]

Type your answer to continue.
```

The agent MUST NOT proceed until it receives user input. The input MUST be recorded in tasks.md with the exact text and a timestamp.

## Testing Strategy

| Layer | What to test | Tool |
|-------|--------------|------|
| Unit | Warning classification logic (identify MUST_RESOLVE vs ADVISORY from task description) | Manual review + integration test in /project-audit |
| Integration | sdd-tasks produces correctly formatted tasks.md entries with warning markers | Manual SDD cycle execution |
| E2E | sdd-apply blocks on MUST_RESOLVE, waits for answer, records it, then executes task | Manual SDD cycle with user interaction test |
| E2E | sdd-apply logs ADVISORY warnings but continues without interruption | Manual SDD cycle without user input |

## Migration Plan

No data migration required. This change applies only to new SDD cycles created after the feature is implemented.

Existing tasks.md files from archived changes are not affected — this is an optional feature for new changes.

## Open Questions

None.

