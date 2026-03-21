# Proposal: 2026-03-19-feedback-sdd-cycle-context-gaps-p6

Date: 2026-03-19
Status: Draft

## Intent

Address two interconnected feedback items on spec authority and maintenance: (1) orchestrator must read relevant specs before answering questions to reduce answer contradictions; (2) create a spec garbage collection skill to prevent indefinite accumulation of stale/provisional requirements.

## Motivation

The orchestrator's question-answering pathway currently relies on codebase knowledge and ai-context/ files alone, without consulting the authoritative spec layer defined in `openspec/specs/`. This creates a gap where user questions about domain behavior are answered without checking the specification that defines that behavior — leading to contradictions when specs are updated but Q&A answers are not.

Additionally, `openspec/specs/` grows indefinitely. Specs marked PROVISIONAL (pending integration), ORPHANED_REF (no longer referenced in code), or CONTRADICTORY (conflicting with other specs) accumulate over time because no tooling exists to audit, flag, or remove them. This causes specs to become harder to navigate and maintain.

Both problems reflect the same philosophical issue: if specs are the authoritative source of domain behavior, the system must actively use them in Q&A and actively maintain them against drift.

## Supersedes

None — this is a purely additive change.

## Scope

### Included

1. **Spec-first Q&A enhancement (Proposal 6a)**
   - Modify orchestrator CLAUDE.md: add new rule to Question routing pathway
   - When user asks a question about a domain topic, orchestrator reads `openspec/specs/index.yaml` to find matching specs (stem-based keyword matching)
   - Load top 3 matching specs as authoritative behavioral context before answering
   - Surfaced contradictions explicitly to user if spec says X but codebase is doing Y
   - No impact on Change Request or Exploration routing

2. **New skill: sdd-spec-gc (Proposal 6b)**
   - Create new skill at `~/.claude/skills/sdd-spec-gc/SKILL.md`
   - Implement `/sdd-spec-gc [domain]` — audit a single domain spec
   - Implement `/sdd-spec-gc --all` — audit all specs in `openspec/specs/`
   - Features:
     - Dry-run mode (no modifications, reports candidates before writing)
     - Identify requirements marked PROVISIONAL, ORPHANED_REF, CONTRADICTORY
     - Best-effort codebase search for orphan references
     - User confirmation gate before removals
     - Changelog recording what was removed and when
   - Register skill in CLAUDE.md Skills Registry

### Excluded (explicitly out of scope)

- Rephrasing or consolidating requirements (GC removes only, does not edit or merge)
- Automated spec linting rules or pre-commit hooks (future work)
- Spec versioning or branching (single-master-specs model remains)
- Repairing contradictions (GC surfaces them; user decides removal or reconciliation)
- Migration path from current flat index to SQLite/FTS5 (deferred per ADR 034)

## Proposed Approach

### Spec-first Q&A (6a)

1. Extend the Question routing pathway in CLAUDE.md
2. Before answering, scan `openspec/specs/index.yaml` for keywords matching the user's question
3. Load matching specs (capped at 3) as supplementary context
4. If a spec contradicts codebase or ai-context/ context, surface it explicitly: "Spec says X, but codebase does Y — clarify which is authoritative?"
5. Fall back gracefully: if index.yaml is missing or no keywords match, answer without spec context (non-blocking)

Pattern already proven: `sdd-explore` SKILL.md includes Step 0 sub-step that loads matching specs as behavioral contracts. Reuse this pattern for Q&A.

### Spec garbage collection (6b)

1. Create new maintenance skill `sdd-spec-gc` (similar category to `project-audit`, `project-fix`)
2. Implement two modes:
   - **Single-domain mode**: `/sdd-spec-gc orchestrator-behavior` — scan one spec for stale markers
   - **All-domains mode**: `/sdd-spec-gc --all` — scan all `openspec/specs/*/spec.md`
3. For each requirement, detect:
   - `[PROVISIONAL ...]` markers — requirements pending integration, unstable
   - `[ORPHANED_REF ...]` markers — requirements with no codebase references (best-effort search)
   - `[CONTRADICTORY ...]` markers — requirements that conflict with other specs
4. Dry-run output: list candidates, explain why each was flagged, estimate impact of removal
5. User confirmation: "Remove X requirements? (y/n)" — only on explicit user approval
6. Changelog: append entry to `CHANGELOG_GC.md` (or ai-context/changelog-ai.md section) recording:
   - Timestamp
   - Domain(s) processed
   - Count of removed requirements per marker type
   - Reason for removal (if user provided comment)

### Integration touchpoints

- CLAUDE.md: add question routing rule + register sdd-spec-gc skill
- `openspec/config.yaml`: no changes (GC reads specs natively)
- `ai-context/`: changelog updated if GC is executed
- `docs/SPEC-CONTEXT.md`: new section documenting spec-first Q&A behavior
- ADR: no new ADR (implementation detail of existing spec-authority decision)

## Affected Areas

| Area/Module | Type of Change | Impact |
|---|---|---|
| CLAUDE.md (Question routing section) | Modified | Medium — adds spec preload step to Q&A path |
| sdd-explore/SKILL.md | Reference only | Low — documents existing behavior as pattern model |
| New skill: sdd-spec-gc | New | High — creates new maintenance capability |
| openspec/specs/index.yaml | Read-only for Q&A | Low — already exists; no modifications |
| Master specs | Read-only for GC | High — will be targets for cleanup once GC is available |
| docs/SPEC-CONTEXT.md | New section | Low — documentation only |

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Keyword matching loads irrelevant specs | Medium | Low | Proposal 6a defines stem-matching heuristic; design phase refines with examples and precision threshold |
| GC codebase search misses references in comments/strings | High (expected) | Low | Proposal 6b marks uncertain orphans as UNCERTAIN rather than removing them; user reviews before commit |
| After GC, no process prevents re-accumulation | Medium | Medium | Design phase can recommend cadence (e.g., run every N archived cycles); future work: linting rule |
| GC search is slow on large codebases | Medium | Low | Proposal limits to single-domain or --all mode; design phase can add timeout/cancellation handling |

## Rollback Plan

1. **If spec-first Q&A causes wrong answers**: remove the new Question routing rule from CLAUDE.md, revert to original behavior
2. **If sdd-spec-gc removes too much**: git revert the commit that archived the GC change, restore specs from version control
3. **If spec contradictions are introduced**: restore `openspec/specs/` from git; re-run GC with more conservative removal criteria
4. **All rollbacks via git**: no database or irreversible state — specs are plain markdown committed to version control

## Dependencies

- `openspec/specs/index.yaml` must exist (already exists as of 2026-03-14)
- `docs/templates/` structure (used by sdd-propose for optional PRD; not blocking for this change)
- No external API or library dependencies

## Success Criteria

- [ ] Spec-first Q&A: user asks question about domain → orchestrator reads matching specs before answering
- [ ] Spec contradiction surfacing: when spec contradicts codebase, user is notified explicitly in Q&A response
- [ ] sdd-spec-gc skill exists and is registered in CLAUDE.md Skills Registry
- [ ] `/sdd-spec-gc domain-name` produces dry-run report listing PROVISIONAL/ORPHANED_REF/CONTRADICTORY candidates
- [ ] `/sdd-spec-gc --all` produces dry-run report across all domain specs
- [ ] User confirmation gate works: GC pauses before removals, accepts y/n input
- [ ] Changelog entry created/updated after each GC execution (timestamp, domain, count, markers)
- [ ] Both features degrade gracefully (no errors) when index.yaml is missing or specs are not found

## Effort Estimate

Medium (1–2 days)

Breakdown:
- sdd-spec-gc skill design & implementation: 6–8 hours
- Orchestrator Q&A rule: 1–2 hours
- Testing & validation: 3–4 hours
- Documentation (docs/SPEC-CONTEXT.md update): 1 hour

## Context

Recorded from feedback session 2026-03-19-feedback-sdd-cycle-context-gaps-p6:

### Explicit Intents

- **Spec-first Q&A**: "When I ask the orchestrator about welcome video completion, it should read the video-wiring spec before answering — not just code"
- **Spec maintenance needed**: "Master specs grow indefinitely with provisional/stale requirements; need tooling to audit and clean them"
- **No rephrase/consolidate**: "Garbage collection should only remove; it should not try to edit or merge requirements"

### Provisional Notes

- **GC best-effort**: Codebase search for ORPHANED_REF is best-effort (comment references will be missed); flagged candidates as UNCERTAIN until user confirms
- **Spec contradictions**: Proposal 6a expects specs to be authoritative but allows user to choose which authority wins (spec or codebase)

## Contradiction Resolution

No CERTAIN contradictions detected in exploration. One UNCERTAIN contradiction was identified and resolved:

### Spec contradiction accumulation

**Prior context**: `sdd-verify-enforcement` ADR (2026-03-10) says specs are authoritative; users trust them as the system of record.

**This proposal**: Introduces a GC skill that can remove requirements from specs, changing what the "record" contains.

**Resolution approach**: Intentional design — removal is not a breaking change. GC is user-initiated (dry-run before commit), logged (changelog entry), and reversible (git revert). The proposal explicitly scopes GC to removal-only; it never modifies existing requirements. This respects the authority of specs while allowing them to evolve.

---

Next step: `/sdd-spec` (delta specs for both proposals) and `/sdd-design` (technical design) can run in parallel. Both will define the exact matching algorithm, GC marker schema, and integration touchpoints.
