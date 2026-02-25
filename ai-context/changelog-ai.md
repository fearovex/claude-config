# AI Changelog — claude-config

> Log of significant changes made with AI assistance. Newest first.

---

## 2026-02-25 — coherence-verification apply

**Type**: Feature / Compliance enhancement
**Agent**: Claude Sonnet 4.6
**SDD cycle**: coherence-verification (apply phase)
**Files modified**:
- `skills/skill-creator/SKILL.md` — added Tools/Platforms catalog section with 4 entries (claude-code-expert, excel-expert, openclaw-assistant, image-ocr)
- `skills/memory-manager/SKILL.md` — replaced all `docs/ai-context` references with canonical `ai-context` path
- `skills/project-setup/SKILL.md` — replaced all `docs/ai-context` references with canonical `ai-context` path
- `skills/project-audit/SKILL.md` — added D3e (active change completeness), D3f (archive completeness), D4d (structural section completeness), D4e (language compliance), D4f (skill naming), D4g (skill contents), D4h (orphaned files), D6d (legacy path pattern) sub-checks with FIX_MANIFEST schemas and report templates
**Decisions made**:
- D4e language violations are WARNING severity (non-blocking, no score deduction) as intended by design
- D6d legacy path check applies HIGH severity for SDD/meta-tool skills, MEDIUM for tech skills
- Report format templates added inline to the existing dimension report sections
**Notes**: The tasks.md and design.md for coherence-verification were not found at the expected path; changes were implemented directly from the apply instructions embedded in the sub-agent prompt.

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
