# Exploration: fix-sdd-orchestration-delta-spec

Date: 2026-03-14

## Current State

### Problem

The change `2026-03-14-specs-as-subagent-background` has a delta spec at:

`openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md`

This delta spec was authored by the `sdd-spec` sub-agent during the spec phase, **before** the design phase resolved the implementation approach. The spec was written assuming **Approach A** (orchestrator injects a `SPEC CONTEXT` block into the sub-agent Task prompt in `CLAUDE.md`).

The `sdd-design` sub-agent subsequently chose **Approach B** (each phase skill independently self-selects and loads spec files in its own Step 0 sub-step). This choice is documented in `design.md` Technical Decisions row 1 and has been fully implemented.

The result: the delta spec for `sdd-orchestration` describes requirements that were explicitly discarded, causing three `⚠️ PARTIAL` entries in the verify-report.md Spec Compliance Matrix:

1. `SPEC CONTEXT block in sub-agent prompt (Approach A)` — not implemented by design
2. `Date prefix excluded from token set` — explicit date-prefix exclusion not implemented (Approach A concern)
3. `Exact directory name match outranks partial match` — ranking not implemented (Approach A concern)

The verify-report correctly identifies this as a "scope divergence" and notes the suggestion: "update the sdd-orchestration delta spec to reflect Approach B."

### Affected Files

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `openspec/changes/2026-03-14-specs-as-subagent-background/specs/sdd-orchestration/spec.md` | REWRITE — describes Approach A requirements that were discarded | This is the delta spec that needs to be updated |
| `openspec/changes/2026-03-14-specs-as-subagent-background/verify-report.md` | READ — identifies the PARTIAL warnings | Provides the acceptance criteria for what "fixed" looks like |
| `openspec/changes/2026-03-14-specs-as-subagent-background/design.md` | READ — documents Approach B decisions | Primary source of truth for what the delta spec should say |
| `openspec/specs/sdd-orchestration/spec.md` | READ — base/master spec | Provides the stable base that the delta spec extends |

### What the Delta Spec Currently Says (Approach A)

The existing delta spec has two top-level requirements:

1. **"Sub-agent launch template includes a SPEC CONTEXT block"** — requires the orchestrator (CLAUDE.md / sdd-ff / sdd-new) to inject an explicit SPEC CONTEXT block into every sub-agent Task prompt with: inferred domain names, explicit file paths, precedence declaration, role declaration for ai-context/. Includes 5 scenarios.

2. **"Domain inference is deterministic and auditable"** — requires the orchestrator to implement a specific domain inference algorithm (split slug, discard date prefix, match against openspec/specs/ directories, rank exact > partial, cap at 5). Includes 2 scenarios.

Both requirements are **orchestrator-side concerns**. The implementation actually done is **phase-skill-side** (each skill does its own domain discovery).

### What Approach B Actually Implemented

Per `design.md` and the verify-report's Coherence section, Approach B provides:

- Each of the 5 phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`) has a new Step 0 sub-step that **self-selects** relevant spec files
- The self-selection algorithm: `stems = change_name.split("-").filter(s => s.length > 1)` — match against `openspec/specs/` domain directory names; hard cap at 3 matches
- Non-blocking: INFO-level note on missing directory or unreadable files; never blocks or fails
- Spec files loaded as authoritative behavioral contracts; `ai-context/` remains supplementary
- `sdd-apply` explicitly excluded (operates against delta specs only)
- Convention document at `docs/SPEC-CONTEXT.md` defines the full contract
- Master spec extended at `openspec/specs/sdd-context-loading/spec.md` (not `sdd-orchestration`)

### Key Difference in Scope

The delta spec for `sdd-orchestration` was targeting **orchestrator behavior** (CLAUDE.md, sdd-ff, sdd-new). The actual implementation is entirely within **phase skill behavior** (the 5 individual SKILL.md files). The orchestrator was explicitly **not** modified — `design.md` Data Flow diagram includes the comment "Sub-agent receives CONTEXT block (unchanged — no SPEC CONTEXT injected)".

## Analyzed Approaches

### Approach A: Delete the delta spec entirely

**Description**: Remove `specs/sdd-orchestration/spec.md` from the change folder. The sdd-orchestration master spec at `openspec/specs/sdd-orchestration/spec.md` remains unchanged (it covers slug inference and exploration-as-Step-0, which are unrelated to this change).

**Pros**: Simple; avoids having a stale delta spec in the archive
**Cons**: No documentary record that Approach A was considered and rejected; the verify-report still references the delta spec domain and its PARTIAL warnings — the verify-report itself would need updating too
**Estimated effort**: Low
**Risk**: Low — but incomplete (verify-report still has PARTIAL rows that reference this domain)

### Approach B: Rewrite the delta spec to describe Approach B requirements (recommended)

**Description**: Replace the delta spec content with requirements that accurately describe what was implemented: the phase-skill self-selection behavior. The new delta spec should require:

1. Each of the 5 phase skills implements a spec context preload sub-step
2. The sub-step uses the stem-based matching algorithm (split, filter single-char, match against openspec/specs/ domains)
3. Hard cap of 3 matches
4. Non-blocking contract (INFO on missing files; never status: blocked or failed)
5. Spec files treated as authoritative behavioral contracts; ai-context/ remains supplementary
6. sdd-apply is excluded

This transforms the delta spec from "what orchestrators should do (Approach A)" to "what phase skills should do (Approach B)".

**Pros**: Delta spec truthfully describes what was built; verify-report PARTIAL entries can become COMPLIANT on re-verification; archive is self-consistent
**Cons**: Requires editing the spec file; verify-report should also be re-verified afterward
**Estimated effort**: Low
**Risk**: Low

### Approach C: Update verify-report to close PARTIAL warnings without touching the delta spec

**Description**: Annotate the verify-report to mark the PARTIAL rows as ACCEPTED DEVIATION with rationale, acknowledging the design override.

**Pros**: Minimal file changes; preserves audit trail of the Approach A spec
**Cons**: Leaves a permanently mismatched delta spec in the archive; future readers of the archive will find a spec that does not reflect the implementation; violates the spirit of SDD (specs should describe reality)
**Estimated effort**: Very low
**Risk**: Medium (data integrity — misleading archive)

## Recommendation

**Approach B** — Rewrite the delta spec to describe Approach B requirements.

The SDD principle is that delta specs describe the behavioral requirements for what is being built. The delta spec was authored speculatively before the design decision; now that the design is final and implementation is complete, the delta spec should be updated to reflect the actual contract. This is not retroactive spec-writing — it is correcting a known divergence (documented in the verify-report itself) before archiving.

The rewrite scope is narrow:
- The `sdd-orchestration` delta spec currently has 2 requirements + 7 scenarios
- The replacement will have requirements describing phase-skill behavior (which is already documented in the master spec at `openspec/specs/sdd-context-loading/spec.md`)
- The replacement scenarios should be specific to what the sdd-orchestration-related behavior change means: the orchestrators are **not** modified; the expectation is that sub-agents receive spec context through self-selection, not injection

After the delta spec is rewritten, the verify-report should be re-run (or the PARTIAL entries updated to COMPLIANT with the corrected spec as evidence).

## Identified Risks

- **Archiving while PARTIAL**: If the change is archived without fixing the delta spec, the archive will contain a permanently misleading spec. Low technical impact but violates SDD audit trail integrity.
- **Verify-report consistency**: After rewriting the delta spec, the verify-report's sdd-orchestration rows need to be updated to COMPLIANT. This is a sdd-verify step. The current verify-report already has a clear note explaining the divergence — updating it is low risk.

## Open Questions

None. The design decision is documented and final. The implementation is verified correct. The only open item is the delta spec text itself.

## Ready for Proposal

Yes — the scope is clear, narrow, and well-bounded. The existing verify-report provides the exact acceptance criteria (the three PARTIAL rows that should become COMPLIANT).
