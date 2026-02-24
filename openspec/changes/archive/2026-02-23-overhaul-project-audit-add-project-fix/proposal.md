# Proposal: Overhaul project-audit and Add project-fix Skill

**Date:** 2026-02-23
**Status:** ARCHIVED (retroactive)
**Change:** overhaul-project-audit-add-project-fix

## Problem

The existing project-audit skill only checked file existence across 4 dimensions. It did not verify content quality, SDD orchestrator readiness, cross-reference integrity, or architecture compliance. There was no skill to apply the audit findings automatically.

## Solution

1. Rewrite project-audit with 7 dimensions (expanded to 8 in subsequent change)
2. Create project-fix skill that reads audit-report.md as its spec and implements corrections phase by phase
3. Register /project:fix in global CLAUDE.md meta-tools table

## Success Criteria

- project-audit generates a FIX_MANIFEST block in audit-report.md
- project-fix reads that manifest and implements corrections
- Running /project:audit after /project:fix shows an improved score
