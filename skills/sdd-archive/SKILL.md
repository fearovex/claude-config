---
name: sdd-archive
description: >
  Syncs delta specs to master specs and archives a completed SDD change to openspec/changes/archive/.
  Trigger: /sdd-archive <change-name>, archive change, finalize SDD cycle, close change.
format: procedural
---

# sdd-archive

> Syncs delta specs to the master specs and archives the completed change.

**Triggers**: sdd:archive, archive change, finalize sdd cycle, close change, sdd archive

---

## Purpose

Archiving is the **final step** of the SDD cycle. It integrates the learnings from the change into the master specs (permanent source of truth) and moves the change to history. It is irreversible — I confirm with the user before executing.

---

## Spec Lifecycle

```
1. openspec/specs/ describes the CURRENT behavior of the system
2. A change proposes modifications (as deltas)
3. The implementation makes the actual changes in the code
4. Archiving MERGES the deltas into the master specs
5. openspec/specs/ now describes the NEW behavior
6. The next change starts from the updated specs
```

---

## Process

### Step 1 — Verify it is archivable

I read `openspec/changes/<change-name>/verify-report.md` if it exists.

If there are unresolved CRITICAL issues:
```
No archiving allowed.

The verification report has [N] critical issues:
- [issue 1]
- [issue 2]

Resolve the issues and run /sdd-verify again before archiving.
```

If there is no verification report, I inform the user and ask whether to proceed anyway.

**User-docs review checkbox** (non-blocking):

After reading the verify-report.md (if it exists), surface the user-docs review item status:

```
User docs review checkbox: [CHECKED / UNCHECKED / ABSENT]
```

- CHECKED: `verify-report.md` contains `[x] Review user docs` — good
- UNCHECKED: `verify-report.md` contains `[ ] Review user docs` — remind the user to check if this change affects `scenarios.md`, `quick-reference.md`, or `onboarding.md`
- ABSENT: the checkbox is not in the verify-report — no action needed (older changes pre-date this requirement)

This check is **non-blocking** — the archive operation continues regardless of the checkbox state.

### Step 2 — Confirm with the user

```
Do you confirm archiving the change "[change-name]"?

This will perform the following IRREVERSIBLE actions:
1. Merge delta specs → master specs in openspec/specs/
2. Move openspec/changes/[name]/ → openspec/changes/archive/[date]-[name]/

[PASS WITH WARNINGS — warnings were left unresolved]
[or: Verification: PASS]

Continue? [y/n]
```

### Step 3 — Sync delta specs to master specs

For each delta spec file in `openspec/changes/<name>/specs/`:

#### If master spec exists (`openspec/specs/<domain>/spec.md`):

I apply the delta:

**ADDED** → I append the new requirements at the end of the master spec file
**MODIFIED** → I replace the existing requirement with the new version
**REMOVED** → I delete the requirement (with an audit comment)

Merge example:
```markdown
<!-- Before in master spec -->
### Requirement: Export JSON
The system MUST export data in JSON format.

<!-- After applying MODIFIED from delta -->
### Requirement: Export JSON
The system MUST export data in JSON and CSV format.
*(Modified in: 2026-02-23 by change "add-csv-export")*
```

**I PRESERVE EVERYTHING that is NOT in the delta.**

#### If NO master spec exists:

I copy the delta file to `openspec/specs/<domain>/spec.md` (it becomes the full spec).

### Step 4 — Move to archive

I move the change folder:
```
openspec/changes/<change-name>/
→ openspec/changes/archive/YYYY-MM-DD-<change-name>/
```

I create `openspec/changes/archive/` if it does not exist.

### Step 5 — Create closure note

I create `openspec/changes/archive/YYYY-MM-DD-<name>/CLOSURE.md`:

```markdown
# Closure: [change-name]

Start date: [date from proposal.md]
Close date: [YYYY-MM-DD]

## Summary
[What was done in one or two lines]

## Modified Specs
| Domain | Action | Change |
|--------|--------|--------|
| [domain] | Added/Modified/Created | [description] |

## Modified Code Files
[List of main files that changed]

## Key Decisions Made
[The architecture.md decisions relevant for the future]

## Lessons Learned
[If there were deviations, problems, or insights during the cycle]

## User Docs Reviewed
[YES — updated scenarios.md / quick-reference.md / onboarding.md as needed | NO — change does not affect user-facing workflows | N/A — pre-dates this requirement]
```

### Step 5b — Verify-report template (for reference when creating verify-report.md)

When writing a `verify-report.md` as part of an SDD cycle, include this checkbox at the end:

```markdown
## User Documentation

- [ ] Review user docs (ai-context/scenarios.md / ai-context/quick-reference.md / ai-context/onboarding.md)
      if this change adds, removes, or renames skills, changes onboarding workflows, or introduces new commands.
      Mark [x] when confirmed reviewed (or confirmed no update needed).
```

This checkbox is **not blocking** — you may archive even if unchecked.

### Step 6 — Auto-update memory

After the archive is complete, I automatically update `ai-context/` with the decisions and changes from this cycle.

**Process:**

1. Read `~/.claude/skills/memory-update/SKILL.md`
2. Execute the `/memory-update` process inline, using the archived change as session context:
   - Change name: `<change-name>`
   - Archive path: `openspec/changes/archive/YYYY-MM-DD-<change-name>/`
   - Artifacts: proposal, specs, design, tasks, closure note
3. Report the result

**Non-blocking error handling:**

- **On success**: report in the output:
  ```
  Memory updated: ai-context/ files refreshed with decisions from "[change-name]".
  ```
- **On failure** (skill not found, write error, any other issue): report a warning and continue:
  ```
  Warning: Memory update failed — [reason]. Archive completed successfully.
  Suggestion: Run /memory-update manually to update ai-context/.
  ```

The archive is **always** considered successful regardless of the memory-update outcome.

**Final output:**

```
Change "[change-name]" successfully archived.

Master specs updated:
  - openspec/specs/auth/spec.md — 2 requirements added

Archived at:
  - openspec/changes/archive/2026-02-23-[name]/

Memory: [updated | failed — reason]
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|failed",
  "summary": "Change [name] archived. [N] master specs updated. Memory: [updated|failed|skipped].",
  "artifacts": [
    "openspec/specs/<domain>/spec.md — updated",
    "openspec/changes/archive/YYYY-MM-DD-<name>/ — created"
  ],
  "next_recommended": [],
  "risks": []
}
```

---

## Rules

- NEVER archive with unresolved CRITICAL issues
- ALWAYS confirm with the user before executing (it is irreversible)
- PRESERVE all master spec content that is not in the delta
- The archive history is IMMUTABLE — I never delete files from archive/
- If the merge is destructive (e.g. the delta removes a lot), I show this explicitly to the user
- If the master spec has conflicts with the delta, I show them and ask how to resolve
