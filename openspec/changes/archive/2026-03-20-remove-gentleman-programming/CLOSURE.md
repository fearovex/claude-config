# Closure: 2026-03-20-remove-gentleman-programming

Start date: 2026-03-20
Close date: 2026-03-20

## Summary

Removed all live references to "Gentleman-Programming" / "Gentleman-Skills" from active configuration files, replacing brand-specific labels with neutral equivalents. 41 file locations addressed; 17 skill YAML frontmatter lines, 1 CLAUDE.md section header, 8 documentation and spec requirement phrases updated. Archives and changelog entries preserved unchanged.

## Modified Specs

| Domain   | Action                 | Change        |
| -------- | ---------------------- | ------------- |
| skill-metadata-attribution | Created | New master spec defining requirements for removal of external brand attribution from skill metadata and documentation |
| format-contract | Modified | Updated Implementation Notes section to use neutral "externally-sourced skills" terminology instead of "Gentleman-Skills corpus" |
| skills-catalog-format | Modified | Updated Scenario documentation requirement to specify neutral phrasing ("externally-sourced skills") in variant attribution notes |

## Modified Code Files

**Skills catalog (17 files):**
- skills/react-19/SKILL.md
- skills/nextjs-15/SKILL.md
- skills/typescript/SKILL.md
- skills/zustand-5/SKILL.md
- skills/zod-4/SKILL.md
- skills/tailwind-4/SKILL.md
- skills/ai-sdk-5/SKILL.md
- skills/react-native/SKILL.md
- skills/electron/SKILL.md
- skills/django-drf/SKILL.md
- skills/spring-boot-3/SKILL.md
- skills/hexagonal-architecture-java/SKILL.md
- skills/java-21/SKILL.md
- skills/playwright/SKILL.md
- skills/pytest/SKILL.md
- skills/github-pr/SKILL.md
- skills/jira-task/SKILL.md

**Configuration:**
- CLAUDE.md (section header: "### Technology Skills (global catalog)")
- docs/format-types.md (3 phrase replacements in variant heading notes)
- docs/architecture-definition-report.md (removed: Reference to agent-teams-lite GitHub link)
- openspec/specs/format-contract/spec.md (2 line updates in Implementation Notes)
- openspec/specs/skills-catalog-format/spec.md (1 line update in scenario documentation)
- ai-context/known-issues.md (1 phrase replacement in structural note)
- ai-context/changelog-ai.md (1 new entry appended)
- openspec/specs/index.yaml (1 new entry added for skill-metadata-attribution domain)

## Key Decisions Made

1. **Complete removal of `author:` field**: No replacement or alternative value — the field has no functional role in the SDD system. Removal is cleaner than substitution.

2. **Neutral terminology standardization**: Replaced "Gentleman-Skills corpus" with "externally-sourced skills" throughout live documentation and specs. This terminology preserves the semantic meaning (variants come from well-vetted external sources) without naming a specific external brand.

3. **Archive immutability**: Preserved all historical records in `openspec/changes/archive/` unchanged. The SDD audit trail remains intact.

4. **Changelog append-only**: New entry added at top of `ai-context/changelog-ai.md` documenting the removal. All prior entries remain unedited per project convention.

5. **Installation deployment**: Ran `install.sh` after CLAUDE.md edit to propagate the change to `~/.claude/CLAUDE.md`.

## Lessons Learned

1. **Brand decoupling is low-risk**: Removing attribution metadata and renaming section labels produce zero behavioral changes to the SDD system. All functional logic remains intact — only labels and comments change.

2. **Neutral terminology works**: "Externally-sourced skills" is a cleaner, source-agnostic way to refer to production-quality skills from external well-vetted sources without naming a specific organization.

3. **Spec-driven removals**: The change was fully spec-driven — REQ-1 through REQ-4 in skill-metadata-attribution define each removal requirement. Verification confirmed all 15 scenarios passed.

4. **Frontmatter consistency**: After removal, all 17 skill files maintain valid YAML frontmatter with consistent fields (`name`, `description`, `format`, `model`).

## User Docs Reviewed

N/A — change does not affect user-facing workflows or command documentation. This is a configuration/metadata housekeeping change with no impact on skill functionality or user experience.
