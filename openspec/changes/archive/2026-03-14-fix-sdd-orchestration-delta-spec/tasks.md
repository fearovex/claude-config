# Task Plan: 2026-03-14-fix-sdd-orchestration-delta-spec

Date: 2026-03-14
Design: openspec/changes/2026-03-14-fix-sdd-orchestration-delta-spec/design.md

## Progress: 3/3 tasks

## Phase 1: Delta Spec Correction

- [x] 1.1 Rewrite `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` — replace both Approach A requirements and all 7 scenarios with one Approach B requirement (`Orchestrators do not inject SPEC CONTEXT blocks`) and 2 scenarios (`Sub-agent prompt template contains no SPEC CONTEXT block` and `Phase skill self-selects spec context independently`), following the exact structure in design.md § Interfaces and Contracts

## Phase 2: Validation

- [x] 2.1 Read `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` after rewrite — confirm zero Approach A requirements present (no reference to SPEC CONTEXT block injection, no orchestrator-side domain inference, no ranking algorithm)

- [x] 2.2 Read `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` — confirm Spec Compliance Matrix has zero `⚠️ PARTIAL` rows for the `sdd-orchestration` domain and overall Verdict is `PASS` (this file was already updated by sdd-spec; task is a confirmation read, not a write)

---

## Implementation Notes

- The verify-report.md was already updated by the sdd-spec sub-agent — it currently shows `✅ COMPLIANT` for all sdd-orchestration rows and `## Verdict: PASS`. Task 2.2 is a read-only confirmation.
- The delta spec rewrite content is fully specified in `design.md` § Interfaces and Contracts and § Data Flow — the implementer should reproduce that content verbatim.
- No SKILL.md files, CLAUDE.md, or master specs are modified by this change.
- After sdd-apply completes, run `bash install.sh` (no deployed files changed, but Workflow A convention applies to openspec/ artifacts) and commit.

## Blockers

None.
