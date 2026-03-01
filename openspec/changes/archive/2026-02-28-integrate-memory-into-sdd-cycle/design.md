# Technical Design: integrate-memory-into-sdd-cycle

Date: 2026-02-28
Proposal: openspec/changes/integrate-memory-into-sdd-cycle/proposal.md

## General Approach

Extend the sdd-archive skill by adding a new Step 7 that automatically invokes the memory-update skill after the archive operation completes. The invocation is non-blocking: if memory-update fails, the archive still reports success with a warning. The two orchestrator skills (sdd-ff and sdd-new) receive informational text additions in their final summaries so users know memory will be auto-updated at archive time.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Integration point | sdd-archive Step 7 (after closure note) | Hooking into sdd-apply, sdd-verify, or post-commit hook | Archive is the terminal SDD phase where all decisions are finalized; earlier phases may still change. Proposal explicitly scopes this to archive only. |
| Invocation method | Inline instructions in SKILL.md (direct execution by the sub-agent) | Task tool delegation to a nested sub-agent | sdd-archive is an executor skill, not an orchestrator. Adding Task-tool delegation would violate the convention that only sdd-ff and sdd-new use Task tool (see conventions.md). The sub-agent running sdd-archive reads memory-update/SKILL.md directly and executes it in the same context. |
| Failure handling | Non-blocking with warning in output | Blocking (fail archive if memory-update fails), silent ignore | Proposal explicitly requires non-blocking. A warning ensures visibility without breaking the archive workflow. |
| Context passing to memory-update | memory-update reads session context naturally (files modified, decisions made) | Passing explicit parameters via a structured interface | memory-update already works by analyzing "what changed in this session" (Step 1 of its process). The archive sub-agent has full context of the change. No new interface needed. |
| Step 6 replacement | Replace the manual recommendation text with a confirmation/warning block | Keep Step 6 as-is and add Step 7 after it | Step 6 currently says "Recommendation: Run /memory-update". After auto-invocation, this text becomes misleading. Replacing it with the result confirmation is cleaner. |

## Data Flow

```
User runs /sdd-archive <change-name>
          |
          v
    Step 1: Verify archivable
          |
          v
    Step 2: Confirm with user
          |
          v
    Step 3: Sync delta specs -> master specs
          |
          v
    Step 4: Move to archive/
          |
          v
    Step 5: Create CLOSURE.md
          |
          v
    Step 6: Auto-update memory    [NEW - replaces old Step 6]
          |
          +---> Read memory-update/SKILL.md
          |        |
          |        +---> Step 1: Analyze session (change artifacts)
          |        +---> Step 2-6: Update ai-context/ files
          |        +---> Step 7: Summary
          |
          +---> On success: report "Memory updated: [details]"
          +---> On failure: report "Memory update failed: [reason]. Archive completed."
          |
          v
    Output to Orchestrator (status, summary, artifacts)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-archive/SKILL.md` | Modify | Replace Step 6 content: remove manual recommendation, add auto-invocation of memory-update with non-blocking error handling. Renumber as "Step 6 -- Auto-update memory". Update Output to Orchestrator to include memory-update result. |
| `skills/sdd-ff/SKILL.md` | Modify | Add one line in Step 5 final summary (after "Ready to implement?" block): note that `/sdd-archive` will auto-update ai-context/ memory. |
| `skills/sdd-new/SKILL.md` | Modify | Add one line in Step 6 final summary (after remaining phases listing): note that `/sdd-archive` will auto-update ai-context/ memory. |

## Interfaces and Contracts

No new interfaces or contracts are needed. The integration uses the existing memory-update skill's process steps directly. The only contract is the implicit one already in place:

```markdown
# memory-update contract (existing, unchanged)
Input:  ai-context/ directory must exist
Output: Updated ai-context/ files + summary text
Error:  If ai-context/ does not exist, suggests /memory-init first
```

The sdd-archive output JSON gains one optional field in its summary text:

```
"summary": "Change [name] archived. [N] master specs updated. Memory: [updated|failed|skipped]."
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual | Run `/sdd-archive` on a test change and verify ai-context/ files are updated | Manual execution |
| Manual | Simulate memory-update failure (e.g., delete ai-context/) and verify archive still succeeds with warning | Manual execution |
| Audit | Run `/project-audit` after apply to verify score >= previous | project-audit skill |

No automated tests exist for skills in this project. The testing strategy mirrors the existing pattern: manual verification + project-audit score check.

## Migration Plan

No data migration required. The change modifies skill instruction files only. Deployment via `install.sh` is sufficient.

## Open Questions

None. The proposal is clear, the affected files are well-understood, and the memory-update skill's behavior is stable and documented.
