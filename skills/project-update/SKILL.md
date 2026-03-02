---
name: project-update
description: >
  Updates and migrates the Claude configuration of a project to the current user-level state.
  Trigger: /project-update, update project config, migrate SDD, sync claude project.
format: procedural
---

# project-update

> Updates and migrates the Claude configuration of a project to the current user-level state.

**Triggers**: project-update, update project config, migrate sdd, sync claude project, update claude project

---

## What this skill does

When the user runs `/project-update`, I synchronize the project's Claude configuration with:
- Changes in the user-level CLAUDE.md
- New skills available in the global catalog
- Changes in the real project stack (new deps, versions)
- Improvements in the memory structure

---

## Use Cases

### Case A — Update stack in ai-context/

The project has new dependencies or versions not yet documented:

1. I read the current stack from code (`package.json`, etc.)
2. I compare with `ai-context/stack.md`
3. I show a diff of detected changes
4. I update `stack.md` with the differences (confirming with the user)

### Case B — Update the project CLAUDE.md

The user-level CLAUDE.md or SDD conventions changed:

1. I read the project's `CLAUDE.md`
2. I identify sections that correspond to user-level templates
3. I propose updates while preserving project customization
4. I confirm with the user before writing

Sections I synchronize:
- Memory instructions (protocol at session start/end)
- Available SDD commands
- Skills registry (I add new ones from the catalog)

Sections I NEVER touch without explicit confirmation:
- Project stack
- Documented architecture
- Team-specific conventions
- Known issues

### Case C — Add missing memory files

If `ai-context/` exists but is missing files:

1. I detect which files are missing
2. I generate only the missing ones, reading the real code
3. I do not modify existing ones

### Case D — Migrate old structure

If the project has a different memory structure (e.g., AGENTS.md, memory.md, etc.):

1. I identify the existing structure
2. I propose migration to the new format
3. I preserve ALL existing content in the migration
4. I create the new structure and archive the old one in `ai-context/legacy/`

---

## Process

### Step 1 — Quick diagnosis

I run an internal audit (like `project-audit` but without a full report) to identify what needs updating.

### Step 1b — Stale-doc scan

After the quick diagnosis, I check user documentation freshness:

For each of the following files (only if they exist):
- `ai-context/onboarding.md`
- `ai-context/scenarios.md`
- `ai-context/quick-reference.md`

For each existing file:
1. Read its first 10 lines and search for `^> Last verified: (\d{4}-\d{2}-\d{2})$`
2. If the field is absent or malformed → treat as infinitely stale (add to REFRESH list)
3. If the date is more than 90 days from today → add to the proposed change plan as a `REFRESH` item
4. If the date is ≤ 90 days → no action
5. If the file does not exist → skip silently (not in scope of project-update; suggest `/project-onboard` to create)

Any file added to the REFRESH list appears in Step 2 as:
```
REFRESH:
  - ai-context/[filename]
    Reason: Last verified [date] ([N] days ago — exceeds 90-day threshold)
```

### Step 2 — Change plan

I present to the user exactly what I am going to change:

```
Proposed changes:

UPDATE:
  - ai-context/stack.md
    Reason: 3 new dependencies detected (zod 4.0, tanstack-query 5.x)

CREATE:
  - ai-context/known-issues.md
    Reason: Missing file

NO CHANGES:
  - CLAUDE.md (project customization detected)
  - ai-context/architecture.md (updated 5 days ago)

Proceed? [y/n]
```

### Step 3 — Execution

For REFRESH items: I offer regeneration but require explicit user confirmation before overwriting:
```
Regenerate ai-context/[filename]?
This will overwrite the current file with updated content.
Your manually curated content may be replaced.

Preview available? [Y to preview diff / N to skip regeneration]
```
**Never regenerate automatically.** The user must explicitly confirm.

I apply only the approved changes:
- Stack changes: I update section by section, I do not rewrite
- New files: I generate with real detected content
- CLAUDE.md: I use intelligent merge preserving custom content

### Step 4 — Summary

```
✅ Update completed

Changes applied:
  - ai-context/stack.md — 3 dependencies updated
  - ai-context/known-issues.md — created

No changes:
  - CLAUDE.md
  - ai-context/architecture.md

Recommendation: Review ai-context/architecture.md,
the folder structure changed since the last update.
```

---

## Rules

- NEVER overwrite without showing what changes and asking for confirmation
- I preserve ALL existing content as a base, I only add/update
- If there is a conflict between what exists and what is new, I show it and ask
- Automatic backup before modifying (`CLAUDE.md.bak`, etc.) if the file has more than 30 lines
- The files in `ai-context/` belong to the team — I treat them with care
