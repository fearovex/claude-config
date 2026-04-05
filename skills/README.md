# Skills — Discovery Guide

> How skills are structured, discovered, and invoked in this system.

---

## What is a Skill?

A **skill** is a directory containing exactly one `SKILL.md` file. The SKILL.md is a Markdown file with YAML frontmatter that defines the skill's behavior, triggers, and process steps.

```
skills/
└── sdd-explore/
    └── SKILL.md   ← the only required file
```

When Claude Code receives a command like `/sdd-ff`, it reads `SKILL.md` and follows its instructions.

---

## SKILL.md Format

Every SKILL.md MUST have YAML frontmatter followed by Markdown content:

```yaml
---
name: skill-name
description: >
  One-line description. Trigger: /command <args>, alias, natural language phrase.
format: procedural   # procedural | reference | anti-pattern
model: haiku         # haiku | sonnet | opus
---
```

### Format types

| Format | Required sections | Use when |
|--------|-------------------|----------|
| `procedural` | `**Triggers**`, `## Process`, `## Rules` | Step-by-step workflows |
| `reference` | `**Triggers**`, `## Patterns` or `## Examples`, `## Rules` | Pattern catalogs, lookup guides |
| `anti-pattern` | `**Triggers**`, `## Anti-patterns`, `## Rules` | What NOT to do |

Absent `format:` defaults to `procedural`.

---

## Skill Resolution

When a skill is referenced (e.g., `~/.claude/skills/sdd-explore/SKILL.md`), the system resolves it using this priority order:

```
1. .claude/skills/<name>/SKILL.md         (project-local — highest priority)
2. ~/.claude/skills/<name>/SKILL.md       (global catalog — fallback)
```

See `docs/SKILL-RESOLUTION.md` for the full algorithm and config override format.

---

## Sub-Agent Invocation

Orchestrator skills launch phase sub-agents via the Task tool using this pattern:

```
Task tool:
  subagent_type: "general-purpose"
  model: haiku
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-[PHASE]/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path]
    - Change: [change-slug]
    - Previous artifacts: [list of paths]

    TASK: Execute the [phase] phase for change "[slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

For the full I/O contract, see the sub-agent launch pattern in CLAUDE.md.

---

## Step 0 — Project Context Loading

All SDD phase skills load project context in Step 0 before doing any work:

```
1. Read ai-context/stack.md
2. Read ai-context/architecture.md
3. Read ai-context/conventions.md
4. Extract ## Skills Registry from CLAUDE.md
```

This step is **non-blocking**: missing files produce `INFO` notes, never `blocked` or `failed` status.

---

## Adding a Project-Local Skill

To override a global skill for a specific project:

```bash
# Option 1: Use /skill-add to copy a global skill into the project
/skill-add sdd-explore

# Option 2: Create manually
mkdir -p .claude/skills/sdd-explore
# Write your custom SKILL.md
```

The project-local version will be resolved first from that point on.

---

## Creating a New Skill

Use `/skill-create <name>` to scaffold a new skill directory. The skill-creator will prompt for:
- Skill name
- Format type (procedural/reference/anti-pattern)
- Trigger phrases
- Whether it's global or project-specific

---

## Registry

Skills in this repository (global catalog):

- **SDD**: `sdd-apply`, `sdd-archive`, `sdd-design`, `sdd-explore`, `sdd-init`, `sdd-propose`, `sdd-spec`, `sdd-status`, `sdd-tasks`, `sdd-verify`
- **Infrastructure**: `project-audit`, `project-fix`, `project-onboard`, `project-setup`, `memory-manage`, `codebase-teach`, `feature-domain-expert`, `config-export`, `skill-creator`, `smart-commit`
- **Workflow**: `branch-pr`, `issue-creation`, `judgment-day`, `project-tracking`
- **Technology**: `go-testing`, `nextjs-15`, `react-19`, `react-native`, `solid-ddd`, `tailwind-4`, `typescript`, `zustand-5`
