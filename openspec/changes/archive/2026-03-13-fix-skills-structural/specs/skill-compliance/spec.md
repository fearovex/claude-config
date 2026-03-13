# Spec: Skill Structural Compliance

Change: 2026-03-13-fix-skills-structural
Date: 2026-03-13

## Requirements

### Requirement 1: skill-creator SKILL.md — Remove dead /skill-add documentation

**Description**: The skill-creator skill contains 25 lines (lines 294–319) documenting a `/skill-add` mode that is fully delegated to the separate `skill-add/SKILL.md` skill. This section MUST be removed to eliminate duplicate and confusing documentation. The `/skill-create` functionality (the primary purpose of skill-creator) MUST remain unchanged.

#### Scenario: Dead code block exists and can be identified

- **GIVEN** the skill-creator/SKILL.md file is read as-is from the repository
- **WHEN** lines 294–319 are examined
- **THEN** they contain a "## Process: /skill-add" section heading (line 295)
- **AND** lines 297–318 describe verification steps, catalog lookup, and delegation logic
- **AND** line 317–318 explicitly state the delegation: "The addition strategy (local copy vs. global reference) is fully owned by `skill-add/SKILL.md`"

#### Scenario: Successful removal of dead section

- **GIVEN** skill-creator/SKILL.md contains lines 294–319 as described above
- **WHEN** lines 294–319 are deleted
- **THEN** the file is modified but valid
- **AND** the preceding content (line 293: "---") is preserved
- **AND** the following content (line 320 onward: "## Global Catalog Skills") is preserved without gap
- **AND** no functional `/skill-create` documentation is removed

#### Scenario: No functional behavior change

- **GIVEN** the `/skill-create` functionality is documented in earlier sections of skill-creator/SKILL.md
- **WHEN** lines 294–319 are removed
- **THEN** the remaining `/skill-create` documentation is identical and unchanged
- **AND** the skill's format (procedural) and triggers remain the same
- **AND** the skill's Process, Rules, and other sections are unaffected

---

### Requirement 2: pytest SKILL.md — Translate Spanish comment to English

**Description**: The pytest skill contains a Spanish comment on line 51 that violates the English-only language rule (Unbreakable Rule 1 in CLAUDE.md). The comment `# Teardown automático` MUST be changed to `# Teardown automatic` with no other changes to the code or logic.

#### Scenario: Spanish comment is identified

- **GIVEN** pytest/SKILL.md line 51 is examined
- **WHEN** the line is read
- **THEN** it contains the text `database.cleanup()  # Teardown automático`
- **AND** the comment uses Spanish language (violating Unbreakable Rule 1)

#### Scenario: Comment is successfully translated

- **GIVEN** line 51 contains `database.cleanup()  # Teardown automático`
- **WHEN** "automático" is replaced with "automatic"
- **THEN** line 51 reads `database.cleanup()  # Teardown automatic`
- **AND** the code itself (`database.cleanup()`) is unchanged
- **AND** no other lines are modified

#### Scenario: English-only rule is satisfied

- **GIVEN** the translated file is scanned for non-English text
- **WHEN** scanning from line 1 to end-of-file
- **THEN** no Spanish, French, or other non-English text is found (excluding code identifiers and URLs)
- **AND** the comment intent ("this is an automatic teardown") is preserved

---

### Requirement 3: elixir-antipatterns SKILL.md — Rename section heading

**Description**: The elixir-antipatterns skill declares `format: anti-pattern` in its YAML frontmatter (line 11) but uses the incorrect section heading `## Critical Patterns` (line 28) instead of the required `## Anti-patterns`. The section heading MUST be renamed from `## Critical Patterns` to `## Anti-patterns` to match the declared format and satisfy the format contract (per `docs/format-types.md`).

#### Scenario: Format declaration and section heading mismatch is identified

- **GIVEN** elixir-antipatterns/SKILL.md is read from lines 1–40
- **WHEN** the YAML frontmatter is examined
- **THEN** line 11 contains `format: anti-pattern`
- **AND** the main skill content shows `## Critical Patterns` at line 28
- **AND** per `docs/format-types.md`, `format: anti-pattern` requires `## Anti-patterns` (not `## Critical Patterns`)

#### Scenario: Section heading is successfully renamed

- **GIVEN** line 28 currently reads `## Critical Patterns`
- **WHEN** the heading is changed to `## Anti-patterns`
- **THEN** line 28 now reads `## Anti-patterns`
- **AND** no content within the section (lines 29 onward) is modified
- **AND** the list of 8 patterns (lines 30–39) remains unchanged

#### Scenario: Format contract is satisfied

- **GIVEN** the file declares `format: anti-pattern` in the frontmatter
- **WHEN** line 28 is inspected after the change
- **THEN** it contains the required `## Anti-patterns` section heading
- **AND** the format contract per `docs/format-types.md` (required sections table, line 195) is satisfied

---

### Requirement 4: claude-code-expert SKILL.md — Consolidate duplicate sections

**Description**: The claude-code-expert skill declares `format: reference` but contains duplicate `## Description` and `**Triggers**` sections. Per the format contract (reference format requires exactly one `**Triggers**` declaration and no duplicate section headings), all duplicate declarations MUST be removed. One clean `**Triggers**` and one `## Description` section MUST remain at the front of the file. All patterns, examples, and rules content MUST be preserved.

#### Scenario: Duplicate sections are identified

- **GIVEN** claude-code-expert/SKILL.md is examined
- **WHEN** lines 1–50 are scanned
- **THEN** line 13 contains the first `## Description` heading
- **AND** line 23 contains the first `**Triggers**` declaration
- **AND** lines 165–171 contain a second `## Description` section (within a code block example showing incorrect structure)
- **AND** line 170 contains duplicate `**Triggers**` text (within the same example)

#### Scenario: Duplicate example code block is removed

- **GIVEN** lines 165–171 contain the example showing incorrect SKILL.md structure
- **WHEN** the file is reviewed for duplicates in the actual skill documentation (not within code examples)
- **THEN** only one `## Description` and one `**Triggers**` exist in the actual skill documentation (lines 13 and 23)
- **AND** lines 165–171 are part of an embedded example showing "do not do this" and are preserved as an example

#### Scenario: Format contract is satisfied

- **GIVEN** the file declares `format: reference` in the YAML frontmatter
- **WHEN** the structure is inspected after verification
- **THEN** the frontmatter, H1 title, blockquote description, `**Triggers**` declaration, and pattern/rule sections are present
- **AND** per `docs/format-types.md` (line 110–116), the reference format contract is satisfied with one `**Triggers**` and one set of patterns/examples/rules
- **AND** no duplicate headings exist in the main skill documentation

#### Scenario: All content is preserved

- **GIVEN** the skill has multiple pattern sections (`## File Structure for Claude Code`, `## CLAUDE.md Configuration`, `## Creating Skills`, etc.)
- **WHEN** deduplication is applied
- **THEN** all pattern sections are preserved
- **AND** all example code blocks, best practices, and rules remain unchanged
- **AND** only structural duplicate headings are removed

---

## Acceptance Criteria

- [ ] skill-creator/SKILL.md: Lines 294–319 removed; file is valid markdown; `/skill-create` functionality unaffected
- [ ] pytest/SKILL.md: Line 51 comment changed from `# Teardown automático` to `# Teardown automatic`; no code logic changes
- [ ] elixir-antipatterns/SKILL.md: Section heading on line 28 changed from `## Critical Patterns` to `## Anti-patterns`; format contract satisfied
- [ ] claude-code-expert/SKILL.md: Verified to contain exactly one `**Triggers**` declaration and one `## Description` section in main skill documentation; all pattern/example/rule content preserved
- [ ] All four skills pass format contract validation per `docs/format-types.md`
- [ ] No unintended changes to other files
- [ ] All files remain valid YAML + Markdown after changes
