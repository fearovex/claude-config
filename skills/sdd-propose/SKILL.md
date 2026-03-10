---
name: sdd-propose
description: >
  Creates a change proposal with clear intent, defined scope, and technical approach.
  Trigger: /sdd-propose <change-name>, create proposal, define change scope, sdd proposal.
format: procedural
model: haiku
---

# sdd-propose

> Creates a change proposal with clear intent, defined scope, and technical approach.

**Triggers**: `/sdd-propose <change-name>`, create proposal, define change, sdd proposal

---

## Purpose

The proposal defines the **WHAT and WHY** before entering into technical details. It is the scope contract of the change. Without an approved proposal, there are no specs or design.

---

## Process

### Step 0a — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the project's `CLAUDE.md` (at project root) and extract the `## Skills Registry` section.

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`

Loaded context is used as enrichment throughout all subsequent steps. It informs architectural
coherence, naming consistency, and skill alignment checks—but does NOT override explicit
content in the proposal or design.

### Step 0b — Domain context preload

This step is **non-blocking**: any failure (missing directory, unreadable file, no match) MUST produce at most an INFO-level note in the output. This step MUST NOT produce `status: blocked` or `status: failed` on its own.

1. **List candidate files**: list all `.md` files in `ai-context/features/`. Exclude `_template.md` and any file whose name begins with an underscore (`_`). If the directory does not exist or is empty after exclusions, skip this step silently and proceed to Step 1.

2. **Apply the filename-stem matching heuristic**:
   - Split the `<change-name>` on hyphens (`-`) to obtain stems.
   - Discard any single-character stems.
   - For each candidate file, compute its domain slug (filename without `.md`).
   - A match occurs when: the domain slug appears anywhere in `<change-name>` **OR** any change-name stem appears anywhere in the domain slug (case-insensitive comparison).

3. **Load matching files**: for each file that matches, read its full contents and treat them as enrichment context for proposal authoring. If multiple files match, load all of them. If a file cannot be read (e.g. permissions issue), log an INFO note and continue — do not block.

4. **If no file matches**: skip silently. Proceed to Step 1 without error or warning.

5. **When files are loaded**: note the loaded paths in the Step 6 output summary and include them in the `artifacts` list (marked as read, not written).

**Algorithm reference** (from design.md):

```
stems = change_name.split("-").filter(s => s.length > 1)
for each feature_file in ai-context/features/ (excluding _ prefix files):
  domain = feature_file.stem  (filename without .md)
  if domain in change_name OR any stem in domain → match
```

**Examples**:

- change `add-payments-gateway` → stems `[add, payments, gateway]` → matches `features/payments.md`
- change `auth-token-refresh` → stems `[auth, token, refresh]` → matches `features/auth.md`
- change `improve-project-audit` → stems `[improve, project, audit]` → no match → skip silently

### Step 1 — Read prior context

If `openspec/changes/<change-name>/exploration.md` exists, I read it first.
If `openspec/config.yaml` exists, I read the project rules.
If `ai-context/architecture.md` exists, I consult it for coherence.

### Step 2 — Understand the request in depth

If the request is ambiguous, I ask:

- What is the problem or need that motivates this change?
- Are there known constraints (performance, compatibility, etc.)?
- Are there parts that are explicitly OUT of scope?

### Step 3 — Create the change directory

```
openspec/changes/<change-name>/
```

### Step 4 — Write proposal.md

I create `openspec/changes/<change-name>/proposal.md`:

```markdown
# Proposal: [change-name]

Date: [YYYY-MM-DD]
Status: Draft

## Intent

[One clear sentence: what problem it solves or what need it covers]

## Motivation

[Why this is necessary now. Business or technical context.]

## Scope

### Included

- [deliverable 1]
- [deliverable 2]
- [deliverable 3]

### Excluded (explicitly out of scope)

- [what will NOT be done and why]

## Proposed Approach

[High-level description of the technical solution.
Does not go into implementation detail — that is the design's job.
Explains the "how" at a conceptual level.]

## Affected Areas

| Area/Module | Type of Change       | Impact          |
| ----------- | -------------------- | --------------- |
| [area]      | New/Modified/Removed | Low/Medium/High |

## Risks

| Risk   | Probability     | Impact          | Mitigation        |
| ------ | --------------- | --------------- | ----------------- |
| [risk] | Low/Medium/High | Low/Medium/High | [how to mitigate] |

## Rollback Plan

[How to revert if something goes wrong.
Must be concrete: which files, which commands, which steps.]

## Dependencies

- [What must exist/be completed before starting]
- [Changes in other parts of the system that this requires]

## Success Criteria

- [ ] [measurable and verifiable criterion 1]
- [ ] [measurable and verifiable criterion 2]
- [ ] [measurable and verifiable criterion 3]

## Effort Estimate

[Low (hours) / Medium (1-2 days) / High (several days)]
```

### Step 5 — PRD Shell Generation

This step is **non-blocking**: any failure produces a warning in the output, never `status: blocked` or `status: failed`.

1. **Idempotency check**: if `openspec/changes/<change-name>/prd.md` already exists, skip this step entirely — leave the file untouched.
2. **Template check**: if `docs/templates/prd-template.md` does not exist, log the warning `"PRD template not found — skipping PRD shell creation"` and skip.
3. **Copy and fill frontmatter**: copy `docs/templates/prd-template.md` to `openspec/changes/<change-name>/prd.md` and fill the following frontmatter fields:
   - `title`: derived from `<change-name>` (replace hyphens with spaces, title-case)
   - `date`: today's date in `YYYY-MM-DD` format
   - `related-change`: `openspec/changes/<change-name>/`
4. **User note**: inform the user that `prd.md` is optional and intended for product-facing changes. It can be left blank or deleted if the change is purely technical.
5. **Artifacts**: add `openspec/changes/<change-name>/prd.md` to the artifacts list **only** if it was created in this run (not if it already existed or was skipped).

### Step 6 — Summary to orchestrator

I return a clear executive summary:

```
Proposal created: [change-name]

Intent: [one line]
Scope: [N deliverables included, M excluded]
Approach: [one line]
Risk: Low/Medium/High
Next step: specs + design (can run in parallel)
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "summary": "Proposal [name]: [intent in one line]. Risk [level].",
  "artifacts": ["openspec/changes/<name>/proposal.md"],
  "next_recommended": ["sdd-spec", "sdd-design"],
  "risks": ["[main risk if any]"]
}
```

---

## Rules

- ALWAYS create `proposal.md` — it is the entry point for all subsequent phases
- Every proposal MUST have a rollback plan and success criteria
- Success criteria must be MEASURABLE and VERIFIABLE (not vague)
- Excluded scope is as important as included scope — it prevents scope creep
- I do not go into implementation details — that is the job of `sdd-design`
- If the proposal is trivial (1-2 line change), I indicate it and suggest skipping the full cycle
