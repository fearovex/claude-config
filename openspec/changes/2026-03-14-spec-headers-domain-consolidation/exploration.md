# Exploration: spec-headers-domain-consolidation

## Current State

55 spec domains live under `openspec/specs/`. Of these, 5 use a legacy inline-prose header format instead of the structured `Change: / Date:` key-value format adopted in recent changes. Additionally, two domains (`sdd-apply` and `sdd-apply-execution`) govern the same skill but live in separate directories with no cross-reference, making it unclear they belong together.

### Legacy header format (target of backfill)

The canonical structured header (observed in `orchestrator-behavior/spec.md`, `sub-agent-governance-injection/spec.md`) is:

```
# Spec: <title>

Change: YYYY-MM-DD-<slug>
Date: YYYY-MM-DD
```

The 5 legacy specs use italic inline prose instead:

| Domain | Current header | Lines |
|--------|---------------|-------|
| `sdd-apply` | `*Created: 2026-03-03 by change "tech-skill-auto-activation"*` | 589 |
| `sdd-apply-execution` | `*Created: 2026-02-28 by change "close-p1-gaps-sdd-apply-verify"*` | 172 |
| `sdd-verify-execution` | `*Created: 2026-02-28 by change "close-p1-gaps-sdd-apply-verify"*` | 340 |
| `smart-commit` | `Last updated: 2026-03-03` / `Created by change: smart-commit-functional-split` (bare text + `---`) | 426 |
| `solid-ddd-skill` | `*Created: 2026-03-04 by change "solid-ddd-quality-enforcement"*` | 156 |

Note: `smart-commit` uses a slightly different non-canonical format (bare key lines + horizontal rule) rather than italics. All five are inconsistent with the structured format.

### sdd-apply domain split

`sdd-apply/spec.md` and `sdd-apply-execution/spec.md` both specify behavior of the `sdd-apply` skill:

- **sdd-apply** (589 lines): tech skill auto-activation (Step 0 preload), Stack-to-Skill Mapping Table, solid-ddd unconditional preload, structured Quality Gate, Diagnosis Step, retry circuit breaker
- **sdd-apply-execution** (172 lines): TDD mode detection and RED-GREEN-REFACTOR cycle, no-commit-suggestion rule (added by sdd-verify-enforcement change), TDD output field

The two specs were created in different change cycles and grew independently. There is no cross-reference between them. A reader of `sdd-apply/spec.md` will not discover the TDD behavior spec without knowing to look in a separate domain.

## Affected Areas

| File | Impact | Notes |
|------|--------|-------|
| `openspec/specs/sdd-apply/spec.md` | Header backfill + consolidation target | 589 lines; receives header + sections from sdd-apply-execution |
| `openspec/specs/sdd-apply-execution/spec.md` | Header backfill + possibly retired after consolidation | 172 lines; distinct TDD + no-commit content |
| `openspec/specs/sdd-verify-execution/spec.md` | Header backfill only | 340 lines; no structural change needed |
| `openspec/specs/smart-commit/spec.md` | Header backfill only | 426 lines; uses near-canonical but non-standard format |
| `openspec/specs/solid-ddd-skill/spec.md` | Header backfill only | 156 lines; simple italic replacement |

## Analyzed Approaches

### Approach A: Backfill headers only — no consolidation

**Description**: Add structured `Change:` / `Date:` headers to all 5 legacy specs. Leave `sdd-apply-execution` as a separate domain. No domain merging.

**Pros**:
- Minimal risk — only 5 single-line header replacements
- No content moves; no risk of losing requirements
- `sdd-apply-execution` domain name remains stable (referenced in architecture.md decision 19 and design notes)

**Cons**:
- Does not address the discoverability problem: two domains governing the same skill remain separated
- Future maintainers still need to know to look in `sdd-apply-execution` for TDD behavior

**Estimated effort**: Low
**Risk**: Low

---

### Approach B: Header backfill + consolidate sdd-apply and sdd-apply-execution into sections

**Description**: Backfill headers on all 5 specs. Additionally, merge `sdd-apply-execution/spec.md` content into `sdd-apply/spec.md` as a new top-level section (e.g., `## Part 2: TDD Mode and Output`). Retire `sdd-apply-execution` domain directory (or keep it as a redirect stub referencing the merged location).

**Pros**:
- All `sdd-apply` behavior in one file — no discoverability gap
- Cleaner domain model: one skill = one spec domain
- Consistent with how other merged specs work (e.g., sdd-apply already accumulates requirements from multiple changes inline)

**Cons**:
- `sdd-apply/spec.md` grows from 589 to ~760 lines — still manageable
- `sdd-apply-execution` domain name is referenced in `architecture.md` key decisions 19 and D13 audit entries; retirement means those references become stale (low-impact, not operational)
- Slightly higher risk of merge error vs. pure header backfill

**Estimated effort**: Low-Medium
**Risk**: Low-Medium

---

### Approach C: Header backfill + rename sdd-apply-execution without merging

**Description**: Backfill headers. Keep `sdd-apply-execution` as a separate file but add a cross-reference comment at the top of each file pointing to the other.

**Pros**: Low effort; improves discoverability without content moves

**Cons**: Still two separate files; cross-reference comment is informal and not enforced

**Estimated effort**: Low
**Risk**: Low

## Recommendation

**Approach B** for the consolidation; **Approach A logic** for the other 4 specs (header backfill only).

Rationale:
- The `sdd-apply` + `sdd-apply-execution` split is the only genuine domain-cohesion issue. The other 4 specs (sdd-verify-execution, smart-commit, solid-ddd-skill) each represent distinct skills with no overlap — they only need header normalization.
- Merging TDD behavior into `sdd-apply/spec.md` as a clearly delimited section (with a `## Part 2` heading) is the lowest-risk consolidation: the content is additive, not contradicting, and the resulting file size is reasonable.
- After merge, `sdd-apply-execution/` directory should be retired (deleted) to prevent D13 from picking it up as a stale domain.

## Identified Risks

- **Stale architecture.md references**: `architecture.md` references `openspec/specs/sdd-apply-execution/spec.md` in key decisions 12 and 15 (apply-retry-limit and apply-diagnose-first). After merge, those paths resolve to `sdd-apply/spec.md`. Low impact (documentation-only; no runtime effect) — update architecture.md entries as part of apply.
- **D13 audit re-scan**: After `sdd-apply-execution/` is removed, `/project-audit` D13 will no longer see that domain. This is the desired outcome — the content lives in `sdd-apply/spec.md` which D13 will continue to scan. No audit regression expected.
- **smart-commit/spec.md has no italic format** — it uses a slightly different non-canonical style. The backfill is still straightforward (replace the two bare lines + `---` with the structured header block). This is noted so the apply agent is not confused by the different source format.

## Open Questions

- None. The change scope is clear and self-contained. All 5 files have been read and their formats confirmed.

## Ready for Proposal

Yes — the change is well-scoped, low-risk, and the approach is clear.
