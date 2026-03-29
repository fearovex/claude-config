---
name: sdd-archive
description: >
  Closes a completed SDD change by saving an archive report to engram and optionally updating ai-context/ memory.
  Trigger: /sdd-archive <change-name>, archive change, finalize SDD cycle, close change.
format: procedural
model: haiku
metadata:
  version: "3.0"
---

# sdd-archive

> Closes a completed SDD change and persists an archive report.

**Triggers**: `/sdd-archive <change-name>`, archive change, finalize sdd cycle, close change, sdd archive

---

## Purpose

Archiving is the **final step** of the SDD cycle. It validates completeness, saves a closure record, and updates the project memory layer. It is irreversible — I confirm with the user before executing.

---

## Process

### Skill Resolution

When the orchestrator launches this sub-agent, it resolves the skill path using:

```
1. .claude/skills/sdd-archive/SKILL.md     (project-local — highest priority)
2. ~/.claude/skills/sdd-archive/SKILL.md   (global catalog — fallback)
```

Project-local skills override the global catalog. See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

### Step 1 — Verify it is archivable

#### Completeness Check

Before reading the verify report, I check for required SDD artifacts in engram. Artifact exists if `mem_search` returns results.

**CRITICAL artifacts** (block with no proceed option): proposal, tasks

**WARNING artifacts** (present two-option prompt): design, specs

**Check order:**

1. Check CRITICAL artifacts first. If any are absent:

```
CRITICAL — Cannot archive "[change-name]"

The following artifacts are required for a valid SDD cycle but are missing:
  - proposal   (required — CRITICAL)
  - tasks      (required — CRITICAL)

Return and complete the missing phases before archiving.
No proceed option is available.
```

List only the artifacts that are actually absent. Halt immediately. Do NOT evaluate WARNING artifacts.

2. If CRITICAL passes, check WARNING artifacts. If any are absent:

```
WARNING — Incomplete cycle detected for "[change-name]"

The following artifacts are missing:
  - design     (recommended — WARNING)
  - specs      (recommended — WARNING)

Choose:
  1. Return and complete the missing phases (/sdd-spec, /sdd-design)
  2. Archive anyway — I acknowledge these phases were intentionally skipped

Reply 1 or 2:
```

List only the artifacts that are actually absent. Wait for the user to reply:
- **Option 1 selected**: halt. The user returns to complete the missing phases.
- **Option 2 selected**: record the skipped phases (for use in Step 4 closure) and continue.

3. If all CRITICAL and WARNING artifacts are present: produce no output and continue immediately.

**Note**: exploration is explicitly excluded from this check. Its absence MUST NOT trigger any CRITICAL or WARNING output.

---

I read the verify report artifact if it exists:
- `mem_search(query: "sdd/{change-name}/verify-report")` → `mem_get_observation(id)`.

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

After reading the verify-report (if it exists), surface the user-docs review item status:

```
User docs review checkbox: [CHECKED / UNCHECKED / ABSENT]
```

- CHECKED: verify-report contains `[x] Review user docs` — good
- UNCHECKED: verify-report contains `[ ] Review user docs` — remind the user to check if this change affects user-facing docs
- ABSENT: the checkbox is not in the verify-report — no action needed (older changes pre-date this requirement)

This check is **non-blocking** — the archive operation continues regardless of the checkbox state.

### Step 2 — Confirm with the user

```
Do you confirm archiving the change "[change-name]"?

This will perform the following actions:
1. Save an archive closure report to engram
2. Update ai-context/ with decisions from this change

[PASS WITH WARNINGS — warnings were left unresolved]
[or: Verification: PASS]

Continue? [y/n]
```

### Step 3 — Update feature files (optional)

If `ai-context/features/` exists and any domain specs were produced for this change, check whether the delta specs introduced new business rules, invariants, or gotchas that should be reflected in the permanent feature files.

For each affected domain:
- If a matching feature file exists: append new business rules or invariants to the appropriate sections
- If no matching feature file exists: skip — feature files are created by `/codebase-teach` or `/memory-init`, not by archive

This step is **non-blocking**. If `ai-context/features/` does not exist, skip entirely.

### Step 4 — Save closure to engram

Call `mem_save` with `topic_key: sdd/{change-name}/archive-report`, `type: architecture`, content = compact summary:
```
Archived: {change-name}. Dates: {start} -> {close}. Summary: {1-2 sentences}.
Specs domains: {domain list}. Skipped phases: {list or "none"}.
```

If Engram MCP is not reachable: skip persistence. Return closure content inline only.

### Step 5 — Auto-update memory

After the archive is complete, I automatically update `ai-context/` with the decisions and changes from this cycle.

**Process:**

1. Read `~/.claude/skills/memory-manage/SKILL.md`
2. Execute the `/memory-manage` process in "update" mode inline, using the archived change as session context:
   - Change name: `<change-name>`
   - Artifacts: proposal, specs, design, tasks (from engram)
3. Report the result

**Non-blocking error handling:**

- **On success**: report in the output:
  ```
  Memory updated: ai-context/ files refreshed with decisions from "[change-name]".
  ```
- **On failure** (skill not found, write error, any other issue): report a warning and continue:
  ```
  Warning: Memory update failed — [reason]. Archive completed successfully.
  Suggestion: Run /memory-manage (update mode) manually to update ai-context/.
  ```

The archive is **always** considered successful regardless of the memory-update outcome.

**Final output:**

```
Change "[change-name]" successfully archived.

Memory: [updated | failed — reason]
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|failed",
  "summary": "Change [name] archived. Memory: [updated|failed|skipped].",
  "artifacts": ["engram:sdd/{change-name}/archive-report"],
  "next_recommended": [],
  "risks": []
}
```

---

## Rules

- NEVER archive with unresolved CRITICAL issues
- ALWAYS confirm with the user before executing (it is irreversible)
- CRITICAL artifacts (`proposal`, `tasks`) MUST block with no proceed option — the completeness check MUST run before the verify-report is read
- WARNING artifacts (`design`, `specs`) MUST always offer option 2 (acknowledge and proceed) — they MUST NOT silently block
