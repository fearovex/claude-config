# AI Changelog — claude-config

> Log of significant changes made with AI assistance. Newest first.

---

## 2026-02-28 — project-fix executed (colon separators + stale references)

**Type**: Config
**Agent**: Claude Opus 4.6
**Score before**: 95/100
**Actions executed**: 0 critical, 0 high, 6 medium, 6 low
**Files modified**:
- `ai-context/stack.md` — Replaced `memory-manager/` with `memory-init/` + `memory-update/` in directory tree; updated Meta-tools count from 6 to 10 with correct skill list
- `ai-context/architecture.md` — Fixed `/sdd:ff` and `/sdd:apply` to `/sdd-ff` and `/sdd-apply` in SDD meta-cycle; replaced `memory-manager` with `memory-init / memory-update` as ai-context producer; updated drift note
- `ai-context/conventions.md` — Fixed `/sdd:ff` and `/sdd:apply` to `/sdd-ff` and `/sdd-apply` in SDD workflow
- `ai-context/known-issues.md` — Fixed `/project:audit` to `/project-audit` and `/skill:test` to `/skill-test`
- `CLAUDE.md` — Changed "9 dimensions" to "10 dimensions" in /project-audit description
- `README.md` — Replaced all colon separators with hyphens (30+ occurrences); replaced `memory-manager` with `memory-init` + `memory-update`; changed "9 dimensions" to "10 dimensions"; removed stale `openclaw-assistant` entry
- `skills/sdd-archive/SKILL.md` — Fixed `/sdd:verify` to `/sdd-verify`, `/memory:update` to `/memory-update`, `memory:update` to `memory-update`
- `skills/project-audit/SKILL.md` — Fixed 7 colon separator occurrences (`/project:fix`, `/project:audit`, `/sdd:new`, `/sdd:ff`, `/sdd:*`, `/skill:add`)
- `skills/project-fix/SKILL.md` — Fixed `/sdd:*` to `/sdd-*` in 2 locations
- `skills/sdd-explore/SKILL.md` — Fixed `/sdd:explore` to `/sdd-explore`

**SDD Readiness**: FULL → FULL
**Notes**: Comprehensive cleanup of legacy colon separator notation and stale memory-manager references after the skill split into memory-init + memory-update.

---

## 2026-02-28 — project-fix executed

**Type**: Config
**Agent**: Claude Opus 4.6
**Score before**: 97/100
**Actions executed**: 0 critical, 0 high, 1 medium
**Files modified**:
- `ai-context/stack.md` — Removed stale `openclaw-assistant` reference from Misc category (skill directory does not exist)

**SDD Readiness**: FULL → FULL
**Notes**: Minimal fix session — only one broken cross-reference to correct.

---

## 2026-02-27 — improve-project-analysis applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files created**:
- `skills/project-analyze/SKILL.md` — new standalone framework-agnostic analysis skill (`/project-analyze`); observes and describes only — never scores, never produces FIX_MANIFEST entries; produces `analysis-report.md` at project root and updates `ai-context/` `[auto-updated]` sections; 6-step process: config read, stack detection (manifest-first + extension fallback), structure mapping, convention sampling, architecture drift detection, write outputs
**Files modified**:
- `skills/project-audit/SKILL.md` — rewrote Dimension 7 (Architecture Compliance): D7 is now a consumer of `analysis-report.md` (produced by `/project-analyze`); framework-agnostic; scoring table: absent=0/5 CRITICAL, no architecture.md=2/5 HIGH, drift=none→5/5, minor→3/5, significant→0/5; staleness warning when `Last analyzed:` > 7 days; D7 violations go in `violations[]` only (not `required_actions`); Phase A extension: added `ANALYSIS_REPORT_EXISTS` and `ANALYSIS_REPORT_DATE` variables to the Phase A Bash script; D7 report output template updated
- `CLAUDE.md` — `/project-analyze` registered in: Available Commands table (Meta-tools section), execution routing table (`~/.claude/skills/project-analyze/SKILL.md`), Skills Registry (Meta-tool Skills subsection)
- `ai-context/architecture.md` — new row added to the "Communication between skills via artifacts" table: `analysis-report.md` (Producer: `project-analyze`, Consumer: `project-audit (D7), user`, Location: project root)
- `openspec/config.yaml` — appended optional `analysis` key comment block documenting `analysis.max_sample_files` (default: 20), `analysis.exclude_dirs` (optional list), `analysis.analysis_targets` (optional explicit override list)

**Decisions made**:
- `project-analyze` is a pure observation skill — no scoring, no FIX_MANIFEST, no severity labels
- `project-audit` D7 does NOT auto-invoke `project-analyze` — treats `analysis-report.md` as external input
- If `analysis-report.md` absent, D7 scores 0/5 with CRITICAL message instructing user to run `/project-analyze` first
- `[auto-updated]` marker strategy uses HTML comment syntax invisible in rendered Markdown — no collision with existing `ai-context/` content
- `project-analyze` NEVER creates `ai-context/` directory — if absent, writes only `analysis-report.md` and instructs user to run `/memory-init`
- Maximum 3 Bash calls per `project-analyze` execution: Steps 1+2 share 1 call, Step 3 = 1 call, Step 4 = 1 call

**Change**: improve-project-analysis | SDD cycle complete

---

## 2026-02-26 — feature-docs-dimension applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `skills/project-audit/SKILL.md` — added Dimension 10 (Feature Docs Coverage): Phase A discovery extension (`FEATURE_DOCS_CONFIG_EXISTS`), config-driven detection from `openspec/config.yaml`, heuristic fallback with three source patterns and exclusion list, four checks (D10-a through D10-d), D10 row in score summary table, D10 section in report template, D10 row in Detailed Scoring table; D10 findings are informational only and do NOT affect the score or appear in FIX_MANIFEST
- `openspec/config.yaml` — appended optional `feature_docs:` top-level section as a fully commented-out schema reference documenting `convention`, `paths`, and `feature_detection` sub-keys with all accepted values; the actual heuristic detection remains operative for this project

**Decisions made**:
- D10 is informational-only (N/A scoring) — no score deduction, no auto-fix by /project-fix
- D10 findings are explicitly excluded from `required_actions` and `skill_quality_actions` in FIX_MANIFEST
- Heuristic detection sources: `src/` subdirs, `docs/features/` dirs, local `.claude/skills/` dirs
- Config-driven detection takes precedence over heuristic when `feature_docs:` key is present in `openspec/config.yaml`
- `feature_docs:` section in `openspec/config.yaml` is commented out for claude-config itself (this repo has no feature subdirectories to audit in that sense)

**Motivation**: Users with feature-rich projects need visibility into which features have supporting documentation. D10 provides a non-blocking coverage audit that surfaced documentation gaps without disrupting the existing score contract.

---

## 2026-02-26 — user-docs-and-onboard-skill applied

**Type**: Feature / Documentation
**Agent**: Claude Sonnet 4.6
**Files created**:
- `ai-context/scenarios.md` — 6-case onboarding guide with symptoms, commands, expected outcomes, failure modes
- `ai-context/quick-reference.md` — compact single-page reference: situation table, SDD flow, command glossary, /sdd-ff vs /sdd-new
- `skills/project-onboard/SKILL.md` — automated project state diagnostic skill (/project-onboard)
**Files modified**:
- `skills/project-audit/SKILL.md` — D2: added freshness sub-checks for scenarios.md and quick-reference.md (LOW severity, no score deduction)
- `skills/sdd-archive/SKILL.md` — Step 1: surfaces user-docs review checkbox; CLOSURE.md template: User Docs Reviewed field; Step 5b: verify-report template checkbox
- `skills/project-update/SKILL.md` — Step 1b: stale-doc scan for all 3 user docs; Step 3: explicit confirmation before regeneration
- `CLAUDE.md` — /project-onboard in Available Commands, routing table, and Skills Registry
- `ai-context/architecture.md` — 3 new artifact table rows

**Decisions made**:
- project-onboard uses strict priority-order waterfall (not heuristic scoring) — deterministic, one case per run
- Check 4 (local skills) is non-blocking — project can be Case 6 and have local skill issues simultaneously
- sdd-archive user-docs checkbox is non-blocking — surfaced, not enforced
- project-update stale-doc regeneration requires explicit user confirmation — never automatic

**Motivation**: Users with multiple external projects need intuitive documentation to understand the correct SDD onboarding flow and know which commands to run in each project state.

---

## 2026-02-26 — enhance-project-audit-skill-review applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `skills/project-audit/SKILL.md` — appended Dimension 9 (Project Skills Quality): 5 sub-checks (skip, duplicate detection, structural completeness, language compliance, stack relevance); D9 section in report template; `skill_quality_actions` in FIX_MANIFEST schema; D9 rows in score and Detailed Scoring tables
- `skills/project-fix/SKILL.md` — appended Phase 5 (D9 Corrections): 4 action handlers (`delete_duplicate`, `add_missing_section`, `flag_irrelevant`, `flag_language`) + `move-to-global` informational message; `skill_quality_actions` added to Step 1 parsing
- `ai-context/architecture.md` — added `onboarding.md` row to artifacts communication table
**Files created**:
- `ai-context/onboarding.md` — canonical 4-step onboarding sequence for external projects

**Decisions made**:
- D9 scoring is N/A (no deduction) in iteration 1 — purely informational
- `skill_quality_actions` is a new top-level FIX_MANIFEST key to avoid collision with `required_actions` severity buckets
- `flag_language` in Phase 5 reports only — does NOT auto-modify files
- `move-to-global` has no automated handler — emits explicit manual promotion workflow
- `onboarding.md` placed in `ai-context/` (not `docs/`, not as a skill) — read-only documentation, not a command

**Motivation**: User has multiple external projects to migrate to SDD. Needed: D9 skill audit, Phase 5 fix handler, and documented onboarding workflow.

---

## 2026-02-26 — add-orchestrator-skills applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files created**:
- `skills/sdd-ff/SKILL.md` — orchestrator: fast-forward SDD cycle (propose → parallel spec+design → tasks)
- `skills/sdd-new/SKILL.md` — orchestrator: full SDD cycle with optional explore + confirmation gates
- `skills/sdd-status/SKILL.md` — status reader: scans openspec/changes/ and renders artifact presence table
- `skills/skill-add/SKILL.md` — skill installer: adds global skills to project CLAUDE.md registry
**Files modified**:
- `CLAUDE.md` — routing table (4 new rows: sdd-ff, sdd-new, sdd-status, skill-add updated); Skills Registry (new SDD Orchestrators subsection + skill-add entry)
- `ai-context/conventions.md` — added Orchestrator skills subsection with Task tool delegation guidance
**Archived**: `openspec/changes/archive/2026-02-26-add-orchestrator-skills/`

**Decisions made**:
- Orchestrator skills (sdd-ff, sdd-new) are self-contained SKILL.md files that use Task tool directly — they do not rely on CLAUDE.md being read at runtime
- skill-add is a separate skill from skill-creator (add existing vs create new)
- sdd-ff has no user gates (fast-forward runs automatically); sdd-new has two confirmation gates (after propose, after spec+design)
- sdd-status is filesystem-only — no git inspection

**Motivation**: `/sdd-ff` returned "Unknown skill: sdd-ff" because CLAUDE.md documentation is insufficient for Claude Code CLI to register commands. Actual SKILL.md files are required.

---

## 2026-02-26 — sync-sh-redesign applied

**Type**: Refactor / Architecture clarity
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `sync.sh` — rewritten: memory/ only. Removed cp for CLAUDE.md/settings.json and sync_dir for skills/hooks/openspec/ai-context. Added missing-dir guard.
- `install.sh` — header comment added documenting direction and scope. No logic changes.
- `ai-context/architecture.md` — per-directory direction diagram + decision #5 rewritten.
- `ai-context/conventions.md` — Workflow A/B model replacing old "sync before commit" instruction.
- `CLAUDE.md` — Tech Stack, Sync discipline, SDD meta-cycle line corrected.

**Decisions made**:
- `sync.sh` scope reduced to `memory/` only — the single directory that Claude Code writes automatically during any session.
- All other dirs (skills, CLAUDE.md, hooks, openspec, ai-context) are repo-authoritative: edit in repo → install.sh → commit.
- Names kept (sync.sh / install.sh) to avoid breaking documentation references.

---

## 2026-02-24 — project-fix round 3

**Type**: Config / Compliance fix
**Agent**: Claude Sonnet 4.6
**Score before**: 97/100
**Actions executed**: 0 critical, 0 high, 3 medium, 1 low
**Files modified**:
- `skills/skill-creator/SKILL.md` — full translation from Spanish to English + command notation fix
- `skills/jira-task/SKILL.md` — translated Spanish headings, rules, template bodies
- `skills/jira-epic/SKILL.md` — translated Spanish headings, template bodies, decomposition section
- `ai-context/stack.md` — Meta-tools count corrected from 5 to 6 (added skill-creator)
**SDD Readiness**: FULL → FULL

---

## 2026-02-24 — project-fix round 2

**Type**: Config / Compliance fix
**Agent**: Claude Sonnet 4.6
**Score before**: 93/100
**Actions executed**: 0 critical, 4 high, 1 medium, 1 low
**Files modified**:
- `skills/memory-manager/SKILL.md` — translated all Spanish to English, fixed command notation
- `skills/project-fix/SKILL.md` — translated all Spanish to English, fixed command notation
- `skills/project-setup/SKILL.md` — translated all Spanish to English, fixed command notation
- `skills/project-update/SKILL.md` — translated all Spanish to English, fixed command notation
- `openspec/config.yaml` — added tasks.md to required_artifacts_per_change
- `ai-context/stack.md` — updated Misc skill count from 3+ to 4, added image-ocr
**SDD Readiness**: FULL → FULL

---

## 2026-02-24 — project-fix executed

**Type**: Config / Compliance fix
**Agent**: Claude Sonnet 4.6
**Score before**: 88/100
**Actions executed**: 1 critical, 2 high, 2 medium
**Files modified**:
- `skills/project-audit/SKILL.md` — translated all Spanish headings to English, fixed command notation
- `skills/sdd-{explore,propose,spec,design,tasks,apply,verify,archive}/SKILL.md` — translated JSON output field names (resumen→summary, artefactos→artifacts, riesgos→risks, desviaciones→deviations)
- `CLAUDE.md` — added image-ocr to Skills Registry
**Files created**:
- `skills/image-ocr/SKILL.md` — synced from ~/.claude/skills/image-ocr/
- `openspec/changes/archive/2026-02-24-add-global-config-exception/` — archived completed change
- `openspec/changes/archive/*/tasks.md` (3 files) — retroactive stubs
**SDD Readiness**: FULL → FULL
**Decisions taken**:
- Command notation standardized: `/project:fix` → `/project-fix` in project-audit/SKILL.md
- `"desviaciones"` also translated in sdd-apply as it was a Spanish JSON key
- Fixes applied to ~/.claude/ directly (sync.sh captures that direction)

---

## 2026-02-23 — Bootstrap SDD infrastructure on claude-config

**Type:** Configuration / Meta
**Agent:** Claude Sonnet 4.6
**SDD cycle:** Applied retroactively (changes were made without prior SDD cycle — documented here as first archive entry)

**What changed:**
- `openspec/config.yaml` — Created: SDD configuration for this repo with English-only rules
- `ai-context/stack.md` — Created: project identity, file types, skill catalog inventory
- `ai-context/architecture.md` — Created: two-layer architecture, skill structure, artifact communication map
- `ai-context/conventions.md` — Created: naming, SKILL.md structure, git workflow, sync rules
- `ai-context/known-issues.md` — Created: rsync on Windows, install.sh directionality, GITHUB_TOKEN dependency
- `ai-context/changelog-ai.md` — Created: this file

**Decisions made:**
- `ai-context/` placed at repo root (not `docs/ai-context/`) since this is not a code project
- `openspec/config.yaml` uses English-only rules — this repo enforces the English standard
- Known issues documented immediately to capture technical debt visible at bootstrap time

---

## 2026-02-23 — Overhaul project-audit, create project-fix

**Type:** Feature
**Agent:** Claude Sonnet 4.6
**Commit:** `680ce20`
**SDD cycle:** NOT applied (retroactive — this was the change that motivated applying SDD to this repo)

**What changed:**
- `skills/project-audit/SKILL.md` — Full rewrite: 4 dimensions → 7 dimensions, added FIX_MANIFEST output, structured audit-report.md artifact
- `skills/project-fix/SKILL.md` — New skill: reads audit-report.md as spec, implements corrections phase by phase
- `CLAUDE.md` — Registered `/project:fix` in meta-tools table and skill routing table

**Why this change was made:**
Audit of the Audiio V3 project revealed that project-audit only checked file existence, not content quality or SDD readiness. The new audit generates a machine-readable report consumed by project-fix, implementing the audit→fix flow as a self-contained SDD meta-cycle.

**Technical debt created:**
- project-audit does not handle projects without package.json (affects claude-config itself)
- Both skills were written without prior SDD artifacts — violates the standard this repo enforces

---

## 2026-02-23 — Initial commit: SDD architecture setup

**Type:** Initial Setup
**Commit:** `4c62733`
**Agent:** Claude Sonnet 4.6 (prior session)

**What changed:**
- Initial CLAUDE.md with SDD orchestrator pattern
- Full SDD phase skill catalog (8 phases)
- Meta-tool skills: project-setup, project-audit, project-update
- Technology skill catalog (~25 skills)
- install.sh + sync.sh scripts
- settings.json with MCP server configuration
