# Spec: sdd-verify-execution

*Created: 2026-02-28 by change "close-p1-gaps-sdd-apply-verify"*

## Overview

This spec describes the observable behavior of the `sdd-verify` skill when executing build/test commands and producing a Spec Compliance Matrix. It covers test runner detection and execution, build/type-check execution, optional coverage validation, the compliance matrix format, and the updated verify-report.md template.

---

## Requirements

### Requirement: Test runner detection and execution

The `sdd-verify` skill MUST detect the project's test runner and execute the test suite, capturing exit code and output. Detection MUST use well-known project files and fall back gracefully when no runner is found.

#### Scenario: Test runner detected from package.json

- **GIVEN** a project with a `package.json` file containing a `scripts.test` entry
- **WHEN** `sdd-verify` runs the test execution step
- **THEN** it executes `npm test` (or `yarn test` / `pnpm test` based on lockfile presence)
- **AND** it captures the exit code (0 = pass, non-zero = failure)
- **AND** it captures the stdout/stderr output for analysis

#### Scenario: Test runner detected from pyproject.toml or setup.cfg

- **GIVEN** a project with `pyproject.toml` or `setup.cfg` indicating pytest
- **WHEN** `sdd-verify` runs the test execution step
- **THEN** it executes `pytest` (or the configured test command)
- **AND** it captures the exit code and output

#### Scenario: Test runner detected from Makefile

- **GIVEN** a project with a `Makefile` containing a `test` target
- **WHEN** `sdd-verify` runs the test execution step
- **THEN** it executes `make test`
- **AND** it captures the exit code and output

#### Scenario: Test runner detected from build.gradle or gradlew

- **GIVEN** a project with `build.gradle` or `gradlew`
- **WHEN** `sdd-verify` runs the test execution step
- **THEN** it executes `./gradlew test`
- **AND** it captures the exit code and output

#### Scenario: No test runner detected -- graceful skip

- **GIVEN** a project with no recognizable test runner configuration
- **WHEN** `sdd-verify` reaches the test execution step
- **THEN** it skips test execution
- **AND** it reports "Test Execution: SKIPPED -- no test runner detected" with status WARNING
- **AND** it does NOT fail the verification

#### Scenario: Test runner exists but tests fail

- **GIVEN** a detected test runner
- **WHEN** the test command executes and returns a non-zero exit code
- **THEN** `sdd-verify` captures the failure details
- **AND** reports the test execution result as FAILING in the verify-report.md
- **AND** each failing test name is listed if parseable from the output

#### Scenario: Test runner exists but command errors out

- **GIVEN** a detected test runner
- **WHEN** the test command cannot be executed (e.g., missing dependencies, command not found)
- **THEN** `sdd-verify` reports "Test Execution: ERROR -- [error message]" with status WARNING
- **AND** it does NOT block verification (it continues to subsequent steps)

---

### Requirement: Build and type check execution

The `sdd-verify` skill MUST detect and execute the project's build/type-check command, capturing results. Detection MUST use well-known project files and fall back gracefully.

#### Scenario: Build command detected from package.json

- **GIVEN** a project with a `package.json` file containing a `scripts.build` entry
- **WHEN** `sdd-verify` runs the build/type-check step
- **THEN** it executes the build command
- **AND** it captures the exit code (0 = pass, non-zero = failure)

#### Scenario: TypeScript type checking detected

- **GIVEN** a project with a `tsconfig.json` file
- **AND** TypeScript is listed as a devDependency
- **WHEN** `sdd-verify` runs the build/type-check step
- **THEN** it executes `npx tsc --noEmit` (or the equivalent type-check command)
- **AND** it captures any type errors

#### Scenario: No build command detected -- graceful skip

- **GIVEN** a project with no recognizable build configuration
- **WHEN** `sdd-verify` reaches the build/type-check step
- **THEN** it skips build execution
- **AND** it reports "Build/Type Check: SKIPPED -- no build command detected" with status INFO (not WARNING)
- **AND** it does NOT fail the verification

#### Scenario: Build command fails

- **GIVEN** a detected build command
- **WHEN** the build command returns a non-zero exit code
- **THEN** `sdd-verify` reports "Build/Type Check: FAILING" in the verify-report.md
- **AND** error output is included in the detail section

---

### Requirement: Coverage validation (optional, config-driven)

The `sdd-verify` skill MUST support an optional coverage validation step that compares actual test coverage against a configured threshold. This step is ONLY active when a threshold is configured.

#### Scenario: Coverage threshold configured and met

- **GIVEN** `openspec/config.yaml` contains a `coverage_threshold` key (e.g., `coverage_threshold: 80`)
- **AND** the test runner produces coverage output
- **WHEN** `sdd-verify` runs the coverage validation step
- **THEN** it parses the coverage percentage from the output
- **AND** reports "Coverage: [X]% (threshold: [Y]%) -- PASS"

#### Scenario: Coverage threshold configured but not met

- **GIVEN** `openspec/config.yaml` contains `coverage_threshold: 80`
- **AND** the actual coverage is 65%
- **WHEN** `sdd-verify` runs the coverage validation step
- **THEN** it reports "Coverage: 65% (threshold: 80%) -- BELOW THRESHOLD" with status WARNING
- **AND** it does NOT fail the verification (coverage is advisory, not a hard gate)

#### Scenario: No coverage threshold configured -- skip

- **GIVEN** `openspec/config.yaml` does NOT contain a `coverage_threshold` key
- **WHEN** `sdd-verify` reaches the coverage validation step
- **THEN** it skips coverage validation entirely
- **AND** it reports "Coverage Validation: SKIPPED -- no threshold configured"

#### Scenario: Coverage data not parseable

- **GIVEN** a coverage threshold is configured
- **AND** the test runner output does not contain parseable coverage data
- **WHEN** `sdd-verify` runs the coverage validation step
- **THEN** it reports "Coverage Validation: SKIPPED -- could not parse coverage from test output" with status WARNING

---

### Requirement: Spec Compliance Matrix

The `sdd-verify` skill MUST produce a Spec Compliance Matrix that cross-references every Given/When/Then scenario from the change's spec files against the verification evidence. Each scenario MUST receive a compliance status.

#### Scenario: Matrix generated with all scenarios compliant

- **GIVEN** a change with spec files containing 5 Given/When/Then scenarios
- **AND** all scenarios have corresponding test coverage and passing tests
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** the matrix contains 5 rows (one per scenario)
- **AND** each row has columns: Spec Domain, Requirement, Scenario, Status, Evidence
- **AND** all rows have status COMPLIANT

#### Scenario: Matrix includes FAILING status

- **GIVEN** a spec scenario that has a corresponding test
- **AND** that test is failing
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** the scenario row has status FAILING
- **AND** the Evidence column references the failing test name or output

#### Scenario: Matrix includes UNTESTED status

- **GIVEN** a spec scenario that has no corresponding test
- **AND** no test runner was detected OR no test covers this scenario
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** the scenario row has status UNTESTED
- **AND** the Evidence column states "No test coverage found"

#### Scenario: Matrix includes PARTIAL status

- **GIVEN** a spec scenario with multiple THEN/AND clauses
- **AND** code evidence covers some but not all of the expected behaviors
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** the scenario row has status PARTIAL
- **AND** the Evidence column lists which clauses are covered and which are not

#### Scenario: Matrix covers all spec domains

- **GIVEN** a change that affects multiple spec domains (e.g., `sdd-apply-execution` and `sdd-verify-execution`)
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** the matrix includes scenarios from ALL spec domains
- **AND** each row identifies which domain and requirement it belongs to

#### Scenario: Matrix produced even when no test runner exists

- **GIVEN** no test runner was detected in the project
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** the matrix is still produced
- **AND** compliance status is determined from code inspection evidence (not test results)
- **AND** scenarios verified only by code inspection receive status COMPLIANT or PARTIAL (never UNTESTED, since code evidence was checked)

---

### Requirement: Updated verify-report.md template

The `sdd-verify` verify-report.md template MUST include new sections for Build, Test Execution, Coverage, and Spec Compliance Matrix alongside the existing Completeness, Correctness, Coherence, and Testing sections.

#### Scenario: Verify report includes all sections

- **GIVEN** `sdd-verify` has completed all verification steps
- **WHEN** it creates `verify-report.md`
- **THEN** the report includes the following sections in order:
  1. Summary table (with all dimensions including new ones)
  2. Detail: Completeness (Tasks)
  3. Detail: Correctness (Specs)
  4. Detail: Coherence (Design)
  5. Detail: Test Execution (new)
  6. Detail: Build / Type Check (new)
  7. Detail: Coverage Validation (new, if applicable)
  8. Detail: Spec Compliance Matrix (new)
  9. Issues Found (Critical / Warnings / Suggestions)
- **AND** the Summary table has rows for: Completeness, Correctness, Coherence, Testing, Test Execution, Build/Type Check, Coverage (if configured), and Spec Compliance

#### Scenario: Summary table includes new dimension statuses

- **GIVEN** `sdd-verify` has completed verification
- **WHEN** the Summary table is generated
- **THEN** each new dimension (Test Execution, Build/Type Check, Coverage, Spec Compliance) has a status of OK, WARNING, CRITICAL, SKIPPED, or INFO
- **AND** SKIPPED dimensions do NOT count as WARNING or CRITICAL for the verdict

#### Scenario: Verdict calculation unchanged for projects without test infrastructure

- **GIVEN** a project with no test runner, no build command, and no coverage threshold
- **WHEN** `sdd-verify` calculates the verdict
- **THEN** the verdict is based on Completeness, Correctness, Coherence, and Testing (code inspection) only
- **AND** skipped dimensions do NOT produce CRITICAL or WARNING
- **AND** the verdict is identical to what the pre-change sdd-verify would have produced

---

## Rules

- These specs describe observable outcomes only -- not how detection or execution is implemented internally
- All scenarios marked with MUST are non-negotiable for this change to be considered complete
- Test and build execution MUST NOT modify project files -- they are read-only operations (run commands, capture output)
- The Spec Compliance Matrix is always produced, even if test execution was skipped -- it can use code inspection evidence
- Coverage validation is strictly optional and advisory -- it MUST NOT block verification or produce CRITICAL status
- Skipped dimensions (no runner, no build, no coverage config) MUST degrade gracefully without affecting the verdict
