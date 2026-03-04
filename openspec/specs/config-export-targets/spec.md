# Spec: config-export-targets

Change: config-export
Date: 2026-03-03

## Overview

This spec describes the observable output requirements for each export target
produced by the `config-export` skill. It covers content requirements, format
constraints, and what Claude Code-specific content MUST be stripped or adapted
in each target's output. Implementation prompts are not specified here — only
the observable properties of the generated files.

---

## Requirements

### Requirement: Copilot export produces a flat Markdown file focused on code conventions

The generated `.github/copilot-instructions.md` MUST be readable by GitHub
Copilot as a project-level instruction file. It MUST contain the project's
code conventions, tech stack, and coding rules in plain Markdown prose. It MUST
NOT contain Claude Code-specific syntax or orchestration references.

#### Scenario: copilot output contains tech stack information

- **GIVEN** the source bundle includes `ai-context/stack.md`
- **WHEN** the copilot export is generated
- **THEN** `.github/copilot-instructions.md` contains a section describing the
  project's tech stack (language, framework, key tools)
- **AND** the stack information is expressed in plain prose or a Markdown table,
  not as skill registry entries

#### Scenario: copilot output contains code conventions

- **GIVEN** the source bundle includes `ai-context/conventions.md`
- **WHEN** the copilot export is generated
- **THEN** `.github/copilot-instructions.md` contains the project's coding
  conventions (naming, style, patterns)
- **AND** the conventions are expressed as direct instructions to the AI
  assistant (imperative voice), not as meta-instructions to an orchestrator

#### Scenario: copilot output strips Claude Code-specific syntax

- **GIVEN** the source `CLAUDE.md` contains Claude Code slash commands (e.g.,
  `/sdd-ff`, `/project-audit`), Task tool references, and sub-agent delegation
  patterns
- **WHEN** the copilot export is generated
- **THEN** `.github/copilot-instructions.md` does NOT contain any slash
  commands, Task tool invocations, or sub-agent launch patterns
- **AND** the skill registry table from CLAUDE.md is NOT reproduced verbatim

#### Scenario: copilot output includes known issues when present

- **GIVEN** the source bundle includes `ai-context/known-issues.md` with
  non-empty content
- **WHEN** the copilot export is generated
- **THEN** `.github/copilot-instructions.md` contains a section summarizing
  known issues or gotchas relevant to a developer working in the project

#### Scenario: copilot output is valid Markdown

- **GIVEN** the copilot export has been generated
- **WHEN** a Markdown parser reads the file
- **THEN** the file contains no malformed headings, unclosed code blocks, or
  broken links
- **AND** the file starts with a top-level heading (e.g., `# Project Instructions`)

---

### Requirement: Gemini export produces a GEMINI.md that mirrors CLAUDE.md structure with adaptations

The generated `GEMINI.md` MUST follow a structure similar to `CLAUDE.md` (a
top-level instruction file for the Gemini assistant) but with Claude
Code-specific references adapted or removed.

#### Scenario: GEMINI.md preserves project identity and working principles

- **GIVEN** the source `CLAUDE.md` contains a working principles section
- **WHEN** the Gemini export is generated
- **THEN** `GEMINI.md` contains the project's working principles (clean code,
  no over-engineering, tests as first-class citizens, etc.)
- **AND** the principles are retained with equivalent phrasing

#### Scenario: GEMINI.md contains architecture and conventions

- **GIVEN** the source bundle includes `ai-context/architecture.md` and
  `ai-context/conventions.md`
- **WHEN** the Gemini export is generated
- **THEN** `GEMINI.md` contains sections describing the project architecture and
  conventions
- **AND** the content is adapted to remove references to SDD phases, artifacts,
  and the orchestrator delegation model

#### Scenario: GEMINI.md strips Claude Code-specific command tables

- **GIVEN** the source `CLAUDE.md` contains the "Available Commands" table with
  `/sdd-ff`, `/project-audit`, `/skill-create`, and other meta-tool commands
- **WHEN** the Gemini export is generated
- **THEN** `GEMINI.md` does NOT contain the SDD command table verbatim
- **AND** if a commands/shortcuts section is present in `GEMINI.md`, it MUST
  NOT reference commands that do not exist in Gemini CLI (slash commands are
  Claude Code-specific)

#### Scenario: GEMINI.md strips Task tool and sub-agent delegation patterns

- **GIVEN** the source `CLAUDE.md` includes orchestrator delegation patterns
  (Task tool, sub-agent launch pattern, phase DAG)
- **WHEN** the Gemini export is generated
- **THEN** `GEMINI.md` does NOT contain any reference to the Task tool,
  sub-agent launch patterns, or the SDD phase DAG diagram
- **AND** the general intent (structured, phased development) MAY be retained
  in adapted prose if it adds value for Gemini users

#### Scenario: GEMINI.md is valid Markdown

- **GIVEN** the Gemini export has been generated
- **WHEN** a Markdown parser reads `GEMINI.md`
- **THEN** the file contains no malformed headings, unclosed code blocks, or
  broken links
- **AND** the file starts with a top-level heading

---

### Requirement: Cursor export produces one or more .mdc files with valid MDC frontmatter

The generated files under `.cursor/rules/` MUST use Cursor's MDC format: a
Markdown file with YAML frontmatter containing at minimum the fields
`description`, `globs`, and `alwaysApply`.

#### Scenario: at least one .mdc file is generated for a cursor export

- **GIVEN** the user has confirmed the cursor export
- **WHEN** the skill writes cursor output
- **THEN** at least one `.mdc` file exists under `.cursor/rules/`
- **AND** the file name is a valid slug (lowercase letters, digits, hyphens only)
  with the `.mdc` extension

#### Scenario: each .mdc file has valid YAML frontmatter

- **GIVEN** a `.mdc` file has been written to `.cursor/rules/`
- **WHEN** its frontmatter is parsed as YAML
- **THEN** the frontmatter contains all three required fields:
  - `description`: a non-empty string describing the rule's purpose
  - `globs`: a string or array of glob patterns (MAY be empty string `""` if
    the rule applies to all files)
  - `alwaysApply`: a boolean (`true` or `false`)
- **AND** no other frontmatter fields are required (additional fields are
  permitted but not mandated)

#### Scenario: cursor export splits output into logical domain files

- **GIVEN** the source bundle contains CLAUDE.md, conventions, stack, and
  architecture information
- **WHEN** the cursor export is generated
- **THEN** the skill produces separate `.mdc` files per logical domain rather
  than a single monolithic file
- **AND** domain split follows these guidelines (exact naming is flexible):
  - One file covering code conventions and style rules
  - One file covering tech stack and tooling
  - One file covering architecture decisions (if `architecture.md` is present)
- **AND** each domain file is independently usable — no cross-file dependencies

#### Scenario: cursor .mdc files strip Claude Code-specific orchestration content

- **GIVEN** the source bundle includes CLAUDE.md with orchestrator patterns,
  SDD phase DAG, and Task tool references
- **WHEN** cursor export files are generated
- **THEN** no `.mdc` file contains slash commands, Task tool invocations,
  sub-agent launch patterns, or the SDD phase DAG
- **AND** the `alwaysApply` field is `true` for files containing project-wide
  conventions that should always be active in Cursor

#### Scenario: cursor export with minimal source (CLAUDE.md only)

- **GIVEN** the source bundle contains only `CLAUDE.md` (no `ai-context/` files)
- **WHEN** the cursor export is generated
- **THEN** at least one `.mdc` file is produced using content from `CLAUDE.md`
- **AND** the file's `description` field acknowledges it was generated from
  CLAUDE.md only (e.g., "Generated from CLAUDE.md — ai-context/ not found")

---

### Requirement: no export target reproduces Claude Code-specific content verbatim

All three export targets share a common constraint: content that is specific to
Claude Code's runtime, tools, or orchestration model MUST NOT appear in any
exported file.

The following content categories MUST be stripped or adapted in all targets:

| Category | Examples | Required action |
|----------|----------|-----------------|
| Slash commands | `/sdd-ff`, `/project-audit`, `/skill-create` | Strip entirely |
| Task tool references | "Launch sub-agent via Task tool" | Strip entirely |
| Sub-agent delegation patterns | "subagent_type: general-purpose" | Strip entirely |
| SDD phase DAG | The `explore → propose → spec…` diagram | Strip entirely |
| install.sh / sync.sh references | "Run install.sh to deploy" | Strip entirely |
| SKILL.md registry entries | The full skills registry table | Strip entirely or summarize |
| openspec/ artifact paths | "openspec/changes/<name>/proposal.md" | Strip entirely |

#### Scenario: no exported file contains a slash command

- **GIVEN** any of the three export targets have been generated
- **WHEN** the generated file is searched for patterns matching `/<word>` at the
  start of a line or inline in imperative sentences
- **THEN** no matches are found that correspond to Claude Code meta-tool or SDD
  phase commands

---

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

*(Added in: 2026-03-04 by change "config-export-token-optimization")*

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

*(Added in: 2026-03-04 by change "config-export-token-optimization")*

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

*(Added in: 2026-03-04 by change "config-export-token-optimization")*

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

*(Added in: 2026-03-04 by change "config-export-token-optimization")*

---

## Rules

- Every `.mdc` file generated for cursor MUST have valid YAML frontmatter with
  `description`, `globs`, and `alwaysApply` fields — files missing these fields
  are non-conforming outputs
- The copilot output MUST be a single file at `.github/copilot-instructions.md`
  — splitting into multiple files is NOT permitted in V1
- The Gemini output MUST be a single file at `GEMINI.md` at the project root —
  no subdirectories
- Content stripping rules apply to ALL export targets equally — no target
  receives a verbatim copy of the source `CLAUDE.md`
- The skill MUST NOT guess at Cursor's `globs` pattern — if no meaningful glob
  can be inferred from a domain, MUST use `""` (applies to all files) rather
  than an incorrect pattern
- Output file encoding MUST be UTF-8; no BOM
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
