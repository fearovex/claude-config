# Analysis Report — claude-config

Last analyzed: 2026-03-08 00:00
Analyzer: project-analyze
Config: sample_size=20, targets=auto-detected

---

## Summary

`claude-config` is the global Claude Code meta-system repository — the source of truth for SDD orchestration, skill catalog, and project memory architecture. It deploys to `~/.claude/` via `install.sh` and captures memory back via `sync.sh`.

The project is organized in a clear feature-based pattern: each `skills/` subdirectory is a distinct capability with a single `SKILL.md` entry point. 49 skill directories are currently present (up from 47 on 2026-03-03). All documented architectural layers are present and correctly positioned. No active SDD changes currently in flight (last archived: `2026-03-08-clean-skill-template-noise`).

Stack detected: Markdown + YAML + Bash / Claude Code SDD meta-system / no database
Organization pattern: feature-based
Architecture drift: minor
Conventions documented: yes

---

## Stack

Source: openspec/config.yaml + file-extension sampling (no standard package manifests found)

| Category | Detected | Source |
|----------|----------|--------|
| Language | Markdown + YAML + Bash | openspec/config.yaml |
| Framework | Claude Code SDD meta-system | openspec/config.yaml |
| Database | none | openspec/config.yaml |
| Testing | manual validation via /project-audit | openspec/config.yaml |
| Build tool | install.sh (bash deploy) | file: install.sh |
| Hooks runtime | Node.js | file: hooks/smart-commit-context.js (.js extension) |
| Version control | Git | .git directory |

Key file types (no versioned package dependencies):
| File type | Count | Purpose |
|-----------|-------|---------|
| `.md` | 100 | SKILL.md entries, ai-context/, docs, openspec artifacts |
| `.json` | 3 | settings.json, settings.local.json, hook config |
| `.sh` | 2 | install.sh, sync.sh |
| `.yaml` | 1 | openspec/config.yaml |
| `.js` | 1 | hooks/smart-commit-context.js |
| `.ps1` | 1 | PowerShell helper script |

No standard package manifests (package.json, pyproject.toml, etc.) — expected for a Markdown/YAML/Bash meta-system.

Observed skill count: **49 directories** under `skills/`.

---

## Structure

Organization pattern: **feature-based**
Confidence: high — each `skills/` subdirectory is a distinct capability (feature/tool) with its own `SKILL.md` entry point; no technical layer separation within skills/

Top-level layout:
```
claude-config/
├── CLAUDE.md              # Global orchestrator instructions
├── settings.json          # Claude Code user settings
├── settings.local.json    # Local overrides (not committed)
├── install.sh             # Deploy repo → ~/.claude/
├── sync.sh                # Capture ~/.claude/memory/ → repo/memory/
├── skills/                # Skill catalog (49 skill directories) ← source root
│   ├── sdd-*/             # SDD phase + orchestrator skills (11)
│   ├── project-*/         # Meta-tool skills (6)
│   ├── memory-*/          # Memory management skills (2)
│   ├── skill-*/           # Skill management skills (2)
│   ├── claude-*/          # System/audit skills (2)
│   ├── config-export/     # Config export skill (1)
│   ├── feature-domain-expert/  # Domain knowledge skill (1)
│   ├── smart-commit/      # Commit automation (1)
│   └── [tech-skills]/     # Technology catalog (18 skills)
├── docs/                  # Documentation
│   ├── adr/               # Architecture Decision Records (23 ADRs + README)
│   ├── templates/         # prd-template.md, adr-template.md
│   └── copilot-templates/ # GitHub Copilot instruction exports
├── hooks/                 # Claude Code event hooks (Node.js)
├── openspec/              # SDD artifacts for this repo
│   ├── config.yaml
│   ├── changes/           # SDD change history (archive/)
│   └── specs/             # Domain specs (38 domains)
├── ai-context/            # Project memory layer
│   ├── stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md
│   ├── onboarding.md, quick-reference.md, scenarios.md
│   └── features/          # Feature-level domain knowledge stubs
├── memory/                # Claude auto-memory (per-project notes)
└── scripts/               # Helper scripts
```

Source root(s): `skills/` (49 feature directories)
Test root(s): none detected — testing is via `/project-audit` (integration test pattern)
Entry point(s): `CLAUDE.md` (read at session start), `skills/*/SKILL.md` (read on demand per trigger)

---

## Conventions Observed

Sample size: 10 SKILL.md files across 10 skill directories
Sampling method: auto-detected (most recently modified — representative cross-section: procedural, reference, anti-pattern formats)
Directories sampled: skills/project-audit, skills/sdd-apply, skills/sdd-ff, skills/sdd-propose, skills/project-fix, skills/memory-init, skills/react-19, skills/typescript, skills/smart-commit, skills/solid-ddd

### Naming
- Files: **UPPER_CASE** for entry points (`SKILL.md`), **kebab-case** for directories
  Example: `skills/project-audit/SKILL.md`, `skills/sdd-propose/`
- Functions/methods: **snake_case** in bash scripts
  Example: `copy_dir()` in install.sh
- YAML keys: **kebab-case** or **snake_case**
  Example: `artifact_store:`, `minimum_score_to_archive:`
- Skill name conventions: `sdd-[phase]`, `project-[action]`, `memory-[action]`, `[tech]-[version]`
  Example: `sdd-apply`, `project-audit`, `memory-init`, `react-19`

### Import style
N/A — SKILL.md files reference other skills via absolute path strings, not imports.
Example: `~/.claude/skills/sdd-propose/SKILL.md`

### Error handling
- Bash: `set -e` + `|| true` for expected-failures pattern
  Example: `claude mcp remove github 2>/dev/null || true`
- SKILL.md: guard clauses — explicit "Stop here if..." conditions
- Sub-agent contracts: `status: ok|warning|blocked|failed` return codes

### SKILL.md structure (observed — canonical pattern)
All sampled SKILL.md files follow this exact structure:
1. YAML frontmatter: `name`, `description`, `format: procedural|reference|anti-pattern`, optional `model`, `thinking`, `license`, `metadata`
2. H1 heading (`# skill-name`)
3. Blockquote description (`> ...`)
4. Bold triggers (`**Triggers**: ...`)
5. Format-specific main section:
   - `procedural` → `## Process` with nested `### Step N` headings
   - `reference` → `## Patterns` or `## Examples`
   - `anti-pattern` → `## Anti-patterns`
6. `## Rules` section always last

### Module/layer boundaries
Skills communicate exclusively via file artifacts — no in-memory passing. Each skill reads and writes named files:
- `audit-report.md` (project-audit → project-fix)
- `analysis-report.md` (project-analyze → project-audit D7)
- `openspec/changes/*/tasks.md` (sdd-tasks → sdd-apply)
- `ai-context/*.md` (memory-init/memory-update → all skills)

---

## Architecture Drift

Basis for comparison: `ai-context/architecture.md` exists — full drift comparison performed.

### Documented vs Observed

| Documented (architecture.md) | Observed in repo | Status |
|------------------------------|------------------|--------|
| `skills/` directory with skill subdirectories | ✅ `skills/` with 49 subdirs | match |
| `hooks/` directory | ✅ `hooks/` present | match |
| `openspec/` with config.yaml and changes/ | ✅ `openspec/config.yaml`, `changes/`, `specs/` | match |
| `ai-context/` with 5 core files | ✅ 8 files observed (5 core + 3 user-docs) | minor drift |
| `docs/adr/` with README.md | ✅ 23 ADRs + README.md | match |
| `docs/templates/` with prd and adr templates | ✅ both templates present | match |
| `memory/` directory | ✅ present | match |
| install.sh + sync.sh at root | ✅ both present | match |
| Skill count ~47 (last documented) | 49 observed | minor drift |
| Active SDD changes: none (as of 2026-03-03) | 0 active changes confirmed | match |

### Drift Summary

**minor** (2 informational entries)

Drift entries:
- Skill count: architecture.md last documented 47 skills; 49 observed (natural catalog growth — `smart-commit` functional variants or new tech skills added since last analysis)
  - Documented: ~47 skill directories under `skills/`
  - Observed: 49 skill directories
  - Impact: informational — no structural mismatch

- ai-context/ file count: architecture.md artifact table documents 3 user-doc files (onboarding.md, quick-reference.md, scenarios.md) which ARE present; stack.md skill category table references "5 core files" only (outdated count in manual section)
  - Documented: 5 core ai-context/ files (in stack.md skill categories section)
  - Observed: 8 files (5 core + onboarding.md + quick-reference.md + scenarios.md) + features/ subdirectory
  - Impact: informational — all files documented in architecture.md artifact table; stack.md manual count is stale

---

## ai-context/ Update Log

Files modified:
- `ai-context/stack.md`: updated section `stack-detection` (skill count 47→49, .md count 83→100)
- `ai-context/architecture.md`: updated section `structure-mapping` (active changes: none; skill count 49; ai-context 8 files), updated section `drift-summary`
- `ai-context/conventions.md`: updated section `observed-conventions` (no changes — conventions stable)

Human-edited sections preserved:
- `ai-context/stack.md` → ## What this project is, ## File types, ## Directory structure, ## Skill categories, ## Workflows
- `ai-context/architecture.md` → ## System role, ## Two-layer architecture, ## Skill architecture, ## SDD meta-cycle, ## Communication between skills via artifacts, ## Key architectural decisions, ## claude-folder-audit Check Inventory
- `ai-context/conventions.md` → ## Language, ## Naming conventions, ## SKILL.md structure, ## Git conventions, ## SDD workflow, ## PRD Convention, ## ADR Convention, ## Workflows
