# Exploration: specs-as-subagent-background

Date: 2026-03-14
Change: 2026-03-14-specs-as-subagent-background

---

## Summary

This change proposes loading relevant master specs from `openspec/specs/` as structured background
context in sub-agent prompts, promoting them from "incidentally read" to "explicitly injected" in
the sub-agent CONTEXT block. The purpose is to replace the current model where sub-agents rely
primarily on `ai-context/` (session-written narrative memory) with a model where they operate
against the exact behavioral contracts defined in the master spec layer.

---

## Current State

### Sub-agent context loading today (three layers)

All six SDD phase skills execute **Step 0 — Load project context** as their first step. This step reads:

1. `ai-context/stack.md` — tech stack
2. `ai-context/architecture.md` — architectural decisions
3. `ai-context/conventions.md` — naming patterns
4. Full project `CLAUDE.md` (governance + Skills Registry)

For `sdd-propose` and `sdd-spec`, there is also a **Sub-step 0b — Domain context preload** that reads
matching `ai-context/features/<domain>.md` files (feature-level business rules and invariants).

**Spec files (`openspec/specs/`) are NOT part of Step 0.** They are sometimes read during phase
execution (e.g., `sdd-spec` reads existing domain specs as part of Step 1 — Read prior artifacts),
but they are not part of the injected CONTEXT block that orchestrators pass to sub-agents.

### The master spec layer

`openspec/specs/` currently contains **55 domain directories**, each with a `spec.md` file.
These files are the direct output of prior SDD cycles — they define exact behavioral contracts
using the Given/When/Then scenario format. Every behavior the system enforces is represented here
with more precision than `ai-context/architecture.md` can capture.

Notable domains directly relevant to this change:
- `sdd-context-loading/spec.md` — mandates Step 0 block in all SDD phase skills
- `sdd-phase-context-loading/spec.md` — dual-block (Step 0a/0b) requirement for sdd-propose and sdd-spec
- `sdd-orchestration/spec.md` — mandatory exploration, slug inference, phase ordering
- `sub-agent-governance-injection/spec.md` — CONTEXT block format (Project, governance, Change, Previous artifacts)
- `sub-agent-execution-contract-update/spec.md` — sub-agent I/O contract
- `skill-orchestration/spec.md` — orchestrator delegation pattern

### Orchestrator CONTEXT block format (current)

From `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`, each Task tool call passes:

```
CONTEXT:
- Project: [absolute path]
- Project governance: [absolute path]/CLAUDE.md
- Change: [inferred-slug]
- Previous artifacts: [list of paths]
```

There is **no SPEC CONTEXT block** injected today. Sub-agents discover relevant spec files
only if their SKILL.md instructs them to do so (which `sdd-spec` does in Step 1, but
`sdd-explore`, `sdd-propose`, `sdd-design`, and `sdd-tasks` do not explicitly do).

---

## Affected Areas

| File/Module | Current State | Change Needed |
| ----------- | ------------- | ------------- |
| `CLAUDE.md` — sub-agent launch template | CONTEXT block has 4 fields | Add SPEC CONTEXT block with domain list |
| `skills/sdd-ff/SKILL.md` — Steps 0–3 | Injects CONTEXT only | Must build domain list and inject SPEC CONTEXT |
| `skills/sdd-new/SKILL.md` — Steps 1–4 | Same as sdd-ff | Same as sdd-ff |
| `skills/sdd-explore/SKILL.md` — Step 0 | Reads ai-context/ only | Add spec file loading step |
| `skills/sdd-propose/SKILL.md` — Step 0a/0b | Reads ai-context/ + features | Add spec file loading step |
| `skills/sdd-spec/SKILL.md` — Step 1 | Reads proposal.md + existing domain spec | Formalize spec loading in Step 0, extend to injected domains |
| `skills/sdd-design/SKILL.md` — Step 0 | Reads ai-context/ | Add spec file loading step |
| `skills/sdd-tasks/SKILL.md` — Step 0 | Reads ai-context/ | Add spec file loading step |
| `openspec/specs/sdd-context-loading/spec.md` | Defines Step 0 contract | Must be extended with spec-loading requirement |
| `docs/` | No SPEC-CONTEXT.md exists | New convention doc needed |

---

## Analyzed Approaches

### Approach A: Orchestrator-injected SPEC CONTEXT block (proposed)

**Description**: The orchestrators (`sdd-ff`, `sdd-new`) compute relevant domain names by matching
the change slug against directory names under `openspec/specs/`. They inject a `SPEC CONTEXT:` block
into the Task prompt listing the matched spec file paths. Phase skills add a new sub-step to their
Step 0 to read these files when present.

**Pros**:
- Orchestrators have the full slug and can do one filesystem scan per cycle (not per phase)
- Sub-agents receive the spec paths explicitly — no search needed in each sub-agent
- Consistent with the existing governance injection pattern (Project governance: path is also injected)
- Non-blocking by design (if no domains match, block is empty or absent — sub-agent falls back)

**Cons**:
- Orchestrators must perform `ls openspec/specs/` and string matching — adds slight logic to SKILL.md
- If the injected domain list is wrong (slug vocabulary differs from spec dir name), sub-agents silently load wrong specs
- CLAUDE.md sub-agent launch template grows in complexity

**Estimated effort**: Medium
**Risk**: Low–Medium (domain name mismatch is the primary risk; mitigated by fallback)

---

### Approach B: Phase-skill self-selection (no orchestrator injection)

**Description**: Orchestrators do not change. Each phase skill Step 0 is updated to list
`openspec/specs/` and self-select relevant domains using the same slug-matching heuristic
already used for `ai-context/features/` (change name contains domain slug or vice versa).
No SPEC CONTEXT block is passed.

**Pros**:
- Orchestrators remain unchanged (lower blast radius)
- Each phase skill already has the change name and can do matching independently
- Consistent with the existing `ai-context/features/` preload pattern
- Simpler to implement: only 5 SKILL.md edits, no orchestrator edits

**Cons**:
- Every sub-agent performs `ls openspec/specs/` — 5 filesystem scans per `/sdd-ff` cycle
- Each sub-agent independently infers domain relevance, potentially with inconsistent results
- No visibility to the orchestrator of which specs were selected

**Estimated effort**: Low–Medium
**Risk**: Low

---

### Approach C: Hybrid — orchestrator infers, phase skills read

**Description**: Orchestrators inject the SPEC CONTEXT block as in Approach A. Phase skills
use the injected list as the primary source but also fall back to self-selection (Approach B)
when no SPEC CONTEXT is present (e.g., when a phase is invoked standalone via `/sdd-spec`).

**Pros**:
- Best of both: efficient (one scan), consistent (orchestrator-driven), and robust (standalone fallback)
- Standalone phase skill invocations still work without orchestrator
- Clean separation: orchestrator owns domain selection for FF cycles; skills own it for standalone use

**Cons**:
- Most complex to implement — both orchestrators and all 5 phase skills change
- Two code paths to maintain (injected vs. self-selected)

**Estimated effort**: Medium–High
**Risk**: Low (complexity risk only)

---

### Approach Comparison Table

| Approach | Pros | Cons | Effort | Risk |
| -------- | ---- | ---- | ------ | ---- |
| A: Orchestrator injection | Single scan, explicit, consistent | Orchestrator logic grows, name-mismatch risk | Medium | Low–Medium |
| B: Phase-skill self-selection | Orchestrators unchanged, consistent with features pattern | 5× scans, independent inference | Low–Medium | Low |
| C: Hybrid | Robust, efficient, standalone-safe | Most complex, two code paths | Medium–High | Low |

---

## Recommendation

**Approach B — Phase-skill self-selection** for the initial implementation.

Rationale:
1. The `ai-context/features/` preload (already in `sdd-propose` and `sdd-spec`) uses exactly this pattern. Extending it to `openspec/specs/` is a natural, low-risk extension rather than a new architectural layer.
2. The 55-domain directory listing is a trivial filesystem operation and the cost of doing it 5 times per cycle is negligible.
3. Orchestrators (`sdd-ff`, `sdd-new`) have already grown significantly with governance injection and slug inference. Keeping spec selection in phase skills preserves the orchestrator's role as a sequencer, not a selector.
4. Approach A and C can be layered on later if cross-phase spec consistency becomes a problem.

The `sdd-context-loading/spec.md` master spec must be extended with the new requirement (Step 0 spec loading).
A new `docs/SPEC-CONTEXT.md` convention document is needed.

---

## Identified Risks

- **Domain name vocabulary mismatch** (Low impact): The slug `specs-as-subagent-background` would not match any existing spec domain by substring (no domain is named `specs`, `subagent`, or `background`). This is the primary failure mode — sub-agent loads no specs when the change name uses different vocabulary than the spec directory. **Mitigation**: Sub-agents fall back to `ai-context/` context when no domain matches (current behavior). A future indexing mechanism (companion proposal `2026-03-14-specs-search-optimization`) would address this.
- **Spec file proliferation** (Low impact): With 55 domains, the sub-agent could match 3–5 specs by keyword even when only 1 is truly relevant. **Mitigation**: Cap at 3–5 matches; sub-agents use judgment.
- **Spec files contradict ai-context/ summaries** (Low probability, Medium impact): If an `ai-context/architecture.md` entry contradicts a master spec scenario, the sub-agent may produce inconsistent output. **Mitigation**: Spec files take precedence; `ai-context/` is explicitly supplementary per the proposal.
- **Step 0 load order conflict** (Low risk): `sdd-propose` and `sdd-spec` already have Step 0a (global context) and Step 0b (feature files). Adding spec loading as Step 0c must not disrupt existing ordering. **Mitigation**: Spec loading is additive; the SKILL.md edit adds a clear sub-step label.

---

## Open Questions

1. **Loading cap**: Should sub-agents load at most 3 matching spec files (proposal says 3–5)? A hard cap prevents context overload for changes that touch many domains.
2. **Spec loading for sdd-apply**: The proposal excludes `sdd-apply` because it "already loads specs via the sdd-spec delta." Verify: does `sdd-apply` explicitly read the `openspec/changes/<change>/specs/` delta? If not, the exclusion rationale needs re-examination.
3. **Convention doc scope**: Should `docs/SPEC-CONTEXT.md` also document the fallback behavior and the companion search-optimization proposal's relationship?

---

## Ready for Proposal

Yes — proposal.md already exists at `openspec/changes/2026-03-14-specs-as-subagent-background/proposal.md`.
The exploration confirms the proposal is well-scoped and Approach B is the recommended implementation path.
