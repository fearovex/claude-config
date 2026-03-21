---
name: sdd-archive
description: >
  Syncs delta specs to master specs and archives a completed SDD change to openspec/changes/archive/.
  Trigger: /sdd-archive <change-name>, archive change, finalize SDD cycle, close change.
format: procedural
model: haiku
---

# sdd-archive

> Syncs delta specs to the master specs and archives the completed change.

**Triggers**: `/sdd-archive <change-name>`, archive change, finalize sdd cycle, close change, sdd archive

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

### Skill Resolution

When the orchestrator launches this sub-agent, it resolves the skill path using:

```
1. .claude/skills/sdd-archive/SKILL.md     (project-local — highest priority)
2. openspec/config.yaml skill_overrides    (explicit redirect)
3. ~/.claude/skills/sdd-archive/SKILL.md   (global catalog — fallback)
```

Project-local skills override the global catalog. See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

### Step 1 — Verify it is archivable

#### Completeness Check

Before reading `verify-report.md`, I check the change directory for required SDD artifacts using a two-tier severity model.

**CRITICAL artifacts** (block with no proceed option): `proposal.md`, `tasks.md`

**WARNING artifacts** (present two-option prompt): `design.md`, non-empty `specs/` directory (contains at least one `.md` file)

**Check order:**

1. Check CRITICAL artifacts first. If any are absent:

```
CRITICAL — Cannot archive "[change-name]"

The following artifacts are required for a valid SDD cycle but are missing:
  - proposal.md   (required — CRITICAL)
  - tasks.md      (required — CRITICAL)

Return and complete the missing phases before archiving.
No proceed option is available.
```

List only the artifacts that are actually absent. Halt immediately. Do NOT evaluate WARNING artifacts. Do NOT continue to the verify-report.md check.

2. If CRITICAL passes, check WARNING artifacts. If any are absent:

```
WARNING — Incomplete cycle detected for "[change-name]"

The following artifacts are missing:
  - design.md     (recommended — WARNING)
  - specs/        (recommended — WARNING)

Choose:
  1. Return and complete the missing phases (/sdd-spec, /sdd-design)
  2. Archive anyway — I acknowledge these phases were intentionally skipped

Reply 1 or 2:
```

List only the artifacts that are actually absent. Wait for the user to reply:
- **Option 1 selected**: halt. The user returns to complete the missing phases.
- **Option 2 selected**: record the skipped phases (for use in Step 5 CLOSURE.md) and continue to the verify-report.md check.

3. If all CRITICAL and WARNING artifacts are present: produce no output and continue immediately to the verify-report.md check.

**Note**: `exploration.md` and `prd.md` are explicitly excluded from this check. Their absence MUST NOT trigger any CRITICAL or WARNING output.

---

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
_(Modified in: 2026-02-23 by change "add-csv-export")_
```

**I PRESERVE EVERYTHING that is NOT in the delta.**

#### If NO master spec exists:

I copy the delta file to `openspec/specs/<domain>/spec.md` (it becomes the full spec).

### Step 3a — Update spec index

**Condition:** This step runs only if a new domain directory was created under `openspec/specs/` during Step 3 (i.e., the delta spec had no corresponding master spec and was copied as a new domain).

If the condition is met:

1. **If `openspec/specs/index.yaml` does not exist:** create it with the standard header and `domains:` root key:

   ```yaml
   # openspec/specs/index.yaml
   # Spec domain index — maintained by sdd-archive.
   # Each entry: domain (directory name), summary, keywords (3–8), related (optional).

   domains:
   ```

2. **Append one entry** under the `domains:` key using the following field derivation rules:

   | Field | Derivation |
   |-------|-----------|
   | `domain` | The new directory name exactly as created under `openspec/specs/` |
   | `summary` | Derived from the spec file title (first `#` heading after the frontmatter/header block) or, if absent, the first requirement sentence |
   | `keywords` | Derived from the domain name tokens (split on `-`) plus key nouns found in the spec title and first requirement; 3–8 terms; use change-slug vocabulary (lowercase, hyphen-separated) |
   | `related` | Omit the key entirely if no cross-references are detectable; otherwise include domain names that appear as references in the proposal or other specs for this change — ONLY include values that exist as `domain` entries in the current `index.yaml` |

3. **Format constraint:** the new entry MUST follow the existing YAML format exactly — no schema changes. Omit `related` entirely (do not write `related: []`) when there are no cross-references.

   ```yaml
     - domain: <new-domain-name>
       summary: "<one-line description>"
       keywords: [<term>, <term>, ...]
       related: [<domain>, ...]   # omit if empty
   ```

4. **Non-blocking:** if `index.yaml` cannot be written (permission error, parse error), log a warning and continue. This step MUST NOT block the archive operation.

### Step 4 — Move to archive

**Pre-flight: strip embedded date from slug**

Before constructing the archive folder name, check whether `<change-name>` already starts with a date prefix:

```
if <change-name> matches /^\d{4}-\d{2}-\d{2}-(.+)$/
  archive_slug = captured group 1  (everything after the embedded date)
else
  archive_slug = <change-name>
```

Then construct the archive destination using today's archive date:

```
openspec/changes/<change-name>/
→ openspec/changes/archive/YYYY-MM-DD-<archive_slug>/
```

Example:
- Input slug `2026-03-14-spec-headers` → archive folder `2026-03-19-spec-headers` (not `2026-03-19-2026-03-14-spec-headers`)
- Input slug `add-payment-flow` → archive folder `2026-03-19-add-payment-flow` (no change)

I create `openspec/changes/archive/` if it does not exist.

I move the change folder:

After ALL files are confirmed present at `openspec/changes/archive/<date>-<archive_slug>/`, I MUST delete `openspec/changes/<change-name>/` and all its contents. Source deletion MUST NOT execute before destination files are confirmed — if confirmation fails, I halt and report an error without deleting the source.

I confirm the source directory `openspec/changes/<change-name>/` no longer exists before continuing to Step 5. I output "Source directory deleted: openspec/changes/<change-name>/" to confirm completion. If deletion fails after a successful copy, I output a WARNING with the exact path to delete manually and continue to Step 5 with `status: warning`.

### Step 5 — Create closure note

I create `openspec/changes/archive/YYYY-MM-DD-<archive_slug>/CLOSURE.md` (using the same `archive_slug` computed in Step 4):

```markdown
# Closure: [change-name]

Start date: [date from proposal.md]
Close date: [YYYY-MM-DD]

## Summary

[What was done in one or two lines]

## Modified Specs

| Domain   | Action                 | Change        |
| -------- | ---------------------- | ------------- |
| [domain] | Added/Modified/Created | [description] |

## Modified Code Files

[List of main files that changed]

## Key Decisions Made

[The architecture.md decisions relevant for the future]

## Lessons Learned

[If there were deviations, problems, or insights during the cycle]

## User Docs Reviewed

[YES — updated scenarios.md / quick-reference.md / onboarding.md as needed | NO — change does not affect user-facing workflows | N/A — pre-dates this requirement]

Skipped phases: [phase1, phase2]
```

**Conditional field — `Skipped phases:`**: Include this field ONLY when the user selected option 2 during a WARNING-level completeness check in Step 1. Derive phase names from the absent artifacts: `design.md` → `design`, absent or empty `specs/` → `spec`. If no phases were skipped (happy-path archive), omit this field entirely — do NOT write `Skipped phases: none` or leave the line blank.

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
   - Archive path: `openspec/changes/archive/YYYY-MM-DD-<archive_slug>/`
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
    "openspec/changes/archive/YYYY-MM-DD-<archive_slug>/ — created"
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
- CRITICAL artifacts (`proposal.md`, `tasks.md`) MUST block with no proceed option — the completeness check MUST run before `verify-report.md` is read
- WARNING artifacts (`design.md`, non-empty `specs/`) MUST always offer option 2 (acknowledge and proceed) — they MUST NOT silently block
