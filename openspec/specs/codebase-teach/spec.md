# Spec: codebase-teach

Change: 2026-03-10-codebase-teach-skill
Date: 2026-03-10

---

## Requirements

### Requirement: Skill entry point must exist and be structurally valid

The `codebase-teach` skill MUST be a directory `skills/codebase-teach/` containing exactly one
`SKILL.md` file. The SKILL.md MUST declare `format: procedural` in its YAML frontmatter, MUST
include the `**Triggers**` section, MUST include a `## Process` section with numbered steps, and
MUST include a `## Rules` section.

#### Scenario: Skill directory and SKILL.md are present and valid

- **GIVEN** the repo has been updated with the `codebase-teach` skill
- **WHEN** `skills/codebase-teach/SKILL.md` is read
- **THEN** the file MUST contain a YAML frontmatter block with `format: procedural`
- **AND** the file MUST contain a `**Triggers**` or `## Triggers` section
- **AND** the file MUST contain a `## Process` section
- **AND** the file MUST contain a `## Rules` section

#### Scenario: project-audit D4b finds no structural violation

- **GIVEN** the skill is installed via `install.sh`
- **WHEN** `/project-audit` is run on the `agent-config` repo
- **THEN** the audit score MUST NOT decrease relative to the pre-change score
- **AND** no `MEDIUM` or `HIGH` finding for `codebase-teach` MUST appear in `audit-report.md`

---

### Requirement: Skill is registered in CLAUDE.md

The `codebase-teach` skill MUST appear in the `## Skills Registry` section of `CLAUDE.md` with a
path entry and a one-line description. It MUST also appear in the `## Available Commands` section
as `/codebase-teach`.

#### Scenario: CLAUDE.md lists the skill in the registry

- **GIVEN** the CLAUDE.md has been updated
- **WHEN** the `## Skills Registry` section is read
- **THEN** it MUST contain a line referencing `~/.claude/skills/codebase-teach/SKILL.md`
- **AND** the line MUST include a description of what the skill does

#### Scenario: CLAUDE.md lists the command in Available Commands

- **GIVEN** the CLAUDE.md has been updated
- **WHEN** the `## Available Commands` section is read
- **THEN** it MUST contain a row with `/codebase-teach` and a description of its action

---

### Requirement: Skill scans bounded contexts from the project directory structure

When invoked, the `codebase-teach` skill MUST scan the project's directory structure to identify
bounded context candidates. A bounded context candidate is any feature directory, domain module, or
service layer visible in the source tree. The skill MUST cross-reference discovered contexts against
existing `ai-context/features/` files.

#### Scenario: Project has feature directories

- **GIVEN** a project with directories such as `features/`, `src/`, or `domain/` at a known depth
- **WHEN** `/codebase-teach` is invoked
- **THEN** the skill MUST enumerate directories that appear to be bounded context candidates
- **AND** each candidate MUST be listed in the output (exploration log or `teach-report.md`)

#### Scenario: Project has no recognizable feature directories

- **GIVEN** a project with a flat structure and no feature-style subdirectories
- **WHEN** `/codebase-teach` is invoked
- **THEN** the skill MUST still complete without error
- **AND** the `teach-report.md` MUST note "No bounded context directories detected" with a suggestion to run `/memory-init` first

#### Scenario: `ai-context/features/` does not exist

- **GIVEN** a project where `ai-context/features/` is absent
- **WHEN** `/codebase-teach` is invoked
- **THEN** the skill MUST note the absence and continue
- **AND** the teach-report MUST recommend running `/memory-init` before re-running `/codebase-teach`

---

### Requirement: Skill reads key implementation files per bounded context

For each detected bounded context, the `codebase-teach` skill MUST read up to a configurable
maximum of key implementation files (services, models, handlers, controllers). The default maximum
is **10 files per context**. The skill MUST process contexts **sequentially** to stay within
context window limits.

#### Scenario: Bounded context has more than 10 key files

- **GIVEN** a bounded context with 25 implementation files
- **WHEN** the skill reads that context
- **THEN** it MUST read at most 10 files (by default)
- **AND** the `teach-report.md` MUST note how many files were sampled vs. total found

#### Scenario: Bounded context has fewer than 10 key files

- **GIVEN** a bounded context with 4 implementation files
- **WHEN** the skill reads that context
- **THEN** it MUST read all 4 files
- **AND** no truncation notice MUST appear in the report for this context

#### Scenario: A file in the context is unreadable

- **GIVEN** a bounded context with a file that cannot be read (binary, permission error)
- **WHEN** the skill encounters that file
- **THEN** it MUST skip that file and continue with the remaining files
- **AND** the skipped file MUST be listed in the `teach-report.md` under a "Skipped files" section

---

### Requirement: Skill writes or updates `ai-context/features/<context>.md`

For each bounded context analyzed, the skill MUST produce or update an
`ai-context/features/<context>.md` file. The file MUST follow the six-section format defined in
`ai-context/features/_template.md`: Domain Overview, Business Rules and Invariants, Data Model
Summary, Integration Points, Decision Log, Known Gotchas. All AI-generated sections MUST be marked
with an `[auto-updated]` marker.

#### Scenario: Feature file does not yet exist

- **GIVEN** a bounded context `payments` with no `ai-context/features/payments.md`
- **WHEN** the skill completes analysis for that context
- **THEN** a new file `ai-context/features/payments.md` MUST be written
- **AND** it MUST contain all six required sections
- **AND** AI-generated sections MUST carry the `[auto-updated]` marker

#### Scenario: Feature file already exists

- **GIVEN** a bounded context `auth` with an existing `ai-context/features/auth.md`
- **WHEN** the skill completes analysis for that context
- **THEN** the existing file MUST be updated, not replaced wholesale
- **AND** sections marked `[auto-updated]` MAY be overwritten
- **AND** sections NOT marked `[auto-updated]` (human-authored) MUST NOT be overwritten

#### Scenario: Feature file has `_template.md` name

- **GIVEN** the skill is scanning `ai-context/features/`
- **WHEN** it encounters `_template.md`
- **THEN** it MUST skip that file entirely — it MUST NOT be overwritten or treated as a feature context

---

### Requirement: Skill evaluates documentation coverage and writes `teach-report.md`

After analyzing all bounded contexts, the skill MUST produce a `teach-report.md` file in the
project's working directory. The report MUST include: coverage percentage (documented contexts /
total detected contexts), gap list (contexts found in code but not in `ai-context/features/`),
list of files read per context, and list of sections written or updated.

#### Scenario: All detected contexts have feature files

- **GIVEN** a project with 3 bounded contexts, all documented in `ai-context/features/`
- **WHEN** the skill completes
- **THEN** the `teach-report.md` MUST show coverage at 100%
- **AND** the gap list MUST be empty

#### Scenario: Some contexts have no feature files

- **GIVEN** a project with 5 bounded contexts, 2 documented and 3 missing
- **WHEN** the skill completes
- **THEN** the `teach-report.md` MUST show coverage at 40% (2 / 5)
- **AND** the gap list MUST name the 3 undocumented contexts

#### Scenario: `teach-report.md` structure

- **GIVEN** any successful run
- **WHEN** `teach-report.md` is read
- **THEN** it MUST contain at minimum: a coverage percentage line, a "Gaps" section listing undocumented contexts, a "Files read" section (per context), and a "Sections written/updated" section

---

### Requirement: Skill boundary — must not modify other ai-context files

The `codebase-teach` skill MUST only write to `ai-context/features/<context>.md` and produce
`teach-report.md`. It MUST NOT modify `ai-context/stack.md`, `ai-context/architecture.md`,
`ai-context/conventions.md`, `ai-context/known-issues.md`, `ai-context/changelog-ai.md`, or any
SDD artifact (`openspec/`, `docs/`).

#### Scenario: Skill completes without touching core ai-context files

- **GIVEN** a successful `/codebase-teach` run
- **WHEN** the working tree is inspected afterward
- **THEN** `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`,
  `ai-context/known-issues.md`, and `ai-context/changelog-ai.md` MUST be unmodified
- **AND** no `openspec/` files MUST have been written or changed

---

### Requirement: Skill is manual-only — no automatic invocation

The `codebase-teach` skill MUST NOT be invoked automatically by any other skill (including
`memory-init`, `memory-update`, `project-analyze`, or any SDD phase skill). It is a
user-initiated command only.

#### Scenario: Running `/memory-init` does not trigger `/codebase-teach`

- **GIVEN** a project with no `ai-context/features/` scaffold
- **WHEN** `/memory-init` runs
- **THEN** `codebase-teach` MUST NOT be invoked
- **AND** no `teach-report.md` MUST be produced

#### Scenario: Running `/sdd-apply` does not trigger `/codebase-teach`

- **GIVEN** any SDD apply phase
- **WHEN** `sdd-apply` processes tasks
- **THEN** it MUST NOT load or invoke `codebase-teach`
