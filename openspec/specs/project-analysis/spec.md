# Spec: project-analysis

Change: improve-project-analysis
Date: 2026-02-27

## Overview

This spec covers the observable behavior introduced by the `improve-project-analysis` change. It spans three areas:

1. **New skill: `project-analyze`** — standalone, framework-agnostic codebase analysis
2. **`analysis-report.md` format and `[auto-updated]` section markers** — the file-based handoff artifact
3. **Delta on `project-audit`** — D7 rewritten to read `analysis-report.md`; orchestration sequence formalized

Related base specs (modified by this change):
- `openspec/specs/audit-dimensions/spec.md` — D7 behavior modified
- `openspec/specs/audit-execution/spec.md` — orchestration sequence added

---

## Part 1 — New Skill: `project-analyze`

### Requirement: `project-analyze` skill exists with a valid SKILL.md

A directory `skills/project-analyze/` MUST exist in the repository with exactly one entry point file `SKILL.md`. The SKILL.md MUST contain a Trigger definition, a Process section with numbered steps, a Rules section, and an Output format section.

#### Scenario: Skill directory and entry point are present after install

- **GIVEN** `install.sh` has been run after this change is applied
- **WHEN** the filesystem is inspected at `~/.claude/skills/project-analyze/`
- **THEN** the directory exists
- **AND** `~/.claude/skills/project-analyze/SKILL.md` exists and is readable
- **AND** the file contains non-empty Trigger, Process, Rules, and Output sections

#### Scenario: SKILL.md trigger matches canonical command name

- **GIVEN** the SKILL.md for `project-analyze` is read
- **WHEN** the Trigger section is examined
- **THEN** the trigger includes `/project-analyze` as the primary invocation pattern
- **AND** the description states the skill observes and describes — never scores, never produces FIX_MANIFEST entries

---

### Requirement: `project-analyze` performs five structured analysis steps

When invoked, `project-analyze` MUST execute five steps in order: structure mapping, stack detection, convention sampling, architecture drift detection, and `ai-context/` update. Each step MUST produce a named section in `analysis-report.md`.

#### Scenario: Structure mapping step produces folder organization section

- **GIVEN** `/project-analyze` is invoked on a project with any folder layout
- **WHEN** the structure mapping step runs
- **THEN** `analysis-report.md` contains a section titled "Structure" (or equivalent)
- **AND** that section identifies the organizational pattern observed (feature-based, layer-based, monorepo, flat, or other)
- **AND** the section lists the top-level directories and their inferred purpose

#### Scenario: Stack detection step produces technology section

- **GIVEN** `/project-analyze` is invoked on a project
- **WHEN** the stack detection step runs
- **THEN** `analysis-report.md` contains a section titled "Stack" (or equivalent)
- **AND** if a manifest file is present (`package.json`, `requirements.txt`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `mix.exs`), the section lists the primary runtime, framework, and key dependencies extracted from that manifest
- **AND** if no manifest is present, the section lists the detected file extensions and inferred technologies
- **AND** the section does NOT hardcode any framework-specific assumptions — it reflects only what is observed

#### Scenario: Stack detection on a project with no manifest file

- **GIVEN** `/project-analyze` is invoked on a project with no recognized manifest file (e.g., a pure Markdown documentation repository)
- **WHEN** the stack detection step runs
- **THEN** `analysis-report.md` "Stack" section states that no manifest was found
- **AND** it lists the most common file extensions found in the repository as the inferred stack signal
- **AND** the step does NOT error out or produce an empty section

#### Scenario: Convention sampling step produces patterns section

- **GIVEN** `/project-analyze` is invoked on a project with source files
- **WHEN** the convention sampling step runs
- **THEN** `analysis-report.md` contains a section titled "Conventions" (or equivalent)
- **AND** that section documents observed naming patterns for files, functions, or classes (e.g., kebab-case files, PascalCase components, snake_case functions)
- **AND** the sample size used (number of files read) is stated in the section
- **AND** the section explicitly states which directories were sampled

#### Scenario: Convention sampling respects configurable sample size

- **GIVEN** `openspec/config.yaml` exists and contains an `analysis_targets` key with explicit source paths
- **WHEN** the convention sampling step runs
- **THEN** sampling is restricted to the declared paths
- **AND** the number of files read does not exceed the declared limit (or the default of 20 if no limit is declared)

#### Scenario: Convention sampling falls back when no config is present

- **GIVEN** `openspec/config.yaml` is absent OR does not contain an `analysis_targets` key
- **WHEN** the convention sampling step runs
- **THEN** the skill auto-detects source directories (directories with the most source files of the detected stack type)
- **AND** samples up to 20 files across those directories
- **AND** the "Conventions" section in `analysis-report.md` notes that auto-detection was used

#### Scenario: Architecture drift detection step produces drift section

- **GIVEN** `/project-analyze` is invoked on a project that has `ai-context/architecture.md`
- **WHEN** the architecture drift detection step runs
- **THEN** `analysis-report.md` contains a section titled "Architecture Drift" (or equivalent)
- **AND** that section lists each discrepancy found between what `architecture.md` documents and what the actual folder/file structure contains
- **AND** each entry is labeled as "Drift" (documented but not observed) or "Undocumented" (observed but not documented)
- **AND** no drift entry is labeled as a failure, error, or score deduction — they are informational observations only

#### Scenario: Architecture drift detection when `ai-context/architecture.md` is absent

- **GIVEN** `/project-analyze` is invoked on a project with no `ai-context/architecture.md`
- **WHEN** the architecture drift detection step runs
- **THEN** `analysis-report.md` "Architecture Drift" section states that no baseline architecture document was found
- **AND** the section does NOT produce any drift entries
- **AND** the skill proceeds to the next step without error

#### Scenario: Architecture drift entries are informational, not scored

- **GIVEN** `/project-analyze` has detected drift between documented architecture and observed structure
- **WHEN** the `analysis-report.md` is read by any consuming skill or human
- **THEN** no drift entry contains a numeric score, severity level (CRITICAL/HIGH/MEDIUM/LOW), or FIX_MANIFEST reference
- **AND** the report section uses neutral language (e.g., "Observed:", "Documented:", "Difference:")

---

### Requirement: `project-analyze` MUST NOT score or produce FIX_MANIFEST entries

`project-analyze` is a pure observation skill. It MUST NOT produce any scoring output, severity classifications, or FIX_MANIFEST YAML blocks. This boundary is absolute.

#### Scenario: `analysis-report.md` contains no scoring or FIX_MANIFEST content

- **GIVEN** `/project-analyze` has completed a run
- **WHEN** the full `analysis-report.md` is read
- **THEN** the file contains no numeric score values (e.g., "Score: 75/100")
- **AND** the file contains no `FIX_MANIFEST` YAML block or equivalent structured action list
- **AND** the file contains no severity labels (CRITICAL, HIGH, MEDIUM, LOW) used in a pass/fail context
- **AND** the file contains no instructions directed at `project-fix`

---

### Requirement: `project-analyze` updates `ai-context/` using append/update strategy

After analysis, `project-analyze` MUST update `stack.md`, `architecture.md`, and `conventions.md` in the project's `ai-context/` directory. It MUST overwrite only sections marked `[auto-updated]` and MUST leave all other sections intact.

#### Scenario: `[auto-updated]` sections are overwritten with fresh observations

- **GIVEN** `ai-context/stack.md` contains a section marked `[auto-updated]`
- **WHEN** `/project-analyze` completes
- **THEN** that section in `ai-context/stack.md` is replaced with current observations
- **AND** the replacement content reflects the actual stack detected in the current run
- **AND** a `Last analyzed:` date is written or updated at the top of each modified file

#### Scenario: Human-edited sections without `[auto-updated]` marker are preserved

- **GIVEN** `ai-context/architecture.md` contains a section with manually written architectural decisions (no `[auto-updated]` marker)
- **WHEN** `/project-analyze` completes
- **THEN** that section is unchanged in content and formatting
- **AND** no content from that section is removed or replaced

#### Scenario: First run creates `[auto-updated]` sections when `ai-context/` files are absent

- **GIVEN** the target project has no `ai-context/` directory (or has empty files)
- **WHEN** `/project-analyze` runs
- **THEN** it creates `ai-context/stack.md`, `ai-context/architecture.md`, and `ai-context/conventions.md` if they do not exist
- **AND** all content it writes is wrapped in `[auto-updated]` section markers
- **AND** a `Last analyzed:` date is written at the top of each file

#### Scenario: `known-issues.md` and `changelog-ai.md` are not modified

- **GIVEN** `/project-analyze` runs on any project
- **WHEN** the run completes
- **THEN** `ai-context/known-issues.md` is not modified
- **AND** `ai-context/changelog-ai.md` is not modified
- **AND** only `stack.md`, `architecture.md`, and `conventions.md` are candidates for update

---

### Requirement: `project-analyze` produces `analysis-report.md` in the project root

The output artifact MUST be saved as `analysis-report.md` in the project root (same directory as `audit-report.md`).

#### Scenario: `analysis-report.md` is created at the expected path

- **GIVEN** `/project-analyze` is invoked on a project at path `/projects/myapp`
- **WHEN** the run completes
- **THEN** the file `/projects/myapp/analysis-report.md` exists
- **AND** it contains all five structured sections (Structure, Stack, Conventions, Architecture Drift, Summary)

#### Scenario: Subsequent runs overwrite the previous `analysis-report.md`

- **GIVEN** `/project-analyze` was run previously and `analysis-report.md` exists
- **WHEN** `/project-analyze` is run again
- **THEN** `analysis-report.md` is overwritten with the new run's output
- **AND** the `Last analyzed:` date in the report reflects the current run's date

---

## Part 2 — `analysis-report.md` Format and `[auto-updated]` Markers

### Requirement: `analysis-report.md` has a defined, stable structure

`analysis-report.md` MUST follow a defined section structure so that consuming skills (specifically `project-audit` D7) can reliably parse its content.

#### Scenario: `analysis-report.md` contains all required top-level sections

- **GIVEN** `/project-analyze` has completed a run
- **WHEN** `analysis-report.md` is read
- **THEN** it contains the following sections in order:
  1. A summary block at the top (project name, date analyzed, stack summary, organization pattern, drift count)
  2. "Structure" section
  3. "Stack" section
  4. "Conventions" section
  5. "Architecture Drift" section
- **AND** each section is preceded by a level-2 markdown heading (`##`)

#### Scenario: Summary block contains machine-readable metadata

- **GIVEN** `analysis-report.md` exists
- **WHEN** the summary block is read
- **THEN** it contains at minimum:
  - `Last analyzed:` field with an ISO date (YYYY-MM-DD)
  - `Stack:` field with a one-line summary of detected technologies
  - `Organization:` field stating the detected folder organization pattern
  - `Drift entries:` field with a numeric count of architecture drift observations
- **AND** this metadata is formatted consistently so a skill can read specific values without ambiguous parsing

---

### Requirement: `[auto-updated]` section markers define overwrite boundaries in `ai-context/`

Sections in `ai-context/` files that were written by `project-analyze` MUST be clearly delimited so the skill can identify and overwrite them on subsequent runs without touching human-written content.

#### Scenario: `[auto-updated]` marker format is consistent

- **GIVEN** `project-analyze` has written to `ai-context/stack.md`
- **WHEN** the file is read
- **THEN** each auto-updated section begins with a line containing `<!-- [auto-updated] start: <section-name> -->`
- **AND** ends with a line containing `<!-- [auto-updated] end: <section-name> -->`
- **AND** the section name is a stable identifier (e.g., `detected-stack`, `observed-structure`) that does not change between runs

#### Scenario: Content outside `[auto-updated]` markers is never modified

- **GIVEN** `ai-context/architecture.md` has human-written content both before and after an `[auto-updated]` section
- **WHEN** `/project-analyze` runs and updates the `[auto-updated]` section
- **THEN** only the content between the markers is replaced
- **AND** all content before the opening marker and after the closing marker is byte-for-byte identical to the pre-run state

---

## Part 3 — Delta on `project-audit`: D7 and Orchestration

### Requirement: D7 — Architecture Compliance reads `analysis-report.md` instead of sampling source files

*This is a MODIFIED requirement relative to the current D7 behavior.*

D7 MUST read the "Architecture Drift" section of `analysis-report.md` as its primary source of architecture compliance information. D7 MUST NOT issue Bash calls to sample source files directly.

*(Before: D7 sampled 3 API routes, 3 domain services, and 2 components using hardcoded Next.js/Prisma patterns.)*

#### Scenario: D7 reads `analysis-report.md` when the file is present

- **GIVEN** `analysis-report.md` exists in the project root at the time `project-audit` runs
- **WHEN** D7 executes
- **THEN** D7 reads the "Architecture Drift" section of `analysis-report.md` using the Read tool
- **AND** D7 does NOT issue any Bash call to sample source code files
- **AND** D7 uses the drift count from `analysis-report.md` to determine its score: zero drift entries = full score; one or more drift entries = partial score

#### Scenario: D7 emits a clear failure with instruction when `analysis-report.md` is absent

- **GIVEN** `analysis-report.md` does NOT exist in the project root
- **WHEN** D7 executes during a `project-audit` run
- **THEN** D7 receives a score of 0
- **AND** the D7 section of `audit-report.md` contains an explicit message stating that `analysis-report.md` was not found
- **AND** the message instructs the user to run `/project-analyze` first and then re-run `/project-audit`
- **AND** no source code files are sampled as a fallback

#### Scenario: D7 on a framework-agnostic project produces a meaningful score

- **GIVEN** a project that uses Django, Spring Boot, Elixir Phoenix, or any non-Next.js framework
- **AND** `analysis-report.md` was produced by `/project-analyze` on that project
- **WHEN** `/project-audit` is run
- **THEN** D7 produces a score based on the drift entries in `analysis-report.md` without reference to Next.js- or Prisma-specific patterns
- **AND** the D7 finding in `audit-report.md` reflects the actual architecture state of the project, not a hardcoded expectation

#### Scenario: D7 FIX_MANIFEST entry when drift is present

- **GIVEN** `analysis-report.md` reports one or more drift entries
- **WHEN** D7 produces its findings
- **THEN** the FIX_MANIFEST entry for D7 references the specific drift entries from `analysis-report.md`
- **AND** the FIX_MANIFEST action instructs the user to either update `ai-context/architecture.md` to reflect reality or reconcile the code with the documented architecture
- **AND** the action does NOT prescribe implementation-specific code changes

---

### Requirement: `project-audit` documents its orchestration sequence

`project-audit/SKILL.md` MUST document that it operates in two phases, with `project-analyze` as a named prerequisite step for D7.

#### Scenario: SKILL.md Phase A includes `project-analyze` as a prerequisite

- **GIVEN** `skills/project-audit/SKILL.md` is read
- **WHEN** the Phase A section is examined
- **THEN** the section states that `analysis-report.md` is consumed in Phase B (D7)
- **AND** the section states that if `analysis-report.md` is absent, D7 will score 0
- **AND** the section does NOT instruct `project-audit` to automatically invoke `project-analyze` — it treats the report as an external input

#### Scenario: `project-audit` does NOT automatically invoke `project-analyze`

- **GIVEN** `analysis-report.md` is absent when `project-audit` is run
- **WHEN** `project-audit` executes
- **THEN** `project-audit` does NOT spawn a sub-agent or call `project-analyze` internally
- **AND** it proceeds with D7 scored at 0 and emits the instruction message
- **AND** total Bash call count for the audit run remains within the existing limit (≤ 3)

---

## Part 4 — Registry and Documentation Updates

### Requirement: `project-analyze` is registered in `CLAUDE.md` and the Skills Registry

After this change, both the global `CLAUDE.md` and the project's `CLAUDE.md` MUST list `project-analyze` as a meta-tool command.

#### Scenario: `project-analyze` appears in the Meta-tools command table

- **GIVEN** `CLAUDE.md` is read
- **WHEN** the Meta-tools command table is examined
- **THEN** a row for `/project-analyze` is present with a description that includes "deep framework-agnostic codebase analysis"
- **AND** the row is placed adjacent to related meta-tools (e.g., near `/project-audit` or `/memory-init`)

#### Scenario: `project-analyze` appears in the Skills Registry section

- **GIVEN** `CLAUDE.md` is read
- **WHEN** the Skills Registry section is examined
- **THEN** `~/.claude/skills/project-analyze/SKILL.md` is listed
- **AND** the entry describes it as a standalone analysis skill that observes and describes, separate from audit

#### Scenario: `CLAUDE.md` maps `/project-analyze` to its skill file

- **GIVEN** the "How I Execute Commands" table in `CLAUDE.md` is read
- **WHEN** the row for `/project-analyze` is examined
- **THEN** the skill path is `~/.claude/skills/project-analyze/SKILL.md`

---

### Requirement: `ai-context/architecture.md` artifact table includes `analysis-report.md`

The artifact table in `ai-context/architecture.md` MUST include a row for `analysis-report.md`.

#### Scenario: `analysis-report.md` row exists in artifact table

- **GIVEN** `ai-context/architecture.md` is read
- **WHEN** the "Communication between skills via artifacts" table is examined
- **THEN** a row for `analysis-report.md` is present with:
  - Producer: `project-analyze`
  - Consumer: `project-audit` (D7), user
  - Location: project root

---

## Out of Scope

The following behaviors are explicitly NOT covered by this spec and MUST NOT be implemented as part of this change:

1. **`project-analyze` scoring output** — The skill produces no score, no severity labels, no FIX_MANIFEST blocks. Any scoring derived from analysis is the responsibility of `project-audit` alone.
2. **Automatic invocation of `project-analyze` by `project-audit`** — `project-audit` reads `analysis-report.md` as an external input. It does not call `project-analyze` as a sub-step. The user is responsible for running `project-analyze` before `project-audit` when a fresh analysis is needed.
3. **Exhaustive convention linting** — `project-analyze` describes observed patterns using sampling (default ≤ 20 files). It does not diff `conventions.md` line by line or perform exhaustive compliance checking across all source files.
4. **Changes to `project-fix`** — The FIX_MANIFEST format and `project-fix` logic are unchanged in this cycle.
5. **Changes to `memory-manager`** — `memory-init` and `memory-update` are unchanged. `project-analyze` complements `memory-manager` but does not replace it.
6. **SDD sub-agent context injection** — Adding explicit `ai-context/` reading instructions to the sub-agent launch pattern is deferred to a follow-on change.
7. **D9 (local skill quality) and D10 (feature docs coverage) extraction** — These remain embedded in `project-audit` for this cycle.
8. **`project-analyze` replacing `memory-init`** — On a project with no `ai-context/` at all, `memory-init` remains the recommended first-time initializer. `project-analyze` is designed for re-analysis of established projects, though it will create files if they are absent.

---

## Risks and Ambiguities

| Risk | Classification | Notes |
|------|----------------|-------|
| D7 scoring formula (zero drift = full score, any drift = partial) — exact deduction per drift entry is not defined in this spec | **[Pending clarification]** | Design phase must define the scoring formula. This spec only requires that the score is driven by drift count, not source code sampling. |
| `analysis-report.md` freshness threshold — proposal states 7-day warning, but the exact behavior (warning vs. score deduction) is not specified | **[Pending clarification]** | Design phase should decide: does `project-audit` warn only, or deduct from D7 score when report is stale? |
| `[auto-updated]` marker format — HTML comment markers are specified here; design phase must confirm this does not conflict with any existing `ai-context/` file content | Low risk — HTML comments are invisible in rendered Markdown and unlikely to collide with existing content |
| `project-analyze` context window on large repos — sample ceiling of 20 files is a mitigation, but very large monorepos may still require additional guardrails | Medium risk — design should specify behavior when the detected source directories contain thousands of files |

---

## Rules

- All MUST requirements in this spec are non-negotiable for this change to be considered complete
- SHOULD requirements may have documented exceptions
- Out-of-scope items listed above MUST NOT be implemented as part of this change
- Scenarios are the verification criteria for `verify-report.md`
