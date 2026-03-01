# Task Plan: audit-improvements

Date: 2026-03-01
Design: openspec/changes/audit-improvements/design.md

## Progress: 18/18 tasks

---

## Phase 1: Phase A Script Extension

- [x] 1.1 Modify `skills/project-audit/SKILL.md` — extend the Phase A Bash discovery script block to export five new variables: `ROOT_SETTINGS_JSON_EXISTS`, `DOTCLAUDE_SETTINGS_JSON_EXISTS`, `SETTINGS_LOCAL_JSON_EXISTS`, `ADR_DIR_EXISTS`, `ADR_README_EXISTS`, `OPENSPEC_SPECS_EXISTS` — each using the existing `f` (file) or `d` (directory) helper pattern already present in the script

---

## Phase 2: D1 Enhancement — Template Path Verification

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — in the D1 (CLAUDE.md Quality) section, add a step: read the `Documentation Conventions` section of `CLAUDE.md`, extract any paths matching the pattern `docs/templates/*.md`, then for each path check whether the file exists on disk
- [x] 2.2 Modify `skills/project-audit/SKILL.md` — in D1, add the scoring rule: emit a MEDIUM finding per missing template path ("Template path referenced in CLAUDE.md does not exist on disk: [path]"); add the missing paths to `required_actions.medium` in the FIX_MANIFEST; skip check entirely when no `docs/templates/*.md` pattern is found in CLAUDE.md
- [x] 2.3 Modify `skills/project-audit/SKILL.md` — in D1, add the template path verification output block (markdown table: Template path | Exists) to the D1 section of the generated report format

---

## Phase 3: D2 Enhancement — Placeholder Detection and Version Count

- [x] 3.1 Modify `skills/project-audit/SKILL.md` — in the D2 (Memory Layer) section, add a placeholder phrase scan step: while reading each `ai-context/*.md` file (which the skill already does), check the content for the phrases `[To be filled]`, `TODO`, `[empty]`, `[TBD]`, `[placeholder]`, `[To confirm]`, `[Empty]` (case-insensitive for bracket-enclosed variants)
- [x] 3.2 Modify `skills/project-audit/SKILL.md` — in D2, add the scoring rule: emit a HIGH finding per file that contains a placeholder phrase ("file appears to contain unfilled placeholder content"); treat such a file as functionally empty even if it passes the line-count check; add the finding to `required_actions.high` in the FIX_MANIFEST
- [x] 3.3 Modify `skills/project-audit/SKILL.md` — in D2, add a `stack.md` technology version count step: count lines in `ai-context/stack.md` that contain a version-like string (`x.y`, `x.y.z`, or `vX` patterns); emit a MEDIUM finding if the count is fewer than 3 ("stack.md lists fewer than 3 technologies with concrete versions — minimum is 3"); add to `required_actions.medium`
- [x] 3.4 Modify `skills/project-audit/SKILL.md` — in D2, add the placeholder detection and version count output blocks to the D2 section of the generated report format (two markdown tables as specified in design.md Interfaces section)

---

## Phase 4: D3 Enhancement — Hook Script Existence

- [x] 4.1 Modify `skills/project-audit/SKILL.md` — in the D3 (SDD Compliance) section, add a hook script existence step: if `ROOT_SETTINGS_JSON_EXISTS=1` or `DOTCLAUDE_SETTINGS_JSON_EXISTS=1`, read the corresponding `settings.json`; if `SETTINGS_LOCAL_JSON_EXISTS=1`, read `settings.local.json`; extract all script paths from the `hooks:` object in each file
- [x] 4.2 Modify `skills/project-audit/SKILL.md` — in D3, add the scoring rule: for each extracted hook script path, check whether the file exists on disk; emit a HIGH finding per missing script ("Hook script referenced in [file] not found on disk: [path]"); add to `required_actions.high` in the FIX_MANIFEST; emit no finding when no `hooks` key is present
- [x] 4.3 Modify `skills/project-audit/SKILL.md` — in D3, add the hook script existence output block to the D3 section of the generated report format (markdown table: Hook event | Script path | Exists)

---

## Phase 5: D3 Enhancement — Active Changes Conflict Detection

- [x] 5.1 Modify `skills/project-audit/SKILL.md` — in D3, add a conflict detection step: list all non-archived changes (directories in `openspec/changes/` that are not under `archive/`) that have a `design.md`; for each such `design.md`, read the File Change Matrix section and extract the file paths listed in the `File` column; normalize each path (lowercase + strip leading `./`)
- [x] 5.2 Modify `skills/project-audit/SKILL.md` — in D3, add the scoring rule: compute the set intersection of extracted file paths across all active changes; for each overlapping path, emit a MEDIUM finding ("Concurrent file modification conflict detected: [path] is targeted by both [change-A] and [change-B]"); add to `violations[]` in the FIX_MANIFEST (not `required_actions`); skip the entire step when fewer than two active changes have a `design.md`
- [x] 5.3 Modify `skills/project-audit/SKILL.md` — in D3, add the conflict detection output block to the D3 section of the generated report format (markdown table: File | Change A | Change B, or "No conflicts detected")

---

## Phase 6: D7 Enhancement — Staleness Score Impact

- [x] 6.1 Modify `skills/project-audit/SKILL.md` — in the D7 (Architecture) scoring section, add the staleness penalty logic: if `ANALYSIS_REPORT_EXISTS=1` AND the `Last analyzed:` date in `analysis-report.md` is 31–60 days before the current audit date, deduct 1 point from the drift-based D7 score (floor: 0); if the date is more than 60 days old, deduct 2 points (floor: 0); no penalty when the file is absent or 30 days old or fresher
- [x] 6.2 Modify `skills/project-audit/SKILL.md` — in D7, update the scoring table/rubric to document both staleness tiers (31–60 days: −1 pt; > 60 days: −2 pts) and the note "staleness penalty stacks with drift penalty; floor is 0"; ensure the Max Points for D7 remains 5 and the TOTAL row still sums to 100; add a staleness explanation line to the D7 output block in the report format

---

## Phase 7: D12 — ADR Coverage (New Dimension)

- [x] 7.1 Modify `skills/project-audit/SKILL.md` — append a new Dimension 12 (ADR Coverage) section after D11: add the activation condition (CLAUDE.md contains `docs/adr/`), the README existence check using `ADR_README_EXISTS`, the per-ADR file `## Status` section scan for each `docs/adr/NNN-*.md` file, and the three finding rules: HIGH for missing README (add to `required_actions.high`), MEDIUM for ADR missing Status field (add to `required_actions.medium`), INFO when directory exists but contains no ADR files; skip entirely with "N/A" message when CLAUDE.md has no `docs/adr/` reference
- [x] 7.2 Modify `skills/project-audit/SKILL.md` — add the D12 score table row ("ADR Coverage" | N/A) to the Detailed Scoring table at the bottom of the skill; ensure the TOTAL row remains 100; add the D12 output block format (as specified in design.md Interfaces section: Condition | ADR README exists | ADRs scanned | per-ADR table)

---

## Phase 8: D13 — Spec Coverage (New Dimension)

- [x] 8.1 Modify `skills/project-audit/SKILL.md` — append a new Dimension 13 (Spec Coverage) section after D12: add the activation condition (`OPENSPEC_SPECS_EXISTS=1` AND directory non-empty), the per-domain spec.md existence check, the per-spec path reference scan (check if referenced paths exist on disk), and the three finding rules: MEDIUM for missing `spec.md` in a domain directory (add to `required_actions.medium`), INFO for a stale path reference in a spec file (add to `violations[]` only); skip entirely with "N/A" message when `openspec/specs/` does not exist or is empty
- [x] 8.2 Modify `skills/project-audit/SKILL.md` — add the D13 score table row ("Spec Coverage" | N/A) to the Detailed Scoring table; ensure TOTAL remains 100; add the D13 output block format (as specified in design.md Interfaces section: Condition | Domains detected | per-domain table)

---

## Phase 9: Memory and Documentation Update

- [x] 9.1 Modify `ai-context/changelog-ai.md` — add a changelog entry for the `audit-improvements` change: date 2026-03-01, summary of the 7 checks added (D1 template, D2 placeholder+version, D3 hook existence+conflict, D7 staleness penalty, D12 ADR Coverage, D13 Spec Coverage)
- [x] 9.2 Modify `ai-context/architecture.md` — document D12 (ADR Coverage) and D13 (Spec Coverage) as new informational audit dimensions in the artifact communication table or the relevant architecture section

---

## Implementation Notes

- All new checks MUST be conditional — projects without the relevant artifacts (docs/adr/, openspec/specs/, hook scripts, template references) must receive N/A or a skip message, never a penalty
- The D7 staleness penalty stacks with the drift penalty; the combined score floor is 0 — never negative
- D12 and D13 are informational (N/A in Max Points column); their HIGH/MEDIUM findings ARE placed in `required_actions` and are actionable by `/project-fix`, but they do NOT reduce the base 100-point score
- For D3 conflict detection: normalize paths with `lowercase + strip leading ./` before computing the intersection; document the limitation that other path format inconsistencies are not caught
- For D2 placeholder detection: the scan is case-insensitive for bracket-enclosed phrases (e.g., `[todo]` and `[TODO]` are both caught)
- Phase A script extension (Task 1.1) must be completed before implementing any dimension that uses the new variables (D3 hooks, D12, D13)
- Tasks 5.1–5.3 (D3 conflict detection) require reading multiple `design.md` files; this does not add extra Bash calls since file reading uses the Read tool

## Blockers

None.
