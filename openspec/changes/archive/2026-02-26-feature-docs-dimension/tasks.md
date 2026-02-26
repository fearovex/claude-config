# Task Plan: feature-docs-dimension

Date: 2026-02-26
Design: openspec/changes/feature-docs-dimension/design.md

## Progress: 8/8 tasks

---

## Phase 1: config.yaml Schema Extension

- [x] 1.1 Modify `openspec/config.yaml` — append a `feature_docs:` top-level optional section (with full inline YAML comment documentation covering `convention`, `paths`, and `feature_detection` sub-keys and accepted values) as shown in the design's Interfaces and Contracts section ✓

---

## Phase 2: project-audit SKILL.md — D10 Logic Block

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — insert `### Dimension 10 — Feature Docs Coverage` section between the Dimension 9 section and the `## Report Format` section; the new section MUST include: the skip condition when no features are detected, the Phase A discovery extension for `FEATURE_DOCS_CONFIG_EXISTS`, config-driven detection (reads `feature_docs` from `openspec/config.yaml`), heuristic detection fallback with all three sources and the exclusion list (`shared`, `utils`, `common`, `lib`), and the four check definitions (D10-a through D10-d) each with explicit pass/fail criteria as specified in the design ✓

- [x] 2.2 Modify `skills/project-audit/SKILL.md` — extend the Phase A discovery bash script to emit the variable `FEATURE_DOCS_CONFIG_EXISTS` (1 if `openspec/config.yaml` contains a `feature_docs:` key, 0 otherwise) and add `FEATURE_DOCS_CONFIG_EXISTS` to the output key schema documentation ✓

---

## Phase 3: project-audit SKILL.md — Report Format Updates

- [x] 3.1 Modify `skills/project-audit/SKILL.md` — add a D10 row to the score summary table inside the `## Report Format` block, immediately before the `| **TOTAL** |` row, with the format: `| Feature Docs Coverage | N/A | N/A | ✅/ℹ️/— |` ✓

- [x] 3.2 Modify `skills/project-audit/SKILL.md` — insert a `## Dimension 10 — Feature Docs Coverage [OK|INFO|SKIPPED]` report section template into the `## Report Format` block, positioned after the `## Dimension 9` template section and before `## Required Actions`; the template MUST use the format defined in the design's Report section template (detection mode, features detected, coverage table with D10-a through D10-d columns, and the informational note stating D10 findings do NOT affect the score and are NOT auto-fixed by /project-fix) ✓

- [x] 3.3 Modify `skills/project-audit/SKILL.md` — add a `| **Feature Docs Coverage** |` row to the `## Detailed Scoring` table at the bottom of the file, with the description "Informational only — no score deduction. Detects feature/skill documentation gaps." and value "N/A" in the Max Points column; verify the TOTAL row still shows 100 ✓

---

## Phase 4: Cleanup and Memory Update

- [x] 4.1 Update `ai-context/changelog-ai.md` — add an entry for this change documenting that Dimension 10 (Feature Docs Coverage) was added to `project-audit/SKILL.md` and that `openspec/config.yaml` was extended with the optional `feature_docs` schema ✓

- [x] 4.2 Update `ai-context/architecture.md` — add a brief note about the `feature_docs` optional config key in `openspec/config.yaml` and its role as the configuration source for D10 feature detection ✓

---

## Implementation Notes

- Tasks 2.1 and 2.2 MUST be done together since they both modify `skills/project-audit/SKILL.md` — coordinate them in a single apply sub-agent pass to avoid overlapping edits
- The D10 block in SKILL.md is strictly additive: tasks 2.1, 3.1, 3.2, and 3.3 all modify the same file; apply them in order (2.1 → 2.2 → 3.1 → 3.2 → 3.3) in a single sub-agent pass to maintain file consistency
- Do NOT alter any D1–D9 logic, point allocations, or the FIX_MANIFEST schema when implementing tasks 3.1–3.3
- The `feature_docs` section in `openspec/config.yaml` (task 1.1) is for documentation of the schema only — for this project (claude-config) the section should be commented out or marked as an example since claude-config itself does not have feature subdirectories to audit in that sense; leave the actual heuristic detection as the operative mode
- D10 findings MUST NOT appear in `required_actions` or `skill_quality_actions` in the FIX_MANIFEST — document this exclusion explicitly in the D10 block (task 2.1)

## Blockers

None.
