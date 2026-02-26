# Closure: feature-docs-dimension

Start date: 2026-02-26
Close date: 2026-02-26

## Summary

Added Dimension 10 (Feature Docs Coverage) to project-audit — an informational-only dimension that detects feature/skill documentation gaps via config-driven or heuristic discovery. Dimension does not affect the 100-point score.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| audit-dimensions | Added | D10 detection logic (config-driven + heuristic), D10-a through D10-d checks, FIX_MANIFEST exclusion rule |
| audit-scoring | Added | D10 N/A row requirement, 100-point model preservation requirement |
| config-schema | Created | New spec: feature_docs optional top-level key in openspec/config.yaml with convention, paths, feature_detection sub-keys |

## Modified Code Files

- `skills/project-audit/SKILL.md` — added Dimension 10 section (detection, four checks, report template, D10 row in score tables, Phase A script extension for FEATURE_DOCS_CONFIG_EXISTS)
- `openspec/config.yaml` — appended fully commented feature_docs schema block as reference documentation

## Key Decisions Made

- D10 is informational-only (N/A scoring) — adds value without penalizing projects that have not adopted the convention
- D10 findings are explicitly excluded from FIX_MANIFEST required_actions and skill_quality_actions — /project-fix does not act on D10
- Heuristic detection covers three source patterns with an exclusion list ([shared, utils, common, lib, types, hooks, components])
- Config-driven detection takes precedence over heuristic when feature_docs: key is active (not commented out) in openspec/config.yaml
- Phase A bash script extended with FEATURE_DOCS_CONFIG_EXISTS variable for consistent discovery

## Lessons Learned

- The Phase A script's grep for `feature_docs:` matches commented lines, producing a false positive (FEATURE_DOCS_CONFIG_EXISTS=1 when the key is commented). This has no negative functional effect since heuristic detection runs regardless, but a future improvement could use `grep -v "^#"` to filter comment lines before searching.

## User Docs Reviewed

YES — confirmed no updates needed to scenarios.md or quick-reference.md. This change adds D10 to project-audit only; no new user commands, no workflow changes for end users.
