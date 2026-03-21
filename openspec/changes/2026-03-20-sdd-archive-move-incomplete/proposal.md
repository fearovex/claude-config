# Proposal: sdd-archive-move-incomplete

Date: 2026-03-20
Status: Draft

## Intent

Fix the `sdd-archive` skill's Step 4, which copies change files to the archive destination but never deletes the source directory, leaving ghost duplicates under `openspec/changes/` after every archive operation.

## Motivation

The `sdd-archive` skill's Step 4 is titled "Move to archive" and its confirmation prompt says "IRREVERSIBLE actions: Move openspec/changes/[name]/ → openspec/changes/archive/[date]-[name]/". However, the step body only contains copy/create instructions — there is no LLM instruction to delete `openspec/changes/<change-name>/` after the copy. Sub-agents terminate after writing files to the destination, leaving the source directory intact.

This was introduced (or made worse) during the `sdd-archive-orphan-validation` change, which modified Step 4 to add a date-stripping pre-flight block and in doing so silently dropped the original `I move the change folder:` sentence that served as a weak semantic anchor for the deletion intent.

The master spec at `openspec/specs/sdd-archive-execution/spec.md` is entirely silent on source-directory deletion, meaning the gap is also formally unspecified. Two artifacts need fixing: the SKILL.md and the master spec.

## Supersedes

None — this is a purely additive change. No existing spec requirement is removed or replaced. The SKILL.md restoration of the deletion instruction does not supersede any behavior that was formally required — it fills a gap that was never specified.

## Scope

### Included

- Add explicit source-directory deletion instruction to Step 4 of `skills/sdd-archive/SKILL.md`
- Add a verification sentence confirming the source is gone before Step 5 begins
- Restore the `I move the change folder:` semantic anchor sentence to Step 4 for clarity
- Add a new delta spec requirement to `openspec/specs/sdd-archive-execution/spec.md` (or this change's delta spec) formalizing move semantics: source MUST be deleted after successful copy

### Excluded (explicitly out of scope)

- Changes to Step 0 (orphan detection), Step 1 (verify archivable), Step 5 (CLOSURE.md), Step 6 (index maintenance), or Step 7 (memory update) — these steps are correct and unrelated
- Changes to how the archive destination path is computed (the date-stripping pre-flight added by `sdd-archive-orphan-validation` is correct and must be preserved)
- Retroactive cleanup of existing ghost duplicates already present in `openspec/changes/` (a separate cleanup operation if needed)
- Git-tracking improvements (the LLM sub-agent uses Claude Code file tools, not `git mv`; git will show deletions as normal deletes, which is acceptable behavior)

## Proposed Approach

**Step 4 of `skills/sdd-archive/SKILL.md`** will be updated to include three explicit instructions after the archive destination folder creation:

1. **Copy all files**: existing logic already does this — retain it.
2. **Delete source**: add prose instruction — "I delete `openspec/changes/<change-name>/` and all its contents."
3. **Verify deletion**: add verification sentence — "I confirm the source directory no longer exists before continuing to Step 5."

The instruction will emphasize the precondition: source deletion only occurs after ALL files are confirmed at the destination. This guards against partial-copy + delete data loss.

**Delta spec** for this change will add one new requirement to `sdd-archive-execution` covering the move semantics: Step 4 MUST delete the source after all files are confirmed copied; the source MUST NOT exist after Step 4 completes. The delta will be merged into the master spec at archive time.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `skills/sdd-archive/SKILL.md` | Modified — Step 4 gains source-deletion instruction | HIGH — fixes the core behavioral bug |
| `openspec/specs/sdd-archive-execution/spec.md` | Modified — new requirement for move semantics | MEDIUM — closes the spec gap; future verify passes now have a contract |
| `openspec/changes/<active>/` | Operational — ghost duplicates stop accumulating | HIGH — every future archive will leave a clean state |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Over-deletion: sub-agent deletes wrong folder | Low | High | Instruction must name the exact path `openspec/changes/<change-name>/` explicitly; precondition requires destination success first |
| Partial copy + delete: copy fails mid-way then delete succeeds | Very Low | High | Instruction must state "only delete source after ALL files are confirmed at destination" |
| LLM ignores the new instruction | Low | Medium | Instruction will use imperative language ("I MUST delete", "The source MUST NOT exist") consistent with spec conventions |
| Step 4 date-stripping pre-flight is accidentally disrupted | Low | Medium | Design must preserve the existing pre-flight block verbatim; only the post-copy deletion instruction is added |

## Rollback Plan

If the new deletion instruction causes incorrect behavior (e.g., early deletion before copy completes):

1. Revert `skills/sdd-archive/SKILL.md` via `git checkout HEAD -- skills/sdd-archive/SKILL.md`
2. Run `bash install.sh` to redeploy the reverted skill to `~/.claude/`
3. The delta spec is in `openspec/changes/2026-03-20-sdd-archive-move-incomplete/specs/` and will not have been merged yet if archive hasn't run — no spec rollback needed in that case
4. If the delta spec was already merged: add a revert entry to the master spec and run a new `sdd-ff` to document the revert

## Dependencies

- `skills/sdd-archive/SKILL.md` must be read before modifying (to preserve existing Step 4 date-stripping pre-flight logic)
- `openspec/specs/sdd-archive-execution/spec.md` must be read in full before adding the delta requirement (to avoid duplicating existing requirement IDs or conflicting with the orphan precondition requirements)
- No other skills or phases depend on this change

## Success Criteria

- [ ] `skills/sdd-archive/SKILL.md` Step 4 contains an explicit instruction to delete `openspec/changes/<change-name>/` after all files have been written to the destination
- [ ] Step 4 contains a verification step confirming the source directory no longer exists before proceeding to Step 5
- [ ] The date-stripping pre-flight block in Step 4 is unchanged
- [ ] A delta spec requirement is written in this change's `specs/sdd-archive-execution/spec.md` stating that the source directory MUST be deleted and MUST NOT exist after Step 4 completes
- [ ] Running `sdd-archive` on a test change results in `openspec/changes/<change-name>/` being absent after the operation
- [ ] The `verify-report.md` for this change records at least one `[x]` criterion with observable evidence

## Effort Estimate

Low (hours) — targeted two-file change with no new skills, no new orchestration, and a clear fix location identified by exploration.
