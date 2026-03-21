# Task Plan: 2026-03-20-sdd-archive-move-incomplete

Date: 2026-03-20
Design: openspec/changes/2026-03-20-sdd-archive-move-incomplete/design.md

## Progress: 4/4 tasks

## Phase 1: Skill Fix

- [x] 1.1 Read `skills/sdd-archive/SKILL.md` in full to locate the exact Step 4 insertion point (the `I create openspec/changes/archive/` sentence) and verify the date-stripping pre-flight block is preserved verbatim

- [x] 1.2 Modify `skills/sdd-archive/SKILL.md` — insert into Step 4, after the archive directory creation instruction and all file-copy instructions, three new prose sentences:
  (1) Semantic anchor: "I move the change folder:"
  (2) Deletion instruction: "After ALL files are confirmed present at `openspec/changes/archive/<date>-<archive_slug>/`, I MUST delete `openspec/changes/<change-name>/` and all its contents. Source deletion MUST NOT execute before destination files are confirmed — if confirmation fails, I halt and report an error without deleting the source."
  (3) Verification sentence: "I confirm the source directory `openspec/changes/<change-name>/` no longer exists before continuing to Step 5. I output 'Source directory deleted: openspec/changes/<change-name>/' to confirm completion. If deletion fails after a successful copy, I output a WARNING with the exact path to delete manually and continue to Step 5 with `status: warning`."
  Acceptance: Step 4 contains all three sentences; the date-stripping pre-flight block (which strips an existing `YYYY-MM-DD-` prefix and computes `archive_slug`) is unchanged

## Phase 2: Master Spec Update

- [x] 2.1 Read `openspec/specs/sdd-archive-execution/spec.md` in full to identify the highest existing requirement ID and confirm no existing requirement already covers source-directory deletion

- [x] 2.2 Modify `openspec/specs/sdd-archive-execution/spec.md` — append the two new requirements from the delta spec at `openspec/changes/2026-03-20-sdd-archive-move-incomplete/specs/sdd-archive-execution/spec.md`:
  (1) "Step 4 MUST delete the source directory after successful copy" — with all four scenarios
  (2) "Step 4 MUST preserve the date-stripping pre-flight block" — with its scenario
  Assign new requirement IDs following the existing numbering sequence.
  Acceptance: master spec contains both requirements with IDs; no existing requirement is modified or removed

---

## Implementation Notes

- The deletion instruction placement is strictly after the copy instructions and before Step 5. The pre-flight date-stripping block (which produces `archive_slug` from `change-name`) runs first and MUST NOT be touched.
- Task 1.2 depends on task 1.1 (read before write). Task 2.2 depends on task 2.1 (read before write).
- The `status: warning` floor for deletion failures (not `status: failed`) is explicitly required by the delta spec — the implementer MUST honor this distinction.
- After `skills/sdd-archive/SKILL.md` is modified, run `bash install.sh` (in the project root) to deploy the updated skill to `~/.claude/skills/sdd-archive/SKILL.md`.

## Blockers

None.
