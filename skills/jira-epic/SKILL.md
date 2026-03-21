---
name: jira-epic
description: >
  Create Jira epics for large features with overview, requirements, technical diagram, and task decomposition.
  Trigger: When creating Jira epics, planning large features, or structuring work spanning multiple components.
license: Apache-2.0
metadata:
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When creating Jira epics, planning large features, or structuring work spanning multiple components.

Load when: creating Jira epics for large features, planning work that spans multiple sprints or components, or decomposing epics into tasks.

## When to create an Epic vs a Task

| Create Epic | Create Task directly |
|-------------|---------------------|
| Feature spanning multiple sprints | Feature taking 1-2 days |
| Requires work in API + UI + SDK | Work in a single component |
| Entire new page of the app | Small improvement to existing feature |
| Major architectural refactor | Bug fix or minor tweak |

## Epic Title Format

```
[EPIC] Feature Name

Examples:
  [EPIC] User Authentication System
  [EPIC] Analytics Dashboard
  [EPIC] Multi-tenant Support
  [EPIC] Payment Integration
```

## Epic Template

```
h2. Overview

*What:* [What this feature does in one sentence]
*Who:* [For which users/roles]
*Why:* [What problem it solves or what value it provides]

h2. Goals
* [Measurable goal 1]
* [Measurable goal 2]
* [Measurable goal 3]

h2. Out of Scope
* [What this epic explicitly does NOT include]
* [What is left for a future epic]

h2. Requirements

h3. Functional Requirements
* [FR-01] [Functional requirement 1]
* [FR-02] [Functional requirement 2]
* [FR-03] [Functional requirement 3]

h3. Non-Functional Requirements
* Performance: [e.g.: API < 200ms p95]
* Security: [e.g.: authentication required on all endpoints]
* Scalability: [e.g.: support N concurrent users]

h2. Technical Considerations

h3. Architecture
[Description of the architectural approach]

h3. Data Model Changes
[New tables, fields, relationships if applicable]

h3. API Changes
[New endpoints, changes to existing ones]

h3. UI Components
[New pages, main components]

h2. Diagram

{code}
[ASCII diagram of the main flow or architecture]

Example:
User → Login Page → POST /api/auth/login
                         ↓
                    Validate credentials
                         ↓
                    Generate JWT + Refresh Token
                         ↓
                    Redirect → Dashboard
{code}

h2. Implementation Plan

h3. Phase 1: Foundation
* [ ] [Technical task 1] — (API)
* [ ] [Technical task 2] — (API)

h3. Phase 2: Core Features
* [ ] [Technical task 3] — (UI)
* [ ] [Technical task 4] — (UI)

h3. Phase 3: Integration & Polish
* [ ] [Technical task 5] — (API + UI)
* [ ] [Technical task 6]

h2. Acceptance Criteria
* [ ] [Measurable success criterion 1]
* [ ] [Measurable success criterion 2]
* [ ] [Measurable success criterion 3]

h2. Dependencies
* [External or internal dependency that blocks the start]

h2. Links
* Figma: [link if available]
* Design doc: [link if available]
* Related epics: [links]
```

## Task Decomposition

Once the epic is created, decompose it into tasks using the `jira-task` skill:

```
Epic: [EPIC] User Authentication System
  ↓
Tasks:
  [FEATURE] Add User model and repository (API)
  [FEATURE] Add login endpoint (API)
  [FEATURE] Add JWT middleware (API)
  [FEATURE] Add refresh token endpoint (API)
  [FEATURE] Add login page (UI)
  [FEATURE] Add protected route wrapper (UI)
  [FEATURE] Add auth state management (UI)
  [FEATURE] Add E2E auth tests (UI)
```

Decomposition rules:
- Each task <= 2 days of work
- Split by component (API/UI/SDK)
- Order respects technical dependencies
- Tasks in the same phase can be parallel

## Jira MCP Fields for Epic

```javascript
{
  project_key: "PROJECT",
  issue_type: "Epic",
  summary: "[EPIC] Feature Name",
  description: "...",           // Jira Wiki markup
  priority: "High",
  // epic_name: "Feature Name"  // Epic-specific field in Jira
}
```

## Mermaid Diagrams (if the project supports them)

```
// Data flow
sequenceDiagram
    User->>+Browser: Enter credentials
    Browser->>+API: POST /auth/login
    API->>+DB: Validate user
    DB-->>-API: User found
    API-->>-Browser: JWT token
    Browser-->>-User: Redirect to dashboard

// Architecture
graph TD
    A[React App] --> B[Auth Context]
    B --> C[API Client]
    C --> D[/api/auth/login]
    C --> E[/api/auth/refresh]
    D --> F[(Database)]
    E --> F
```

## Anti-Patterns

### ❌ Epic without out of scope

```
No "Out of Scope" → inevitable scope creep
→ Always explicitly define what does NOT belong
```

### ❌ Tasks too large in the epic

```
❌ [FEATURE] Implement entire auth system (API + UI) ← Single task
✅ Split into 6-8 specific tasks per component
```

### ❌ Vague criteria

```
❌ "The auth system works"
✅ "User can log in with email/password and receives a JWT with 24h expiration"

## Rules

- Epics must include a high-level overview, acceptance criteria, and a task decomposition section — an epic with only a title is incomplete
- Technical diagrams (architecture, flow, component) are required for epics that span multiple system components
- Each epic must be decomposable into independently deliverable Jira tasks before it is considered ready for development
- Epic scope must be bounded — if the description spans more than one business domain, split into separate epics
- Use Jira Wiki markup syntax when formatting epic descriptions to ensure correct rendering in Jira
```
