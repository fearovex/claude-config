# Proposal: skill-format-types

Date: 2026-03-01
Status: Draft

## Intent

Formalize multiple skill format types so that the structural validation rules correctly distinguish between procedural skills (which must have a `## Process` section) and reference/pattern skills (which intentionally do not).

## Motivation

The global CLAUDE.md states an unbreakable rule: every SKILL.md must have "trigger definition, process steps, rules section." However, 19 of the 44 skills in the current catalog are technology/library reference skills (e.g., `react-19`, `nextjs-15`, `typescript`, `tailwind-4`) that are intentionally structured around patterns and examples rather than sequential process steps. These skills do not have a `## Process` section — and should not — because their purpose is to provide contextual reference knowledge, not to orchestrate a procedure.

This mismatch means:
1. The unbreakable rule as written is violated by nearly half the catalog.
2. `project-audit` (D4 and D9) flags these skills as structurally non-compliant, generating false positives.
3. `project-fix` may attempt to "correct" valid reference skills, introducing unnecessary noise.
4. `skill-creator` has no guidance on which format to apply when creating a new skill.

Without a formalized type system, the catalog will continue to grow inconsistently, and automated tooling will remain misaligned with actual conventions.

## Scope

### Included

- Define 2–3 canonical skill format types with formal names and required section contracts:
  - **Format A (Procedural)**: `Triggers → Process → Rules` — for orchestrator, meta-tool, and SDD phase skills
  - **Format B (Reference)**: `Triggers → Patterns / Examples → Rules` — for technology and library skills
  - **Format C (Anti-pattern)** (if justified): `Triggers → Anti-patterns → Rules` — for skills like `elixir-antipatterns` that are structured as anti-pattern catalogs
- Add a `format:` declaration field to SKILL.md frontmatter (YAML header), allowing skills to self-declare their type
- Update CLAUDE.md unbreakable Rule 2 to reference the format type system
- Update `project-audit` (D4/D9) to validate each skill against its declared format, not just check for `## Process`
- Update `project-fix` to apply format-aware structural corrections
- Update `skill-creator` to ask or infer the format type when creating a new skill
- Add a `format-types.md` reference document to `docs/` cataloging all defined formats

### Excluded (explicitly out of scope)

- Retroactively modifying all 44 existing SKILL.md files to add `format:` declarations — this is a migration task and will be handled as a separate follow-up change
- Changing the actual content or behavior of any existing skill (only structural metadata and validation logic changes)
- Introducing a new skill type beyond A, B, and C — additional types may be added in future changes if evidence warrants them
- Enforcing format declarations as hard-blocking in CI/CD — validation remains advisory and audit-based

## Proposed Approach

Introduce a lightweight `format:` frontmatter field in SKILL.md files using the existing YAML header convention. Skills that declare `format: procedural` must have `## Process`; skills that declare `format: reference` must have a `## Patterns` or `## Examples` section; skills that declare `format: anti-pattern` must have an `## Anti-patterns` section. Skills with no `format:` declaration default to the procedural check (preserving backwards compatibility).

Validation logic in `project-audit` (D4 and D9) is updated to read the `format:` field before evaluating structural compliance. `project-fix` receives a corresponding update to generate format-correct skeleton sections when repairing a skill. `skill-creator` adds a format-selection step at the start of its process.

A short reference document (`docs/format-types.md`) defines the canonical format contracts and serves as the authoritative source for all tooling.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `CLAUDE.md` (global + project) | Modified — Rule 2 updated | Medium |
| `skills/project-audit/SKILL.md` | Modified — D4/D9 validation logic | Medium |
| `skills/project-fix/SKILL.md` | Modified — format-aware repair logic | Medium |
| `skills/skill-creator/SKILL.md` | Modified — format-selection step added | Low |
| `docs/format-types.md` | New — canonical format type reference | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Skills without `format:` declarations are incorrectly classified during audit | Medium | Medium | Default to procedural check (backwards-compatible); only fully suppress false positives for skills with explicit declaration |
| Format C (Anti-pattern) is too narrow to justify a separate type | Low | Low | Merge into Format B if insufficient distinct members; the design phase will validate |
| Validation logic changes break existing compliant skills | Low | High | Audit score must be >= current score on canonical test project (Audiio V3) before archiving |
| format-types.md becomes stale as catalog grows | Medium | Low | Document is referenced by skill-creator and updated as part of any new skill creation |

## Rollback Plan

1. Revert changes to `CLAUDE.md` by restoring the previous version from git: `git checkout HEAD~1 CLAUDE.md`
2. Revert skill file changes: `git checkout HEAD~1 skills/project-audit/SKILL.md skills/project-fix/SKILL.md skills/skill-creator/SKILL.md`
3. Delete `docs/format-types.md`
4. Run `install.sh` to redeploy the reverted config to `~/.claude/`
5. Verify with `/project-audit` that the score returns to baseline

No database migrations, no destructive operations — all changes are file-based and version-controlled.

## Dependencies

- None: all affected components exist and no external dependencies are introduced
- The migration of existing SKILL.md files (adding `format:` declarations) is a downstream dependency that will be tracked as a separate change after this change is archived

## Success Criteria

- [ ] `docs/format-types.md` exists and defines at least 2 canonical formats with required section contracts
- [ ] CLAUDE.md Rule 2 references the format type system and the `format:` frontmatter field
- [ ] `project-audit` D4/D9 reads the `format:` field from SKILL.md frontmatter and validates against the declared format rather than unconditionally checking for `## Process`
- [ ] `project-fix` generates format-correct skeleton sections when repairing a skill (procedural → `## Process`, reference → `## Patterns`)
- [ ] `skill-creator` includes a format-selection step that prompts or infers format type before generating the SKILL.md skeleton
- [ ] `/project-audit` score on the canonical test project (Audiio V3) is >= the score before this change
- [ ] At least one existing reference skill (e.g., `react-19`) correctly passes D4/D9 audit when `format: reference` is declared in its frontmatter

## Effort Estimate

Medium (1–2 days): 5 file modifications + 1 new file, coordinated across audit, fix, and creator skills.
