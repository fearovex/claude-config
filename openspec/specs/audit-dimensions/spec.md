# Spec: audit-dimensions

Change: deprecate-commands-normalize-skills
Date: 2026-02-26

## Overview

This spec describes the observable behavior of `project-audit` at the dimension level after the commands deprecation. It covers: removal of Dimension 5 entirely, removal of the "Has Commands registry" check from Dimension 1, and the addition of a passive INFO notice when a legacy `commands/` directory is detected.

---

## Requirements

### Requirement: Dimension 5 (Commands Quality) is fully removed from project-audit

`project-audit/SKILL.md` MUST NOT contain any Dimension 5 section, D5 checks, or commands-focused audit logic after this change.

#### Scenario: SKILL.md has no Dimension 5 section

- **GIVEN** `skills/project-audit/SKILL.md` has been updated
- **WHEN** a developer reads the file from top to bottom
- **THEN** there is no section heading "Dimension 5" or "Commands Quality"
- **AND** there are no sub-checks 5a or 5b in the file
- **AND** the file's dimension count is 8 explicitly numbered dimensions (1, 2, 3, 4, 6, 7, 8, 9) plus D9

#### Scenario: Report format has no D5 block

- **GIVEN** the report format section of `project-audit/SKILL.md` defines the structure of the generated report
- **WHEN** that section is read
- **THEN** there is no "Dimension 5 — Commands" block in the report format template
- **AND** there is no row for D5 in any score table template
- **AND** the FIX_MANIFEST YAML template within the report format does not reference any commands-related action types (e.g., `fix_commands_registry`)

---

### Requirement: Dimension 1 does not penalize absence of a commands registry

The "Has Commands registry" check MUST be removed from Dimension 1's check table. Its absence MUST NOT be reported as a finding or deduct from D1's score.

#### Scenario: D1 check table has no commands registry row

- **GIVEN** `skills/project-audit/SKILL.md` D1 section is read
- **WHEN** a developer reads the "Checks to run" table
- **THEN** the table has no row with text "Has Commands registry" or equivalent
- **AND** no severity value is assigned for a missing commands table in CLAUDE.md

#### Scenario: D1 report format has no commands registry row

- **GIVEN** the D1 block in the report format template is read
- **WHEN** the table of checks and statuses is examined
- **THEN** there is no "Commands registry present" row in the template table
- **AND** the template table contains a "Skills registry present" row (unchanged)

#### Scenario: Audit on a project whose CLAUDE.md has no commands table

- **GIVEN** a project whose `CLAUDE.md` contains a Skills registry table but no Commands registry table
- **WHEN** `/project-audit` is run
- **THEN** the D1 score is unaffected by the absence of a Commands registry
- **AND** no D1 finding of any severity is emitted for "missing Commands registry"

---

### Requirement: Legacy commands/ directory triggers a passive INFO notice

If the target project has a `.claude/commands/` directory, `project-audit` MUST emit exactly one LOW/INFO finding recommending migration to skills. This finding MUST carry zero score penalty.

#### Scenario: INFO notice emitted for a project with commands/ present

- **GIVEN** the target project has a `.claude/commands/` directory with at least one file
- **WHEN** `/project-audit` runs
- **THEN** exactly one LOW finding appears in the report with text that:
  - identifies that a legacy `.claude/commands/` directory was detected
  - recommends migrating to `.claude/skills/` following the official Claude Code standard
- **AND** the finding severity is LOW (informational only)
- **AND** the finding does NOT appear in the `required_actions.critical`, `required_actions.high`, or `required_actions.medium` blocks of the FIX_MANIFEST

#### Scenario: No INFO notice emitted for a project without commands/

- **GIVEN** the target project has NO `.claude/commands/` directory
- **WHEN** `/project-audit` runs
- **THEN** no finding related to commands/ is emitted anywhere in the report

#### Scenario: INFO notice does not affect score

- **GIVEN** two identical projects, one with `.claude/commands/` and one without
- **WHEN** `/project-audit` is run on each
- **THEN** both projects receive the same numeric score
- **AND** the only difference in the reports is the presence or absence of the LOW INFO finding about commands/

---

### Requirement: The commands deprecation change itself is not audited or penalized

`project-audit` MUST NOT, after this change, generate any FIX_MANIFEST actions that would cause `project-fix` to create, repair, or populate a `.claude/commands/` directory.

#### Scenario: FIX_MANIFEST contains no commands-related actions for a compliant project

- **GIVEN** a project that correctly uses only `.claude/skills/` and has no `.claude/commands/` directory
- **WHEN** `/project-audit` is run and a FIX_MANIFEST is generated
- **THEN** the FIX_MANIFEST `required_actions` blocks contain no action with a `target` pointing to `.claude/commands/`
- **AND** no action type of `fix_commands_registry` or similar is present

---

## Rules

- The INFO notice for legacy commands/ is observable behavior — its presence and wording in the report are verifiable criteria
- Score impact is verifiable by comparing scores between runs on identical projects with and without commands/
- These specs do not constrain how the commands/ detection is implemented internally — only that the observable output matches the scenarios above

---

## ADDED in feature-docs-dimension (2026-02-26)

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

---

### Requirement: D10 detection phase — heuristic fallback

When `feature_docs` is absent from `openspec/config.yaml`, D10 MUST fall back to heuristic detection to discover features. The heuristic MUST resolve the effective local skills directory using the `LOCAL_SKILLS_DIR` variable emitted by the Phase A script — `skills/` when the repo is detected as global-config, `.claude/skills/` otherwise.

*(Modified in: 2026-02-27 by change "global-config-skill-audit")*

#### Scenario: D10 heuristic Source 1 uses LOCAL_SKILLS_DIR on a standard project *(modified)*

- **GIVEN** the target project is a standard (non-global-config) project
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=.claude/skills`
- **WHEN** D10 applies heuristic Source 1
- **THEN** it scans `.claude/skills/` for non-SDD skills as feature sources
- **AND** the behavior is identical to pre-change behavior for standard projects

#### Scenario: D10 heuristic Source 1 uses LOCAL_SKILLS_DIR on the global-config repo

- **GIVEN** the target project is the global-config repo (has `install.sh` + `sync.sh` at root, or `framework: "Claude Code SDD meta-system"` in `openspec/config.yaml`)
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=skills`
- **WHEN** D10 applies heuristic Source 1
- **THEN** it scans `skills/` (root) for non-SDD skill directories as feature sources
- **AND** does NOT scan `.claude/skills/` (which does not exist in this repo)

#### Scenario: D10 runs heuristic detection when feature_docs is absent

- **GIVEN** the target project has `openspec/config.yaml` but no `feature_docs` section (or no `openspec/config.yaml` at all)
- **WHEN** `/project-audit` is run
- **THEN** D10 applies the heuristic detection strategy, scanning the following locations in order:
  1. Non-SDD skills in `$LOCAL_SKILLS_DIR` (skills whose names do not start with `sdd-`, `project-`, `memory-`, or `skill-`)
  2. Markdown files directly in `docs/features/` or `docs/modules/` (if those directories exist)
  3. Subdirectories of `src/features/`, `src/modules/`, or `app/` that contain their own `README.md`
- **AND** directories named `shared`, `utils`, `common`, or `lib` are excluded from heuristic detection even if they contain a `README.md`

#### Scenario: D10 emits INFO and skips checks when no features are detected *(unchanged)*

- **GIVEN** the target project has no `feature_docs` configured AND heuristic detection finds zero features
- **WHEN** `/project-audit` runs D10
- **THEN** the D10 section in the report contains exactly one line: "No feature docs detected — D10 skipped"
- **AND** no coverage table is emitted for D10
- **AND** no D10 findings of any severity are added to the FIX_MANIFEST

---

### Requirement: D10-a Coverage check

For each detected feature, D10 MUST verify that a corresponding documentation artifact (SKILL.md or markdown file) exists.

---

### Requirement: D10-b Structural Quality check

For each detected feature with a documentation artifact, D10 MUST verify that the artifact meets minimum structural quality standards.

---

### Requirement: D10-c Code Freshness check

For each detected feature with a documentation artifact, D10 MUST verify that file paths referenced in the doc still exist on disk.

---

### Requirement: D10-d Registry Alignment check

For each detected feature skill, D10 MUST verify that the skill is listed in the target project's `CLAUDE.md` Skills Registry.

---

---

## ADDED in global-config-skill-audit (2026-02-27)

### Requirement: D9 uses LOCAL_SKILLS_DIR to determine the skills path

D9 (Project Skills Quality) MUST use `LOCAL_SKILLS_DIR` (emitted by the Phase A script) as the path to the local skills directory, instead of the hardcoded `.claude/skills/`.

#### Scenario: D9 skip condition checks LOCAL_SKILLS_DIR

- **GIVEN** the Phase A script has been executed and has emitted `LOCAL_SKILLS_DIR`
- **WHEN** D9 evaluates whether to skip
- **THEN** D9 checks whether the directory identified by `LOCAL_SKILLS_DIR` exists
- **AND** if `LOCAL_SKILLS_DIR` does NOT exist as a directory, D9 emits "No skills directory found — Dimension 9 skipped" and produces no further findings

#### Scenario: D9 runs on a standard project (LOCAL_SKILLS_DIR = .claude/skills)

- **GIVEN** the target project is a standard project
- **AND** the Phase A script emitted `LOCAL_SKILLS_DIR=.claude/skills`
- **AND** `.claude/skills/` exists in the project
- **WHEN** D9 runs
- **THEN** D9 audits the skills found in `.claude/skills/`
- **AND** the output is identical to pre-change behavior for standard projects

#### Scenario: D9 runs on the global-config repo (LOCAL_SKILLS_DIR = skills)

- **GIVEN** the target project is the global-config repo
- **AND** the Phase A script emitted `LOCAL_SKILLS_DIR=skills`
- **AND** `skills/` (root) exists and contains skill directories
- **WHEN** D9 runs
- **THEN** D9 does NOT emit "Dimension 9 skipped"
- **AND** D9 audits at least one skill directory from `skills/`
- **AND** the report includes a D9 section with at least one skill listed

#### Scenario: D9 duplicate detection when LOCAL_SKILLS_DIR = skills (global-config)

- **GIVEN** the global-config repo is the audit target
- **AND** D9's duplicate-detection logic compares local skills with the global catalog
- **WHEN** the comparison runs
- **THEN** skills found in `skills/` are compared against `~/.claude/skills/` (the deployed runtime)
- **AND** because the local skills ARE the global catalog, all skills are expected to have a matching global counterpart
- **AND** this is documented as expected behavior with a `keep` disposition — no WARNING findings are emitted solely because a local skill matches a global skill

---

### Requirement: D10-a and D10-d path references use LOCAL_SKILLS_DIR

When checking coverage (D10-a) and registry alignment (D10-d), the path used to locate a skill's SKILL.md MUST be derived from `LOCAL_SKILLS_DIR`.

#### Scenario: D10-a coverage check uses LOCAL_SKILLS_DIR path

- **GIVEN** D10 has detected a feature with `convention=skill`
- **AND** the Phase A script emitted `LOCAL_SKILLS_DIR=skills` (global-config)
- **WHEN** D10-a checks whether a documentation artifact exists for that feature
- **THEN** it looks for `skills/<feature_name>/SKILL.md`
- **AND** does NOT look for `.claude/skills/<feature_name>/SKILL.md`

#### Scenario: D10-d registry alignment check reads root CLAUDE.md (unchanged for global-config)

- **GIVEN** D10 is running against the global-config repo
- **WHEN** D10-d checks that a detected feature skill is listed in the CLAUDE.md Skills Registry
- **THEN** it reads the `CLAUDE.md` at the project root (not `.claude/CLAUDE.md`)
- **AND** this behavior is correct for both standard and global-config repos (no change in lookup target)

---

### Requirement: D10 findings never appear in FIX_MANIFEST required_actions

D10 MUST NOT generate FIX_MANIFEST entries that would cause `/project-fix` to create or repair feature documentation.

#### Scenario: FIX_MANIFEST contains no D10 entries

- **GIVEN** D10 has detected features with ❌ findings (e.g., missing coverage, stale paths)
- **WHEN** the FIX_MANIFEST in `audit-report.md` is read
- **THEN** `required_actions.critical`, `required_actions.high`, and `required_actions.medium` contain no entries referencing D10 findings
- **AND** a note in the D10 section states that fixing feature documentation gaps is a human decision

---

## ADDED in skill-internal-coherence-validation (2026-02-28)

### Requirement: Dimension 11 (Internal Coherence) is present in project-audit

`project-audit/SKILL.md` MUST contain a Dimension 11 section that validates internal coherence of individual skill files. Dimension 11 MUST appear after Dimension 10 in the file and MUST follow the informational-only pattern established by D9 and D10.

#### Scenario: SKILL.md contains a Dimension 11 section

- **GIVEN** `skills/project-audit/SKILL.md` has been updated with this change
- **WHEN** a developer reads the file from top to bottom
- **THEN** there is a section heading "Dimension 11" or "Internal Coherence" after the Dimension 10 section
- **AND** the section documents three sub-checks: D11-a (Count Consistency), D11-b (Section Numbering Continuity), D11-c (Frontmatter-Body Alignment)
- **AND** each sub-check has explicit pass/fail criteria documented

#### Scenario: Report format has a D11 block

- **GIVEN** the report format section of `project-audit/SKILL.md` defines the structure of the generated report
- **WHEN** that section is read
- **THEN** there is a "Dimension 11 — Internal Coherence" block in the report format template
- **AND** the block includes a table listing each audited skill file and its coherence findings
- **AND** there is no row for D11 in the scoring table (informational only)

---

### Requirement: D11 scope — which files are audited

D11 MUST audit all skill files found in `$LOCAL_SKILLS_DIR` (emitted by the Phase A script). D11 MUST also audit the project root `CLAUDE.md` if it exists.

#### Scenario: D11 audits all skill files via LOCAL_SKILLS_DIR on a standard project

- **GIVEN** the target project is a standard project
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=.claude/skills`
- **AND** `.claude/skills/` contains 5 skill directories each with a `SKILL.md`
- **WHEN** D11 runs
- **THEN** D11 audits each of the 5 `SKILL.md` files
- **AND** D11 audits the root `CLAUDE.md`

#### Scenario: D11 audits skill files on the global-config repo

- **GIVEN** the target project is the global-config repo
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=skills`
- **WHEN** D11 runs
- **THEN** D11 audits skill files from `skills/` (root), not `.claude/skills/`
- **AND** D11 audits the root `CLAUDE.md`

#### Scenario: D11 skips when no skills directory exists

- **GIVEN** the target project has no skills directory (the path in `LOCAL_SKILLS_DIR` does not exist)
- **AND** no root `CLAUDE.md` exists
- **WHEN** D11 runs
- **THEN** D11 emits "No auditable files found — Dimension 11 skipped"
- **AND** no findings are produced

---

### Requirement: D11-a Count Consistency check

For each audited file, D11 MUST extract numeric claims from headers and summary lines and compare them against the actual count of matching sections in the body.

#### Scenario: D11-a detects a header claiming "7 Dimensions" when 10 exist

- **GIVEN** a `SKILL.md` file contains a header or summary line stating "7 Dimensions"
- **AND** the file body contains 10 sections whose headings match the pattern "Dimension N" (where N is a number)
- **WHEN** D11-a runs on that file
- **THEN** D11-a emits a finding: the file claims 7 dimensions but 10 were found
- **AND** the finding severity is INFO

#### Scenario: D11-a detects a header claiming "5 Steps" when 5 exist

- **GIVEN** a `SKILL.md` file contains a header or summary line stating "5 Steps"
- **AND** the file body contains exactly 5 sections whose headings match "Step N" or "### Step N"
- **WHEN** D11-a runs on that file
- **THEN** D11-a emits no finding for that count claim (it is consistent)

#### Scenario: D11-a handles files with no numeric claims

- **GIVEN** a `SKILL.md` file contains no numeric claims in headers or summary lines
- **WHEN** D11-a runs on that file
- **THEN** D11-a emits no count-related findings for that file

#### Scenario: D11-a checks CLAUDE.md count claims

- **GIVEN** the root `CLAUDE.md` contains a line stating "23 skills" in a summary or header
- **AND** the Skills Registry section lists 25 skills
- **WHEN** D11-a runs on `CLAUDE.md`
- **THEN** D11-a emits a finding: the file claims 23 skills but 25 were found
- **AND** the finding severity is INFO

---

### Requirement: D11-b Section Numbering Continuity check

For each audited file, D11 MUST verify that numbered section sequences have no gaps or duplicates.

#### Scenario: D11-b detects a numbering gap

- **GIVEN** a `SKILL.md` file contains sections numbered "Step 1", "Step 2", "Step 4" (Step 3 is missing)
- **WHEN** D11-b runs on that file
- **THEN** D11-b emits a finding: section numbering gap detected — "Step 3" is missing between "Step 2" and "Step 4"
- **AND** the finding severity is INFO

#### Scenario: D11-b detects a duplicate number

- **GIVEN** a `SKILL.md` file contains two sections both titled "Step 2"
- **WHEN** D11-b runs on that file
- **THEN** D11-b emits a finding: duplicate section number detected — "Step 2" appears twice
- **AND** the finding severity is INFO

#### Scenario: D11-b validates a correct sequence

- **GIVEN** a `SKILL.md` file contains sections "Dimension 1", "Dimension 2", "Dimension 3" (consecutive, no gaps, no duplicates)
- **WHEN** D11-b runs on that file
- **THEN** D11-b emits no numbering findings for that file

---

### Requirement: D11-c Frontmatter-Body Alignment check

For each audited file that has YAML frontmatter, D11 MUST verify that count claims in the `description` field match the body content.

#### Scenario: D11-c detects frontmatter description mismatch

- **GIVEN** a `SKILL.md` file has YAML frontmatter with `description: "Audits 7 dimensions of project health"`
- **AND** the file body defines 10 dimensions
- **WHEN** D11-c runs on that file
- **THEN** D11-c emits a finding: frontmatter description claims 7 dimensions but 10 were found in the body
- **AND** the finding severity is INFO

#### Scenario: D11-c passes when frontmatter matches body

- **GIVEN** a `SKILL.md` file has YAML frontmatter with `description: "Validates 3 rules"`
- **AND** the file body defines exactly 3 rules
- **WHEN** D11-c runs on that file
- **THEN** D11-c emits no frontmatter-related findings

#### Scenario: D11-c skips files without frontmatter

- **GIVEN** a `SKILL.md` file has no YAML frontmatter block
- **WHEN** D11-c runs on that file
- **THEN** D11-c emits no frontmatter-related findings for that file

---

### Requirement: D11 is informational only — no score impact

D11 MUST NOT affect the numeric audit score. D11 findings MUST appear only in `violations[]` of the FIX_MANIFEST, never in `required_actions`.

#### Scenario: D11 findings do not affect the score

- **GIVEN** two identical projects, one with a known D11 inconsistency and one without
- **WHEN** `/project-audit` is run on each
- **THEN** both projects receive the same numeric score
- **AND** the only difference in reports is the presence or absence of D11 INFO findings

#### Scenario: D11 findings appear in violations only

- **GIVEN** D11 has detected 3 inconsistencies across skill files
- **WHEN** the FIX_MANIFEST in `audit-report.md` is generated
- **THEN** `violations[]` contains 3 entries referencing D11 findings
- **AND** `required_actions.critical`, `required_actions.high`, and `required_actions.medium` contain no entries referencing D11 findings

---

### Requirement: D11 does not introduce additional Bash calls

D11 MUST NOT introduce any new Bash tool calls beyond the existing Phase A discovery script. All file reading for D11 MUST use the Read, Glob, or Grep tools.

#### Scenario: D11 uses only Read/Glob/Grep for file analysis

- **GIVEN** the Phase A discovery script has completed
- **WHEN** D11 evaluates skill files for internal coherence
- **THEN** D11 reads file contents using the Read tool
- **AND** D11 does NOT issue any Bash calls (e.g., `grep`, `wc -l`, `find`)
- **AND** the total Bash call count for the entire audit remains at most 3

---

## ADDED in audit-improvements (2026-03-01)

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

## Rules (updated in audit-improvements 2026-03-01)

- All new checks MUST be conditional: projects without the relevant artifacts (docs/adr/,
  openspec/specs/, hook scripts) MUST receive N/A or skip, not a penalty
- D7 staleness penalty applies only when `analysis-report.md` exists AND is older than
  30 days; the score floor is 0 (cannot go negative from penalties)
- D12 and D13 are additive dimensions that do not alter the 100-point scoring pool for
  Dimensions 1–9
- Path normalization in D3 conflict detection MUST strip leading `./` before comparison
- Placeholder phrase detection in D2 is case-insensitive for phrases in brackets
  (e.g., `[TODO]` and `[todo]` are both detected)
