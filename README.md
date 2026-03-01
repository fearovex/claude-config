# claude-config

Global configuration repository for Claude Code. This repo is the source of truth for the
SDD (Specification-Driven Development) meta-system that runs inside Claude Code.

It serves two roles:

1. **Meta-tool** — creates, audits, and maintains the SDD + memory architecture across projects
2. **SDD Orchestrator** — executes specification-driven development cycles by delegating to
   specialized sub-agents

Changes made here are synced to `~/.claude/` (the Claude Code runtime directory) via `install.sh`
and captured back via `sync.sh`.

For the canonical reference on all commands, flow, and rules, read [CLAUDE.md](./CLAUDE.md).

---

## Repository Structure

```
claude-config/
├── CLAUDE.md              # Global orchestrator instructions (read by Claude at session start)
├── settings.json          # Claude Code user-level settings (MCP servers, permissions)
├── settings.local.json    # Machine-local overrides — NOT committed
├── install.sh             # One-way: repo → ~/.claude/  (new machine setup)
├── sync.sh                # One-way: ~/.claude/ → repo  (capture session changes)
├── skills/                # Skill catalog (~38 skills)
│   ├── sdd-*/             # SDD phase skills (8 phases)
│   ├── project-*/         # Meta-tool skills (setup, audit, fix, update)
│   ├── memory-init/       # Memory initialization (ai-context/ from scratch)
│   ├── memory-update/     # Memory update (session decisions → ai-context/)
│   ├── skill-creator/     # Skill scaffolding tool
│   └── [tech-skills]/     # Technology catalog (react-19, nextjs-15, typescript, etc.)
├── hooks/                 # Claude Code event hooks
├── memory/                # Claude auto-memory (per-project session notes)
├── openspec/              # SDD artifacts for this repo itself
│   ├── config.yaml        # SDD project configuration
│   └── changes/           # Active and archived change specs
│       └── archive/       # Completed changes (YYYY-MM-DD-name/)
└── ai-context/            # Project memory layer
    ├── stack.md
    ├── architecture.md
    ├── conventions.md
    ├── known-issues.md
    └── changelog-ai.md
```

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
| `project-update` | Updates the project `CLAUDE.md` with user-level changes |
| `memory-init` | Generates `ai-context/` files by reading the project from scratch |
| `memory-update` | Updates `ai-context/` with work done in the current session |
| `skill-creator` | Scaffolds a new skill directory with a compliant `SKILL.md` |

### Technology Skills

**Frontend / Full-stack**

| Skill | Description |
|-------|-------------|
| `react-19` | React 19 patterns and best practices |
| `nextjs-15` | Next.js 15 app router, server components, routing |
| `typescript` | TypeScript strict-mode conventions |
| `zustand-5` | Zustand 5 state management |
| `zod-4` | Zod 4 schema validation |
| `tailwind-4` | Tailwind CSS 4 utility-first styling |
| `ai-sdk-5` | Vercel AI SDK 5 for LLM integrations |
| `react-native` | React Native mobile development |
| `electron` | Electron desktop app development |

**Backend**

| Skill | Description |
|-------|-------------|
| `django-drf` | Django + Django REST Framework |
| `spring-boot-3` | Spring Boot 3 Java services |
| `hexagonal-architecture-java` | Hexagonal / ports-and-adapters architecture in Java |
| `java-21` | Java 21 features and idioms |

**Testing**

| Skill | Description |
|-------|-------------|
| `playwright` | End-to-end testing with Playwright |
| `pytest` | Python testing with pytest |

**Tooling / Process**

| Skill | Description |
|-------|-------------|
| `github-pr` | GitHub pull request workflow |
| `jira-task` | Jira task creation and management |
| `jira-epic` | Jira epic authoring |
| `smart-commit` | Conventional commit message generation |
| `elixir-antipatterns` | Elixir anti-pattern detection and fixes |

**Platforms / Misc**

| Skill | Description |
|-------|-------------|
| `claude-code-expert` | CLAUDE.md config, custom skills, hooks, MCP, advanced workflows |
| `excel-expert` | Excel file creation and analysis (ExcelJS, SheetJS, openpyxl, pandas) |
| `image-ocr` | OCR text extraction from images (Tesseract, EasyOCR, Claude Vision, etc.) |

---

## How to Use

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/claude-code) installed and authenticated
- `GITHUB_TOKEN` environment variable set (required for the GitHub MCP server)
- Git Bash or a Unix-compatible shell

### Initial Setup (new machine)

```bash
git clone <this-repo> ~/claude-config
cd ~/claude-config
bash install.sh
```

`install.sh` copies all files from the repo to `~/.claude/` and registers the GitHub and
filesystem MCP servers. This is a one-way operation: repo → `~/.claude/`.

> Note: `settings.local.json` is NOT restored by `install.sh`. Claude Code generates it
> automatically on first run.

### Capturing Changes Made During a Session

When a Claude Code session modifies files in `~/.claude/` (skills, CLAUDE.md, etc.), those
changes must be synced back to the repo before committing:

```bash
bash sync.sh
git add -A
git commit -m "chore: sync session changes"
```

`sync.sh` is a one-way operation: `~/.claude/` → repo.

> Warning: on Windows/Git Bash, `rsync` may not be available. Use the manual `cp -r` fallback
> documented in [ai-context/known-issues.md](./ai-context/known-issues.md).

### Making Changes to Skills or CLAUDE.md

The meta-SDD cycle for this repo:

```
/sdd-ff <change-name>  →  review artifacts  →  /sdd-apply  →  install.sh  →  git commit
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
| `/project-update` | Update the project `CLAUDE.md` with user-level changes |
| `/skill-create <name>` | Create a new skill (global or project-specific) |
| `/skill-add <name>` | Add a skill from the global catalog to the current project |
| `/memory-init` | Generate `ai-context/` files by reading the project from scratch |
| `/memory-update` | Update `ai-context/` with work done in the current session |

### SDD Development Cycle

| Command | Action |
|---------|--------|
| `/sdd-new <change>` | Start a complete SDD cycle for a change |
| `/sdd-ff <change>` | Fast-forward: propose → spec + design (parallel) → tasks |
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

The fast-forward shortcut `/sdd-ff <change>` runs propose → spec + design → tasks in one shot
and presents the full plan for approval before any code is written.

SDD artifacts are stored in `openspec/changes/<change-name>/` and archived to
`openspec/changes/archive/YYYY-MM-DD-<name>/` when complete.

---

## Contributing / Modifying

### Unbreakable Rules

1. **Language** — ALL content (skills, YAML, scripts, commits) MUST be in English. No exceptions.

2. **Skill structure** — every skill is a directory with exactly one `SKILL.md` entry point.
   `SKILL.md` must contain: trigger definition, process steps, rules section.

3. **SDD compliance** — every skill modification requires at minimum `/sdd-ff` before apply.
   Every archived change must have a `verify-report.md` with at least one checked criterion.

4. **Sync discipline** — always run `sync.sh` before committing. Never edit `~/.claude/`
   directly without syncing back to the repo.

### Meta-SDD cycle for this repo

```bash
# 1. Plan and spec the change
/sdd-ff <change-name>

# 2. Review the generated proposal, spec, design, and tasks in openspec/changes/<change-name>/

# 3. Implement
/sdd-apply <change-name>

# 4. Sync and commit
bash sync.sh
git add -A
git commit -m "feat: <description>"
```
