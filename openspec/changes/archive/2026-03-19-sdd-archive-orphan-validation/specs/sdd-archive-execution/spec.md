# Delta Spec: sdd-archive-execution

Change: 2026-03-19-sdd-archive-orphan-validation
Date: 2026-03-19
Base: openspec/specs/sdd-archive-execution/spec.md

---

## ADDED — New requirements

### Requirement: Completeness validation runs before verify-report check

Before `sdd-archive` reads `verify-report.md` or presents the irreversibility confirmation
prompt, it MUST run a completeness validation check on the change directory to detect missing
required SDD artifacts. This check uses a two-tier severity model: CRITICAL (blocks with no
proceed option) and WARNING (user may acknowledge and continue).

The check MUST run at the top of Step 1 ("Verify it is archivable"), before any existing
Step 1 logic.

#### Scenario: Happy path — all required artifacts present

- **GIVEN** an SDD change directory at `openspec/changes/<name>/` contains `proposal.md`,
  `tasks.md`, `design.md`, and a non-empty `specs/` directory
- **WHEN** `sdd-archive` executes Step 1
- **THEN** the completeness check produces no output and no prompts
- **AND** execution continues immediately to the existing `verify-report.md` check
- **AND** no additional user interaction is required for the completeness check itself

#### Scenario: CRITICAL block — proposal.md is absent

- **GIVEN** a change directory that does NOT contain `proposal.md`
- **WHEN** `sdd-archive` executes the completeness check in Step 1
- **THEN** the output displays a CRITICAL block listing `proposal.md` as missing
- **AND** the block MUST NOT include any option for the user to proceed or acknowledge
- **AND** `sdd-archive` halts immediately — the existing verify-report check and
  confirmation prompt MUST NOT be reached
- **AND** the output instructs the user to return and complete the missing phase before
  attempting to archive again

#### Scenario: CRITICAL block — tasks.md is absent

- **GIVEN** a change directory that does NOT contain `tasks.md`
- **WHEN** `sdd-archive` executes the completeness check in Step 1
- **THEN** the output displays a CRITICAL block listing `tasks.md` as missing
- **AND** no proceed option is presented
- **AND** `sdd-archive` halts — the existing Step 1 verify-report logic is NOT executed

#### Scenario: CRITICAL block — both proposal.md and tasks.md are absent

- **GIVEN** a change directory that contains neither `proposal.md` nor `tasks.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** both files are listed in a single CRITICAL block
- **AND** the archive halts with no proceed option

#### Scenario: WARNING — design.md is absent

- **GIVEN** a change directory that contains `proposal.md` and `tasks.md` but does NOT
  contain `design.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** the output displays a WARNING block listing `design.md` as missing
- **AND** the block presents exactly two options:
  - Option 1: Return and complete the missing phases
  - Option 2: Archive anyway with explicit acknowledgment that `design.md` was intentionally
    skipped
- **AND** the archive does NOT proceed until the user selects one of the two options

#### Scenario: WARNING — specs/ directory is absent or empty

- **GIVEN** a change directory that contains `proposal.md` and `tasks.md` but either has no
  `specs/` directory or has a `specs/` directory that contains no `.md` files
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** the output displays a WARNING block listing the missing specs as absent/empty
- **AND** exactly two options (return to complete / acknowledge and proceed) are presented

#### Scenario: WARNING — both design.md and specs/ are absent

- **GIVEN** a change directory with `proposal.md` and `tasks.md`, but without `design.md`
  and with an absent or empty `specs/` directory
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** a single WARNING block lists both `design.md` and `specs/` as missing
- **AND** the same two-option prompt is presented once (not twice)

#### Scenario: CRITICAL takes precedence over WARNING in the same check

- **GIVEN** a change directory where `proposal.md` is absent AND `design.md` is absent
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** only the CRITICAL block is presented (listing `proposal.md` as missing)
- **AND** the WARNING for `design.md` is NOT displayed alongside the CRITICAL block
- **AND** the archive halts without any proceed option

---

### Requirement: CLOSURE.md records skipped phases when option 2 is selected

When a user selects option 2 (archive with explicit acknowledgment) during a WARNING-level
completeness check, the `CLOSURE.md` file created in Step 5 MUST include a `Skipped phases:`
field that lists each phase whose artifact was absent and acknowledged.

#### Scenario: CLOSURE.md includes Skipped phases field after WARNING acknowledgment

- **GIVEN** the user has selected option 2 (acknowledge and archive) for a WARNING that
  listed `design.md` as absent
- **WHEN** `sdd-archive` creates the `CLOSURE.md` in Step 5
- **THEN** `CLOSURE.md` contains a `Skipped phases:` field
- **AND** the field lists `design` as a skipped phase
- **AND** the field appears as a distinct line or section in the closure note (not buried in
  the summary paragraph)

#### Scenario: CLOSURE.md includes Skipped phases field for multiple WARNING artifacts

- **GIVEN** the user has acknowledged a WARNING listing both `design.md` and `specs/` as absent
- **WHEN** `sdd-archive` creates `CLOSURE.md`
- **THEN** the `Skipped phases:` field lists both `design` and `spec` as skipped phases
- **AND** the field is present regardless of whether any other closure sections are populated

#### Scenario: CLOSURE.md does NOT contain Skipped phases field when all artifacts are present

- **GIVEN** a happy-path archive where all required artifacts were present (no WARNING was
  triggered)
- **WHEN** `sdd-archive` creates `CLOSURE.md`
- **THEN** `CLOSURE.md` does NOT contain a `Skipped phases:` field
- **AND** the closure note structure is unchanged from the standard template

---

### Requirement: exploration.md and prd.md are never checked

The completeness validation MUST NOT check for `exploration.md` or `prd.md`. These files are
optional by project convention and their absence MUST NOT trigger any CRITICAL or WARNING
output.

#### Scenario: Archive proceeds normally when exploration.md is absent

- **GIVEN** a change directory that has all CRITICAL and WARNING artifacts but no `exploration.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** no warning or block is produced for the absent `exploration.md`
- **AND** execution continues as if the file were present

#### Scenario: Archive proceeds normally when prd.md is absent

- **GIVEN** a change directory that has all CRITICAL and WARNING artifacts but no `prd.md`
- **WHEN** `sdd-archive` executes the completeness check
- **THEN** no warning or block is produced for the absent `prd.md`
- **AND** execution continues as if the file were present

---

## Rules

- The completeness check is purely terminal — it runs only in `sdd-archive`, never in any other SDD phase skill
- CRITICAL artifacts (`proposal.md`, `tasks.md`) MUST block with no user escape path
- WARNING artifacts (`design.md`, non-empty `specs/`) MUST always offer option 2 (acknowledge and proceed) — they MUST NOT silently block
- The `Skipped phases:` field in `CLOSURE.md` is informational only; it does not alter archive success status
- Completeness validation MUST run before `verify-report.md` is read and before the irreversibility confirmation prompt
- `exploration.md` and `prd.md` are explicitly excluded from the check and MUST NOT appear in any block output
