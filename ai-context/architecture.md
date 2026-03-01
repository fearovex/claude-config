# Architecture — claude-config

> Last updated: 2026-02-23

## System role

`claude-config` is the global brain of Claude Code. It defines:
1. **How Claude orchestrates** — the SDD workflow, delegation patterns, phase DAG
2. **What Claude knows** — skill catalog covering SDD phases, meta-tools, tech stacks
3. **How projects are managed** — setup, audit, fix, update lifecycle

## Two-layer architecture

```
claude-config (repo)          ~/.claude/ (runtime)
      │                              │
      ├── CLAUDE.md    ──install──►  ├── CLAUDE.md       ← Claude reads at session start
      ├── skills/      ──install──►  ├── skills/          ← Claude reads on demand
      ├── settings.json ─install──►  ├── settings.json    ← Claude Code config
      ├── hooks/       ──install──►  ├── hooks/           ← Event hooks
      ├── openspec/    ──install──►  ├── openspec/        ← SDD artifacts
      ├── ai-context/  ──install──►  ├── ai-context/      ← Project memory
      └── memory/      ──install──►  └── memory/          ← User memory snapshot
                            ◄──sync────  (memory/ only — Claude writes here during sessions)
```

- `install.sh` : repo/ → ~/.claude/  (all directories — the deploy operation)
- `sync.sh`    : ~/.claude/memory/ → repo/memory/  (memory only — periodic capture)

## Skill architecture

Every skill is a directory with a `SKILL.md` entry point:

```
skills/
└── skill-name/
    └── SKILL.md       # Instructions Claude reads and executes
```

A SKILL.md must contain:
- **Trigger definition** — when to use this skill
- **Process** — step-by-step instructions Claude follows
- **Rules** — constraints and invariants
- **Output format** — what the skill produces

## SDD meta-cycle (applied to this repo itself)

Any change to a skill or the global CLAUDE.md must go through:

```
/sdd-ff <change-name>   →   review   →   /sdd-apply   →   install.sh + git commit
```

Fast-forward is the minimum cycle. For breaking changes to core skills (orchestrator, SDD phases), full cycle is required.

## Communication between skills via artifacts

Skills that need to pass state to each other use **file artifacts**:

| Artifact | Producer | Consumer | Location |
|----------|---------|---------|----------|
| `audit-report.md` | project-audit | project-fix | `.claude/audit-report.md` in project |
| `analysis-report.md` | project-analyze | project-audit (D7), user | project root |
| `openspec/config.yaml` | project-setup / project-fix | all SDD phases | `openspec/` in project — also contains the optional `feature_docs:` top-level key (config-driven detection source for D10); when absent, project-audit falls back to heuristic detection |
| `openspec/changes/*/proposal.md` | sdd-propose | sdd-spec, sdd-design | `openspec/changes/<name>/` |
| `openspec/changes/*/tasks.md` | sdd-tasks | sdd-apply | `openspec/changes/<name>/` |
| `ai-context/*.md` | memory-init / memory-update / project-fix | all skills | `ai-context/` in project |
| `ai-context/onboarding.md` | (human / project-fix) | humans / new project sessions | `ai-context/` in project — canonical external project onboarding sequence |
| `ai-context/scenarios.md` | (human / project-onboard) | humans / new project sessions | `ai-context/` in project — 6-case onboarding guide, case-based entry point for users at different project states |
| `ai-context/quick-reference.md` | (human) | humans | `ai-context/` in project — single-page SDD quick reference: situation table, command glossary, flow diagram |
| `skills/project-onboard/SKILL.md` | SDD cycle | Claude at session start / on demand | `~/.claude/skills/project-onboard/` — automated project state diagnostic, triggered by `/project-onboard` |
| `~/.claude/skills/memory-update/SKILL.md` | (read by sdd-archive Step 6) | sdd-archive sub-agent | `~/.claude/skills/memory-update/` — auto-invoked inline by sdd-archive after successful archive; non-blocking (archive success is independent of memory-update outcome) |
| `docs/templates/prd-template.md` | proposal-prd-and-adr-system SDD cycle | humans / Claude sessions starting product-level changes | `docs/templates/` — optional PRD template; feeds into `proposal.md`, not a replacement |
| `docs/templates/adr-template.md` | proposal-prd-and-adr-system SDD cycle | humans adding new ADRs | `docs/templates/` — Nygard format ADR template |
| `docs/adr/README.md` + `docs/adr/NNN-*.md` | proposal-prd-and-adr-system SDD cycle | humans / Claude sessions making architectural decisions | `docs/adr/` — ADR index + individual decision records; must be updated when new ADRs are added |

## Key architectural decisions

1. **Skills are directories, not files** — allows co-locating templates, examples, or sub-skills
2. **SKILL.md is the convention** — every skill directory has exactly one entry point named `SKILL.md`
3. **Artifacts over in-memory state** — skills communicate via files, never via conversation context alone
4. **Orchestrator delegates everything** — the global CLAUDE.md never executes work itself, always spawns subagents via Task tool
5. **install.sh is repo-authoritative** — all directories flow repo → ~/.claude/. The only reverse direction is `sync.sh`, which captures `memory/` only. Every other directory (skills/, CLAUDE.md, hooks/, openspec/, ai-context/) must always be edited in the repo — never in ~/.claude/ directly.

<!-- [auto-updated]: structure-mapping — last run: 2026-02-28 -->
## Observed Structure (auto-detected)

Organization pattern: **feature-based** (confidence: high)
Each `skills/` subdirectory is a distinct capability with one `SKILL.md` entry point.

```
claude-config/ (observed 2026-02-28)
├── CLAUDE.md, README.md, settings.json, settings.local.json
├── install.sh, sync.sh
├── skills/          43 skill directories (see stack-detection for full list)
│   ├── sdd-*/       11 SDD phase/orchestrator skills
│   ├── project-*/   6 meta-tool skills
│   └── [others]     26 skills (tech catalog, tooling, memory, skill mgmt)
├── hooks/           smart-commit-context.js
├── openspec/        config.yaml + changes/ + specs/ (7 subdirs)
├── ai-context/      8 files: stack, architecture, conventions, known-issues,
│                    changelog-ai, onboarding, quick-reference, scenarios
└── memory/          MEMORY.md + topic files
```

<!-- [/auto-updated] -->

<!-- [auto-updated]: drift-summary — last run: 2026-02-28 -->
## Architecture Drift (auto-detected)

Drift level: **minor** (5 informational entries)

Summary of drift vs. `architecture.md` + `stack.md` (baseline: 2026-02-23):
- `openclaw-assistant` listed in stack.md Misc category but skill directory not found
- Skill count: documented ~35–37, observed 43 (natural growth)
- `openspec/specs/` directory (7 subdirs) exists but not in stack.md directory tree
- `README.md` at root not mentioned in documented structure
- Command separator inconsistency: conventions.md previously used `/sdd:ff` (colon) — fixed to `/sdd-ff` (hyphen)

All drift is informational. No structural mismatches detected.

<!-- [/auto-updated] -->
