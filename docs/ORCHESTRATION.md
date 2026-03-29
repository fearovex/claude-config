# Orchestration Architecture

> How the SDD orchestrator coordinates sub-agents in this system.

---

## Overview

The Claude Code SDD system uses a **hub-and-spoke orchestrator model**:

- The **orchestrator** (main conversation / CLAUDE.md) coordinates the overall SDD cycle
- **Sub-agents** execute individual phases in isolated context windows
- Communication between orchestrator and sub-agents is **file-only** (no shared memory)

---

## Why This Model?

| Property | Benefit |
|----------|---------|
| Context isolation | Each sub-agent starts fresh — no context pollution between phases |
| Parallelism | Spec and design phases run simultaneously in separate Task tool calls |
| Minimal orchestrator state | Orchestrator tracks only file paths, not file contents |
| Auditability | All inter-agent communication is written to disk (openspec/changes/) |
| Replaceability | Any sub-agent can be replaced by a project-local override without changing the orchestrator |

---

## Phase DAG

```
explore (optional but recommended)
      │
      ▼
  propose
      │
   ┌──┴──┐
   ▼     ▼
 spec  design   ← parallel (single message with two Task calls)
   └──┬──┘
      ▼
   tasks
      │
      ▼
   apply          ← can run in phases (Phase 1, Phase 2, ...)
      │
      ▼
  verify
      │
      ▼
 archive          ← irreversible; always requires user confirmation
```

### Parallelism

`spec` and `design` are always launched together in a single orchestrator message (two Task tool calls). They run concurrently and the orchestrator waits for both before proceeding to `tasks`.

No other phases run in parallel — each depends on the output of the previous.

---

## Orchestrator Responsibilities

The orchestrator NEVER:
- Reads source code directly for analysis
- Writes implementation code inline
- Writes specs, proposals, or designs directly
- Executes phase work in its own context

The orchestrator ALWAYS:
- Delegates each phase to a sub-agent via Task tool
- Maintains minimal state (file paths only, not contents)
- Presents clear summaries to the user after each phase
- Asks for user confirmation before irreversible actions (archive)
- Stops immediately when any phase returns `blocked` or `failed`

---

## Sub-Agent Launch Pattern

```
Task tool:
  subagent_type: "general-purpose"
  model: [per-skill model from SKILL.md]
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file <resolved-skill-path>
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path]
    - Change: [change-slug]
    - Previous artifacts: [list of paths]

    TASK: Execute the [phase] phase for change "[slug]".

    Return: status, summary, artifacts, next_recommended, risks
```

The orchestrator resolves the skill path using the algorithm in `docs/SKILL-RESOLUTION.md`.

---

## Artifact Flow

```
┌─────────────────────────────────────────────────────────┐
│  Orchestrator (main conversation)                        │
│  - tracks: [slug], [artifact paths]                      │
│  - delegates via Task tool                               │
└──────────────┬──────────────────────────────────────────┘
               │ Task tool call
               ▼
┌─────────────────────────────────────────────────────────┐
│  Sub-agent (fresh context)                               │
│  - reads SKILL.md                                        │
│  - reads prior artifacts from disk                       │
│  - writes new artifacts to disk                          │
│  - returns: status, summary, artifacts list              │
└──────────────┬──────────────────────────────────────────┘
               │ filesystem
               ▼
┌─────────────────────────────────────────────────────────┐
│  openspec/changes/<slug>/                                │
│  ├── exploration.md                                      │
│  ├── proposal.md                                         │
│  ├── specs/<domain>/spec.md                              │
│  ├── design.md                                           │
│  ├── tasks.md                                            │
│  └── verify-report.md                                    │
└─────────────────────────────────────────────────────────┘
```

---

## Skill Resolution

When the orchestrator constructs a sub-agent prompt, it resolves the skill path using:

```
1. .claude/skills/<name>/SKILL.md     (project-local override)
2. openspec/config.yaml skill_overrides
3. ~/.claude/skills/<name>/SKILL.md   (global catalog)
```

This allows projects to override any phase skill locally without modifying the global catalog.

See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

## Error Handling Protocol

| Sub-agent returns | Orchestrator action |
|-------------------|---------------------|
| `ok` | Continue to next phase |
| `warning` | Continue; surface warning prominently |
| `blocked` | STOP immediately; report to user; do NOT continue |
| `failed` | STOP immediately; report error; do NOT continue |

After a `blocked` or `failed`, the user must resolve the issue and re-trigger the appropriate command.

---

## Confirmation Gates

| Orchestrator | Gate |
|---|---|
| `sdd-archive` | Always — archive is irreversible |

---

## Memory and Persistence

The system uses **openspec** (filesystem) as its persistence layer:

| Scope | Location |
|-------|----------|
| Active change artifacts | `openspec/changes/<slug>/` |
| Master specifications | `openspec/specs/<domain>/spec.md` |
| Archived changes | `openspec/changes/archive/<date>-<slug>/` |
| Project memory | `ai-context/*.md` |
| Feature domain knowledge | `ai-context/features/<domain>.md` |
| ADRs | `docs/adr/<NNN>-<slug>.md` |

All files are versioned in git. The primary persistence layer is the filesystem (openspec/). Engram provides an additional persistent memory layer across sessions when available — engram is the default for SDD artifact persistence, with openspec as the fallback.

---

## Adding a New Phase

To add a new SDD phase (e.g., `sdd-review`):

1. Create `skills/sdd-review/SKILL.md` following the section contract for its format type
2. Add it to the phase DAG comment in `CLAUDE.md`
3. Register it in `agents.md`
4. Update `openspec/agent-execution-contract.md` if it introduces new return fields
5. Optionally update the orchestrator instructions in `CLAUDE.md` to include it in the coordinated cycle

---

## See Also

- `agents.md` — canonical agent registry
- `docs/SKILL-RESOLUTION.md` — skill path resolution rules
- `skills/README.md` — skill authoring guide
- `openspec/agent-execution-contract.md` — I/O contract specification
