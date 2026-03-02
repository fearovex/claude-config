---
name: memory-update
description: >
  Updates ai-context/ memory files with the work done in the current session.
  Trigger: /memory-update, update memory, sync memory, record session.
format: procedural
---

# memory-update

> Updates the hybrid memory layer (ai-context/) with decisions and changes from the current session.

**Triggers**: /memory-update, update memory, sync memory, record session work

---

## Purpose

Incrementally updates the existing ai-context/ files to reflect what happened during the current work session. Use after completing significant work (SDD cycles, architectural changes, bug fixes).

---

## When to use

After:
- Completing an SDD cycle (/sdd-archive)
- Making significant architectural changes
- Resolving important bugs
- Changing project conventions or patterns
- At the end of a long work session

---

## Process

### Step 1 — Analyze what changed in this session

I review the context of the current session:
- Which files were created/modified
- What decisions were made
- What problems were found and resolved
- If the stack changed (new deps, updated versions)

### Step 2 — Determine which files to update

| If in the session... | I update |
|---------------------|----------|
| Dependencies were added/removed | `stack.md` |
| Architecture decisions were made | `architecture.md` |
| Coding patterns, naming conventions, or import styles changed | `conventions.md` |
| Bugs were found/resolved | `known-issues.md` |
| Any significant change was made | `changelog-ai.md` |

### Step 3 — Update stack.md (if applicable)

I only update the sections that changed. I add without deleting history:
- New dependency: add it to the table with its version and purpose
- Removed dependency: mark it as `~~[name]~~ (removed [date])`
- Updated version: update the number

### Step 4 — Update architecture.md (if applicable)

If new decisions were made, I add them to the decisions table:
```markdown
| [new decision] | [choice] | [alternatives] | [actual reason] |
```

If the folder structure changed, I update the tree.

### Step 4b — Update conventions.md (if applicable)

If naming patterns, import styles, or code patterns changed during the session, I update `ai-context/conventions.md`:
- New or changed naming convention: update the relevant entry under `## Naming`
- New import style or file organization pattern: update `## File Organization` or `## Detected Code Patterns`
- If the file contains `[auto-updated]` sections written by `/project-analyze`, I write new entries **outside** the marker boundaries (`<!-- [auto-updated] -->` ... `<!-- [/auto-updated] -->`) and leave marker content intact

### Step 5 — Update known-issues.md (if applicable)

- Resolved issues: move them to a `## Resolved Issues` section with resolution date
- New issues found: add them to the corresponding section

### Step 6 — Add entry to changelog-ai.md

I always add an entry at the top (chronologically descending):

```markdown
### [YYYY-MM-DD] — [Descriptive name of the work]
**What was done**: [concise description]
**Modified files**:
- `path/file.ext` — [what changed]
**Decisions made**:
- [decision relevant for future sessions]
**Notes**: [anything important]
```

### Step 7 — Summary for the user

```
Memory updated

Modified files:
  - ai-context/stack.md — 2 dependencies added
  - ai-context/known-issues.md — 1 issue resolved, 1 new
  - ai-context/changelog-ai.md — entry added

No changes:
  - ai-context/architecture.md
  - ai-context/conventions.md
```

---

## Rules

- I read real code to infer, I never invent
- I update incrementally, I never overwrite everything
- I mark with [To confirm] what I cannot determine with certainty
- I preserve history: resolved items are moved, not deleted
- If `ai-context/` does not exist, I suggest `/memory-init` first
- I respect `[auto-updated]` section boundaries left by `/project-analyze`
