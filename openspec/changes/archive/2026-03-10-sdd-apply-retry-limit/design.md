# Technical Design: sdd-apply-retry-limit

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-apply-retry-limit/proposal.md

## General Approach

The `sdd-apply` skill will be modified to track attempt counts per task and enforce a circuit breaker. When a task exceeds the maximum retry attempts (default 3, configurable), it is marked `[BLOCKED]` in `tasks.md` with a summary of all attempts, the final error, and a specific resolution instruction. The phase halts to prevent context degradation. The user must explicitly resolve the block and update the task status back to `[TODO]` before resuming.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|----------------|
| Attempt tracking location | In-memory counter (per task, reset each session) | Persistent counter in tasks.md (before task start) | Simplicity: in-memory is sufficient because `/sdd-apply` is a single continuous execution. Persistent markers would require parsing and updating tasks.md repeatedly during execution. |
| Max attempts default | 3 | 5, unlimited with timeout | 3 is conservative and surfaces manual intervention earlier, preventing context loops. Matches industry SRE practices (e.g., circuit breakers). Still configurable for power users. |
| Configuration storage | `openspec/config.yaml` with key `apply_max_retries` | CLAUDE.md top-level, environment variable, hardcoded | Keeps project config in one place (openspec/config.yaml). Non-breaking: absent key defaults to 3. |
| Same-strategy detection | Hash-based file diff comparison (files changed + content delta) | Full AST-level comparison, instruction-level diffing | Hash-based is robust, conservative, and transparent. We detect "same files changed in same way" reliably. Avoids false positives of "different but equivalent" changes. |
| BLOCKED marker format | `[BLOCKED]` status in tasks.md (new status alongside TODO, x) | Separate BLOCKED_TASKS.md file, comment field in tasks.md | Inline marking is discoverable, human-readable, and integrates with existing task format. Single source of truth. |
| Phase halt behavior | Agent stops immediately and reports to user | Automatically skip and continue to next task | Fails fast to surface the problem. Context degradation is worse than stopping early. User must explicitly resolve and resume. |
| Resume mechanism | User edits tasks.md task status from `[BLOCKED]` back to `[TODO]`, re-runs `/sdd-apply` | Agent detects BLOCKED tasks and auto-retries after a delay | Manual resume is explicit and gives the user control. Auto-retry could loop indefinitely if the block is a deeper environment issue. |

## Data Flow

```
/sdd-apply <change-name>
    ↓
Load tasks.md, proposal.md, design.md
    ↓
Load attempt_counter = {} (empty map, task_id → count)
Load config: apply_max_retries = openspec/config.yaml.apply_max_retries or 3
    ↓
For each task in tasks.md (order: Phase 1, 2, 3, ...):
    ↓
    ├─ Check: is task status [TODO] or marked for re-attempt?
    │   └─ Yes: increment attempt_counter[task_id]
    │   └─ No: skip to next task
    │
    ├─ Exceeded max attempts?
    │   └─ Yes: mark [BLOCKED], append attempt summary, halt phase, report to user
    │   └─ No: continue
    │
    ├─ Read current task:
    │   ├─ file_snapshot_before = hash all files to be modified
    │   └─ execute implementation (per design.md and spec)
    │
    ├─ Check: did implementation succeed?
    │   ├─ Yes:
    │   │   ├─ Mark task [x] (complete)
    │   │   ├─ Reset attempt_counter[task_id] = 0 (optional, clean state)
    │   │   └─ Proceed to next task
    │   │
    │   └─ No:
    │       ├─ Compare file_snapshot_after with file_snapshot_before
    │       ├─ Same files modified in same way as previous attempt?
    │       │   ├─ Yes: mark [BLOCKED] with "same strategy detected", halt phase
    │       │   └─ No: continue
    │       ├─ Increment attempt_counter[task_id] again
    │       ├─ Attempt_counter[task_id] > max_attempts?
    │       │   ├─ Yes: mark [BLOCKED], halt phase, report to user
    │       │   └─ No: re-attempt with different approach
    │       └─ (loop back to "execute implementation")
    │
    └─ End of task

Loop continues until:
  1. All tasks completed, OR
  2. A [BLOCKED] task is encountered (phase halts)

Report to user:
  ✅ Phase complete (all tasks done), OR
  ⛔ Phase halted — task X.Y BLOCKED after N attempts
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `~/.claude/skills/sdd-apply/SKILL.md` | Modify | Add Step 0b for retry counter initialization; modify Phase 1 task execution loop to include attempt tracking, BLOCKED state logic, same-strategy detection, and phase halt on BLOCKED |
| `openspec/config.yaml` | Modify (optional) | Add `apply_max_retries: 3` (optional; absent key defaults to 3) |
| `openspec/changes/<change-name>/tasks.md` | Modify (runtime) | Change task status from `[TODO]` to `[BLOCKED]` when max attempts exceeded; append attempt summary, error, resolution instruction |

## Interfaces and Contracts

### Retry Counter Data Structure (in-memory, per `/sdd-apply` invocation)

```python
attempt_counter = {
    "1.1": 1,      # task_id → attempt count
    "1.2": 0,
    "2.1": 3,
}

max_attempts = 3   # from config or default
```

### Task Status Enum

```
[TODO]      — Task not yet attempted or marked for re-attempt
[x]         — Task completed successfully
[BLOCKED]   — Task failed after max_attempts; manual intervention required
```

### Config Schema (openspec/config.yaml)

```yaml
apply_max_retries: 3    # Optional; if absent, default is 3
```

### BLOCKED Task Format in tasks.md

```markdown
- [BLOCKED] Task 2.3 — description
  - Attempts: 3/3
  - Tried:
    1. Modified src/file.ts to add new function; error: "ReferenceError: xyz is not defined"
    2. Modified src/file.ts and src/module.ts; error: "Module not found: ./missing"
    3. Reverted to approach 1 and added xyz import; error: "ReferenceError: xyz is still not defined"
  - Last error: "ReferenceError: xyz is still not defined"
  - Resolution required: Verify that xyz is exported from the correct module before resuming
```

### Same-Strategy Detection Algorithm

```
def is_same_strategy(previous_attempt, current_attempt):
    """
    Returns true if both attempts modified the same set of files
    with identical content changes (or near-identical).
    """
    # Collect all files touched in each attempt
    files_prev = set(previous_attempt['files_modified'].keys())
    files_curr = set(current_attempt['files_modified'].keys())

    # Must touch exactly the same files
    if files_prev != files_curr:
        return False

    # For each file, compare hashes of the changes
    for file_path in files_prev:
        hash_prev = hash(previous_attempt['files_modified'][file_path])
        hash_curr = hash(current_attempt['files_modified'][file_path])
        if hash_prev != hash_curr:
            return False

    return True  # Same files, same content changes → same strategy
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|--------------|------|
| Unit | Attempt counter increment, max_attempts comparison, config defaults | Manual verification in SKILL.md logic |
| Integration | Task status transitions (TODO → x, TODO → BLOCKED), tasks.md updates during loop | Manual verification during `/sdd-apply` run |
| E2E | Full `/sdd-apply` cycle: propose → spec → design → tasks → apply with intentional task failures to trigger BLOCKED state, resume from BLOCKED | Manual + `/project-audit` post-apply (verify-report.md checks) |

## Migration Plan

No data migration required. This is a purely additive change to `sdd-apply` SKILL.md. Existing projects with no `apply_max_retries` config will default to 3 attempts.

## Open Questions

- Should retry attempts be logged to a separate `.claude/apply-attempt-log.txt` file for later debugging? (Non-blocking; enhancement for future sessions)
- Should there be a way to permanently mark a task as "give up" (e.g., `[SKIP]`) without requiring manual intervention? (Non-blocking; can be added later as a user preference)
- What if all max_attempts are consumed across multiple `/sdd-apply` invocations (i.e., user runs apply, it fails after 1 attempt, they resume, it fails after 1 more attempt, etc.)? Should the counter be cumulative or per-invocation? (Decision: per-invocation; cumulative would require persistent state and is out of scope for this change)
