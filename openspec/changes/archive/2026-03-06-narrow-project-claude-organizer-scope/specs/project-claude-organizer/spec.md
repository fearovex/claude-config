# Delta Spec: project-claude-organizer

Change: narrow-project-claude-organizer-scope
Date: 2026-03-06
Base: openspec/specs/project-claude-organizer/spec.md

---

## ADDED — New requirements

### Requirement: project-claude-organizer exposes an explicit organizer kernel

The `project-claude-organizer` skill MUST describe its command flow as a stable organizer kernel with four stages: detect, classify, propose, and apply additive migrations.

The kernel is a product-level contract. Existing migration strategies may evolve, but they operate inside this four-stage flow rather than redefining the command.

#### Scenario: Skill documents the organizer kernel as a top-level contract

- **GIVEN** a developer reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they read the top-level structure before the detailed steps
- **THEN** they find an explicit section describing the organizer kernel
- **AND** that section names detect, classify, propose, and apply additive migrations as the core stages

#### Scenario: Organizer kernel does not replace existing migration details

- **GIVEN** `skills/project-claude-organizer/SKILL.md` has been updated by this change
- **WHEN** the migration strategy sections are read
- **THEN** the existing detailed handlers are still present
- **AND** the kernel acts as an umbrella contract rather than a replacement for detailed strategy logic

---

### Requirement: project-claude-organizer classifies behavior by scope boundary

The `project-claude-organizer` skill MUST distinguish between three behavior classes:

- **Core additive migrations** — safe create/copy/append operations that remain in organizer core behavior
- **Explicit opt-in operations** — scaffolding, user-choice branches, and cleanup deletions that require either category-level confirmation or post-migration confirmation
- **Advisory-only outcomes** — unexpected items, skills-audit findings, non-qualifying files, and ambiguous routing cases that do not trigger organizer mutations automatically

#### Scenario: Core additive migrations are described separately from advisory outcomes

- **GIVEN** a developer reads `skills/project-claude-organizer/SKILL.md`
- **WHEN** they inspect the top-level contract sections
- **THEN** they can identify which outcomes are core additive migrations
- **AND** they can identify which outcomes are advisory only

#### Scenario: Cleanup deletion is not treated as core organizer behavior

- **GIVEN** the organizer skill has been updated by this change
- **WHEN** a developer reads the scope-boundary contract
- **THEN** cleanup deletion is described as an explicit opt-in follow-up to successful migration
- **AND** it is not described as part of the organizer kernel itself

---

### Requirement: skills audit remains advisory and does not expand mutation scope

The skills-audit portion of `project-claude-organizer` MUST remain diagnostic only.

Even when it reports HIGH-severity findings such as scope overlap, it MUST NOT expand the organizer's automatic mutation scope to rewrite or delete project-local skills.

#### Scenario: Skills audit finding does not authorize mutation

- **GIVEN** the organizer detects a HIGH-severity `scope_overlap` finding in `.claude/skills/`
- **WHEN** the organizer applies the plan
- **THEN** the finding is reported in the output artifact
- **AND** no project-local skill file is rewritten or deleted solely because of that finding

---

### Requirement: ambiguous or unsupported structures remain manual-review outcomes

When `project-claude-organizer` encounters an item that does not map cleanly to a supported migration path, it MUST preserve the existing advisory-first posture.

Ambiguous routing cases, non-qualifying command files, unsupported legacy items, and unexpected structures MUST remain reportable manual-review outcomes rather than speculative organizer mutations.

#### Scenario: Unexpected structure remains advisory-only

- **GIVEN** an item under `.claude/` does not match the canonical set or any supported legacy pattern
- **WHEN** the organizer classifies the project
- **THEN** the item remains reported as unexpected/manual review
- **AND** the organizer does not invent a new migration path for it automatically

#### Scenario: Non-qualifying commands file remains advisory-only

- **GIVEN** `.claude/commands/misc-notes.md` contains no qualifying scaffold signals
- **WHEN** the organizer processes the `commands/` category
- **THEN** the file is reported as advisory-only
- **AND** the organizer does not scaffold or modify it

## Rules

- This change is contractual and scoping-oriented; it MUST NOT rename `/project-claude-organizer`
- This change MUST preserve the additive-first mutation model already established in organizer behavior
- Skills-audit findings remain advisory regardless of severity unless a future dedicated command is introduced for remediation
- Cleanup deletion remains a post-migration opt-in path, not part of the organizer kernel itself