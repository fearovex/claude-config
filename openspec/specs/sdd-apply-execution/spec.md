# Spec: sdd-apply-execution

*Created: 2026-02-28 by change "close-p1-gaps-sdd-apply-verify"*

## Overview

This spec describes the observable behavior of the `sdd-apply` skill when detecting and activating TDD mode. It covers the detection logic, the RED-GREEN-REFACTOR cycle, and the graceful fallback when TDD is not detected.

---

## Requirements

### Requirement: TDD mode detection

The `sdd-apply` skill MUST include a step that detects whether the current project supports TDD before beginning implementation. Detection MUST check three sources in priority order: (1) explicit `tdd: true` in `openspec/config.yaml`, (2) presence of testing skills in the project CLAUDE.md, (3) existing test file patterns in the codebase.

#### Scenario: TDD detected via explicit config flag

- **GIVEN** a project where `openspec/config.yaml` contains a top-level key `tdd: true`
- **WHEN** `sdd-apply` executes the TDD detection step
- **THEN** TDD mode is activated
- **AND** the detection step reports "TDD mode: ON (source: config)"

#### Scenario: TDD detected via testing skill in CLAUDE.md

- **GIVEN** a project where `openspec/config.yaml` does NOT contain `tdd: true`
- **AND** the project CLAUDE.md references at least one testing skill (e.g., `playwright`, `pytest`, `vitest`)
- **AND** at least one test file exists matching common patterns (`*.test.*`, `*.spec.*`, `test_*`, `*_test.*`)
- **WHEN** `sdd-apply` executes the TDD detection step
- **THEN** TDD mode is activated
- **AND** the detection step reports "TDD mode: ON (source: testing skill + test files)"

#### Scenario: TDD NOT detected -- testing skill present but no test files

- **GIVEN** a project where `openspec/config.yaml` does NOT contain `tdd: true`
- **AND** the project CLAUDE.md references a testing skill
- **AND** no test files exist matching common patterns
- **WHEN** `sdd-apply` executes the TDD detection step
- **THEN** TDD mode is NOT activated
- **AND** the detection step reports "TDD mode: OFF (testing skill found but no existing test files)"

#### Scenario: TDD NOT detected -- no signals at all

- **GIVEN** a project where `openspec/config.yaml` does NOT contain `tdd: true`
- **AND** the project CLAUDE.md does NOT reference any testing skills
- **AND** no test files exist matching common patterns
- **WHEN** `sdd-apply` executes the TDD detection step
- **THEN** TDD mode is NOT activated
- **AND** the detection step reports "TDD mode: OFF"

#### Scenario: Explicit opt-out overrides file patterns

- **GIVEN** a project where `openspec/config.yaml` contains `tdd: false`
- **AND** test files exist in the codebase
- **WHEN** `sdd-apply` executes the TDD detection step
- **THEN** TDD mode is NOT activated
- **AND** the detection step reports "TDD mode: OFF (explicitly disabled in config)"

---

### Requirement: RED-GREEN-REFACTOR cycle in TDD mode

When TDD mode is active, the `sdd-apply` skill MUST implement each task using the RED-GREEN-REFACTOR sub-flow instead of the standard sequential implementation.

#### Scenario: Task implemented with RED-GREEN-REFACTOR cycle

- **GIVEN** TDD mode is active
- **AND** a task is assigned for implementation
- **WHEN** `sdd-apply` implements the task
- **THEN** it first writes a failing test that captures the expected behavior from the spec scenario (RED)
- **AND** then writes the minimum code to make the test pass (GREEN)
- **AND** then refactors the code while keeping all tests passing (REFACTOR)
- **AND** marks the task as complete in tasks.md only after REFACTOR is done

#### Scenario: Test references spec scenarios

- **GIVEN** TDD mode is active
- **AND** the spec for the affected domain contains Given/When/Then scenarios
- **WHEN** `sdd-apply` writes the failing test (RED phase)
- **THEN** the test SHOULD map to one or more spec scenarios
- **AND** the test name or description SHOULD reference the scenario name

#### Scenario: RED phase failure is expected

- **GIVEN** TDD mode is active and the RED phase test has been written
- **WHEN** `sdd-apply` runs the test
- **THEN** the test MUST fail (confirming the behavior is not yet implemented)
- **AND** if the test passes unexpectedly, `sdd-apply` reports a DEVIATION noting the behavior was already implemented

#### Scenario: GREEN phase -- minimum code only

- **GIVEN** the RED phase test is failing
- **WHEN** `sdd-apply` writes code to make it pass (GREEN phase)
- **THEN** it writes only the minimum code necessary to make the test pass
- **AND** it does NOT add extra features, optimizations, or abstractions in this phase

#### Scenario: REFACTOR phase preserves test status

- **GIVEN** the GREEN phase test is passing
- **WHEN** `sdd-apply` refactors the code (REFACTOR phase)
- **THEN** all tests MUST still pass after refactoring
- **AND** if a test breaks during refactoring, `sdd-apply` fixes the code (not the test) to restore the green state

---

### Requirement: Non-breaking fallback when TDD is not detected

When TDD mode is NOT detected, the `sdd-apply` skill MUST behave identically to its current behavior with no observable differences.

#### Scenario: Standard implementation without TDD

- **GIVEN** TDD mode is NOT active
- **WHEN** `sdd-apply` implements tasks
- **THEN** it follows the existing sequential implementation flow (read task, consult specs, consult design, read existing code, write code, mark complete)
- **AND** no test-first sub-flow is triggered
- **AND** the output format remains unchanged

#### Scenario: TDD detection step produces no side effects

- **GIVEN** TDD mode is NOT active
- **WHEN** the TDD detection step completes
- **THEN** no test files are created
- **AND** no configuration files are modified
- **AND** the only observable effect is the detection report line in the output

---

### Requirement: TDD mode reported in output

The `sdd-apply` output to the orchestrator MUST include a field indicating whether TDD mode was used.

#### Scenario: Output includes TDD mode status

- **GIVEN** `sdd-apply` has completed implementation of assigned tasks
- **WHEN** it produces the output JSON for the orchestrator
- **THEN** the output includes a `"tdd_mode"` field with value `true` or `false`
- **AND** if `true`, the `"summary"` field mentions TDD mode was used

---

## Rules

- These specs describe observable outcomes only -- not how the detection or cycle is implemented internally
- All scenarios marked with MUST are non-negotiable for this change to be considered complete
- Scenarios marked with SHOULD are recommended but acceptable to omit with documented justification
- The TDD detection step MUST NOT install test frameworks -- it only detects what already exists
- The RED-GREEN-REFACTOR cycle applies per-task, not per-phase
