---
name: sdd-status
description: >
  Shows the status of all active SDD changes by inspecting openspec/changes/ on disk.
  Trigger: /sdd-status, show active changes, what changes are in progress, SDD status.
format: procedural
---

# sdd-status

> Shows the status of all active SDD changes by inspecting openspec/changes/ on disk.

**Triggers**: `/sdd-status`, SDD status, active changes, show open changes, what changes are in progress

---

## Process

### Step 1 — Locate openspec/changes/

Check if `openspec/changes/` exists in the current project.

If it does NOT exist:
```
No openspec/changes/ directory found.

This project has no SDD changes yet.
To start a new change: /sdd-new <change-name>
```
Stop here.

---

### Step 2 — List active change directories

Read all directories directly under `openspec/changes/` EXCLUDING `archive/`.

Each subdirectory is a change. If there are no non-archive directories:
```
No active changes found in openspec/changes/.

Archived: [N] changes in openspec/changes/archive/
To start a new change: /sdd-new <change-name>
```
Stop here.

---

### Step 3 — Check artifacts for each change

For each change directory, check the presence of these files:
- `exploration.md` → marks explore phase done
- `proposal.md` → marks propose phase done
- `specs/` directory (non-empty) → marks spec phase done
- `design.md` → marks design phase done
- `tasks.md` → marks tasks phase done
- `verify-report.md` → marks verify phase done

---

### Step 4 — Infer current phase

Based on which artifacts are present, infer the current phase for each change:

| Condition | Current Phase |
|-----------|--------------|
| No artifacts at all | not started |
| proposal.md absent | explore (or not started) |
| proposal.md present, specs/ or design.md absent | propose done — awaiting spec/design |
| proposal.md + specs/ + design.md present, tasks.md absent | spec+design done — awaiting tasks |
| tasks.md present, verify-report.md absent | tasks done — ready for apply/verify |
| verify-report.md present | verify done — ready to archive |

---

### Step 5 — Render output table

```
Active SDD changes (openspec/changes/ — excluding archive/):

| Change                  | explore | proposal | spec | design | tasks | verify |
|-------------------------|---------|----------|------|--------|-------|--------|
| [change-name]           |   [✓/-] |   [✓/-]  | [✓/-]|  [✓/-] | [✓/-] |  [✓/-] |

Current phase:
- [change-name]: [inferred phase]

Archived: [N] changes in openspec/changes/archive/
```

Use `✓` for present, `-` for absent.

If `N` archived changes cannot be determined (e.g. archive/ does not exist), show `0`.

---

## Rules

- Filesystem-only: I only inspect files and directories — no git history, no git status, no network
- I never modify any files in this phase
- If `openspec/changes/` does not exist, I report gracefully and suggest `/sdd-new`
- Archived changes (under `archive/`) are counted but not listed in the active table
- The `specs/` check is satisfied by the presence of the directory with at least one file inside
- I do not attempt to parse file contents — presence/absence only
