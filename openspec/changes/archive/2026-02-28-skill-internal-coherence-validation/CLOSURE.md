# Closure: skill-internal-coherence-validation

Start date: 2026-02-28
Close date: 2026-02-28

## Summary

Added Dimension 11 (Internal Coherence) to project-audit, which validates that skill files' declared counts, section numbering, and frontmatter descriptions match their actual content. Also fixed incorrect "7 dimensions" references across CLAUDE.md, README.md, and SKILL.md.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| audit-dimensions | Added | D11 requirements: 7 requirements, 21 Given/When/Then scenarios covering count consistency (D11-a), numbering continuity (D11-b), and frontmatter-body alignment (D11-c) |

## Modified Code Files

- `skills/project-audit/SKILL.md` — Added D11 dimension section, updated header to "10 Dimensions", added report output block, score table row, detailed scoring row, FIX_MANIFEST rule
- `openspec/specs/audit-dimensions/spec.md` — Appended D11 requirements and scenarios
- `CLAUDE.md` — Fixed "7 dimensions" → "10 dimensions"
- `README.md` — Fixed "7 dimensions" → "10 dimensions" (2 occurrences)
- `ai-context/stack.md` — Updated [auto-updated] section via project-analyze
- `ai-context/architecture.md` — Updated [auto-updated] sections via project-analyze
- `ai-context/conventions.md` — Updated [auto-updated] section via project-analyze

## Key Decisions Made

- D11 assigned as new number (not reusing D5 gap) to preserve audit history integrity
- Informational-only pattern (same as D9/D10) — no score impact, violations[] only
- Pure Phase B dimension — no new Bash calls, uses Read/Glob/Grep only
- Self-referential check included (project-audit SKILL.md is scanned by its own D11)

## Lessons Learned

- The original "7 dimensions" claim persisted through 3 dimension additions (D8, D9, D10) without anyone catching it — this is exactly the class of error D11 is designed to detect
- Conservative pattern matching (headings and blockquotes only) avoids false positives from numeric references in prose and code examples

## User Docs Reviewed

N/A — change does not affect user-facing workflows
