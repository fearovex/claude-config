# Task Plan: skill-internal-coherence-validation

Date: 2026-02-28
Design: openspec/changes/skill-internal-coherence-validation/design.md

## Progress: 8/8 tasks

## Phase 1: Add D11 dimension to project-audit SKILL.md

- [x] 1.1 Modify `skills/project-audit/SKILL.md` — add `### Dimension 11 — Internal Coherence` section after the Dimension 10 section, containing three sub-check definitions: D11-a (Count Consistency) with `CLAIM_PATTERN` extraction from headings and blockquotes, D11-b (Section Numbering Continuity) with sequence pattern matching for Step/Dimension/Phase/D-prefix, and D11-c (Frontmatter-Body Alignment) with YAML description field verification
- [x] 1.2 Modify `skills/project-audit/SKILL.md` — update the header line `## Audit Process — 9 Dimensions` to `## Audit Process — 10 Dimensions`
- [x] 1.3 Modify `skills/project-audit/SKILL.md` — add D11 report output block in the Report Format section after the Dimension 10 block, following the template from design.md (per-skill findings table with columns: Skill, Count OK, Numbering OK, Frontmatter OK, Findings)

## Phase 2: Update scoring table and FIX_MANIFEST references

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — add a row for D11 (Internal Coherence) in the score table within the Report Format section: `| Internal Coherence | N/A | N/A | ✅/ℹ️/— |` after the Feature Docs Coverage row
- [x] 2.2 Modify `skills/project-audit/SKILL.md` — add D11 FIX_MANIFEST rule: D11 findings go in `violations[]` only with severity `info`, rule names `D11-count-consistency`, `D11-numbering-continuity`, `D11-frontmatter-body`; MUST NOT appear in `required_actions` or `skill_quality_actions`
- [x] 2.3 Modify `skills/project-audit/SKILL.md` — add D11 to the Detailed Scoring table at the bottom: `| **Internal Coherence** | Informational only — no score deduction. Validates count claims, section numbering, and frontmatter consistency within individual skill files. | N/A |`

## Phase 3: Update spec and frontmatter

- [x] 3.1 Modify `openspec/specs/audit-dimensions/spec.md` — append a new `## ADDED in skill-internal-coherence-validation (2026-02-28)` section at the end of the file, containing the D11 requirements and scenarios from `openspec/changes/skill-internal-coherence-validation/specs/audit-dimensions/spec.md`
- [x] 3.2 Modify `skills/project-audit/SKILL.md` — update the YAML frontmatter `description` field to reflect the correct dimension count if it contains a numeric claim (currently says "Deep diagnostic" with no count, so verify and update only if a count is present)

---

## Implementation Notes

- D11 follows the exact same informational-only pattern as D9 and D10: no score impact, findings in `violations[]` only, `/project-fix` does not act on them
- D11 uses only Read/Glob/Grep tools for file analysis — no new Bash calls beyond the existing Phase A discovery script
- D11 scope: all `SKILL.md` files under `$LOCAL_SKILLS_DIR` (emitted by Phase A) plus root `CLAUDE.md`
- The three check patterns (count consistency, numbering continuity, frontmatter-body) are defined in design.md under "Interfaces and Contracts > D11 check patterns"
- The header update from "9 Dimensions" to "10 Dimensions" is itself a count consistency fix — D11 would catch this exact class of error

## Blockers

None.
