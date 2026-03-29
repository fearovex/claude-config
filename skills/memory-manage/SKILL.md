---
name: memory-manage
description: >
  Manages the ai-context/ memory layer: initialize from scratch, update with session work, or maintain/cleanup.
  Trigger: /memory-init, /memory-update, /memory-maintain, initialize memory, update memory, maintain memory.
format: procedural
---

# memory-manage

> Unified management of the ai-context/ memory layer. Three modes: init, update, maintain.

**Triggers**: `/memory-init`, `/memory-update`, `/memory-maintain`, initialize memory, update memory, maintain memory, memory housekeeping, clean ai-context

---

## Mode Detection

Determine the mode from the invocation:
- `/memory-init` or "initialize memory" or "generate ai-context" → **init mode**
- `/memory-update` or "update memory" or "sync memory" or "record session" → **update mode**
- `/memory-maintain` or "maintain memory" or "memory housekeeping" or "clean ai-context" → **maintain mode**

---

## Mode: init

> Creates the 5 core ai-context/ files from scratch by reading the project.

**Use when**: Project has no `ai-context/` yet, or you want to regenerate from scratch.

### Process

1. **Project inventory**: Read configuration files, folder structure, README, representative source files, tests, CI/CD configs.
2. **Generate files**:
   - `ai-context/stack.md` — tech stack, versions, key tools
   - `ai-context/architecture.md` — architectural decisions and rationale
   - `ai-context/conventions.md` — naming patterns, code conventions
   - `ai-context/known-issues.md` — known bugs, tech debt, gotchas
   - `ai-context/changelog-ai.md` — empty, ready for session entries
3. **Feature stubs**: Scan for bounded contexts (directories with domain logic). Create `ai-context/features/_template.md` and stub files for discovered domains.
4. **Report**: List files created and coverage summary.

---

## Mode: update

> Incrementally updates ai-context/ with work done in the current session.

**Use when**: After completing significant work (SDD cycles, architecture changes, bug fixes).

### Process

1. **Analyze session**: Review what changed — files created/modified, decisions made, bugs fixed, conventions established.
2. **Update relevant files**:
   - `ai-context/stack.md` — new dependencies, version changes
   - `ai-context/architecture.md` — new decisions, pattern changes
   - `ai-context/conventions.md` — new naming patterns, style changes
   - `ai-context/known-issues.md` — new issues found, resolved issues marked
   - `ai-context/changelog-ai.md` — append entry with date, summary, files affected
   - `ai-context/features/<domain>.md` — update if relevant domain was touched
3. **Preserve**: Never overwrite `[manual]` sections. Only update `[auto-updated]` markers.

---

## Mode: maintain

> Periodic housekeeping: archive old entries, separate resolved issues, detect gaps.

**Use when**: changelog-ai.md is long (30+ entries), known-issues has resolved items, or at the start of a new project phase.

### Process

1. **Changelog archival**: If `changelog-ai.md` has more than 30 entries, move older entries to `changelog-ai-archive.md`.
2. **Known-issues cleanup**: Move resolved items from `known-issues.md` to `known-issues-archive.md`.
3. **Index generation**: Create/update `ai-context/index.md` listing all ai-context/ files with one-line descriptions.
4. **Gap detection**: Check if CLAUDE.md references ai-context/ files that don't exist. Report gaps.
5. **Dry-run first**: Present all proposed changes, require user confirmation before applying.

---

## Rules

- Init mode MUST NOT run if ai-context/ already exists — warn and suggest update mode instead
- Update mode MUST NOT create new core files — only modify existing ones
- Maintain mode MUST present dry-run before any destructive action (archival, moves)
- All modes are read-heavy, write-light — the goal is accurate, concise documentation
- Never overwrite `[manual]` sections in any file
- Feature file updates follow the format defined in `skills/feature-domain-expert/SKILL.md`
