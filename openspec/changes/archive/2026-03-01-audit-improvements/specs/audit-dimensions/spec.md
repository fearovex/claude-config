# Delta Spec: audit-dimensions

Change: audit-improvements
Date: 2026-03-01
Base: openspec/specs/audit-dimensions/spec.md

---

## Overview

This delta adds observable behavior requirements for seven incremental improvements to
`project-audit`: enhanced D2 placeholder detection, enhanced D3 hook script existence
and active-changes conflict detection, D7 staleness score impact, D1 template path
verification, and two new dimensions — ADR Coverage (D12) and Spec Coverage (D13).

---

## ADDED — New requirements

---

### Requirement: D2 detects placeholder-only content in ai-context files

When any `ai-context/` file contains phrases that indicate unfilled template content,
D2 MUST report a finding. The following phrases are recognized as placeholder
indicators: `[To be filled]`, `TODO`, `[empty]`, `[TBD]`, `[placeholder]`,
`[To confirm]`, `[Empty]`.

#### Scenario: D2 fails when stack.md contains only placeholder text

- **GIVEN** `ai-context/stack.md` contains a line with the text `[To be filled]` and
  no technology-version pairs
- **WHEN** `/project-audit` is run on that project
- **THEN** D2 reports a finding of severity HIGH for `stack.md`:
  "stack.md appears to contain unfilled placeholder content"
- **AND** the D2 score for that file is reduced by at least 1 point compared to a
  project where `stack.md` has real content

#### Scenario: D2 fails when known-issues.md is a near-empty template

- **GIVEN** `ai-context/known-issues.md` exists and contains `[To confirm]` but no
  substantive content
- **WHEN** `/project-audit` is run
- **THEN** D2 reports a HIGH finding: "known-issues.md contains placeholder text only"
- **AND** the file is treated as functionally empty despite passing the line-count check

#### Scenario: D2 passes when placeholder phrases are absent

- **GIVEN** `ai-context/stack.md` lists at least 3 technologies each with a concrete
  version number (e.g., "React 19.0.0", "TypeScript 5.4.2")
- **AND** the file contains no recognized placeholder phrases
- **WHEN** `/project-audit` runs D2
- **THEN** no placeholder-content finding is emitted for `stack.md`

#### Scenario: D2 fails when stack.md lists fewer than 3 technologies with concrete versions

- **GIVEN** `ai-context/stack.md` exists with more than 30 lines
- **AND** it mentions only 1 technology with a version number (all others are named
  without versions or are vague)
- **WHEN** `/project-audit` runs D2
- **THEN** D2 emits a MEDIUM finding: "stack.md lists fewer than 3 technologies with
  concrete versions — minimum is 3"
- **AND** the D2 score is reduced compared to a stack.md with 3+ versioned entries

---

### Requirement: D3 verifies that hook scripts referenced in settings files exist on disk

When `settings.json` or `settings.local.json` in the project references hook scripts
(via the `hooks` key), `project-audit` D3 MUST verify that each referenced script path
exists on disk. A script path that does not exist on disk MUST be reported as a HIGH
finding.

#### Scenario: D3 reports missing hook script

- **GIVEN** the project's `settings.json` contains a `hooks` block that references a
  script at `hooks/my-hook.js`
- **AND** `hooks/my-hook.js` does NOT exist at the project root
- **WHEN** `/project-audit` runs D3
- **THEN** D3 emits a HIGH finding: "Hook script referenced in settings.json not found
  on disk: hooks/my-hook.js"
- **AND** this finding is listed in `required_actions.high` in the FIX_MANIFEST

#### Scenario: D3 passes when all hook scripts exist on disk

- **GIVEN** the project's `settings.json` references two hook scripts
- **AND** both scripts exist at the declared paths
- **WHEN** `/project-audit` runs D3
- **THEN** no hook-script-existence finding is emitted

#### Scenario: D3 is a no-op when no hooks are declared

- **GIVEN** the project's `settings.json` exists but has no `hooks` key
- **WHEN** `/project-audit` runs D3
- **THEN** D3 emits no hook-script-existence finding
- **AND** the D3 score is not affected

#### Scenario: D3 checks both settings.json and settings.local.json

- **GIVEN** the project has both `settings.json` (referencing hook A) and
  `settings.local.json` (referencing hook B)
- **AND** hook A exists but hook B does NOT
- **WHEN** `/project-audit` runs D3
- **THEN** exactly one HIGH finding is emitted for hook B from `settings.local.json`
- **AND** no finding is emitted for hook A (it exists)

---

### Requirement: D3 detects active-changes conflict when two changes target the same files

When two or more non-archived changes in `openspec/changes/` each declare a file
modification plan in their `design.md`, and two such plans reference the same file path,
`project-audit` D3 MUST emit a MEDIUM finding describing the conflict.

#### Scenario: D3 detects a file conflict between two active changes

- **GIVEN** `openspec/changes/change-alpha/design.md` and
  `openspec/changes/change-beta/design.md` both list `skills/project-audit/SKILL.md` in
  their file change plan sections
- **WHEN** `/project-audit` runs D3
- **THEN** D3 emits a MEDIUM finding: "Concurrent file modification conflict detected:
  skills/project-audit/SKILL.md is targeted by both change-alpha and change-beta"
- **AND** the finding is listed under `violations[]` in the FIX_MANIFEST (not in
  `required_actions`, since resolution is a human decision)

#### Scenario: D3 emits no conflict finding when no files are shared

- **GIVEN** two active non-archived changes each have a `design.md`
- **AND** the file paths listed in each design.md are entirely distinct (no overlap)
- **WHEN** `/project-audit` runs D3
- **THEN** no conflict finding is emitted

#### Scenario: D3 skips conflict check when fewer than two active changes have design.md

- **GIVEN** only one non-archived change has a `design.md`
- **WHEN** `/project-audit` runs D3
- **THEN** the conflict detection step is skipped and no finding is emitted

#### Scenario: D3 normalizes paths before comparison

- **GIVEN** `change-alpha/design.md` references `skills/project-audit/SKILL.md`
- **AND** `change-beta/design.md` references `./skills/project-audit/SKILL.md`
  (with a leading `./`)
- **WHEN** D3 performs conflict detection
- **THEN** the paths are normalized (leading `./` stripped) before comparison
- **AND** a conflict finding IS emitted for the overlapping path

---

### Requirement: D7 applies a score penalty when analysis-report.md is older than 30 days

When `analysis-report.md` exists but its `Last analyzed:` date is more than 30 days
before the current audit date, D7 MUST reduce its score by 1–2 points. Absence of
`analysis-report.md` retains the existing CRITICAL behavior (0/5).

#### Scenario: D7 deducts points for a stale analysis report (31–60 days old)

- **GIVEN** `analysis-report.md` exists with a `Last analyzed:` date that is 35 days
  before today
- **AND** the drift summary in the report is `none` (which would normally yield 5/5)
- **WHEN** `/project-audit` runs D7
- **THEN** D7 emits a staleness warning: "analysis-report.md is 35 days old (> 30 days)
  — staleness penalty applied"
- **AND** the D7 score is 4/5 (one-point deduction) instead of 5/5

#### Scenario: D7 deducts 2 points for a very stale analysis report (>60 days old)

- **GIVEN** `analysis-report.md` exists with a `Last analyzed:` date that is 75 days
  before today
- **AND** the drift summary is `none`
- **WHEN** `/project-audit` runs D7
- **THEN** D7 emits a staleness warning: "analysis-report.md is 75 days old (> 60 days)
  — staleness penalty applied"
- **AND** the D7 score is 3/5 (two-point deduction)

#### Scenario: D7 applies no penalty when analysis-report.md is 30 days old or fresher

- **GIVEN** `analysis-report.md` exists with a `Last analyzed:` date that is exactly 30
  days before today (boundary case)
- **AND** the drift summary is `none`
- **WHEN** `/project-audit` runs D7
- **THEN** D7 emits no staleness penalty finding
- **AND** the D7 score is 5/5

#### Scenario: D7 staleness penalty stacks with drift penalty

- **GIVEN** `analysis-report.md` exists and is 40 days old
- **AND** the drift summary is `minor` (which would normally yield 3/5)
- **WHEN** `/project-audit` runs D7
- **THEN** D7 deducts 1 additional point for staleness
- **AND** the D7 score is 2/5 (3 for minor drift − 1 for staleness)
- **AND** the score floor is 0/5 (cannot go negative)

#### Scenario: D7 staleness behavior is unchanged when analysis-report.md is absent

- **GIVEN** `analysis-report.md` does NOT exist in the project root
- **WHEN** `/project-audit` runs D7
- **THEN** D7 assigns 0/5 with the message "Run /project-analyze first, then
  re-run /project-audit" — identical to pre-change behavior
- **AND** no staleness penalty logic is applied (penalty only applies when the file
  exists but is old)

---

### Requirement: D1 verifies that template paths mentioned in CLAUDE.md exist on disk

When `CLAUDE.md` references a template file path (e.g., `docs/templates/prd-template.md`),
`project-audit` D1 MUST verify that file exists at the project root. A template path that
does not exist MUST be reported as a MEDIUM finding.

#### Scenario: D1 reports missing template file referenced in CLAUDE.md

- **GIVEN** `CLAUDE.md` contains the text `docs/templates/prd-template.md`
- **AND** the file `docs/templates/prd-template.md` does NOT exist in the project
- **WHEN** `/project-audit` runs D1
- **THEN** D1 emits a MEDIUM finding: "Template path referenced in CLAUDE.md does not
  exist on disk: docs/templates/prd-template.md"
- **AND** the finding is listed in `required_actions.medium` in the FIX_MANIFEST

#### Scenario: D1 passes when all referenced template paths exist

- **GIVEN** `CLAUDE.md` references `docs/templates/prd-template.md` and
  `docs/templates/adr-template.md`
- **AND** both files exist at the declared paths
- **WHEN** `/project-audit` runs D1
- **THEN** no template-path finding is emitted for either template

#### Scenario: D1 skips template check when CLAUDE.md has no template path references

- **GIVEN** `CLAUDE.md` contains no path strings matching `docs/templates/*.md` or
  equivalent template path patterns
- **WHEN** `/project-audit` runs D1
- **THEN** the template path check is skipped and emits no finding

#### Scenario: D1 detects multiple missing template paths in one run

- **GIVEN** `CLAUDE.md` references two template paths, neither of which exists on disk
- **WHEN** `/project-audit` runs D1
- **THEN** D1 emits exactly two separate MEDIUM findings — one per missing path
- **AND** both paths appear in `required_actions.medium` in the FIX_MANIFEST

---

### Requirement: Dimension 12 (ADR Coverage) audits ADR system health when CLAUDE.md references docs/adr/

When `CLAUDE.md` contains a reference to `docs/adr/`, `project-audit` MUST run a new
Dimension 12 check that verifies the ADR system is properly structured and maintained.
When `docs/adr/` is not referenced in `CLAUDE.md`, D12 MUST be skipped entirely with no
score impact.

#### Scenario: D12 is skipped when CLAUDE.md has no docs/adr/ reference

- **GIVEN** `CLAUDE.md` does NOT contain `docs/adr/` anywhere in its content
- **WHEN** `/project-audit` runs
- **THEN** D12 emits "ADR Coverage check skipped — docs/adr/ not referenced in CLAUDE.md"
- **AND** no ADR-related findings are added to the FIX_MANIFEST
- **AND** no score is deducted for the absence of ADRs

#### Scenario: D12 fails when CLAUDE.md references docs/adr/ but docs/adr/README.md is absent

- **GIVEN** `CLAUDE.md` contains a reference to `docs/adr/`
- **AND** `docs/adr/` does NOT exist, or exists but has no `README.md`
- **WHEN** `/project-audit` runs D12
- **THEN** D12 emits a HIGH finding: "CLAUDE.md references docs/adr/ but docs/adr/README.md
  is missing"
- **AND** the finding is listed in `required_actions.high` in the FIX_MANIFEST

#### Scenario: D12 validates status field in each ADR file

- **GIVEN** `docs/adr/` exists and contains two ADR markdown files
- **AND** one file has `status: accepted` in its frontmatter or body header
- **AND** the other file has no `status` field at all
- **WHEN** `/project-audit` runs D12
- **THEN** D12 emits a MEDIUM finding for the ADR missing a status field: "ADR file
  docs/adr/002-something.md is missing a valid status field"
- **AND** valid status values are: `accepted`, `deprecated`, `superseded`

#### Scenario: D12 passes when all ADR files have valid status values

- **GIVEN** `docs/adr/` contains three ADR files, each with a `status` field set to one
  of: `accepted`, `deprecated`, or `superseded`
- **WHEN** `/project-audit` runs D12
- **THEN** no ADR status findings are emitted

#### Scenario: D12 is informational when docs/adr/ exists but is empty

- **GIVEN** `CLAUDE.md` references `docs/adr/` and `docs/adr/README.md` exists
- **AND** the `docs/adr/` directory contains no ADR files (only the README)
- **WHEN** `/project-audit` runs D12
- **THEN** D12 emits an INFO finding: "docs/adr/ contains no ADR files yet"
- **AND** no score is deducted (informational only; no ADRs present means nothing to
  validate)

#### Scenario: D12 does not affect the existing 100-point score

- **GIVEN** D12 has run and detected ADR issues
- **WHEN** the score table in the audit report is read
- **THEN** D12 findings are listed separately as bonus/informational findings
- **AND** the maximum attainable score for Dimensions 1–9 remains 100
- **AND** D12 HIGH findings ARE listed in `required_actions.high` (they trigger
  project-fix) but do NOT reduce the base 100-point score

---

### Requirement: Dimension 13 (Spec Coverage) audits spec file health when openspec/specs/ exists

When `openspec/specs/` exists in the project, `project-audit` MUST run a new Dimension 13
check that verifies spec files are valid and their referenced paths still exist on disk.
When `openspec/specs/` does not exist, D13 MUST be skipped with no score impact.

#### Scenario: D13 is skipped when openspec/specs/ does not exist

- **GIVEN** `openspec/` exists but `openspec/specs/` does NOT exist
- **WHEN** `/project-audit` runs
- **THEN** D13 emits "Spec Coverage check skipped — openspec/specs/ not found"
- **AND** no spec-related findings are added to the FIX_MANIFEST
- **AND** no score is deducted

#### Scenario: D13 is skipped when openspec/ does not exist at all

- **GIVEN** the project has no `openspec/` directory
- **WHEN** `/project-audit` runs
- **THEN** D13 is skipped (same as above)

#### Scenario: D13 verifies at least one spec exists per detected domain

- **GIVEN** `openspec/specs/` exists and contains subdirectories: `auth/`, `payments/`
- **AND** `auth/spec.md` exists but `payments/spec.md` is missing
- **WHEN** `/project-audit` runs D13
- **THEN** D13 emits a MEDIUM finding: "Domain directory openspec/specs/payments/ exists
  but contains no spec.md file"

#### Scenario: D13 passes when all domain spec directories contain a spec.md

- **GIVEN** `openspec/specs/` contains three domain subdirectories, each with a `spec.md`
- **WHEN** `/project-audit` runs D13
- **THEN** no spec-coverage finding is emitted for missing spec files

#### Scenario: D13 flags a spec that references a non-existent path

- **GIVEN** `openspec/specs/auth/spec.md` contains a file path reference such as
  `src/auth/login.ts` in its body
- **AND** `src/auth/login.ts` does NOT exist in the project
- **WHEN** `/project-audit` runs D13
- **THEN** D13 emits an INFO finding: "Spec openspec/specs/auth/spec.md references a
  path that no longer exists: src/auth/login.ts"
- **AND** the finding is listed in `violations[]` of the FIX_MANIFEST with severity INFO
  (not a scored deduction)

#### Scenario: D13 passes when all spec path references are valid

- **GIVEN** `openspec/specs/` contains three domain specs, each referencing file paths
  that all exist on disk
- **WHEN** `/project-audit` runs D13
- **THEN** no stale-path finding is emitted

#### Scenario: D13 does not affect the existing 100-point score

- **GIVEN** D13 has run and detected spec issues
- **WHEN** the score table in the audit report is read
- **THEN** D13 MEDIUM findings for missing spec.md files appear in `required_actions.medium`
  (triggering project-fix)
- **AND** D13 INFO findings for stale paths appear only in `violations[]`
- **AND** the maximum attainable score for Dimensions 1–9 remains 100

---

## Rules

- All new checks MUST be conditional: projects without the relevant artifacts (docs/adr/,
  openspec/specs/, hook scripts) MUST receive N/A or skip, not a penalty
- D7 staleness penalty applies only when `analysis-report.md` exists AND is older than
  30 days; the score floor is 0 (cannot go negative from penalties)
- D12 and D13 are additive dimensions that do not alter the 100-point scoring pool for
  Dimensions 1–9
- Path normalization in D3 conflict detection MUST strip leading `./` before comparison
- Placeholder phrase detection in D2 is case-insensitive for phrases in brackets
  (e.g., `[TODO]` and `[todo]` are both detected)
- These specs describe observable behavior only; implementation details are left to
  the design phase
