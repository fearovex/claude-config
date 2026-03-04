# Delta Spec: config-export-skill

Change: config-export-token-optimization
Date: 2026-03-04
Base: openspec/specs/config-export-skill/spec.md

## Overview

This delta spec captures the behavioral changes to the `config-export` skill's
invocation contract and source collection step introduced by the
token-optimization refactoring. The observable behavior of target selection,
dry-run, file writing, overwrite warnings, and summary is unchanged and governed
by the base spec. Only the source collection step gains new filtering behavior.

---

## ADDED — New requirements

### Requirement: config-export skips the Skills Registry block of CLAUDE.md during source collection

During Step 1 (source collection), when the skill reads `CLAUDE.md` into the
in-context bundle, the Skills Registry section (lines listing
`~/.claude/skills/...` or `.claude/skills/...` file paths) MUST be excluded
from the content passed to transformation prompts. The file itself is still
read; only the registry block is excluded from transformation input.

#### Scenario: CLAUDE.md contains a Skills Registry section

- **GIVEN** the source `CLAUDE.md` includes a `## Skills Registry` section
  containing lines starting with `~/.claude/skills/` or `.claude/skills/`
- **WHEN** the skill builds the in-context bundle for transformation
- **THEN** the Skills Registry block is not included in the context passed to
  the Copilot, Gemini, or Cursor transformation prompts
- **AND** all other sections of `CLAUDE.md` are retained in the bundle

#### Scenario: CLAUDE.md has no Skills Registry section

- **GIVEN** the source `CLAUDE.md` does NOT contain a `## Skills Registry`
  section
- **WHEN** the skill builds the in-context bundle for transformation
- **THEN** the full `CLAUDE.md` content is included unchanged
- **AND** no error or warning is emitted

---

### Requirement: config-export skips auto-updated sections of ai-context/ files during source collection

When reading `ai-context/architecture.md` and `ai-context/conventions.md` into
the in-context bundle, the skill MUST exclude sections bracketed by
`<!-- [auto-updated]` ... `<!-- [/auto-updated] -->` markers. These sections
(such as "Observed Conventions", "Architecture Drift", "Observed Structure")
are auto-generated and MUST NOT be passed to transformation prompts.

#### Scenario: architecture.md contains an auto-updated section

- **GIVEN** `ai-context/architecture.md` contains one or more sections wrapped
  in `<!-- [auto-updated] -->` ... `<!-- [/auto-updated] -->` HTML comment
  markers
- **WHEN** the skill builds the in-context bundle for transformation
- **THEN** the content between those markers (inclusive of the markers) is
  excluded from the bundle
- **AND** all content outside the markers is retained

#### Scenario: architecture.md has no auto-updated markers

- **GIVEN** `ai-context/architecture.md` contains no `<!-- [auto-updated] -->`
  markers
- **WHEN** the skill builds the in-context bundle for transformation
- **THEN** the full `architecture.md` content is included in the bundle
- **AND** no error or warning is emitted

#### Scenario: conventions.md contains an auto-updated section

- **GIVEN** `ai-context/conventions.md` contains one or more sections wrapped
  in `<!-- [auto-updated] -->` ... `<!-- [/auto-updated] -->` HTML comment
  markers
- **WHEN** the skill builds the in-context bundle for transformation
- **THEN** those auto-updated sections are excluded from the bundle
- **AND** all content outside the markers is retained

---

## MODIFIED — Modified requirements

*(No existing config-export-skill requirements are modified by this change. The
source collection priority order (CLAUDE.md → stack.md → architecture.md →
conventions.md → known-issues.md) remains unchanged. The filtering described
above is applied after reading, before transformation.)*

---

## REMOVED — Removed requirements

*(No existing config-export-skill requirements are removed by this change.)*

---

## Rules

- The Skills Registry filtering MUST be applied to `CLAUDE.md` content before
  it is passed to any transformation prompt; it MUST NOT alter or truncate the
  `CLAUDE.md` file on disk
- The auto-updated section filtering MUST be applied to `architecture.md` and
  `conventions.md` only; `stack.md` and `known-issues.md` are not filtered
- Filtering is silent — no WARNING or INFO message is emitted to the user when
  content is filtered
- The output files produced after filtering MUST be substantively identical in
  content to those produced by the pre-optimization skill (no new sections
  removed or added relative to the pre-change baseline)
- `known-issues.md` and `stack.md` are NOT subject to auto-updated section
  filtering (they are not known to contain `[auto-updated]` blocks)
