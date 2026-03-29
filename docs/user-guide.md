# User Guide — agent-config

Last updated: 2026-03-12

---

## What is agent-config?

`agent-config` is a personal configuration repository for [Claude Code](https://docs.anthropic.com/claude-code).
It holds everything Claude needs to operate consistently across all your projects: a catalog of
reusable skills, a project memory layer, and an orchestrator configuration that drives a
Specification-Driven Development (SDD) workflow.

Two components ship inside this repo:

1. **Skill catalog** (`skills/`) — one directory per skill, each with a `SKILL.md` entry point.
   Skills cover SDD phases (explore → propose → spec → design → tasks → apply → verify → archive),
   meta-tools (audit, fix, setup), and technology stacks (React, TypeScript, etc.).

2. **Memory layer** (`ai-context/`) — five Markdown files that persist project knowledge between
   Claude Code sessions: stack, architecture, conventions, known issues, and a changelog.

The goal is a reusable SDD workflow: every change — whether a one-line fix or a multi-week
feature — follows the same phase sequence, producing durable artifacts that survive context resets.

---

## Deployment model

`agent-config` uses two one-way scripts to keep the repo and the Claude Code runtime in sync.

```
agent-config (repo)  ──install.sh──►  ~/.claude/ (runtime)
                       ◄──sync.sh────  ~/.claude/memory/ only
```

| Script | Direction | What it copies |
|--------|-----------|----------------|
| `install.sh` | repo → `~/.claude/` | Skills, CLAUDE.md, hooks, settings.json, openspec/ |
| `sync.sh` | `~/.claude/memory/` → `repo/memory/` | Auto-memory only |

**Important distinctions:**

- `sync.sh` does **not** deploy skills, CLAUDE.md, or hooks. It only captures auto-memory.
- `install.sh` is one-way and non-destructive: it overwrites `~/.claude/` files from the repo,
  but does not delete files that exist only in `~/.claude/`.
- Never edit `~/.claude/` directly. Changes made there are overwritten the next time `install.sh` runs.

### New machine setup

```bash
git clone <this-repo-url> ~/agent-config
cd ~/agent-config
bash install.sh
```

After `install.sh` completes, open any project directory in Claude Code. The skills and
orchestrator configuration are immediately available.

---

## Global configuration out-of-the-box

Running `install.sh` deploys the following to `~/.claude/`:

- `CLAUDE.md` — the orchestrator instructions Claude reads at every session start
- `skills/` — the full skill catalog (~33 skills)
- `hooks/` — Claude Code event hooks
- `settings.json` — MCP server registrations (GitHub, filesystem)
- `openspec/` — SDD artifact storage for this repo itself
- `ai-context/` — memory layer files

### Skill categories

| Category | Examples |
|----------|---------|
| SDD phases | `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive` |
| Meta-tools | `project-setup`, `project-audit`, `project-fix`, `project-onboard` |
| Memory | `memory-manage`, `codebase-teach` |
| Frontend | `react-19`, `nextjs-15`, `typescript`, `zustand-5`, `tailwind-4` |
| Tooling | `smart-commit`, `config-export` |
| Design principles | `solid-ddd` (loaded automatically by `sdd-apply` on non-doc changes) |

### Memory layer

The `ai-context/` directory holds five files Claude reads at the start of each session:

| File | Purpose |
|------|---------|
| `stack.md` | Tech stack, versions, key tools |
| `architecture.md` | Architectural decisions and rationale |
| `conventions.md` | Naming patterns, code conventions |
| `known-issues.md` | Known bugs, gotchas, current limitations |
| `changelog-ai.md` | Log of AI-authored changes |

Run `/memory-manage` to generate these files from scratch or update them at the end of each session.

### Intent classification overview

When you type a free-form message, Claude classifies your intent before responding:

- **Change request** (fix, add, implement, create…) → recommends `/sdd-explore` + `/sdd-propose <slug>`
- **Exploration** (review, analyze, investigate…) → auto-launches `sdd-explore`
- **Question** (what is, how does, explain…) → answers directly
- **Slash command** (`/sdd-explore`, `/project-audit`…) → executes immediately

This routing ensures implementation work always follows the SDD cycle rather than being
written ad hoc.

---

## Project-level customization

### When to override

Global skills work for most projects. Override when a project needs different behavior:
a stricter apply policy, a project-specific technology skill, or a disabled intent class.

### Three-tier precedence

```
Priority 1 (highest): .claude/skills/<skill-name>/SKILL.md   ← project-local
Priority 2:           openspec/config.yaml skill_overrides   ← explicit redirect
Priority 3 (lowest):  ~/.claude/skills/<skill-name>/SKILL.md ← global catalog
```

Claude resolves a skill by walking the tiers top-to-bottom and using the first match it finds.

### Worked example: project-local sdd-apply override

Suppose your project needs `sdd-apply` to always run linting before marking a task complete.
The global `sdd-apply` skill does not include this step. Override it locally:

```
your-project/
└── .claude/
    └── skills/
        └── sdd-apply/
            └── SKILL.md   ← your project-specific version
```

At runtime, when Claude executes `/sdd-apply`, it finds `.claude/skills/sdd-apply/SKILL.md`
first (Priority 1) and uses that version. The global `~/.claude/skills/sdd-apply/SKILL.md` is
never loaded for this project.

To revert: delete `.claude/skills/sdd-apply/` — the global skill takes over automatically.

See [SKILL-RESOLUTION.md](./SKILL-RESOLUTION.md) for the full resolution algorithm.

### Disabling intent classification

Add the following block to your project's `CLAUDE.md` to turn off orchestrator routing:

```markdown
## Always-On Orchestrator — Override
intent_classification: disabled
```

Or restrict to specific classes:

```markdown
## Always-On Orchestrator — Override
intent_classification:
  enabled_classes: [Meta-Command, Change Request]
```

---

## Conflict resolution workflow

A conflict occurs when a project's Claude config drifts from the expected structure: a skill
entry is missing, a SKILL.md lacks a required section, or a format field is invalid.

The two-step resolution workflow:

```
Step 1: /project-audit   →  audit-report.md  (find problems)
Step 2: /project-fix     →  applies fixes     (correct problems)
```

### Realistic scenario

You add a new skill (`go-testing`) to the global catalog but forget to register it in the
project's `CLAUDE.md`. Running `/project-audit` produces:

```
## Dimension 6 — Skills Registry
Status: FAIL
Finding: Skill `go-testing` is present in ~/.claude/skills/ but not listed in
         the project's CLAUDE.md Skills Registry section.
Fix: Add entry under "### Testing":
     - `~/.claude/skills/go-testing/SKILL.md` — Go testing patterns
```

**Resolution:**

1. Run `/project-fix` — it reads `audit-report.md` and applies the correction automatically.
2. Run `bash install.sh` to deploy the updated config to `~/.claude/`.

If the audit reports a format violation (missing `## Rules` section in a procedural SKILL.md),
`/project-fix` scaffolds the missing section with a placeholder and logs a `TODO` for you to fill in.

---

## Command reference at a glance

### Meta-tools

| Command | What it does |
|---------|-------------|
| `/project-setup` | Deploy SDD + memory structure in a new project |
| `/project-onboard` | Detect onboarding case (1–6) and recommend first command |
| `/project-audit` | Audit Claude config across 10 dimensions — generates `audit-report.md` |
| `/project-fix` | Apply all corrections from `audit-report.md` |
| `/skill-create <name>` | Scaffold a new skill directory or register an existing global skill |
| `/memory-manage` | Initialize, update, or maintain all `ai-context/` files |
| `/codebase-teach` | Extract domain knowledge into `ai-context/features/` files |

### SDD phases

| Command | What it does |
|---------|-------------|
| `/sdd-explore <topic>` | Investigate without committing to any change |
| `/sdd-propose <change>` | Create a proposal document |
| `/sdd-spec <change>` | Write delta specifications (WHAT the change must do) |
| `/sdd-design <change>` | Write a technical design (HOW to implement it) |
| `/sdd-tasks <change>` | Break the design into a phased task plan |
| `/sdd-apply <change>` | Implement the task plan, task by task |
| `/sdd-verify <change>` | Verify implementation against acceptance criteria |
| `/sdd-archive <change>` | Archive the completed change to `openspec/changes/archive/` |
| `/sdd-status` | Show active changes and artifact presence |

See [ORCHESTRATION.md](./ORCHESTRATION.md) for the full phase DAG and orchestration rules.

---

## Quick-start checklist

### New machine setup

- [ ] Clone the repo: `git clone <repo-url> ~/agent-config`
- [ ] Run `cd ~/agent-config && bash install.sh`
- [ ] Open any project in Claude Code and confirm skills are available (type `/sdd-status`)
- [ ] Set `GITHUB_TOKEN` environment variable if you use the GitHub MCP server
- [ ] (Optional) Run `/memory-manage` in each project to generate `ai-context/` files

### First SDD cycle

- [ ] Open a Claude Code session in your project
- [ ] Run `/sdd-explore <topic>` to investigate the codebase area
- [ ] Run `/sdd-propose <slug>` to create a proposal, then proceed with spec + design + tasks
- [ ] Review the artifacts in `openspec/changes/<slug>/`
- [ ] Approve and run `/sdd-apply <slug>`
- [ ] Run `bash install.sh` if the change modifies skills or CLAUDE.md
- [ ] Run `/sdd-verify <slug>` to confirm implementation meets the spec
- [ ] Run `/sdd-archive <slug>` to archive the completed change

### Deploying a config change

- [ ] Edit the relevant file(s) in the repo (skills, CLAUDE.md, hooks, etc.)
- [ ] Run `bash install.sh` to deploy the updated config to `~/.claude/`
- [ ] Verify the change is active by opening a new Claude Code session
- [ ] Run `git add <files> && git commit -m "chore: <description>"` to persist the change

---

## Troubleshooting

**Claude is not picking up my skill changes.**
Run `bash install.sh`. Changes in the repo are not live until deployed to `~/.claude/`.

**I ran `sync.sh` but my skill edits are missing from the repo.**
`sync.sh` only captures `~/.claude/memory/`. It does not sync skills, CLAUDE.md, or hooks.
Always edit files in the repo and deploy with `install.sh`.

**I edited a file directly in `~/.claude/` and it was overwritten.**
`install.sh` is one-way (repo → `~/.claude/`). Direct edits to `~/.claude/` are lost on the
next `install.sh` run. Always make changes in the repo.

**Claude is not routing my message to the SDD cycle.**
Intent classification may be disabled in the project's `CLAUDE.md`. Check for an
`intent_classification: disabled` override. Remove it or restrict it to re-enable routing.

---

## See also

- [SKILL-RESOLUTION.md](./SKILL-RESOLUTION.md) — full skill resolution algorithm (3 tiers, config override)
- [ORCHESTRATION.md](./ORCHESTRATION.md) — hub-and-spoke orchestration model, phase DAG, artifact flow
- [format-types.md](./format-types.md) — SKILL.md format types and section contracts
- [skills/README.md](../skills/README.md) — skill authoring guide and invocation pattern
