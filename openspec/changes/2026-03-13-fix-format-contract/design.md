# Technical Design: Fix Format Contract

Date: 2026-03-13
Proposal: openspec/changes/2026-03-13-fix-format-contract/exploration.md

---

## General Approach

Update the format contract in `docs/format-types.md` to accept variant section names (`## Critical Patterns` and `## Code Examples`) used by externally-sourced Gentleman-Skills, while preserving their reader-facing structure. Concurrently update the project-audit D4b validation logic to recognize both standard and variant headings via regex-based pattern matching. This is a documentation + validation update with zero impact on skill content or external quality.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| **Variant acceptance mechanism** | Regex pattern matching in project-audit D4b check | String literal expansion in config, or code-based allowlist | Regex is concise, maintainable, and scales to future variant names without re-deployment. Pattern matching at the validation site keeps the logic self-documenting. |
| **Documentation location** | Expand the format contract table at lines 110–123 and quick-reference table at lines 255–261 in `docs/format-types.md` | Create a separate variance document or appendix | The format contract is the single source of truth. Variant documentation belongs inline so it is discoverable by tooling that reads the document programmatically. |
| **Skill file changes** | None — all 21 affected skills remain unchanged | Rename sections to match standard names | Non-destructive approach preserves Gentleman-Skills quality, avoids maintenance burden, and supports re-syncing from upstream sources without losing changes. Semantic equivalence makes this safe. |
| **Validation strategy** | Update D4b to use regex with two alternatives: `(## Patterns\|## Critical Patterns)` and `(## Examples\|## Code Examples)` | Case-insensitive substring match, or config-driven allowlist | Regex is precise, fails-safe (only exact matches), and remains readable. Case-sensitive matching is correct because Markdown headings are case-sensitive. |
| **Scope of change** | Only D4b reference format check is modified; all other dimension rules remain unchanged | Broad audit refactoring to support general heading variants | Minimal change surface reduces risk and preserves audit stability. The format contract already defines what is accepted; we are just widening the regex patterns. |

---

## Data Flow

The validation flow for reference skills in project-audit D4b:

```
For each skill in .claude/skills/:
  ├─ Parse YAML frontmatter
  ├─ Extract format: value
  │
  └─ If format == "reference":
     ├─ Read skill file
     ├─ Check for Triggers (existing logic — unchanged)
     ├─ Check for Rules (existing logic — unchanged)
     │
     └─ Check for Patterns OR Examples (D4b — MODIFIED):
        ├─ Scan file for: ## Patterns
        ├─ Scan file for: ## Critical Patterns (NEW)
        ├─ Scan file for: ## Examples
        ├─ Scan file for: ## Code Examples (NEW)
        │
        └─ If none found → MEDIUM finding
            "reference skill [name] missing ## Patterns or ## Examples section"
                ↓
            (Update message to include variants:
             "missing (## Patterns|## Critical Patterns) or
              (## Examples|## Code Examples) section")
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `docs/format-types.md` | Modify | Section 110–123 (reference format): Expand "Accepted headings" column to list both standard and variant section names. Section 255–261 (quick-reference table): Update the reference row to include variants. Add a note explaining that variants are approved for externally-sourced skills. |
| `~/.claude/skills/project-audit/SKILL.md` | Modify | Dimension 4b (Skills Quality) check for reference format: Update the "Accepted headings" cell from `## Patterns`, `## Examples` to include variants `## Critical Patterns`, `## Code Examples`. Update the validation logic description and the finding message to document the new pattern. Replace simple string matching with regex alternatives for robust detection. |

---

## Interfaces and Contracts

### Updated Format Contract (docs/format-types.md)

**Current (lines 112–116)**:
```markdown
| Section | Accepted headings | Required? |
|---------|------------------|-----------|
| Trigger definition | `**Triggers**` or `## Triggers` | ✅ Required |
| Patterns or Examples | `## Patterns` **or** `## Examples` (at least one) | ✅ Required |
| Rules | `## Rules` | ✅ Required |
```

**Updated**:
```markdown
| Section | Accepted headings | Required? |
|---------|------------------|-----------|
| Trigger definition | `**Triggers**` or `## Triggers` | ✅ Required |
| Patterns or Examples | `## Patterns`, `## Examples`, `## Critical Patterns`, `## Code Examples` (at least one from each pair) | ✅ Required |
| Rules | `## Rules` | ✅ Required |
```

**Quick-reference table (lines 255–261)**:

Current:
```markdown
| `reference` | Patterns or Examples | `## Patterns`, `## Examples` |
```

Updated:
```markdown
| `reference` | Patterns or Examples | `## Patterns`, `## Examples`, `## Critical Patterns`, `## Code Examples` |
```

**Added note** (after the quick-reference table):
```markdown
> **Variant naming**: Skills externally-sourced from Gentleman-Skills may use descriptive variants
> (`## Critical Patterns`, `## Code Examples`) instead of the standard names. Both forms satisfy the
> contract. This variance is approved only for reference-sourced documentation. Custom project skills
> created via `skill-creator` continue to use standard names.
```

### Validation Logic Update (project-audit D4b)

**Current check (line 320)**:
```
reference skill [name] missing ## Patterns or ## Examples section
```

**Updated validation description** (in Dimension 4b, section "Apply the check for the resolved format"):

Replace the reference row:
```
| `reference` | Patterns or Examples | `## Patterns`, `## Examples` | ...
```

With:
```
| `reference` | Patterns or Examples | `## Patterns`, `## Examples`, `## Critical Patterns` (variant), `## Code Examples` (variant) | MEDIUM: "reference skill [name] missing patterns section (## Patterns or ## Critical Patterns) and examples section (## Examples or ## Code Examples)" |
```

**Updated finding message**:
When a reference skill has neither standard nor variant names:
```
"reference skill [name] missing (## Patterns or ## Critical Patterns) or (## Examples or ## Code Examples) section"
```

---

## Implementation Details

### Regex Pattern for D4b Check

In the validation code, replace string-literal checks:

```bash
# Old (pseudo-code):
grep -q "^## Patterns\|^## Examples" "$skill_file"
```

With regex alternatives:

```bash
# New (pseudo-code):
grep -E "^## (Patterns|Critical Patterns)" "$skill_file" && \
grep -E "^## (Examples|Code Examples)" "$skill_file"
```

Or as a single combined check:
```bash
# Combined: At least one pattern variant AND at least one example variant
grep -E "^## (Patterns|Critical Patterns)" "$skill_file" && \
grep -E "^## (Examples|Code Examples)" "$skill_file"
```

Both patterns must be present (semantic AND, not OR) for the check to pass.

---

## Testing Strategy

| Layer | What to test | Validation |
|-------|--------------|------------|
| Unit | Regex pattern matching for all four heading variants | Manually test patterns: `## Patterns`, `## Critical Patterns`, `## Examples`, `## Code Examples` |
| Integration | Run `/project-audit` on full skill catalog | Verify 0 MEDIUM findings for the 21 affected skills. Verify no regressions in other audit dimensions. |
| End-to-end | Re-run audit on known test subset | Sample 3 affected skills (e.g., `react-19`, `pytest`, `elixir-antipatterns`) and confirm audit passes with both standard and variant names. |

---

## Migration Plan

**No data migration required.** This is a documentation + validation update. No skill files are modified.

**Rollout steps**:

1. Update `docs/format-types.md` with expanded contract + variant documentation
2. Update `~/.claude/skills/project-audit/SKILL.md` dimension 4b check with new regex logic and updated finding messages
3. Deploy via `install.sh` to make changes active in `~/.claude/`
4. Run `/project-audit` on the full project to verify all 21 affected skills now produce 0 MEDIUM findings
5. Commit with message referencing the change slug

**Rollback plan** (if needed):

- Revert both files to prior commit
- Re-run `/project-audit` to restore original findings
- No skill content changes to roll back

---

## Open Questions

None. The proposal is self-contained and the exploration phase has validated both the problem and the solution.

---

## Risk Analysis

### Low Risk

**Why this change is safe:**

1. **Non-destructive**: No skill files are modified. The 21 Gentleman-Skills remain unchanged.
2. **Additive validation**: The regex patterns only broaden acceptance criteria; no existing valid skills become invalid.
3. **Single source of truth**: The format contract (`docs/format-types.md`) is already the authoritative reference for tooling. Widening the accepted patterns does not introduce inconsistency.
4. **Minimal touch surface**: Only two files are modified. D4b check logic is localized. No cross-dimension dependencies.
5. **Semantic correctness**: `## Critical Patterns` and `## Patterns` are semantically equivalent; the same applies to `## Examples` and `## Code Examples`. The change reflects reality, not a workaround.
6. **Backward compatible**: Existing skills with standard names continue to pass. New skills created via `skill-creator` are unaffected (they still generate standard names).

### Precedent Concern (Mitigated)

**Risk**: Future developers might use non-standard headings in custom skills, eroding consistency.

**Mitigation**: The documentation update explicitly states that variant names are *approved only for externally-sourced skills*. Custom project skills remain subject to standard names. This is enforced by the contract document.

### None Identified

- No downstream build, test, or deployment systems depend on exact heading matching beyond the audit check itself.
- No breaking changes to any other audit dimensions.
- Audit score improvement (21 fewer false-positive findings) is a net benefit.

---

## Success Criteria

1. ✅ `docs/format-types.md` expanded with variant names in both section 110–123 and quick-reference table 255–261
2. ✅ `~/.claude/skills/project-audit/SKILL.md` dimension 4b check updated to recognize all four heading variants via regex
3. ✅ Running `/project-audit` on the full project produces 0 MEDIUM findings for the 21 affected skills
4. ✅ All other audit dimensions remain unchanged (no regressions)
5. ✅ Sample test of 3 affected skills (e.g., react-19, pytest, elixir-antipatterns) confirms both standard and variant names are accepted
6. ✅ Project audit score >= previous score (expected: score improves by ~21 points due to finding reduction)
