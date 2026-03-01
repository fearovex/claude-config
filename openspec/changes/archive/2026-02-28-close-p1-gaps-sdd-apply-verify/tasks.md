# Task Plan: close-p1-gaps-sdd-apply-verify

Date: 2026-02-28
Design: openspec/changes/close-p1-gaps-sdd-apply-verify/design.md

## Progress: 11/11 tasks

## Phase 1: sdd-apply TDD Mode

- [x] 1.1 Modify `skills/sdd-apply/SKILL.md` — insert new **Step 2 "Detect Implementation Mode"** between current Step 1 and Step 2. Content: three-source TDD detection cascade (1: `openspec/config.yaml` `tdd.enabled`, 2: testing skills in project CLAUDE.md, 3: test file patterns `*.test.*`, `*.spec.*`, `test_*`, `*_test.*`). Require explicit config OR at least 2 heuristic signals. Include detection result reporting ("TDD mode: ON/OFF (source: ...)"). Include explicit opt-out via `tdd: false`. ✓
- [x] 1.2 Modify `skills/sdd-apply/SKILL.md` — renumber current Step 2 to **Step 3 "Verify work scope"**, current Step 3 to **Step 4 "Implement task by task"**, current Step 4 to **Step 5 "Respect the design"**, current Step 5 to **Step 6 "Update progress in tasks.md"**. ✓
- [x] 1.3 Modify `skills/sdd-apply/SKILL.md` — add a **TDD sub-flow** inside Step 4 (renamed from Step 3): conditional block "If TDD mode is active" with RED (write failing test mapping to spec scenario), GREEN (minimum code to pass), REFACTOR (clean up while tests stay green) micro-cycle per task. Keep existing sequential flow as the "If TDD mode is NOT active" branch (unchanged behavior). ✓
- [x] 1.4 Modify `skills/sdd-apply/SKILL.md` — update the **Output to Orchestrator** JSON to include a `"tdd_mode": true|false` field. Update the summary template to mention TDD mode when active. ✓

## Phase 2: sdd-verify Build/Test Execution

- [x] 2.1 Modify `skills/sdd-verify/SKILL.md` — add **Step 6 "Run Tests"** after existing Step 5 (Testing Check). Content: prioritized test runner detection table (`package.json` scripts.test -> `pyproject.toml`/`pytest.ini` -> `Makefile` test target -> `build.gradle`/`gradlew` -> `mix.exs` -> fallback skip with WARNING). Execute via Bash tool, capture exit code + stdout/stderr. Record runner, command, exit code, summary of failures. Handle command error gracefully (WARNING, continue). ✓
- [x] 2.2 Modify `skills/sdd-verify/SKILL.md` — add **Step 7 "Build & Type Check"** after Step 6. Content: prioritized build command detection table (`package.json` scripts.build/scripts.typecheck -> `tsconfig.json` with `npx tsc --noEmit` -> `Makefile` build target -> `build.gradle`/`gradlew build` -> `mix compile` -> skip with INFO). Execute via Bash tool, capture exit code + error output. ✓
- [x] 2.3 Modify `skills/sdd-verify/SKILL.md` — add **Step 8 "Coverage Validation"** (optional) after Step 7. Content: read `openspec/config.yaml` for `coverage.threshold`; if not set, skip entirely; if set, parse coverage from Step 6 output, compare actual vs threshold, report PASS/FAIL (advisory only, never CRITICAL). ✓

## Phase 3: sdd-verify Spec Compliance Matrix and Report Template

- [x] 3.1 Modify `skills/sdd-verify/SKILL.md` — add **Step 9 "Spec Compliance Matrix"** after Step 8. Content: for each spec file in `openspec/changes/<name>/specs/`, for each Given/When/Then scenario, cross-reference against code implementation (Step 3 data) and test results (Step 6 data). Assign status per scenario: COMPLIANT (implemented + test passes), FAILING (implemented + test fails), UNTESTED (implemented + no test), PARTIAL (partially implemented). Output as Markdown table. Produce matrix even when no test runner exists (use code inspection evidence). ✓
- [x] 3.2 Modify `skills/sdd-verify/SKILL.md` — renumber current Step 6 to **Step 10 "Create verify-report.md"** and update the report template to include new sections: "Detail: Test Execution" (runner, command, exit code, pass/fail/skip counts), "Detail: Build / Type Check" (command, exit code, errors), "Detail: Coverage Validation" (threshold, actual, PASS/FAIL — only if configured), "Detail: Spec Compliance Matrix" (the table from Step 9). Update Summary table to include rows for Test Execution, Build/Type Check, Coverage (if configured), and Spec Compliance. Add SKIPPED/INFO statuses that do NOT count as WARNING/CRITICAL for the verdict. Preserve identical verdict for projects without test infrastructure. ✓
- [x] 3.3 Modify `skills/sdd-verify/SKILL.md` — update the **Output to Orchestrator** JSON to include new fields or notes reflecting the additional verification dimensions (test execution result, build result, compliance matrix summary). ✓

## Phase 4: Config Schema Extension

- [x] 4.1 Modify `openspec/config.yaml` — add commented-out `tdd:` block (with `enabled`, `explicit_only` keys) and `coverage:` block (with `threshold`, `tool` keys) following the existing `feature_docs:` and `analysis:` documented pattern. Include explanatory comments consistent with existing style. ✓

---

## Implementation Notes

- All changes are Markdown-only modifications to SKILL.md files and YAML comments in config.yaml. No executable code is introduced.
- Step renumbering in sdd-apply shifts old Steps 2-5 to 3-6. In sdd-verify, new steps are appended as Steps 6-9; only the old Step 6 becomes Step 10.
- TDD detection must degrade gracefully: when no signals are found, behavior is identical to current (non-breaking).
- Test/build execution in sdd-verify must degrade gracefully: SKIPPED dimensions do not affect verdict calculation.
- The Spec Compliance Matrix is always produced regardless of test runner presence.

## Blockers

None.
