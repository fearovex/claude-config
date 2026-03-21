# Exploration: SDD Cycle Context Gaps (Part 6) — Orchestrator & Spec GC Feedback

## Governance Summary

- Governance loaded: 7 unbreakable rules, tech stack: Markdown + YAML + Bash, intent classification: enabled
- Project CLAUDE.md found at: C:\Users\juanp\claude-config\CLAUDE.md
- Last updated: 2026-03-12 (7 days ago — context current)

## Handoff Context

This exploration is driven by two feedback proposals created in session 2026-03-19-feedback-sdd-cycle-context-gaps-p6:

### Proposal 6a: Orchestrator Must Read Relevant Specs Before Answering Questions
- **Decision triggered**: Orchestrator answers questions from code alone, not from specs
- **Goal**: Spec-first Q&A — orchestrator reads matching specs before answering questions about project domains
- **Success criteria**:
  - When user asks about "welcome video completion", orchestrator reads `openspec/specs/fy-video-wiring/spec.md` first
  - Spec contradictions are surfaced explicitly to user
  - Questions about unmapped domains still work (no extra reads)
- **Target files**: CLAUDE.md, sdd-explore/SKILL.md
- **Constraints**: Should not affect Change Requests or Explorations; only Questions

### Proposal 6b: New Skill sdd-spec-gc — Spec Garbage Collection
- **Decision triggered**: Master specs grow indefinitely; obsolete/provisional/contradictory requirements accumulate
- **Goal**: Create a skill to audit and clean specs
- **Success criteria**:
  - `/sdd-spec-gc domain` identifies PROVISIONAL/ORPHANED_REF/CONTRADICTORY requirements
  - Dry-run reports candidates before write
  - User can confirm removals; changelog records what was removed
- **Target files**: New skill at `~/.claude/skills/sdd-spec-gc/SKILL.md`; register in CLAUDE.md
- **Constraints**: Read-only until user confirms; no rephrase/consolidate (removals only)

## Current State

### Spec-first Q&A in existing codebase

The orchestrator's CLAUDE.md currently has:
- Intent classification routing (Meta-Command, Change Request, Exploration, Question)
- A rule that reads ai-context/ files at session start
- **No rule for reading specs before answering Questions**

`sdd-explore` already implements spec-context preload (Step 0 sub-step):
- Reads `openspec/specs/index.yaml` to find matching domains (stem matching)
- Loads top 3 matching specs as authoritative behavioral contracts
- Marks them as supplementary context

This pattern exists for explore but is absent from the Question pathway.

### Spec accumulation problem

Observed in recent sessions:
- `openspec/specs/fy-video-wiring/spec.md` contains requirements marked "provisional pending EWP integration"
- `openspec/specs/orchestrator-behavior/spec.md` has been through multiple cycles (2026-02-26, 2026-03-04, 2026-03-10, 2026-03-14)
- No tooling exists to flag, surface, or remove stale requirements
- No GC process exists; master specs are append-only

### Skill ecosystem status

Current SDD skills:
- 8 SDD phase skills: sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive
- 2 orchestrator skills: sdd-ff, sdd-new
- No spec maintenance skill exists

`sdd-spec-gc` would be a new **maintenance skill** (similar category to meta-tools like project-audit, project-fix).

## Branch Diff

Files modified in current branch relevant to this feedback change:

```
CLAUDE.md (modified)
ai-context/architecture.md (modified)
ai-context/changelog-ai.md (modified)
docs/adr/README.md (modified)
openspec/changes/spec-hygiene/exploration.md (deleted)
openspec/specs/index.yaml (modified)
openspec/specs/orchestrator-behavior/spec.md (modified)
openspec/specs/sdd-archive-execution/spec.md (modified)
openspec/specs/sdd-orchestration/spec.md (modified)
openspec/specs/sdd-phase-context-loading/spec.md (modified)
skills/sdd-archive/SKILL.md (modified)
skills/sdd-explore/SKILL.md (modified)
skills/sdd-ff/SKILL.md (modified)
skills/sdd-propose/SKILL.md (modified)
skills/sdd-spec/SKILL.md (modified)
skills/sdd-tasks/SKILL.md (modified)
docs/adr/037-context-handoff-between-sessions-convention.md (untracked — new)
docs/adr/038-sdd-archive-orphan-validation-convention.md (untracked — new)
docs/adr/039-orphan-change-disposition-convention.md (untracked — new)
docs/adr/040-context-contradiction-handling-convention.md (untracked — new)
```

These represent changes from prior SDD cycles (spec-hygiene, context-handoff, etc.) that are being merged in this session.

## Prior Attempts

No prior attempts related to "spec garbage collection" or "orchestrator spec reading" found in archive.

Related prior work:
- 2026-03-14-specs-search-optimization: implemented spec index (openspec/specs/index.yaml) for stem-based spec discovery
- 2026-03-14-add-clarification-gate-for-ambiguous-inputs: added clarification gate to orchestrator classification
- 2026-03-10-sdd-project-context-awareness: added Step 0 project context loading to all SDD phase skills

Neither of these prior cycles delivered spec-first Q&A for the orchestrator or a GC skill.

## Contradiction Analysis

### Proposal 6a contradictions

**Item**: Spec-first Q&A should only apply to Questions (not Change Requests)
- **Status**: CERTAIN — proposal explicitly states "This rule is additive — it does not change how the orchestrator handles Change Requests or Explorations, only Questions"
- **Severity**: INFO
- **Resolution**: Verified — the proposed rule correctly scopes to Question routing only

**Item**: Keyword matching heuristic may create false positives (spec loaded when not relevant)
- **Status**: UNCERTAIN — proposal suggests heuristic matching but does not define precision requirement
- **Severity**: WARNING
- **Resolution**: Can be addressed in sdd-ff phase (when defining exact matching algorithm); exploration documents the concern

### Proposal 6b contradictions

**Item**: ORPHANED_REF detection requires codebase search — may be slow or inconclusive
- **Status**: CERTAIN — proposal acknowledges "codebase search is best-effort" and flag as UNCERTAIN rather than remove
- **Severity**: INFO
- **Resolution**: Proposal already includes safeguard; no contradiction

**Item**: No mechanism to prevent re-accumulation after GC (prevents regression)
- **Status**: UNCERTAIN — proposal suggests recording GC timestamp in comment, but no recurring process defined
- **Severity**: WARNING
- **Resolution**: Can be addressed in proposal or design phase (e.g., recommend cadence in CLAUDE.md)

No CERTAIN contradictions detected.

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `CLAUDE.md` (Question routing) | MEDIUM — adds step to Q&A path | New rule: check index.yaml + read matching specs before answering |
| `sdd-explore/SKILL.md` | LOW — documents existing behavior | Spec-first pattern already implemented; exploration phase is model for other phases |
| `~/.claude/skills/sdd-spec-gc/SKILL.md` | HIGH — new file | Creates new maintenance skill |
| `openspec/specs/index.yaml` | LOW — read-only for Q&A feature | Already exists; sdd-spec-gc will depend on it |
| Existing specs (e.g., `fy-video-wiring/spec.md`) | HIGH — target for cleanup | Will accumulate PROVISIONAL/ORPHANED_REF candidates once sdd-spec-gc is available |

## Analyzed Approaches

### Approach A: Minimal Q&A enhancement (Proposal 6a only)

**Description**: Add spec-first Q&A to orchestrator Question routing without creating a GC skill. Specs are never cleaned; accumulation continues.

**Pros**:
- Low implementation cost (one rule in CLAUDE.md)
- Improves answer accuracy immediately
- No new skill needed
- Solves the "contradicts spec" problem

**Cons**:
- Does NOT address spec accumulation (proposal 6b problem still unsolved)
- Over time, specs become harder to read (more noise)
- Contradictions accumulate faster if not periodically cleaned
- User can't act on "this spec is stale" feedback

**Estimated effort**: Low
**Risk**: Low

### Approach B: Full spec maintenance (both proposals)

**Description**: Implement both proposal 6a (Q&A enhancement) and proposal 6b (GC skill). Users can query specs accurately AND clean them periodically.

**Pros**:
- Solves both "answer accuracy" and "spec bloat" problems
- GC skill is reusable (works on any project)
- Empowers users to maintain spec quality
- Reflects the SDD philosophy: if specs are the authority, they deserve maintenance tooling

**Cons**:
- Requires implementing a new skill (higher effort)
- GC requires codebase search (orphan detection is best-effort)
- Requires user discipline to run GC periodically
- Two moving parts (orchestrator rule + skill)

**Estimated effort**: Medium
**Risk**: Low (GC is non-destructive until confirmed, both are optional)

### Approach C: Defer GC, implement Q&A only initially

**Description**: Implement proposal 6a now (quick win). Mark proposal 6b as future work; separate SDD cycle to implement GC later.

**Pros**:
- Ships value faster (spec-first Q&A available sooner)
- Lower initial effort and risk
- GC can benefit from more field experience before design

**Cons**:
- Splits work across sessions (context switching)
- Q&A improvement creates pressure to clean specs (users see stale requirements) but tool is unavailable
- Violates principle of addressing feedback holistically

**Estimated effort**: Low (now) + Medium (later)
**Risk**: Low

## Recommendation

**Approach B: Full spec maintenance (both proposals)** is recommended.

Rationale:
1. Both proposals were created in the same feedback session addressing interconnected problems
2. The orchestrator's Q&A enhancement naturally surfaces stale specs (user sees "provisional pending X" in answers)
3. Users will naturally ask "how do I clean this?" — the GC skill directly answers that
4. Implementing both together provides a complete mental model: specs are authoritative AND maintainable
5. Risk is low: GC is non-destructive until confirmed; both Q&A and GC follow established SDD patterns (step-by-step, user confirmation gates)

## Identified Risks

- **Spec matching heuristic precision**: Keyword matching in index.yaml may load irrelevant specs
  - Impact: User sees tangentially related specs in Q&A
  - Mitigation: Proposal 6a includes explicit keyword matching heuristic; design phase can refine with examples

- **GC ORPHANED_REF false negatives**: Codebase search may miss references in comments or string literals
  - Impact: Some stale requirements are not flagged for removal
  - Mitigation: Proposal 6b marks UNCERTAIN orphans (not removed). User can manually review.

- **Re-accumulation**: After GC runs, nothing prevents new provisional/stale requirements from accumulating again
  - Impact: Specs grow stale again over time
  - Mitigation: Design phase can recommend cadence in CLAUDE.md; future work: automated linting rule

- **Codebase search performance**: Searching large codebases for orphan references could be slow
  - Impact: sdd-spec-gc may timeout on very large projects
  - Mitigation: Proposal limits to `[domain]` mode (scan one spec) and `--all` mode (scan all); design phase can add cancellation/timeout handling

## Open Questions

1. **How precise should keyword matching be?**
   - Proposal 6a mentions keyword arrays in index.yaml but does not define minimum precision (false positive rate)
   - Design phase should define: "Spec is loaded if at least N keywords match" (e.g., N=1, N=2)

2. **Should sdd-spec-gc run interactively or in batch mode?**
   - Proposal 6b describes interactive dry-run + user confirmation
   - Edge case: what if user is running GC on 50+ domains (--all mode)? Should individual specs be confirmed one-by-one or bulk?

3. **What is the recommended GC cadence?**
   - Proposal 6b mentions "every 5-10 archived cycles" but doesn't document this in CLAUDE.md
   - Should this be a documented convention in ai-context/conventions.md or openspec/config.yaml?

## Ready for Proposal

**Yes.** Both proposals are well-formed, address interconnected problems, and have low risk. Exploration identifies no blocking contradictions. The feedback session correctly captured two complementary improvements to spec handling.

Proceed to `/sdd-propose` phase.
