# Delta Spec: config-export-targets

Change: config-export-token-optimization
Date: 2026-03-04
Base: openspec/specs/config-export-targets/spec.md

## Overview

This delta spec captures the behavioral changes to the three transformation
prompts (Copilot, Gemini, Cursor) introduced by the token-optimization
refactoring. The change consolidates the repeated STRIP preamble shared by all
three prompts into a single shared definition and adds explicit skip instructions
for the Skills Registry and auto-updated ai-context/ sections.

The observable output requirements for the generated files (content, format,
encoding, canonical paths) defined in the base spec are UNCHANGED. This delta
specifies only the new structural constraints on the transformation prompts
themselves — observable at the SKILL.md level, not at the generated file level.

---

## ADDED — New requirements

### Requirement: a single shared STRIP preamble governs common strip items across all three transformation prompts

The `config-export/SKILL.md` MUST define exactly one shared STRIP preamble
block. The three transformation prompts (Copilot, Gemini, Cursor) MUST reference
this shared block by name rather than each repeating its own full copy of the
common strip items.

#### Scenario: shared STRIP block is present and referenced

- **GIVEN** the `config-export/SKILL.md` is read
- **WHEN** its transformation prompt section is inspected
- **THEN** exactly one shared STRIP preamble definition exists, positioned
  before the three individual transformation prompts
- **AND** each of the three transformation prompts references the shared block
  (e.g., "Apply the Shared STRIP Preamble above, then additionally strip:")
  rather than repeating the full strip item list verbatim
- **AND** the combined line count of the three transformation prompts is reduced
  by at least 30 lines relative to the pre-change baseline

#### Scenario: shared block items are still applied to all three targets

- **GIVEN** the shared STRIP preamble defines a common set of strip items
  (slash commands, Task tool references, sub-agent patterns, install.sh and
  sync.sh references, etc.)
- **WHEN** the Copilot transformation is applied to a source bundle containing
  those items
- **THEN** none of the common strip items appear in `.github/copilot-instructions.md`
- **WHEN** the Gemini transformation is applied to the same source bundle
- **THEN** none of the common strip items appear in `GEMINI.md`
- **WHEN** the Cursor transformation is applied to the same source bundle
- **THEN** none of the common strip items appear in any `.cursor/rules/*.mdc` file

---

### Requirement: all three transformation prompts explicitly skip the Skills Registry section

Each transformation prompt (or the shared STRIP preamble) MUST include an
explicit instruction to skip or discard the Skills Registry section of `CLAUDE.md`.

#### Scenario: Copilot transformation excludes Skills Registry content

- **GIVEN** the source `CLAUDE.md` includes a `## Skills Registry` section
  listing skill file paths
- **WHEN** the Copilot transformation is applied
- **THEN** `.github/copilot-instructions.md` does NOT contain the Skills
  Registry block (skill file paths starting with `~/.claude/skills/` or
  `.claude/skills/`)
- **AND** all other content retained by the base spec is still present

#### Scenario: Gemini transformation excludes Skills Registry content

- **GIVEN** the source `CLAUDE.md` includes a `## Skills Registry` section
- **WHEN** the Gemini transformation is applied
- **THEN** `GEMINI.md` does NOT contain the Skills Registry block
- **AND** all other content retained by the base spec is still present

#### Scenario: Cursor transformation excludes Skills Registry content

- **GIVEN** the source `CLAUDE.md` includes a `## Skills Registry` section
- **WHEN** the Cursor transformation is applied
- **THEN** no `.cursor/rules/*.mdc` file contains the Skills Registry block
- **AND** all other content retained by the base spec is still present

---

### Requirement: all three transformation prompts explicitly skip auto-updated sections of ai-context/ files

Each transformation prompt (or the shared STRIP preamble) MUST include an
explicit instruction to skip sections of `ai-context/architecture.md` and
`ai-context/conventions.md` that are wrapped in `<!-- [auto-updated] -->` ...
`<!-- [/auto-updated] -->` markers.

#### Scenario: architecture.md auto-updated content is absent from all target outputs

- **GIVEN** the source bundle includes `ai-context/architecture.md` containing
  an `<!-- [auto-updated] -->` section (e.g., "Observed Structure",
  "Architecture Drift")
- **WHEN** any of the three transformations (Copilot, Gemini, Cursor) are applied
- **THEN** the auto-updated section content does NOT appear in any generated
  output file
- **AND** content from `architecture.md` that is NOT inside an auto-updated
  block (e.g., key architectural decisions, system role description) is still
  retained in outputs where applicable

#### Scenario: conventions.md auto-updated content is absent from all target outputs

- **GIVEN** the source bundle includes `ai-context/conventions.md` containing
  an `<!-- [auto-updated] -->` section (e.g., "Observed Conventions")
- **WHEN** any of the three transformations (Copilot, Gemini, Cursor) are applied
- **THEN** the auto-updated section content does NOT appear in any generated
  output file
- **AND** non-auto-updated conventions content is retained in outputs where
  applicable

---

### Requirement: output files generated after the optimization are substantively identical to pre-change output

The refactoring of SKILL.md (shared STRIP block, skip instructions) MUST NOT
change the observable content of the generated output files.

#### Scenario: Copilot output is content-equivalent before and after the change

- **GIVEN** a fixed source bundle (CLAUDE.md + ai-context/ files unchanged)
- **WHEN** the Copilot transformation is applied with the optimized SKILL.md
- **THEN** `.github/copilot-instructions.md` is substantively identical in
  content to the file generated by the pre-optimization SKILL.md
- **AND** no section present in the pre-change output is absent in the
  post-change output
- **AND** no new section absent in the pre-change output appears in the
  post-change output

#### Scenario: Gemini output is content-equivalent before and after the change

- **GIVEN** a fixed source bundle
- **WHEN** the Gemini transformation is applied with the optimized SKILL.md
- **THEN** `GEMINI.md` is substantively identical in content to the pre-change
  output

#### Scenario: Cursor output is content-equivalent before and after the change

- **GIVEN** a fixed source bundle
- **WHEN** the Cursor transformation is applied with the optimized SKILL.md
- **THEN** each `.cursor/rules/*.mdc` file is substantively identical in
  content to the corresponding pre-change file

---

## MODIFIED — Modified requirements

*(No existing config-export-targets requirements are modified in terms of
observable output behavior. The STRIP categories table and all per-target
content and format requirements from the base spec remain in force.)*

---

## REMOVED — Removed requirements

*(No existing config-export-targets requirements are removed by this change.)*

---

## Rules

- The shared STRIP preamble MUST be a distinct, named section in SKILL.md
  positioned before the three individual transformation prompt sub-sections
- Each transformation prompt MUST NOT reproduce the full common strip item list
  verbatim — it MUST use a reference to the shared block for common items
- Target-specific strip items (items that apply to only one or two targets)
  MAY still be listed inline in the individual transformation prompt
- The Skills Registry skip instruction MUST be included in the shared STRIP
  preamble (not per-prompt) since it applies to all three targets
- The auto-updated section skip instruction MUST be included in the shared
  STRIP preamble since it applies to all three targets
- The output content equivalence requirement is the definitive acceptance
  criterion: any optimization that changes the observable generated output is
  non-conforming, regardless of token savings achieved
