# Proposal: skills-catalog-analysis

Date: 2026-03-14
Status: Draft

## Intent

Resolve format contract violations and structural issues in the skills catalog so that `/project-audit` no longer produces false-positive compliance findings and the catalog consistently matches the documented structural contracts.

## Motivation

The `sdd-explore` phase identified 8 findings across the 51-skill catalog. The most impactful finding is that 22 skills fail the format contract check (`project-audit` D4b / D9-3) — not because of bad content but because of a naming convention mismatch between the externally-sourced tech skills (which use `## Critical Patterns` and `## Code Examples`) and the contract, which requires exactly `## Patterns` or `## Examples`. Running `/project-audit` on this repo currently yields MEDIUM findings for every one of these skills, depressing the audit score and masking real violations.

Additionally, `elixir-antipatterns` has a hard violation: it is declared `format: anti-pattern` but uses `## Critical Patterns` as its main section — the required `## Anti-patterns` heading is entirely absent. The `claude-code-expert` skill contains duplicate `## Description` and `**Triggers**` headings, and `sdd-verify` is the only SDD phase skill without a governance loading block (Step 0).

Fixing these issues is high-value and low-risk: the content of the skills is correct; only naming conventions and structural housekeeping need to be addressed.

## Scope

### Included

- **Phase 1 — Format contract alignment (High priority)**
  - Update `docs/format-types.md` and `project-audit` SKILL.md to accept `## Critical Patterns` and `## Code Examples` as valid `reference` format section alternatives (Option A from exploration Finding 1) — this resolves 19 tech skills in one change.
  - Fix `skills/elixir-antipatterns/SKILL.md`: rename `## Critical Patterns` → `## Anti-patterns` (hard anti-pattern format violation).
  - Fix `skills/claude-code-expert/SKILL.md`: remove duplicate `## Description` section and the redundant `**Triggers**` occurrence.

- **Phase 2 — Consistency (Medium priority)**
  - Add Step 0 governance loading block to `skills/sdd-verify/SKILL.md` for consistency with all other SDD phase skills.
  - Create `docs/sdd-slug-algorithm.md` documenting the STOP_WORDS algorithm canonically; add a reference note in both `sdd-ff` and `sdd-new` (documentation only — no behavioral change).

### Excluded (explicitly out of scope)

- Renaming `## Critical Patterns` → `## Patterns` in the 19 externally-sourced tech skills — high effort, low benefit; Option A (contract update) achieves the same compliance outcome with zero content risk.
- Extracting the Step 0 governance block into a shared `SHARED_CONTEXT.md` file — prompting context benefits from self-contained skill instructions; the resilience value outweighs the maintenance cost at the current catalog size.
- Consolidating `sdd-status` into another orchestrator skill.
- Addressing the conceptual overlap between `codebase-teach`, `memory-update`, and `project-analyze` — this is intentional and already documented in CLAUDE.md.
- Any changes to the slug algorithm behavior in `sdd-ff` or `sdd-new`.

## Proposed Approach

**Phase 1** targets the root cause of all audit false-positives: the gap between the format contract definition and the naming conventions used in 19 externally-sourced skills. Rather than refactoring 19 skills, the contract is extended to recognize the `## Critical Patterns` / `## Code Examples` headings as valid alternatives. This is a 2-file change (`docs/format-types.md` and `project-audit/SKILL.md` section detection rule). The `elixir-antipatterns` fix is a single heading rename — no content change. The `claude-code-expert` fix removes two duplicate headings.

**Phase 2** adds a Step 0 governance block to `sdd-verify` (copy-paste from any other phase skill, then trimmed to read-only context). The slug algorithm documentation is a new markdown file in `docs/` with no behavioral impact.

All changes are applied via the standard SDD cycle: apply → verify → `install.sh` → commit.

## Affected Areas

| Area/Module | Type of Change | Impact |
| --- | --- | --- |
| `docs/format-types.md` | Modified — extend `reference` format contract | Low |
| `skills/project-audit/SKILL.md` | Modified — update section detection rule | Low |
| `skills/elixir-antipatterns/SKILL.md` | Modified — rename main section heading | Low |
| `skills/claude-code-expert/SKILL.md` | Modified — remove duplicate headings | Low |
| `skills/sdd-verify/SKILL.md` | Modified — add Step 0 governance block | Low |
| `docs/sdd-slug-algorithm.md` | New — canonical slug algorithm documentation | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| `project-audit` section detection regex updated incorrectly | Low | Medium | Verify against 2-3 known-compliant skills and 2-3 known-violating skills after change |
| Step 0 added to `sdd-verify` causes unexpected blocking behavior | Low | Low | Step 0 is declared non-blocking in all phase skills; copy the exact non-blocking pattern |
| Contract extension causes a future ambiguity when adding new `reference` skills | Low | Low | Document the extended set explicitly in `docs/format-types.md`; new skills should prefer canonical `## Patterns` |

## Rollback Plan

All changes are to `.md` files tracked in git. Rollback is:

1. `git revert <commit-sha>` — reverts the commit introducing the changes.
2. `bash install.sh` — redeploys the reverted files to `~/.claude/`.

Each phase should be committed separately so Phase 1 and Phase 2 can be reverted independently.

## Dependencies

- `docs/format-types.md` must be updated before or simultaneously with `project-audit/SKILL.md` to keep the documentation and enforcement in sync.
- No external dependencies. No changes to `openspec/config.yaml` or `install.sh`.

## Success Criteria

- [ ] Running `/project-audit` on this repo produces zero MEDIUM or HIGH findings for the 19 tech skills that use `## Critical Patterns` / `## Code Examples`.
- [ ] `skills/elixir-antipatterns/SKILL.md` contains a `## Anti-patterns` section (verifiable by grep).
- [ ] `skills/claude-code-expert/SKILL.md` has exactly one `## Description` section and one `**Triggers**` occurrence.
- [ ] `skills/sdd-verify/SKILL.md` contains a Step 0 governance loading block and emits a `Governance loaded:` log line when executed.
- [ ] `docs/sdd-slug-algorithm.md` exists and is referenced by a note in both `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`.
- [ ] `bash install.sh` completes without errors after all changes are applied.
- [ ] `git log` shows at least two commits — one per phase.

## Effort Estimate

Low (hours) — all changes are markdown edits; no logic or script changes. Phase 1 is ~4 files, Phase 2 is ~3 files + 1 new doc.
