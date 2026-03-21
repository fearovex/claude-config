# Spec: spec-header-conventions

Change: 2026-03-14-spec-headers-domain-consolidation
Date: 2026-03-14

## Requirements

### Requirement: Canonical structured header format in all spec files

Every spec file under `openspec/specs/<domain>/spec.md` MUST begin with a `# Spec:` title line followed immediately by a two-line structured header block (`Change:` and `Date:`) as the first content after the title. No spec file MUST use the legacy inline-prose header format (`*Created: ...`), bare key-value lines, or a horizontal rule separator as its header.

#### Scenario: Spec file has canonical structured header — happy path

- **GIVEN** any spec file `openspec/specs/<domain>/spec.md` exists
- **WHEN** a reader or parser reads the first four lines of the file
- **THEN** line 1 MUST match `# Spec: <title>`
- **AND** line 2 MUST be blank
- **AND** line 3 MUST match `Change: <slug>`
- **AND** line 4 MUST match `Date: YYYY-MM-DD`

#### Scenario: Formerly legacy spec files have been backfilled — sdd-apply

- **GIVEN** the file `openspec/specs/sdd-apply/spec.md` after this change is applied
- **WHEN** a reader inspects the header block at the top of the file
- **THEN** the header contains `Change: 2026-03-03-tech-skill-auto-activation` (the originating slug)
- **AND** the header contains `Date: 2026-03-03`
- **AND** no italic `*Created: ...*` line is present in the header

#### Scenario: Formerly legacy spec files have been backfilled — sdd-verify-execution

- **GIVEN** the file `openspec/specs/sdd-verify-execution/spec.md` after this change is applied
- **WHEN** a reader inspects the header block at the top of the file
- **THEN** the header contains `Change: 2026-02-28-close-p1-gaps-sdd-apply-verify`
- **AND** the header contains `Date: 2026-02-28`
- **AND** no italic `*Created: ...*` line is present in the header

#### Scenario: Formerly legacy spec files have been backfilled — smart-commit

- **GIVEN** the file `openspec/specs/smart-commit/spec.md` after this change is applied
- **WHEN** a reader inspects the header block at the top of the file
- **THEN** the header contains `Change: 2026-03-03-smart-commit-functional-split`
- **AND** the header contains `Date: 2026-03-03`
- **AND** the bare-key-line + horizontal-rule format that preceded the `## Requirements` section is no longer present

#### Scenario: Formerly legacy spec files have been backfilled — solid-ddd-skill

- **GIVEN** the file `openspec/specs/solid-ddd-skill/spec.md` after this change is applied
- **WHEN** a reader inspects the header block at the top of the file
- **THEN** the header contains `Change: 2026-03-04-solid-ddd-quality-enforcement`
- **AND** the header contains `Date: 2026-03-04`
- **AND** no italic `*Created: ...*` line is present in the header

#### Scenario: Non-legacy spec files are not modified

- **GIVEN** any spec file whose header was already in the canonical `Change:` / `Date:` format before this change
- **WHEN** this change is applied
- **THEN** that spec file's content is unchanged
- **AND** its header remains identical to its pre-change state

---

### Requirement: sdd-apply spec consolidates all sdd-apply behavior into a single file

`openspec/specs/sdd-apply/spec.md` MUST contain all behavior specifications for the `sdd-apply` skill, including TDD mode detection, the RED-GREEN-REFACTOR cycle, and the no-commit-suggestion rule. The separate `sdd-apply-execution` domain directory MUST NOT exist after this change is applied.

#### Scenario: sdd-apply spec contains the Part 2 section — happy path

- **GIVEN** `openspec/specs/sdd-apply/spec.md` after this change is applied
- **WHEN** a reader searches the file for TDD-related content
- **THEN** the file MUST contain a `## Part 2: TDD Mode and Output` section
- **AND** the TDD mode detection requirement (three-source priority check) MUST be present in that section
- **AND** the RED-GREEN-REFACTOR cycle requirement MUST be present in that section
- **AND** the no-commit-suggestion requirement MUST be present in that section

#### Scenario: Part 2 content is additive — no existing content removed

- **GIVEN** `openspec/specs/sdd-apply/spec.md` before and after this change
- **WHEN** the pre-change and post-change versions are compared
- **THEN** all requirements, scenarios, and rules present before the change are still present after
- **AND** no existing line of content has been removed or rewritten

#### Scenario: sdd-apply-execution directory no longer exists

- **GIVEN** the file system after this change is applied
- **WHEN** a reader navigates to `openspec/specs/sdd-apply-execution/`
- **THEN** the directory MUST NOT exist
- **AND** no `spec.md` or any other file is present at that path

#### Scenario: sdd-apply spec header is backfilled before Part 2 is appended

- **GIVEN** `openspec/specs/sdd-apply/spec.md` after this change is applied
- **WHEN** a reader reads the beginning and end of the file
- **THEN** the file begins with the canonical `Change:` / `Date:` structured header
- **AND** the file ends with the `## Part 2: TDD Mode and Output` content (i.e., Part 2 is appended after all existing content)
- **AND** the Part 2 heading and its content appear only once in the file

---

### Requirement: architecture.md references updated to reflect consolidation

Any entry in `ai-context/architecture.md` that previously referenced `openspec/specs/sdd-apply-execution/spec.md` MUST be updated to reference `openspec/specs/sdd-apply/spec.md` instead.

#### Scenario: architecture.md references point to the merged location

- **GIVEN** `ai-context/architecture.md` after this change is applied
- **WHEN** a reader searches the file for references to `sdd-apply-execution`
- **THEN** no reference to `openspec/specs/sdd-apply-execution/spec.md` is found
- **AND** the path `openspec/specs/sdd-apply/spec.md` appears in the entries that previously referenced `sdd-apply-execution`

#### Scenario: Unrelated architecture.md entries are not modified

- **GIVEN** `ai-context/architecture.md` entries that do not reference `sdd-apply-execution`
- **WHEN** this change is applied
- **THEN** those entries are unchanged
- **AND** no line other than the two referencing `sdd-apply-execution` is modified

---

### Requirement: No spec content is lost or altered beyond the defined scope

This change is strictly maintenance-level. No requirement, scenario, or rule within any target spec file MUST be altered, rewritten, paraphrased, or removed. The only permitted modifications are:
- Header line replacement (legacy → canonical format)
- Appending the `## Part 2: TDD Mode and Output` section to `sdd-apply/spec.md`
- Updating two path references in `architecture.md`

#### Scenario: Requirements count preserved in each backfilled spec

- **GIVEN** each of the four header-only backfill targets (`sdd-apply`, `sdd-verify-execution`, `smart-commit`, `solid-ddd-skill`)
- **WHEN** the requirement count in the pre-change and post-change versions is compared
- **THEN** the count is identical (no requirement added or removed)
- **AND** every scenario name is present in both versions

#### Scenario: Part 2 content matches sdd-apply-execution spec verbatim

- **GIVEN** the content appended as `## Part 2: TDD Mode and Output` in `sdd-apply/spec.md`
- **WHEN** it is compared with the pre-change content of `sdd-apply-execution/spec.md` (excluding its own title line and legacy header)
- **THEN** the content is identical (no paraphrasing, no omissions, no additions beyond the section heading)

#### Scenario: File line count increases by expected amount

- **GIVEN** `openspec/specs/sdd-apply/spec.md` before and after this change
- **WHEN** the line count is compared
- **THEN** the post-change line count is approximately the pre-change line count plus the line count of `sdd-apply-execution/spec.md` (minus its title and legacy header, plus the new Part 2 section heading)
- **AND** the post-change line count is greater than the pre-change line count (no net loss)

---

## Rules

- The canonical spec header format is `Change: <slug>` on one line and `Date: YYYY-MM-DD` on the next line, immediately after the `# Spec:` title and a blank line — this ordering MUST NOT be changed
- Originating slugs in backfilled headers MUST be taken verbatim from the legacy header text — no inference or substitution is permitted
- The `## Part 2: TDD Mode and Output` section heading MUST appear exactly once in `sdd-apply/spec.md` after the change is applied
- The deletion of `openspec/specs/sdd-apply-execution/` MUST NOT happen before the Part 2 content is successfully appended to `sdd-apply/spec.md`
- No file other than the six identified targets (`sdd-apply/spec.md`, `sdd-apply-execution/spec.md`, `sdd-verify-execution/spec.md`, `smart-commit/spec.md`, `solid-ddd-skill/spec.md`, `ai-context/architecture.md`) MUST be modified by this change
