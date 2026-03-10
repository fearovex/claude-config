# Verification Report: sdd-apply-diagnose-first

Date: 2026-03-10
Verifier: sdd-verify

## Summary

| Dimension            | Status       |
| -------------------- | ------------ |
| Completeness (Tasks) | ✅ OK        |
| Correctness (Specs)  | ✅ OK        |
| Coherence (Design)   | ✅ OK        |
| Testing              | ✅ OK        |
| Test Execution       | ⏭️ SKIPPED   |
| Build / Type Check   | ℹ️ INFO       |
| Coverage             | ⏭️ SKIPPED   |
| Spec Compliance      | ✅ OK        |

## Verdict: PASS

---

## Detail: Completeness

### Completeness

| Metric               | Value |
| -------------------- | ----- |
| Total tasks          | 5     |
| Completed tasks [x]  | 5     |
| Incomplete tasks [ ] | 0     |

All 5 tasks marked `[x]` in tasks.md. Progress header reads `## Progress: 5/5 tasks`.

---

## Detail: Correctness

### Correctness (Specs)

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| Mandatory Diagnosis Step before each task implementation | ✅ Implemented | Step 4 in SKILL.md (4.1–4.4) mandates reading files, running commands, writing DIAGNOSIS block before any file change |
| Diagnosis findings that contradict task assumptions trigger MUST_RESOLVE warning | ✅ Implemented | Step 4.4 implements the contradiction check and MUST_RESOLVE block format exactly as specified |
| diagnosis_commands optional key in openspec/config.yaml | ✅ Implemented | Step 1 documents the key; Step 4.2 reads and executes it; config.yaml has the commented example block |

### Scenario Coverage

| Scenario | Status |
| -------- | ------ |
| Diagnosis step runs before any file modification | ✅ Covered — Step 4 is positioned before Step 5 (Implement); the instruction "No file write or edit operation is permitted until the DIAGNOSIS block for that task has been written" enforces the hard gate |
| Hypothesis structure is complete | ✅ Covered — DIAGNOSIS block template in Step 4.3 contains all 5 mandatory fields + Risk field |
| Task with no read-only commands applicable | ✅ Covered — Step 4.1 requires reading pattern-reference files for creation tasks; Step 4.2 explicitly handles absent/inapplicable commands; field 3 describes the gap for new files |
| File changes do not occur before diagnosis is written | ✅ Covered — The gate instruction in Step 4 intro text enforces this invariant |
| Diagnosis reveals contradicting state — warning raised | ✅ Covered — Step 4.4 contains the exact MUST_RESOLVE block format matching the spec |
| Diagnosis confirms expected state — no warning needed | ✅ Covered — Step 4.4 ends with "If diagnosis confirms the expected state, I proceed immediately to Step 5" |
| Multiple contradicting assumptions in one task | ✅ Covered — Step 4.4 states "I MUST list each one as a separate item within the single MUST_RESOLVE block and wait for one combined user confirmation" |
| diagnosis_commands present — commands are run during diagnosis | ✅ Covered — Step 4.2 "Present" branch runs each command and captures output |
| diagnosis_commands absent — step uses auto-detected commands only | ✅ Covered — Step 4.2 "Absent" branch notes "diagnosis_commands: not configured" |
| diagnosis_commands contains a command that fails | ✅ Covered — Step 4.2 states failed commands "MUST NOT block the Diagnosis Step" and failure is noted in Risk field |

---

## Detail: Coherence

### Coherence (Design)

| Decision | Followed? | Notes |
| -------- | --------- | ----- |
| Placement of Diagnosis Step between Step 0 and implementation (Step 5) | ✅ Yes | New Step 4 inserted; old Steps 4–6 renumbered to 5–7 |
| Structured prose DIAGNOSIS block (6 fields: files, commands, current behavior, data/state, hypothesis, risk) | ✅ Yes | Block template in Step 4.3 matches exactly the Interfaces section in design.md |
| MUST_RESOLVE pause mechanism — sub-agent writes warning block and halts until user confirms | ✅ Yes | Step 4.4 implements this; format matches design.md MUST_RESOLVE template |
| diagnosis_commands as optional top-level key in openspec/config.yaml | ✅ Yes | Key documented in Step 1 and in config.yaml; consistent with other optional key documentation conventions |
| Universal applicability — every task including creation tasks | ✅ Yes | Step 4.1 covers creation tasks with "read related files that serve as pattern references" |
| Data flow: Step 0 → Step 1 → Step 2 → Step 3 → NEW Step 4 → Step 5 → Step 6 → Step 7 | ✅ Yes | Renumbering is correct and sequential |

---

## Detail: Testing

### Testing

| Area | Tests Exist | Notes |
| ---- | ----------- | ----- |
| sdd-apply/SKILL.md — Diagnosis Step instructions | N/A | This is a procedural SKILL.md change. No automated test framework applicable. Verification is via skill content inspection against spec scenarios (design.md explicitly states this). |

Design explicitly states: "No automated test framework is applicable — this is a SKILL.md (procedural instructions) change. Verification is done via `/sdd-verify` reviewing the skill against the spec scenarios." Testing dimension is N/A for this change type.

---

## Detail: Test Execution

| Metric        | Value                   |
| ------------- | ----------------------- |
| Runner        | none detected           |
| Command       | N/A                     |
| Exit code     | N/A                     |
| Tests passed  | N/A                     |
| Tests failed  | N/A                     |
| Tests skipped | N/A                     |

No test runner detected (no package.json, pyproject.toml, Makefile, build.gradle, or mix.exs). Skipped.

---

## Detail: Build / Type Check

| Metric    | Value                                        |
| --------- | -------------------------------------------- |
| Command   | N/A                                          |
| Exit code | N/A                                          |
| Errors    | N/A                                          |

No build command detected. This is a documentation-only change (.md and .yaml files). Skipped — INFO.

---

## Spec Compliance Matrix

| Spec Domain | Requirement | Scenario | Status | Evidence |
| ----------- | ----------- | -------- | ------ | -------- |
| sdd-apply | Mandatory Diagnosis Step | Diagnosis step runs before any file modification | COMPLIANT | Step 4 intro: "No file write or edit operation is permitted until the DIAGNOSIS block for that task has been written." Step 4 precedes Step 5 (Implement). |
| sdd-apply | Mandatory Diagnosis Step | Hypothesis structure is complete | COMPLIANT | Step 4.3 DIAGNOSIS block template lists all 5 fields + Risk field exactly matching spec. |
| sdd-apply | Mandatory Diagnosis Step | Task with no read-only commands applicable | COMPLIANT | Step 4.1 covers creation tasks; Step 4.2 absent branch notes "none applicable" / "diagnosis_commands: not configured". |
| sdd-apply | Mandatory Diagnosis Step | File changes do not occur before diagnosis is written | COMPLIANT | Hard gate enforced by instruction ordering and explicit prohibition in Step 4 intro. |
| sdd-apply | MUST_RESOLVE warning for contradictions | Diagnosis reveals contradicting state — warning raised | COMPLIANT | Step 4.4 contains MUST_RESOLVE block format matching spec exactly (emoji, field structure, option lines). |
| sdd-apply | MUST_RESOLVE warning for contradictions | Diagnosis confirms expected state — no warning needed | COMPLIANT | Step 4.4 last sentence: "If diagnosis confirms the expected state, I proceed immediately to Step 5." |
| sdd-apply | MUST_RESOLVE warning for contradictions | Multiple contradicting assumptions in one task | COMPLIANT | Step 4.4: "I MUST list each one as a separate item within the single MUST_RESOLVE block and wait for one combined user confirmation before proceeding." |
| sdd-apply | diagnosis_commands config key | diagnosis_commands present — commands are run during diagnosis | COMPLIANT | Step 4.2 "Present" branch runs each command and captures output for DIAGNOSIS block. |
| sdd-apply | diagnosis_commands config key | diagnosis_commands absent — step uses auto-detected commands only | COMPLIANT | Step 4.2 "Absent" branch documented; config.yaml has commented example block. |
| sdd-apply | diagnosis_commands config key | diagnosis_commands contains a command that fails | COMPLIANT | Step 4.2: failed command "MUST NOT block the Diagnosis Step — I note the failure in the Risk field and continue." |

**Matrix totals:** 10 scenarios — COMPLIANT: 10, FAILING: 0, UNTESTED: 0, PARTIAL: 0

---

## Issues Found

### CRITICAL (must be resolved before archiving):

None.

### WARNINGS (should be resolved):

None.

### SUGGESTIONS (optional improvements):

- The open question in design.md ("Should the Diagnosis Step be skippable via a per-task annotation?") is intentionally deferred. No action required for this change.
