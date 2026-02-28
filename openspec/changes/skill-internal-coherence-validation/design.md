# Technical Design: skill-internal-coherence-validation

Date: 2026-02-28
Proposal: openspec/changes/skill-internal-coherence-validation/proposal.md

## General Approach

Add a new Dimension 11 — Internal Coherence to `project-audit/SKILL.md` that iterates over every skill file found during audit and runs three structural coherence checks: count consistency, section numbering continuity, and frontmatter-body alignment. The dimension follows the exact same informational-only pattern established by D9 and D10 — no score impact, findings go to `violations[]` only, and `/project-fix` does not act on them.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Dimension number | D11 | Reuse gap at D5 | D5 was intentionally removed (commands deprecation). Reusing it would create confusion in archived audit reports that reference old D5. Sequential numbering preserves audit history integrity. |
| Scope of files checked | All SKILL.md files under `$LOCAL_SKILLS_DIR` | All markdown files in the project; only CLAUDE.md | SKILL.md files are the highest-value targets (they instruct Claude directly). Expanding to all markdown is explicitly out of scope per proposal. Using `$LOCAL_SKILLS_DIR` follows the D9/D10 precedent for global-config awareness. |
| Count extraction method | Pattern-based: extract numeric claims from headings and blockquote descriptions | AST-based markdown parsing; regex on full body | Headings and blockquotes are the canonical locations where count claims appear in SKILL.md files. Pattern matching on these specific locations reduces false positives from numeric mentions in prose. |
| Section numbering detection | Match patterns like `D1`, `Step 1`, `### 1.`, `## Phase 1` with regex | Only H2/H3 headers; only `Step N` format | Skills use diverse numbering conventions (Dimension N, Step N, Phase N, numbered sub-lists). A broader regex set catches more real inconsistencies without over-matching. |
| Score impact | Informational-only (0 points, N/A in score table) | Scored dimension (e.g., 5 points) | Proposal explicitly requires informational-only, consistent with D9 and D10 precedent. Scoring can be added in a future iteration once false-positive rate is validated. |
| FIX_MANIFEST placement | `violations[]` only | `required_actions` or `skill_quality_actions` | Coherence issues require human judgment to fix (update header vs. update body). Automated fixing could destroy correct content. `violations[]` is the correct bucket per proposal. |
| Phase A vs Phase B | Pure Phase B (Read tool only) | Add checks to Phase A bash script | D11 checks require reading file content and applying pattern matching — this is Read-tool work, not bash existence checks. No new Phase A keys needed. Adding bash logic would violate the "max 3 bash calls" constraint for minimal benefit. |
| Also check audit SKILL.md itself | Yes — include `project-audit/SKILL.md` in the scan | Skip it to avoid self-referential issues | The original motivation was exactly this file claiming "7 Dimensions" while having 9. Self-check is the core value proposition. No circular dependency since D11 only reads and reports. |

## Data Flow

```
Phase A (existing)
    │
    ├── $LOCAL_SKILLS_DIR = "skills" | ".claude/skills"
    │
    ▼
Phase B — D11 execution
    │
    ├── Enumerate: glob $LOCAL_SKILLS_DIR/*/SKILL.md
    │
    ├── For each SKILL.md:
    │   │
    │   ├── Read file content (Read tool)
    │   │
    │   ├── Check 1: Count consistency
    │   │   ├── Extract: headings + blockquote with numeric claims
    │   │   │   Pattern: /(\d+)\s+(Dimensions?|Steps?|Rules?|Phases?|Checks?|Sub-checks?)/i
    │   │   ├── For each claim: count matching sections in body
    │   │   │   e.g., "9 Dimensions" → count /^###?\s+Dimension\s+\d+/gm
    │   │   └── If declared ≠ actual → add to findings
    │   │
    │   ├── Check 2: Section numbering continuity
    │   │   ├── Extract numbered sequences from H2/H3 headings
    │   │   │   Patterns: /Step\s+(\d+)/i, /D(\d+)/, /Phase\s+(\d+)/i,
    │   │   │            /(\d+)[a-z]?\.\s/, /#### (\d+)[a-z]\./
    │   │   ├── For each sequence type: collect numbers, sort, check for gaps/duplicates
    │   │   └── If gap or duplicate found → add to findings
    │   │
    │   └── Check 3: Frontmatter-body alignment
    │       ├── Parse YAML frontmatter (between --- markers)
    │       ├── Extract `description` field
    │       ├── If description contains a numeric claim → verify against body
    │       └── If mismatch → add to findings
    │
    └── Emit D11 output block in report
        ├── Per-skill findings table
        └── Append violations to FIX_MANIFEST violations[]
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | Add D11 section after D10 with three check definitions; update header "9 Dimensions" → "10 Dimensions"; add D11 row to score table (N/A); add D11 report format block; add D11 FIX_MANIFEST rule |
| `openspec/specs/audit-dimensions/spec.md` | Modify | Append D11 requirements and scenarios at the end (following existing D9/D10 amendment pattern) |

## Interfaces and Contracts

### D11 findings structure (appended to FIX_MANIFEST `violations[]`)

```yaml
violations:
  # ... existing violations ...
  - file: "skills/project-audit/SKILL.md"
    line: 42
    rule: "D11-count-consistency"
    severity: "info"
    detail: "Header claims '7 Dimensions' but body contains 9 Dimension sections"
  - file: "skills/sdd-apply/SKILL.md"
    line: 15
    rule: "D11-numbering-continuity"
    severity: "info"
    detail: "Step numbering gap: found Steps 1,2,4 (missing Step 3)"
  - file: "skills/react-19/SKILL.md"
    line: 3
    rule: "D11-frontmatter-body"
    severity: "info"
    detail: "Frontmatter description claims '5 rules' but body has 4 ## Rules items"
```

### D11 check patterns (pseudo-specification)

```
# Check 1 — Count consistency
CLAIM_PATTERN = /(\d+)\s+(Dimensions?|Steps?|Rules?|Phases?|Checks?|Sub-checks?)/i
  → Extract from: H1, H2, H3 headings and blockquote lines (lines starting with >)
  → Match body sections: heading lines containing the same keyword (case-insensitive)
  → Tolerance: none — declared count must exactly match actual count

# Check 2 — Section numbering continuity
SEQUENCE_PATTERNS:
  - /^#{2,3}\s+.*Step\s+(\d+)/im     → Step sequences
  - /^#{2,3}\s+.*Dimension\s+(\d+)/im → Dimension sequences
  - /^#{2,3}\s+.*Phase\s+(\d+)/im     → Phase sequences
  - /^#{2,4}\s+.*D(\d+)/m             → D-prefixed sequences (D1, D2, ...)
  → For each pattern: collect all matched numbers, sort ascending
  → Gap: a number N is missing where min..max is not contiguous
  → Duplicate: a number appears more than once
  → Report only if sequence has ≥ 2 members (single item = no sequence to validate)

# Check 3 — Frontmatter-body alignment
  → Parse YAML between first pair of --- markers
  → If `description:` field contains a numeric claim (reuse CLAIM_PATTERN)
  → Verify that claim against body using same logic as Check 1
```

### D11 report output block

```markdown
## Dimension 11 — Internal Coherence [OK|INFO|SKIPPED]

**Skills scanned**: [N] from $LOCAL_SKILLS_DIR

| Skill | Count OK | Numbering OK | Frontmatter OK | Findings |
|-------|----------|-------------|----------------|----------|
| [skill-name] | ✅/⚠️ | ✅/⚠️ | ✅/⚠️/N/A | [detail or "clean"] |

**Inconsistencies found**: [N] across [M] skills (or "None — all skills internally coherent")

*D11 findings are informational only — they do not affect the score and are not auto-fixed by /project-fix.*
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Integration | Run `/project-audit` on claude-config itself and verify D11 output appears | Manual execution |
| Smoke | Verify D11 correctly detects the known "9 Dimensions" header vs actual 10 after this change is applied | Manual inspection of report |
| Regression | Verify all D1-D10 outputs unchanged, score unchanged | Compare pre/post reports |

## Migration Plan

No data migration required. D11 is purely additive — it adds a new section to the audit report. Existing audit reports remain valid (they simply lack D11 output). The header count update ("9 Dimensions" → "10 Dimensions") is a documentation accuracy fix, not a behavioral migration.

## Open Questions

None. The design follows established patterns (D9, D10) and the proposal is well-constrained. All three checks are structurally defined with clear pattern specifications.
