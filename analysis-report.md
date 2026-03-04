# Analysis Report — claude-config

Last analyzed: 2026-03-03 00:00
Analyzer: project-analyze
Config: sample_size=20, targets=auto-detected

---

## Summary

`claude-config` is the global Claude Code meta-system repository — the source of truth for SDD orchestration, skill catalog, and project memory architecture. It deploys to `~/.claude/` via `install.sh` and captures memory back via `sync.sh`.

The project is organized in a clear feature-based pattern: each `skills/` subdirectory is a distinct capability with a single `SKILL.md` entry point. 47 skill directories are currently present (up from 44 on 2026-03-01). All documented architectural layers are present and correctly positioned. Three active SDD changes are in flight: `config-export`, `enhance-claude-folder-audit`, and `feature-domain-knowledge-layer`.

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
| Build tool | install.sh (bash deploy) | file: install.sh |
| Hooks runtime | Node.js (hooks/smart-commit-context.js) | file extension: .js |
| Version control | Git | .git directory |

Key dependencies (top 10 by apparent importance):

| Package | Version | Inferred purpose |
|---------|---------|-----------------|
| Claude Code CLI | n/a | Runtime host — SKILL.md files are executed by Claude Code |
| Bash | system | install.sh, sync.sh deployment scripts |
| Git | system | Version control and SDD artifact history |
| Node.js | system | hooks/smart-commit-context.js hook runtime |
| Markdown | n/a | Primary content language for all SKILL.md files |
| YAML | n/a | openspec/config.yaml and frontmatter in SKILL.md files |
| GitHub MCP | via settings.json | GitHub API access registered in install.sh |
| Filesystem MCP | via settings.json | File read/write access for skills |

No standard package manifests found (package.json, pyproject.toml, pom.xml, go.mod, Cargo.toml, mix.exs, composer.json). This is expected: the project is a Markdown/YAML/Bash meta-system, not an application. Stack inferred from file extension distribution: `.md` (83 files), `.json` (3 files), `.sh` (2 files), `.yaml` (1 file), `.js` (1 file).

---

## Structure

Organization pattern: feature-based
Confidence: high — each `skills/` subdirectory is a distinct capability domain; naming follows a consistent prefix convention (sdd-*, project-*, memory-*, skill-*); no single flat source root

Top-level layout:

```
claude-config/
├── CLAUDE.md              [orchestrator] — global SDD orchestrator instructions for Claude
├── README.md              [documentation] — project overview
├── settings.json          [configuration] — Claude Code user-level settings (MCP, permissions)
├── settings.local.json    [configuration] — local overrides, not committed
├── install.sh             [tooling/scripts] — deploys repo → ~/.claude/
├── sync.sh                [tooling/scripts] — captures ~/.claude/memory/ → repo/memory/
├── .gitattributes         [configuration] — forces LF line endings for scripts
├── .gitignore             [configuration] — git exclusions
├── skills/                [source root] — 47 skill directories, each with SKILL.md
│   ├── sdd-*/             SDD phase skills (11: explore, propose, spec, design, tasks, apply, verify, archive, ff, new, status)
│   ├── project-*/         Meta-tool skills (6: setup, onboard, audit, analyze, fix, update)
│   ├── memory-*/          Memory management skills (2: memory-init, memory-update)
│   ├── skill-*/           Skill management skills (2: skill-creator, skill-add)
│   ├── claude-*/          System audit skills (2: claude-code-expert, claude-folder-audit)
│   ├── config-export/     Config export skill (1)
│   ├── feature-domain-expert/ Domain knowledge skill (1)
│   ├── smart-commit/      Commit automation skill (1)
│   └── [tech-skills]/     Technology catalog (18 skills)
├── hooks/                 [tooling] — smart-commit-context.js (Node.js hook)
├── openspec/              [configuration] — SDD artifacts for this repo itself
│   ├── config.yaml        SDD project configuration
│   ├── specs/             master spec domains (22 directories)
│   └── changes/           active changes (3) + archive/
├── ai-context/            [documentation/memory] — 8 memory files + features/ scaffold
│   └── features/          feature domain knowledge scaffold
├── docs/                  [documentation] — ADRs + templates
│   ├── adr/               16 ADRs + README.md index
│   └── templates/         prd-template.md, adr-template.md
└── memory/                [memory] — Claude auto-memory (MEMORY.md + topic files)
```

Source root(s): `skills/` (primary — 47 subdirectories, each containing SKILL.md)
Test root(s): none detected (testing is manual, via /project-audit integration test)
Entry point(s): `CLAUDE.md` (read by Claude at session start), `skills/*/SKILL.md` (read on demand per command)

---

## Conventions Observed

Sample size: 20 files across skills/, ai-context/
Sampling method: auto-detected (SKILL.md files from SDD, meta-tool, and tech skill categories + ai-context/ memory files)
Directories sampled: skills/sdd-ff, skills/sdd-propose, skills/sdd-apply, skills/sdd-archive, skills/project-audit, skills/project-fix, skills/memory-init, skills/react-19, skills/elixir-antipatterns, skills/smart-commit, skills/config-export, skills/claude-folder-audit, skills/feature-domain-expert, ai-context/

### Naming
- Files: UPPER_CASE for entry points (`SKILL.md`), kebab-case for directories (`project-audit/`, `sdd-propose/`, `react-19/`)
  Example: `skills/project-audit/SKILL.md`
- Skill directories: kebab-case with semantic prefix — `sdd-[phase]`, `project-[action]`, `memory-[action]`, `skill-[action]`, `[tech]-[version]`
  Example: `sdd-ff`, `project-setup`, `memory-init`, `react-19`, `zustand-5`
- Bash functions: snake_case
  Example: `copy_dir` in install.sh
- SDD change names: kebab-case descriptive
  Example: `smart-commit-auto-stage`, `claude-folder-audit-project-mode`
- Archived changes: `YYYY-MM-DD-[name]`
  Example: `2026-03-03-smart-commit-auto-stage`
- Constants/sections: UPPER_SNAKE where applicable
  Example: `ANALYSIS_REPORT_EXISTS`, `ANALYSIS_REPORT_DATE` (in project-audit Phase A variables)

### Import style
Not applicable — primary content language is Markdown, not a programming language with import statements. Skills reference each other by absolute path in prose:
Example: `~/.claude/skills/sdd-propose/SKILL.md`

### Error handling
- Bash: `set -e` + `|| true` for expected failures
  Example: `claude mcp remove github 2>/dev/null || true` in install.sh
- SKILL.md guard clauses: explicit "Stop here if..." prose
  Example: "If no argument is provided, ask the user for the change name before proceeding."
- Sub-agent return contracts: `status: ok|warning|blocked|failed` with structured JSON output
  Example from sdd-propose: `{ "status": "ok", "summary": "...", "artifacts": [...], "next_recommended": [...] }`

### Module/layer boundaries
Skills communicate exclusively via file artifacts — no in-memory state passing. Each skill reads its inputs from well-known paths and writes its outputs to well-known paths. The orchestrator (sdd-ff, sdd-new) delegates to executor skills via Task tool; executor skills never delegate further. Reference detected via cross-skill artifact table in ai-context/architecture.md.

---

## Architecture Drift

Basis for comparison: ai-context/architecture.md exists (last updated: 2026-03-03)

### Documented vs Observed

| Documented (architecture.md) | Observed in repo | Status |
|------------------------------|------------------|--------|
| `claude-config/` → `~/.claude/` two-layer architecture | install.sh + ~/.claude/ runtime confirmed | match |
| `skills/` — skill catalog directory | 47 skill directories under skills/ | match |
| `hooks/` — Claude Code event hooks | hooks/smart-commit-context.js present | match |
| `openspec/` — SDD artifacts for this repo | openspec/config.yaml + changes/ + specs/ present | match |
| `ai-context/` — memory layer (8 files) | ai-context/ with 8 files + features/ sub-dir | match |
| `docs/adr/` — Architecture Decision Records | 16 ADRs + README.md present | match |
| `docs/templates/` — prd-template, adr-template | both template files present | match |
| `memory/` — Claude auto-memory | memory/ directory present | match |
| Skill count: ~44 (per stack.md) | 47 skill directories observed | minor drift |
| `ai-context/` — 5 core files documented in stack.md | 8 files observed (3 additional: onboarding.md, quick-reference.md, scenarios.md) | minor drift |

### Drift Summary

minor (2 informational entries)

Drift entries:
- Skill count: stack.md documents ~44 skills; 47 are now present (natural catalog growth — `config-export`, `feature-domain-expert`, and one additional skill added since last count)
  - Documented: ~44 skill directories
  - Observed: 47 skill directories

- ai-context/ file count: stack.md lists 5 core files; 8 files are present
  - Documented: stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md
  - Observed: the above 5 + onboarding.md, quick-reference.md, scenarios.md (documented in architecture.md artifact table as valid additions; stack.md count is outdated)

Both drift entries are count-lag issues from organic catalog growth, not structural mismatches.

---

## ai-context/ Update Log

Files modified:
- `ai-context/stack.md` — updated section: `stack-detection` (skill count updated to 47; .js extension noted)
- `ai-context/architecture.md` — updated sections: `structure-mapping` (47 skills, 3 active changes, ai-context/features/ noted), `drift-summary` (minor, 2 entries)
- `ai-context/conventions.md` — updated section: `observed-conventions` (sample updated to reflect current 20-file sample)

Human-edited sections preserved:
- `ai-context/stack.md` → "What this project is", "File types", "Directory structure", "Skill categories", "Workflows" sections left untouched
- `ai-context/architecture.md` → "System role", "Two-layer architecture", "Skill architecture", "Skill format type system", "SDD meta-cycle", "Communication between skills via artifacts", "Key architectural decisions", "claude-folder-audit: Check Inventory (project mode)" sections left untouched
- `ai-context/conventions.md` → "Language", "Naming conventions", "SKILL.md structure", "Orchestrator skills", "Git conventions", "SDD workflow for this repo", "PRD Convention", "ADR Convention", "Workflows" sections left untouched

---

## Skills Relevance Analysis

### Skills Catalog Table

| Skill | Format | Category | SDD Integration | Notes |
|-------|--------|----------|-----------------|-------|
| `sdd-ff` | procedural | Core SDD (orchestrator) | Wired — primary user entry point for SDD; invoked by `/sdd-ff`; referenced in CLAUDE.md routing table and Skills Registry | Launches propose → spec+design (parallel) → tasks via Task tool delegation; no user gates |
| `sdd-new` | procedural | Core SDD (orchestrator) | Wired — full-cycle entry point; invoked by `/sdd-new`; referenced in CLAUDE.md routing table and Skills Registry | Same as sdd-ff plus optional explore + two user confirmation gates |
| `sdd-explore` | procedural | Core SDD (phase) | Wired — optional first phase of SDD DAG; invoked by sdd-new or directly via `/sdd-explore` | Pure research, no file writes; called by sdd-new Step 1 |
| `sdd-propose` | procedural | Core SDD (phase) | Wired — mandatory Phase 1; invoked by sdd-ff Step 1, sdd-new Step 2; produces proposal.md (consumed by sdd-spec + sdd-design) | Auto-creates prd.md shell when template exists |
| `sdd-spec` | procedural | Core SDD (phase) | Wired — mandatory Phase 2 (parallel with sdd-design); invoked by sdd-ff Step 2, sdd-new; reads proposal.md; produces specs/ | Also reads ai-context/features/ for domain context |
| `sdd-design` | procedural | Core SDD (phase) | Wired — mandatory Phase 2 (parallel with sdd-spec); invoked by sdd-ff Step 2, sdd-new; reads proposal.md; produces design.md | Auto-creates ADR in docs/adr/ when keyword-significant decision detected |
| `sdd-tasks` | procedural | Core SDD (phase) | Wired — mandatory Phase 3; invoked by sdd-ff Step 3, sdd-new; requires both spec + design complete; produces tasks.md | Input for sdd-apply |
| `sdd-apply` | procedural | Core SDD (phase) | Wired — implementation phase; invoked by `/sdd-apply`; reads tasks.md + specs + design | Marks task progress in tasks.md; TDD-aware |
| `sdd-verify` | procedural | Core SDD (phase) | Wired — quality gate; invoked by `/sdd-verify`; reads all change artifacts; produces verify-report.md | Recommended but non-blocking for archive |
| `sdd-archive` | procedural | Core SDD (phase) | Wired — final phase; invoked by `/sdd-archive`; moves change folder to archive/; auto-invokes memory-update inline | Irreversible; requires at least one [x] in verify-report.md |
| `sdd-status` | procedural | Core SDD (utility) | Wired — referenced in CLAUDE.md; invoked by `/sdd-status`; inspects openspec/changes/ on disk | Filesystem-only reader; no git inspection |
| `project-setup` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/project-setup` | Deploys SDD + ai-context/ scaffold to a new project |
| `project-onboard` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/project-onboard` | Priority-order waterfall across 6 onboarding cases; also triggered by sdd-archive Check 4 |
| `project-audit` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/project-audit`; consumes analysis-report.md (D7) | Produces audit-report.md consumed by project-fix; 13 audit dimensions |
| `project-analyze` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/project-analyze`; also invoked internally by project-audit Phase A | Produces analysis-report.md; updates ai-context/ [auto-updated] sections |
| `project-fix` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/project-fix`; reads audit-report.md as spec | Implements all required_actions from audit; 5 correction phases |
| `project-update` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/project-update` | Migrates project Claude config to current user-level state; scans for stale user docs |
| `memory-init` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/memory-init` | Creates all 5 ai-context/ files from scratch; prerequisite for project-analyze on new projects |
| `memory-update` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/memory-update`; also auto-invoked inline by sdd-archive Step 6 | Updates ai-context/ with session decisions; non-blocking |
| `skill-creator` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table (`/skill-create`) and Skills Registry; invoked by `/skill-create` | Creates new skills (global or project-local); two-tier placement model aware |
| `skill-add` | procedural | Meta-tool | Wired — referenced in CLAUDE.md routing table and Skills Registry; invoked by `/skill-add` | Adds global skill to project CLAUDE.md registry; local copy is default |
| `claude-folder-audit` | procedural | System audit | Wired — referenced in CLAUDE.md Skills Registry under "System Audits"; invoked by `/claude-folder-audit` | Audits ~/.claude/ (global mode) or .claude/ (project mode); standalone, not a D11 extension |
| `config-export` | procedural | Auxiliary | Wired — referenced in CLAUDE.md Skills Registry; invoked by `/config-export`; has active SDD change in progress | Exports CLAUDE.md + ai-context/ to GitHub Copilot, Gemini, Cursor formats; no SDD phase role |
| `feature-domain-expert` | reference | Auxiliary | Wired — referenced in CLAUDE.md Skills Registry; consumed by sdd-propose and sdd-spec Step 0 (reads ai-context/features/*.md) | Guides authoring and consumption of feature-level domain knowledge files |
| `smart-commit` | procedural | Auxiliary | Wired — referenced in CLAUDE.md Skills Registry; triggered by hook (hooks/smart-commit-context.js) or direct invocation | Grouped multi-commit workflow with auto-staging; v1.1; no SDD phase role |
| `claude-code-expert` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry; invoked by trigger; no SDD phase role | Reference for Claude Code configuration, custom skills, hooks, MCP — meta-knowledge for this repo itself |
| `excel-expert` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Enrichment skill for Excel/spreadsheet work; no SDD integration |
| `image-ocr` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Enrichment skill for OCR tasks; no SDD integration |
| `react-19` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Frontend enrichment; no SDD integration |
| `nextjs-15` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Frontend enrichment; no SDD integration |
| `typescript` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Language enrichment; no SDD integration |
| `zustand-5` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Frontend enrichment; no SDD integration |
| `zod-4` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Validation enrichment; no SDD integration |
| `tailwind-4` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Frontend enrichment; no SDD integration |
| `ai-sdk-5` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | AI SDK enrichment; no SDD integration |
| `react-native` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Mobile enrichment; no SDD integration |
| `electron` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Desktop enrichment; no SDD integration |
| `django-drf` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Backend enrichment; no SDD integration |
| `spring-boot-3` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Backend enrichment; no SDD integration |
| `hexagonal-architecture-java` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Architecture enrichment; no SDD integration |
| `java-21` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Language enrichment; no SDD integration |
| `playwright` | procedural | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Testing enrichment; no SDD integration |
| `pytest` | procedural | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Testing enrichment; no SDD integration |
| `github-pr` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Tooling enrichment; no SDD integration |
| `jira-task` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Tooling enrichment; no SDD integration |
| `jira-epic` | reference | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Tooling enrichment; no SDD integration |
| `elixir-antipatterns` | anti-pattern | Technology | Standalone — referenced in CLAUDE.md Skills Registry | Language enrichment (anti-pattern format); no SDD integration |

### Skills Relevance Narrative

**Essential skills for the SDD cycle** form two tight clusters. The first is the SDD phase executor set: `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, and `sdd-archive`. These eight skills implement the complete phase DAG and cannot be removed without breaking the SDD workflow. They are always invoked in sequence (skipping only explore and verify, which are optional or non-blocking). The second essential cluster is the SDD orchestrator pair: `sdd-ff` and `sdd-new`. These are the primary user-facing entry points that drive the phase DAG automatically — without them, users would need to invoke each phase skill individually, which is error-prone.

The meta-tool skills (`project-setup`, `project-onboard`, `project-audit`, `project-analyze`, `project-fix`, `project-update`, `memory-init`, `memory-update`, `skill-creator`, `skill-add`) are not part of the SDD phase DAG but are essential to the broader meta-system: they manage the Claude configuration lifecycle across projects. Of these, `project-audit` and `project-fix` form a tightly coupled pair (audit produces the spec; fix consumes it), and `project-analyze` feeds directly into `project-audit` D7 scoring. The memory skills (`memory-init`, `memory-update`) are prerequisites for any project that uses ai-context/ — they populate the baseline that all SDD phases read. `claude-folder-audit` is correctly positioned as a standalone system-level audit skill, not integrated into project-audit (per ADR-009).

**Peripheral but registry-visible skills** include `config-export` (useful cross-AI export), `feature-domain-expert` (referenced by sdd-propose/sdd-spec Step 0 but not a mandatory step), `smart-commit` (integrated via hook, not via SDD phases), and the entire technology catalog. Technology skills (`react-19`, `nextjs-15`, `typescript`, `zustand-5`, `zod-4`, `tailwind-4`, `ai-sdk-5`, `react-native`, `electron`, `django-drf`, `spring-boot-3`, `hexagonal-architecture-java`, `java-21`, `playwright`, `pytest`, `github-pr`, `jira-task`, `jira-epic`, `elixir-antipatterns`, `claude-code-expert`, `excel-expert`, `image-ocr`) enrich Claude's knowledge when working in those specific technology stacks but do not drive or participate in SDD orchestration. They are correctly catalogued in CLAUDE.md's "Technology Skills" sub-section, clearly distinct from the SDD and meta-tool skills.

**Identified gaps** — given the architecture, two skills are notably absent:
1. A `claude-folder-fix` skill is referenced in ADR-009 and known-issues.md as future work (the auto-fix companion to `claude-folder-audit`). The audit produces a report but no automated remediation path exists beyond manual intervention.
2. A `skill-test` meta-tool is mentioned in known-issues.md as a desired future improvement — no automated test runner exists for individual skills; the only validation is running `/project-audit` against a full test project.

**Orphaned skills** — none detected. Every skill in `skills/` is referenced in CLAUDE.md's Skills Registry. No skill directory was found without a corresponding registry entry. The registry is current as of the latest SDD changes. Note: three active changes (`config-export`, `enhance-claude-folder-audit`, `feature-domain-knowledge-layer`) have SDD artifacts in `openspec/changes/` but their corresponding skills are already present in `skills/` — these represent in-flight enhancement cycles, not new skill creation.
