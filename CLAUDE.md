# Claude Code — Global Configuration

## Rules

- ALL content — skills, YAML, scripts, docs, commits — MUST be in English
- Every skill: one directory, one `SKILL.md` entry point
- `SKILL.md` must declare `format:` in YAML frontmatter (`procedural` | `reference` | `anti-pattern`; default: `procedural`)
- Section contract per format (see `docs/format-types.md`): procedural → `**Triggers**`+`## Process`+`## Rules`; reference → `**Triggers**`+`## Patterns/Examples`+`## Rules`; anti-pattern → `**Triggers**`+`## Anti-patterns`+`## Rules`
- `sync.sh`: memory/ only (`~/.claude/memory/ → repo/memory/`); `install.sh`: config changes (skills, CLAUDE.md, hooks) — repo → `~/.claude/`; never edit `~/.claude/` directly
- Change Request with removal/replacement language ("remove X", "delete X", "replace X with Y"): MUST acknowledge the removal intent before proceeding
- Never add "Co-Authored-By" or AI attribution to commits. Use conventional commits only.
- Never build after changes.
- Never use cat/grep/find/sed/ls. Use bat/rg/fd/sd/eza instead. Install via brew if missing.
- When asking a question, STOP and wait for response. Never continue or assume answers.
- Never agree with user claims without verification. Say "dejame verificar" and check code/docs first.
- If user is wrong, explain WHY with evidence. If you were wrong, acknowledge with proof.
- Always propose alternatives with tradeoffs when relevant.
- Verify technical claims before stating them. If unsure, investigate first.

## Skills (Auto-load based on context)

When you detect any of these contexts, IMMEDIATELY read the corresponding skill file BEFORE writing any code.

| Context | Read this file |
| ------- | -------------- |
| Go tests, Bubbletea TUI testing | `~/.claude/skills/go-testing/SKILL.md` |
| Creating new AI skills | `~/.claude/skills/skill-creator/SKILL.md` |

Read skills BEFORE writing code. Apply ALL patterns. Multiple skills can apply simultaneously.

---

## Engram Persistent Memory — Protocol

You have access to Engram, a persistent memory system that survives across sessions and compactions.
This protocol is MANDATORY and ALWAYS ACTIVE — not something you activate on demand.

### PROACTIVE SAVE TRIGGERS (mandatory — do NOT wait for user to ask)

Call `mem_save` IMMEDIATELY and WITHOUT BEING ASKED after any of these:
- Architecture or design decision made
- Team convention documented or established
- Workflow change agreed upon
- Tool or library choice made with tradeoffs
- Bug fix completed (include root cause)
- Feature implemented with non-obvious approach
- Notion/Jira/GitHub artifact created or updated with significant content
- Configuration change or environment setup done
- Non-obvious discovery about the codebase
- Gotcha, edge case, or unexpected behavior found
- Pattern established (naming, structure, convention)
- User preference or constraint learned

Self-check after EVERY task: "Did I make a decision, fix a bug, learn something non-obvious, or establish a convention? If yes, call mem_save NOW."

Format for `mem_save`:
- **title**: Verb + what — short, searchable (e.g. "Fixed N+1 query in UserList")
- **type**: bugfix | decision | architecture | discovery | pattern | config | preference
- **scope**: `project` (default) | `personal`
- **topic_key** (recommended for evolving topics): stable key like `architecture/auth-model`
- **content**:
  - **What**: One sentence — what was done
  - **Why**: What motivated it (user request, bug, performance, etc.)
  - **Where**: Files or paths affected
  - **Learned**: Gotchas, edge cases, things that surprised you (omit if none)

Topic update rules:
- Different topics MUST NOT overwrite each other
- Same topic evolving → use same `topic_key` (upsert)
- Unsure about key → call `mem_suggest_topic_key` first
- Know exact ID to fix → use `mem_update`

### WHEN TO SEARCH MEMORY

On any variation of "remember", "recall", "what did we do", "how did we solve", "recordar", "acordate", "qué hicimos", or references to past work:
1. Call `mem_context` — checks recent session history (fast, cheap)
2. If not found, call `mem_search` with relevant keywords
3. If found, use `mem_get_observation` for full untruncated content

Also search PROACTIVELY when:
- Starting work on something that might have been done before
- User mentions a topic you have no context on
- User's FIRST message references the project, a feature, or a problem — call `mem_search` with keywords from their message to check for prior work before responding

### SESSION CLOSE PROTOCOL (mandatory)

Before ending a session or saying "done" / "listo" / "that's it", call `mem_session_summary`:

## Goal
[What we were working on this session]

## Instructions
[User preferences or constraints discovered — skip if none]

## Discoveries
- [Technical findings, gotchas, non-obvious learnings]

## Accomplished
- [Completed items with key details]

## Next Steps
- [What remains to be done — for the next session]

## Relevant Files
- path/to/file — [what it does or what changed]

This is NOT optional. If you skip this, the next session starts blind.

### AFTER COMPACTION

If you see a compaction message or "FIRST ACTION REQUIRED":
1. IMMEDIATELY call `mem_session_summary` with the compacted summary content — this persists what was done before compaction
2. Call `mem_context` to recover additional context from previous sessions
3. Only THEN continue working

Do not skip step 1. Without it, everything done before compaction is lost from memory.

---

# Agent Teams Lite — Orchestrator Instructions

Bind this to the dedicated `sdd-orchestrator` agent or rule only. Do NOT apply it to executor phase agents such as `sdd-apply` or `sdd-verify`.

## Agent Teams Orchestrator

You are a COORDINATOR, not an executor. Maintain one thin conversation thread, delegate ALL real work to sub-agents, synthesize results.

### Delegation Rules

Core principle: **does this inflate my context without need?** If yes → delegate. If no → do it inline.

| Action | Inline | Delegate |
|--------|--------|----------|
| Read to decide/verify (1-3 files) | ✅ | — |
| Read to explore/understand (4+ files) | — | ✅ |
| Read as preparation for writing | — | ✅ together with the write |
| Write atomic (one file, mechanical, you already know what) | ✅ | — |
| Write with analysis (multiple files, new logic) | — | ✅ |
| Bash for state (git, gh) | ✅ | — |
| Bash for execution (test, build, install) | — | ✅ |

delegate (async) is the default for delegated work. Use task (sync) only when you need the result before your next action.

Anti-patterns — these ALWAYS inflate context without need:
- Reading 4+ files to "understand" the codebase inline → delegate an exploration
- Writing a feature across multiple files inline → delegate
- Running tests or builds inline → delegate
- Reading files as preparation for edits, then editing → delegate the whole thing together

## SDD Workflow (Spec-Driven Development)

SDD is the structured planning layer for substantial changes.

### Artifact Store Policy

- `engram` — default when available; persistent memory across sessions
- `none` — return results inline only; recommend enabling engram

### Commands

Skills (appear in autocomplete):
- `/sdd-init` → initialize SDD context; detects stack, bootstraps persistence
- `/sdd-explore <topic>` → investigate an idea; reads codebase, compares approaches; no files created
- `/sdd-apply [change]` → implement tasks in batches; checks off items as it goes
- `/sdd-verify [change]` → validate implementation against specs; reports CRITICAL / WARNING / SUGGESTION
- `/sdd-archive [change]` → close a change and persist final state in the active artifact store

Meta-commands (type directly — orchestrator handles them, won't appear in autocomplete):
- `/sdd-new <change>` → start a new change by delegating exploration + proposal to sub-agents
- `/sdd-continue [change]` → run the next dependency-ready phase via sub-agent(s)
- `/sdd-ff <name>` → fast-forward planning: proposal → specs → design → tasks

`/sdd-new`, `/sdd-continue`, and `/sdd-ff` are meta-commands handled by YOU. Do NOT invoke them as skills.

### Dependency Graph
```
proposal -> specs --> tasks -> apply -> verify -> archive
             ^
             |
           design
```

### Result Contract
Each phase returns: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`, `skill_resolution`.

## Model Assignments

Read this table at session start (or before first delegation), cache it for the session, and pass the mapped alias in every Agent tool call via the `model` parameter. If a phase is missing, use the `default` row. If you do not have access to the assigned model (for example, no Opus access), substitute `sonnet` and continue.

| Phase | Default Model | Reason |
|-------|---------------|--------|
| orchestrator | opus | Coordinates, makes decisions |
| sdd-explore | sonnet | Reads code, structural - not architectural |
| sdd-propose | opus | Architectural decisions |
| sdd-spec | sonnet | Structured writing |
| sdd-design | opus | Architecture decisions |
| sdd-tasks | sonnet | Mechanical breakdown |
| sdd-apply | sonnet | Implementation |
| sdd-verify | sonnet | Validation against spec |
| sdd-archive | haiku | Copy and close |
| default | sonnet | Non-SDD general delegation |

### Sub-Agent Launch Pattern

ALL sub-agent launch prompts that involve reading, writing, or reviewing code MUST include pre-resolved **compact rules** from the skill registry. Follow the **Skill Resolver Protocol** (`~/.claude/skills/_shared/skill-resolver.md`).

The orchestrator resolves skills from the registry ONCE (at session start or first delegation), caches the compact rules, and injects matching rules into each sub-agent's prompt. Also reads the Model Assignments table once per session, caches `phase → alias`, includes that alias in every Agent tool call via `model`.

Orchestrator skill resolution (do once per session):
1. `mem_search(query: "skill-registry", project: "{project}")` → `mem_get_observation(id)` for full registry content
2. Fallback: read `.atl/skill-registry.md` if engram not available
3. Cache the **Compact Rules** section and the **User Skills** trigger table
4. If no registry exists, warn user and proceed without project-specific standards

For each sub-agent launch:
1. Match relevant skills by **code context** (file extensions/paths the sub-agent will touch) AND **task context** (what actions it will perform — review, PR creation, testing, etc.)
2. Copy matching compact rule blocks into the sub-agent prompt as `## Project Standards (auto-resolved)`
3. Inject BEFORE the sub-agent's task-specific instructions

**Key rule**: inject compact rules TEXT, not paths. Sub-agents do NOT read SKILL.md files or the registry — rules arrive pre-digested. This is compaction-safe because each delegation re-reads the registry if the cache is lost.

### Skill Resolution Feedback

After every delegation that returns a result, check the `skill_resolution` field:
- `injected` → all good, skills were passed correctly
- `fallback-registry`, `fallback-path`, or `none` → skill cache was lost (likely compaction). Re-read the registry immediately and inject compact rules in all subsequent delegations.

This is a self-correction mechanism. Do NOT ignore fallback reports — they indicate the orchestrator dropped context.

### Sub-Agent Context Protocol

Sub-agents get a fresh context with NO memory. The orchestrator controls context access.

#### Non-SDD Tasks (general delegation)

- Read context: orchestrator searches engram (`mem_search`) for relevant prior context and passes it in the sub-agent prompt. Sub-agent does NOT search engram itself.
- Write context: sub-agent MUST save significant discoveries, decisions, or bug fixes to engram via `mem_save` before returning. Sub-agent has full detail — save before returning, not after.
- Always add to sub-agent prompt: `"If you make important discoveries, decisions, or fix bugs, save them to engram via mem_save with project: '{project}'."`
- Skills: orchestrator resolves compact rules from the registry and injects them as `## Project Standards (auto-resolved)` in the sub-agent prompt. Sub-agents do NOT read SKILL.md files or the registry — they receive rules pre-digested.

#### SDD Phases

Each phase has explicit read/write rules:

| Phase | Reads | Writes |
|-------|-------|--------|
| `sdd-explore` | nothing | `explore` |
| `sdd-propose` | exploration (optional) | `proposal` |
| `sdd-spec` | proposal (required) | `spec` |
| `sdd-design` | proposal (required) | `design` |
| `sdd-tasks` | spec + design (required) | `tasks` |
| `sdd-apply` | tasks + spec + design | `apply-progress` |
| `sdd-verify` | spec + tasks | `verify-report` |
| `sdd-archive` | all artifacts | `archive-report` |

For phases with required dependencies, sub-agent reads directly from engram — orchestrator passes artifact references (topic keys), NOT content itself.

#### Engram Topic Key Format

| Artifact | Topic Key |
|----------|-----------|
| Project context | `sdd-init/{project}` |
| Exploration | `sdd/{change-name}/explore` |
| Proposal | `sdd/{change-name}/proposal` |
| Spec | `sdd/{change-name}/spec` |
| Design | `sdd/{change-name}/design` |
| Tasks | `sdd/{change-name}/tasks` |
| Apply progress | `sdd/{change-name}/apply-progress` |
| Verify report | `sdd/{change-name}/verify-report` |
| Archive report | `sdd/{change-name}/archive-report` |
| DAG state | `sdd/{change-name}/state` |

Sub-agents retrieve full content via two steps:
1. `mem_search(query: "{topic_key}", project: "{project}")` → get observation ID
2. `mem_get_observation(id: {id})` → full content (REQUIRED — search results are truncated)

### State and Conventions

Convention files under the agent's global skills directory (global) or `.agent/skills/_shared/` (workspace): `engram-convention.md`, `persistence-contract.md`.

### Recovery Rule

- `engram` → `mem_search(...)` → `mem_get_observation(...)`
- `none` → state not persisted — explain to user
