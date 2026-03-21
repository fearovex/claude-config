# Closure: feedback-sdd-cycle-context-gaps

Start date: 2026-03-19
Close date: 2026-03-19

## Summary

Addressed six interconnected architectural gaps in the SDD orchestrator and phase skills for handling replacement changes, removal intents, and context contradictions. Added Branch Diff, Prior Attempts, and Contradiction Analysis to sdd-explore; Supersedes section and conversation context extraction to sdd-propose; supersedes validation to sdd-spec; removal task generation to sdd-tasks; contradiction gate to sdd-ff; and context extraction rule to the orchestrator.

## Modified Specs

| Domain | Action | Change |
| -------- | ---------------------- | ------------- |
| sdd-explore-replacement-detection | Created | Branch Diff, Prior Attempts, Contradiction Analysis sections in exploration.md |
| sdd-propose-supersedes-section | Created | Supersedes section, Context section, and Contradiction Resolution section in proposal.md |
| sdd-tasks-removal-tasks | Created | Explicit removal/replacement task generation from proposal Supersedes section |
| sdd-phase-context-loading | Modified | sdd-spec supersedes validation — validates delta spec against proposal Supersedes section |
| sdd-orchestration | Modified | sdd-ff contradiction gate, pre-populated proposal skeleton before explore launch |
| orchestrator-behavior | Modified | Context extraction rule (Rule 7) for removal/replacement language before /sdd-ff handoff |
| index.yaml | Modified | Three new domain entries added: sdd-explore-replacement-detection, sdd-propose-supersedes-section, sdd-tasks-removal-tasks |

## Modified Code Files

- `skills/sdd-explore/SKILL.md` — Branch Diff, Prior Attempts, Contradiction Analysis sections
- `skills/sdd-propose/SKILL.md` — Supersedes section, Context section, Contradiction Resolution
- `skills/sdd-spec/SKILL.md` — Supersedes validation step
- `skills/sdd-tasks/SKILL.md` — Removal task generation from Supersedes
- `skills/sdd-ff/SKILL.md` — Contradiction gate, proposal pre-population Step 0
- `CLAUDE.md` — Unbreakable Rule 7: context extraction before SDD handoff

## Key Decisions Made

- Exploration is the right phase to detect branch diffs, prior attempts, and contradictions (read-only, non-destructive)
- Contradictions are classified as CERTAIN or UNCERTAIN; only UNCERTAIN ones trigger a user gate in sdd-ff
- The Supersedes section in proposal.md is the authoritative scope boundary for removal/replacement intent
- Pre-population of a skeleton proposal.md before exploration ensures removal language is captured from the start
- Context extraction rule in the orchestrator is inline CLAUDE.md logic — no new skill or artifact required

## Lessons Learned

- SDD phase skills were designed for purely additive changes; replacement and removal semantics were architectural blind spots
- The spec authoring phase (sdd-spec) had no mechanism to distinguish "preserve existing behavior" from "user explicitly wants this gone"
- Cross-session context loss (new sessions not finding prior archived attempts) is a systematic gap in how sdd-explore loads context

## User Docs Reviewed

NO — this change affects SDD phase skills and orchestrator behavior, not user-facing workflow documentation (scenarios.md, quick-reference.md, onboarding.md).
