# Proposal: 2026-03-19-sdd-archive-orphan-validation

Date: 2026-03-19
Status: Draft

## Intent

Add a completeness validation step to `sdd-archive` that detects incomplete SDD cycles before they are irreversibly archived, distinguishing between CRITICAL missing artifacts (block) and WARNING-level missing artifacts (confirm with explicit acknowledgment).

## Motivation

`sdd-archive` currently validates only `verify-report.md` before archiving. It does not check whether the other required SDD artifacts (`proposal.md`, `tasks.md`, `design.md`, `specs/`) are present. This allows incomplete or abandoned change directories to be archived without any signal that the cycle was not completed.

Historical analysis of 65 archived changes shows `proposal.md` and `tasks.md` are present in 100% of cases, `design.md` and `specs/` in ~86%, and `exploration.md` in only ~34%. This empirical data establishes a clear required/optional boundary. Currently there are 4 orphan changes in `openspec/changes/` that would fail a completeness check — exactly the accumulation problem this change addresses.

Since `sdd-archive` is the only terminal node in the SDD phase DAG, it is the correct and only place to perform a retroactive completeness check.

## Scope

### Included

- Expand `sdd-archive` Step 1 ("Verify it is archivable") with a completeness check block that runs before the existing `verify-report.md` check
- CRITICAL gate: missing `proposal.md` or `tasks.md` → block, no proceed option
- WARNING gate: missing `design.md` or missing/empty `specs/` directory → present option 1 (return and complete) or option 2 (archive with explicit acknowledgment)
- When the user acknowledges skipped phases, record a `Skipped phases:` field in `CLOSURE.md`
- Write a delta spec for `sdd-archive-execution` capturing the new validation requirements and scenarios

### Excluded (explicitly out of scope)

- No config-driven artifact checklist (`openspec/config.yaml` key) — over-engineering for this meta-system
- No changes to other SDD phase skills — the check is terminal only
- No automated remediation of orphan changes currently in `openspec/changes/` — those are surfaced naturally when a user attempts to archive them
- No change to `exploration.md` handling — it remains unchecked (optional by definition)
- No change to `prd.md` handling — it remains unchecked (optional by definition)

## Proposed Approach

Insert a structured completeness check at the top of `sdd-archive` Step 1, before the `verify-report.md` check, using a two-tier severity model consistent with how other SDD skills handle warnings:

1. **CRITICAL artifacts** (`proposal.md`, `tasks.md`): if either is absent, output a `CRITICAL` block listing the missing files and halt — no option to proceed. These files are present in 100% of valid archived cycles; their absence means the change was never properly proposed or planned.

2. **WARNING artifacts** (`design.md`, `specs/` directory non-empty): if any are absent, output a `WARNING` block listing the missing files and present a two-option prompt:
   - Option 1: Return and complete the missing phases
   - Option 2: Archive anyway with explicit acknowledgment that these phases were intentionally skipped
   If the user selects option 2, the `CLOSURE.md` produced in Step 5 includes a `Skipped phases:` field recording which phases were omitted.

3. Existing behavior (verify-report.md check, user confirmation prompt) is unchanged and continues after the new check passes.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `skills/sdd-archive/SKILL.md` | Modified — Step 1 expansion | Medium — adds validation logic before the confirmation prompt |
| `openspec/specs/sdd-archive-execution/spec.md` | Modified — delta spec | Low — new requirement section + 4 new scenarios |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Existing incomplete changes blocked unexpectedly | High (4 known orphans) | Low — intentional; user can acknowledge | Document in this proposal; the gate surfaces them as intended |
| Legitimate hotfix/trivial cycles that skip design are blocked | Low — WARNING not CRITICAL | Low | Option 2 (acknowledge and proceed) is always available for WARNING-level missing artifacts |
| Users select option 2 habitually (prompt fatigue) | Low | Low — the acknowledgment is recorded in CLOSURE.md; pattern is visible in audit | Acceptable — the record in CLOSURE.md creates a paper trail |

## Rollback Plan

Revert `skills/sdd-archive/SKILL.md` to the previous version via `git revert` or `git checkout <previous-commit> -- skills/sdd-archive/SKILL.md`. Run `install.sh` to deploy the reverted file to `~/.claude/`. The delta spec in `openspec/specs/sdd-archive-execution/spec.md` can be reverted the same way. No data is lost — the change only modifies skill instructions and a spec file.

## Dependencies

- None — the `sdd-archive` skill and `sdd-archive-execution` spec exist already; this is an additive expansion

## Success Criteria

- [ ] `sdd-archive` blocks (no proceed option) when `proposal.md` is absent from the change directory
- [ ] `sdd-archive` blocks (no proceed option) when `tasks.md` is absent from the change directory
- [ ] `sdd-archive` presents a two-option acknowledgment prompt when `design.md` is absent
- [ ] `sdd-archive` presents a two-option acknowledgment prompt when `specs/` is absent or empty
- [ ] When option 2 is selected, `CLOSURE.md` includes a `Skipped phases:` field listing the omitted phases
- [ ] The completeness check runs BEFORE the existing `verify-report.md` check and the irreversibility confirmation prompt
- [ ] Happy path (all required artifacts present) produces no additional output or prompts
- [ ] `openspec/specs/sdd-archive-execution/spec.md` contains at least one scenario for CRITICAL block and one for WARNING acknowledgment

## Effort Estimate

Low-Medium (hours to 1 day)
