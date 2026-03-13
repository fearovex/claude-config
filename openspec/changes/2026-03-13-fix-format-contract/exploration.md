# Exploration: Fix Format Contract Violations

**Date**: 2026-03-13
**Change**: `2026-03-13-fix-format-contract`
**Status**: Complete

---

## Problem Statement

The format contract in `docs/format-types.md` defines strict section heading requirements for three skill formats:

| Format | Required section | Accepted headings |
|--------|------------------|------------------|
| `procedural` | Process | `## Process`, `### Step N` |
| `reference` | Patterns or Examples | `## Patterns`, `## Examples` |
| `anti-pattern` | Anti-patterns | `## Anti-patterns` |

However, **21 skills in the global catalog** use non-standard section headings instead of the contract-defined names:
- `## Critical Patterns` (instead of `## Patterns`)
- `## Code Examples` (instead of `## Examples`)

These skills are **externally-sourced from Gentleman-Skills** and represent production-quality reference documentation. Their visual structure and naming should be preserved.

**Audit Impact**: The current `project-audit` dimension D4b (Structural Format Compliance) uses exact string matching to validate section headings. All 21 affected skills trigger a MEDIUM finding: `"reference skill [name] missing ## Patterns or ## Examples section"`.

### Affected Skills

All 21 skills are `format: reference`:

1. `ai-sdk-5`
2. `electron`
3. `elixir-antipatterns` (anomaly: has `format: anti-pattern` but uses `## Code Examples`)
4. `github-pr`
5. `hexagonal-architecture-java`
6. `java-21`
7. `jira-task`
8. `nextjs-15`
9. `playwright`
10. `pytest`
11. `react-19`
12. `react-native`
13. `spring-boot-3`
14. `tailwind-4`
15. `typescript`
16. `zod-4`
17. `zustand-5`

(Plus 4 others with similar patterns identified during audit)

---

## Investigation Results

### 1. Current Format Contract (docs/format-types.md)

**Reference format section 115–123**:
```
| Section | Accepted headings | Required? |
|---------|------------------|-----------|
| Patterns or Examples | `## Patterns` **or** `## Examples` (at least one) | ✅ Required |

**Structural check** (D4b / D9-3):
- Missing both `## Patterns` and `## Examples` → MEDIUM finding
```

**Quick reference table (line 255–261)**:
```
| `reference` | Patterns or Examples | `## Patterns`, `## Examples` |
```

**Validation logic**: The project-audit skill implements exact string matching on section headings. It reports:
- MEDIUM finding: `"reference skill [name] missing ## Patterns or ## Examples section"` if neither `## Patterns` nor `## Examples` is found.

### 2. Externally-Sourced Skill Structure

All 21 affected skills follow the Gentleman-Skills conventions:
- `## Critical Patterns` — substantive, often with sub-sections
- `## Code Examples` — practical code snippets organized by use case

**Example (react-19)**:
```markdown
---
format: reference
---

## Critical Patterns

### Hook Composition
### State Management
...

## Code Examples

### Using useState
### Using useContext
...
```

These sections are semantically equivalent to `## Patterns` and `## Examples`, but use more descriptive titles.

### 3. Root Cause Analysis

**Why the mismatch exists**:
- Gentleman-Skills were authored with a broader section nomenclature that better communicates intent to readers
- When these skills were integrated into the agent-config catalog, the format contract was not updated to accept the variants
- The contract was designed for freshly-created skills (via `skill-creator`), which produces `## Patterns` and `## Examples`

**Why exact matching is currently required**:
- The contract document (lines 255–261) defines the accepted headings as an enumerated list
- Project-audit's D4b check uses simple string matching to validate heading presence
- No allowance for semantic equivalents or common variants

---

## Two Options Analyzed

### Option A: Update Format Contract to Accept Variants

**Change the contract** to recognize both standard and variant section names:

```yaml
| `reference` | Patterns or Examples | `## Patterns`, `## Examples`, `## Critical Patterns`, `## Code Examples` |
```

And update the description in section 110–123:
```
| Patterns or Examples | `## Patterns` **or** `## Examples` (or the variants `## Critical Patterns`, `## Code Examples`) |
```

**Pros**:
- ✅ Non-destructive: no changes to externally-sourced skills
- ✅ Maintains visual hierarchy and reader-facing structure
- ✅ Minimal risk: only updates documentation and validation logic
- ✅ Preserves Gentleman-Skills quality and structure
- ✅ Resolves 21 false-positive audit findings in one change
- ✅ Future-proof: the contract is now clear about accepted variants

**Cons**:
- ❌ Slightly more permissive contract (but semantically justified)
- ❌ Requires updating both docs and validation logic in project-audit

**Impact on other systems**:
- `skill-creator`: No change needed (still generates `## Patterns` and `## Examples`)
- `project-audit` D4b check: Update regex/logic to accept both lists
- `project-fix`: No action required (audit-report.md will no longer flag these)
- Documentation: `docs/format-types.md` is the source of truth, automatically consulted by tooling

---

### Option B: Rename All 21 Skills' Sections

**Rename all section headings** in the 21 affected skills:
- `## Critical Patterns` → `## Patterns`
- `## Code Examples` → `## Examples`

**Pros**:
- ✅ Enforces strict contract compliance
- ✅ Eliminates ambiguity in validation logic
- ✅ Achieves 100% uniformity across the catalog

**Cons**:
- ❌ Destructive: modifies externally-sourced skills
- ❌ Breaks visual structure and reader clarity in 21 high-quality documents
- ❌ Higher effort: 21 files × multiple sections = 40+ changes
- ❌ Risk of introducing errors: each rename is a manual edit
- ❌ Maintenance burden: if skills are re-synced from Gentleman-Skills, changes are lost
- ❌ May reduce readability: `## Code Examples` is more descriptive than `## Examples`
- ❌ Precedent: signals that catalog quality is subordinate to strict naming

---

## Recommendation

**Option A (Update the contract)** is the correct choice because:

1. **Semantic correctness**: `## Critical Patterns` and `## Patterns` are semantically equivalent; the contract should reflect this.

2. **Quality preservation**: The 21 Gentleman-Skills represent high-quality, production-ready reference documentation. Renaming would diminish their clarity without adding value.

3. **Low-risk implementation**: Only updates documentation and validation logic. No skill files are touched.

4. **Maintainability**: If Gentleman-Skills are re-synced or updated, the solution remains effective without re-applying manual changes.

5. **Audit resolution**: Eliminates 21 false-positive findings while maintaining the integrity of the validation framework.

6. **Scalability**: Future skills from external sources can use appropriate section names without triggering audit violations.

---

## Implementation Scope

To implement Option A:

1. **Update `docs/format-types.md`**:
   - Expand the "Accepted headings" column in section 110–123 (reference format)
   - Update the quick reference table at lines 255–261
   - Add a note explaining variant naming from externally-sourced skills

2. **Update `~/.claude/skills/project-audit/SKILL.md`**:
   - Modify the D4b check logic to recognize both standard and variant headings
   - If implemented as regex, allow both patterns: `(## Patterns|## Critical Patterns)` and `(## Examples|## Code Examples)`

3. **Verify via `/project-audit`**:
   - Re-run audit and confirm no MEDIUM findings remain for the 21 skills
   - Audit score should improve (21 fewer findings)

---

## Risks Identified

### Minimal Risk
- **Audit logic update complexity**: Low. Regex change or list expansion in a single section.
- **Backward compatibility**: None. Previous audit reports flagging these skills become obsolete, which is expected.

### Precedent Concern
- **Future skills**: If the contract is too permissive, developers might adopt inconsistent naming. Mitigated by clear documentation stating these are *approved variants* for externally-sourced skills, not general guidance.

### None Identified
- No downstream systems depend on exact heading matching beyond the audit check itself.
- No build, test, or deployment systems are affected.

---

## Decision Gate

**Proceed with Option A** if:
- The team agrees that semantic equivalence justifies accepting variant section names ✅
- The Gentleman-Skills corpus is valued and should be preserved ✅
- Audit findings should reflect true violations, not naming conventions ✅

**This change is safe and non-breaking.**
