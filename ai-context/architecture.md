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
| `openspec/changes/*/prd.md` | sdd-propose (Step 5, optional) | humans / product-level change authors | `openspec/changes/<name>/` — auto-created shell when `docs/templates/prd-template.md` exists and no `prd.md` is present; idempotent (never overwrites existing file); non-blocking if template absent |
| `docs/adr/NNN-<slug>.md` | sdd-design (Step 5, optional) | humans / architecture reviewers | `docs/adr/` — auto-created when Technical Decisions table in `design.md` contains a keyword-significant architectural decision; numbering via filesystem count; non-blocking if template or README.md absent |
| `docs/adr/` (D12 — ADR Coverage) | N/A (human-maintained) | project-audit (D12) | `docs/adr/` — informational audit dimension; no score impact. Checks `README.md` existence (HIGH finding if absent) and each `docs/adr/NNN-*.md` for a `## Status` section (MEDIUM finding per ADR missing Status). Activated only when CLAUDE.md references `docs/adr/`; skipped with "N/A" when no reference found. Findings placed in `required_actions` and are actionable by `/project-fix`. |
| `openspec/specs/` (D13 — Spec Coverage) | sdd-spec | project-audit (D13) | `openspec/specs/` — informational audit dimension; no score impact. Activated when `openspec/specs/` exists and is non-empty. Checks each domain directory for a `spec.md` (MEDIUM finding per missing file) and scans referenced paths in each spec for existence (INFO finding per stale path, added to `violations[]` only). Skipped with "N/A" when directory is absent or empty. Findings placed in `required_actions` and are actionable by `/project-fix`. |

## Key architectural decisions

1. **Skills are directories, not files** — allows co-locating templates, examples, or sub-skills
2. **SKILL.md is the convention** — every skill directory has exactly one entry point named `SKILL.md`
3. **Artifacts over in-memory state** — skills communicate via files, never via conversation context alone
4. **Orchestrator delegates everything** — the global CLAUDE.md never executes work itself, always spawns subagents via Task tool
5. **install.sh is repo-authoritative** — all directories flow repo → ~/.claude/. The only reverse direction is `sync.sh`, which captures `memory/` only. Every other directory (skills/, CLAUDE.md, hooks/, openspec/, ai-context/) must always be edited in the repo — never in ~/.claude/ directly.

<!-- [auto-updated]: structure-mapping — last run: 2026-03-01 -->
## Observed Structure (auto-detected)

Organization pattern: **feature-based** (confidence: high)
Each `skills/` subdirectory is a distinct capability with one `SKILL.md` entry point.

```
claude-config/ (observed 2026-03-01)
├── CLAUDE.md, README.md, settings.json, install.sh, sync.sh
├── skills/          44 skill directories (see stack-detection for full list)
│   ├── sdd-*/       SDD phase/orchestrator skills
│   ├── project-*/   6 meta-tool skills
│   ├── memory-*/    2 memory management skills
│   ├── skill-*/     2 skill management skills
│   └── [others]     tech catalog + smart-commit
├── hooks/           smart-commit-context.js
├── openspec/        config.yaml + changes/ + specs/
├── ai-context/      8 files: stack, architecture, conventions, known-issues,
│                    changelog-ai, onboarding, quick-reference, scenarios
├── docs/            adr/ (6 ADRs) + templates/ (prd, adr)
└── memory/          MEMORY.md + topic files
```

<!-- [/auto-updated] -->

<!-- [auto-updated]: drift-summary — last run: 2026-03-01 -->
## Architecture Drift (auto-detected)

Drift level: **minor** (2 informational entries)

Summary of drift vs. `architecture.md` baseline (2026-02-23):
- Skill count: documented ~35 in stack.md manual section, 44 observed (natural catalog growth)
- `.claude/` local directory at repo root (audit artifact) — not in documented structure; expected, not committed

All drift is informational. No structural mismatches detected. Previous drift items from 2026-02-28 (openclaw-assistant reference, command separator inconsistency, openspec/specs/ omission) appear resolved or no longer applicable.

<!-- [/auto-updated] -->
