---
name: sdd-ff
description: >
  Fast-forward SDD cycle: runs propose → spec+design (parallel) → tasks automatically, then asks before apply.
  Trigger: /sdd-ff <change-name>, quick SDD cycle, fast-forward, skip explore phase.
format: procedural
---

# sdd-ff

> Fast-forward SDD cycle: runs propose → spec+design (parallel) → tasks automatically, then asks before apply.

**Triggers**: `/sdd-ff <change-name>`, fast-forward, quick SDD cycle, skip explore

---

## Step 1 — Validate argument

`$ARGUMENTS` must be a non-empty kebab-case change name (e.g. `add-payment-flow`).

If empty or missing:
```
Usage: /sdd-ff <change-name>

Provide a kebab-case change name. Example:
  /sdd-ff add-payment-flow
```
Stop here if argument is missing.

---

## Step 2 — Launch propose sub-agent

Use the Task tool:

```
Task tool:
  subagent_type: "general-purpose"
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-propose/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Change: [change-name from $ARGUMENTS]
    - Previous artifacts: none

    TASK: Execute the propose phase for change "[change-name]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for the result. If status is `blocked` or `failed`, stop and report to user. If status is `warning`, continue but surface the warning prominently.

---

## Step 3 — Launch spec + design sub-agents in parallel

Use two Task tool calls simultaneously:

**Spec sub-agent:**
```
Task tool:
  subagent_type: "general-purpose"
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-spec/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Change: [change-name]
    - Previous artifacts: openspec/changes/[change-name]/proposal.md

    TASK: Execute the spec phase for change "[change-name]".

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
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-design/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Change: [change-name]
    - Previous artifacts: openspec/changes/[change-name]/proposal.md

    TASK: Execute the design phase for change "[change-name]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for **both** to complete before proceeding. If either is `blocked` or `failed`, stop and report. Surface any warnings from either.

---

## Step 4 — Launch tasks sub-agent

Use the Task tool:

```
Task tool:
  subagent_type: "general-purpose"
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-tasks/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Change: [change-name]
    - Previous artifacts: openspec/changes/[change-name]/proposal.md, openspec/changes/[change-name]/specs/, openspec/changes/[change-name]/design.md

    TASK: Execute the tasks phase for change "[change-name]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for the result.

---

## Step 5 — Present complete summary and ask before apply

Present to the user:

```
✅ Fast-forward complete — [change-name]

Phase results:
  propose  : [status] — [one-line summary]
  spec     : [status] — [one-line summary]
  design   : [status] — [one-line summary]
  tasks    : [status] — [one-line summary]

Artifacts created:
  openspec/changes/[change-name]/proposal.md
  openspec/changes/[change-name]/specs/*/spec.md
  openspec/changes/[change-name]/design.md
  openspec/changes/[change-name]/tasks.md

[If any warnings] ⚠️ Warnings:
  - [warning text]

Ready to implement? Run:
  /sdd-apply [change-name]

Note: When the cycle completes, /sdd-archive will auto-update ai-context/ memory.
```

Do NOT invoke `/sdd-apply` automatically. The user must trigger it explicitly.

---

## Rules

- `$ARGUMENTS` must be provided — fail early with usage if missing
- Sub-agents are launched with the Task tool; I (sdd-ff) am the orchestrator, not a sub-agent
- `spec` and `design` sub-agents are always launched in parallel (single message with two Task calls)
- If any phase returns `blocked` or `failed`, stop immediately and report — do NOT continue to the next phase
- Warnings are surfaced but do not block the cycle
- I do NOT invoke `/sdd-apply` automatically — user must trigger it explicitly
- I maintain minimal state: only file paths, not file contents, between phases
- The change name from `$ARGUMENTS` is passed verbatim to all sub-agents
