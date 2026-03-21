# Technical Design: 2026-03-19-sdd-archive-orphan-validation

Date: 2026-03-19
Proposal: openspec/changes/2026-03-19-sdd-archive-orphan-validation/proposal.md

## General Approach

Insert a two-tier completeness validation block at the top of `sdd-archive` Step 1, before the existing `verify-report.md` check. The block reads the change directory's file listing, classifies missing artifacts as CRITICAL or WARNING, and either halts (CRITICAL) or presents a two-option prompt (WARNING). When the user selects option 2 (archive with acknowledgment), the skipped phases are recorded in the `CLOSURE.md` produced in Step 5. The `sdd-archive-execution` delta spec is updated with four new scenarios covering the CRITICAL block, the WARNING prompt, the acknowledgment recording, and the happy path.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Insertion point | Top of Step 1, before verify-report.md check | After verify-report.md check; separate Step 0 | Completeness must be checked before irreversibility concerns. Running it first ensures invalid cycles are caught even when verify-report.md is absent. |
| CRITICAL vs WARNING classification | proposal.md + tasks.md = CRITICAL; design.md + specs/ = WARNING | All artifacts CRITICAL; config-driven threshold | Empirical data (100% present vs ~86%) and semantic weight drive the split. proposal+tasks represent minimum viable cycle intent. design+specs are phase-complete but have legitimate skip cases (hotfix/trivial cycles). |
| User confirmation flow for WARNING | Two-option prompt: return to complete OR archive with acknowledgment | Single-option block; silent archive anyway; config flag | Keeps user in control without imposing a hard block on legitimate abbreviated cycles. Two options is the established pattern in sdd-tasks (MUST_RESOLVE / ADVISORY). |
| Skipped phases recording | `Skipped phases:` field added to CLOSURE.md | Separate `skip-log.md`; warning in verify-report.md | CLOSURE.md is the canonical terminal artifact for the change record. Adding one field there is minimal-impact and co-locates the fact with the change summary. |
| Scope | sdd-archive SKILL.md + sdd-archive-execution delta spec only | Also updating sdd-verify or sdd-status | sdd-archive is the only terminal node; changes at any earlier phase would be speculative (cycles legitimately skip phases). sdd-archive-execution spec captures the new behavioral contract. |
| Convention alignment | Two-tier severity model (CRITICAL / WARNING) reuses existing sdd-tasks pattern | New severity naming | Reuses the MUST_RESOLVE/ADVISORY mental model already present in sdd-tasks — no new patterns to learn. CRITICAL maps to MUST_RESOLVE semantics; WARNING maps to ADVISORY-with-explicit-gate semantics. |

## Data Flow

```
sdd-archive invoked with <change-name>
        │
        ▼
Step 1 — Completeness Check (NEW)
        │
        ├─ Check for CRITICAL artifacts:
        │   proposal.md, tasks.md
        │        │
        │        ├─ All present → continue to WARNING check
        │        │
        │        └─ Any absent → HALT
        │               Output CRITICAL block listing missing files
        │               No proceed option
        │               (status: blocked)
        │
        ├─ Check for WARNING artifacts:
        │   design.md, specs/ (non-empty directory)
        │        │
        │        ├─ All present → continue to verify-report.md check
        │        │
        │        └─ Any absent → Present two-option prompt
        │               Option 1: Return and complete missing phases
        │               Option 2: Archive with acknowledgment
        │                    │
        │                    ├─ Option 1 selected → HALT (user goes back)
        │                    │
        │                    └─ Option 2 selected → record skipped phases
        │                         Continue to verify-report.md check
        │
        ▼
Step 1 (existing) — verify-report.md check
        │
        ▼
Step 2 — Confirm with user (existing)
        │
        ▼
Step 3 — Sync delta specs (existing)
        │
        ▼
Step 3a — Update spec index (existing)
        │
        ▼
Step 4 — Move to archive (existing)
        │
        ▼
Step 5 — Create CLOSURE.md (MODIFIED)
        │   When skipped phases were acknowledged:
        │   add "Skipped phases: [design, specs]" field
        │
        ▼
Step 6 — Auto-update memory (existing)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-archive/SKILL.md` | Modify | Insert completeness check block at top of Step 1; update CLOSURE.md template in Step 5 to include optional `Skipped phases:` field; update Rules section |
| `openspec/specs/sdd-archive-execution/spec.md` | Modify (delta) | Add new requirement section "Completeness validation before archive" with 4 scenarios: CRITICAL block, WARNING prompt, acknowledgment recording in CLOSURE.md, happy path no-op |

## Interfaces and Contracts

```
# Completeness check output — CRITICAL case
CRITICAL — Cannot archive "[change-name]"

The following artifacts are required for a valid SDD cycle but are missing:
  - proposal.md   (required — CRITICAL)
  - tasks.md      (required — CRITICAL)

Return and complete the missing phases before archiving.
No proceed option is available.

---

# Completeness check output — WARNING case
WARNING — Incomplete cycle detected for "[change-name]"

The following artifacts are missing:
  - design.md     (recommended — WARNING)
  - specs/        (recommended — WARNING)

Choose:
  1. Return and complete the missing phases (/sdd-spec, /sdd-design)
  2. Archive anyway — I acknowledge these phases were intentionally skipped

Reply 1 or 2:

---

# CLOSURE.md — Skipped phases field (added when option 2 is selected)
Skipped phases: design, specs   ← only present when phases were acknowledged as skipped

---

# Completeness check — happy path
(no output — execution continues silently to verify-report.md check)
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|--------------|------|
| Manual scenario | CRITICAL block: invoke sdd-archive on a change missing proposal.md → verify halt with no proceed option | Manual execution against a test change directory |
| Manual scenario | WARNING prompt: invoke sdd-archive on a change missing design.md → verify two-option prompt appears | Manual execution |
| Manual scenario | Option 2 path: select option 2 → verify CLOSURE.md contains `Skipped phases:` field listing missing phases | Manual execution |
| Manual scenario | Happy path: invoke sdd-archive on a change with all artifacts present → verify no additional output before verify-report.md check | Manual execution |
| Spec verification | sdd-archive-execution delta spec scenarios are satisfied by the SKILL.md logic | /sdd-verify after apply |

No automated test runner in this meta-system — all verification is manual scenario-based or via `/sdd-verify`.

## Migration Plan

No data migration required. The 4 known orphan changes in `openspec/changes/` will surface the WARNING prompt the next time a user attempts to archive them — this is intentional behavior.

## Open Questions

None.
