# Audit Report — agent-config

Generated: 2026-03-12 00:00
Score: 94/100
SDD Ready: YES

Project Type: **global-config** (install.sh + sync.sh detected at root → LOCAL_SKILLS_DIR=skills)

---

## FIX_MANIFEST

<!-- This block is consumed by /project-fix — DO NOT modify manually -->

```yaml
score: 94
sdd_ready: true
generated_at: "2026-03-12 00:00"
project_root: "C:/Users/juanp/claude-config"

required_actions:
  critical: []
  high:
    - id: "D8-missing-verify-report-solid-ddd"
      type: update_file
      target: "openspec/changes/archive/2026-03-04-solid-ddd-quality-enforcement/"
      reason: "Archived change is missing verify-report.md — required by SDD compliance rule"
  medium:
    - id: "D4b-playwright-missing-process"
      type: skill_quality_action
      action_type: add_missing_section
      target: "skills/playwright/SKILL.md"
      missing_sections: ["## Process"]
      reason: "Skill declares format: procedural but is missing ## Process section"
    - id: "D4b-pytest-missing-process"
      type: skill_quality_action
      action_type: add_missing_section
      target: "skills/pytest/SKILL.md"
      missing_sections: ["## Process"]
      reason: "Skill declares format: procedural but is missing ## Process section"
    - id: "D12-adr029-not-in-readme-index"
      type: update_file
      target: "docs/adr/README.md"
      reason: "ADR 029 (orchestrator-always-on-intent-classification) is an untracked file not yet in the ADR index table in docs/adr/README.md"
  low:
    - id: "D2-stack-counts-stale"
      type: update_file
      target: "ai-context/stack.md"
      reason: "Manual skill category sub-counts are slightly stale (51 skill directories observed, auto-detected section is accurate)"

missing_global_skills: []

orphaned_changes: []

violations:
  - file: "ai-context/architecture.md"
    line: 203
    rule: "D7-minor-drift"
    severity: "medium"
    detail: "Skill count: stack.md manual section documents outdated sub-counts; 51 observed (natural catalog growth)"
  - file: "ai-context/stack.md"
    line: 54
    rule: "D7-minor-drift"
    severity: "medium"
    detail: "ai-context/ file count: stack.md Skill categories table references '5 core files'; 8 files observed"

skill_quality_actions:
  - id: "D9-playwright-add-missing-section"
    skill_name: "playwright"
    local_path: "skills/playwright/SKILL.md"
    global_counterpart: "~/.claude/skills/playwright/SKILL.md"
    action_type: "add_missing_section"
    disposition: "keep"
    missing_sections: ["## Process"]
    detail: "Declares format: procedural but uses ## Critical Patterns / ## Code Examples instead of ## Process. Consider changing format: to reference."
    severity: "warning"
  - id: "D9-pytest-add-missing-section"
    skill_name: "pytest"
    local_path: "skills/pytest/SKILL.md"
    global_counterpart: "~/.claude/skills/pytest/SKILL.md"
    action_type: "add_missing_section"
    disposition: "keep"
    missing_sections: ["## Process"]
    detail: "Declares format: procedural but uses ## Critical Patterns / ## Code Examples instead of ## Process. Consider changing format: to reference."
    severity: "warning"
```

---

## Executive Summary

`agent-config` is the global-config repo for the Claude Code SDD meta-system. It scores **94/100** — excellent health with SDD fully operational. All 50 skills are on disk and in the registry. All 8 SDD phase skills are globally installed. The memory layer is complete with all 5 required files, substantial content, and no placeholders. The main deductions come from: (1) minor architecture drift captured by a 4-day-old analysis-report.md (D7: 3/5), (2) one archived change missing a verify-report.md (D8: 3/5), and (3) two skills (`playwright`, `pytest`) declaring `format: procedural` but missing the required `## Process` section (D4: 18/20). ADR 029 exists on disk as an untracked file but is not yet listed in the docs/adr/README.md index.

---

## Score: 94/100

| Dimension                               | Points  | Max     | Status |
| --------------------------------------- | ------- | ------- | ------ |
| CLAUDE.md complete and accurate         | 20      | 20      | ✅     |
| Memory initialized                      | 15      | 15      | ✅     |
| Memory with substantial content         | 10      | 10      | ✅     |
| SDD Orchestrator operational            | 20      | 20      | ✅     |
| Skills registry complete and functional | 18      | 20      | ⚠️     |
| Cross-references valid                  | 5       | 5       | ✅     |
| Architecture compliance                 | 3       | 5       | ⚠️     |
| Testing & Verification integrity        | 3       | 5       | ⚠️     |
| Project Skills Quality                  | N/A     | N/A     | ℹ️     |
| Feature Docs Coverage                   | N/A     | N/A     | —      |
| Internal Coherence                      | N/A     | N/A     | ✅     |
| ADR Coverage                            | N/A     | N/A     | ⚠️     |
| Spec Coverage                           | N/A     | N/A     | ✅     |
| **TOTAL**                               | **94**  | **100** |        |

**SDD Readiness**: FULL

- openspec/ exists ✅
- config.yaml valid ✅
- CLAUDE.md mentions /sdd-* (40 references) ✅
- All 8 global SDD phase skills present ✅

---

## Dimension 1 — CLAUDE.md [OK]

| Check | Status | Detail |
| ----- | ------ | ------ |
| Exists root `CLAUDE.md` (global-config repo) | ✅ | Accepted per global-config compatibility policy |
| Has >50 lines | ✅ | 501 lines |
| Stack documented | ✅ | `## Tech Stack` section present |
| Stack vs package.json | ✅ | No package.json — expected for Markdown/YAML/Bash meta-system |
| Has Architecture section | ✅ | `## Architecture` section present |
| Skills registry present | ✅ | Full skills table present |
| Mentions SDD (/sdd-*) | ✅ | 40 /sdd-* references |
| Has Unbreakable Rules | ✅ | `## Unbreakable Rules` section present |
| Has Plan Mode Rules | ✅ | `## Plan Mode Rules` section present |

**Stack Discrepancies:** None — no package.json exists (expected for this meta-system).

**Template path verification:**

| Template path | Exists |
| ------------- | ------ |
| docs/templates/prd-template.md | ✅ |

_`docs/templates/adr-template.md` not explicitly referenced in CLAUDE.md — no finding emitted. File exists on disk._

---

## Dimension 2 — Memory [OK]

| File | Exists | Lines | Content | Coherence |
| ---- | ------ | ----- | ------- | --------- |
| stack.md | ✅ | 98 | ✅ | ✅ |
| architecture.md | ✅ | 211 | ✅ | ✅ |
| conventions.md | ✅ | 208 | ✅ | ✅ |
| known-issues.md | ✅ | 118 | ✅ | ✅ |
| changelog-ai.md | ✅ | >5 | ✅ | N/A |

**Coherence issues detected:** None. All files reference real directories and patterns that exist in the project.

**Placeholder phrase detection:** No placeholder phrases detected.

**stack.md technology count:** Auto-detected section lists Markdown, YAML, Bash, Claude Code SDD meta-system, Node.js (hooks runtime), Git — 6 entries ✅ (minimum: 3).

**User documentation freshness:**

| File | Exists | Last verified | Days old | Status |
| ---- | ------ | ------------- | -------- | ------ |
| ai-context/scenarios.md | ✅ | 2026-02-26 | 14 days | ✅ |
| ai-context/quick-reference.md | ✅ | 2026-02-26 | 14 days | ✅ |

---

## Dimension 3 — SDD Orchestrator [OK]

**Global SDD Skills:**

| Skill | Exists |
| ----- | ------ |
| sdd-explore | ✅ |
| sdd-propose | ✅ |
| sdd-spec | ✅ |
| sdd-design | ✅ |
| sdd-tasks | ✅ |
| sdd-apply | ✅ |
| sdd-verify | ✅ |
| sdd-archive | ✅ |

**openspec/ in project:**

| Check | Status |
| ----- | ------ |
| `openspec/` exists | ✅ |
| `openspec/config.yaml` exists | ✅ |
| Config has `artifact_store.mode: openspec` | ✅ |
| Config has project name and stack | ✅ |

**CLAUDE.md mentions SDD:** ✅ (40 /sdd-* references)

**Orphaned changes:** none

**Hook script existence:** No `hooks` key found in settings.json, .claude/settings.local.json, or settings.local.json — check skipped.

**Active changes — file conflict detection:** Only one active change has design.md (`2026-03-12-orchestrator-always-on`) — fewer than two active changes have design.md → check skipped.

---

## Dimension 4 — Skills [WARNING]

**Skills in registry but not on disk:** `sdd-[PHASE]` appears in CLAUDE.md as a template placeholder in a code block — not a real registry entry, no action required.

**Skills on disk but not in registry:** none (all 50 skills are referenced in CLAUDE.md).

**Skills with insufficient content (<30 lines):** none.

**Structural compliance issues (format-aware check):**

| Skill | Format declared | Issue | Severity |
| ----- | --------------- | ----- | -------- |
| playwright | procedural | Missing `## Process` section (uses `## Critical Patterns` / `## Code Examples` / `## Rules`) | ⚠️ MEDIUM |
| pytest | procedural | Missing `## Process` section (uses `## Critical Patterns` / `## Code Examples` / `## Rules`) | ⚠️ MEDIUM |

_Recommended fix: change `format: procedural` to `format: reference` in both skills' frontmatter — their actual structure (patterns + examples + rules) matches the `reference` format contract._

**D4c — Global tech skills coverage:** This is the global-config repo — all applicable technology skills are in the catalog. No relevant uninstalled global skills detected. Full credit (10/10).

---

## Dimension 6 — Cross-references [OK]

**Broken references:** none

| Reference | Source | Status |
| --------- | ------ | ------ |
| `docs/SKILL-RESOLUTION.md` | CLAUDE.md | ✅ |
| `docs/ORCHESTRATION.md` | CLAUDE.md | ✅ |
| `openspec/agent-execution-contract.md` | CLAUDE.md | ✅ |
| `agents.md` | CLAUDE.md | ✅ |
| `skills/README.md` | CLAUDE.md | ✅ |
| `docs/format-types.md` | architecture.md / conventions.md | ✅ |
| `docs/templates/prd-template.md` | CLAUDE.md | ✅ |
| `docs/templates/adr-template.md` | conventions.md | ✅ |

---

## Dimension 7 — Architecture Compliance [WARNING]

Analysis report found: YES
Last analyzed: 2026-03-08
Report age: 4 days
Architecture drift status: **minor** (2 informational entries)
Staleness penalty: none (4 days ≤ 30 days)
Score: 3/5

**Drift entries:**

| File/Pattern | Expected | Found |
| ------------ | -------- | ----- |
| stack.md skill category sub-counts | Current counts per category | Outdated sub-counts (natural catalog growth since last analysis 2026-03-03) |
| stack.md ai-context/ file count | 5 core files (manual section) | 8 files observed (onboarding.md, quick-reference.md, scenarios.md present but not counted in manual section) |

_Both drift entries are informational. No structural mismatches. All documented architectural layers (skills/, hooks/, openspec/, ai-context/, docs/adr/, docs/templates/, memory/) are present and correctly positioned._

---

## Dimension 8 — Testing & Verification [WARNING]

**openspec/config.yaml has testing block:** ✅
- `minimum_score_to_archive: 75` ✅
- `required_artifacts_per_change` defined ✅
- `verify_report_requirements` defined ✅
- `test_project` documented ✅

**Verify rules are executable:** ✅ (references `/project-audit` and concrete metrics)

**Archived changes without verify-report.md:**
- `2026-03-04-solid-ddd-quality-enforcement` — MISSING verify-report.md ⚠️ HIGH

**Archived changes with empty verify-report.md (without [x]):** none

---

## Dimension 9 — Project Skills Quality [INFO]

**Local skills directory**: skills — 50 skills found

_Global-config circular detection: all 50 skills have counterparts in `~/.claude/skills/` because they are the source deployed by `install.sh`. Disposition = `keep` for all (expected behavior per D9-2 global-config note)._

**Skills with missing structural sections:**
- `playwright`: missing `## Process` (format: procedural)
- `pytest`: missing `## Process` (format: procedural)

**Language violations (INFO):** none

**Stack relevance issues (INFO):** none

---

## Dimension 10 — Feature Docs Coverage [SKIPPED]

No feature directories detected — Dimension 10 skipped.

_Heuristic: all skills use SDD/meta-tool prefixes or are technology catalog entries. No `docs/features/`, `docs/modules/`, or `src/features/` directories found._

---

## Dimension 11 — Internal Coherence [OK]

**Skills scanned**: 50 from `skills/`

No heading-level count inconsistencies, sequence numbering gaps, or frontmatter-body alignment issues detected. CLAUDE.md and sampled SKILL.md files are internally coherent.

**Inconsistencies found**: None — all skills internally coherent.

---

## Dimension 12 — ADR Coverage [WARNING]

**Condition**: CLAUDE.md references `docs/adr/` — YES
**ADR README exists**: ✅
**ADRs scanned**: 29 files (001–029)

All 29 ADR files have a valid `## Status` section. No ADRs are missing the status field.

| ADR | Status field found | Status value | Finding |
| --- | ------------------ | ------------ | ------- |
| 001–028 | ✅ | various (Accepted, Proposed, etc.) | clean |
| 029-orchestrator-always-on-intent-classification.md | ✅ | Accepted | ⚠️ Not yet in docs/adr/README.md index (untracked file) |

_D12 findings are informational only — no score impact._

---

## Dimension 13 — Spec Coverage [OK]

**Condition**: `openspec/specs/` exists and is non-empty — YES
**Domains detected**: 41 domains

All 41 domain directories contain a `spec.md` file. No missing specs detected.

| Domain (sample) | spec.md found | Stale paths | Status |
| --------------- | ------------- | ----------- | ------ |
| adr-system | ✅ | 0 | ✅ |
| sdd-orchestration | ✅ | 0 | ✅ |
| sdd-context-loading | ✅ | 0 | ✅ |
| skill-format-types | ✅ | 0 | ✅ |
| All others (37) | ✅ | 0 | ✅ |

_D13 findings are informational only — no score impact._

---

## Required Actions

### Critical (block SDD):

None.

### High (degrade quality):

1. **Create verify-report.md** for `openspec/changes/archive/2026-03-04-solid-ddd-quality-enforcement/` — this archived change is missing the required verify-report.md. Add the file with at least one `[x]` criterion documenting what was verified. Run `/project-fix` or create manually.

### Medium:

1. **Fix `skills/playwright/SKILL.md`**: Skill declares `format: procedural` but is missing `## Process` section. Recommended fix: change `format:` to `reference` in frontmatter (the actual content structure — Critical Patterns + Code Examples + Rules — matches the `reference` format contract).

2. **Fix `skills/pytest/SKILL.md`**: Same issue — declares `format: procedural` but is missing `## Process`. Change `format:` to `reference`.

3. **Update `docs/adr/README.md` index**: Add row for ADR 029 (`029-orchestrator-always-on-intent-classification.md`, status: Accepted, date: 2026-03-12). This ADR is currently an untracked file not listed in the index.

### Low (optional improvements):

1. Update `ai-context/stack.md` manual skill category sub-counts — slightly stale (51 directories currently under `skills/`). The auto-detected section is accurate; only the hand-written table is stale.

---

_To implement these corrections: run `/project-fix`_
_This report was generated by `/project-audit` — do not modify the FIX_MANIFEST block manually_
