---
name: sdd-propose
description: >
  Creates a change proposal with clear intent, defined scope, and technical approach.
  Trigger: /sdd-propose <change-name>, create proposal, define change scope, sdd proposal.
format: procedural
model: sonnet
metadata:
  version: "2.1"
---

# sdd-propose

> Creates a change proposal with clear intent, defined scope, and technical approach.

**Triggers**: `/sdd-propose <change-name>`, create proposal, define change, sdd proposal

---

## Purpose

The proposal defines the **WHAT and WHY** before entering into technical details. It is the scope contract of the change. Without an approved proposal, there are no specs or design.

---

## Process

### Skill Resolution

When the orchestrator launches this sub-agent, it resolves the skill path using:

```
1. .claude/skills/sdd-propose/SKILL.md     (project-local — highest priority)
2. openspec/config.yaml skill_overrides    (explicit redirect)
3. ~/.claude/skills/sdd-propose/SKILL.md   (global catalog — fallback)
```

Project-local skills override the global catalog. See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

### Step 0a — Load project context

Follow `skills/_shared/sdd-phase-common.md` **Section F** (Project Context Load). Non-blocking.

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

### Step 0c — Spec context preload

Follow `skills/_shared/sdd-phase-common.md` **Section G** (Spec Context Preload). Non-blocking.

---

### Step 1 — Read prior context

I load the exploration artifact from the active persistence mode:
- **engram**: `mem_search(query: "sdd/{change-name}/explore")` → `mem_get_observation(id)` for full content.
- **openspec** / **hybrid**: Read `openspec/changes/<change-name>/exploration.md` if it exists.
- **none**: Skip — no prior exploration available.

If `openspec/config.yaml` exists, I read the project rules.
If `ai-context/architecture.md` exists, I consult it for coherence.

### Step 2 — Understand the request in depth

If the request is ambiguous, I ask:

- What is the problem or need that motivates this change?
- Are there known constraints (performance, compatibility, etc.)?
- Are there parts that are explicitly OUT of scope?

### Step 3 — Create the change directory (openspec/hybrid only)

**Mode detection (inline, non-blocking):**
Read `artifact_store.mode` from orchestrator launch context.
- If absent and Engram MCP is reachable → default to `engram`
- If absent and Engram MCP is not reachable → default to `none`

- **engram** / **none**: Skip directory creation — no filesystem artifacts.
- **openspec** / **hybrid**: Create `openspec/changes/<change-name>/` directory.

### Step 4 — Write proposal.md

#### Step 4a — Generate Supersedes section

Before writing the proposal, I scan for replacement/removal intent:

1. Read the exploration artifact (if available) and check `## Branch Diff`, `## Prior Attempts`, and `## Contradiction Analysis` sections:
   - **engram**: `mem_search(query: "sdd/{change-name}/explore")` → `mem_get_observation(id)`.
   - **openspec** / **hybrid**: Read `openspec/changes/<change-name>/exploration.md`.
   - **none**: Skip exploration input.
2. Scan the user's description and any pre-seeded `## Context Notes` in the proposal for patterns: "remove X", "no longer X", "delete X", "replace X with Y".
3. From the above, build the `## Supersedes` section:
   - **If nothing is being removed or replaced**: state `"None — this is a purely additive change."`
   - **If removals or replacements are found**: list each item under `### REMOVED`, `### REPLACED`, or `### CONTRADICTED` subsections as appropriate.
4. **Validation**: if a Supersedes entry claims to "remove" something but describes adding, emit a `MUST_RESOLVE` warning and pause for user confirmation.

#### Step 4b — Write proposal.md

I persist the proposal artifact based on the active persistence mode:

**Write dispatch:**
- **engram**: Call `mem_save` with `topic_key: sdd/{change-name}/proposal`, `type: architecture`, `project: {project}`, content = full proposal markdown. Do NOT write any file.
- **openspec**: Write `openspec/changes/<change-name>/proposal.md` with full proposal content.
- **hybrid**: Perform BOTH the engram `mem_save` AND the openspec filesystem write.
- **none**: Skip all write operations. Return proposal content inline only.

Content format (applies to all write modes):

```markdown
# Proposal: [change-name]

Date: [YYYY-MM-DD]
Status: Draft

## Intent

[One clear sentence: what problem it solves or what need it covers]

## Motivation

[Why this is necessary now. Business or technical context.]

## Supersedes

[ALWAYS present — even if nothing is superseded. If purely additive: "None — this is a purely additive change."]

### REMOVED (if applicable)

- **[Feature or component name]** (`path/to/file`)
  Reason: [why it is being removed]

### REPLACED (if applicable)

| Old | New | Reason |
|-----|-----|--------|
| [old feature] | [new feature] | [why] |

### CONTRADICTED (if applicable)

- **[Feature or behavior]**: prior context says "[X]", this proposal says "[NOT X]"
  Resolution: [contract superseded / breaking change / deprecation period / stakeholder coordination required]

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

### Step 5 — Preserve conversation context

This step is **non-blocking**: if no conversation context is available, skip silently.

1. Scan the user's original request and any pre-seeded `## Context Notes` in proposal.md for:
   - Explicit removal/replacement intents ("remove X", "no longer needed", "delete Y")
   - Platform or environment constraints ("mobile must not", "not on web", "desktop only")
   - Cautions or provisional notes ("careful with Z", "provisional, pending W")
2. If any of the above are found, append a `## Context` section to proposal.md:

```markdown
## Context

Recorded from conversation at [YYYY-MM-DDTHH:MMZ]:

### Explicit Intents

- **[intent]**: [exact wording or paraphrase from user]

### Platform Constraints

- **[constraint]**: [description]

### Provisional Notes

- **[note]**: [description and condition]
```

3. If nothing notable is found: skip this section — do NOT add an empty `## Context` section.

### Step 6 — Contradiction Resolution documentation

This step is **non-blocking**: only runs if contradictions were detected in exploration.md.

1. Read the exploration artifact's `## Contradiction Analysis` section:
   - **engram**: `mem_search(query: "sdd/{change-name}/explore")` → `mem_get_observation(id)` → extract section.
   - **openspec** / **hybrid**: Read `openspec/changes/<change-name>/exploration.md`.
   - **none**: Skip — no exploration available.
2. For each **CERTAIN** contradiction found, add a `## Contradiction Resolution` section to proposal.md documenting each one and its resolution approach:

```markdown
## Contradiction Resolution

### [Feature or behavior name]

**Prior context**: [what the prior spec or archived change said]
**This proposal**: [what this change intends to do instead]
**Resolution approach**: [one of: contract superseded / breaking change with migration / deprecation period / stakeholder coordination required]
```

3. For each **UNCERTAIN** contradiction: do NOT add it here — those may be handled by the orchestrator before propose runs as part of a multi-phase flow. If propose runs via direct invocation, document the UNCERTAIN contradictions in `## Risks` instead.

### Step 7 — PRD Shell Generation

This step is **non-blocking**: any failure produces a warning in the output, never `status: blocked` or `status: failed`.

**Note**: PRD shell generation only applies to **openspec** and **hybrid** modes. In **engram** or **none** mode, skip this step entirely — PRDs are filesystem-only artifacts.

1. **Idempotency check**: if `openspec/changes/<change-name>/prd.md` already exists, skip this step entirely — leave the file untouched.
2. **Template check**: if `docs/templates/prd-template.md` does not exist, log the warning `"PRD template not found — skipping PRD shell creation"` and skip.
3. **Copy and fill frontmatter**: copy `docs/templates/prd-template.md` to `openspec/changes/<change-name>/prd.md` and fill the following frontmatter fields:
   - `title`: derived from `<change-name>` (replace hyphens with spaces, title-case)
   - `date`: today's date in `YYYY-MM-DD` format
   - `related-change`: `openspec/changes/<change-name>/`
4. **User note**: inform the user that `prd.md` is optional and intended for product-facing changes. It can be left blank or deleted if the change is purely technical.
5. **Artifacts**: add `openspec/changes/<change-name>/prd.md` to the artifacts list **only** if it was created in this run (not if it already existed or was skipped).

### Step 8 — Summary to orchestrator

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
  "artifacts": "<mode-dependent — see write dispatch in Step 4b>",
  // engram   → ["engram:sdd/{change-name}/proposal"]
  // openspec → ["openspec/changes/<name>/proposal.md"]
  // hybrid   → ["engram:sdd/{change-name}/proposal", "openspec/changes/<name>/proposal.md"]
  // none     → []
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
