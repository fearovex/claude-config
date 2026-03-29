# agent-config

Global configuration repository for Claude Code. This repo is the source of truth for the
SDD (Specification-Driven Development) meta-system that runs inside Claude Code.

It serves two roles:

1. **Meta-tool** — creates, audits, and maintains the SDD + memory architecture across projects
2. **SDD Orchestrator** — executes specification-driven development cycles by delegating to
   specialized sub-agents

Changes made here are deployed to `~/.claude/` (the Claude Code runtime directory) via `install.sh`.
Only Claude's auto-memory is captured back via `sync.sh`.

For the canonical reference on all commands, flow, and rules, read [CLAUDE.md](./CLAUDE.md).
For the canonical reference on all commands, flow, and rules, read [CLAUDE.md](./CLAUDE.md).

---

## Repository Structure

```
agent-config/
├── CLAUDE.md              # Global orchestrator instructions (read by Claude at session start)
├── settings.json          # Claude Code user-level settings (MCP servers, permissions)
├── install.sh             # One-way: repo → ~/.claude/  (deploy to runtime)
├── sync.sh                # One-way: ~/.claude/memory/ → repo/  (capture auto-memory)
├── skills/                # Skill catalog (~33 skills)
│   ├── _shared/           # Shared contracts (persistence, phase-common, conventions)
│   ├── sdd-*/             # SDD phase skills (8 phases + init + status)
│   ├── project-*/         # Meta-tool skills (setup, audit, fix, onboard)
│   ├── memory-manage/     # ai-context/ management (init/update/maintain)
│   ├── skill-creator/     # Skill scaffolding
│   └── [tech-skills]/     # Technology patterns (react-19, nextjs-15, typescript, etc.)
├── hooks/                 # Claude Code event hooks
├── docs/                  # Reference docs (format-types, skill-resolution, templates)
└── output-styles/         # Output persona (gentleman.md)
```

**Persistence**: Engram (default) for cross-session memory. OpenSpec (fallback) for file-based artifacts. Both created in TARGET projects by `/project-setup` — not stored in this repo.

---

## Skills Catalog

Each skill is a directory with a single `SKILL.md` entry point. Claude reads the relevant
SKILL.md on demand and executes its instructions.

### SDD Phase Skills

| Skill | Description |
|-------|-------------|
| `sdd-explore` | Investigates a topic or codebase without committing to changes |
| `sdd-propose` | Creates a proposal document for a change |
| `sdd-spec` | Writes delta specifications (WHAT the change must do) |
| `sdd-design` | Creates a technical design (HOW to implement it) |
| `sdd-tasks` | Breaks the design into a phased task plan |
| `sdd-apply` | Implements tasks following specs and design |
| `sdd-verify` | Verifies implementation against acceptance criteria |
| `sdd-archive` | Archives a completed change into `openspec/changes/archive/` |

### Meta-tool Skills

| Skill | Description |
|-------|-------------|
| `project-setup` | Deploys SDD + memory structure in a new project |
| `project-audit` | Audits a project's Claude config across 10 dimensions, generates `audit-report.md` |
| `project-fix` | Reads `audit-report.md` and applies all corrections |
| `memory-manage` | Initializes, updates, or maintains `ai-context/` files (all modes) |
| `skill-creator` | Scaffolds a new skill directory or registers an existing global skill |

### Technology Skills

**Frontend / Full-stack**

| Skill | Description |
|-------|-------------|
| `react-19` | React 19 patterns and best practices |
| `nextjs-15` | Next.js 15 app router, server components, routing |
| `typescript` | TypeScript strict-mode conventions |
| `zustand-5` | Zustand 5 state management |
| `tailwind-4` | Tailwind CSS 4 utility-first styling |
| `react-native` | React Native mobile development |

**Tooling / Process**

| Skill | Description |
|-------|-------------|
| `smart-commit` | Conventional commit message generation |
| `config-export` | Exports Claude config to Copilot, Gemini, and Cursor formats |

**Design / Testing**

| Skill | Description |
|-------|-------------|
| `solid-ddd` | Language-agnostic SOLID principles and DDD tactical patterns |
| `go-testing` | Go testing patterns including Bubbletea TUI testing |

---

## How to Use

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/claude-code) installed and authenticated
- `GITHUB_TOKEN` environment variable set (required for the GitHub MCP server)
- Git Bash or a Unix-compatible shell

### Initial Setup (new machine)

```bash
git clone <this-repo> ~/agent-config
cd ~/agent-config
bash install.sh
```

`install.sh` copies all files from the repo to `~/.claude/` and registers the GitHub and
filesystem MCP servers. This is a one-way operation: repo → `~/.claude/`.

> Note: `settings.local.json` is NOT restored by `install.sh`. Claude Code generates it
> automatically on first run.

### Capturing Changes Made During a Session

When Claude writes auto-memory during a session, that memory can be synced back to the repo:

```bash
bash sync.sh
git add memory/
git commit -m "chore: sync user memory"
```

`sync.sh` is a one-way operation: `~/.claude/memory/` → `repo/memory/`.

It does not sync skills, hooks, `CLAUDE.md`, `ai-context/`, or `openspec/`.

### Making Changes to Skills or CLAUDE.md

The meta-SDD cycle for this repo:

```
/sdd-explore <change-name>  →  /sdd-propose <change-name>  →  review  →  /sdd-apply  →  install.sh  →  git commit
```

For breaking changes to the orchestrator or SDD phase skills, the full cycle is required:
explore → propose → spec + design → tasks → apply → verify → archive.

---

## Available Commands

Open a Claude Code session inside any project that has `~/.claude/` installed.

### Meta-tools

| Command | Action |
|---------|--------|
| `/project-setup` | Deploy SDD + memory structure in the current project |
| `/project-audit` | Audit the project's Claude config — generates `audit-report.md` (10 dimensions) |
| `/project-fix` | Apply all corrections from `audit-report.md` |
| `/skill-create <name>` | Create a new skill or register an existing global skill |
| `/memory-manage` | Initialize, update, or maintain `ai-context/` files |

### SDD Development Cycle

| Command | Action |
|---------|--------|
| `/sdd-explore <topic>` | Explore a topic without committing to changes |
| `/sdd-propose <change>` | Create a proposal |
| `/sdd-spec <change>` | Write delta specifications |
| `/sdd-design <change>` | Create a technical design |
| `/sdd-tasks <change>` | Break down a task plan |
| `/sdd-apply <change>` | Implement the task plan |
| `/sdd-verify <change>` | Verify implementation against specs |
| `/sdd-archive <change>` | Archive a completed change |
| `/sdd-status` | View the active SDD cycle status |

---

## SDD Development Cycle

The phase DAG for any change:

```
explore (optional)
      │
      ▼
  propose
      │
   ┌──┴──┐
   ▼     ▼
 spec  design   ← run in parallel
   └──┬──┘
      ▼
   tasks
      │
      ▼
   apply
      │
      ▼
  verify
      │
      ▼
 archive
```

Start with `/sdd-explore <topic>` to investigate, then `/sdd-propose <change>` to create a proposal.
Proceed through spec + design + tasks, then apply and verify before archiving.

SDD artifacts are stored in `openspec/changes/<change-name>/` and archived to
`openspec/changes/archive/YYYY-MM-DD-<name>/` when complete.

---

## Contributing / Modifying

### Unbreakable Rules

1. **Language** — ALL content (skills, YAML, scripts, commits) MUST be in English. No exceptions.

2. **Skill structure** — every skill is a directory with exactly one `SKILL.md` entry point.
   `SKILL.md` must contain: trigger definition, process steps, rules section.

3. **SDD compliance** — every skill modification requires at minimum `/sdd-explore` + `/sdd-propose` before apply.
   Every archived change must have a `verify-report.md` with at least one checked criterion.

4. **Sync discipline** — use `install.sh` for config changes and `sync.sh` only for
   `memory/`. Never edit `~/.claude/` directly.

### Meta-SDD cycle for this repo

```bash
# 1. Explore and plan the change
/sdd-explore <change-name>
/sdd-propose <change-name>

# 2. Review the generated proposal, spec, design, and tasks in openspec/changes/<change-name>/

# 3. Implement
/sdd-apply <change-name>

# 4. Deploy and commit
bash install.sh
git add -A
git commit -m "feat: <description>"
```
