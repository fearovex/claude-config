# Delta Spec: audit-dimensions

Change: skill-internal-coherence-validation
Date: 2026-02-28
Base: openspec/specs/audit-dimensions/spec.md

## ADDED — New requirements

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

#### Scenario: D11-a pattern matching for numeric claims

- **GIVEN** a file contains lines with patterns like "N Dimensions", "N Steps", "N Rules", "N skills", "N checks", "N phases" (where N is a digit)
- **WHEN** D11-a extracts numeric claims
- **THEN** it matches only lines in headings (lines starting with `#`) or in the YAML frontmatter `description` field
- **AND** it does NOT match numeric references in body text, examples, or code blocks

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

#### Scenario: D11-b handles intentional numbering gaps (D5 removed)

- **GIVEN** `project-audit/SKILL.md` has dimensions numbered 1, 2, 3, 4, 6, 7, 8, 9, 10, 11 (D5 intentionally removed)
- **WHEN** D11-b runs on that file
- **THEN** D11-b emits a finding: section numbering gap detected — "Dimension 5" is missing
- **AND** the finding severity is INFO (not an error — it is informational only)
- **AND** this is expected behavior because D11 cannot distinguish intentional from accidental gaps

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

#### Scenario: D11 findings include actionable detail

- **GIVEN** D11 has detected an inconsistency in `skills/project-audit/SKILL.md`
- **WHEN** the violation entry is read
- **THEN** it includes: the file path, the check that failed (D11-a, D11-b, or D11-c), the expected value, the actual value, and a human-readable description of the mismatch

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

## Rules

- D11 checks are purely structural and numeric — they do NOT evaluate whether the content is semantically correct or well-written
- D11 pattern matching for numeric claims MUST be conservative: only flag when a numeric claim is clearly present in a heading or frontmatter description and clearly contradicted by the body
- Numeric claims inside code blocks, examples, or quoted text MUST NOT be matched
- D11 cannot distinguish intentional from accidental gaps/mismatches — all findings are informational and require human judgment to resolve
- These specs describe observable behavior only — they do not constrain how D11 is implemented internally
