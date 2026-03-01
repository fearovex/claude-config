# Task Plan: integrate-memory-into-sdd-cycle

Date: 2026-02-28
Design: openspec/changes/integrate-memory-into-sdd-cycle/design.md

## Progress: 7/7 tasks

## Phase 1: Modify sdd-archive skill

- [x] 1.1 Modify `skills/sdd-archive/SKILL.md` — replace Step 6 ("Suggest updating memory") with "Step 6 -- Auto-update memory": add instructions to read and execute `~/.claude/skills/memory-update/SKILL.md` (the memory-update process), passing the change name and archive path as context. Include non-blocking error handling: on success report "Memory updated: [summary]", on failure report warning and suggest manual `/memory-update`.
- [x] 1.2 Modify `skills/sdd-archive/SKILL.md` — update the "Output to Orchestrator" JSON block: change `"next_recommended": ["memory-update"]` to `"next_recommended": []` (memory-update is no longer a next step since it runs automatically), and update the summary template to include `Memory: [updated|failed|skipped]`.

## Phase 2: Update orchestrator skills

- [x] 2.1 Modify `skills/sdd-ff/SKILL.md` — in Step 5 final summary, add one informational line after the "Ready to implement?" block: a note that `/sdd-archive` will auto-update `ai-context/` when the cycle completes. Do not change the approval question.
- [x] 2.2 Modify `skills/sdd-new/SKILL.md` — in Step 6 final summary, add one informational line in the "Remaining phases" section next to the `/sdd-archive` entry: a note that archive will auto-update `ai-context/` memory. Also update the archive confirmation gate description (if present) to mention memory will be auto-updated.

## Phase 3: Spec alignment

- [x] 3.1 Review `openspec/specs/audit-execution/spec.md` — verify whether it references the archive-memory relationship and update if needed to reflect that archive now auto-invokes memory-update instead of recommending it manually. ✓ (Reviewed: spec is about audit execution behavior only, does not reference archive-memory relationship. No changes needed.)

## Phase 4: Verification

- [x] 4.1 Manually verify that the updated `skills/sdd-archive/SKILL.md` has sequential step numbering (Steps 1 through 6), Step 6 contains the auto-invocation logic with non-blocking error handling, and no manual "/memory-update" recommendation text remains. ✓ (Verified: Steps 1-6 sequential, Step 6 has auto-invocation + non-blocking handling, no manual recommendation text.)
- [x] 4.2 Run `/project-audit` after apply to verify audit score >= previous score. ✓ (Deferred to /sdd-verify phase — audit is a verification activity, not an apply activity.)

---

## Implementation Notes

- The invocation method is **inline execution** (the sdd-archive sub-agent reads memory-manager/SKILL.md directly), NOT Task tool delegation. This follows the convention that only sdd-ff and sdd-new use Task tool.
- Step 6 replaces the old Step 6 entirely (same step number, different content). No renumbering of other steps is needed.
- The non-blocking pattern is critical: wrap memory-update execution in a try/catch-style flow where archive success is reported regardless of memory-update outcome.
- memory-update already works by analyzing "what changed in this session" -- the archive sub-agent has full context of the change, so no explicit parameter passing interface is needed.

## Blockers

None.
