---
name: sdd-spec
description: >
  Writes delta specifications with requirements and Given/When/Then scenarios for a change.
  Trigger: /sdd-spec <change-name>, write specs, functional requirements, specification phase.
---

# sdd-spec

> Writes delta specifications with requirements and Given/When/Then scenarios.

**Triggers**: sdd:spec, write specs, specifications, functional requirements, sdd spec

---

## Purpose

Specs define **WHAT the system must do** from the perspective of observable behavior. They do not say how to implement it. They are the source of truth for verification.

**Key concept — Delta Specs:**
Specs are deltas (changes) on top of what already exists, not full replacements.
- If there is no existing spec: I write a complete spec
- If a spec already exists: I write ADDED/MODIFIED/REMOVED sections

---

## Process

### Step 1 — Read prior artifacts

I must read:
- `openspec/changes/<change-name>/proposal.md` (the WHAT and WHY)
- `openspec/specs/<domain>/spec.md` if it exists (current domain spec)
- `ai-context/architecture.md` if it exists (to understand the current system)

### Step 2 — Identify affected domains

From the proposal I extract the domains that need specs:
- One domain = one coherent functional area (auth, payments, users, notifications, etc.)
- Each domain has its own spec file

### Step 3 — Write delta specs

For each affected domain, I create or update:
`openspec/changes/<change-name>/specs/<domain>/spec.md`

#### If NO existing spec — Full spec:

```markdown
# Spec: [Domain]

Change: [change-name]
Date: [YYYY-MM-DD]

## Requirements

### Requirement: [Descriptive name]
[Description using RFC 2119 keywords]

#### Scenario: [Case name]
- **GIVEN** [precondition — system state]
- **WHEN** [action — what happens]
- **THEN** [observable result — what must happen]
- **AND** [additional result if applicable]

#### Scenario: [Edge case]
- **GIVEN** [...]
- **WHEN** [...]
- **THEN** [...]
```

#### If spec ALREADY EXISTS — Delta:

```markdown
# Delta Spec: [Domain]

Change: [change-name]
Date: [YYYY-MM-DD]
Base: openspec/specs/[domain]/spec.md

## ADDED — New requirements

### Requirement: [Name]
[Description]

#### Scenario: [Name]
- **GIVEN** [...]
- **WHEN** [...]
- **THEN** [...]

## MODIFIED — Modified requirements

### Requirement: [Name of existing requirement]
[New description]
*(Before: [previous description])*

#### Scenario: [Name] *(modified)*
- **GIVEN** [...]
- **WHEN** [...]
- **THEN** [...]

## REMOVED — Removed requirements

### Requirement: [Name]
*(Reason: [why it is being removed])*
```

### RFC 2119 Keywords (required)

| Keyword | Meaning |
|---------|---------|
| **MUST** | Absolute requirement |
| **MUST NOT** | Absolute prohibition |
| **SHOULD** | Recommended (exceptions allowed with justification) |
| **MAY** | Optional |

### Types of scenarios to cover

For each requirement I include:
1. **Happy path**: The normal, successful flow
2. **Edge cases**: Extreme values, empty lists, maximums
3. **Error cases**: What happens when something fails
4. **Security cases**: If applicable (authentication, authorization, permissions)

---

## Examples of well-written scenarios

### Well written
```
#### Scenario: Successful login with valid credentials
- GIVEN that the user exists with email "user@example.com" and the correct password
- WHEN they send POST /auth/login with those credentials
- THEN they receive status 200
- AND they receive a valid JWT in the "token" field
- AND the token expires in 24 hours

#### Scenario: Failed login with incorrect password
- GIVEN that the user exists with email "user@example.com"
- WHEN they send POST /auth/login with an incorrect password
- THEN they receive status 401
- AND the error message does NOT reveal whether the email exists
```

### Poorly written (too vague)
```
#### Scenario: The user can log in
- GIVEN there is a user
- WHEN they log in
- THEN it works
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "summary": "Specs for [change-name]: [N] domains, [M] requirements, [K] scenarios.",
  "artifacts": [
    "openspec/changes/<name>/specs/<domain1>/spec.md",
    "openspec/changes/<name>/specs/<domain2>/spec.md"
  ],
  "next_recommended": ["sdd-tasks (after sdd-design)"],
  "risks": []
}
```

---

## Rules

- Specs describe OBSERVABLE BEHAVIOR, not implementation
- Each requirement MUST have at least 1 scenario (happy path minimum)
- Scenarios MUST be testable and verifiable
- I do NOT include implementation details (that is `sdd-design`)
- I do NOT invent behavior — I base everything on the proposal and existing code
- If something is ambiguous in the proposal, I mark it as `[Pending clarification]` and list it in risks
