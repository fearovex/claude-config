# Proposal: audit-improvements

Date: 2026-03-01
Status: Draft

## Intent

Enhance the `project-audit` skill with higher-signal checks across existing and new dimensions to reduce false positives, catch real problems earlier, and produce more actionable audit scores.

## Motivation

The current `project-audit` skill has accumulated gaps identified through real-world use: D2 passes files that contain only placeholder text, D3 does not verify hook scripts exist on disk, D7 treats a stale `analysis-report.md` as informational regardless of age, and the skill has no coverage for ADRs or spec files even though both are now first-class artifacts in the system. These gaps cause audit scores to misrepresent project health, which undermines the core purpose of the skill as an integration test.

## Scope

### Included

- **D2 enhancement**: add placeholder phrase detection (`[To be filled]`, `TODO`, `[empty]`, etc.) and require `stack.md` to list at least 3 technologies with concrete versions
- **New dimension — ADR Coverage**: when `CLAUDE.md` references `docs/adr/`, verify the README.md exists, all ADR files have a valid `status` field (`accepted`, `deprecated`, `superseded`), and archived changes with architectural decisions have corresponding ADRs
- **D3 enhancement — hooks script existence**: read `.claude/settings.json` / `settings.local.json` and verify each referenced hook script exists on disk
- **D7 enhancement — staleness score impact**: `analysis-report.md` older than 30 days reduces D7 score by 1–2 points (currently staleness is only informational)
- **D3 enhancement — active changes conflict detection**: detect when two non-archived changes declare modifications to the same files in their `design.md` file change plans
- **D1 enhancement — template path verification**: when `CLAUDE.md` mentions template paths (e.g., `docs/templates/prd-template.md`), verify those files exist on disk
- **New dimension — Spec Coverage**: when `openspec/specs/` exists, verify at least one spec per detected project domain, and that spec files reference paths that still exist

### Excluded (explicitly out of scope)

- Changes to any SDD phase skill other than `project-audit` — this proposal is scoped to the audit skill only
- Automated fixing of identified issues — `project-fix` handles that; audit only detects and reports
- Scoring weight rebalancing across existing dimensions not listed above — to be addressed in a separate change
- New ADR authoring workflow — the audit only validates existing ADRs, not the creation process
- Any changes to `openspec/config.yaml` structure — no new config keys introduced

## Proposed Approach

Each improvement is implemented as an additive check within the corresponding dimension section of `project-audit/SKILL.md`. The two new dimensions (ADR Coverage, Spec Coverage) are appended after the current 10 dimensions, each with its own scoring rubric following the same pattern as existing dimensions. The staleness score impact for D7 modifies the existing scoring logic with a conditional penalty. No new files or external dependencies are introduced — all checks read existing project files using the same file-reading pattern already used by the skill.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-audit/SKILL.md` | Modified | High |
| `ai-context/changelog-ai.md` | Modified (log entry) | Low |
| `ai-context/architecture.md` | Modified (new dimensions documented) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| New dimensions inflate audit score unexpectedly on projects that don't use ADRs or openspec/specs | Medium | Medium | New dimensions are conditional — only activated when the relevant directories/references are detected in the project |
| D7 score penalty for stale analysis breaks existing projects that have never run `/project-analyze` | Low | Medium | Penalty only applies when `analysis-report.md` exists but is older than 30 days; absence of the file uses existing behavior |
| Conflict detection in D3 produces false positives if design.md files use inconsistent path formats | Medium | Low | Normalize paths before comparison; document the known limitation in the skill |
| Adding 2 new dimensions changes the total score denominator and shifts all existing scores | High | Medium | New dimensions must be explicitly additive (e.g., bonus points or separate subscores), not part of the existing 10-dimension pool, OR the scoring rubric is updated to document the new maximum |

## Rollback Plan

All changes are isolated to `skills/project-audit/SKILL.md`. To revert:
1. `git revert <commit-sha>` on the commit that applied this change, OR
2. `git checkout <previous-sha> -- skills/project-audit/SKILL.md` to restore the prior version
3. Run `install.sh` to re-deploy the reverted file to `~/.claude/`
4. Verify with `/project-audit` on the canonical test project (Audiio V3)

## Dependencies

- `skills/project-audit/SKILL.md` must be read in full before writing the updated version
- The existing 10-dimension scoring pattern must be understood before adding new dimensions
- Test project (Audiio V3 at `D:/Proyectos/Audiio/audiio_v3_1`) must be accessible for the verify phase

## Success Criteria

- [ ] `/project-audit` on a project with placeholder-only `ai-context/` files reports D2 as failing or degraded
- [ ] `/project-audit` on a project with a hook entry in `settings.json` pointing to a non-existent script reports D3 as failing or degraded
- [ ] `/project-audit` on a project with an `analysis-report.md` older than 30 days shows a reduced D7 score compared to a fresh report
- [ ] `/project-audit` on a project with `docs/adr/` referenced in `CLAUDE.md` but no `README.md` reports the new ADR Coverage dimension as failing
- [ ] `/project-audit` on a project with a template path in `CLAUDE.md` pointing to a non-existent file reports D1 as failing or degraded
- [ ] `/project-audit` score on the Audiio V3 test project is >= current baseline score (no regression)
- [ ] All new checks are conditional — projects without the relevant artifacts receive N/A or skip the check, not a penalty

## Effort Estimate

Medium (1–2 days) — 7 incremental checks across an existing skill, each independently implementable; the two new dimensions add the most effort due to scoring rubric design.
