# Proposal: integrate-memory-into-sdd-cycle

Date: 2026-02-28
Status: Draft

## Intent

Eliminate the gap between SDD cycle completion and memory updates by making sdd-archive automatically invoke /memory-update as its final step, ensuring ai-context/ is always current after every archived change.

## Motivation

Currently, sdd-archive (Step 6) only prints a text recommendation: "Run /memory-update to update ai-context/". In practice, users forget to run it. This causes the memory layer (ai-context/) to become stale over time, which degrades the quality of subsequent sessions because Claude reads outdated context at startup.

The archive phase is the natural integration point because:
1. It is the terminal phase of the SDD cycle -- all decisions are finalized
2. The change name and artifact set provide rich context for what to record
3. memory-update is non-destructive (only adds/updates, never deletes)
4. The SDD cycle is already a multi-step automated process, so adding one more step is ergonomically consistent

## Scope

### Included
- Modify `sdd-archive/SKILL.md` to add a new Step 7 that invokes /memory-update automatically after the archive completes
- Modify `sdd-ff/SKILL.md` final summary to mention that memory will be auto-updated after archive
- Modify `sdd-new/SKILL.md` final summary to mention that memory will be auto-updated after archive
- Update the `openspec/specs/audit-execution/spec.md` if it references the archive-memory relationship

### Excluded (explicitly out of scope)
- Changing how memory-update itself works -- its internal logic remains untouched
- Adding memory-update to other SDD phases (apply, verify) -- only archive is the integration point
- Making the auto-update configurable/optional -- it always runs (users who want to skip can archive manually)
- Modifying sync.sh or install.sh behavior
- Changing the CLAUDE.md orchestrator delegation pattern

## Proposed Approach

Add a new **Step 7 -- Auto-update memory** to `sdd-archive/SKILL.md` that:
1. After the archive is complete and the closure note is written (Step 5), automatically reads and executes `memory-update/SKILL.md`
2. Passes the change name and archive path as context so memory-update knows what to record
3. Reports the memory-update result as part of the archive output (success/failure)
4. The existing Step 6 text recommendation is replaced with a confirmation that the update was performed

For sdd-ff and sdd-new, add a brief note in the final summary indicating that `/sdd-archive` will auto-update memory.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| skills/sdd-archive/SKILL.md | Modified | High -- core behavioral change: new Step 7 |
| skills/sdd-ff/SKILL.md | Modified | Low -- informational text addition only |
| skills/sdd-new/SKILL.md | Modified | Low -- informational text addition only |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| memory-update failure blocks archive completion | Low | Medium | Make memory-update non-blocking: if it fails, archive still succeeds with a warning |
| memory-update produces incorrect ai-context entries | Low | Low | memory-update is already battle-tested; archive just triggers it with richer context |
| Sub-agent context window pressure from running two skills in sequence | Low | Low | sdd-archive sub-agent already has limited context; memory-update reads fresh files |

## Rollback Plan

1. Revert `skills/sdd-archive/SKILL.md` to the version before this change (restore Step 6 as the final step, remove Step 7)
2. Revert the informational text additions in `skills/sdd-ff/SKILL.md` and `skills/sdd-new/SKILL.md`
3. Run `install.sh` to deploy the reverted files
4. No data loss risk: memory-update only adds/updates ai-context/ files, never deletes

## Dependencies

- `skills/memory-update/SKILL.md` must exist and be functional (it does)
- `skills/sdd-archive/SKILL.md` must be the current version with Steps 1-6 (it is)

## Success Criteria

- [ ] sdd-archive/SKILL.md contains a Step 7 that invokes memory-update after archive completion
- [ ] The memory-update invocation in Step 7 is non-blocking (archive succeeds even if memory-update fails)
- [ ] sdd-archive Step 6 no longer shows a manual recommendation but instead confirms the auto-update result
- [ ] sdd-ff final summary mentions that /sdd-archive will auto-update memory
- [ ] sdd-new final summary mentions that /sdd-archive will auto-update memory
- [ ] install.sh deploys the updated skills correctly (manual verification)

## Effort Estimate

Low (hours) -- three skill files with minor modifications each.
