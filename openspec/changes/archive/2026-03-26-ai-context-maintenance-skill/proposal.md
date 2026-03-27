# Proposal: 2026-03-26-ai-context-maintenance-skill

Date: 2026-03-26
Status: Draft

## Intent

Create a new `memory-maintain` skill that performs periodic housekeeping on the `ai-context/` memory layer — archiving old changelog entries, separating resolved known-issues, generating an index entry point, and detecting CLAUDE.md configuration gaps.

## Motivation

The `ai-context/` memory layer has no maintenance mechanism. `changelog-ai.md` has grown to 2373 lines and continues to grow unbounded, making it expensive to load in context windows and less useful as a quick reference. `known-issues.md` accumulates resolved items without formal separation. There is no single-page index explaining what files exist in `ai-context/` and when each was last updated. These are all periodic housekeeping tasks that no existing skill handles — `memory-init` generates from scratch, `memory-update` records session-by-session changes, but neither performs backlog cleanup.

## Supersedes

None — this is a purely additive change.

## Scope

### Included

- New `skills/memory-maintain/SKILL.md` with procedural format
- Step 1: Archive `changelog-ai.md` — keep last 30 entries, move older entries to `ai-context/changelog-ai-archive.md`
- Step 2: Separate `known-issues.md` — move items marked FIXED/RESOLVED to `ai-context/known-issues-archive.md`
- Step 3: Generate or update `ai-context/index.md` — summary of all files in `ai-context/`, their purpose, and last-updated dates
- Step 4: Detect missing "Active Constraints" section in project CLAUDE.md — advisory INFO note only
- Step 5: Produce a maintenance report summarizing actions taken
- Dry-run first mode: skill shows planned changes, then asks user confirmation before writing
- Respect `[auto-updated]` marker boundaries in ai-context/ files
- Delta spec for the `memory-management` domain (or new `memory-maintenance` domain)
- Registration in CLAUDE.md Skills Registry under Meta-tools
- Registration in CLAUDE.md Commands section

### Excluded (explicitly out of scope)

- Modifying existing `memory-update` or `memory-init` skills — this skill is complementary, not a replacement
- Creating or updating feature files in `ai-context/features/` — that is `codebase-teach`'s responsibility
- Auto-fixing CLAUDE.md Active Constraints gaps — detection only, not remediation
- Automatic scheduling or triggering — user invokes manually via `/memory-maintain`
- Archiving or cleaning `ai-context/features/` files — read-only for index generation
- Adding a new dimension to `project-audit` — out of scope for this cycle

## Proposed Approach

Create a standalone procedural skill `memory-maintain` in the `memory-*` family (alongside `memory-init` and `memory-update`). The skill follows a 5-step sequential flow:

1. **Changelog archiving**: Count entries in `changelog-ai.md`. If more than 30, move entries beyond the 30th to `changelog-ai-archive.md` (append to existing archive or create new). An "entry" is defined as a contiguous block starting with a heading marker (e.g., `### ` or `## `).
2. **Known-issues separation**: Scan `known-issues.md` for items containing FIXED or RESOLVED markers. Move those items to `known-issues-archive.md` under a `## Resolved Issues` section with date of archival.
3. **Index generation**: Walk `ai-context/` directory, read each `.md` file's first heading and `Last updated:` date, produce `ai-context/index.md` as a table of contents. If `index.md` already exists, regenerate it (idempotent — always reflects current state).
4. **CLAUDE.md gap detection**: Read the project-root `CLAUDE.md` and check for an "Active Constraints" section near the top. If absent, emit an INFO advisory note in the report. This is detection-only — the skill does not write to CLAUDE.md.
5. **Maintenance report**: Print a summary of all actions taken (entries archived, issues moved, index updated, advisories emitted).

The skill uses a **dry-run-first** interaction pattern: it computes all planned changes, presents them to the user, and only writes files after explicit confirmation. This mirrors the pattern used by `sdd-spec-gc` and `project-claude-organizer`.

Key design decisions:
- **Archive threshold**: Keep last 30 entries (count-based, not date-based) — simpler to implement and predictable
- **Index.md regeneration**: Always regenerate on every run (idempotent) — no stale-index risk
- **Active Constraints scope**: Project-local CLAUDE.md only — the global `~/.claude/CLAUDE.md` is not in scope for this advisory (users maintain it directly)
- **Archive file convention**: `changelog-ai-archive.md` and `known-issues-archive.md` are new file conventions in `ai-context/` — documented in the skill and referenced in conventions

## Affected Areas

| Area/Module | Type of Change | Impact |
| --- | --- | --- |
| `skills/memory-maintain/` | New | Medium — new skill directory + SKILL.md |
| `ai-context/changelog-ai.md` | Modified (by skill at runtime) | Medium — entries archived |
| `ai-context/changelog-ai-archive.md` | New (created by skill at runtime) | Low — receives archived entries |
| `ai-context/known-issues.md` | Modified (by skill at runtime) | Low — resolved items moved out |
| `ai-context/known-issues-archive.md` | New (created by skill at runtime) | Low — receives resolved items |
| `ai-context/index.md` | New (created by skill at runtime) | Low — entry point for memory layer |
| `CLAUDE.md` (project) | Modified | Low — new command + registry entry |
| `openspec/specs/memory-management/spec.md` | Modified | Low — delta spec for new requirements |
| `openspec/specs/index.yaml` | Modified | Low — updated keywords or new domain entry |

## Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| Changelog entry boundary detection is fragile (entries may not have consistent heading format) | Medium | Medium | Define entry boundary heuristic clearly in spec; test against actual `changelog-ai.md` format |
| Archive files grow unbounded over time | Low | Low | Acceptable — archive files are rarely loaded; can add a second-tier archive later if needed |
| `[auto-updated]` markers corrupted during known-issues separation | Low | High | Skill rules explicitly mandate respecting marker boundaries; dry-run preview catches issues before write |
| Active Constraints convention is undefined — advisory may confuse users | Low | Low | Frame as INFO-level suggestion, not a warning; document what the section would contain |

## Rollback Plan

1. Delete `skills/memory-maintain/` directory
2. Revert CLAUDE.md changes (remove registry entry and command)
3. Revert delta spec changes in `openspec/specs/memory-management/spec.md`
4. Revert `openspec/specs/index.yaml` changes
5. Run `bash install.sh` to deploy reverted state
6. Note: any archive files created by the skill at runtime (`changelog-ai-archive.md`, `known-issues-archive.md`, `index.md`) would need manual review — they contain valid historical data and may be worth keeping even if the skill is rolled back

## Dependencies

- Exploration completed: `openspec/changes/2026-03-26-ai-context-maintenance-skill/exploration.md`
- Existing `memory-management` spec domain must be readable for delta spec authoring
- `ai-context/changelog-ai.md` and `ai-context/known-issues.md` must exist (non-blocking if absent — skill skips the corresponding step)

## Success Criteria

- [ ] `skills/memory-maintain/SKILL.md` exists with procedural format, valid frontmatter, `**Triggers**`, `## Process`, and `## Rules` sections
- [ ] Running `/memory-maintain` on the agent-config project produces a dry-run preview showing planned changelog archiving (>30 entries exist)
- [ ] After user confirmation, `changelog-ai.md` retains only the last 30 entries and `changelog-ai-archive.md` contains the rest
- [ ] Known-issues items marked FIXED/RESOLVED are moved to `known-issues-archive.md`
- [ ] `ai-context/index.md` is generated with a table listing all `ai-context/` files, their purpose, and last-updated dates
- [ ] CLAUDE.md Active Constraints detection produces an INFO advisory (since the section currently does not exist)
- [ ] Maintenance report summarizes all actions taken
- [ ] `[auto-updated]` marker boundaries are preserved in all modified files
- [ ] CLAUDE.md Skills Registry lists `memory-maintain` under Meta-tools
- [ ] CLAUDE.md Commands section includes `/memory-maintain`

## Effort Estimate

Medium (1-2 days) — one SKILL.md file, delta spec, CLAUDE.md registration, and index.yaml update. The bulk of the effort is in defining the entry boundary heuristic and the dry-run interaction pattern.
