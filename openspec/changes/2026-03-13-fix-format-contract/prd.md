---
title: Fix Format Contract Violations in Skill Audit
status: Draft
author: Claude Code
date: 2026-03-13
related-change: openspec/changes/2026-03-13-fix-format-contract/
---

# PRD: Fix Format Contract Violations in Skill Audit

## Problem Statement

The skill format contract in `docs/format-types.md` defines strict section heading requirements. However, 21 externally-sourced Gentleman-Skills use semantically equivalent variant names (`## Critical Patterns` instead of `## Patterns`, `## Code Examples` instead of `## Examples`). These variants represent high-quality production documentation, yet the current audit validation triggers false-positive MEDIUM findings due to exact-string matching on section headings.

## Target Users

- **Primary**: Development team maintaining the global skill catalog and running `/project-audit` validation
- **Secondary**: Integrators adding externally-sourced skills to the catalog

## User Stories

### Must Have

- As a skill catalog maintainer, I want the format contract to accept semantically equivalent section names so that high-quality external documentation (Gentleman-Skills) is recognized as compliant.

### Should Have

- As an auditor, I want the `/project-audit` findings to clearly distinguish between true format violations and approved naming variants so that I can focus on genuine issues.

### Could Have

- As a documentation author, I want a clear reference explaining which section names are approved and why so that I can write new skills that align with the standard.

### Won't Have

- Automatic renaming of section headings in affected skills — OUT OF SCOPE: this is non-destructive by design; we preserve external source quality by accepting variants instead of modifying them.

## Non-Functional Requirements

- Format validation must remain performant (no regex backtracking or excessive string comparisons)
- The update must not break existing audit workflows or reports
- Documentation must be clear about which variants are approved and only for externally-sourced skills
- Changes must be backwards-compatible with prior audit reports (existing findings disappear, but no new category of false findings is introduced)

## Acceptance Criteria

- [ ] `docs/format-types.md` sections 110–123 document both standard and variant section names as acceptable
- [ ] Quick reference table (lines 255–261) in `docs/format-types.md` includes variant names
- [ ] Project-audit D4b check recognizes `## Critical Patterns`, `## Code Examples`, and `## Anti-patterns` as valid
- [ ] `/project-audit` produces zero format-contract MEDIUM findings for the 21 affected skills
- [ ] Audit score does not decrease (0 or positive delta expected)

## Notes

This PRD is optional for this technical/documentation change. It can be deleted if the proposal.md is sufficient for stakeholder communication. The change is minimal in scope and non-breaking in impact.
