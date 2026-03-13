# Proposal: fix-skills-structural

Date: 2026-03-13
Status: Draft

## Intent

Fix four structural compliance violations in the skill catalog to ensure all skills satisfy their declared format contracts and language requirements.

## Motivation

The global skill catalog (51 skills) has four isolated structural defects that violate Unbreakable Rules and skill format contracts documented in `CLAUDE.md`, `conventions.md`, and `architecture.md`:

1. **skill-creator/SKILL.md** — contains 25 lines of dead documentation for `/skill-add` mode, which is fully delegated to a separate `skill-add/SKILL.md` skill
2. **pytest/SKILL.md** — violates Unbreakable Rule 1 (English-only) with a Spanish comment: `# Teardown automático`
3. **elixir-antipatterns/SKILL.md** — declares `format: anti-pattern` but uses wrong section heading `## Critical Patterns` instead of required `## Anti-patterns`
4. **claude-code-expert/SKILL.md** — violates reference format contract with duplicate `## Description` and `**Triggers**` sections

These violations break the skill format contract and are flagged by project-audit dimension D4b (structural compliance).

## Scope

### Included

- Remove lines 294–319 from `skills/skill-creator/SKILL.md` (dead `/skill-add` documentation)
- Change line 51 comment in `skills/pytest/SKILL.md` from Spanish to English
- Rename line 28 section heading in `skills/elixir-antipatterns/SKILL.md` from `## Critical Patterns` to `## Anti-patterns`
- Remove duplicate sections from `skills/claude-code-expert/SKILL.md`, consolidating multiple `## Description` and `**Triggers**` instances into a single, clean front-section pair
- Verify all four skills pass format contract validation after changes

### Excluded (explicitly out of scope)

- Full audit of all 51 skills for similar issues (deferred to a separate comprehensive audit change)
- Preventive rules or commit hooks for structural compliance (future infrastructure change)
- Documentation or comments for the format type system (already present in `docs/format-types.md`)

## Proposed Approach

**Surgical fixes** — apply minimal, targeted edits to each file:

1. **skill-creator**: Delete the dead `/skill-add` mode documentation block. The functionality is fully owned by the standalone `skill-add/SKILL.md` skill; the removed text only duplicates and confuses users.

2. **pytest**: Simple translation of one comment: `# Teardown automático` → `# Teardown automatic`. No behavior change; satisfies English-only language rule.

3. **elixir-antipatterns**: Rename the section heading from `## Critical Patterns` to `## Anti-patterns` to match the declared `format: anti-pattern` in YAML frontmatter and satisfy the format contract per `architecture.md` section "Skill format type system".

4. **claude-code-expert**: Consolidate duplicate sections. The file declares `format: reference`, which requires `**Triggers**`, `## Patterns` or `## Examples`, and `## Rules`. Remove both duplicate `## Description` blocks and duplicate `**Triggers**` declarations, keeping only one clean pair at the front of the file. Preserve all substantive content (patterns, examples, rules).

**Rationale**: Each fix is isolated, low-risk, and independently verifiable. No behavior change — purely structural compliance. Matches the "no over-engineering" working principle.

## Affected Areas

| Area/Module | Type of Change | Impact |
|---|---|---|
| `skills/skill-creator/SKILL.md` | Code removal (dead documentation) | Low — removes confusing text; actual `/skill-create` functionality unaffected |
| `skills/pytest/SKILL.md` | Text change (comment translation) | Low — comment only; no code behavior change |
| `skills/elixir-antipatterns/SKILL.md` | Section rename (structural) | Medium — fixes format contract violation; content unchanged |
| `skills/claude-code-expert/SKILL.md` | Deduplication (structural cleanup) | Medium — removes duplicate headings; preserves all content and patterns |

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Accidental removal of valid content from skill-creator | Low | Loss of functionality if `/skill-add` integration is needed | Verify that `skill-add/SKILL.md` is a standalone skill and fully implements all required functionality before deletion. (Already confirmed: skill-add/SKILL.md exists and is complete.) |
| Comment mistranslation in pytest | Low | Altered code intent if the comment carries special meaning | Translation is straightforward: Spanish "automático" = English "automatic". Comment describes fixture teardown scope, not a special mechanism. |
| Breaking format contract in elixir-antipatterns | Low | Audit tools fail if section name changes but format field remains | Renaming `## Critical Patterns` to `## Anti-patterns` is the correct contract-compliant fix. Audit tools expect `## Anti-patterns` for `format: anti-pattern`. |
| Creating new compliance issues in claude-code-expert | Low | Losing information or creating different structure issues | Plan: preserve all content (patterns, examples, rules), consolidate duplicate headers cleanly, verify reference format contract after edit. |

## Rollback Plan

Each fix is isolated and can be reverted independently:

1. **skill-creator**: `git checkout skills/skill-creator/SKILL.md`
2. **pytest**: `git checkout skills/pytest/SKILL.md`
3. **elixir-antipatterns**: `git checkout skills/elixir-antipatterns/SKILL.md`
4. **claude-code-expert**: `git checkout skills/claude-code-expert/SKILL.md`

If any fix creates unexpected side effects:
- All changes are file-only (no schema or configuration changes)
- Deployment via `install.sh` (no special activation required)
- Immediate re-run of `/project-audit` will detect new issues if introduced

## Dependencies

- **skill-add/SKILL.md** must exist and fully implement `/skill-add` functionality before removing that section from skill-creator (already confirmed)
- **project-audit D4b** should pass after fixes applied (validates format contracts and detects similar issues)
- **Installation** via `install.sh` (standard Workflow A: edit in repo → install.sh → git commit)

## Success Criteria

- [ ] skill-creator lines 294–319 are removed; `/skill-create` documentation and functionality are unaffected
- [ ] pytest line 51 comment is changed to English; no code behavior is altered
- [ ] elixir-antipatterns section heading is renamed from `## Critical Patterns` to `## Anti-patterns`; skill content is unchanged
- [ ] claude-code-expert duplicate `## Description` and `**Triggers**` sections are removed; all patterns, examples, and rules are preserved
- [ ] All four skills pass format contract validation (verified via manual inspection against `docs/format-types.md`)
- [ ] No functional behavior change to any skill
- [ ] `/project-audit` runs successfully and dimension D4b passes (no new format compliance violations introduced)

## Effort Estimate

**Low (hours)** — Four straightforward text edits, no build or test cycles required.

---

## Notes for Implementation

**Format Contracts (per architecture.md):**

- `format: procedural` (default) requires: `**Triggers**`, `## Process`, `## Rules`
- `format: reference` requires: `**Triggers**`, `## Patterns` or `## Examples`, `## Rules`
- `format: anti-pattern` requires: `**Triggers**`, `## Anti-patterns`, `## Rules`

**Verification after apply:**

Use `/project-audit` dimension D4b to validate format compliance:

```bash
/project-audit
```

Check dimension D4b in the audit report — should show zero violations for the four skills modified.
