---
name: sdd-ff
description: >
  Fast-forward SDD cycle: includes mandatory exploration as Step 0, then runs propose → spec+design (parallel) → tasks automatically, then asks before apply.
  Trigger: /sdd-ff <description>, quick SDD cycle, fast-forward, fast forward SDD.
format: procedural
model: haiku
---

# sdd-ff

> Fast-forward SDD cycle: infers slug, runs mandatory exploration (Step 0), then propose → spec+design (parallel) → tasks automatically, then asks before apply.

**Triggers**: `/sdd-ff <description>`, fast-forward, quick SDD cycle, fast forward SDD

---

## Process

### Skill Resolution (Orchestrator)

Before launching each sub-agent, I resolve the skill path using:

```
1. .claude/skills/<skill-name>/SKILL.md     (project-local — highest priority)
2. openspec/config.yaml skill_overrides     (explicit redirect)
3. ~/.claude/skills/<skill-name>/SKILL.md   (global catalog — fallback)
```

I pass the resolved path in the sub-agent prompt. See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

### Step 0 — Infer slug and run exploration

`$ARGUMENTS` must be a non-empty description of the change (e.g. `add payment flow`).

If empty or missing:

```
Usage: /sdd-ff <description>

Provide a description of the change. Example:
  /sdd-ff add payment flow
```

Stop here if argument is missing.

**Infer the slug** using the algorithm below (canonical definition: `docs/sdd-slug-algorithm.md`):

```
STOP_WORDS = { "fix", "add", "update", "the", "a", "an", "for", "of", "in", "with",
               "showing", "wrong", "year", "users", "user" }

1. Lowercase and tokenize the description (split on spaces and punctuation)
2. Filter out tokens that are in STOP_WORDS
3. Take the first 5 remaining tokens as meaningful words
4. Join with hyphens
5. Prefix with today's date: YYYY-MM-DD
6. Truncate to 50 characters if needed
7. Check for collisions: if openspec/changes/[slug]/ already exists,
   append -2, then -3, etc., until the slug is unique
```

Output to user (do NOT ask for confirmation or rename):

```
Inferred change name: [slug]
```

**Then immediately launch the explore sub-agent** (no user gate):

```
Task tool:
  subagent_type: "general-purpose"
  model: sonnet
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-explore/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Project governance: [absolute path of current working directory]/CLAUDE.md
    - Change: [inferred-slug]
    - Previous artifacts: none

    TASK: Execute the explore phase for change "[inferred-slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for result. If status is `blocked` or `failed`, stop and report to user. If status is `warning`, continue but surface the warning prominently.

---

### Step 1 — Launch propose sub-agent

Use the Task tool:

```
Task tool:
  subagent_type: "general-purpose"
  model: sonnet
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-propose/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Project governance: [absolute path of current working directory]/CLAUDE.md
    - Change: [inferred-slug]
    - Previous artifacts: openspec/changes/[inferred-slug]/exploration.md

    TASK: Execute the propose phase for change "[inferred-slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for the result. If status is `blocked` or `failed`, stop and report to user. If status is `warning`, continue but surface the warning prominently.

---

### Step 2 — Launch spec + design sub-agents in parallel

Use two Task tool calls simultaneously:

**Spec sub-agent:**

```
Task tool:
  subagent_type: "general-purpose"
  model: sonnet
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-spec/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Project governance: [absolute path of current working directory]/CLAUDE.md
    - Change: [inferred-slug]
    - Previous artifacts: openspec/changes/[inferred-slug]/proposal.md

    TASK: Execute the spec phase for change "[inferred-slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

**Design sub-agent:**

```
Task tool:
  subagent_type: "general-purpose"
  model: sonnet
  thinking: enabled
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-design/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Project governance: [absolute path of current working directory]/CLAUDE.md
    - Change: [inferred-slug]
    - Previous artifacts: openspec/changes/[inferred-slug]/proposal.md

    TASK: Execute the design phase for change "[inferred-slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for **both** to complete before proceeding. If either is `blocked` or `failed`, stop and report. Surface any warnings from either.

---

### Step 3 — Launch tasks sub-agent

Use the Task tool:

```
Task tool:
  subagent_type: "general-purpose"
  model: sonnet
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-tasks/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Project governance: [absolute path of current working directory]/CLAUDE.md
    - Change: [inferred-slug]
    - Previous artifacts: openspec/changes/[inferred-slug]/proposal.md, openspec/changes/[inferred-slug]/specs/, openspec/changes/[inferred-slug]/design.md

    TASK: Execute the tasks phase for change "[inferred-slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for the result.

---

### Step 4 — Present complete summary and ask before apply

Present to the user:

```
Fast-forward complete — [inferred-slug]

Phase results:
  explore  : [status] — [one-line summary]
  propose  : [status] — [one-line summary]
  spec     : [status] — [one-line summary]
  design   : [status] — [one-line summary]
  tasks    : [status] — [one-line summary]

Artifacts created:
  openspec/changes/[inferred-slug]/exploration.md
  openspec/changes/[inferred-slug]/proposal.md
  openspec/changes/[inferred-slug]/specs/*/spec.md
  openspec/changes/[inferred-slug]/design.md
  openspec/changes/[inferred-slug]/tasks.md

[If any warnings] Warnings:
  - [warning text]

Ready to implement? Run:
  /sdd-apply [inferred-slug]

Note: When the cycle completes, /sdd-archive will auto-update ai-context/ memory.
```

Do NOT invoke `/sdd-apply` automatically. The user must trigger it explicitly.

---

## Rules

- `$ARGUMENTS` must be provided — fail early with usage if missing
- The slug is always inferred from the description — do NOT ask the user to provide or confirm a name
- Exploration runs unconditionally as Step 0 (no user gate)
- Sub-agents are launched with the Task tool; I (sdd-ff) am the orchestrator, not a sub-agent
- `spec` and `design` sub-agents are always launched in parallel (single message with two Task calls)
- If any phase returns `blocked` or `failed`, stop immediately and report — do NOT continue to the next phase
- Warnings are surfaced but do not block the cycle
- I do NOT invoke `/sdd-apply` automatically — user must trigger it explicitly
- I maintain minimal state: only file paths, not file contents, between phases
- The inferred slug is passed to all sub-agents (never the raw description)
