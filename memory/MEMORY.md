# User Memory — Juan Pablo

## SDD architecture installed (2026-02-23)

Specification-Driven Development was installed at the user level in `~/.claude/`.

### Core structure
- `~/.claude/CLAUDE.md` — global orchestrator with meta-tool and SDD commands
- `~/.claude/memory/MEMORY.md` — this file
- `~/.claude/skills/project-setup/` — initializes SDD + memory in projects
- `~/.claude/skills/project-audit/` — audits Claude project configuration
- `~/.claude/skills/project-update/` — updates or migrates project configuration
- `~/.claude/skills/skill-creator/` — creates generic or project-specific skills
- `~/.claude/skills/memory-update/` — updates project memory files
- `~/.claude/skills/sdd-explore/` — explore phase
- `~/.claude/skills/sdd-propose/` — propose phase
- `~/.claude/skills/sdd-spec/` — specification phase
- `~/.claude/skills/sdd-design/` — design phase
- `~/.claude/skills/sdd-tasks/` — task-planning phase
- `~/.claude/skills/sdd-apply/` — implementation phase
- `~/.claude/skills/sdd-verify/` — verification phase
- `~/.claude/skills/sdd-archive/` — archive phase

### Architecture philosophy
- User level acts as a meta-tool layer that creates, audits, and updates project setups.
- Projects receive `CLAUDE.md` plus `ai-context/` as the versioned memory layer.
- SDD is coordinated from the user level through delegated sub-agents.
- Memory is stored as versioned Markdown without external dependencies.

### Key commands
- `/project-setup` — initialize a new project
- `/project-audit` — run a health check
- `/sdd-ff <change-name>` — fast SDD cycle
- `/memory-update` — refresh project memory after a work session

## User preferences
- Prefer Spanish for conversation
- Prefer clean code without over-engineering
- Confirm before irreversible actions
