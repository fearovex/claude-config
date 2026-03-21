---
name: sdd-explore
description: >
  Investigates and analyzes an idea or codebase area before committing to changes. Pure research, no writes.
  Trigger: /sdd-explore <topic>, explore, investigate codebase, research feature, analyze before changing.
format: procedural
model: sonnet
---

# sdd-explore

> Investigates and analyzes an idea or area of the codebase before committing to changes.

**Triggers**: `/sdd-explore <topic>`, explore, investigate codebase, analyze before changing, research feature

---

## Purpose

The exploration phase is **optional but valuable**. Its goal is to understand the terrain before proposing changes. It creates no code and modifies nothing. It only reads and analyzes.

Use it when:

- The request is vague or complex
- You are unsure of the scope of the change
- You want to understand the impact before committing
- There are multiple possible approaches

---

## Process

### Skill Resolution

When the orchestrator launches this sub-agent, it resolves the skill path using:

```
1. .claude/skills/sdd-explore/SKILL.md     (project-local — highest priority)
2. openspec/config.yaml skill_overrides    (explicit redirect)
3. ~/.claude/skills/sdd-explore/SKILL.md   (global catalog — fallback)
```

Project-local skills override the global catalog. See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

### Step 0 — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the full project `CLAUDE.md` (at project root). Extract and log:
   - Count of items listed under `## Unbreakable Rules`
   - Value of the primary language from `## Tech Stack`
   - Whether `intent_classification:` is `disabled` (check for Override section)
   Output a single governance log line:
   `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`
   If CLAUDE.md is absent: log `INFO: project CLAUDE.md not found — governance falls back to global defaults.`

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`

Loaded context is used as enrichment throughout all subsequent steps. It informs architectural
coherence, naming consistency, and skill alignment checks — but does NOT override explicit
content in the proposal or design.

### Step 0 sub-step — Spec context preload

This sub-step is **non-blocking**: any failure (missing directory, unreadable file, no match) MUST produce at most an INFO-level note. This sub-step MUST NOT produce `status: blocked` or `status: failed`.

1. **List candidates**: list subdirectory names in `openspec/specs/`. If the directory does not exist, log `INFO: openspec/specs/ not found — skipping spec context preload` and skip this sub-step.

2. **Apply stem matching**:
   ```
   stems = change_name.split("-").filter(s => s.length > 1)
   matches = []
   for domain in candidates:
     if domain in change_name OR any stem in domain:
       matches.append(domain)
   matches = matches[:3]   ← hard cap at 3
   ```

3. **Load matches**: for each matched domain, read `openspec/specs/<domain>/spec.md` and treat its content as an **authoritative behavioral contract** (precedence over `ai-context/` for behavioral questions; `ai-context/` remains supplementary for architecture and naming context). If a file cannot be read, log an INFO note and skip that file.

4. **If no match**: skip silently — proceed to Step 1 without error or warning.

5. **When files are loaded**: emit the log line `Spec context loaded from: [domain/spec.md, ...]` and include the loaded paths in the artifacts list (read, not written).

See `docs/SPEC-CONTEXT.md` for the full convention reference, load cap rationale, and fallback behavior.

### Step 0 sub-step — Handoff context preload

This sub-step is **non-blocking**: any failure (missing file, unreadable file, no slug) MUST produce
at most an INFO-level note. This sub-step MUST NOT produce `status: blocked` or `status: failed`.

1. Resolve the change slug from the invocation context (same slug used in the change directory path).
2. Check whether `openspec/changes/<slug>/proposal.md` exists.
3. If absent: skip silently — log `INFO: no pre-seeded proposal.md found — proceeding without handoff context.`
4. If present: read the file. Treat its content as **supplemental intent enrichment**:
   - It informs what the explore should prioritize, not what the codebase shows.
   - It MUST NOT override live codebase findings.
   - Log: `Handoff context loaded from: openspec/changes/<slug>/proposal.md`
5. When loaded, include a `## Handoff Context` section in the exploration.md output
   (placed before `## Current State`) summarizing:
   - Decision that triggered the change
   - Goal and success criteria from the seeded proposal
   - Explore targets listed in the proposal
   - Constraints ("do not do" items)

---

### Step 1 — Understand the request

I classify what type of exploration is needed:

- **New feature**: What already exists? Where would it fit?
- **Bug**: Where is the problem? What is the root cause?
- **Refactor**: What code is affected? What are the risks?
- **Integration**: What exists to connect? What is missing?

### Step 2 — Branch Diff scan

This step is **non-blocking**: any failure (git unavailable, no working tree, empty diff) MUST produce at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Run `git status --short` to identify modified, staged, and untracked files in the current working tree.
2. Filter results to files relevant to the domain being explored (match by path prefix, filename, or keyword overlap with the change name).
3. Classify each file as: `modified`, `staged`, `deleted`, or `untracked`.
4. Write output to the `## Branch Diff` section in `exploration.md`.

**If git is unavailable or diff is empty**: log `INFO: branch diff unavailable or empty — skipping Branch Diff section` and include an empty `## Branch Diff` section with that note.

**Output format:**
```
## Branch Diff

Files modified in current branch relevant to this change:
- path/to/file.ts (modified)
- path/to/other.ts (staged, pending deletion)
- path/to/new-file.ts (untracked)
```

### Step 3 — Prior Attempts archive scan

This step is **non-blocking**: any failure (archive absent, unreadable files) MUST produce at most an INFO-level note.

1. Check whether `openspec/changes/archive/` exists. If absent: log `INFO: no archive directory found — skipping Prior Attempts section` and write an empty `## Prior Attempts` section.
2. List all subdirectories matching `YYYY-MM-DD-*` pattern.
3. For each archived change:
   a. Extract keywords from its slug (split on `-`, discard stop words like `fix`, `add`, `the`, `a`).
   b. Compute keyword overlap with the current change slug.
   c. If overlap >= 1 keyword: include in results.
4. For each included result: read `verify-report.md` (outcome) or note folder-only listing if absent.
5. Write output to the `## Prior Attempts` section in `exploration.md`.

**Output format:**
```
## Prior Attempts

Prior archived changes related to this topic:
- 2026-02-15-auth-flow-v1: COMPLETED (verify-report present)
- 2026-02-20-auth-flow-v2: ABANDONED (no verify-report)

[or: "No prior attempts found in archive."]
```

### Step 4 — Contradiction Analysis

This step is **non-blocking**: contradictions are informational and MUST NOT cause `status: blocked` or `status: failed`. At most, contradictions may cause `status: warning`.

1. Compare the user's stated intent (from change description and any pre-seeded proposal.md `## Context Notes`) against:
   - Loaded specs from Step 0c (behavioral contracts)
   - Prior attempt outcomes from Step 3
   - `ai-context/` files
2. For each potential contradiction detected, classify severity:
   - **CERTAIN**: the user says "remove X" AND a loaded spec explicitly states "X MUST exist" — no ambiguity
   - **UNCERTAIN**: the user intent implies removing or changing X, but there is no explicit spec contract — ambiguous
3. Assign impact level: `INFO` (minimal), `WARNING` (notable), `CRITICAL` (breaking)
4. Write output to the `## Contradiction Analysis` section in `exploration.md`.
5. Do NOT block exploration — the status remains `ok` unless contradictions are severe enough to set `status: warning`.

**Output format:**
```
## Contradiction Analysis

Contradictions detected between user intent and existing context:

- Item: [feature or behavior name]
  Status: CERTAIN|UNCERTAIN — [explanation of what contradicts what]
  Severity: INFO|WARNING|CRITICAL
  Resolution: [suggested resolution or "Requires user confirmation"]

[or: "No contradictions detected."]
```

### Step 5 — Investigate the codebase

I read real code following this hierarchy:

1. Entry points of the affected area
2. Files related to the functionality
3. Existing tests (they reveal expected behavior)
4. Relevant configurations
5. `ai-context/architecture.md` if it exists (to understand past decisions)

### Step 6 — Analyze approaches

For each possible approach I generate a comparison table:

| Approach   | Pros | Cons | Effort          | Risk            |
| ---------- | ---- | ---- | --------------- | --------------- |
| [Option A] |      |      | Low/Medium/High | Low/Medium/High |
| [Option B] |      |      |                 |                 |

### Step 7 — Identify risks and dependencies

- Code that would break with the change
- Dependencies that would need to be updated
- Tests that would fail
- Non-obvious side effects

### Step 8 — Save if a change name was specified

**Pre-save naming check (non-blocking):**

If `<change-name>` starts with `explore-`, warn before writing:

```
⚠ Note: The change name "[change-name]" starts with "explore-".
Standalone explore folders (e.g. explore-fy-topic) are not part of an sdd-ff cycle
and will not be automatically cleaned up or archived.

If you intend this as a full SDD change, use a descriptive slug:
  /sdd-ff <description>   ← recommended: creates a dated slug automatically

If you intend this as a one-off investigation, proceed as-is.
```

This warning is informational only — writing proceeds regardless of the name.

If invoked as `/sdd-explore <change-name>`, I save to:
`openspec/changes/<change-name>/exploration.md`

```markdown
# Exploration: [topic]

## Handoff Context

[Populated from pre-seeded proposal.md if present — see Step 0 sub-step Handoff context preload]

## Current State

[What currently exists in the codebase]

## Branch Diff

Files modified in current branch relevant to this change:
- [path/to/file] (modified|staged|deleted|untracked)

[or: "INFO: branch diff unavailable or empty."]

## Prior Attempts

Prior archived changes related to this topic:
- [YYYY-MM-DD-slug]: [outcome — COMPLETED/ABANDONED/IN-PROGRESS]

[or: "No prior attempts found in archive."]

## Contradiction Analysis

Contradictions detected between user intent and existing context:

- Item: [feature or behavior name]
  Status: CERTAIN|UNCERTAIN — [explanation]
  Severity: INFO|WARNING|CRITICAL
  Resolution: [suggestion or "Requires user confirmation"]

[or: "No contradictions detected."]

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |

## Analyzed Approaches

### Approach A: [name]

**Description**: [how it would work]
**Pros**: [advantages]
**Cons**: [disadvantages]
**Estimated effort**: Low/Medium/High
**Risk**: Low/Medium/High

### Approach B: [name]

[same format]

## Recommendation

[Recommended approach and why]

## Identified Risks

- [risk]: [impact] — [suggested mitigation]

## Open Questions

- [things that need clarification before proposing]

## Ready for Proposal

[Yes/No — and why if No]
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "summary": "Analysis of [topic]: [2-3 lines of the main finding]",
  "artifacts": ["openspec/changes/<name>/exploration.md"],
  "next_recommended": ["sdd-propose"],
  "risks": ["[risk if found]"]
}
```

---

## Rules

- I ONLY read code — I never modify anything in this phase
- I read real code, never assume or invent
- If I find something unexpected (technical debt, inconsistencies), I report it
- I keep the analysis concise: the goal is to inform, not to write a thesis
- If the exploration reveals that the change is trivial, I say so clearly
