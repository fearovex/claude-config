# Analysis Report — claude-config

Last analyzed: 2026-03-01 00:00
Analyzer: project-analyze
Config: sample_size=20, targets=auto-detected

---

## Summary

`claude-config` is the global Claude Code meta-system repository — the source of truth for SDD orchestration, skill catalog, and project memory architecture. It deploys to `~/.claude/` via `install.sh` and captures memory back via `sync.sh`.

The project is organized in a clear feature-based pattern: each `skills/` subdirectory is a distinct capability with a single `SKILL.md` entry point. 44 skill directories are currently present, up from 43 in the previous analysis (2026-02-28). All documented architectural layers are present and correctly positioned.

Stack detected: Markdown + YAML + Bash / Claude Code SDD meta-system / no database
Organization pattern: feature-based
Architecture drift: minor
Conventions documented: yes

---

## Stack

Source: openspec/config.yaml (no standard package manifests found)

| Category | Detected | Source |
|----------|----------|--------|
| Language | Markdown + YAML + Bash | config.yaml `stack.language` |
| Framework | Claude Code SDD meta-system | config.yaml `stack.framework` |
| Database | none | config.yaml `stack.database` |
| Testing | manual validation via /project-audit | config.yaml `stack.testing` |
| Build tool | install.sh / sync.sh | root-level shell scripts |
| Hooks runtime | Node.js | hooks/smart-commit-context.js |
| Version control | Git | .git directory |

Key dependencies (top 10 by apparent importance):

| Package | Version | Inferred purpose |
|---------|---------|-----------------|
| Claude Code CLI | user-level | Execution runtime for all skills and orchestration |
| SKILL.md convention | N/A | Entry point contract for every skill directory |
| openspec/config.yaml | N/A | Project-level SDD configuration and analysis parameters |
| install.sh | N/A | Deployment pipeline: repo → ~/.claude/ |
| sync.sh | N/A | Memory capture: ~/.claude/memory/ → repo/memory/ |
| ai-context/ layer | N/A | Project memory: stack, arch, conventions, known-issues, changelog |
| openspec/ artifacts | N/A | SDD change lifecycle storage |
| docs/adr/ | N/A | Architecture Decision Record catalog |
| hooks/smart-commit-context.js | N/A | Claude Code event hook (Node.js) |
| settings.json | N/A | Claude Code user-level settings (MCP, permissions) |

No standard package manifests found (package.json, pyproject.toml, etc.) — expected for this Markdown/YAML/Bash meta-system.

---

## Structure

Organization pattern: feature-based
Confidence: high — all 44 `skills/` subdirectories are named after business capabilities, each containing exactly one `SKILL.md` entry point; no technical-layer directories (no `api/`, `models/`, `controllers/`)

Top-level layout:
```
claude-config/ (observed 2026-03-01)
├── CLAUDE.md              # Global orchestrator instructions (primary entry point)
├── README.md              # Project documentation
├── settings.json          # Claude Code user-level settings
├── install.sh             # Deploy: repo → ~/.claude/ (all directories)
├── sync.sh                # Capture: ~/.claude/memory/ → repo/memory/ only
├── analysis-report.md     # project-analyze output
├── skills/                # Skill catalog (44 skills, each in own directory)
│   ├── sdd-*/             # SDD phase/orchestrator skills (9): sdd-explore, sdd-propose,
│   │                      #   sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify,
│   │                      #   sdd-archive, sdd-ff, sdd-new, sdd-status
│   ├── project-*/         # Meta-tools (6): project-setup, project-onboard,
│   │                      #   project-audit, project-analyze, project-fix, project-update
│   ├── memory-init/       # Memory initialization
│   ├── memory-update/     # Memory session update
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
├── openspec/              # SDD artifact store
│   ├── config.yaml
│   ├── changes/           # Active SDD changes + archive/
│   └── specs/             # Domain specifications
├── ai-context/            # Memory layer (8 files: stack, architecture, conventions,
│                          #   known-issues, changelog-ai, onboarding, quick-reference, scenarios)
├── docs/                  # Documentation
│   ├── adr/               # Architecture Decision Records (6 ADRs)
│   └── templates/         # prd-template.md, adr-template.md
└── memory/                # User memory snapshot (MEMORY.md + topic files)
```

Source root(s): `skills/` (44 skill directories, each with SKILL.md)
Test root(s): none detected (validation via `/project-audit` command)
Entry point(s): `CLAUDE.md` (orchestrator), `skills/*/SKILL.md` (skill entry points)

---

## Conventions Observed

Sample size: 20 files across 2 directories
Sampling method: auto-detected
Directories sampled: `skills/` (SKILL.md files), `ai-context/`

### Naming
- Files: kebab-case for skill directories; UPPER for entry points
  Example: `sdd-ff/SKILL.md`, `project-audit/SKILL.md`
- Functions/methods: imperative verb phrases in SKILL.md step headings (no traditional code functions)
  Example: `## Step 1 — Validate argument`, `## Launch propose sub-agent`
- Classes/types: N/A — no programming language in this project
- Constants: UPPER_SNAKE for entry point filenames; `YYYY-MM-DD-[name]` for archived changes
  Example: `SKILL.md`, `2026-02-23-add-project-fix`

### Import style
Not applicable — documentation/configuration project. Skills reference other artifacts by absolute path.
Example: `~/.claude/skills/sdd-propose/SKILL.md`

### Error handling
- Bash scripts: `set -e` (fail-fast) + `|| true` for expected-to-fail commands
  Example: `claude mcp remove github 2>/dev/null || true`
- SKILL.md: explicit guard clauses — "Stop here if argument is missing."
- Sub-agent return contracts: `status: ok|warning|blocked|failed`

### Module/layer boundaries
- Orchestrator (CLAUDE.md) reads SKILL.md → delegates to sub-agents via Task tool
- Skills communicate exclusively via file artifacts (never in-memory state)
- install.sh deploys all skills; sync.sh is memory-only (one-way)

---

## Architecture Drift

Basis for comparison: `ai-context/architecture.md` (last updated: 2026-02-23; auto-updated: 2026-02-28)

### Documented vs Observed

| Documented (architecture.md) | Observed in repo | Status |
|------------------------------|------------------|--------|
| `CLAUDE.md` at root | Present | match |
| `skills/` — skill catalog | Present, 44 directories | minor drift — count 43→44 |
| `settings.json` at root | Present | match |
| `hooks/` with smart-commit-context.js | Present | match |
| `openspec/` — config.yaml + changes/ + specs/ | Present with all three | match |
| `ai-context/` — 8 files | Present, 8 files | match |
| `memory/` — user memory snapshot | Present | match |
| `docs/adr/` + `docs/templates/` | Present | match |
| `install.sh` + `sync.sh` at root | Both present | match |
| Two-layer architecture (repo → ~/.claude/) | `.claude/` local dir at repo root | minor drift — local audit artifact, expected |

### Drift Summary

minor (2 informational entries)

Drift entries:
- Skill count: 44 observed vs. 43 documented in previous auto-update (2026-02-28)
  - Documented: "43 skill directories"
  - Observed: 44 skill directories (one new skill added since 2026-02-28)
  - Impact: informational — natural catalog growth

- `.claude/` local directory at repo root not in documented structure
  - Documented: no `.claude/` entry in folder tree
  - Observed: `.claude/audit-report.md` present (local audit artifact from previous run)
  - Impact: informational — expected local runtime artifact, not committed to VCS

---

## ai-context/ Update Log

Files modified:
- `ai-context/stack.md` — updated section: `stack-detection`
- `ai-context/architecture.md` — updated sections: `structure-mapping`, `drift-summary`
- `ai-context/conventions.md` — updated section: `observed-conventions`

Human-edited sections preserved:
- `ai-context/stack.md` → What this project is, File types, Directory structure, Skill categories, Workflows
- `ai-context/architecture.md` → System role, Two-layer architecture, Skill architecture, SDD meta-cycle, Communication between skills via artifacts, Key architectural decisions
- `ai-context/conventions.md` → Language, Naming conventions, SKILL.md structure, Git conventions, SDD workflow, PRD Convention, ADR Convention, Workflows
