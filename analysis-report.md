# Analysis Report — claude-config

Last analyzed: 2026-02-28 (current session)
Analyzer: project-analyze
Config: sample_size=20, targets=auto-detected

---

## Summary

`claude-config` is the global brain of Claude Code: a pure documentation and configuration project with no compiled code. It defines the SDD orchestration workflow, a catalog of 43 skills (each a directory with one `SKILL.md` entry point), and the memory layer for Claude sessions. The project is synced to `~/.claude/` via `install.sh` and memory is captured back via `sync.sh`.

The project is organized as a flat directory of skills under `skills/`, each directory representing a distinct capability (SDD phase, meta-tool, or technology skill). This is a feature-based organization applied to a documentation/config project.

Stack detected: Markdown + YAML + Bash / Claude Code SDD meta-system / none
Organization pattern: feature-based
Architecture drift: minor
Conventions documented: yes

---

## Stack

Source: openspec/config.yaml (project manifest) + file-extension sampling

| Category | Detected | Source |
|----------|----------|--------|
| Language | Markdown + YAML + Bash | openspec/config.yaml `stack.language` |
| Framework | Claude Code SDD meta-system | openspec/config.yaml `stack.framework` |
| Database | none | openspec/config.yaml `stack.database` |
| Testing | manual validation via /project-audit | openspec/config.yaml `stack.testing` |
| Build tool | install.sh (bash deploy script) | file: install.sh |
| Hooks runtime | Node.js (smart-commit-context.js) | file: hooks/smart-commit-context.js |
| Version control | Git | .git directory present |

No standard package manifests found (no package.json, pyproject.toml, pom.xml, etc.). This is expected for a Markdown/YAML/Bash meta-system.

Key file types (by count):
| Extension | Count | Inferred purpose |
|-----------|-------|-----------------|
| `.md` | 145 | Skill entry points, SDD artifacts, memory layer |
| `.json` | 3 | Claude Code settings |
| `.sh` | 2 | Deploy and sync scripts |
| `.yaml` | 1 | openspec config |
| `.js` | 1 | Hooks (Node.js) |

---

## Structure

Organization pattern: feature-based
Confidence: high — all 43 `skills/` subdirectories are named after business capabilities, each containing exactly one `SKILL.md` entry point; no technical-layer directories (no `api/`, `models/`, `controllers/`)

Top-level layout:
```
claude-config/ (observed 2026-02-28)
├── CLAUDE.md              # Global orchestrator instructions (primary entry point)
├── README.md              # Project documentation
├── settings.json          # Claude Code user-level settings
├── settings.local.json    # Local overrides (not committed to VCS)
├── install.sh             # Deploy: repo → ~/.claude/ (all directories)
├── sync.sh                # Capture: ~/.claude/memory/ → repo/memory/ only
├── skills/                # Skill catalog (43 skills, each in own directory)
│   ├── sdd-*/             # SDD phase skills (11): sdd-explore, sdd-propose, sdd-spec,
│   │                      #   sdd-design, sdd-tasks, sdd-apply, sdd-verify,
│   │                      #   sdd-archive, sdd-ff, sdd-new, sdd-status
│   ├── project-*/         # Meta-tools (6): project-setup, project-onboard,
│   │                      #   project-audit, project-analyze, project-fix,
│   │                      #   project-update
│   ├── memory-manager/    # Memory management skill
│   ├── skill-add/         # Skill registry management
│   ├── skill-creator/     # Skill creation tool
│   ├── smart-commit/      # Git commit workflow
│   └── [tech-skills]/     # Technology catalog (react-19, nextjs-15, typescript,
│                          #   zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native,
│                          #   electron, django-drf, spring-boot-3, java-21,
│                          #   hexagonal-architecture-java, playwright, pytest,
│                          #   github-pr, jira-task, jira-epic, elixir-antipatterns,
│                          #   claude-code-expert, excel-expert, image-ocr)
├── hooks/                 # Claude Code event hooks
│   └── smart-commit-context.js
├── openspec/              # SDD artifacts for this repo
│   ├── config.yaml        # openspec configuration
│   ├── changes/           # Active SDD changes + archive/
│   └── specs/             # Shared specs (7 subdirs: audit-dimensions, audit-execution,
│                          #   audit-scoring, config-schema, fix-setup-behavior,
│                          #   global-permissions, project-analysis)
├── ai-context/            # Memory layer (8 files: stack, architecture, conventions,
│                          #   known-issues, changelog-ai, onboarding, quick-reference, scenarios)
└── memory/                # Claude auto-memory (MEMORY.md + topic files)
```

Source root(s): `skills/` (43 skill directories, each with SKILL.md)
Test root(s): none detected (validation via `/project-audit` command)
Entry point(s): `CLAUDE.md` (orchestrator), `skills/*/SKILL.md` (skill entry points)

---

## Conventions Observed

Sample size: 10 files across 4 directories
Sampling method: auto-detected (representative files from each category)
Directories sampled: skills/ (5 SKILL.md files), hooks/, root scripts

### Naming
- Skill directories: kebab-case — e.g. `project-audit`, `sdd-propose`, `react-19`, `smart-commit`
- SKILL.md entry point: UPPER_CASE filename — `SKILL.md` in every skill directory
- SDD change names: kebab-case descriptive — e.g. `normalize-tech-skill-structure`
- Archived changes: `YYYY-MM-DD-[name]` prefix — e.g. `2026-02-27-global-config-skill-audit`
- Bash functions: snake_case — e.g. `copy_dir` in install.sh

### SKILL.md structure (observed pattern)
All sampled SKILL.md files follow a consistent structure:
1. Optional YAML frontmatter (`---`) with `name`, `description`, optional `license`/`metadata`
2. `# skill-name` H1 heading
3. `> One-line description` blockquote
4. `**Triggers**: [when to use]` bold triggers
5. `## Step N — Description` numbered steps with em-dash separator
6. `## Rules` section at the end (hard constraints)

### Import style
Not applicable — no code imports. Skills reference other artifacts by file path.
Example pattern: `Read the file ~/.claude/skills/sdd-[PHASE]/SKILL.md`

### Error handling
- Bash scripts: `set -e` (fail-fast) + `|| true` for expected-to-fail commands
  Example: `claude mcp remove github 2>/dev/null || true`
- SKILL.md: explicit "Stop here if..." guard clauses

### Inter-skill communication
- Skills are isolated: each SKILL.md is self-contained
- Communication exclusively via file artifacts (audit-report.md, tasks.md, analysis-report.md)
- Orchestrator skills (sdd-ff, sdd-new) use the Task tool to delegate to sub-agents

---

## Architecture Drift

Basis for comparison: `ai-context/architecture.md` (last updated: 2026-02-23)

### Documented vs Observed

| Documented (architecture.md / stack.md) | Observed in repo | Status |
|-----------------------------------------|------------------|--------|
| `CLAUDE.md` at root | Found at root | match |
| `skills/` directory with skill subdirs | Found — 43 subdirs (SKILL.md each) | match |
| `settings.json` at root | Found at root | match |
| `hooks/` directory | Found with `smart-commit-context.js` | match |
| `openspec/` with config.yaml + changes/archive | Found; also has `specs/` subdir | match |
| `ai-context/` with stack, arch, conventions, etc. | Found — 8 files present | match |
| `memory/` directory | Found with MEMORY.md | match |
| `install.sh` at root | Found at root | match |
| `sync.sh` at root | Found at root | match |
| `stack.md` Misc category: `openclaw-assistant` | No `skills/openclaw-assistant/` dir found | minor drift |
| `stack.md` skill count: ~35 skills | 43 skill directories observed | minor drift |
| `openspec/specs/` directory | Found with 7 subdirs, not in stack.md tree | minor drift |
| `README.md` at root | Found — not mentioned in architecture.md | minor drift |
| Command separator: `/sdd:ff` in conventions.md | Runtime uses `/sdd-ff` (hyphen) | minor drift |

### Drift Summary

Drift level: **minor** (5 informational entries)

- `openclaw-assistant` referenced in `stack.md` Misc category but no corresponding directory exists — likely renamed or removed without updating stack.md
- Skill count: stack.md manual section documents ~35 skills, 43 observed (natural growth since 2026-02-23)
- `openspec/specs/` directory (7 subdirs) present but not in stack.md directory tree
- `README.md` at root not mentioned in documented structure
- `conventions.md` SDD workflow section uses old colon separator (`/sdd:ff`) while runtime uses hyphen (`/sdd-ff`)

All drift is informational. No structural mismatches detected.

---

## ai-context/ Update Log

Files modified:
- `ai-context/stack.md` — updated `[auto-updated]: stack-detection` section
- `ai-context/architecture.md` — updated `[auto-updated]: structure-mapping` and `[auto-updated]: drift-summary` sections
- `ai-context/conventions.md` — updated `[auto-updated]: observed-conventions` section

Human-edited sections preserved — only content within `[auto-updated]` markers was replaced.
