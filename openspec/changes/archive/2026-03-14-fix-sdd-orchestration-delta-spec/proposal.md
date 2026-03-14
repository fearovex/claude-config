# Proposal: 2026-03-14-fix-sdd-orchestration-delta-spec

Date: 2026-03-14
Status: Draft

## Intent

Rewrite the `sdd-orchestration` delta spec in the `2026-03-14-specs-as-subagent-background` change folder to accurately describe the Approach B (phase-skill self-selection) implementation instead of the discarded Approach A (orchestrator injection) requirements.

## Motivation

The `sdd-spec` sub-agent authored the `sdd-orchestration` delta spec before the design phase resolved the implementation approach. It described Approach A requirements (orchestrator injects a SPEC CONTEXT block into every sub-agent Task prompt). The `sdd-design` sub-agent subsequently chose Approach B (each phase skill independently self-selects and loads spec files in its own Step 0 sub-step). Approach B was fully implemented and verified.

As a result, the delta spec for `sdd-orchestration` in `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` describes requirements that were explicitly discarded by design. The `verify-report.md` for that change documents three `⚠️ PARTIAL` entries in the Spec Compliance Matrix, all of which are Approach A orchestrator-side concerns not implemented by design. The change cannot be cleanly archived while its delta spec contradicts the implementation.

Leaving the mismatched delta spec in the archive would violate the SDD principle that specs describe the behavioral requirements for what was actually built.

## Scope

### Included

- Rewrite `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` to describe Approach B requirements (phase-skill self-selection behavior)
- Update `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` to change the three `⚠️ PARTIAL` Spec Compliance Matrix rows to `✅ COMPLIANT`, citing the corrected delta spec as evidence
- Update the Spec Compliance Matrix Summary row for `sdd-orchestration` domain from WARNING to COMPLIANT

### Excluded (explicitly out of scope)

- No changes to any SKILL.md files — the implementation is already correct and complete
- No changes to `openspec/specs/sdd-orchestration/spec.md` (master spec) — it covers slug inference and exploration-as-Step-0, unrelated to this change
- No changes to `openspec/specs/sdd-context-loading/spec.md` (master spec) — it already correctly describes the Approach B contract
- No changes to `docs/SPEC-CONTEXT.md` — it is authoritative and correct
- No changes to `sdd-apply` or the orchestrator (CLAUDE.md, sdd-ff, sdd-new) — they were not modified in the original change and are not part of this correction
- No new SDD phases, ADRs, or architectural decisions — this is a documentation correction within an existing change folder

## Proposed Approach

Replace the two Approach A requirements in the `sdd-orchestration` delta spec with requirements that describe the observable constraint that Approach B places on the sdd-orchestration domain: that the orchestrators (CLAUDE.md, sdd-ff, sdd-new) do NOT inject spec context into sub-agent prompts, and that sub-agents receive spec context through their own Step 0c self-selection sub-step rather than through orchestrator-side injection.

The new delta spec should have:
1. One requirement: orchestrators do not inject SPEC CONTEXT blocks — sub-agents self-select
2. Scenarios that verify the absence of Approach A behavior (no SPEC CONTEXT block in sub-agent Task prompt template) and the presence of Approach B behavior (sub-agents' Step 0c handles spec loading)

After the delta spec is corrected, update the verify-report to reflect the corrected compliance status for the three previously-PARTIAL rows.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------------- | --------------- |
| `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` | Modified (rewrite content) | Low — correction within an existing change folder |
| `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` | Modified (update 3 rows) | Low — correctness update; verdict may change from PASS WITH WARNINGS to PASS |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | --------------- | --------------- | ----------------- |
| Rewritten delta spec introduces new requirements not implemented | Low | Medium | Limit delta spec to stating what the orchestrator does NOT do (no injection) — verifiable against current SKILL.md files |
| verify-report updated incorrectly (false COMPLIANT) | Low | Medium | Cross-reference rewritten spec requirements against actual sdd-ff/sdd-new/CLAUDE.md content during sdd-verify |

## Rollback Plan

Both files are text artifacts inside `openspec/changes/2026-03-14-specs-as-subagent-background/`. Git history preserves the original content. To revert:

```
git checkout HEAD -- openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md
git checkout HEAD -- openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md
```

No deployed files (SKILL.md, CLAUDE.md) are modified by this change — rollback has zero runtime impact.

## Dependencies

- `openspec/changes/2026-03-14-specs-as-subagent-background/design.md` must be readable (authoritative source for Approach B decisions)
- `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` must be readable (provides exact acceptance criteria: the three PARTIAL rows)
- No external dependencies

## Success Criteria

- [ ] `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` contains no Approach A requirements (no SPEC CONTEXT block injection requirement, no orchestrator-side domain inference requirement)
- [ ] The rewritten delta spec has at least one requirement and at least one scenario describing the Approach B orchestrator contract
- [ ] `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` Spec Compliance Matrix has zero `⚠️ PARTIAL` rows for the `sdd-orchestration` domain
- [ ] The verify-report overall Correctness or Spec Compliance summary no longer shows WARNING for the `sdd-orchestration` domain

## Effort Estimate

Low (hours) — narrow scope: two text file edits within an existing change folder. No code changes, no new files, no skill modifications.
