# Proposal: Fix Format Contract Violations

**Date**: 2026-03-13  
**Status**: Draft

---

## Intent

Update the skill format contract to accept semantically equivalent section names from externally-sourced Gentleman-Skills, eliminating 21 false-positive audit findings.

---

## Motivation

The `docs/format-types.md` format contract defines strict section heading requirements for reference and anti-pattern skills:

- **reference format**: must have `## Patterns` or `## Examples`
- **anti-pattern format**: must have `## Anti-patterns`

However, 21 skills from the Gentleman-Skills corpus use semantically equivalent variant names:
- `## Critical Patterns` instead of `## Patterns`
- `## Code Examples` instead of `## Examples`
- `## Anti-patterns` (correct, but one skill has anomalous format declaration)

These 21 skills are **high-quality, production-ready reference documentation**. Their naming is more descriptive and clearer to readers. The current `project-audit` validation uses exact string matching, triggering a MEDIUM finding (`"reference skill [name] missing ## Patterns or ## Examples section"`) for each of the 21 affected skills.

**Root cause**: The format contract was designed for freshly-created skills (via `skill-creator`), not for integration of semantically equivalent external sources. The audit finding represents a naming convention difference, not a structural violation.

---

## Scope

### Included

1. **Update `docs/format-types.md`**:
   - Expand the "Accepted headings" section (lines 110–123) for `reference` format to document both standard and variant section names
   - Update the quick reference table (lines 255–261) to include variants
   - Add a note explaining that `## Critical Patterns` and `## Code Examples` are approved variants from externally-sourced skills

2. **Update `~/.claude/skills/project-audit/SKILL.md`**:
   - Modify the D4b (Structural Format Compliance) check logic to accept both standard and variant headings
   - Implementation: update regex/list matching to recognize both patterns (e.g., `(## Patterns|## Critical Patterns)` and `(## Examples|## Code Examples)`)
   - Update the MEDIUM finding description to be more precise about what constitutes a violation

3. **Verify via audit**:
   - Re-run `/project-audit` and confirm zero MEDIUM findings for format contract violations in the 21 affected skills
   - Confirm audit score remains stable or improves (21 false-positives removed)

### Excluded (explicitly out of scope)

- Renaming section headings in any of the 21 affected skills (non-destructive approach)
- Modifying the `skill-creator` tool (continues to generate standard names for new skills)
- Changes to other audit dimensions (D1–D12, D14+)
- Changes to the global CLAUDE.md Skills Registry

---

## Proposed Approach

**Semantic equivalence principle**: The format contract should recognize that `## Critical Patterns` is semantically equivalent to `## Patterns`, and `## Code Examples` is equivalent to `## Examples`. These are not violations—they are approved variants for externally-sourced skills.

**Three-part implementation**:

1. **Documentation**: Expand `docs/format-types.md` with a clear table and explanatory note clarifying which section names are accepted and why variants exist.

2. **Validation logic**: Update the D4b check in `project-audit` to accept both standard and variant names. Implement as a whitelist or regex pattern that matches any of:
   - For `reference` format: `## Patterns`, `## Critical Patterns`, `## Examples`, `## Code Examples`
   - For `anti-pattern` format: `## Anti-patterns` (unchanged — already correct)

3. **Verification**: Run `/project-audit` and confirm the format contract violations disappear. The audit score should improve (21 fewer findings).

---

## Affected Areas

| Area/Module | Type of Change | Impact |
|---|---|---|
| `docs/format-types.md` | Modified | Documentation — affects future readers and validators |
| `~/.claude/skills/project-audit/SKILL.md` | Modified | Validation logic — affects audit output |
| 21 externally-sourced skills (ai-sdk-5, react-19, etc.) | No change | These files remain untouched; they are now correctly validated |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Validation logic becomes too permissive | Low | Medium | Document the approved variants clearly; mark them as specific to externally-sourced skills in comments. Future-proof by restricting to the exact list of approved variants, not a general pattern. |
| Future skills use inconsistent naming | Low | Low | Document that variants are for *externally-sourced* skills only; new skills created with `skill-creator` continue to use standard names. The tool's behavior is unchanged. |
| Audit findings reports become unclear | Low | Low | Update the D4b finding message to be more precise: distinguish between "missing required section" (error) vs. "using an approved variant name" (pass). |

**None of these risks are significant.** The change is safe, non-breaking, and improves audit accuracy.

---

## Rollback Plan

If the change introduces unexpected side effects:

1. **Revert `docs/format-types.md`**: restore to prior version (lines 110–123 and 255–261 reverted)
2. **Revert `~/.claude/skills/project-audit/SKILL.md`**: restore D4b check to original exact-string matching
3. **Re-run `/project-audit`**: confirm findings return to prior state
4. **Git undo**: `git revert <commit-sha>` if changes have been committed

**Rollback impact**: Audit findings for the 21 skills reappear; however, no skill files were modified, so reverting changes only affects the validation logic, not the corpus.

---

## Dependencies

- None. This change does not require changes to any other systems.
- It does require editing two files in the global skill catalog and docs.

---

## Success Criteria

- [ ] `docs/format-types.md` is updated with variant section names documented as approved
- [ ] `~/.claude/skills/project-audit/SKILL.md` D4b check accepts both standard and variant headings
- [ ] Running `/project-audit` produces zero MEDIUM findings for "format contract violations" across all 21 affected skills
- [ ] Audit score remains stable or improves (21 fewer violations than prior audit)
- [ ] Other audit dimensions (D1–D12, D14+) remain unchanged
- [ ] No changes to the 21 affected skill files themselves (non-destructive)

---

## Effort Estimate

**Low** (1–2 hours)

- Documentation update: 20–30 minutes (clarify section 110–123, update quick reference table, add explanatory note)
- Validation logic update: 20–30 minutes (expand regex or whitelist in project-audit)
- Testing via `/project-audit`: 10–15 minutes (run audit, verify findings eliminated)
- Review and commit: 10–15 minutes

---

## Additional Context

### Why Option A (contract update) over Option B (rename all 21 skills)?

1. **Non-destructive**: Skill files are unchanged; high-quality external documentation is preserved
2. **Maintainability**: If Gentleman-Skills are re-synced, no manual changes are lost
3. **Scalability**: Future external sources can use appropriate naming without triggering violations
4. **Reader clarity**: `## Code Examples` and `## Critical Patterns` are more descriptive than generic names
5. **Audit precision**: Findings should reflect *true* violations, not naming convention preferences

### 21 Affected Skills (all with `format: reference`)

ai-sdk-5, electron, github-pr, hexagonal-architecture-java, java-21, jira-task, nextjs-15, playwright, pytest, react-19, react-native, spring-boot-3, tailwind-4, typescript, zod-4, zustand-5 (16 reference skills)

Plus elixir-antipatterns (anomaly: `format: anti-pattern` but uses `## Code Examples`), django-drf, and others (21 total identified in exploration.md)

---

## Summary for Review

**Problem**: 21 externally-sourced skills use variant section headings (`## Critical Patterns`, `## Code Examples`) that don't match the format contract, triggering false-positive audit findings.

**Solution**: Accept approved variants in the contract and validation logic. No skill files are modified.

**Benefit**: Eliminates 21 false-positive audit findings while preserving high-quality external documentation.

**Risk**: Minimal — change is non-breaking and localized to documentation + validation logic.

**Next step**: Proceed to spec + design phases for detailed implementation.
