# Closure: clean-skill-template-noise

Start date: 2026-03-08
Close date: 2026-03-08

## Summary

Reduced low-priority template noise in the active skill catalog by balancing the nested report-example fences in `project-audit` and replacing raw scaffold `TODO` markers with explicit scaffold wording in `project-fix` and `project-claude-organizer`.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| skill-template-noise | Created | Added the master contract for balanced nested report fences and explicit scaffold placeholder wording |

## Modified Code Files

- `skills/project-audit/SKILL.md`
- `skills/project-fix/SKILL.md`
- `skills/project-claude-organizer/SKILL.md`
- `openspec/specs/skill-template-noise/spec.md`
- `ai-context/changelog-ai.md`

## Key Decisions Made

- Keep the cleanup in the existing active skills rather than moving templates into dedicated files.
- Replace raw `TODO` markers with explicit scaffold language that is still clearly placeholder content.
- Preserve command behavior, mutation authority, and trigger semantics.

## Lessons Learned

- Small documentation-hygiene fixes still benefit from a narrow SDD cycle when they touch active skill contracts.
- Placeholder scans are easier to keep quiet when scaffold wording is explicit instead of generic.

## User Docs Reviewed

NO — change does not affect user-facing workflows
