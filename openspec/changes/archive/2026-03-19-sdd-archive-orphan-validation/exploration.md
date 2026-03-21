# Exploration: sdd-archive-orphan-validation

## Current State

### sdd-archive validation today

`sdd-archive` (at `~/.claude/skills/sdd-archive/SKILL.md`) performs exactly **one artifact-level validation** in Step 1:

> Read `openspec/changes/<change-name>/verify-report.md` if it exists.
> If CRITICAL issues present → block. If missing → inform user and ask whether to proceed.

This is a **soft gate on verify-report.md** only. It does NOT check:
- Whether `proposal.md` exists (the change was formally proposed)
- Whether `design.md` exists (technical design was done)
- Whether `tasks.md` exists (implementation was task-planned)
- Whether `exploration.md` exists (only present on sdd-ff/sdd-new cycles, optional anyway)
- Whether a `specs/` directory exists (delta specs were written)

Beyond verify-report.md, the only other archive precondition is the irreversibility confirmation prompt in Step 2. No completeness check is performed before that confirmation is requested.

### What "required" vs "optional" means in the SDD cycle

From `CLAUDE.md` (Phase DAG and artifact storage sections), the full artifact set for a completed SDD cycle is:

| Artifact | Phase that produces it | Required for complete cycle? |
|---|---|---|
| `exploration.md` | sdd-explore (Step 0 in sdd-ff) | **Optional** — present in ~50% of archived changes |
| `proposal.md` | sdd-propose | **Required** — present in 100% of observed archived changes |
| `prd.md` | sdd-propose (optional sub-step) | Optional — auto-created only when template exists |
| `specs/<domain>/spec.md` | sdd-spec | **Required** for non-trivial changes — present in ~85% of archived changes; absent in early bootstrap changes pre-dating the spec system |
| `design.md` | sdd-design | **Required** — present in ~85% of archived changes; absent only in very early bootstrap changes |
| `tasks.md` | sdd-tasks | **Required** — present in 100% of observed archived changes |
| `verify-report.md` | sdd-verify | **Required** (currently gated) — present in 100% of observed archived changes |
| `CLOSURE.md` | sdd-archive Step 5 | Produced by archive itself — not a precondition |

**From historical analysis of 65 archived changes:**
- `proposal.md`: 65/65 (100%)
- `tasks.md`: 65/65 (100%)
- `verify-report.md`: 65/65 (100%)
- `design.md`: ~56/65 (86%) — absent in early 2026-02-23 bootstrap changes that pre-date design phase
- `specs/`: ~56/65 (86%) — same pattern (design and specs absent together)
- `exploration.md`: ~22/65 (34%) — clearly optional

### Orphan changes currently in openspec/changes/

| Change directory | proposal | design | tasks | verify-report | specs | Assessment |
|---|---|---|---|---|---|---|
| `spec-hygiene` | - | - | - | - | - | Abandoned exploration stub — no proposal ever filed |
| `2026-03-14-spec-headers-domain-consolidation` | Y | Y | Y | - | Y | Missing verify-report — incomplete cycle |
| `2026-03-14-specs-sqlite-store` | Y | Y | - | - | - | Incomplete — missing tasks, verify |
| `2026-03-18-context-handoff-between-sessions` | Y | - | Y | Y | - | Missing design and specs |

These are exactly the **orphan accumulation problem** this change aims to solve.

### How other SDD skills handle validation

**sdd-verify** (closest analogue): checks completeness of tasks (Step 2), correctness vs specs (Step 3), coherence vs design (Step 4). Uses CRITICAL/WARNING/SUGGESTION severity tier. CRITICAL blocks archiving.

**sdd-apply**: enforces per-task retry circuit breaker (`[BLOCKED]` state), Diagnosis Step before writes, Quality Gate before marking `[x]`. Uses MUST_RESOLVE / ADVISORY warning tiers.

**sdd-tasks**: classifies warnings as MUST_RESOLVE (blocking) or ADVISORY (non-blocking).

**Pattern across skills**: use explicit severity tiers; only CRITICAL/MUST_RESOLVE blocks; all other findings warn-and-continue.

None of the other SDD phase skills validate that prerequisite phases have been run — they assume the phase DAG was followed. `sdd-archive` is the only terminal node where such a retroactive check makes sense.

### Where validation should be inserted

The natural insertion point is **Step 1** — currently titled "Verify it is archivable." The verify-report.md check already lives there. A completeness check of other required artifacts fits organically before Step 2 (the user confirmation prompt).

The check should run in this order:
1. Check required artifacts (proposal.md, tasks.md, design.md) — NEW
2. Check verify-report.md for CRITICAL issues — EXISTING
3. Surface the user-docs checkbox — EXISTING
4. Then prompt for confirmation (Step 2)

Running the check before confirmation is important: the user should know what is missing before committing to an irreversible action.

---

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `skills/sdd-archive/SKILL.md` | Primary change — Step 1 expansion | Add completeness check block before verify-report check |
| `openspec/specs/sdd-archive-execution/spec.md` | Delta spec target | New requirement + scenarios for orphan/completeness validation |
| `ai-context/architecture.md` | Memory update | After archiving, record the new validation rule |

---

## Analyzed Approaches

### Approach A: Warn-and-proceed (non-blocking)

**Description**: When required artifacts are missing, sdd-archive logs a warning and lists the missing files, then asks the user whether to proceed anyway (same pattern as the missing verify-report today).

**Pros**:
- Consistent with existing missing-verify-report behavior
- Does not block legitimate edge cases (e.g., a hotfix cycle that skips design)
- User always in control

**Cons**:
- Weak signal — orphan changes can still be silently archived
- Does not distinguish between "intentionally skipped design" and "forgot to run sdd-design"
- The prompt fatigue problem: if users always say yes, the check is noise

**Estimated effort**: Low
**Risk**: Low — no behavioral change to the happy path

---

### Approach B: Block-unless-confirmed (MUST_RESOLVE for critical artifacts)

**Description**: Treat missing `proposal.md` or `tasks.md` as CRITICAL (block). Treat missing `design.md` or `specs/` as WARNING (warn + confirm). `exploration.md` is not checked (always optional).

**Pros**:
- Prevents truly incomplete cycles from being archived
- Differentiates severity: proposal+tasks are unambiguously required; design+specs are expected but can be legitimately absent
- Consistent with sdd-verify CRITICAL/WARNING model

**Cons**:
- Could be annoying for projects in early stages where design is intentionally skipped
- Adds friction to the archive flow

**Estimated effort**: Low-Medium
**Risk**: Low-Medium — edge cases where users intentionally skip phases need an escape hatch

---

### Approach C: Config-driven artifact checklist

**Description**: Add an `archive.required_artifacts` key to `openspec/config.yaml` that lets projects override which artifacts are required. Default list = `[proposal, tasks, design]`. Missing artifacts = CRITICAL.

**Pros**:
- Maximum flexibility per project
- No friction for lightweight projects that skip design

**Cons**:
- Over-engineering for a meta-system where the SDD cycle is fixed
- Adds config surface without a real user need
- This repo's `openspec/config.yaml` does not have this pattern for any skill

**Estimated effort**: Medium-High
**Risk**: Low — but adds maintenance burden

---

## Recommendation

**Approach B (Block-unless-confirmed for critical artifacts)** with one refinement: make the block a **confirm-with-explicit-acknowledgment** rather than a hard block, using the pattern:

```
Missing required artifacts detected:
  ❌ design.md — not found
  ❌ specs/ — not found

These artifacts are expected for a complete SDD cycle.
Options:
  1. Return and complete the missing phases (/sdd-design, /sdd-spec)
  2. Archive anyway with acknowledgment that these phases were intentionally skipped

Reply with 1 or 2.
```

- `proposal.md` and `tasks.md` absent → CRITICAL (block, no option 2 — these are truly required)
- `design.md` or `specs/` absent → WARNING (present option 1 or 2, require explicit acknowledgment)
- `exploration.md` absent → not checked (optional, no mention)
- `verify-report.md` logic unchanged (existing behavior)

This approach:
- Preserves user control (no hard lock-out)
- Differentiates severity meaningfully
- Generates an explicit "I skipped design intentionally" signal that can be recorded in CLOSURE.md
- Is consistent with the confirm-before-archive pattern already in Step 2

---

## Identified Risks

- **Overly strict for early-stage cycles**: Some legitimate use cases skip design (hotfixes, trivial skill updates). Mitigation: the explicit acknowledgment path in option 2 handles this.
- **Retroactive strictness on existing cycles**: Changes already in `openspec/changes/` that are incomplete (like the 4 orphan changes currently present) will hit this gate. This is intentional — the gate will surface them.
- **spec.md in sdd-archive-execution needs update**: The master spec at `openspec/specs/sdd-archive-execution/spec.md` must receive a new "Requirement: orphan/completeness validation" section as a delta spec from this change.

---

## Open Questions

- Should the orphan check produce a CLOSURE.md note when the user acknowledges skipped phases? (Recommendation: yes — add a "Skipped phases: [list]" field to CLOSURE.md.)
- Should `sdd-archive` also detect changes that have zero spec delta (no `specs/` dir or empty `specs/` dir) and treat them differently from changes that have spec files? (Recommendation: treat empty `specs/` same as absent — both are WARNING-level.)

---

## Ready for Proposal

Yes — the scope is well-defined, the insertion point is clear, the approach decision is made. No blockers.
