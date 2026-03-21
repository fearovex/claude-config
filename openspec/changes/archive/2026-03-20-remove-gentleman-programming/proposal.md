# Proposal: remove-gentleman-programming

Date: 2026-03-20
Status: Draft

## Intent

Remove all live references to "Gentleman-Programming" / "Gentleman-Skills" / "gentleman-programming" from active configuration files, replacing brand-specific labels with neutral equivalents, while preserving historical records in archives and changelog entries unchanged.

## Motivation

The global Claude Code configuration currently carries attribution labels tied to the "Gentleman-Programming" external brand across 41 file locations. These labels have no functional significance for the SDD system — they are metadata (author frontmatter), section headers, and explanatory notes. Keeping them creates unnecessary coupling to an external brand identity that is not part of the project's architecture or governance model. Removing them produces a cleaner, self-contained configuration that does not imply external dependency or endorsement.

## Supersedes

### REMOVED

- **`author: gentleman-programming` frontmatter field** (`skills/*/SKILL.md` — 17 files)
  Reason: The `author:` field is metadata attribution with no functional role in the SDD system. No spec requires its presence. Removing it eliminates the brand reference without any behavioral change.

- **Section header label "extracted from Gentleman-Skills"** (`CLAUDE.md` line 651)
  Reason: The Skills Registry header `### Technology Skills (global catalog — extracted from Gentleman-Skills)` implies external source attribution that is no longer accurate or necessary. Renamed to `### Technology Skills (global catalog)`.

- **Corpus attribution notes in `docs/format-types.md`** (3 occurrences at lines 120, 202, 272)
  Reason: Explanatory notes reference "externally-sourced skills from the Gentleman-Skills corpus" to justify audit exceptions for variant headings. The exception logic is sound regardless of the source label. Rephrasing to "externally-sourced skills" preserves the rule without the brand name.

- **Attribution line in `docs/architecture-definition-report.md`** (line 8)
  Reason: The line `> **Reference**: Based on [agent-teams-lite](https://github.com/Gentleman-Programming/agent-teams-lite) v2.0` is an internal reference note. Removing it eliminates the brand reference; the document remains self-contained.

- **Brand references in master specs** (`openspec/specs/format-contract/spec.md` lines 13, 135; `openspec/specs/skills-catalog-format/spec.md` line 35)
  Reason: Live master specs reference the corpus by name in requirement descriptions. Rephrasing to "externally-sourced skills" preserves the requirement semantics.

- **Corpus reference in `ai-context/known-issues.md`** (line 110)
  Reason: An explanatory structural note references "Gentleman-Skills corpus". This is a live memory file (not a historical record) and can be rephrased without loss of meaning.

### REPLACED

| Old | New | Reason |
|-----|-----|--------|
| `author: gentleman-programming` | _(line removed)_ | No functional role; pure attribution metadata |
| `### Technology Skills (global catalog — extracted from Gentleman-Skills)` | `### Technology Skills (global catalog)` | Neutral label; source attribution not required |
| `"externally-sourced skills from the Gentleman-Skills corpus"` (3 occurrences) | `"externally-sourced skills"` | Rule logic is source-name-agnostic |
| `> **Reference**: Based on agent-teams-lite...` | _(line removed)_ | Internal doc; external attribution not required |
| `"Gentleman-Skills corpus"` references in master specs | `"externally-sourced skills"` | Preserves requirement semantics |
| `"Gentleman-Skills corpus"` in `ai-context/known-issues.md` | `"externally-sourced skills"` | Live memory file — rephrase is safe |

## Scope

### Included

- Remove `author: gentleman-programming` from YAML frontmatter of 17 skill files under `skills/`
- Rename section header in `CLAUDE.md` (1 line change)
- Rephrase 3 explanatory notes in `docs/format-types.md`
- Remove or neutralize attribution line in `docs/architecture-definition-report.md`
- Rephrase 2 references in `openspec/specs/format-contract/spec.md`
- Rephrase 1 reference in `openspec/specs/skills-catalog-format/spec.md`
- Rephrase 1 note in `ai-context/known-issues.md`
- Add a new `ai-context/changelog-ai.md` entry documenting the removal (append-only)
- Run `install.sh` to deploy the updated config to `~/.claude/`

### Excluded (explicitly out of scope)

- **Archive files** (`openspec/changes/archive/**`) — historical records of completed SDD cycles; editing them would corrupt the project's decision audit trail
- **Existing `ai-context/changelog-ai.md` entries** — append-only historical records; prior entries must not be edited
- **External GitHub URL** (the URL itself within `architecture-definition-report.md`) — if the line is removed entirely the URL is gone; if kept, the URL is factual external attribution and must not be modified
- **Creating any new skill or spec domain** — this is a purely cosmetic cleanup with no architectural changes

## Proposed Approach

All changes are cosmetic (metadata removal, label renaming, note rephrasing). The approach is a targeted find-and-replace pass across the 7 identified file groups. No behavioral changes, no spec semantic changes, no skill logic changes. The format contract exception in `docs/format-types.md` (accepting variant headings from externally-sourced skills) is preserved verbatim except for removal of the brand name. After file edits, `install.sh` deploys the updated config.

## Affected Areas

| Area/Module | Type of Change | Impact |
|---|---|---|
| `skills/*/SKILL.md` (17 files) | Removed — `author:` frontmatter line | Low |
| `CLAUDE.md` | Modified — 1 section header | Low |
| `docs/format-types.md` | Modified — 3 explanatory notes | Low |
| `docs/architecture-definition-report.md` | Removed — 1 attribution line | Low |
| `openspec/specs/format-contract/spec.md` | Modified — 2 requirement descriptions | Low |
| `openspec/specs/skills-catalog-format/spec.md` | Modified — 1 requirement description | Low |
| `ai-context/known-issues.md` | Modified — 1 explanatory note | Low |
| `ai-context/changelog-ai.md` | New entry appended | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Format contract regression: variant heading exception accidentally removed | Low | Medium | Verify that the variant heading exception logic (`## Critical Patterns`, `## Code Examples`) is preserved in `docs/format-types.md` after rephrasing |
| CLAUDE.md section header mismatch with installed `~/.claude/CLAUDE.md` | Low | Low | Run `install.sh` after changes; verify runtime file matches repo |
| Master spec semantic drift: rephrase changes meaning of a requirement | Very Low | Low | Review each rephrased spec line for semantic equivalence before committing |

## Rollback Plan

All changes are to text files under version control. To revert:

1. `git diff HEAD` — identify all modified files
2. `git checkout -- <file>` for each modified file, or `git reset --hard HEAD` to revert all uncommitted changes
3. Run `install.sh` to redeploy the reverted config to `~/.claude/`

No data migration, no schema change, no external system impact — rollback is instant.

## Dependencies

- No blocking dependencies
- `install.sh` must be run after apply to propagate changes to `~/.claude/`

## Success Criteria

- [ ] Zero occurrences of "gentleman-programming", "Gentleman-Skills", "Gentleman-Programming" in all live files (CLAUDE.md, skills/, docs/, openspec/specs/, ai-context/known-issues.md) — verified by `grep -ri "gentleman" skills/ docs/ openspec/specs/ CLAUDE.md ai-context/known-issues.md`
- [ ] `docs/format-types.md` format contract exception for variant headings (`## Critical Patterns`, `## Code Examples`) is still present and semantically equivalent after rephrasing
- [ ] All 17 skill YAML frontmatter blocks are valid after `author:` line removal (no frontmatter parse errors)
- [ ] Archive files and prior changelog entries are unchanged — verified by `git diff openspec/changes/archive/ ai-context/changelog-ai.md` showing no deletions in existing lines
- [ ] `install.sh` runs without errors after apply

## Effort Estimate

Low (hours) — all 24 edits are single-line or multi-line text replacements across 8 file groups. No logic changes required.

## Context

Recorded from conversation at 2026-03-20T00:00Z:

### Explicit Intents

- **Remove gentleman-programming references from live files only**: historical records (archives, changelog entries) must not be edited — they are append-only or sealed records.
- **Purely cosmetic change**: no behavioral or architectural changes; only metadata, labels, and explanatory notes are affected.
