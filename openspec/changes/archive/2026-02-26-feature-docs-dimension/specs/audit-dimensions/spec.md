# Delta Spec: audit-dimensions

Change: feature-docs-dimension
Date: 2026-02-26
Base: openspec/specs/audit-dimensions/spec.md

---

## ADDED — New requirements

### Requirement: Dimension 10 (Feature Docs Coverage) is present in project-audit

`project-audit/SKILL.md` MUST contain a Dimension 10 section that evaluates feature-level documentation coverage. Dimension 10 MUST run after Dimension 9 and MUST follow the detection logic defined below.

#### Scenario: SKILL.md contains a Dimension 10 section

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the file from top to bottom
- **THEN** there is a section heading "Dimension 10" or "Feature Docs Coverage" after the Dimension 9 section
- **AND** the section documents four sub-checks: D10-a (Coverage), D10-b (Structural Quality), D10-c (Code Freshness), D10-d (Registry Alignment)
- **AND** each sub-check has explicit pass/fail criteria documented

---

### Requirement: D10 detection phase — configured path

When `feature_docs` is present in `openspec/config.yaml`, D10 MUST use the declared convention, paths, and feature detection strategy to enumerate features.

#### Scenario: D10 uses configured feature_docs when present

- **GIVEN** the target project has an `openspec/config.yaml` containing a `feature_docs` section with `convention`, `paths`, and `feature_detection` keys
- **WHEN** `/project-audit` is run on that project
- **THEN** D10 enumerates features using the paths and strategy declared in `feature_docs`
- **AND** D10 does NOT fall back to heuristic detection
- **AND** the D10 coverage table in the report lists only features identified via the declared configuration

#### Scenario: D10 uses configured paths to find feature docs

- **GIVEN** `feature_docs.paths` in `openspec/config.yaml` lists `docs/features/` and `.claude/skills/`
- **WHEN** `/project-audit` runs D10
- **THEN** D10 searches for documentation files only within those declared paths
- **AND** it does not scan directories that are not listed in `feature_docs.paths`

---

### Requirement: D10 detection phase — heuristic fallback

When `feature_docs` is absent from `openspec/config.yaml`, D10 MUST fall back to heuristic detection to discover features.

#### Scenario: D10 runs heuristic detection when feature_docs is absent

- **GIVEN** the target project has `openspec/config.yaml` but no `feature_docs` section (or no `openspec/config.yaml` at all)
- **WHEN** `/project-audit` is run
- **THEN** D10 applies the heuristic detection strategy, scanning the following locations in order:
  1. Non-SDD skills in `.claude/skills/` (skills whose names do not start with `sdd-`, `project-`, `memory-`, or `skill-`)
  2. Markdown files directly in `docs/features/` or `docs/modules/` (if those directories exist)
  3. Subdirectories of `src/features/`, `src/modules/`, or `app/` that contain their own `README.md`
- **AND** directories named `shared`, `utils`, `common`, or `lib` are excluded from heuristic detection even if they contain a `README.md`

#### Scenario: D10 emits INFO and skips checks when no features are detected

- **GIVEN** the target project has no `feature_docs` configured AND heuristic detection finds zero features
- **WHEN** `/project-audit` runs D10
- **THEN** the D10 section in the report contains exactly one line: "No feature docs detected — D10 skipped"
- **AND** no coverage table is emitted for D10
- **AND** no D10 findings of any severity are added to the FIX_MANIFEST

---

### Requirement: D10-a Coverage check

For each detected feature, D10 MUST verify that a corresponding documentation artifact (SKILL.md or markdown file) exists.

#### Scenario: Feature with a corresponding doc passes D10-a

- **GIVEN** a feature named "audio-player" is detected
- **AND** a documentation artifact exists at `.claude/skills/audio-player/SKILL.md` or `docs/features/audio-player.md`
- **WHEN** D10 runs the coverage check
- **THEN** the "audio-player" row in the D10 coverage table shows ✅ for the Coverage column

#### Scenario: Feature without a corresponding doc fails D10-a

- **GIVEN** a feature named "audio-player" is detected (e.g., as a subdirectory of `src/features/`)
- **AND** no documentation artifact exists at any of the configured or heuristically determined doc paths
- **WHEN** D10 runs the coverage check
- **THEN** the "audio-player" row in the D10 coverage table shows ❌ for the Coverage column

---

### Requirement: D10-b Structural Quality check

For each detected feature with a documentation artifact, D10 MUST verify that the artifact meets minimum structural quality standards.

#### Scenario: SKILL.md doc passes D10-b when it has required sections

- **GIVEN** a feature's documentation artifact is a `SKILL.md` file
- **WHEN** D10 runs the structural quality check
- **THEN** the check passes (✅) if and only if the file contains ALL of the following:
  - A valid YAML frontmatter block (delimited by `---`)
  - A triggers line (containing "Triggers:" or similar)
  - A process section (an H2 or H3 heading containing "Process" or "Steps")
  - A rules section (an H2 or H3 heading containing "Rules")
- **AND** the check fails (❌) if any of those sections is absent

#### Scenario: Markdown doc passes D10-b when it has H1 and at least one H2

- **GIVEN** a feature's documentation artifact is a `.md` file (not a SKILL.md)
- **WHEN** D10 runs the structural quality check
- **THEN** the check passes (✅) if and only if the file has an H1 title (`# ...`) and at least one H2 section (`## ...`)
- **AND** the check fails (❌) if either the H1 or all H2 sections are absent

#### Scenario: Feature without a doc shows ⚠️ for D10-b

- **GIVEN** a feature has no documentation artifact (D10-a is ❌)
- **WHEN** D10 evaluates D10-b for that feature
- **THEN** the Coverage column shows ❌ and the Structural Quality column shows ⚠️ (not applicable — doc missing)

---

### Requirement: D10-c Code Freshness check

For each detected feature with a documentation artifact, D10 MUST verify that file paths referenced in the doc still exist on disk.

#### Scenario: Doc with all referenced paths present passes D10-c

- **GIVEN** a documentation artifact references inline paths matching patterns `/src/`, `/lib/`, or `/app/` (e.g., `src/features/audio-player/index.ts`)
- **AND** all such referenced paths exist on disk
- **WHEN** D10 runs the code freshness check
- **THEN** the Code Freshness column for that feature shows ✅

#### Scenario: Doc with at least one stale path fails D10-c

- **GIVEN** a documentation artifact references a path that no longer exists on disk (e.g., `src/features/audio-player/legacy.ts` was deleted)
- **WHEN** D10 runs the code freshness check
- **THEN** the Code Freshness column for that feature shows ❌
- **AND** the specific stale path is noted in the D10 findings section of the report

#### Scenario: Doc with no inline paths passes D10-c trivially

- **GIVEN** a documentation artifact contains no inline paths matching `/src/`, `/lib/`, or `/app/`
- **WHEN** D10 runs the code freshness check
- **THEN** the Code Freshness column for that feature shows ✅ (no stale references detected)

---

### Requirement: D10-d Registry Alignment check

For each detected feature skill, D10 MUST verify that the skill is listed in the target project's `CLAUDE.md` Skills Registry.

#### Scenario: Feature skill listed in CLAUDE.md passes D10-d

- **GIVEN** a feature named "audio-player" has a `SKILL.md` at `.claude/skills/audio-player/`
- **AND** the project's `CLAUDE.md` contains a Skills Registry section that references `audio-player`
- **WHEN** D10 runs the registry alignment check
- **THEN** the Registry Alignment column for "audio-player" shows ✅

#### Scenario: Feature skill NOT listed in CLAUDE.md fails D10-d

- **GIVEN** a feature named "audio-player" has a `SKILL.md` at `.claude/skills/audio-player/`
- **AND** the project's `CLAUDE.md` does NOT mention `audio-player` in any Skills Registry section
- **WHEN** D10 runs the registry alignment check
- **THEN** the Registry Alignment column for "audio-player" shows ❌

#### Scenario: Markdown-only feature docs are not subject to D10-d

- **GIVEN** a feature's documentation artifact is a plain markdown file (not a `SKILL.md`)
- **WHEN** D10 evaluates D10-d for that feature
- **THEN** the Registry Alignment column shows ⚠️ (N/A — not a skill)
- **AND** no finding is emitted for missing registry entry for that feature

---

### Requirement: D10 coverage table appears in audit-report.md

After running `/project-audit` on a project where D10 detects at least one feature, the `audit-report.md` MUST contain a D10 coverage table.

#### Scenario: Coverage table format when features are detected

- **GIVEN** D10 has detected at least one feature
- **WHEN** the audit report is written
- **THEN** the D10 section in `audit-report.md` contains a markdown table with at minimum the following columns:
  - Feature
  - Coverage (D10-a)
  - Structural Quality (D10-b)
  - Code Freshness (D10-c)
  - Registry Alignment (D10-d)
- **AND** each row corresponds to one detected feature
- **AND** each cell in the check columns contains exactly one of: ✅, ⚠️, or ❌

#### Scenario: D10 section appears after the D9 section in the report

- **GIVEN** the full `audit-report.md` is produced
- **WHEN** the report is read top to bottom
- **THEN** the D10 section appears after the D9 section
- **AND** the D10 section precedes the score table

---

### Requirement: D10 findings never appear in FIX_MANIFEST required_actions

D10 MUST NOT generate FIX_MANIFEST entries that would cause `/project-fix` to create or repair feature documentation.

#### Scenario: FIX_MANIFEST contains no D10 entries

- **GIVEN** D10 has detected features with ❌ findings (e.g., missing coverage, stale paths)
- **WHEN** the FIX_MANIFEST in `audit-report.md` is read
- **THEN** `required_actions.critical`, `required_actions.high`, and `required_actions.medium` contain no entries referencing D10 findings
- **AND** any D10 findings that are surfaced appear only in the informational/LOW section of the report (if that section exists) or inline in the D10 table
- **AND** a note in the D10 section states that fixing feature documentation gaps is a human decision

---

## Rules

- D10 describes OBSERVABLE BEHAVIOR only — the format of the coverage table and report output are the verifiable criteria
- D10 scenarios that reference heuristic detection are non-negotiable for projects without `feature_docs` configured
- The exclusion list (`shared`, `utils`, `common`, `lib`) is part of the observable specification — a change to that list is a spec change, not just an implementation detail
- All ❌ findings from D10 are informational — none of them are blocking or score-affecting
