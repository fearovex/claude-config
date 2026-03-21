# Technical Design: SDD Cycle Context Gaps — System Overhaul

Date: 2026-03-19
Proposal: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps/proposal.md

## General Approach

Implement six coordinated skill modifications and one global orchestrator rule injection to handle replacement changes and context contradictions in the SDD cycle. The core strategy is to pass contextual metadata through the artifact chain (explore → propose → spec → tasks) and introduce explicit gates in the orchestrator and phase skills for contradiction detection.

Each phase skill is enhanced with new sections or rules that consume upstream artifacts while maintaining backward compatibility with existing archived changes. The sequencing enforces a strict dependency: propose must complete before spec/tasks can validate their cross-references.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Artifact contract mechanism | File-based sections in exploration.md, proposal.md, and tasks.md | Database/environment variables, conversation context only | Maintains project convention of artifact-over-conversation communication; searchable and auditable within SDD cycle; compatible with async sub-agent execution |
| Supersedes section presence | Always exist in proposal.md; if nothing superseded, explicitly state "None — purely additive change" | Optional Supersedes section, infer from absence | Explicit presence prevents ambiguity; users are forced to think about what they're replacing, not just what they're adding; matches the pattern of success criteria (always present even if empty) |
| Contradiction gate behavior | Gate only on UNCERTAIN contradictions; log prior attempts as INFO | Gate on any contradiction, gate on prior attempts separately | UNCERTAIN contradictions need user decision; prior attempts are informational to avoid repeated failures but not blocking; matches feedback-session rule pattern (explicit opt-out, not opt-in) |
| Branch-local diff detection | Use git to scan working tree diff when proposal.md is present | Always scan archive, require explicit flag to scan branch | Git diff is precise and already available; archive check is optional add-on for cross-session awareness; flag not needed—archive check is always beneficial |
| Conversation context extraction | Pre-populate proposal.md before explore launch (sdd-ff Step 0 sub-step) | Extract during propose phase, extract inline in CLAUDE.md | Pre-population in sdd-ff allows explore to read context without multi-phase handoff; cleaner than inline rule changes; compatible with unified flow |
| Skill dependency sequencing | Enforce strict order in tasks.md and sdd-apply rule set | Let apply execute in parallel or flexible order | Propose→Spec→Tasks have data dependencies (Supersedes section must be written before spec reads it); parallel execution would risk reading undefined sections; explicit sequencing prevents integration failures |
| ADR generation trigger | Create ADR 040 when design.md decision table contains keywords: "context", "contradiction", "replacement", "artifact", "convention" | Use heuristic score, create for all architectural decisions | Pattern-based keyword matching aligns with existing sdd-design ADR detection logic; these keywords signal decisions that future sessions will need to understand and respect |
| CLAUDE.md rule location | Extend Unbreakable Rules section with a new rule 6b about conversation context extraction | Create new Orchestrator section, create separate rule file | Unbreakable Rules are loaded at session start and don't require additional file I/O; rule 6 (feedback persistence) is related, so 6b fits naturally; consistency with existing rule numbering |

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ sdd-ff invocation with /sdd-ff <description>                                │
│ ├─ Step 0: Extract conversation context (remove, replace, careful with...) │
│ │           Pre-populate proposal.md with context sections                  │
│ └─ Step 1: Launch sdd-explore (reads pre-seeded proposal.md)               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ sdd-explore output: exploration.md                                          │
│ ├─ Step 2: Scan working tree diff (branch-local implementation)             │
│ ├─ Step 3: Scan openspec/changes/archive for prior attempts                │
│ ├─ Step 4: Identify contradictions (prior context vs. user request)        │
│ └─ Output sections:                                                         │
│    ├─ Current State (existing)                                              │
│    ├─ Branch Diff (NEW) — git diff --name-only for modified files          │
│    ├─ Prior Attempts (NEW) — list of archived attempts with outcomes      │
│    ├─ Contradiction Analysis (NEW) — CERTAIN/UNCERTAIN status per item    │
│    └─ Recommendation (existing)                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ sdd-propose reads exploration.md + pre-seeded proposal context              │
│ ├─ Step 4: Populate proposal.md Supersedes section (NEW)                   │
│ │          ├─ Enumerate removals (inferred from "remove X" in context)     │
│ │          ├─ Enumerate replacements (from Branch Diff + user request)     │
│ │          └─ Format: Supersedes / None — purely additive / List items    │
│ ├─ Step 5: Preserve conversation context (mobile constraints, careful with)│
│ └─ Step 7: Document risk of UNCERTAIN contradictions (NEW)                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ sdd-spec + sdd-design (parallel)                                           │
│                                                                              │
│ sdd-spec reads proposal.md Supersedes section:                              │
│ ├─ Step 1: Validate that no spec scenario says "preserve X"                │
│ │          when proposal says "remove X"                                    │
│ └─ Rules (NEW): Reject spec.md with unconfirmed preservation requirements  │
│                                                                              │
│ sdd-design (no changes to core logic — this phase is unaffected)            │
│ └─ Step 4: ADR Detection — if Keywords match, create ADR 040               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ sdd-tasks reads proposal.md Supersedes + exploration.md sections             │
│ ├─ Step 3: Generate removal tasks from Supersedes section (NEW)            │
│ │          (one task per removal, e.g., "Remove usePeriodicRefresh hook")  │
│ └─ Output: tasks.md includes both addition and removal tasks               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│ sdd-apply executes tasks in strict sequence:                                │
│ Phase 1: Execute propose updates (finalize all Supersedes sections)        │
│ Phase 2: Execute spec validation (cross-check Supersedes)                  │
│ Phase 3: Execute tasks (consume finalized proposal, generate removal tasks)│
│                                                                              │
│ Circuit breaker: if Phase N fails, halt and report blocking error          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `~/.claude/skills/sdd-explore/SKILL.md` | Modify | Add Step 2 (Branch Diff scan), Step 3 (Prior Attempts detection), Step 4 (Contradiction Analysis); expand Process section |
| `~/.claude/skills/sdd-propose/SKILL.md` | Modify | Step 4 extended: add Supersedes section generation; Step 7 added: document UNCERTAIN contradictions; conversation context preservation |
| `~/.claude/skills/sdd-spec/SKILL.md` | Modify | Step 1 extended: add cross-check rule against proposal Supersedes section; validation logic in Rules section |
| `~/.claude/skills/sdd-tasks/SKILL.md` | Modify | Step 3 new logic: infer removal tasks from proposal Supersedes section; add to task matrix |
| `~/.claude/skills/sdd-ff/SKILL.md` | Modify | Step 0 new sub-step: extract conversation context, pre-populate proposal.md; Step 2: add contradiction confirmation gate before launching propose |
| `CLAUDE.md` (global) | Modify | Extend Unbreakable Rules Rule 5 with Rule 6b: orchestrator must extract conversation context before confirming /sdd-ff |
| `docs/adr/040-context-contradiction-handling-convention.md` | Create | Document the unified context-contradiction handling convention and artifact contracts for future sessions |

## Interfaces and Contracts

### exploration.md — Three New Sections

```markdown
## Branch Diff
[Git diff output showing modified files in current branch]
Files:
- src/auth/auth.service.ts (modified)
- src/hooks/usePeriodicRefresh.ts (deleted)
- ...

## Prior Attempts
[List of archived prior attempts with outcomes]
- 2026-02-15-auth-flow-v1: FAILED — hook removal broke membership polling
- 2026-02-20-auth-flow-v2: ABANDONED — mobile constraints not met
- ...

## Contradiction Analysis
[Analysis of contradictions between user request and prior context]
- Item: Remove usePeriodicRefresh hook
  Status: UNCERTAIN — archived note says "Membership polling unaffected", but current context says "remove hook"
  Resolution: Requires user confirmation
```

### proposal.md — New Supersedes Section

```markdown
## Supersedes

If nothing is superseded:
```
None — this is a purely additive change.
```

If replacements exist:
```
| Item | Removal | Replacement | Reason |
|------|---------|-------------|--------|
| Authentication hook | usePeriodicRefresh | None (feature removed) | Not needed post-EWP integration |
| Mark Complete behavior | In-memory simulation | SharePoint write-back | EWP integration complete |
```

### tasks.md — Removal Task Entries

For each removal in Supersedes, generate a task:

```markdown
### Phase X: Removals

- [ ] TODO - Remove usePeriodicRefresh hook from src/hooks/
  **Rationale**: Per proposal Supersedes; no longer needed post-EWP integration
  **Files affected**: src/hooks/usePeriodicRefresh.ts, src/auth/auth.module.ts
  **Verification**: Unit tests pass; no runtime errors in membership flow
```

### sdd-ff Step 0 — Conversation Context Extraction

```
Extract patterns from conversation:
  - "remove X" → add to removals
  - "careful with Y" → add to constraints
  - "mobile must not..." → add to constraints
  - "provisional, pending Z" → add to context notes

Pre-populate proposal.md with:
  ## Context Notes (from conversation)
  - Constraints: [list]
  - Prior state notes: [list]
  - Removals mentioned: [list]
```

### sdd-ff Step 2 — Contradiction Gate

```
IF exploration.md contains UNCERTAIN contradictions:
  Present confirmation to user:
    "Exploration found UNCERTAIN contradiction(s):
     - Item X: archived context says Y, but you said Z
     Ready to proceed? [Yes / No / Review context]"
  IF user says No → halt and ask for clarification
  IF user says Review → show contradiction details
  IF user says Yes → record decision and continue
ELSE
  Continue to propose phase
```

## Testing Strategy

| Layer | What to test | Tool | Notes |
|-------|--------------|------|-------|
| Unit | sdd-explore diff scan logic | Manual file inspection + git commands | Test with a branch containing modified files |
| Unit | Prior attempts archive search | Manual filesystem walk + pattern matching | Test with 3+ archived changes |
| Unit | Contradiction detection heuristics | String matching against exploration.md sections | Test CERTAIN vs UNCERTAIN classification |
| Unit | Supersedes section generation | sdd-propose file write inspection | Test with replacement + removal + additive scenarios |
| Integration | Full cycle: propose → spec → tasks | Create test scenario with all sections present | Verify Supersedes section flows through to tasks.md |
| Integration | Backwards compat: old exploration.md without new sections | Run propose on archived changes | Should tolerate missing Branch Diff, Prior Attempts, Contradiction Analysis |
| Acceptance | User gate on UNCERTAIN contradictions | sdd-ff invocation + user response | Confirm gate presents correctly and halts execution |
| Acceptance | ADR 040 creation by sdd-design | sdd-design invocation + docs/adr check | Confirm ADR file created with correct numbering and content |

## Migration Plan

### No data migration required.
Archived changes (pre-overhaul) remain compatible:
- Old exploration.md without new sections: propose skips sections gracefully
- Old proposal.md without Supersedes: sdd-tasks generates empty removal task list
- Backwards compatibility is enforced in each skill's Step 1

### Rollout sequence (enforced in sdd-apply):
1. Update sdd-explore SKILL.md
2. Update sdd-propose SKILL.md
3. Update sdd-spec SKILL.md
4. Update sdd-tasks SKILL.md
5. Update sdd-ff SKILL.md
6. Update CLAUDE.md (global orchestrator rule)
7. Create ADR 040 (via sdd-design output or manual Step 4)

Apply will halt if any phase fails; no partial deployments.

## Open Questions

1. **Should prior attempts be searchable by keyword?**
   - Current design: list all archived changes; let user read summaries
   - Alternative: implement full-text search on archive metadata
   - **Resolution**: Start with simple list; search is future work (ADR 034 mentions similar scalability triggers)

2. **What if Supersedes section is misused (contains additions instead of removals)?**
   - Current design: sdd-tasks trusts proposal.md; sdd-verify step tests outcomes
   - Alternative: Add validation rule in sdd-propose to reject Supersedes entries that don't match removal/replacement patterns
   - **Resolution**: Validate in sdd-propose Step 4 — if an entry claims to "remove" but describe adding, raise MUST_RESOLVE warning

3. **Should conversation context pre-population be user-editable before explore?**
   - Current design: sdd-ff populates proposal.md Step 0, user sees it during explore/propose
   - Alternative: Show context extraction to user before launching explore for confirmation
   - **Resolution**: Pre-populate without gate (similar to feedback-session handling); user can edit in proposal.md before approving

4. **What happens if git is unavailable or branch diff is empty?**
   - Current design: sdd-explore gracefully skips branch diff with INFO note
   - Alternative: Require git; halt if unavailable
   - **Resolution**: Non-blocking; if git unavailable, log INFO and continue; empty diff is valid (new feature on clean branch)

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| **Integration gap if sequencing is wrong** | Medium | Apply updates spec before propose finishes → specs fail | Phase dependencies strict in tasks.md; sdd-apply validates Phase 1 completion before Phase 2 start; circuit breaker halts on error |
| **User confusion with Supersedes section** | Low | Users unfamiliar with the section may omit it or misuse it | sdd-propose Step 4 includes help text and examples; default template clarifies intent; validation rule in Step 4 catches common errors |
| **Backwards compat with archived proposals** | Low | Old proposal.md without Supersedes won't have removals | New Supersedes is optional for old proposals; tasks.md generation tolerates missing section (treats as empty list) |
| **Breaking active SDD cycles** | Low | User in-progress /sdd-ff when overhaul installs | Changes are live immediately; users' in-progress cycles inherit new rules; sdd-ff is re-startable — user can re-run to pick up context extraction |
| **Proposal verification complexity** | Medium | Verify step must test all six skills working together | Create test scenario with removal + replacement + contradiction + prior attempts; verify passes all criteria |
| **Documentation lag** | Low | CLAUDE.md out of sync with skill updates | Proposal lists exact CLAUDE.md rules needed; sdd-design surfaces as action item; ADR 040 documents convention |
| **False positives in contradiction detection** | Low–Medium | Contradiction analysis flags non-contradictions as UNCERTAIN | Implement specific heuristic: contradiction = "prior context says X" AND "user request says NOT X"; validate heuristics in integration testing |

## Open Questions (Design Clarifications)

1. **How are prior attempts selected for display?**
   - Current: All archived changes in openspec/changes/archive/
   - Future: Could filter by keyword match on slug
   - Recommendation: Show all; user scans for relevance (simple and transparent)

2. **What format for "prior attempts" display?**
   - Archive directory structure: `YYYY-MM-DD-[slug]/`
   - Display in exploration.md: `[YYYY-MM-DD slug]: [outcome summary]`
   - Outcome summary from: verify-report.md `## Verification Results` or a closure note in the archived change
   - Recommendation: Read closure notes if present; fallback to folder list if absent (non-blocking)

3. **Contradiction detection: string matching vs semantic understanding?**
   - Current design: String patterns ("remove X", "provisional pending", "unaffected")
   - Full semantic understanding would require context merging across phases
   - Recommendation: Start with string patterns and explicit UNCERTAIN classification; escalate unclear cases to user via gate

4. **Should sdd-ff gate be blocking or informational for UNCERTAIN contradictions?**
   - Current design: BLOCKING gate (user must respond Yes/No/Review)
   - Alternative: Informational log, continue automatically
   - Recommendation: BLOCKING gate (rule 5b in CLAUDE.md — feedback sessions require user confirmation; this is a special case of feedback)
