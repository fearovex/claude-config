# Task Plan: SDD Cycle Context Gaps — System Overhaul

Date: 2026-03-19
Design: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps/design.md

## Progress: 26/26 tasks

---

## Phase 1: sdd-explore Skill Enhancements — Foundation for Context Detection

Enhancement of exploration.md to include three new sections that surface branch diffs, prior attempts, and contradictions.

- [x] 1.1 Modify `~/.claude/skills/sdd-explore/SKILL.md` — Add Step 2: Branch Diff scanning
  Requirement: Scan `git status --short` for modified, staged, and untracked files in the domain being explored; output structured summary to exploration.md `## Branch Diff` section
  Files: `~/.claude/skills/sdd-explore/SKILL.md`
  Spec reference: `specs/sdd-explore-replacement-detection/spec.md` (Branch Diff requirement)

- [x] 1.2 Modify `~/.claude/skills/sdd-explore/SKILL.md` — Add Step 3: Prior Attempts archive scan
  Requirement: Scan `openspec/changes/archive/` for YYYY-MM-DD-* directories; match by keyword overlap with current change; extract proposal/exploration intent summaries; list with outcome classification
  Files: `~/.claude/skills/sdd-explore/SKILL.md`
  Spec reference: `specs/sdd-explore-replacement-detection/spec.md` (Prior Attempts requirement)

- [x] 1.3 Modify `~/.claude/skills/sdd-explore/SKILL.md` — Add Step 4: Contradiction Analysis detection
  Requirement: Compare user's stated intent against loaded specs (from Step 0c) and ai-context/; detect conflicts where user says "remove X" but spec says "X MUST exist"; classify as CERTAIN (explicit contradiction) or UNCERTAIN (ambiguous); report with severity (INFO/WARNING/CRITICAL); do NOT block exploration
  Files: `~/.claude/skills/sdd-explore/SKILL.md`
  Spec reference: `specs/sdd-explore-replacement-detection/spec.md` (Contradiction Analysis requirement)

- [x] 1.4 Modify `~/.claude/skills/sdd-explore/SKILL.md` — Update output format to include all three new sections
  Requirement: Ensure exploration.md template includes `## Branch Diff`, `## Prior Attempts`, `## Contradiction Analysis` sections in the output; existing sections (`## Current State`, `## Recommendation`) preserved
  Files: `~/.claude/skills/sdd-explore/SKILL.md`
  Spec reference: `specs/sdd-explore-replacement-detection/spec.md` (Rules section)

---

## Phase 2: sdd-propose Skill Enhancements — Enumerate Removals and Context

Addition of Supersedes section to proposal.md and preservation of conversation context.

- [x] 2.1 Modify `~/.claude/skills/sdd-propose/SKILL.md` — Add Step 4 extended: Generate Supersedes section
  Requirement: Read exploration.md for contradictions and Branch Diff; infer removals/replacements from user description and contradiction analysis; create proposal.md `## Supersedes` section with three subsections (REMOVED, REPLACED, CONTRADICTED) or state "None — purely additive change"
  Files: `~/.claude/skills/sdd-propose/SKILL.md`
  Spec reference: `specs/sdd-propose-supersedes-section/spec.md` (Supersedes section requirement)

- [x] 2.2 Modify `~/.claude/skills/sdd-propose/SKILL.md` — Add Step 5: Preserve conversation context
  Requirement: Extract conversation context from user input and prior messages (if available); record explicit removal/replacement intents, platform constraints, and cautions in proposal.md `## Context` section; include timestamp
  Files: `~/.claude/skills/sdd-propose/SKILL.md`
  Spec reference: `specs/sdd-propose-supersedes-section/spec.md` (Conversation context preservation requirement)

- [x] 2.3 Modify `~/.claude/skills/sdd-propose/SKILL.md` — Add Step 6: Contradiction Resolution documentation
  Requirement: If exploration.md reports CERTAIN contradictions, add proposal.md `## Contradiction Resolution` section acknowledging each one and describing the resolution approach (contract superseded, breaking change, deprecation period, stakeholder coordination required)
  Files: `~/.claude/skills/sdd-propose/SKILL.md`
  Spec reference: `specs/sdd-propose-supersedes-section/spec.md` (Contradiction conversion requirement)

- [x] 2.4 Modify `~/.claude/skills/sdd-propose/SKILL.md` — Update proposal.md template to always include Supersedes
  Requirement: Ensure generated proposal.md always includes Supersedes section (present in every proposal); if nothing superseded, explicitly states "None — purely additive change"
  Files: `~/.claude/skills/sdd-propose/SKILL.md`
  Spec reference: `specs/sdd-propose-supersedes-section/spec.md` (Supersedes presence rule)

---

## Phase 3: sdd-spec Skill Enhancements — Validate Against Removals

Cross-check spec requirements against proposal Supersedes section to prevent unconfirmed preservation.

- [x] 3.1 Modify `~/.claude/skills/sdd-spec/SKILL.md` — Add Step 1 extended: Validate spec against Supersedes section
  Requirement: Read proposal.md Supersedes section before writing delta spec; for each REMOVED or REPLACED item, check if delta spec includes preservation requirements; for each CONTRADICTED item, verify spec aligns with stated resolution; emit MUST_RESOLVE warning if mismatch found
  Files: `~/.claude/skills/sdd-spec/SKILL.md`
  Spec reference: `specs/sdd-spec-supersedes-validation/spec.md` (Validation requirement)

- [x] 3.2 Modify `~/.claude/skills/sdd-spec/SKILL.md` — Add enforcement rule: No unconfirmed preservation requirements
  Requirement: Ensure sdd-spec does NOT invent "preserve X" requirements that are not explicitly stated in the proposal; if proposal is silent on something, spec MUST NOT add preservation requirement; instead note as pending clarification in risks
  Files: `~/.claude/skills/sdd-spec/SKILL.md`
  Spec reference: `specs/sdd-spec-supersedes-validation/spec.md` (Unconfirmed preservation rule)

- [x] 3.3 Modify `~/.claude/skills/sdd-spec/SKILL.md` — Add graceful handling for missing Supersedes section
  Requirement: If proposal.md lacks Supersedes section (older archived changes), log WARNING-level note and skip validation gracefully; proceed with spec generation
  Files: `~/.claude/skills/sdd-spec/SKILL.md`
  Spec reference: `specs/sdd-spec-supersedes-validation/spec.md` (Rules section, backwards compatibility)

---

## Phase 4: sdd-tasks Skill Enhancements — Generate Removal Tasks

Task generation from proposal Supersedes section for removals and replacements.

- [x] 4.1 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — Add Step 3 new logic: Generate removal tasks from Supersedes
  Requirement: Read proposal.md Supersedes section; for each REMOVED item, generate task titled "Remove: [feature name]" with file paths, deletion acceptance criteria; for each REPLACED item, generate two tasks (Remove old → Implement new) with sequencing dependency
  Files: `~/.claude/skills/sdd-tasks/SKILL.md`
  Spec reference: `specs/sdd-tasks-removal-tasks/spec.md` (Task generation requirement)

- [x] 4.2 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — Add Phase 1 organization: Removals and Replacements first
  Requirement: Ensure removal/replacement tasks are grouped in Phase 1 with explicit sequencing: all removals and old-implementation deletions complete before any Phase 2 additions; enforce dependency that Phase 2 cannot start until Phase 1 complete
  Files: `~/.claude/skills/sdd-tasks/SKILL.md`
  Spec reference: `specs/sdd-tasks-removal-tasks/spec.md` (Removal task ordering requirement)

- [x] 4.3 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — Add task linking to spec requirements
  Requirement: Each removal/replacement task includes reference to corresponding spec requirement by name (e.g., "Linked spec: Requirement: Event-driven membership sync"); enables traceability from spec to implementation
  Files: `~/.claude/skills/sdd-tasks/SKILL.md`
  Spec reference: `specs/sdd-tasks-removal-tasks/spec.md` (Task linking requirement)

- [x] 4.4 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — Add handling for empty Supersedes section
  Requirement: If proposal Supersedes is "None — purely additive change", skip removal task generation; only generate tasks from ADDED spec requirements
  Files: `~/.claude/skills/sdd-tasks/SKILL.md`
  Spec reference: `specs/sdd-tasks-removal-tasks/spec.md` (Rules section)

---

## Phase 5: sdd-ff Skill Enhancements — Orchestrator Context Extraction and Gates

Pre-population of proposal and introduction of contradiction confirmation gate.

- [x] 5.1 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add Step 0 pre-population sub-step: Extract conversation context
  Requirement: Before launching sdd-explore, scan user's `/sdd-ff` request for patterns: "remove X", "no longer X", "delete X" (removals), "mobile must", "not on web" (platform constraints), "provisional pending Z" (context notes); pre-populate skeleton proposal.md with Problem statement, initial Supersedes section (preliminary), and identified constraints
  Files: `~/.claude/skills/sdd-ff/SKILL.md`
  Spec reference: `specs/sdd-ff-contradiction-gate/spec.md` (Pre-population requirement)

- [x] 5.2 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add Step 2 new gate: Contradiction confirmation gate
  Requirement: After exploration completes, check exploration.md `## Contradiction Analysis` for UNCERTAIN contradictions; if found, present user confirmation gate listing each contradiction and asking "Does proposal intend to [action]?"; record user answer in proposal.md `## Decisions` section; if user cannot confirm, halt and request clarification
  Files: `~/.claude/skills/sdd-ff/SKILL.md`
  Spec reference: `specs/sdd-ff-contradiction-gate/spec.md` (Contradiction gate requirement)

- [x] 5.3 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add gate logic: UNCERTAIN vs CERTAIN classification
  Requirement: Contradiction gate only activates for UNCERTAIN contradictions; CERTAIN contradictions are handled in proposal (no gate); prior attempts are logged as INFO (non-blocking); gate is blocking — user must respond Yes/No/Review
  Files: `~/.claude/skills/sdd-ff/SKILL.md`
  Spec reference: `specs/sdd-ff-contradiction-gate/spec.md` (Gate rules)

- [x] 5.4 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Update step sequence and integration with explore
  Requirement: Ensure sdd-ff Step 0 (pre-population) runs before sdd-explore launch; ensure Step 2 (gate) runs after exploration but before propose launch; all previous sdd-ff steps (1, 3, 4, 5, 6) preserved and integrated; no breaking changes to existing flow
  Files: `~/.claude/skills/sdd-ff/SKILL.md`
  Spec reference: `specs/sdd-ff-contradiction-gate/spec.md` (Rules section)

---

## Phase 6: CLAUDE.md Global Orchestrator — Context Extraction Rule

Addition of Unbreakable Rule for conversation context extraction before SDD handoff.

- [x] 6.1 Modify `CLAUDE.md` — Add Unbreakable Rule 6b: Context extraction before SDD handoff
  Requirement: Add new rule after Rule 5 (Feedback Persistence) that states: "When recommending `/sdd-ff` in response to Change Request with removal/replacement language, orchestrator MUST confirm user's intent before recommending command"; rule MUST include confirmation pattern and examples for removal vs. purely additive cases
  Files: `CLAUDE.md`
  Spec reference: `specs/orchestrator-context-extraction/spec.md` (Unbreakable Rule 6b requirement)

- [x] 6.2 Modify `CLAUDE.md` — Extend Intent Classification Decision Table
  Requirement: Update Classification Decision Table to explicitly note removal/replacement language ("remove X", "change X to Y", "replace") as strong Change Request signals; add examples showing how orchestrator detects and gates these cases before /sdd-ff recommendation
  Files: `CLAUDE.md`
  Spec reference: `specs/orchestrator-context-extraction/spec.md` (Intent Classification extension requirement)

---

## Phase 7: Integration Sequencing and Verify Preparation

Preparation for apply phase with strict sequencing and testing artifacts.

- [x] 7.1 Create apply sequencing document — Phase dependencies for sdd-apply
  Requirement: Document strict execution order for apply phase: Phase 1 (sdd-explore) → Phase 2 (sdd-propose) → Phase 3 (sdd-spec) → Phase 4 (sdd-tasks) → Phase 5 (sdd-ff) → Phase 6 (CLAUDE.md); note dependencies: propose MUST complete before spec reads Supersedes; spec MUST complete before tasks consumes proposal; enforcing via apply circuit breaker (halt if phase fails)
  Files: Task plan annotation (this file, Integration Notes section)

- [x] 7.2 Create test scenario for verification phase
  Requirement: Document a concrete test case for verify phase: proposal with Supersedes (REMOVED, REPLACED, CONTRADICTED), Branch Diff showing 2 modified files, Prior Attempts listing one archived change, Contradiction Analysis flagging 1 UNCERTAIN item; describe expected flow through all six skills and expected artifacts in each phase
  Files: Task plan annotation (Implementation Notes section)

---

## Phase 8: Documentation and Backwards Compatibility Verification

Final documentation and backwards compatibility checks.

- [x] 8.1 Add backwards compatibility verification notes
  Requirement: Verify and document that all six skills gracefully tolerate missing new sections in archived proposal.md and exploration.md files (old format); ensure propose, spec, tasks all have fallback logic to skip new sections if absent; ensure sdd-ff pre-population does not break if user invokes without context
  Files: Task plan annotation (Blockers section)

- [x] 8.2 Prepare ADR 040 documentation (conditional)
  Requirement: If sdd-design creates ADR 040 documenting context-contradiction handling convention, verify it is created during design phase; if not auto-created, manually create after apply with title "Architecture Decision 040: Context Contradiction Handling Convention in SDD Cycle" and include artifact contracts, phase flow, and motivation from this design
  Files: `docs/adr/040-context-contradiction-handling-convention.md` (optional; created by sdd-design or manual Step 4 after apply)

---

## Implementation Notes

**Critical Sequencing Rules:**

1. **Propose must complete before Spec/Tasks read Supersedes section**: sdd-apply Phase 1 (explore) → Phase 2 (propose) — enforce proposal.md is written before phases 3–4 attempt to read it
2. **Backwards compatibility mandatory**: Every modified skill must handle missing new sections gracefully (older archived changes won't have new artifacts)
3. **No partial deployments**: If any skill update fails during apply, halt and do not proceed to next phase; use circuit breaker pattern
4. **Git availability optional**: Branch Diff step in sdd-explore gracefully skips if git unavailable (log INFO, continue with empty section)
5. **Contradiction gates are blocking only for UNCERTAIN**: CERTAIN contradictions are handled in proposal; prior attempts are informational only

**Phase Integration Map:**

```
Phase 1: sdd-explore
  └─ Output: exploration.md with Branch Diff, Prior Attempts, Contradiction Analysis

Phase 2: sdd-propose  ← depends on Phase 1
  └─ Input: exploration.md + pre-seeded proposal.md (from sdd-ff Step 0)
  └─ Output: proposal.md with Supersedes, Context, Contradiction Resolution

Phase 3: sdd-spec  ← depends on Phase 2
  └─ Input: proposal.md Supersedes section
  └─ Validation: Ensure no unconfirmed preservation requirements
  └─ Output: spec.md respecting Supersedes boundaries

Phase 4: sdd-tasks  ← depends on Phases 2 & 3
  └─ Input: proposal.md Supersedes + exploration.md
  └─ Output: tasks.md with Phase 1 (removals) → Phase 2+ (additions)

Phase 5: sdd-ff
  └─ Pre-population Step 0 → explore (Phase 1)
  └─ Contradiction gate Step 2 → after explore, before propose
  └─ Consumes: pre-seeded proposal.md, exploration.md
  └─ Output: Updated proposal.md with Decisions section if gate triggered

Phase 6: CLAUDE.md
  └─ Global rule: orchestrator extracts context before /sdd-ff recommendation
  └─ Feeds into sdd-ff Step 0 pre-population
```

**Design Decisions Implementer MUST Keep in Mind:**

- Supersedes section is ALWAYS present in proposal.md, never omitted (even if empty: "None — purely additive")
- Contradiction Analysis sections in exploration.md are informational; they do NOT block exploration (status remains `ok` or `warning`)
- Removal tasks MUST sequence before any addition tasks; enforce Phase 1 dependency barrier
- Prior attempts in exploration.md inform user awareness but do NOT trigger a gate (only UNCERTAIN contradictions gate)
- Conversation context extraction in sdd-ff is pattern-based (not ML); limited to explicit strings like "remove", "mobile must", "provisional"

---

## Blockers

None. All six skills exist and are modifiable. Git is typically available in most environments, with graceful fallback in explore. No external dependencies or data migrations required. Backwards compatibility verified during Phase 8.

---

## Appendix: Test Scenario for Verify Phase

**Scenario**: Auth flow replacement with contradictions and prior attempts

**Input to sdd-ff**: `/sdd-ff remove periodic membership refresh hook, redirect to login on 401 instead`

**Expected exploration.md output:**
```
## Branch Diff
1 modified file: src/auth/auth.service.ts
1 staged file: src/hooks/usePeriodicRefresh.ts (pending deletion)

## Prior Attempts
Found prior attempt: 2026-02-15-auth-flow-v1 (exploration complete, abandoned, reason: "hook removal broke membership polling")

## Contradiction Analysis
- Item: Remove usePeriodicRefresh
  Status: UNCERTAIN — archived note says "Membership polling unaffected", but current context says remove hook
  Severity: WARNING
  Resolution: Requires user confirmation
```

**Expected proposal.md output:**
```
## Supersedes

### REMOVED

- **Periodic Membership Refresh Hook** (src/hooks/usePeriodicRefresh.ts)
  Reason: Hook no longer needed; membership sync now event-driven

## Context

### Explicit Intents

- **Remove usePeriodicRefresh hook**: User stated this is obsolete post-integration

## Decisions

### Hook Removal Confirmation
**Date**: 2026-03-19T15:42Z
**User answer**: Confirmed — hook MUST be removed entirely
```

**Expected tasks.md output:**
```
## Phase 1: Removals

- [ ] 1.1 Remove usePeriodicRefresh hook from src/hooks/
  Linked spec: "Requirement: Event-driven membership sync"
  Files: src/hooks/usePeriodicRefresh.ts (DELETE), src/auth/auth.module.ts (remove registration)

## Phase 2: Implementation

- [ ] 2.1 Implement 401 redirect to login in src/auth/auth.service.ts
  Linked spec: "Requirement: Redirect on 401"
```

**Verification Criteria:**
- [x] Exploration includes all three new sections with accurate content
- [x] Proposal includes Supersedes, Context, Decisions, and Contradiction Resolution
- [x] Spec validation detects no preservation requirement conflicts
- [x] Tasks include removal Phase 1 and addition Phase 2 with ordering enforced
- [x] No breaking changes to existing skills or archived changes
