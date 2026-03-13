# Task Plan: 2026-03-13-fix-skills-structural

Date: 2026-03-13
Design: openspec/changes/2026-03-13-fix-skills-structural/design.md
Spec: openspec/changes/2026-03-13-fix-skills-structural/specs/skill-compliance/spec.md

## Progress: 3/4 tasks

## Phase 1: Structural Fixes

- [x] 1.1 Remove dead `/skill-add` documentation from `skills/skill-creator/SKILL.md` (lines 294–319)
  - **Description**: Delete 26 lines of dead documentation for `/skill-add` mode that is fully delegated to the separate `skill-add/SKILL.md` skill. This section is confusing and misleading to users who read skill-creator and expect it to handle `/skill-add`.
  - **File affected**: `skills/skill-creator/SKILL.md`
  - **Expected change**: Remove lines 294–319 (heading "## Process: /skill-add" through end of that section, before "## Global Catalog Skills")
  - **Acceptance criteria**:
    - Lines 294–319 are deleted from the file
    - The file remains valid Markdown
    - The `/skill-create` functionality documentation (all preceding sections) is unaffected
    - The section prior to the deletion (line 293: "---") and section after (line 320 onward: "## Global Catalog Skills") are properly adjacent
  - **Dependencies**: None
  - **Estimated effort**: 2 minutes

- [x] 1.2 Translate Spanish comment to English in `skills/pytest/SKILL.md` (line 51)
  - **Description**: Change the Spanish comment `# Teardown automático` to English `# Teardown automatic`. This fixes a violation of Unbreakable Rule 1 (ALL content MUST be in English).
  - **File affected**: `skills/pytest/SKILL.md`
  - **Expected change**: Line 51 changed from `database.cleanup()  # Teardown automático` to `database.cleanup()  # Teardown automatic`
  - **Acceptance criteria**:
    - Line 51 comment is changed to English
    - The code `database.cleanup()` is unchanged
    - No other lines are modified
    - The file remains valid Markdown and Python syntax
  - **Dependencies**: None
  - **Estimated effort**: 1 minute

- [x] 1.3 Rename section heading in `skills/elixir-antipatterns/SKILL.md` (line 28)
  - **Description**: Change the section heading from `## Critical Patterns` to `## Anti-patterns` to match the declared `format: anti-pattern` in the YAML frontmatter. This fixes a format contract violation.
  - **File affected**: `skills/elixir-antipatterns/SKILL.md`
  - **Expected change**: Line 28 changed from `## Critical Patterns` to `## Anti-patterns`
  - **Acceptance criteria**:
    - Line 28 heading is renamed to `## Anti-patterns`
    - The content within the section (lines 29 onward) is unchanged
    - The file satisfies the format contract for `format: anti-pattern` (requires `**Triggers**`, `## Anti-patterns`, `## Rules`)
    - The file remains valid Markdown
  - **Dependencies**: None
  - **Estimated effort**: 1 minute

- [x] 1.4 Remove duplicate sections in `skills/claude-code-expert/SKILL.md` (consolidate Description and Triggers)
  - **Description**: The file declares `format: reference` but contains duplicate `## Description` and `**Triggers**` sections. Identify and remove the duplicate declarations, keeping one clean pair at the front of the file. Preserve all patterns, examples, and rules content.
  - **File affected**: `skills/claude-code-expert/SKILL.md`
  - **Expected change**:
    - Remove the second `## Description` section (lines 165–171 or the duplicate instance)
    - Remove duplicate `**Triggers**` declaration(s)
    - Keep exactly one `**Triggers**` declaration (in the YAML frontmatter or first declaration in the content)
    - Keep exactly one `## Description` section at the front
    - Preserve all pattern sections, examples, and rules
  - **Acceptance criteria**:
    - The file contains exactly one `**Triggers**` declaration in the main skill documentation
    - The file contains exactly one `## Description` section in the main skill documentation
    - All pattern sections (File Structure, CLAUDE.md Configuration, Creating Skills, etc.) are preserved
    - All example code blocks and rules remain unchanged
    - The file satisfies the format contract for `format: reference` (requires `**Triggers**`, `## Patterns` or `## Examples`, `## Rules`)
    - The file remains valid Markdown
  - **Dependencies**: None
  - **Estimated effort**: 3 minutes

---

## Implementation Notes

- All edits are surgical (minimal scope, no functional changes to the skills themselves)
- The Edit tool will be used with precise string matching to ensure atomicity and reversibility
- Each file will be re-read after editing to verify changes applied correctly
- Format contracts per `docs/format-types.md`:
  - `format: procedural` requires: `**Triggers**`, `## Process`, `## Rules`
  - `format: reference` requires: `**Triggers**`, `## Patterns` or `## Examples`, `## Rules`
  - `format: anti-pattern` requires: `**Triggers**`, `## Anti-patterns`, `## Rules`

## Blockers

None. All files are readable, all changes are straightforward text edits, and no external dependencies block implementation.

---

## Verification Strategy

After all tasks are completed, each modified skill will be validated against its declared format contract by manual inspection of `docs/format-types.md` requirements. The `/project-audit` tool dimension D4b (Structural Compliance) will be run to verify no new format violations were introduced.

---

## Order of Execution

Tasks should be executed in order (1.1, 1.2, 1.3, 1.4) to maintain logical grouping and ease of review. However, each task is independent and could be reordered if needed.
