---
name: sdd-new
description: >
  Starts a complete SDD cycle with optional exploration phase and user confirmation gates at each stage.
  Trigger: /sdd-new <change-name>, new SDD change, start full SDD cycle, new feature SDD.
format: procedural
model: haiku
---

# sdd-new

> Starts a complete SDD cycle for a change, with an optional exploration phase and user confirmation gates before continuing.

**Triggers**: `/sdd-new <change-name>`, new SDD change, start full SDD cycle, new feature SDD

---

## Process

### Step 1 — Validate argument

`$ARGUMENTS` must be a non-empty kebab-case change name (e.g. `add-payment-flow`).

If empty or missing:

```
Usage: /sdd-new <change-name>

Provide a kebab-case change name. Example:
  /sdd-new add-payment-flow
```

Stop here if argument is missing.

---

### Step 2 — Offer optional exploration

Ask the user:

```
Starting SDD cycle for: [change-name]

Do you want an exploration phase first?
  Y → Run /sdd-explore before proposing (recommended for complex/vague changes)
  N → Skip to propose (use when requirements are clear)
```

If user answers Y (or yes), launch the explore sub-agent:

```
Task tool:
  subagent_type: "general-purpose"
  model: haiku
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-explore/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Change: [change-name]
    - Previous artifacts: none

    TASK: Execute the explore phase for change "[change-name]". Save the output to openspec/changes/[change-name]/exploration.md

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for result. Present the exploration summary to the user. If status is `blocked` or `failed`, stop and report.

---

### Step 3 — Launch propose sub-agent

```
Task tool:
  subagent_type: "general-purpose"
  model: haiku
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-propose/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current working directory]
    - Change: [change-name]
    - Previous artifacts: [openspec/changes/[change-name]/exploration.md if it exists, else none]

    TASK: Execute the propose phase for change "[change-name]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

Wait for result. Present the proposal summary.

**Confirmation gate — after propose:**

```
Proposal created: openspec/changes/[change-name]/proposal.md
[one-paragraph summary from sub-agent]

Continue to spec + design?
  Y → Launch spec and design in parallel
  N → Stop here (you can review the proposal and resume later with /sdd-ff [change-name])
```

If user says N, stop gracefully.

---

### Step 4 — Launch spec + design sub-agents in parallel

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
  model: sonnet
  thinking: enabled
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

Wait for **both** to complete. Present both summaries.

**Confirmation gate — after spec + design:**

```
Spec and design complete:
  spec   : [status] — [one-line summary]
  design : [status] — [one-line summary]

[If any warnings] ⚠️ Warnings: [list]

Continue to tasks breakdown?
  Y → Launch tasks sub-agent
  N → Stop here (resume later with /sdd-tasks [change-name])
```

If user says N, stop gracefully.

---

### Step 5 — Launch tasks sub-agent

```
Task tool:
  subagent_type: "general-purpose"
  model: haiku
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

Wait for result.

---

### Step 6 — Present complete summary and remaining phases

```
✅ SDD cycle ready — [change-name]

Phase results:
  [explore  : [status] — [summary] (if run)]
  propose  : [status] — [summary]
  spec     : [status] — [summary]
  design   : [status] — [summary]
  tasks    : [status] — [summary]

Artifacts:
  openspec/changes/[change-name]/proposal.md
  openspec/changes/[change-name]/specs/*/spec.md
  openspec/changes/[change-name]/design.md
  openspec/changes/[change-name]/tasks.md

[If any warnings] ⚠️ Warnings:
  - [warning text]

Remaining phases:
  → /sdd-apply [change-name]   — implement the tasks
  → /sdd-verify [change-name]  — verify against specs
  → /sdd-archive [change-name] — archive when done (auto-updates ai-context/ memory)

Ready to implement? Run:
  /sdd-apply [change-name]
```

Do NOT invoke `/sdd-apply` automatically. The user must trigger it explicitly.

---

## Rules

- `$ARGUMENTS` must be provided — fail early with usage if missing
- The explore phase is optional and requires explicit user consent
- There are two mandatory confirmation gates: after propose, and after spec+design
- `spec` and `design` sub-agents are always launched in parallel (single message with two Task calls)
- If any phase returns `blocked` or `failed`, stop immediately — do NOT continue
- Warnings are surfaced but do not block the cycle
- I do NOT invoke `/sdd-apply` automatically — user must trigger it explicitly
- I maintain minimal state: only file paths between phases, not file contents
- The change name from `$ARGUMENTS` is passed verbatim to all sub-agents
- After stopping gracefully at any gate, inform the user which command resumes from that point
