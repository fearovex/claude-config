# Proposal: Apply project-fix Corrections — Score 72 → 89+

**Date:** 2026-02-24
**Status:** ARCHIVED
**Change:** project-fix-corrections

## Problem

First run of `/project:audit` on claude-config scored 72/100 with the following critical gaps:
- All 8 SDD phase skills written in Spanish (violates the English convention this repo enforces)
- 4 skills registered on disk but missing from CLAUDE.md registry
- CLAUDE.md missing Tech Stack, Architecture, and Unbreakable Rules sections
- 2 wrong path references (docs/ai-context/ instead of ai-context/)
- verify-report.md for retroactive archive had no test project evidence
- openspec/config.yaml had no testing block (Dimension 8 scored 0/5)

Score was below minimum_score_to_archive: 75 — changes could not be archived.

## Solution

Run `/project:fix` to implement all critical and high priority items from audit-report.md:
1. Translate all 8 SDD phase skills from Spanish to English
2. Register missing skills in CLAUDE.md
3. Add missing CLAUDE.md sections
4. Fix path references
5. Add test project evidence to verify-report.md

## Success Criteria

- Score >= 75 (minimum to archive)
- All 8 SDD phase skills in English (zero Spanish keywords)
- Skills registry bidirectionally correct
- CLAUDE.md has Tech Stack, Architecture, Unbreakable Rules
- Dimension 8 scores > 0
