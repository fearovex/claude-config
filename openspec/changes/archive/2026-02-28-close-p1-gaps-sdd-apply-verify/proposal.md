# Proposal: close-p1-gaps-sdd-apply-verify

Date: 2026-02-28
Status: Draft

## Intent

Close the two P1 gaps identified in the Architecture Definition Report by adding TDD mode support to `sdd-apply` and adding build/test execution plus a formal spec compliance matrix to `sdd-verify`.

## Motivation

An architecture comparison against the reference repo (agent-teams-lite v2.0) revealed two Priority-1 gaps in our SDD phase skills:

1. **sdd-apply lacks TDD mode** -- The reference implementation detects TDD conditions (via `openspec/config.yaml` flags, installed testing skills, or existing test patterns) and switches to a RED-GREEN-REFACTOR cycle. Our current sdd-apply only does standard sequential implementation, which means projects with a TDD culture get no special support.

2. **sdd-verify lacks structured build/test execution and spec compliance matrix** -- The reference implementation runs the project test suite, executes build/type-check commands, optionally validates coverage thresholds, and produces a formal Spec Compliance Matrix that cross-references every spec scenario against test results with statuses (COMPLIANT / FAILING / UNTESTED / PARTIAL). Our sdd-verify mentions running tests but has no structured execution flow and no compliance matrix.

These gaps reduce the quality assurance rigor of the SDD pipeline and miss opportunities to leverage existing test infrastructure.

## Scope

### Included
- Add a new Step 2 "Detect Implementation Mode" to `sdd-apply/SKILL.md` that checks for TDD indicators and activates RED-GREEN-REFACTOR cycle when detected
- Add a `tdd` configuration key to the `openspec/config.yaml` schema documentation (optional, opt-in)
- Add Step 4b "Run Tests" to `sdd-verify/SKILL.md` with test runner detection and execution
- Add Step 4c "Build & Type Check" to `sdd-verify/SKILL.md` with build command detection and execution
- Add Step 4d "Coverage Validation" to `sdd-verify/SKILL.md` (optional, config-driven threshold)
- Add Step 5 "Spec Compliance Matrix" to `sdd-verify/SKILL.md` that maps spec scenarios to test results with COMPLIANT/FAILING/UNTESTED/PARTIAL statuses
- Update the verify-report.md template to include Build, Test Execution, and Spec Compliance sections
- Update the `openspec/specs/audit-execution/spec.md` if it references sdd-apply or sdd-verify behaviors

### Excluded (explicitly out of scope)
- Changes to other SDD phase skills (propose, spec, design, tasks, archive) -- not affected
- Adding actual test frameworks or runners -- the skills only detect and invoke what the project already has
- Changes to the orchestrator (CLAUDE.md) -- no new commands or flow changes
- Coverage enforcement as a hard gate -- coverage validation remains optional and advisory
- Changes to `openspec/config.yaml` in this repo beyond documenting the new keys -- this repo uses `audit-as-integration-test`, not a real test runner

## Proposed Approach

**For sdd-apply TDD mode:**
A new Step 2 is inserted between the current Step 1 (Read full context) and Step 2 (Verify work scope), which becomes Step 3. The detection logic checks three sources in order: (1) explicit `tdd: true` in `openspec/config.yaml`, (2) presence of testing skills (playwright, pytest, etc.) in the project CLAUDE.md, (3) existing test file patterns (`*.test.*`, `*.spec.*`, `test_*`). When TDD is detected, Step 3 (Implement task by task) gains a sub-flow: write failing test first (RED), write minimum code to pass (GREEN), refactor while tests stay green (REFACTOR). When TDD is not detected, behavior is identical to current.

**For sdd-verify build/test execution and compliance matrix:**
The current Steps are renumbered. After the existing Step 4 (Coherence Check / Design), three new steps are added: (4b) Run Tests -- detect test runner from package.json/pyproject.toml/Makefile/etc., execute, capture exit code and output; (4c) Build & Type Check -- detect build command, execute, capture results; (4d) Coverage Validation -- if a threshold is configured in openspec/config.yaml, compare actual coverage. Then Step 5 becomes the Spec Compliance Matrix, which cross-references every Given/When/Then scenario from the spec files against the test execution results. The verify-report.md template gains corresponding sections.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-apply/SKILL.md` | Modified | Medium -- new step inserted, existing steps renumbered |
| `skills/sdd-verify/SKILL.md` | Modified | High -- three new steps plus compliance matrix, template changes |
| `openspec/specs/audit-execution/spec.md` | Modified (if needed) | Low -- reference update only |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| TDD detection produces false positives (e.g. test files exist but project does not practice TDD) | Medium | Low | Make TDD mode opt-in by default: only activate on explicit config flag or strong signals (testing skill installed AND test files exist). Document override. |
| Test runner detection fails for uncommon setups | Low | Medium | Use a prioritized list of common runners (npm test, pytest, mix test, ./gradlew test, make test). Fall back gracefully to "no runner detected -- skipping" with a WARNING. |
| Build command detection varies wildly across ecosystems | Medium | Low | Same detection strategy: check well-known files (package.json scripts.build, Makefile, build.gradle, etc.). Skip gracefully if not found. |
| Spec Compliance Matrix is labor-intensive if specs have many scenarios | Low | Low | Matrix is generated per-spec-file, not globally. Each scenario gets one row. The verifier reads test output, not source code. |
| Renumbering steps in sdd-apply could confuse existing tasks.md references | Low | Low | Step numbers in tasks.md refer to the change's tasks, not skill steps. No impact. |

## Rollback Plan

Both skills are single-file changes (`SKILL.md`). Rollback is:

1. `git checkout HEAD~1 -- skills/sdd-apply/SKILL.md skills/sdd-verify/SKILL.md`
2. Run `install.sh` to redeploy
3. Verify with `/project-audit`

Since the changes are additive (new steps, not removal of existing ones), partial rollback is also possible by reverting individual files.

## Dependencies

- No external dependencies -- both skills are self-contained SKILL.md files
- The `openspec/config.yaml` schema changes are optional (new keys with defaults that preserve current behavior)
- No changes required to the orchestrator or other skills

## Success Criteria

- [ ] `sdd-apply/SKILL.md` contains a TDD detection step that checks config, installed skills, and file patterns
- [ ] `sdd-apply/SKILL.md` documents the RED-GREEN-REFACTOR sub-flow for TDD mode
- [ ] `sdd-apply/SKILL.md` preserves identical behavior when TDD is not detected (non-breaking)
- [ ] `sdd-verify/SKILL.md` contains a "Run Tests" step with runner detection and execution
- [ ] `sdd-verify/SKILL.md` contains a "Build & Type Check" step with build command detection
- [ ] `sdd-verify/SKILL.md` contains an optional "Coverage Validation" step
- [ ] `sdd-verify/SKILL.md` contains a "Spec Compliance Matrix" step with COMPLIANT/FAILING/UNTESTED/PARTIAL statuses
- [ ] The verify-report.md template includes sections for Build, Test Execution, and Spec Compliance Matrix
- [ ] `/project-audit` score remains >= previous score after changes
- [ ] Both skills remain functional for projects without test infrastructure (graceful degradation)

## Effort Estimate

Medium (1-2 days) -- two skill files to modify with significant new content, but no code logic, only Markdown instructions.
