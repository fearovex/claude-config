# Persistence Contract (shared across all SDD skills)

## Mode Resolution

The persistence mode is always `engram` when Engram MCP is reachable, otherwise `none`.

Default resolution:
1. If Engram is available → use `engram`
2. Otherwise → use `none`

When falling back to `none`, recommend the user enable `engram`.

## Mode Detection for Standalone Skills

Skills that run outside the orchestrator pipeline (project-setup, project-audit, project-fix, project-onboard, codebase-teach, memory-*, sdd-status, sdd-spec-gc, config-export) do NOT receive a mode from a launch context. They MUST detect the active mode themselves using this algorithm:

```
1. Check if Engram MCP is reachable (try mem_context or mem_search)
   → If reachable: active_mode = "engram"
   → If not reachable: active_mode = "none"
```

## Behavior Per Mode

| Mode | Read from | Write to | Project files |
|------|-----------|----------|---------------|
| `engram` | Engram | Engram | Never |
| `none` | Orchestrator prompt context | Nowhere | Never |

## State Persistence (Orchestrator)

The orchestrator persists DAG state after each phase transition to enable SDD recovery after compaction.

| Mode | Persist State | Recover State |
|------|--------------|---------------|
| `engram` | `mem_save(topic_key: "sdd/{change-name}/state")` | `mem_search("sdd/*/state")` → `mem_get_observation(id)` |
| `none` | Not possible — warn user | Not possible |

## Common Rules

- `none` → do NOT create or modify any project files; return results inline only
- `engram` → do NOT write any project files; persist to Engram and return observation IDs
- If unsure which mode to use, default to `none`

## Sub-Agent Context Rules

Sub-agents launch with a fresh context and NO access to the orchestrator's instructions or memory protocol.

Who reads, who writes:
- Non-SDD (general task): orchestrator searches engram, passes summary in prompt; sub-agent saves discoveries via `mem_save`
- SDD (phase with dependencies): sub-agent reads artifacts directly from backend; sub-agent saves its artifact
- SDD (phase without dependencies, e.g. explore): nobody reads; sub-agent saves its artifact

Why this split:
- Orchestrator reads for non-SDD: it knows what context is relevant; sub-agents doing their own searches waste tokens on irrelevant results
- Sub-agents read for SDD: SDD artifacts are large; inlining them in the orchestrator prompt would consume the entire context window
- Sub-agents always write: they have the complete detail on what happened; nuance is lost by the time results flow back to the orchestrator

## Orchestrator Prompt Instructions for Sub-Agents

Non-SDD:
```
PERSISTENCE (MANDATORY):
If you make important discoveries, decisions, or fix bugs, you MUST save them to engram before returning:
  mem_save(title: "{short description}", type: "{decision|bugfix|discovery|pattern}",
           project: "{project}", content: "{What, Why, Where, Learned}")
Do NOT return without saving what you learned. This is how the team builds persistent knowledge across sessions.
```

SDD (with dependencies):
```
Read these artifacts before starting (search returns truncated previews):
  mem_search(query: "sdd/{change-name}/{type}", project: "{project}") → get ID
  mem_get_observation(id: {id}) → full content (REQUIRED)

PERSISTENCE (MANDATORY — do NOT skip):
After completing your work, you MUST call:
  mem_save(
    title: "sdd/{change-name}/{artifact-type}",
    topic_key: "sdd/{change-name}/{artifact-type}",
    type: "architecture",
    project: "{project}",
    content: "{your full artifact markdown}"
  )
If you return without calling mem_save, the next phase CANNOT find your artifact and the pipeline BREAKS.
```

SDD (no dependencies):
```
PERSISTENCE (MANDATORY — do NOT skip):
After completing your work, you MUST call:
  mem_save(
    title: "sdd/{change-name}/{artifact-type}",
    topic_key: "sdd/{change-name}/{artifact-type}",
    type: "architecture",
    project: "{project}",
    content: "{your full artifact markdown}"
  )
If you return without calling mem_save, the next phase CANNOT find your artifact and the pipeline BREAKS.
```

## Skill Registry

The orchestrator pre-resolves compact rules from the skill registry and injects them as `## Project Standards (auto-resolved)` in your launch prompt. Sub-agents do NOT read the registry or individual SKILL.md files — rules arrive pre-digested.

To generate/update: run the `skill-registry` skill, or run `sdd-init`.

Sub-agent skill loading: check for a `## Project Standards (auto-resolved)` block in your prompt — if present, follow those rules. If not present, check for `SKILL: Load` instructions as a fallback. If neither exists, proceed without — this is not an error.

## Detail Level

The orchestrator may pass `detail_level`: `concise | standard | deep`. This controls output verbosity but does NOT affect what gets persisted — always persist the full artifact.
