# Spec: skill-metadata-attribution

Change: 2026-03-20-remove-gentleman-programming
Date: 2026-03-20

## Requirements

### Requirement 1 — Skill YAML frontmatter MUST NOT contain author attribution fields

The YAML frontmatter of skill files under `skills/*/SKILL.md` MUST NOT contain an `author:` field attributing a specific external brand or organization. The `author:` field has no functional role in the SDD system and MUST be removed when present.

#### Scenario: skill frontmatter has no author field

- **GIVEN** a skill file at `skills/<name>/SKILL.md` previously contained `author: gentleman-programming` in its YAML frontmatter
- **WHEN** the file is read after this change is applied
- **THEN** the frontmatter MUST NOT contain any `author:` key
- **AND** the frontmatter MUST remain valid YAML (the remaining fields: `name:`, `description:`, `format:` are preserved)
- **AND** the skill's functional behavior MUST be unchanged

#### Scenario: frontmatter parse succeeds after author removal

- **GIVEN** 17 skill files had `author: gentleman-programming` removed from their frontmatter
- **WHEN** any YAML parser processes the frontmatter blocks
- **THEN** all 17 frontmatter blocks MUST parse without errors
- **AND** no other frontmatter field (name, description, format, model) MUST be absent or altered

#### Scenario: audit finds no author fields in skill frontmatter

- **GIVEN** all skill files under `skills/` have been updated
- **WHEN** `grep -r "^author:" skills/` is executed
- **THEN** the command MUST return no matches

---

### Requirement 2 — CLAUDE.md Skills Registry section header MUST use neutral label

The Skills Registry section header in `CLAUDE.md` that groups technology skills MUST NOT reference a specific external brand. The header MUST use a neutral descriptive label.

#### Scenario: CLAUDE.md technology skills header is brand-neutral

- **GIVEN** `CLAUDE.md` previously contained the header `### Technology Skills (global catalog — extracted from Gentleman-Skills)`
- **WHEN** the file is read after this change is applied
- **THEN** the header MUST read `### Technology Skills (global catalog)` (or equivalent neutral phrasing)
- **AND** the header MUST NOT contain the string "Gentleman-Skills" or "Gentleman-Programming"
- **AND** the skill entries listed under the header MUST be unchanged

#### Scenario: installed runtime config reflects updated header

- **GIVEN** `install.sh` is run after the CLAUDE.md update
- **WHEN** `~/.claude/CLAUDE.md` is read
- **THEN** the technology skills section header MUST match the updated label in the repo

---

### Requirement 3 — Internal documentation MUST NOT reference external brand names in explanatory notes

Documentation files (`docs/`, `openspec/specs/`, `ai-context/`) that contain explanatory notes referencing an external organization by brand name MUST be updated to use neutral phrasing. This applies only to live files — archived records are exempt.

#### Scenario: docs/architecture-definition-report.md has no brand attribution line

- **GIVEN** the file previously contained `> **Reference**: Based on [agent-teams-lite](https://github.com/Gentleman-Programming/agent-teams-lite) v2.0`
- **WHEN** the file is read after this change is applied
- **THEN** that attribution line MUST NOT be present
- **AND** the document MUST remain self-contained and readable without the removed line

#### Scenario: ai-context/known-issues.md uses neutral corpus reference

- **GIVEN** the file previously contained a structural note referencing "Gentleman-Skills corpus"
- **WHEN** the file is read after this change is applied
- **THEN** the note MUST use neutral phrasing such as "externally-sourced skills" instead
- **AND** the meaning and content of the structural note MUST be preserved

#### Scenario: grep confirms no brand references in live files

- **GIVEN** all edits have been applied
- **WHEN** `grep -ri "gentleman" skills/ docs/ openspec/specs/ CLAUDE.md ai-context/known-issues.md` is executed
- **THEN** the command MUST return zero matches
- **AND** archive files (`openspec/changes/archive/`) MUST NOT be modified (historical records are excluded from scope)

#### Scenario: archive and historical entries are not modified

- **GIVEN** archived SDD change records exist under `openspec/changes/archive/`
- **GIVEN** existing entries in `ai-context/changelog-ai.md` reference "Gentleman-Skills" in historical session records
- **WHEN** this change is applied
- **THEN** `git diff openspec/changes/archive/` MUST show no deletions or modifications to archived files
- **AND** existing lines in `ai-context/changelog-ai.md` MUST NOT be edited (append-only record)

---

### Requirement 4 — changelog-ai.md receives a new entry documenting the brand removal

After all edits are applied, `ai-context/changelog-ai.md` MUST receive a new appended entry that documents the removal of brand references in this change.

#### Scenario: changelog entry is appended

- **GIVEN** the change has been fully applied
- **WHEN** `ai-context/changelog-ai.md` is read
- **THEN** it MUST contain a new entry (at the end of the file) for this change (`2026-03-20-remove-gentleman-programming`)
- **AND** the new entry MUST describe: files modified, what was removed, and that historical records were preserved
- **AND** all prior entries in the file MUST be unchanged
