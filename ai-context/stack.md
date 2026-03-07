# Stack — claude-config

> Last updated: 2026-03-06

## What this project is

`claude-config` is the source-of-truth repository for the global Claude Code configuration. It is deployed to `~/.claude/` via `install.sh`, while `sync.sh` captures `memory/` only.

## File types

| Type | Purpose |
|------|---------|
| `SKILL.md` | Skill entry point — instructions Claude reads and executes |
| `config.yaml` | SDD openspec project configuration |
| `*.md` | Memory layer, plans, SDD artifacts |
| `*.yaml` | SDD config |
| `*.sh` | Bash scripts (sync, install) |
| `settings.json` | Claude Code user-level settings (MCP, permissions) |

## Directory structure

```
claude-config/
├── CLAUDE.md              # Global orchestrator instructions
├── settings.json          # Claude Code user settings
├── settings.local.json    # Local overrides (not committed)
├── install.sh             # Deploy this repo into ~/.claude/
├── sync.sh                # Capture ~/.claude/memory/ back into repo/memory/
├── skills/                # Skill catalog
│   ├── sdd-*/             # SDD phase skills (8 phases)
│   ├── project-*/         # Meta-tools (setup, audit, fix, update)
│   ├── memory-init/       # Memory initialization (ai-context/ from scratch)
│   ├── memory-update/     # Memory update (session decisions → ai-context/)
│   ├── skill-creator/     # Skill creation tool
│   └── [tech-skills]/     # Technology catalog (react-19, nextjs-15, etc.)
├── docs/                  # Documentation artifacts
│   ├── templates/         # prd-template.md, adr-template.md
│   └── adr/               # Architecture Decision Records (Nygard format)
│       └── README.md      # ADR index — must be kept current
├── memory/                # Claude auto-memory (per-project notes)
├── hooks/                 # Claude Code event hooks
├── openspec/              # SDD artifacts for this repo
│   ├── config.yaml
│   └── changes/
│       └── archive/
└── ai-context/            # This directory — memory layer
```

## Skill categories

| Category | Count | Examples |
|----------|-------|---------|
| SDD phases | 8 | sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-explore |
| Meta-tools | 10 | project-setup, project-onboard, project-audit, project-analyze, project-fix, project-update, memory-init, memory-update, skill-creator, skill-add |
| Tech — Frontend | 8 | react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native |
| Tech — Backend | 4 | django-drf, spring-boot-3, hexagonal-architecture-java, java-21 |
| Tech — Testing | 2 | playwright, pytest |
| Tech — Tooling | 5 | github-pr, jira-task, jira-epic, elixir-antipatterns, electron |
| Misc | 3 | claude-code-expert, excel-expert, image-ocr |

## Workflows

```bash
# Workflow A — Config changes (skills, CLAUDE.md, hooks, ai-context, openspec)
# edit in repo → deploy → commit
bash install.sh && git add -A && git commit -m "feat: ..."

# Workflow B — Memory capture (periodic)
# sync user memory from ~/.claude/memory/ → repo
bash sync.sh && git add memory/ && git commit -m "chore: sync user memory"

# New machine setup
git clone <repo> && bash install.sh
```

`install.sh` is repo-authoritative: copies everything repo → `~/.claude/`.
`sync.sh` captures memory/ only: `~/.claude/memory/ → repo/memory/`. Never run it expecting to capture skill or config changes.

<!-- [auto-updated]: stack-detection — last run: 2026-03-03 -->
## Stack (auto-detected)

Source: openspec/config.yaml + file-extension sampling

| Category | Detected | Source |
|----------|----------|--------|
| Language | Markdown + YAML + Bash | openspec/config.yaml |
| Framework | Claude Code SDD meta-system | openspec/config.yaml |
| Database | none | openspec/config.yaml |
| Testing | manual validation via /project-audit | openspec/config.yaml |
| Build tool | install.sh (bash deploy) | file: install.sh |
| Hooks runtime | Node.js | file: hooks/smart-commit-context.js (.js extension) |
| Version control | Git | .git directory |

Observed skill count: **49 directories** under `skills/`.
File extension distribution: `.md` (83), `.json` (3), `.sh` (2), `.yaml` (1), `.js` (1).
No standard package manifests (package.json, pyproject.toml, etc.) — expected for a Markdown/YAML/Bash meta-system.

<!-- [/auto-updated] -->
