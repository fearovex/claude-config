# AI Changelog — claude-config

> Log of significant changes made with AI assistance. Newest first.

---

### 2026-03-01 — audit-improvements archived

**What was done**: SDD cycle for `audit-improvements` completed and archived. Delta specs merged into master specs for `audit-dimensions` and `audit-scoring`. Change folder moved to `openspec/changes/archive/2026-03-01-audit-improvements/`.
**Modified files**:
- `openspec/specs/audit-dimensions/spec.md` — ADDED sections for D2 placeholder detection, D3 hook script + conflict detection, D7 staleness penalty, D1 template path verification, D12 ADR Coverage, D13 Spec Coverage (7 requirements, 34 scenarios)
- `openspec/specs/audit-scoring/spec.md` — ADDED sections for D7 staleness scoring, D12/D13 informational scoring, non-regression requirement; MODIFIED D7 from informational-only to score-impacting
- `openspec/changes/archive/2026-03-01-audit-improvements/CLOSURE.md` — created
**Decisions made**:
- D12 and D13 are permanently registered in master specs as informational-only dimensions (N/A max points)
- D7 staleness behavior change is a permanent spec modification — it now deducts points, not just warns
**Notes**: All 18 tasks completed, 44 compliance scenarios verified. Live integration test on Audiio V3 recommended before next significant project-audit modification.

---

### 2026-03-01 — audit-improvements applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `skills/project-audit/SKILL.md` — extended with 7 new checks across 5 dimensions and 2 new informational dimensions

**Summary of checks added**:
- **D1 (CLAUDE.md Quality)**: Template path verification — reads `Documentation Conventions` section of CLAUDE.md, extracts `docs/templates/*.md` paths, and emits a MEDIUM finding per missing file on disk
- **D2 (Memory Layer)**: Placeholder phrase detection — scans each `ai-context/*.md` file for unfilled placeholder phrases (`[To be filled]`, `TODO`, `[empty]`, `[TBD]`, `[placeholder]`, `[To confirm]`, `[Empty]`); treats files with placeholders as functionally empty (HIGH finding). Also adds version count check: emits MEDIUM finding if `stack.md` contains fewer than 3 versioned technology lines
- **D3 (SDD Compliance)**: Hook script existence verification (sub-check 3e) — extracts all hook script paths from `settings.json`/`settings.local.json` and emits HIGH finding per missing script on disk. Active changes file conflict detection (sub-check 3f) — extracts File Change Matrix from each active `design.md`, computes path intersection across changes, emits MEDIUM finding per overlapping file path
- **D7 (Architecture)**: Staleness score penalty tiers — if `analysis-report.md` is 31–60 days old, deducts 1 point from D7 score (floor 0); if older than 60 days, deducts 2 points (floor 0); no penalty when file is absent or 30 days old or fresher
- **D12 (ADR Coverage)** — new informational dimension: checks `docs/adr/README.md` existence, scans each `docs/adr/NNN-*.md` for a `## Status` section; HIGH finding for missing README, MEDIUM per ADR missing Status; informational only — no score impact
- **D13 (Spec Coverage)** — new informational dimension: activated when `openspec/specs/` is non-empty; checks each domain directory for a `spec.md`, scans referenced paths for existence; MEDIUM per missing `spec.md`, INFO for stale path references; informational only — no score impact

**Decisions made**:
- All new checks are conditional — projects without the relevant artifacts receive N/A or a skip message, never a penalty
- D7 staleness penalty stacks with the drift penalty; combined floor is 0
- D12 and D13 are informational (N/A in Max Points column); HIGH/MEDIUM findings ARE placed in `required_actions` and are actionable by `/project-fix`, but do not reduce the base 100-point score
- D3 conflict detection normalizes paths with `lowercase + strip leading ./` before computing intersection

**Change**: audit-improvements | SDD cycle complete

---

### 2026-03-01 — sdd-cycle-prd-adr-integration archived

**What was done**: Integrated PRD and ADR as optional auto-generated artifacts into the SDD cycle. `sdd-propose` now auto-creates a `prd.md` shell (idempotent, skips if template absent or file already exists). `sdd-design` now auto-creates an ADR file in `docs/adr/` when a keyword-significant architectural decision is detected in the Technical Decisions table (non-blocking, skips if template or README absent). Both `openspec/config.yaml` and `CLAUDE.md` were updated to document these as optional artifacts.
**Modified files**:
- `skills/sdd-propose/SKILL.md` — added Step 5: PRD shell auto-creation (idempotent, non-blocking)
- `skills/sdd-design/SKILL.md` — added Step 5: ADR auto-creation (keyword heuristic, filesystem numbering, non-blocking)
- `openspec/config.yaml` — added `optional_artifacts` section listing prd.md and docs/adr/NNN-*.md with producing skill annotations
- `CLAUDE.md` — updated SDD Artifact Storage section: prd.md (optional) in change tree; docs/adr/NNN-*.md (optional, sdd-design) in overall tree
- `ai-context/architecture.md` — added two new artifact table rows for prd.md and docs/adr/NNN-*.md auto-generation
**Decisions made**:
- PRD is idempotent and non-blocking: existing `prd.md` is never overwritten; missing template skips silently with a warning
- ADR uses keyword heuristic (cross-cutting concern keywords, patterns absent from `ai-context/architecture.md`) — intentionally fuzzy; future cycles can formalize if needed
- ADR numbering uses filesystem count of `docs/adr/` files to avoid collisions — no global counter state needed
- Both steps return `status: ok` (or `status: warning`) on any failure path — never `status: blocked` or `status: failed`
- Step 5 heading added to `sdd-design` for structural symmetry with `sdd-propose` — accepted deviation, improves readability
**Notes**: Change-name delineation: `proposal-prd-and-adr-system` (previous cycle, 2026-03-01) created the templates and ADR index. This cycle (`sdd-cycle-prd-adr-integration`) wired those templates into the live SDD skill behavior.

---

## 2026-03-01 — proposal-prd-and-adr-system applied

**Type**: Feature / Documentation
**Agent**: Claude Sonnet 4.6
**Files created**:
- `docs/templates/prd-template.md` — PRD template with all 6 required sections (Problem Statement, Target Users, User Stories with MoSCoW tiers, Non-Functional Requirements, Acceptance Criteria, Notes); each section includes placeholder instructions
- `docs/templates/adr-template.md` — ADR template following Nygard format with 4 required sections (Title, Status, Context, Decision, Consequences); includes all valid status values and placeholder instructions
- `docs/adr/README.md` — ADR index with naming convention, numbering scheme, status vocabulary, lifecycle guidance, and table of all 5 ADRs
- `docs/adr/001-skills-as-directories.md` — Retroactive ADR: skills are stored as directories with SKILL.md entry points
- `docs/adr/002-artifacts-over-memory.md` — Retroactive ADR: all inter-skill state passed via named file artifacts, not conversation context
- `docs/adr/003-orchestrator-delegates-everything.md` — Retroactive ADR: CLAUDE.md orchestrator never executes SDD phase work inline; always delegates via Task tool
- `docs/adr/004-install-sh-repo-authoritative.md` — Retroactive ADR: install.sh is the sole authoritative deploy direction (repo → ~/.claude/); sync.sh is memory-only reverse
- `docs/adr/005-skill-md-entry-point-convention.md` — Retroactive ADR: SKILL.md is the mandatory, uniquely-named entry point for every skill directory
**Files modified**:
- `ai-context/conventions.md` — appended "PRD Convention" section explaining PRD is optional for technical changes, recommended for product-level changes, precedes proposal.md, template at docs/templates/prd-template.md
- `CLAUDE.md` — added "Documentation Conventions" subsection in Architecture section referencing docs/adr/README.md and docs/templates/prd-template.md
- `docs/architecture-definition-report.md` — prepended HTML disambiguation comment clarifying "ADR" = Architecture Definition Report, not Architecture Decision Record

**Decisions made**:
- All 5 ADRs use `Accepted (retroactive)` status — decisions predate the ADR system
- ADR content derived exclusively from ai-context/architecture.md — no new architectural claims invented
- PRD is positioned as optional upstream artifact, not a replacement for proposal.md
- docs/templates/ and docs/adr/ directories created as part of this change
- docs/architecture-definition-report.md disambiguation uses HTML comment (invisible in rendered Markdown)

**Change**: proposal-prd-and-adr-system | SDD cycle complete

---

## 2026-02-28 — integrate-memory-into-sdd-cycle archived

**Type**: Feature
**Agent**: Claude Opus 4.6
**Files modified**:
- `skills/sdd-archive/SKILL.md` — Replaced Step 6 (manual "Suggest updating memory") with auto-update: reads `~/.claude/skills/memory-update/SKILL.md` and executes inline with non-blocking error handling; updated Output JSON: `next_recommended` changed from `["memory-update"]` to `[]`, summary includes `Memory: [updated|failed|skipped]`
- `skills/sdd-ff/SKILL.md` — Added informational note in Step 5 summary: archive will auto-update ai-context/
- `skills/sdd-new/SKILL.md` — Added "(auto-updates ai-context/ memory)" to archive entry in Step 6 remaining phases
- `ai-context/architecture.md` — Added memory-update artifact row to communication table

**Specs created**:
- `openspec/specs/sdd-archive-execution/spec.md` — 5 requirements, 11 scenarios covering auto memory-update, non-blocking failure, output format, sdd-ff/sdd-new notes

**Decisions made**:
- Inline execution (not Task tool delegation) — follows convention that only sdd-ff/sdd-new use Task tool
- Step 6 replacement (not Step 7 addition) — keeps step count at 6
- Non-blocking: archive success is always independent of memory-update outcome
- memory-update reads session context naturally — no structured parameter interface needed

**Change**: integrate-memory-into-sdd-cycle | SDD cycle complete

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
