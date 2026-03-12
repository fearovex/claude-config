# Conventions — agent-config

> Last updated: 2026-02-23

## Language

**ALL content MUST be in English.** This includes:
- SKILL.md files
- config.yaml content
- ai-context/ files
- openspec/ artifacts
- Commit messages
- Comments in scripts

No exceptions. Spanish or any other language is a violation.

## Naming conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Skill directories | kebab-case | `project-audit/`, `sdd-propose/` |
| Skill entry point | UPPER | `SKILL.md` |
| SDD phase skills | `sdd-[phase]` prefix | `sdd-propose`, `sdd-apply` |
| Meta-tool skills | `project-[action]` prefix | `project-audit`, `project-fix` |
| Tech skills | `[tech]-[version]` | `react-19`, `nextjs-15`, `zustand-5` |
| SDD change names | kebab-case descriptive | `improve-project-audit`, `add-wallet-skill` |
| openspec changes | `openspec/changes/[name]/` | `openspec/changes/add-project-fix/` |
| Archived changes | `YYYY-MM-DD-[name]` | `2026-02-23-add-project-fix` |

## SKILL.md structure

Every SKILL.md must declare a `format:` field in its YAML frontmatter and satisfy the section
contract for that format. See `docs/format-types.md` for the full authoritative contract.

```yaml
---
name: skill-name
description: >
  One-line description.
format: procedural   # valid values: procedural | reference | anti-pattern
---
```

**Format-to-required-section mapping:**

| `format:` value | Required main section | `## Process` required? |
|-----------------|----------------------|------------------------|
| `procedural` (or absent) | `## Process` | Yes |
| `reference` | `## Patterns` or `## Examples` | No |
| `anti-pattern` | `## Anti-patterns` | No |

All formats always require `**Triggers**` and `## Rules`.

**General structure (procedural example):**

```markdown
# skill-name

> One-line description of what it does.

**Triggers**: [when to use this skill]

---

## Process

### Step 1 — [step name]
[Instructions]

---

## Rules
[Constraints and invariants — always at the end]
```

**Reference skill example (no ## Process):**

```markdown
# react-19

> React 19 patterns with React Compiler.

**Triggers**: React, react-19, hooks

---

## Patterns

### Pattern 1: Server Components
[explanation + code]

## Rules
[constraints]
```

### Orchestrator skills

Some skills are **orchestrators**: they use the Task tool directly inside the SKILL.md to delegate work to sub-agents. This is the correct pattern for skills that coordinate multiple SDD phases.

| Skill | Type | Uses Task tool |
|-------|------|---------------|
| `sdd-ff` | Orchestrator | Yes — launches propose, spec+design (parallel), tasks sub-agents |
| `sdd-new` | Orchestrator | Yes — same as sdd-ff, plus optional explore + confirmation gates |
| All other skills | Executor | No — each skill does its own work directly |

**When to use Task tool delegation inside a SKILL.md:**
- The skill coordinates multiple independent SDD phases
- Each phase requires a fresh context (long output, separate concern)
- The skill is an entry point that users invoke directly (e.g. `/sdd-ff`)

**When NOT to use Task tool inside a SKILL.md:**
- The skill does its own focused work (reading files, writing output, inspecting filesystem)
- Adding delegation would create unnecessary indirection for a single-step task

Orchestrator skills (sdd-ff, sdd-new) are first-class CLI entry points that replace the ad-hoc CLAUDE.md orchestration pattern. They must be self-sufficient SKILL.md files — they cannot rely on CLAUDE.md being read at runtime.

---

## Git conventions

- Commit messages in English
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- **Workflow A (config changes)**: edit in repo → `bash install.sh` → `git commit`
- **Workflow B (memory capture)**: `bash sync.sh` → `git add memory/` → `git commit`
- Commit after each SDD phase (at minimum after apply and after archive)

## SDD workflow for this repo

**Minimum for any skill change:**
```
/sdd-ff <change-name>   →   user approves   →   /sdd-apply   →   install.sh   →   git commit
```

**Required for breaking changes to orchestrator or SDD phase skills:**
Full cycle: explore → propose → spec + design → tasks → apply → verify → archive

## PRD Convention

A Product Requirements Document (PRD) is an optional upstream artifact that can precede the SDD cycle for user-facing or product-level changes.

- **Optional for purely technical changes** — internal refactors, skill modifications, and infrastructure changes do not require a PRD.
- **Recommended for user-facing or product-level changes** — any change that introduces or alters user-visible behavior, a new feature, or a product decision benefits from a PRD before starting the SDD cycle.
- **PRD precedes `proposal.md` and feeds into it** — the PRD defines the "what and why" from a product perspective; `proposal.md` then captures the "what and how" for the SDD cycle. The PRD does NOT replace `proposal.md`.
- **Template**: `docs/templates/prd-template.md`

## ADR Convention

Architectural Decision Records (ADRs) document significant architectural decisions using the Nygard format.

- **Location**: `docs/adr/NNN-short-title.md` — zero-padded three-digit sequential number, lowercase kebab-case title
- **Template**: `docs/templates/adr-template.md` — Nygard format: Title, Status, Context, Decision, Consequences
- **Valid statuses**: Proposed, Accepted, Deprecated, Superseded; retroactive ADRs use `Accepted (retroactive)`
- **Index**: `docs/adr/README.md` must be kept updated with every ADR (number, title, status)
- **Scope**: ADRs capture significant, long-lived architectural choices. They complement `ai-context/architecture.md` (narrative) — they do NOT replace it
- **When to write an ADR**: new skill architecture patterns, changes to install/sync direction, changes to inter-skill communication conventions, or any decision that future sessions would need to understand and respect

## Workflows

### Workflow A — Config changes (skills, CLAUDE.md, hooks, ai-context, openspec)
```
edit in repo → bash install.sh → git commit
```
Use this when you modify any skill, CLAUDE.md, settings.json, hooks/, ai-context/, or openspec/.
`install.sh` deploys the repo to `~/.claude/` so Claude picks up the changes on the next session.
Never run `sync.sh` for these — it will not capture them (by design).

### Workflow B — Memory capture
```
bash sync.sh → git add memory/ && git commit
```
Use this periodically to persist Claude's automatic memory updates (`~/.claude/memory/`) into the repo.
This is the ONLY directory that flows `~/.claude/ → repo/`.

<!-- [auto-updated]: observed-conventions — last run: 2026-03-08 -->
## Conventions Observed (auto-detected)

Sample: 20 files across skills/, ai-context/
Method: auto-detected (SKILL.md files from SDD, meta-tool, and tech skill categories + ai-context/ memory files)
Directories sampled: skills/sdd-ff, skills/sdd-propose, skills/sdd-apply, skills/sdd-archive, skills/project-audit, skills/project-fix, skills/memory-init, skills/react-19, skills/elixir-antipatterns, skills/smart-commit, skills/config-export, skills/claude-folder-audit, skills/feature-domain-expert, ai-context/

### Naming
- Skill directories: kebab-case — e.g. `project-audit`, `sdd-propose`, `react-19`
- Entry point filenames: UPPER_CASE — `SKILL.md` in every skill directory
- Bash functions: snake_case — e.g. `copy_dir` in install.sh
- SDD change names: kebab-case descriptive — e.g. `smart-commit-auto-stage`, `claude-folder-audit-project-mode`
- Archived changes: `YYYY-MM-DD-[name]` — e.g. `2026-03-03-smart-commit-auto-stage`
- Skill prefix conventions: `sdd-[phase]` for SDD phases, `project-[action]` for meta-tools, `memory-[action]` for memory management, `[tech]-[version]` for technology skills

### SKILL.md structure (observed)
All sampled SKILL.md files follow this pattern:
1. YAML frontmatter with `name`, `description`, `format:` (procedural|reference|anti-pattern), optional `license`/`metadata`
2. H1 heading (`# skill-name`)
3. Blockquote description (`> ...`)
4. Bold triggers (`**Triggers**: ...`)
5. Format-specific main section: `## Process` with nested `### Step N` headings (procedural), `## Patterns` or `## Examples` (reference), `## Anti-patterns` (anti-pattern)
6. `## Rules` section last

### Error handling (observed)
- Bash: `set -e` + `|| true` for expected-failures — e.g. `claude mcp remove github 2>/dev/null || true`
- SKILL.md: guard clauses with explicit "Stop here if..." — e.g. "Stop here if argument is missing."
- Sub-agent contracts: `status: ok|warning|blocked|failed` return codes

### Inter-skill communication
File artifacts only — no in-memory passing. Examples: `audit-report.md`, `tasks.md`, `analysis-report.md`.
Skills reference each other by absolute path: `~/.claude/skills/sdd-propose/SKILL.md`.

<!-- [/auto-updated] -->
