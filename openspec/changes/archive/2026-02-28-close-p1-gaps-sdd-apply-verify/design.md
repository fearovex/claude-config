# Technical Design: close-p1-gaps-sdd-apply-verify

Date: 2026-02-28
Proposal: openspec/changes/close-p1-gaps-sdd-apply-verify/proposal.md

## General Approach

Both `sdd-apply/SKILL.md` and `sdd-verify/SKILL.md` are extended with new steps that are inserted into the existing process flow. The new steps are additive: when their preconditions are not met (no TDD config, no test runner found, etc.), they produce a short "skipped" note and the skill behaves identically to today. All detection logic is documented as Markdown instructions that Claude follows at runtime -- no executable code is introduced. The `openspec/config.yaml` schema gains two optional top-level keys (`tdd` and `coverage`) documented as commented-out blocks consistent with the existing `feature_docs:` and `analysis:` patterns.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| TDD detection: three-source cascade | Check (1) `openspec/config.yaml` `tdd: true`, (2) testing skill in CLAUDE.md, (3) test file patterns -- require at least 2 of 3 signals or explicit config | Single-source detection (config only) | Reduces false positives: a project with stale test files but no TDD culture is not forced into TDD mode. Explicit config always wins. |
| TDD step placement in sdd-apply | Insert as new Step 2 between current Steps 1 and 2 (which become 1 and 3) | Append at end; embed inside Step 3 | Placing detection early lets Step 3 (implementation) branch its sub-flow cleanly. Appending would be too late; embedding would make Step 3 overly complex. |
| RED-GREEN-REFACTOR as a sub-flow of Step 3 | Step 3 gains a conditional sub-section: "If TDD mode is active, for each task..." | Separate Step for TDD implementation | The task-by-task loop is the same; only the per-task micro-cycle changes. A separate step would duplicate the loop structure. |
| Test runner detection strategy in sdd-verify | Prioritized lookup table: `package.json` scripts.test -> `pyproject.toml` / `pytest.ini` -> `Makefile` test target -> `build.gradle` test -> `mix.exs` -> fallback "no runner detected" | Auto-detect via `which` commands | File-based detection is deterministic and does not require executing binaries. Consistent with how sdd-apply already reads `openspec/config.yaml` and project files. |
| Build command detection in sdd-verify | Same prioritized lookup: `package.json` scripts.build / scripts.typecheck -> `Makefile` build -> `./gradlew build` -> `mix compile` -> skip | Require explicit config | Most projects have a standard build entry point. Explicit config is available as override via `openspec/config.yaml` but not required. |
| Coverage validation: optional and advisory | Only runs if `coverage.threshold` is set in `openspec/config.yaml`. Reports PASS/FAIL but does not block archiving. | Hard gate; always-on | Proposal explicitly excludes coverage as hard gate. Many projects (including this one) have no coverage tooling. |
| Spec Compliance Matrix placement in sdd-verify | New Step 5 after existing Step 4 (Coherence) and the new test/build steps | Replace existing Step 5 (Testing) | The existing Testing Check (Step 5) is a lightweight table. The new matrix is richer but complementary. We keep the existing Testing Check as Step 5 and add the matrix as Step 6. This avoids losing the simpler testing summary. |
| Step renumbering strategy | Minimal renumbering: insert new steps with letter suffixes where possible, or shift only adjacent steps | Full renumber of all steps | Minimizes diff and reduces confusion for anyone who memorized current step numbers. However, for sdd-apply the insertion as Step 2 necessarily shifts old Step 2->3, 3->4, etc. For sdd-verify, new steps are appended after existing ones without renumbering. |
| Config schema extension | Add `tdd:` and `coverage:` as commented-out blocks in `openspec/config.yaml` following the existing `feature_docs:` and `analysis:` pattern | Separate config file; YAML anchors | Consistency with existing config patterns. Single source of truth. |

## Data Flow

### sdd-apply TDD detection flow

```
Step 1: Read full context
         |
         v
Step 2: Detect Implementation Mode  [NEW]
         |
         +---> Read openspec/config.yaml -> tdd: true?  --yes--> TDD_MODE = true
         |                                    |
         |                                    no
         |                                    v
         +---> Scan CLAUDE.md skills registry for testing skills
         |     (playwright, pytest, etc.)  --found--> signal_count++
         |                                    |
         |                                    v
         +---> Glob for test file patterns
         |     (*.test.*, *.spec.*, test_*)  --found--> signal_count++
         |                                    |
         |                                    v
         +---> signal_count >= 2?  --yes--> TDD_MODE = true
         |                          |
         |                          no --> TDD_MODE = false
         v
Step 3: Verify work scope  (was Step 2)
         |
         v
Step 4: Implement task by task  (was Step 3)
         |
         +---> IF TDD_MODE:
         |       For each task:
         |         1. RED: Write failing test for the task's spec scenario
         |         2. GREEN: Write minimum code to make test pass
         |         3. REFACTOR: Clean up while tests stay green
         |         4. Mark task [x]
         |
         +---> IF NOT TDD_MODE:
         |       For each task:  (existing behavior unchanged)
         |         1-6 as current Step 3
         |
         v
Step 5: Respect the design  (was Step 4)
         |
         v
Step 6: Update progress in tasks.md  (was Step 5)
```

### sdd-verify extended flow

```
Step 1: Load all artifacts           (unchanged)
         |
         v
Step 2: Completeness Check (Tasks)   (unchanged)
         |
         v
Step 3: Correctness Check (Specs)    (unchanged)
         |
         v
Step 4: Coherence Check (Design)     (unchanged)
         |
         v
Step 5: Testing Check                (unchanged -- lightweight summary)
         |
         v
Step 6: Run Tests  [NEW]
         |
         +---> Detect test runner:
         |       package.json scripts.test?  -> npm test / yarn test
         |       pyproject.toml / pytest?    -> pytest
         |       Makefile test target?       -> make test
         |       build.gradle?              -> ./gradlew test
         |       mix.exs?                   -> mix test
         |       none found?                -> skip with NOTE
         |
         +---> Execute via Bash tool, capture exit code + output
         +---> Record: runner, command, exit code, summary of failures
         |
         v
Step 7: Build & Type Check  [NEW]
         |
         +---> Detect build command:
         |       package.json scripts.build?      -> npm run build
         |       package.json scripts.typecheck?   -> npm run typecheck
         |       tsconfig.json?                   -> npx tsc --noEmit
         |       Makefile build target?           -> make build
         |       build.gradle?                    -> ./gradlew build
         |       mix.exs?                         -> mix compile
         |       none found?                      -> skip with NOTE
         |
         +---> Execute via Bash tool, capture exit code + output
         +---> Record: command, exit code, error summary
         |
         v
Step 8: Coverage Validation  [NEW - optional]
         |
         +---> Read openspec/config.yaml -> coverage.threshold?
         |       not set? -> skip entirely (no output)
         |       set?     -> parse coverage output from Step 6
         |                   compare actual vs threshold
         |                   report PASS/FAIL (advisory only)
         |
         v
Step 9: Spec Compliance Matrix  [NEW]
         |
         +---> For each spec file in openspec/changes/<name>/specs/:
         |       For each Given/When/Then scenario:
         |         Cross-reference against:
         |           - Code implementation (Step 3 correctness data)
         |           - Test results (Step 6 output)
         |         Assign status:
         |           COMPLIANT  = implemented + test passes
         |           FAILING    = implemented + test fails
         |           UNTESTED   = implemented + no test
         |           PARTIAL    = partially implemented
         |
         +---> Output as table in verify-report.md
         |
         v
Step 10: Create verify-report.md  (was Step 6, updated template)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-apply/SKILL.md` | Modify | Insert new Step 2 "Detect Implementation Mode" with TDD cascade logic. Add TDD sub-flow to Step 4 (renamed from Step 3). Renumber Steps 2-5 to 3-6. |
| `skills/sdd-verify/SKILL.md` | Modify | Add Steps 6-9 (Run Tests, Build & Type Check, Coverage Validation, Spec Compliance Matrix). Update Step 10 (was Step 6) verify-report.md template to include new sections. Update Output to Orchestrator JSON. |
| `openspec/config.yaml` | Modify | Add commented-out `tdd:` block (with `enabled`, `explicit_only` keys) and `coverage:` block (with `threshold` key) following existing pattern. |

## Interfaces and Contracts

### openspec/config.yaml new keys (all optional, commented out by default)

```yaml
# tdd (optional) — TDD mode configuration for /sdd-apply
# tdd:
#   enabled: true            # explicitly activate TDD mode
#   explicit_only: false     # if true, only activate when enabled: true
#                            # if false (default), also use heuristic detection

# coverage (optional) — Coverage threshold for /sdd-verify
# coverage:
#   threshold: 80            # minimum coverage % (advisory, not blocking)
#   tool: "auto"             # "auto" | "jest" | "pytest-cov" | "c8" | etc.
```

### TDD Mode detection result (internal to sdd-apply, not a file artifact)

```
TDD_MODE: boolean
Detection source: "config" | "heuristic" | "none"
Signals found: list of strings (e.g. ["pytest skill in CLAUDE.md", "test_*.py files found"])
```

### Spec Compliance Matrix format (section in verify-report.md)

```markdown
## Spec Compliance Matrix

| Spec File | Scenario | Implementation | Test | Status |
|-----------|----------|---------------|------|--------|
| specs/auth/spec.md | Login success | Implemented | Passes | COMPLIANT |
| specs/auth/spec.md | Login wrong password | Implemented | Fails | FAILING |
| specs/auth/spec.md | Token refresh | Implemented | None | UNTESTED |
| specs/auth/spec.md | Rate limiting | Partial | None | PARTIAL |
```

### Updated verify-report.md template sections (added after existing Detail sections)

```markdown
## Detail: Test Execution
| Metric | Value |
|--------|-------|
| Runner | [detected runner or "none detected"] |
| Command | [command executed] |
| Exit code | [0/1/N] |
| Tests passed | [N] |
| Tests failed | [N] |
| Tests skipped | [N] |

[If no runner detected: "No test runner detected. Skipped."]

## Detail: Build & Type Check
| Metric | Value |
|--------|-------|
| Command | [command executed] |
| Exit code | [0/1/N] |
| Errors | [count or "none"] |

[If no build command detected: "No build command detected. Skipped."]

## Detail: Coverage
| Metric | Value |
|--------|-------|
| Threshold | [configured %] |
| Actual | [measured %] |
| Result | PASS / FAIL (advisory) |

[If no threshold configured: section omitted entirely]

## Spec Compliance Matrix
[table as defined above]
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Integration | Full SDD cycle with modified skills on a real project | `/project-audit` (audit-as-integration-test) |
| Manual | TDD detection on a project with pytest + test files | Manual invocation of `/sdd-apply` on test project |
| Manual | Verify graceful degradation on project without tests | Manual invocation of `/sdd-verify` on claude-config itself |

## Migration Plan

No data migration required. Both changes are additive Markdown modifications to existing SKILL.md files. The `openspec/config.yaml` changes are commented-out documentation blocks that do not affect current behavior.

## Open Questions

None. The proposal is clear and the existing architecture fully supports the planned changes. All new steps degrade gracefully when their preconditions are not met.
