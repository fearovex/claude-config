# Technical Design: 2026-03-10-sdd-apply-diagnose-first

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-apply-diagnose-first/proposal.md

## General Approach

Insert a mandatory Diagnosis Step into `sdd-apply/SKILL.md` between Step 0 (technology skill preload) and the existing implementation loop (Step 4). The Diagnosis Step requires the sub-agent to read current files, run read-only commands, and write a structured `DIAGNOSIS` block (including a hypothesis) before touching any file. When diagnostic findings contradict the task description, a `MUST_RESOLVE` warning is raised and execution pauses.

This is a documentation-only change: the single modified file is `skills/sdd-apply/SKILL.md` (`.md` extension). No source code, schemas, or scripts are changed.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Placement of Diagnosis Step | Between Step 0 (preload) and Step 4 (implementation loop), introduced as a new Step 3.5 or renumbered step | Before Step 0; after each file write | Front-loading diagnosis before any code change is the core invariant. Inserting after Step 0 ensures technology skills are loaded (context available) but before implementation begins. Renaming to Step 1b was discarded — numbered steps are the project convention for sdd-apply. |
| Diagnosis block format | Structured prose block with 5 mandatory fields + Risk field | Free-form notes; JSON block; inline comments | Structured prose is consistent with how other sdd-apply outputs are formatted (DEVIATION, QUALITY_VIOLATION). A JSON block would be machine-readable but harder for a sub-agent to author inline. |
| MUST_RESOLVE pause mechanism | Sub-agent writes warning block and halts until user confirms | Auto-proceed with best guess; log and continue | The proposal explicitly requires confirmation when assumptions contradict findings. Auto-proceed would defeat the purpose. Logging-only (non-blocking) was considered but rejected — a contradicting assumption is high-risk and warrants explicit confirmation. This pattern is architecturally consistent with how blocking deviations are handled in existing sdd-apply. |
| diagnosis_commands config key | Optional top-level key in `openspec/config.yaml` | Per-change config; inline in tasks.md | `openspec/config.yaml` is the established project-level config surface for sdd-apply behavior (e.g., `tdd`, `project.stack`). Adding `diagnosis_commands` there follows the existing convention and requires no new file. |
| Scope of Diagnosis Step applicability | Every task, including file-creation tasks | Only modification tasks; only tasks matching certain tags | Universal application ensures the invariant holds without requiring the sub-agent to classify tasks. For new files, the diagnosis still provides pattern-reference reading and an intent hypothesis. |

## Data Flow

```
sdd-apply task loop:

  Task N start
       │
       ▼
  Step 0 — Tech skill preload (existing)
       │
       ▼
  Step 1 — Read full context (existing)
       │
       ▼
  Step 2 — TDD mode detection (existing)
       │
       ▼
  Step 3 — Verify work scope (existing, renumbered)
       │
       ▼
  ┌─── NEW: Diagnosis Step ─────────────────────────────────────────┐
  │  1. Read files to be modified (current state)                   │
  │  2. Run diagnosis_commands (from config) + auto-detected cmds   │
  │  3. Write DIAGNOSIS block:                                      │
  │     - Files to modify                                          │
  │     - Command outputs                                           │
  │     - Current behavior observation                             │
  │     - Relevant data/state                                      │
  │     - Hypothesis (X because Y → change Z → outcome W)          │
  │     - Risk                                                      │
  │                  │                                              │
  │         Contradicts task desc?                                  │
  │           YES ──► MUST_RESOLVE warning → PAUSE → user input     │
  │           NO  ──► proceed                                       │
  └─────────────────────────────────────────────────────────────────┘
       │
       ▼
  Step 4 — Implement (TDD or standard) (existing, renumbered)
       │
       ▼
  Step 5 — Quality Gate (existing, renumbered)
       │
       ▼
  Step 6 — Mark task [x] in tasks.md (existing, renumbered)
       │
       ▼
  Next task
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-apply/SKILL.md` | Modify | Add new Diagnosis Step (between current Step 3 and Step 4); add `diagnosis_commands` config key documentation; add `MUST_RESOLVE` warning protocol; renumber subsequent steps if needed |

## Interfaces and Contracts

### DIAGNOSIS block (written by sub-agent in task notes)

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

### MUST_RESOLVE warning block

```
⚠️ MUST_RESOLVE — Diagnosis finding:
  Task X.Y assumes [A], but current state shows [B].

  This may indicate the task description is based on incorrect assumptions.

  Confirm how to proceed:
  Option 1: [proceed with updated understanding]
  Option 2: [revise task description]
```

### openspec/config.yaml optional key (schema addition)

```yaml
# Optional: project-specific read-only diagnostic commands for sdd-apply Diagnosis Step
diagnosis_commands:
  - "npm test -- --dry-run"
  - "cat ai-context/known-issues.md"
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual review | DIAGNOSIS block appears in task output before any file write | Human review of sdd-apply session transcript |
| Manual review | MUST_RESOLVE fires when task assumptions contradict findings | Human review with a task designed to have a known contradiction |
| Spec verification | All 3 new requirements and 8 scenarios pass | /sdd-verify after implementation |

No automated test framework is applicable — this is a SKILL.md (procedural instructions) change. Verification is done via `/sdd-verify` reviewing the skill against the spec scenarios.

## Migration Plan

No data migration required. This is a pure SKILL.md content change. The updated `skills/sdd-apply/SKILL.md` takes effect immediately after `install.sh` is run.

## Open Questions

- Should the Diagnosis Step be skippable via a per-task annotation in tasks.md (e.g., `[skip-diagnosis]`)? Impact: low for now — the proposal explicitly says "mandatory". A future enhancement proposal can add this if needed.
