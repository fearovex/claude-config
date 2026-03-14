# Proposal: specs-search-optimization

Date: 2026-03-14
Status: Draft

## Intent

Introduce a lightweight spec index at `openspec/specs/index.yaml` to enable targeted, keyword-driven spec file selection by sub-agents — replacing blind file listing or exhaustive loading as `openspec/specs/` continues to grow. Also document an MCP-backed SQLite migration path for projects reaching 100+ domains.

## Motivation

`openspec/specs/` currently holds 55 domain directories. Sub-agents that need background spec context have no structured way to identify which files are relevant without reading all of them or guessing by directory name.

As the spec catalog grows, three failure modes emerge:

1. **Exhaustive loading** — reading all 55+ files as background is expensive in tokens, degrades output quality through signal/noise dilution, and is not scalable past ~30 files.
2. **Blind name matching** — matching change slug words against directory names is fragile (vocabulary mismatch, compound concepts, synonyms).
3. **No loading** — sub-agents skip spec context entirely and fall back to the weaker ai-context/ layer, producing lower-fidelity outputs.

A small index file solves problems 1 and 2 at near-zero cost: one read of a compact YAML structure gives the sub-agent enough signal to select exactly the right 2-5 spec files.

## Scope

### Included

- Create `openspec/specs/index.yaml` covering all 55 current domains, each entry containing:
  - `domain`: directory name (matches `openspec/specs/<domain>/`)
  - `summary`: one-line description of what the spec covers
  - `keywords`: 3-8 terms that appear in change slugs or topics related to this domain
  - `related`: list of other domain names frequently co-relevant (optional, added where clear)
- Update `sdd-archive` SKILL.md to include an index maintenance step: when a new domain spec is created, the archivist agent appends its entry to `index.yaml`
- Document an ADR option for SQLite/FTS5 migration for projects reaching 100+ spec domains
- Update `docs/SPEC-CONTEXT.md` (created by companion proposal) to reference the index as the preferred domain selection mechanism

### Excluded (explicitly out of scope)

- Changes to any spec file content
- Automated index generation tooling (the initial index is hand-authored; future updates are handled by sdd-archive)
- Implementing the SQLite migration (ADR documents it as a decision option only — not implemented here)
- Changes to non-SDD skills or CLAUDE.md outside of the sdd-archive step

## Proposed Approach

**Step 1 — Author `openspec/specs/index.yaml`**

Format:

```yaml
# openspec/specs/index.yaml
# Spec domain index — one entry per domain directory under openspec/specs/
# Maintained by sdd-archive: append new entry when a new domain spec is created.

domains:
  - domain: sdd-apply
    summary: Behavioral spec for the sdd-apply phase skill (task execution and TDD mode)
    keywords: [apply, implement, execute, tasks, tdd, code-generation]
    related: [sdd-tasks, sdd-verify]

  - domain: sdd-explore
    summary: Behavioral spec for the sdd-explore phase skill (codebase investigation)
    keywords: [explore, investigate, analyze, review, discovery]
    related: [sdd-propose]

  # ... one entry per domain
```

All 55 domains are populated in the initial authoring pass.

**Step 2 — Update sdd-archive SKILL.md**

Add a step to the archive process: "If the change introduced a new spec domain (new directory under `openspec/specs/`), append its entry to `openspec/specs/index.yaml` following the existing format."

**Step 3 — Write ADR for SQLite migration path**

Create `docs/adr/NNN-spec-index-sqlite-migration.md` documenting:
- Context: flat-file index works up to ~100 domains; beyond that, FTS5 queries outperform sequential YAML parsing
- Decision options: keep flat YAML (status quo), migrate to SQLite with FTS5, use an MCP server exposing the index as a queryable resource
- Status: Proposed (not yet decided)

**Step 4 — Update SPEC-CONTEXT.md**

Add a section "Using the spec index" that describes the two-step lookup: read index.yaml → select matching domains → read those spec files.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `openspec/specs/index.yaml` | New (55-entry index) | Low |
| `skills/sdd-archive/SKILL.md` | Modified (index maintenance step) | Low |
| `docs/adr/NNN-spec-index-sqlite-migration.md` | New (ADR document) | Low |
| `docs/SPEC-CONTEXT.md` | Modified (index lookup section added) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Index becomes stale as new domains are added | Medium | Medium | sdd-archive step makes index maintenance a mandatory phase gate, not optional |
| Keyword set too narrow — relevant domain not matched | Low | Low | Sub-agent falls back to listing `openspec/specs/` directories on no-match |
| Initial hand-authoring of 55 entries contains errors | Low | Low | Errors surface quickly on first use; corrections are trivial YAML edits |
| ADR option creates expectation of imminent SQLite migration | Low | Low | ADR status explicitly set to Proposed (not Accepted) with clear trigger threshold (100+ domains) |

## Rollback Plan

`index.yaml` is a new file with no dependencies. If it causes problems:

1. `git rm openspec/specs/index.yaml` removes it cleanly
2. Sub-agents fall back to name-matching (current behavior) — no regression in existing functionality
3. sdd-archive SKILL.md edit can be reverted independently: `git checkout -- skills/sdd-archive/SKILL.md`

## Dependencies

- Companion proposal `2026-03-14-specs-as-subagent-background` defines the SPEC CONTEXT loading convention that consumes this index. The index is most valuable when that proposal is also implemented, but the index file itself is independently useful as documentation.
- Requires `docs/SPEC-CONTEXT.md` to exist (created by the companion proposal) for Step 4.

## Success Criteria

- [ ] `openspec/specs/index.yaml` exists and contains all 55 current domains with `domain`, `summary`, and `keywords` fields
- [ ] Each entry has 3-8 keywords that reflect realistic change slug vocabulary
- [ ] `sdd-archive/SKILL.md` includes an index maintenance step in its process
- [ ] Sub-agents using the index never load more than 10 spec files as background for a single operation
- [ ] `docs/adr/NNN-spec-index-sqlite-migration.md` exists with status Proposed and documents the 100+ domain threshold as the migration trigger
- [ ] Index is self-consistent: all `related` domain references point to entries that exist in the index

## Effort Estimate

Medium (hours) — initial index authoring (55 entries) is the bulk of the work. SKILL.md edit, ADR, and doc update are each small. No implementation logic required.
