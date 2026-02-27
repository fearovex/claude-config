# Task Plan: improve-project-analysis

Date: 2026-02-27
Design: openspec/changes/improve-project-analysis/design.md

## Progress: 20/20 tasks

---

## Phase 1: New Skill — project-analyze/SKILL.md

- [x] 1.1 Create directory `skills/project-analyze/` and file `skills/project-analyze/SKILL.md` with frontmatter block (`name`, `description`) and the four required sections: Trigger definition, Process (Steps 1–6), Rules, and Output format — content must match the step definitions in `design.md` sections "project-analyze SKILL.md Architecture" and "process steps (6 steps)"

- [x] 1.2 In `skills/project-analyze/SKILL.md` Step 1 (Read config): document that the skill reads `openspec/config.yaml` for `analysis.max_sample_files` (default: 20), `analysis.analysis_targets` (optional override), and `analysis.exclude_dirs` (optional); document that each of these is optional and the skill proceeds with defaults when the key is absent

- [x] 1.3 In `skills/project-analyze/SKILL.md` Step 2 (Stack detection): document the manifest-first detection order (`package.json`, `pyproject.toml`, `requirements.txt`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `mix.exs`, `composer.json`) and the file-extension-sampling fallback when no manifest is found; document that the step must NOT error or produce an empty section

- [x] 1.4 In `skills/project-analyze/SKILL.md` Step 3 (Structure mapping): document the 2-level folder tree read via `find [project_root] -maxdepth 2 -type d`; document the four organization pattern classification rules (feature-based, layer-based, monorepo, flat); document source root and test root detection heuristics

- [x] 1.5 In `skills/project-analyze/SKILL.md` Step 4 (Convention sampling): document the file selection algorithm (up to `max_sample_files`, distributed proportionally across source directories; if `analysis_targets` is set, restrict to those paths); document the four observations: file naming, function/class naming, import style, error handling patterns; document that the Conventions section in `analysis-report.md` MUST state the sample size and which directories were sampled; document the 20-file ceiling and the even-across-directories-by-recency sampling strategy for large repos

- [x] 1.6 In `skills/project-analyze/SKILL.md` Step 5 (Architecture drift detection): document reading `ai-context/architecture.md` if it exists; document the three-way classification (match / minor drift / significant drift); document the behavior when `ai-context/architecture.md` is absent (section states no baseline found, no drift entries produced, no error); document that all drift entries are informational only — no severity labels, no FIX_MANIFEST references

- [x] 1.7 In `skills/project-analyze/SKILL.md` Step 6 (Write outputs): document the `[auto-updated]` marker strategy using the exact HTML comment syntax `<!-- [auto-updated]: <section-id> — last run: YYYY-MM-DD -->` ... `<!-- [/auto-updated] -->` with the four section-IDs (`stack-detection`, `structure-mapping`, `drift-summary`, `observed-conventions`); document the merge algorithm (replace if marker exists, append at end if not); document that `known-issues.md` and `changelog-ai.md` are NEVER written; document that `ai-context/` is NOT created if it does not exist (emit instruction to run `/memory-init` instead); document that `analysis-report.md` is written to the project root

- [x] 1.8 In `skills/project-analyze/SKILL.md` Rules section: add the five hard rules: (1) NEVER scores or assigns severity levels; (2) NEVER produces FIX_MANIFEST entries; (3) NEVER modifies content outside `[auto-updated]` markers; (4) NEVER creates `ai-context/` if it does not exist; (5) maximum 3 Bash calls per execution (Steps 1+2 share 1, Step 3 = 1, Step 4 = 1); add the always-on rules: always writes `Last analyzed:` date to `analysis-report.md`; always reports which ai-context/ sections were updated vs preserved

- [x] 1.9 In `skills/project-analyze/SKILL.md` Output format section: document the exact `analysis-report.md` structure matching the template in `design.md` — sections in order: header metadata block (`Last analyzed`, `Analyzer`, `Config`), `## Summary` (with `Stack detected:`, `Organization pattern:`, `Architecture drift:`, `Conventions documented:` fields), `## Stack`, `## Structure`, `## Conventions Observed`, `## Architecture Drift` (with `Drift Summary` and `Drift entries:` as the D7 consumption contract), `## ai-context/ Update Log`

---

## Phase 2: Modify project-audit — D7 Rewrite and Phase A Extension

- [x] 2.1 In `skills/project-audit/SKILL.md`, replace the entire `### Dimension 7 — Architecture Compliance (sampling)` section (lines 269–299, from the heading through "For each violation: I report file, line, and the violated rule.") with the new D7 definition: D7 reads `analysis-report.md` from the project root; scoring table: absent = 0/5 + CRITICAL message; present + architecture.md absent = 2/5 + HIGH message; drift summary = `none` → 5/5; drift summary = `minor` → 3/5 + MEDIUM + list entries; drift summary = `significant` → 0/5 + HIGH + list entries; staleness warning if `Last analyzed:` > 7 days old (warning text only — score is still computed from existing report, no deduction); FIX_MANIFEST rule: D7 violations go in `violations[]` only (NOT in `required_actions`)

- [x] 2.2 In `skills/project-audit/SKILL.md`, add a "Phase A extension" sub-section inside the existing `## Execution Rules` section (after Rule 8 and before end of file) that documents the `ANALYSIS_REPORT_EXISTS` check: after the Phase A Bash batch completes, check whether `analysis-report.md` exists in the project root and read its `Last analyzed:` date; store result as a variable read by D7 in Phase B; note that `project-audit` does NOT invoke `project-analyze` automatically — it treats `analysis-report.md` as an external input; update the Phase A Bash script template to add `echo "ANALYSIS_REPORT_EXISTS=$(f analysis-report.md)"` and `echo "ANALYSIS_REPORT_DATE=$(head -3 "$PROJECT/analysis-report.md" 2>/dev/null | grep 'Last analyzed:' | cut -d' ' -f3 || echo '')"` to the existing script

- [x] 2.3 In `skills/project-audit/SKILL.md` Report Format section, replace the `## Dimension 7 — Architecture Compliance` output template block (lines 631–639) with the new D7 output template: `## Dimension 7 — Architecture Compliance [OK|WARNING|CRITICAL]`, showing `Analysis report found: YES/NO`, `Last analyzed: [date or N/A]`, `Architecture drift status: [none|minor|significant|N/A]`, and a `Drift entries:` table when drift is present; ensure the Score table row in the report format retains `Architecture compliance | [X] | 5`

---

## Phase 3: Registry and Documentation Updates

- [x] 3.1 In `CLAUDE.md` (project root), add `/project-analyze` row to the "Meta-tools — Project Management" command table, placed between `/project-audit` and `/project-fix`, with description: "Performs deep framework-agnostic codebase analysis — produces analysis-report.md and updates ai-context/" ✓

- [x] 3.2 In `CLAUDE.md` (project root), add `/project-analyze` row to the "How I Execute Commands" mapping table with skill path `~/.claude/skills/project-analyze/SKILL.md` ✓

- [x] 3.3 In `CLAUDE.md` (project root) Skills Registry section, add `~/.claude/skills/project-analyze/SKILL.md` entry under the "Meta-tool Skills" subsection, with description: "deep framework-agnostic codebase analysis — observes and describes, never scores or produces FIX_MANIFEST entries; produces analysis-report.md and updates ai-context/ [auto-updated] sections" ✓

- [x] 3.4 In `ai-context/architecture.md`, add a new row to the "Communication between skills via artifacts" table for `analysis-report.md`: Producer = `project-analyze`, Consumer = `project-audit (D7), user`, Location = `project root` ✓

- [x] 3.5 In `openspec/config.yaml`, append the optional `analysis` key comment block (following the same style as the existing `feature_docs` comment block at the end of the file) documenting: `analysis.max_sample_files` (default: 20), `analysis.exclude_dirs` (optional list), `analysis.analysis_targets` (optional explicit file list that overrides auto-sampling) ✓

---

## Phase 4: Verification Setup

- [x] 4.1 Verify `skills/project-analyze/SKILL.md` exists and contains all four required sections (Trigger, Process, Rules, Output) by reading the file and checking: file is > 80 lines; trigger mentions `/project-analyze`; Rules section explicitly states "NEVER scores", "NEVER produces FIX_MANIFEST", "NEVER creates ai-context/"; Output section references `analysis-report.md` ✓

- [x] 4.2 Verify `skills/project-audit/SKILL.md` D7 section no longer contains references to `PrismaClient`, `withSegmentAPI`, `font-weight`, or Next.js/Prisma-specific patterns; and does contain references to `analysis-report.md`, the drift scoring table (0/2/3/5 scores), and the "Run /project-analyze first" instruction message ✓

---

## Phase 5: Cleanup and Memory Update

- [x] 5.1 Update `ai-context/changelog-ai.md` — append a new entry under today's date (2026-02-27) documenting: created `skills/project-analyze/SKILL.md` (new standalone analysis skill), rewrote D7 in `skills/project-audit/SKILL.md` (framework-agnostic, reads analysis-report.md), updated `CLAUDE.md` (project-analyze registered), updated `ai-context/architecture.md` (analysis-report.md artifact row added), updated `openspec/config.yaml` (analysis optional key documented) ✓

---

## Implementation Notes

- **D7 scoring formula (resolved):** Zero drift entries = 5/5. Minor drift (1+ informational entries, drift summary = `minor`) = 3/5. Significant drift (structural mismatches, drift summary = `significant`) = 0/5. `analysis-report.md` present but no `ai-context/architecture.md` = 2/5 (D7 cannot compare without a baseline). `analysis-report.md` absent = 0/5.
- **Staleness behavior (resolved):** If `Last analyzed:` is older than 7 days, D7 emits a warning message but still computes the score from the existing report. No score deduction for staleness.
- **Large repo sampling (resolved):** When auto-detecting source directories, select files evenly across directories prioritizing most recently modified files. Hard ceiling: 20 files (or `analysis.max_sample_files` if configured). When a directory contains thousands of files, take `ceil(20 / num_dirs)` from each, sorted by recency.
- **`[auto-updated]` marker collision (resolved):** HTML comment markers (`<!-- [auto-updated]: X -->`) are invisible in rendered Markdown. None of the current `ai-context/` files in this repo use that format. No collision risk.
- **`project-analyze` does NOT create `ai-context/`:** If the target project has no `ai-context/` directory, the skill writes only `analysis-report.md` and logs in the Update Log section that `ai-context/` was not found. User must run `/memory-init` first. This is intentional boundary with `memory-manager`.
- **`project-audit` does NOT auto-invoke `project-analyze`:** D7 scores 0 with a clear instruction when `analysis-report.md` is absent. The user must run `/project-analyze` then `/project-audit` manually.
- **Phase A Bash call budget:** The existing Phase A script is one Bash call. Adding `ANALYSIS_REPORT_EXISTS` and `ANALYSIS_REPORT_DATE` variables to the existing script is an in-place extension (no additional Bash call). Total Bash calls remain ≤ 3 for a full audit run.
- **`install.sh` deployment:** New skill directory `skills/project-analyze/` is picked up by `install.sh` automatically (it rsync-copies the entire `skills/` directory). No changes to `install.sh` required.
- **Verify after apply:** Run `/project-audit` on `claude-config` and confirm score ≥ 75. Then run `/project-analyze` on Audiio V3 (D:/Proyectos/Audiio/audiio_v3_1) and confirm `analysis-report.md` is produced with all five sections. Refer to `design.md` Testing Strategy table for full verification checklist.

## Blockers

None.
