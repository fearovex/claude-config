# Task Plan: 2026-03-10-sdd-apply-diagnose-first

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-apply-diagnose-first/design.md

## Progress: 5/5 tasks

## Phase 1: Skill Update — Add Diagnosis Step to sdd-apply

- [x] 1.1 Modify `skills/sdd-apply/SKILL.md` — insert new Diagnosis Step between the existing "Step 3 — Verify work scope" and "Step 4 — Implement task by task" sections. The step MUST contain: (a) instruction to read all files to be modified, (b) instruction to run `diagnosis_commands` from config if present, (c) the structured `DIAGNOSIS` block template with all 5 fields + Risk field, (d) the `MUST_RESOLVE` warning protocol when diagnosis contradicts task assumptions, (e) the hard gate: "no file changes before DIAGNOSIS block is written" ✓
- [x] 1.2 Modify `skills/sdd-apply/SKILL.md` — add documentation for the `diagnosis_commands` optional config key in Step 1 (Read full context) alongside the existing `openspec/config.yaml` read, noting: key is optional, commands are expected to be read-only, absent key means auto-detection only ✓
- [x] 1.3 Modify `skills/sdd-apply/SKILL.md` — renumber steps if needed after insertion so the step numbering remains sequential and unambiguous (current: Step 1, 2, 3, 4, 5, 6 → new step sequence after insertion) ✓

## Phase 2: Config Schema Documentation

- [x] 2.1 Modify `openspec/config.yaml` — add a commented example block documenting the `diagnosis_commands` optional key (YAML comment with schema description and example values), consistent with how other optional keys are documented in the file ✓

## Phase 3: Verification and Memory Update

- [x] 3.1 Update `ai-context/changelog-ai.md` — record the diagnosis-first change with date, change slug, affected file, and brief description of what changed ✓

---

## Implementation Notes

- This is a documentation-only change (only `.md` and `.yaml` files modified). The `sdd-apply` scope guard will skip tech skill preload — this is expected and correct.
- Step numbering in `sdd-apply/SKILL.md` must be verified after insertion: currently Steps 1–6. The Diagnosis Step inserts between Step 3 and Step 4. Options: label it "Step 3.5" or renumber Steps 4–6 to 5–7. Use renumbering for clarity (no decimal steps in existing skill).
- The `DIAGNOSIS` block format in the SKILL.md must match exactly the format defined in `design.md` Interfaces section, which was derived from the proposal.
- `MUST_RESOLVE` warning format must match exactly the format in `design.md` to satisfy spec scenario "Scenario: Diagnosis reveals contradicting state — warning raised".
- `openspec/config.yaml` task (2.1) is additive only — no existing keys should be removed or modified.

## Blockers

None.
