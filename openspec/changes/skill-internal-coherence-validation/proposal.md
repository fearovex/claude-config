# Proposal: skill-internal-coherence-validation

Date: 2026-02-28
Status: Draft

## Intent

Add an automated validation mechanism that detects internal inconsistencies within skill files — such as declared counts not matching actual content, section numbering gaps, and header claims contradicting the body.

## Motivation

The project-audit skill itself recently had a bug where its header said "7 Dimensions" but the file actually defined 9 (later 10) dimensions. This class of error — where a file's metadata or summary contradicts its own content — is invisible to existing audit dimensions, which focus on cross-file integrity (registry vs. disk, paths vs. filesystem). No current dimension validates that a single file is internally coherent. These inconsistencies degrade trust in the documentation and can mislead both human readers and Claude when it reads skill instructions.

## Scope

### Included

- A new audit dimension (D11) in `project-audit/SKILL.md` that validates internal coherence of skill files
- Coherence checks covering: declared counts vs. actual counts, section numbering continuity, header claims vs. body content
- Application to all `.claude/skills/*/SKILL.md` files in the target project (and `skills/*/SKILL.md` for global-config repos)
- Informational-only scoring (no score deduction in iteration 1, consistent with D9 and D10 precedent)
- FIX_MANIFEST `violations[]` entries for detected inconsistencies (not `required_actions`, since these require human judgment to fix)

### Excluded (explicitly out of scope)

- Auto-fixing detected inconsistencies (requires human judgment on whether to update the header or the body)
- Validating non-skill markdown files (ai-context/, proposals, specs) — could be a future extension
- Semantic validation of skill content (e.g., "does this process make sense?") — only structural/numeric coherence
- Cross-file coherence (already covered by D4, D6, D9)
- Score impact — D11 will be informational-only like D9 and D10

## Proposed Approach

Add a new **Dimension 11 — Internal Coherence** to `project-audit/SKILL.md`. This dimension iterates over each skill file and runs a set of pattern-based checks:

1. **Count consistency**: Extract numeric claims from headers/summaries (e.g., "9 Dimensions", "5 Steps", "3 Rules") and compare against the actual count of matching sections in the body.
2. **Section numbering continuity**: For numbered sections (D1, D2, ..., DN or Step 1, Step 2, ..., Step N), verify there are no gaps or duplicates in the sequence.
3. **Frontmatter-body alignment**: If the YAML frontmatter declares a `description` that includes a count or list, verify it matches the body content.

The dimension follows the same pattern as D9 and D10: informational output, no score deduction, findings in `violations[]` only.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-audit/SKILL.md` | Modified — new D11 section | Medium |
| `openspec/specs/audit-dimensions/spec.md` | Modified — D11 spec added | Low |
| Report format in SKILL.md | Modified — D11 output block added to template | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| False positives from ambiguous header phrasing | Medium | Low | Keep checks conservative — only flag when a numeric claim is clearly present and clearly wrong |
| Increased audit runtime from parsing every skill file | Low | Low | Skill files are small (<200 lines typically); parsing is trivial |
| Scope creep into semantic validation | Medium | Medium | Explicitly limit to structural/numeric checks; document boundary clearly in the spec |

## Rollback Plan

Revert the single commit that adds D11 to `skills/project-audit/SKILL.md`. Since D11 is informational-only with no score impact and no FIX_MANIFEST `required_actions`, removing it has zero side effects on existing audit behavior.

## Dependencies

- None. The existing project-audit skill structure supports adding new dimensions without modifying the scoring engine or Phase A script (D11 checks are pure file-reading in Phase B).

## Success Criteria

- [ ] D11 section exists in `skills/project-audit/SKILL.md` with clear check definitions
- [ ] Running `/project-audit` on claude-config itself produces D11 output without errors
- [ ] D11 correctly detects a known inconsistency (e.g., a test file with a mismatched count) or reports clean when no inconsistencies exist
- [ ] D11 findings appear in `violations[]` of FIX_MANIFEST, not in `required_actions`
- [ ] No existing dimension scores are affected by the addition
- [ ] Report format template includes the D11 output section

## Effort Estimate

Low (hours) — single dimension addition following established D9/D10 patterns.
