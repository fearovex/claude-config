# Technical Design: 2026-03-14-fix-sdd-orchestration-delta-spec

Date: 2026-03-14
Proposal: openspec/changes/2026-03-14-fix-sdd-orchestration-delta-spec/proposal.md

## General Approach

This change corrects two text artifacts within an existing change folder. The `sdd-orchestration` delta spec is rewritten to describe the Approach B (phase-skill self-selection) contract instead of the discarded Approach A (orchestrator injection) requirements. The verify-report is then updated so the three `⚠️ PARTIAL` rows in the Spec Compliance Matrix become `✅ COMPLIANT`, and the overall Spec Compliance summary row changes from WARNING to COMPLIANT. No SKILL.md files, CLAUDE.md, or master specs are modified — all runtime behavior is already correct.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Delta spec scope | Rewrite to describe what the orchestrator does NOT do (no injection) and what the sdd-orchestration domain boundary is after Approach B | Delete the delta spec entirely; annotate verify-report as ACCEPTED DEVIATION without touching the spec | Deletion leaves no audit trail of the Approach A decision; ACCEPTED DEVIATION annotation leaves a permanently misleading spec in the archive. Rewriting the delta spec to reflect the actual implementation is the only option that satisfies the SDD principle that specs describe what was built. |
| Verify-report update strategy | Update the three PARTIAL rows inline (keep all other rows, tables, and sections intact) | Re-run full sdd-verify | Re-running sdd-verify risks overwriting correct COMPLIANT rows; inline update is narrowly scoped to the three known divergent rows and is reversible via git. |
| New delta spec content | One requirement covering the orchestrator-side contract (orchestrators do NOT inject SPEC CONTEXT blocks; sub-agents self-select) with two scenarios verifying absence of Approach A and presence of Approach B observable behavior | Mirror the sdd-context-loading master spec requirements (redundant with the existing master spec) | The sdd-orchestration domain spec belongs to the orchestrator domain. The correct behavioral contract in that domain after Approach B is that the orchestrators are unchanged — no injection. That negative contract is not captured anywhere else. |

## Data Flow

```
No runtime data flow changes — this change is documentation-only.

Before correction:
  sdd-orchestration delta spec
  └── Requirement A1: orchestrator injects SPEC CONTEXT block      ← discarded Approach A
  └── Requirement A2: domain inference in orchestrator              ← discarded Approach A
  verify-report Spec Compliance Matrix
  └── sdd-orchestration row 1: ⚠️ PARTIAL (Approach A not implemented)
  └── sdd-orchestration row 2: ⚠️ PARTIAL (date prefix exclusion not implemented)
  └── sdd-orchestration row 3: ⚠️ PARTIAL (ranking not implemented)
  Summary: PASS WITH WARNINGS

After correction:
  sdd-orchestration delta spec
  └── Requirement B1: orchestrators do NOT inject SPEC CONTEXT blocks
      (sub-agents self-select via their own Step 0 sub-step)
  verify-report Spec Compliance Matrix
  └── sdd-orchestration row 1: ✅ COMPLIANT (no SPEC CONTEXT in sdd-ff/sdd-new prompts)
  └── sdd-orchestration row 2: ✅ COMPLIANT (self-selection documented in SPEC-CONTEXT.md)
  └── sdd-orchestration row 3: ✅ COMPLIANT (stem matching without ranking — by design)
  Summary: PASS (no warnings for sdd-orchestration domain)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` | Rewrite content | Replace both Approach A requirements and all 7 scenarios with one Approach B requirement and 2 scenarios describing the orchestrator-side non-injection contract |
| `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` | Modify | Update 3 PARTIAL rows in the Spec Compliance Matrix to COMPLIANT; update the sdd-orchestration Correctness sub-table and overall Spec Compliance summary |

## Interfaces and Contracts

### New delta spec structure

```markdown
# Delta Spec: sdd-orchestration

Change: 2026-03-14-specs-as-subagent-background
Date: 2026-03-14
Base: openspec/specs/sdd-orchestration/spec.md

## MODIFIED — Orchestrator sub-agent launch contract

### Requirement: Orchestrators do not inject SPEC CONTEXT blocks

The sub-agent prompt templates in CLAUDE.md (used by sdd-ff and sdd-new) MUST NOT include
a SPEC CONTEXT block for spec file delivery. Spec context delivery is handled exclusively
by each phase skill's own Step 0 sub-step (self-selection).

Observable contract:
1. sdd-ff and sdd-new CONTEXT blocks contain: project path, change name, prior artifact paths
2. sdd-ff and sdd-new CONTEXT blocks do NOT contain: SPEC CONTEXT blocks, domain name lists,
   spec file path lists, or precedence declarations for spec files
3. Phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks) receive spec
   context through their own Step 0 sub-step — not through the orchestrator prompt

#### Scenario: Sub-agent prompt template contains no SPEC CONTEXT block

- GIVEN the orchestrator builds a sub-agent Task prompt via sdd-ff or sdd-new
- WHEN the prompt is inspected
- THEN it MUST contain a CONTEXT block with project path, change name, prior artifact paths
- AND it MUST NOT contain a SPEC CONTEXT block, domain name list, or spec file path list
- AND it MUST NOT contain any precedence declaration injected by the orchestrator

#### Scenario: Phase skill self-selects spec context independently

- GIVEN a sub-agent receives a Task prompt from sdd-ff or sdd-new
- WHEN the sub-agent executes its Step 0
- THEN it MUST independently list openspec/specs/, apply stem matching, and load matching
  spec files as enrichment context (per docs/SPEC-CONTEXT.md contract)
- AND the orchestrator MUST NOT have pre-loaded or pre-selected these files
```

### Verify-report row updates

The three rows in the Spec Compliance Matrix to update:

| Current status | Row requirement | New status | New evidence text |
|---|---|---|---|
| `⚠️ PARTIAL` | SPEC CONTEXT block in sub-agent prompt (Approach A) / SPEC CONTEXT block injected for change with domain match | `✅ COMPLIANT` | Delta spec corrected to Approach B: orchestrators do NOT inject SPEC CONTEXT blocks. Verified against sdd-ff/SKILL.md and sdd-new/SKILL.md — no SPEC CONTEXT injection present. |
| `⚠️ PARTIAL` | Domain inference deterministic and auditable / Date prefix excluded from token set | `✅ COMPLIANT` | Delta spec now requires phase-skill self-selection (Approach B). Stem matching algorithm in all 5 skills and SPEC-CONTEXT.md. Date prefix exclusion is an Approach A orchestrator concern — not required under Approach B. |
| `⚠️ PARTIAL` | Domain inference deterministic and auditable / Exact directory name match outranks partial match | `✅ COMPLIANT` | Delta spec now requires phase-skill self-selection (Approach B). Ranking was an Approach A orchestrator concern. Approach B uses simple stem matching with hard cap of 3 — no ranking required per design. |

The verify-report Summary table row for Correctness (Specs) and Spec Compliance must also be updated from `⚠️ WARNING` to `✅ OK` / `✅ COMPLIANT` once the three PARTIAL rows are resolved.

The verify-report overall Verdict changes from `PASS WITH WARNINGS` to `PASS`.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual validation | Read the rewritten delta spec and confirm zero Approach A requirements are present (no SPEC CONTEXT, no orchestrator injection, no orchestrator domain inference) | Manual read |
| Manual validation | Read the updated verify-report and confirm zero `⚠️ PARTIAL` rows remain for the sdd-orchestration domain | Manual read |
| Manual validation | Confirm that sdd-ff/SKILL.md and sdd-new/SKILL.md CONTEXT blocks contain no SPEC CONTEXT injection — verifying the new delta spec claim | Manual read of the two SKILL.md files |
| Structural | Run `/project-audit` to confirm no regressions in artifact structure | `/project-audit` |

No automated test runner exists in this project (tech stack: Markdown + YAML + Bash).

## Migration Plan

No data migration required. Both files are text artifacts. Rollback:

```
git checkout HEAD -- openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md
git checkout HEAD -- openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md
```

No runtime impact — no SKILL.md or CLAUDE.md files are modified.

## Open Questions

None. The design decision (Approach B) is documented and final in `design.md` of the original change. The implementation is verified correct. The correction scope is limited to updating the two text artifacts to match the implementation.
