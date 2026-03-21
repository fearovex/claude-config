# Exploration: spec-hygiene

## Current State

The spec landscape is healthy overall. All 55 master spec domains in `openspec/specs/` are single-file (`spec.md`). There are 0 active (non-archived) changes and 63 archived changes. The archive spans from 2026-02-23 to 2026-03-14.

---

## Findings

### 1. Master Spec Domain Count

55 domains in `openspec/specs/`. Every domain contains exactly one `spec.md`. No empty or multi-file domains found.

### 2. Active Changes

0. All changes are archived. The `openspec/changes/` directory contains only the `archive/` subdirectory. Clean state confirmed.

### 3. Archive Size and Health

63 entries in `openspec/changes/archive/`, dating from 2026-02-23 through 2026-03-14.

The most recent archives (2026-03-14) are fully populated:
- `add-clarification-gate-for-ambiguous-inputs`: proposal, design, tasks, verify-report, CLOSURE.md, specs/
- `orchestrator-visibility`: same complete set
- `orchestrator-classification-edge-cases`: same complete set
- `skills-catalog-analysis`: same complete set + exploration.md, prd.md

Older archives (2026-02-23 through 2026-02-26) are lean (proposal, tasks, verify-report only — no design.md or specs/ subdirectory), which is consistent with the SDD process being simpler at that time.

### 4. Spec-to-Archive Traceability

50 of 55 spec domains have a traceable origin via either a `Change:` YAML-style header or a `*Created: ... by change "..."*` inline marker.

The 5 specs that lack a `Change:` header but carry an equivalent `*Created by change*` inline marker:
- `sdd-apply` — created by `tech-skill-auto-activation`
- `sdd-apply-execution` — created by `close-p1-gaps-sdd-apply-verify`
- `sdd-verify-execution` — created by `close-p1-gaps-sdd-apply-verify`
- `smart-commit` — created by `smart-commit-functional-split`
- `solid-ddd-skill` — created by `solid-ddd-quality-enforcement`

All 5 have matching archived change directories. These are NOT orphaned — they simply use an older header convention (`*Created:*` inline) rather than the structured `Change:` header used by newer specs.

### 5. Multi-Change Specs (Living Documents)

`orchestrator-behavior` is the clearest example of a spec updated by multiple changes. It was originally created by `2026-03-12-orchestrator-always-on` and has been extended by at least 3 subsequent changes:
- `orchestrator-visibility` (2026-03-14)
- `orchestrator-classification-edge-cases` (2026-03-14)
- `add-clarification-gate-for-ambiguous-inputs` (2026-03-14)

This is healthy — one authoritative domain spec accumulating delta requirements over time, each update traceable via inline `(modified 2026-03-14)` annotations. No staleness.

`step-0a-governance-discovery` is declared as a delta on `sdd-context-loading` (its `Base:` header points to it). This cross-domain delta relationship is correctly documented.

### 6. Potentially Orphaned Specs

**None found.** Every spec domain has either:
1. A `Change:` header pointing to a named archived change, or
2. A `*Created by change*` inline marker pointing to a named archived change.

The fuzzy string-match check initially produced false negatives (e.g., `orchestrator-behavior` appeared unmatched because its archive uses date prefix `2026-03-12-orchestrator-always-on` not `orchestrator-behavior`). Manual inspection of spec headers confirmed full traceability.

### 7. Spec Staleness Patterns

- No specs lack a creation/change reference.
- The oldest specs (e.g., `audit-dimensions`, `audit-execution`) reference changes from the 2026-02-26 cohort — predating the structured `Change:` header convention, but still traceable via archive directory names.
- `sdd-apply` and `sdd-apply-execution` cover different aspects of the same skill (tech-skill auto-activation vs. TDD detection), which creates mild domain overlap. Not a hygiene problem, but potentially worth consolidating in a future change.

### 8. Spec Header Convention Inconsistency (Minor)

Two header styles exist across the corpus:
- **Structured** (`Change:`, `Date:`, `Base:` YAML-style): used by ~42 specs (post-2026-02-28 era)
- **Inline prose** (`*Created: YYYY-MM-DD by change "name"*`): used by 5 specs (pre-2026-02-28 era)

Neither style is wrong — both provide traceability — but the inconsistency is worth noting as a minor hygiene item.

---

## Affected Areas

| Domain | Impact | Notes |
| --- | --- | --- |
| `openspec/specs/` (all 55 domains) | Read-only audit | All healthy |
| `openspec/changes/archive/` (63 entries) | Read-only audit | All healthy |
| 5 specs with inline `*Created by*` headers | Minor | Older convention; traceable but not structured |
| `sdd-apply` + `sdd-apply-execution` | Minor | Domain overlap (two specs for one skill) |
| `orchestrator-behavior` | N/A | Multi-change living document — healthy pattern |

---

## Analyzed Approaches

### Approach A: No action required

**Description**: Current spec hygiene is good. Accept the minor header inconsistency as historical artifact.
**Pros**: Zero effort; no risk of introducing new issues.
**Cons**: Header inconsistency persists; future auditors must know two conventions.
**Estimated effort**: None
**Risk**: Low

### Approach B: Backfill structured `Change:` headers into 5 legacy specs

**Description**: Add `Change:` and `Date:` headers to the 5 specs that use the inline `*Created by*` convention.
**Pros**: Uniform header convention across all 55 specs; D13 and future tooling can rely on a single pattern.
**Cons**: Minor SDD overhead (requires sdd-ff + apply).
**Estimated effort**: Low (5 file edits)
**Risk**: Low

### Approach C: Merge `sdd-apply` + `sdd-apply-execution` into one domain spec

**Description**: Consolidate the two overlapping sdd-apply domain specs.
**Pros**: Cleaner domain boundaries; one spec per skill.
**Cons**: Requires care to preserve all scenarios from both specs; higher effort.
**Estimated effort**: Medium
**Risk**: Low-Medium (risk of losing a scenario during merge)

---

## Recommendation

**Approach A** for immediate action — the spec corpus is healthy, traceable, and fully archived. No urgent hygiene action is required.

**Approach B** is a low-effort nicety if uniformity matters for tooling. Can be bundled into a future `spec-hygiene` change if desired.

**Approach C** (consolidation) is deferred — there is no functional problem, only an aesthetic one.

---

## Identified Risks

- Header inconsistency: minor — any tool that parses `Change:` headers will silently skip 5 specs; must handle both conventions.
- `sdd-apply` / `sdd-apply-execution` overlap: low — both specs are internally consistent; the overlap is additive, not contradictory.

---

## Open Questions

- Should `sdd-apply` and `sdd-apply-execution` be merged into a single spec domain? No blocking reason to do it now.
- Should the header backfill (Approach B) be done? User preference — no correctness issue either way.

---

## Ready for Proposal

**Yes** (if action is desired) or **No action needed** (if the finding is purely informational).

The spec landscape is clean: 55 domains, 0 active changes, 63 archived changes, full traceability, no orphans, no stale specs.
