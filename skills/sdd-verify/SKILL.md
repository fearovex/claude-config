# sdd-verify

> Verifies that the implementation complies with the specs, design, and task plan.

**Triggers**: sdd:verify, verify implementation, quality gate, validate change, sdd verify

---

## Purpose

Verification is the **quality gate** before archiving. It objectively validates that what was implemented meets what was specified. It fixes nothing — it only reports.

---

## Process

### Step 1 — Load all artifacts

I read:
- `openspec/changes/<change-name>/tasks.md` — what was planned
- `openspec/changes/<change-name>/specs/` — what was required
- `openspec/changes/<change-name>/design.md` — how it was designed
- The code files that were created/modified

### Step 2 — Completeness Check (Tasks)

I count total tasks vs completed tasks:

```markdown
### Completeness
| Metric | Value |
|--------|-------|
| Total tasks | [N] |
| Completed tasks [x] | [M] |
| Incomplete tasks [ ] | [K] |

Incomplete tasks:
- [ ] [number and description of each one]
```

**Severity:**
- Incomplete core logic tasks → CRITICAL
- Incomplete cleanup/docs tasks → WARNING

### Step 3 — Correctness Check (Specs)

For EACH requirement in the spec.md files:

1. I look for evidence in the code that it is implemented
2. For EACH Given/When/Then scenario:
   - Is the GIVEN handled? (precondition/guard)
   - Is the WHEN implemented? (the action/endpoint)
   - Is the THEN verifiable? (the correct result)

```markdown
### Correctness (Specs)
| Requirement | Status | Notes |
|-------------|--------|-------|
| [Req 1] | ✅ Implemented | |
| [Req 2] | ⚠️ Partial | Missing 401 error scenario |
| [Req 3] | ❌ Not implemented | Endpoint /auth/refresh does not exist |

### Scenario Coverage
| Scenario | Status |
|----------|--------|
| Successful login | ✅ Covered |
| Failed login — incorrect password | ✅ Covered |
| Failed login — user does not exist | ⚠️ Partial — implemented but no test |
| Expired token | ❌ Not covered |
```

### Step 4 — Coherence Check (Design)

I verify that the design decisions were followed:

```markdown
### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| Validation with Zod | ✅ Yes | |
| JWT with RS256 | ⚠️ Deviation | HS256 was used. Dev documented it in tasks. |
| Repository pattern | ✅ Yes | |
```

### Step 5 — Testing Check

```markdown
### Testing
| Area | Tests Exist | Scenarios Covered |
|------|-------------|-------------------|
| AuthService.login() | ✅ Yes | 3/4 scenarios |
| AuthController | ✅ Yes | Happy paths only |
| JWT Middleware | ❌ No | — |
```

### Step 6 — Create verify-report.md

I create `openspec/changes/<change-name>/verify-report.md`:

```markdown
# Verification Report: [change-name]

Date: [YYYY-MM-DD]
Verifier: sdd-verify

## Summary

| Dimension | Status |
|-----------|--------|
| Completeness (Tasks) | ✅ OK / ⚠️ WARNING / ❌ CRITICAL |
| Correctness (Specs) | ✅ OK / ⚠️ WARNING / ❌ CRITICAL |
| Coherence (Design) | ✅ OK / ⚠️ WARNING / ❌ CRITICAL |
| Testing | ✅ OK / ⚠️ WARNING / ❌ CRITICAL |

## Verdict: PASS / PASS WITH WARNINGS / FAIL

---

## Detail: Completeness
[tables from step 2]

## Detail: Correctness
[tables from step 3]

## Detail: Coherence
[tables from step 4]

## Detail: Testing
[tables from step 5]

---

## Issues Found

### CRITICAL (must be resolved before archiving):
- [concrete description of the issue]
[or: "None."]

### WARNINGS (should be resolved):
- [description]
[or: "None."]

### SUGGESTIONS (optional improvements):
- [description]
[or: "None."]
```

---

## Verdict Criteria

| Verdict | Condition |
|---------|-----------|
| **PASS** | 0 critical, 0 warnings |
| **PASS WITH WARNINGS** | 0 critical, 1+ warnings |
| **FAIL** | 1+ critical |

---

## Severities

| Severity | Description | Blocks archiving |
|----------|-------------|------------------|
| **CRITICAL** | Requirement not implemented, main scenario not covered, core task incomplete | Yes |
| **WARNING** | Edge case scenario without test, design deviation, pending cleanup task | No |
| **SUGGESTION** | Optional quality improvement | No |

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|failed",
  "summary": "Verification [change-name]: [verdict]. [N] critical, [M] warnings.",
  "artifacts": ["openspec/changes/<name>/verify-report.md"],
  "next_recommended": ["sdd-archive (if PASS or PASS WITH WARNINGS)"],
  "risks": ["CRITICAL: [description if any]"]
}
```

---

## Rules

- I ONLY report — I fix nothing during verification
- I read real code — I do not assume something works just because the file exists
- I am objective: I report what IS, not what should be
- If there are deviations documented in tasks.md, I evaluate them with context
- A FAIL is not personal — it is information for improvement
- I run tests if possible (via Bash tool): I report the actual results
