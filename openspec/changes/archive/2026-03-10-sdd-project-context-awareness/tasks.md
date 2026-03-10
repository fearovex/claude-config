# Task Plan: sdd-project-context-awareness

Date: 2026-03-10
Design: openspec/changes/sdd-project-context-awareness/design.md

## Progress: 4/4 tasks

## Phase 1: Core — Apply Step 0 to remaining skill

- [x] 1.1 Modify `skills/sdd-explore/SKILL.md` — add `### Step 0 — Load project context` block as the first step inside `## Process`, before the existing `### Step 1 — Understand the request`; use the standard (non-dual) template from `docs/sdd-context-injection.md`

## Phase 2: Documentation

- [x] 2.1 Verify `docs/sdd-context-injection.md` exists and contains all required sections: Step 0 block template, dual-block variant, graceful degradation rules, staleness threshold (7 days), how loaded context is used table, skills application table

- [x] 2.2 Verify `docs/adr/024-sdd-project-context-awareness-convention.md` exists and `docs/adr/README.md` index contains row for ADR 024

## Phase 3: Memory

- [x] 3.1 Verify `ai-context/architecture.md` contains decision 11 (SDD phase skills load project context) and confirm the entry references `docs/sdd-context-injection.md`

---

## Implementation Notes

- This change is documentation-only (all files are `.md`). The scope guard in `sdd-apply` marks it as documentation-only; `solid-ddd` preload is skipped.
- Most implementation was already complete prior to this apply run. The only real modification was 1.1 (sdd-explore SKILL.md).
- Tasks 2.1, 2.2, and 3.1 were verification tasks — confirmed by direct file inspection and grep checks.
- The dual-block structure (Step 0a / Step 0b) applies only to `sdd-propose` and `sdd-spec` — already updated before this cycle. `sdd-explore` uses the standard single Step 0.

## Blockers

None.
