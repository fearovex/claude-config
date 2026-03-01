# Task Plan: sdd-cycle-prd-adr-integration

Date: 2026-03-01
Design: openspec/changes/sdd-cycle-prd-adr-integration/design.md

## Progress: 8/8 tasks

## Phase 1: Skill Modifications

- [x] 1.1 Modify `skills/sdd-propose/SKILL.md` — insert a new Step 5 (PRD Shell Generation) between the existing Step 4 (write proposal.md) and the existing Step 5 (summary to orchestrator); renumber old Step 5 to Step 6. The new step must: (a) check if `openspec/changes/<change-name>/prd.md` already exists and skip if it does; (b) check if `docs/templates/prd-template.md` exists and log "PRD template not found — skipping PRD shell creation" then skip if absent; (c) copy the template to `openspec/changes/<change-name>/prd.md` and fill the frontmatter fields (`title` from change-name, `date` from today YYYY-MM-DD, `related-change` pointing to the change path); (d) inform the user that prd.md is optional and intended for product-facing changes; (e) add `prd.md` to the artifacts list only if it was created in this run.

- [x] 1.2 Modify `skills/sdd-design/SKILL.md` — insert a new Step 4 (ADR Detection and Generation) between the existing Step 3 (write design.md) and the existing Step 4 (summary to orchestrator); renumber old Step 4 to Step 5. The new step must: (a) scan the Technical Decisions table in `design.md` for rows containing any of these keywords (case-insensitive): `pattern`, `convention`, `cross-cutting`, `replaces`, `introduces`, `architecture`, `global`, `system-wide`, `breaking`; (b) if no significant decision is found, skip silently; (c) if at least one is found: count existing `docs/adr/[0-9][0-9][0-9]-*.md` files to determine next sequential number (zero-padded to 3 digits); derive a slug as `<NNN>-<change-name>[-<first-matched-keyword>]` truncated to 50 chars, lowercase, hyphens only; copy `docs/templates/adr-template.md` to `docs/adr/<slug>.md` and pre-fill Title, Status (Proposed), Context (from Justification column), and Decision (from Choice column); append a new row to `docs/adr/README.md` ADR index table; add `docs/adr/<slug>.md` to the artifacts list; (d) if `docs/templates/adr-template.md` or `docs/adr/README.md` is absent, log a warning and skip — do NOT return `status: blocked` or `status: failed`.

## Phase 2: Configuration and Documentation Updates

- [x] 2.1 Modify `openspec/config.yaml` — add an `optional_artifacts` key under the `testing:` block (after the existing `required_artifacts_per_change` list). The new key must list two entries, each with an inline comment indicating which skill produces it:
  - `"prd.md"` with comment `# created by sdd-propose if template exists and no prd.md present`
  - `"docs/adr/NNN-*.md"` with comment `# created by sdd-design when a significant architectural decision is detected`
  The existing `required_artifacts_per_change` list (`proposal.md`, `tasks.md`, `verify-report.md`) MUST remain unchanged.

- [x] 2.2 Modify `CLAUDE.md` — update the SDD Artifact Storage section to extend the ASCII artifact tree. Under the per-change directory, add `prd.md (optional)` with a note "← optional; created by sdd-propose if template exists". At the project root level, add a `docs/` subtree showing `docs/adr/README.md` (updated by sdd-design when a new ADR is created) and `docs/adr/NNN-<slug>.md` (optional; created by sdd-design when a significant architectural decision is detected). The existing required artifact entries must remain unchanged.

## Phase 3: Verification Preparation

- [x] 3.1 Manually verify `skills/sdd-propose/SKILL.md` — confirm Step 5 is inserted correctly, Step 6 is the renumbered summary step, and the PRD logic matches the data flow diagram in `openspec/changes/sdd-cycle-prd-adr-integration/design.md` exactly.

- [x] 3.2 Manually verify `skills/sdd-design/SKILL.md` — confirm Step 4 is inserted correctly, Step 5 is the renumbered summary step, and the ADR keyword list and numbering logic match the design spec exactly.

- [x] 3.3 Verify `openspec/config.yaml` contains the new `optional_artifacts` key and that `required_artifacts_per_change` still lists exactly `proposal.md`, `tasks.md`, `verify-report.md`.

- [x] 3.4 Verify `CLAUDE.md` SDD Artifact Storage section shows `prd.md (optional)` under the change directory tree and `docs/adr/` subtree at the project root level with correct annotations.

---

## Implementation Notes

- Both new steps (PRD in sdd-propose, ADR in sdd-design) are **non-blocking**: any file-check failure must produce a warning, not a `status: failed` or `status: blocked` return.
- PRD creation is idempotent: the step checks file existence before writing; if `prd.md` already exists, it must be left untouched regardless of its content.
- ADR number determination uses filesystem count (`docs/adr/[0-9][0-9][0-9]-*.md`) not README.md parsing — this is authoritative even if README.md drifts.
- The `optional_artifacts` key in config.yaml is placed under `testing:` to mirror the pattern established by `required_artifacts_per_change`.
- The CLAUDE.md changes extend the existing ASCII tree in-place; no new top-level section is added — the single artifact tree is the canonical reference.
- After applying all tasks, run `bash install.sh` to deploy updated skills and CLAUDE.md to `~/.claude/`.

## Blockers

None.
