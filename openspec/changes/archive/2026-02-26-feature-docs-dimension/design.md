# Technical Design: feature-docs-dimension

Date: 2026-02-26
Proposal: openspec/changes/feature-docs-dimension/proposal.md

## General Approach

Add a Dimension 10 block to `skills/project-audit/SKILL.md` that detects feature documentation using either config-driven or heuristic discovery, evaluates four checks per detected feature, and outputs a coverage table in the audit report. The implementation is purely additive: it appends a new section to the existing SKILL.md without touching any existing dimension logic, score calculation, or the FIX_MANIFEST schema. The `openspec/config.yaml` schema is extended with an optional `feature_docs` key, documented inline in config.yaml itself.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Placement in SKILL.md | Append D10 as a new `### Dimension 10` block after D9, before the Report Format section | Separate SKILL.md file for D10 | The audit skill is a single-file executor; splitting it would break the Phase A discovery script and the audit mental model. All dimensions live in one file — consistency is required. |
| Detection fallback strategy | Heuristic: non-SDD skills in `.claude/skills/`, then `docs/features/`, `docs/modules/`, then subdirs of `src/features/`, `src/modules/`, `app/` with README.md | Full file-tree walk | Bounded by well-known convention paths; avoids O(n) filesystem scans on large projects. Heuristic is deterministic when exclusion list is followed. |
| Score impact | D10 rows appear in score table as `N/A` — no point allocation, no deduction | Adding D10 to the 100-point pool | Proposal is explicit: informational only. Changing the scoring model would require a separate SDD cycle and migration of all existing audit reports. |
| FIX_MANIFEST exclusion | D10 findings are NOT added to `required_actions` or `skill_quality_actions` | Auto-generating fix entries for missing feature docs | Proposal explicitly excludes this. Feature doc gaps require human judgment about whether to adopt the convention. |
| config.yaml schema extension | Add `feature_docs:` as an optional top-level key with inline YAML comments | New schema file, JSON Schema validation | `config.yaml` is currently free-form YAML with no validator. Adding a documented example block is the established pattern (consistent with how `testing:` and `rules:` are documented). |
| Check D10-c (code freshness) | String scan for path patterns (`/src/`, `/lib/`, `/app/`) in doc files only | Filesystem walk per referenced path | Bounded by doc file size, not project size. No false positives from binary or minified files. |
| Report section placement | After D9, before Required Actions | Before D9 | Maintains dimension number ordering. D9 and D10 are both informational; grouping them at the end keeps scored dimensions together. |

## Data Flow

```
/project-audit invoked
        │
        ▼
Phase A — Bash discovery script (existing)
        │  Adds: FEATURE_DOCS_CONFIG_EXISTS check
        │
        ▼
Dimension 10 — Feature Docs Coverage
        │
        ├─► Read openspec/config.yaml → feature_docs section present?
        │       │
        │       ├─ YES → use configured convention, paths, feature_detection
        │       │
        │       └─ NO  → run heuristic detection:
        │                   1. non-SDD skills in .claude/skills/
        │                   2. markdown files in docs/features/ or docs/modules/
        │                   3. subdirs of src/features/, src/modules/, app/ with README.md
        │                   └─ nothing found? → emit INFO, skip checks
        │
        ├─► For each detected feature: run 4 checks
        │       D10-a: Coverage — does a corresponding doc exist?
        │       D10-b: Structural quality — correct sections present?
        │       D10-c: Code freshness — do referenced paths still exist?
        │       D10-d: Registry alignment — is feature listed in CLAUDE.md Skills Registry?
        │
        └─► Emit coverage table in audit-report.md
                Score table row: D10 → N/A
                NO entries in required_actions
                NO entries in skill_quality_actions
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | Add `### Dimension 10 — Feature Docs Coverage` block between D9 section and Report Format section |
| `skills/project-audit/SKILL.md` | Modify | Add D10 row (`Feature Docs Coverage | N/A | N/A | ✅/ℹ️/—`) to the score table in the Report Format section |
| `skills/project-audit/SKILL.md` | Modify | Add D10 row to the Detailed Scoring table at the bottom |
| `skills/project-audit/SKILL.md` | Modify | Add D10 section template (`## Dimension 10 — Feature Docs Coverage`) to the report format template |
| `skills/project-audit/SKILL.md` | Modify | Extend Phase A discovery script to check `FEATURE_DOCS_CONFIG_EXISTS` |
| `openspec/config.yaml` | Modify | Add `feature_docs:` optional section with inline YAML comment documentation |

## Interfaces and Contracts

### feature_docs config schema (YAML)

```yaml
# Optional. When present, Dimension 10 uses this configuration.
# When absent, D10 falls back to heuristic detection.
feature_docs:
  convention: skill          # "skill" | "markdown" | "mixed"
  paths:
    - docs/features/         # directories to scan for feature docs
    - .claude/skills/
  feature_detection:
    strategy: directory      # "directory" | "prefix" | "explicit"
    root: src/features/      # root directory whose subdirs are treated as features
    exclude:
      - shared               # subdirectory names to ignore
      - utils
      - common
      - lib
```

### D10 heuristic detection algorithm

```
heuristic_sources = []

# Source 1: non-SDD skills in .claude/skills/
if .claude/skills/ exists:
    for each subdirectory name in .claude/skills/:
        if name does NOT start with: sdd-, project-, memory-, skill-:
            add to heuristic_sources as type=skill

# Source 2: markdown files in docs/features/ or docs/modules/
if docs/features/ exists:
    add each *.md file as type=markdown, feature_name = filename without extension
if docs/modules/ exists:
    add each *.md file as type=markdown, feature_name = filename without extension

# Source 3: subdirs of src/features/, src/modules/, app/ with README.md
for each candidate_root in [src/features/, src/modules/, app/]:
    if candidate_root exists:
        for each subdirectory:
            if subdirectory/README.md exists:
                add as type=markdown, feature_name = subdirectory name

if heuristic_sources is empty:
    emit INFO: "No feature docs detected — D10 skipped"
    skip all four checks
    score table row: D10 → N/A (—)
```

### D10 check logic per feature

```
D10-a Coverage:
    if convention=skill:
        PASS if .claude/skills/<feature_name>/SKILL.md exists
        FAIL (⚠️) otherwise
    if convention=markdown:
        PASS if at least one .md file in configured paths references feature_name
        FAIL (⚠️) otherwise
    if convention=mixed:
        PASS if either skill or markdown doc found
        FAIL (⚠️) otherwise

D10-b Structural quality:
    if doc is a SKILL.md:
        PASS if frontmatter (---) present AND triggers defined AND process section AND rules section
        WARN (⚠️) if any of the above missing
    if doc is a .md file (not SKILL.md):
        PASS if has # title (H1) AND at least one ## section (H2)
        WARN (⚠️) if missing either

D10-c Code freshness:
    read the doc file content
    extract all path-like strings matching: /src/[^\s]+|/lib/[^\s]+|/app/[^\s]+
    for each extracted path:
        check if [project_root][path] exists on disk
        if NOT found: flag as stale (⚠️)
    PASS (✅) if no stale paths found or no paths found in doc

D10-d Registry alignment:
    read CLAUDE.md (or .claude/CLAUDE.md)
    check if feature_name appears in the Skills Registry section
    PASS (✅) if found
    INFO (ℹ️) if not found — not a warning because projects may have features
               without skill entries by design
```

### Report section template

```markdown
## Dimension 10 — Feature Docs Coverage [OK|INFO|SKIPPED]

**Detection mode**: [configured | heuristic]
**Features detected**: [N | none — skipped]

| Feature | Coverage (D10-a) | Structure (D10-b) | Freshness (D10-c) | Registry (D10-d) |
|---------|-----------------|-------------------|-------------------|------------------|
| [name] | ✅/⚠️/❌ | ✅/⚠️ | ✅/⚠️ | ✅/ℹ️ |

*Dimension 10 is informational only — findings do NOT affect the score and are NOT auto-fixed by /project-fix.*
```

### Score table row additions

In the existing score table:
```markdown
| Feature Docs Coverage | N/A | N/A | ✅/ℹ️/— |
```

In the Detailed Scoring table:
```markdown
| **Feature Docs Coverage** | Informational only — no score deduction. Detects feature/skill documentation gaps. | N/A |
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual integration | Run `/project-audit` on `claude-config` repo itself — D10 should detect non-SDD skills in `~/.claude/skills/` via heuristic | Manual run |
| Manual integration | Run `/project-audit` on the Audiio V3 test project — verify D10 emits INFO "skipped" if no feature structures detected | Manual run |
| Manual integration | Run `/project-audit` on a project with `feature_docs:` configured in `openspec/config.yaml` — verify D10 uses config, not heuristic | Manual run |
| Regression | Run `/project-audit` on `claude-config` after apply — verify score is identical to pre-apply score | `/project-audit` score comparison |
| Structural | Read the updated `project-audit/SKILL.md` — verify D10 block has all four check definitions with pass/fail criteria | Manual read |

## Migration Plan

No data migration required. All changes are additive:
- The `feature_docs` key in `openspec/config.yaml` is optional — existing configs remain valid.
- The D10 section in SKILL.md is isolated — removing it reverts the change without touching D1–D9.
- The score table additions have no numerical effect on any existing audit report.

## Open Questions

None. All design decisions are covered by the proposal and the existing architecture patterns.
