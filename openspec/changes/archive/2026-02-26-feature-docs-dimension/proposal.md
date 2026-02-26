# Proposal: feature-docs-dimension

Date: 2026-02-26
Status: Draft

## Intent

Add an optional Dimension 10 to `project-audit` that detects and evaluates feature-level documentation coverage, giving teams visibility into which features have docs and which do not — without penalizing projects that have not adopted the convention.

## Motivation

`project-audit` currently audits the Claude/SDD config layer (CLAUDE.md, ai-context/, skills registry, SDD orchestrator) but has no awareness of feature-specific documentation. As projects grow, teams accumulate features without corresponding skill entries or markdown docs, and there is no automated way to detect coverage gaps. Dimension 10 fills this gap by providing an informational coverage table that surfaces undocumented features early — before they become technical debt.

The feature is informational by design: projects with no feature doc convention should not be penalized, but projects that have adopted one (or that have detectable feature structures) should get actionable coverage data.

## Scope

### Included

- A new optional `feature_docs` section in `openspec/config.yaml` to declare convention type, paths, and feature detection config
- A new Dimension 10 block in `project-audit/SKILL.md` covering four checks: coverage, structural quality, code freshness, and skills registry alignment
- Heuristic detection fallback (when `feature_docs` is not configured in config.yaml) that looks for non-SDD skills in `.claude/skills/`, `docs/features/`, `docs/modules/`, and feature-named folders with their own README
- A per-feature coverage table in the audit report showing ✅/⚠️/❌ status per check
- Dimension 10 section in the score table in the report (displayed as N/A — does not affect the 100-point score)
- Update to `openspec/config.yaml` schema documentation (in ai-context/ or inline) to document the new `feature_docs` key

### Excluded (explicitly out of scope)

- Changing the 100-point scoring model — Dimension 10 is informational only; any finding it emits is LOW or INFO severity and carries zero score penalty
- Auto-generating missing feature docs — the dimension only reports, never creates
- Deep static analysis of feature code (e.g., detecting API changes) — code freshness check only verifies whether referenced file paths still exist on disk, not whether function signatures match
- Integration with external documentation systems (Confluence, Notion, etc.)
- Changes to `/project-fix` — fixing feature doc gaps is a human decision; no FIX_MANIFEST entries are generated from D10

## Proposed Approach

### Part 1 — `openspec/config.yaml` extension

A new optional top-level section `feature_docs` is added to the config schema. Example:

```yaml
feature_docs:
  convention: skill          # "skill" | "markdown" | "mixed"
  paths:
    - docs/features/
    - .claude/skills/
  feature_detection:
    strategy: directory      # "directory" | "prefix" | "explicit"
    root: src/features/
    exclude:
      - shared
      - utils
```

When `feature_docs` is absent, Dimension 10 falls back to heuristic detection.

### Part 2 — Dimension 10 in project-audit/SKILL.md

Dimension 10 runs after Dimension 9. It follows this logic:

1. **Detection phase**: If `feature_docs` is configured, use it. Otherwise, run heuristic detection:
   - Non-SDD skills in `.claude/skills/` (skills whose name does not start with `sdd-`, `project-`, `memory-`, `skill-`)
   - Markdown files in `docs/features/` or `docs/modules/` if those directories exist
   - Subdirectories of `src/features/`, `src/modules/`, `app/` that contain their own `README.md`
   - If heuristic finds nothing, emit one INFO line and skip remaining checks

2. **Four checks per detected feature**:
   - **D10-a Coverage**: Does each detected feature have a corresponding doc (skill or markdown file)?
   - **D10-b Structural quality**: If the doc is a SKILL.md, does it have frontmatter + triggers + process + rules sections? If markdown, does it have an H1 title and at least one H2 section?
   - **D10-c Code freshness**: Does the doc reference any file paths that no longer exist on disk? (Scan for inline code paths matching `/src/`, `/lib/`, `/app/` patterns)
   - **D10-d Registry alignment**: Is the feature skill listed in the project's CLAUDE.md Skills Registry?

3. **Output**: A coverage table in the report, one row per feature, with ✅/⚠️/❌ per check column.

4. **Scoring**: Dimension 10 is listed in the score table as `N/A` — it never subtracts from the 100-point total.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-audit/SKILL.md` | Modified — add Dimension 10 block | Medium |
| `openspec/config.yaml` (schema) | Modified — add `feature_docs` section documentation | Low |
| Report format in `project-audit/SKILL.md` | Modified — add D10 section to report template | Low |
| Score table in report template | Modified — add D10 row as N/A | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Heuristic detection produces false positives (flags unrelated dirs as features) | Medium | Low | Heuristic explicitly excludes common non-feature names (`shared`, `utils`, `common`, `lib`); emits INFO not WARNING |
| D10 checks significantly slow down audit on large projects | Low | Medium | Code freshness check uses path string scanning (no filesystem walk per path) — bounded by doc file size, not project size |
| Ambiguity between "skill" and "markdown" convention in mixed projects | Medium | Low | `convention: mixed` is a valid value; D10-b applies the correct structural check based on file extension |
| Users expect D10 findings to be auto-fixed by /project-fix | Low | Medium | FIX_MANIFEST explicitly excludes D10 entries; report notes state this is informational and requires human decision |

## Rollback Plan

Dimension 10 is additive and isolated:
1. Remove the D10 block from `skills/project-audit/SKILL.md` (the section is clearly delimited)
2. Remove the D10 row from the score table in the report template
3. Remove the `feature_docs` section from `openspec/config.yaml` if added
4. Run `install.sh` to redeploy
5. The 100-point score is unaffected — no existing scores change

## Dependencies

- The existing `project-audit/SKILL.md` must be at its current state (Dimensions 1–9 present) before adding D10
- `openspec/config.yaml` schema must be extended before D10 uses it (but D10 works without it via heuristics)
- No external dependencies

## Success Criteria

- [ ] `openspec/config.yaml` accepts a `feature_docs` section without breaking existing audit runs
- [ ] Running `/project-audit` on a project with configured `feature_docs` produces a D10 coverage table in the report
- [ ] Running `/project-audit` on a project without `feature_docs` but with detectable feature structures (e.g., `.claude/skills/` with non-SDD skills) produces a D10 heuristic coverage table
- [ ] Running `/project-audit` on a project with no `feature_docs` and no detectable features emits one INFO line ("No feature docs detected — D10 skipped") and does NOT affect the score
- [ ] A project that previously scored N/100 still scores N/100 after D10 is added (score is not affected)
- [ ] The D10 section appears in `audit-report.md` after the D9 section
- [ ] All four checks (coverage, structural quality, code freshness, registry) are documented in SKILL.md with explicit pass/fail criteria
- [ ] `install.sh` deploys the updated `project-audit/SKILL.md` without errors

## Effort Estimate

Low-Medium (half day): single skill file modification with well-defined logic. The main complexity is specifying the heuristic detection rules precisely enough to be deterministic across different project structures.
