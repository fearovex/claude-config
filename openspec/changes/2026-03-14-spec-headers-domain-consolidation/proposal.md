# Proposal: spec-headers-domain-consolidation

Date: 2026-03-14
Status: Draft

## Intent

Normalize spec file headers across 5 legacy domains to the canonical structured format, and consolidate the split `sdd-apply` / `sdd-apply-execution` domains into a single spec file so that all behavior for one skill lives in one place.

## Motivation

55 spec domains exist under `openspec/specs/`. Five of them use a legacy inline-prose header format (`*Created: ...`  or bare key lines + `---`) instead of the canonical structured `Change: / Date:` block adopted in all recent changes. This inconsistency makes tooling-assisted parsing fragile and violates the uniform spec header convention established across the system.

Additionally, `sdd-apply` and `sdd-apply-execution` are two separate domain directories that both specify behavior for the same skill (`sdd-apply`). They were created in different change cycles and have no cross-references. A reader of `sdd-apply/spec.md` will not discover the TDD mode behavior without already knowing to look in `sdd-apply-execution/`. This discoverability gap violates the "one skill = one spec domain" principle and creates maintenance risk (future changes may update one without the other).

## Scope

### Included

- Backfill structured `Change:` / `Date:` headers in all 5 legacy spec files: `sdd-apply`, `sdd-apply-execution`, `sdd-verify-execution`, `smart-commit`, `solid-ddd-skill`
- Merge content of `sdd-apply-execution/spec.md` into `sdd-apply/spec.md` as a new clearly-delimited section (`## Part 2: TDD Mode and Output`)
- Retire the `sdd-apply-execution/` domain directory (delete the directory) after merge
- Update `ai-context/architecture.md` references to `sdd-apply-execution/spec.md` → `sdd-apply/spec.md`

### Excluded (explicitly out of scope)

- Changes to the content or requirements within the spec files (header normalization only, except for the sdd-apply merge which is purely additive)
- Changes to any of the 50 already-canonical spec domains
- Changes to skill SKILL.md files (this is a spec-layer change only)
- Creating or updating any ADR (the change is maintenance-level, not architecturally novel)

## Proposed Approach

For the 4 non-consolidated specs (`sdd-verify-execution`, `smart-commit`, `solid-ddd-skill`, plus `sdd-apply` itself as target of the merge): replace the legacy header block at the top of each file with the canonical two-line structured block:

```
Change: YYYY-MM-DD-<originating-slug>
Date: YYYY-MM-DD
```

Originating slugs are taken directly from the legacy header text (already identified in exploration.md).

For `sdd-apply-execution`: backfill its header, then append its full content as `## Part 2: TDD Mode and Output` at the end of `sdd-apply/spec.md`. The appended content is unmodified — no requirements are rewritten. After a successful merge, delete `openspec/specs/sdd-apply-execution/` directory.

Finally, update the two `architecture.md` key decision entries that reference `openspec/specs/sdd-apply-execution/spec.md` to point to `openspec/specs/sdd-apply/spec.md`.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `openspec/specs/sdd-apply/spec.md` | Modified (header backfill + appended Part 2 section) | Low |
| `openspec/specs/sdd-apply-execution/spec.md` | Retired (deleted after merge) | Low |
| `openspec/specs/sdd-verify-execution/spec.md` | Modified (header backfill only) | Low |
| `openspec/specs/smart-commit/spec.md` | Modified (header backfill only) | Low |
| `openspec/specs/solid-ddd-skill/spec.md` | Modified (header backfill only) | Low |
| `ai-context/architecture.md` | Modified (path references updated) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Content loss during sdd-apply-execution merge | Low | Medium | Read both files before writing; verify line count in merged file ≥ sum of both sources |
| Incorrect originating slug used in backfilled header | Low | Low | Slugs sourced directly from existing legacy header text — no inference needed |
| architecture.md reference update missed | Low | Low | Only two entries reference sdd-apply-execution; both identified in exploration.md |
| smart-commit near-canonical format causes parser confusion | Low | Low | Noted in exploration.md; apply agent must replace bare-key-lines + `---` block, not italic |

## Rollback Plan

All target files are tracked in git. If any edit produces an error or unwanted result:

1. `git diff openspec/specs/` and `git diff ai-context/architecture.md` to identify affected files
2. `git checkout -- openspec/specs/sdd-apply/spec.md openspec/specs/sdd-verify-execution/spec.md openspec/specs/smart-commit/spec.md openspec/specs/solid-ddd-skill/spec.md ai-context/architecture.md` to restore originals
3. If `sdd-apply-execution/` was already deleted: `git checkout -- openspec/specs/sdd-apply-execution/spec.md` restores the file; recreate the directory if needed (`mkdir -p openspec/specs/sdd-apply-execution/`)
4. No install.sh run is needed — this change affects only openspec/specs/ and ai-context/, not skills/ or CLAUDE.md

## Dependencies

- None. All target files exist and have been read as confirmed in exploration.md.
- No other active SDD changes are modifying the affected files.

## Success Criteria

- [ ] All 5 legacy spec files have a `Change: <slug>` / `Date: <date>` structured header block as the first content after the `# Spec:` title
- [ ] `openspec/specs/sdd-apply/spec.md` contains a `## Part 2: TDD Mode and Output` section with the full content previously in `sdd-apply-execution/spec.md`
- [ ] `openspec/specs/sdd-apply-execution/` directory no longer exists
- [ ] `ai-context/architecture.md` key decision entries previously referencing `openspec/specs/sdd-apply-execution/spec.md` now reference `openspec/specs/sdd-apply/spec.md`
- [ ] No spec file content was lost or altered beyond the header additions and the additive Part 2 merge

## Effort Estimate

Low (hours) — all changes are localized text edits and one directory deletion. No logic changes, no new files to design.
