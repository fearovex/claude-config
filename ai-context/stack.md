# Stack — claude-config

> Last updated: 2026-02-23

## What this project is

`claude-config` is the source-of-truth repository for the global Claude Code configuration. It is synced to `~/.claude/` via `install.sh` and captured back via `sync.sh`.

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
├── install.sh             # Restore ~/.claude/ from this repo
├── sync.sh                # Capture ~/.claude/ back into this repo
├── skills/                # Skill catalog (~35 skills)
│   ├── sdd-*/             # SDD phase skills (8 phases)
│   ├── project-*/         # Meta-tools (setup, audit, fix, update)
│   ├── memory-manager/    # Memory management
│   ├── skill-creator/     # Skill creation tool
│   └── [tech-skills]/     # Technology catalog (react-19, nextjs-15, etc.)
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
| Meta-tools | 6 | project-setup, project-audit, project-fix, project-update, memory-manager, skill-creator |
| Tech — Frontend | 8 | react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native |
| Tech — Backend | 4 | django-drf, spring-boot-3, hexagonal-architecture-java, java-21 |
| Tech — Testing | 2 | playwright, pytest |
| Tech — Tooling | 5 | github-pr, jira-task, jira-epic, elixir-antipatterns, electron |
| Misc | 4 | claude-code-expert, excel-expert, openclaw-assistant, image-ocr |

## Sync workflow

```bash
# Capture changes from ~/.claude/ into repo
bash sync.sh && git add -A && git commit -m "chore: sync"

# Restore repo config to ~/.claude/ (new machine or after reset)
bash install.sh
```

## Important: install.sh does NOT sync

`install.sh` copies FROM the repo TO `~/.claude/`. It does not read what's currently in `~/.claude/`. Always run `sync.sh` before making changes in the repo directly, to avoid overwriting work done via Claude Code sessions.
