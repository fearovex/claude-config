---
name: jira-task
description: >
  Create standardized Jira tasks with proper structure, component splitting, and Jira Wiki markup.
  Trigger: When creating Jira tickets, tasks, or issues for features, bugs, or enhancements.
license: Apache-2.0
metadata:
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When creating Jira tickets, tasks, or issues for features, bugs, or enhancements.

Load when: creating Jira tickets, structuring work items, splitting tasks by component, or using the Jira MCP.

## Critical Patterns

### Rule 1: Split by component

If the change touches API, UI, or SDK → **create separate tasks** per component:
- Enables parallel development
- Assignment by team
- Dependency tracking

```
✅ Feature in API + UI:
  Task 1: [FEATURE] Add user endpoint (API)
  Task 2: [FEATURE] Add user form (UI)

❌ No:
  Task 1: [FEATURE] Add user (API + UI)
```

### Rule 2: Different structure for Bug vs Feature

- **Bug**: Sibling tasks (independent, urgent)
- **Feature**: Parent-child hierarchy (business context above, technical below)

### Rule 3: Jira Wiki Markup (not Markdown)

```
Jira Wiki:          Markdown equivalent:
h2. Title           ## Title
*text*              **text**
* item              - item
|| col1 || col2 ||  | col1 | col2 |
| val1 | val2 |
{code:java}         ```java
...                 ...
{code}              ```
```

## Title Format

```
[TYPE] Description (components)

Types:
  [BUG]         Error in production or development
  [FEATURE]     New functionality
  [ENHANCEMENT] Improvement of existing feature
  [REFACTOR]    Refactoring without behavior change
  [DOCS]        Documentation
  [CHORE]       Maintenance, deps, CI

Components: (API) (UI) (SDK) (API + UI)

Examples:
  [FEATURE] Add user authentication (API)
  [FEATURE] Add login form (UI)
  [BUG] Fix session timeout (API)
  [ENHANCEMENT] Improve search performance (API)
```

## Templates

### Parent Task (Feature — business context)

```
h2. Overview
As a [role], I want [functionality] so that [benefit].

h2. Acceptance Criteria
* The user can [action 1]
* The system [behavior 1]
* When [condition], then [result]

h2. Design
[Link to Figma if applicable]

h2. Notes
[Additional context, decisions, constraints]
```

### Child / Technical Task (API)

```
h2. Description
*Context:* [Link to parent task]

h2. Technical Requirements
* Create POST /api/v1/[resource] endpoint
* Validate input with [schema/validator]
* Return [response format]

h2. Affected Files
* {{src/routes/[file].ts}} — [what changes]
* {{src/services/[file].ts}} — [what changes]
* {{tests/[file].spec.ts}} — [what is added]

h2. Acceptance Criteria
* [ ] Endpoint responds 201 with valid data
* [ ] Returns 400 with invalid input
* [ ] Unit tests pass
* [ ] Integration tests pass

h2. Testing
*Happy path:*
# Send valid request → receive 201
# Verify data in DB

*Edge cases:*
# Invalid input → 400 with descriptive message
# Unauthorized user → 401
```

### Bug Task

```
h2. Current Behavior
[What is currently happening — be specific]

h2. Expected Behavior
[What should happen]

h2. Steps to Reproduce
# Step 1
# Step 2
# Step 3

h2. Environment
* Version: [affected version]
* Browser/OS: [if applicable]

h2. Logs / Evidence
{code}
[stacktrace or relevant logs]
{code}

h2. Affected Files
* {{path/to/file.ts}} — approx. line [N]

h2. Fix Approach
[Description of how it will be resolved]

h2. Testing
* [ ] Bug not reproducible after fix
* [ ] Regression tests added
```

## Jira MCP Fields

```javascript
// Required fields to create a task via MCP
{
  project_key: "PROJECT",       // Jira project key
  issue_type: "Task",
  summary: "[FEATURE] Title (API)",
  description: "...",           // Jira Wiki markup
  priority: "Medium",           // Blocker|Critical|High|Medium|Low

  // Custom fields (verify with your instance):
  // customfield_10359: "UI"    // Team field
}
```

## Priorities

| Priority | Criteria |
|----------|----------|
| Blocker | System down, data at risk, blocks the entire team |
| Critical | Main feature broken, affects majority of users |
| High | Important feature, workaround available |
| Medium | Important improvement, does not block current work |
| Low | Nice-to-have, minor technical debt |

## Anti-Patterns

### ❌ Giant multi-component task

```
[FEATURE] Implement user auth (API + UI + docs + tests)
→ Too large, hard to estimate and assign
```

### ❌ Vague acceptance criteria

```
* Login works ← Not testable
* The user can authenticate successfully ← Also vague

✅ Testable criteria:
* POST /api/auth/login with valid credentials returns 200 + JWT
* POST /api/auth/login with wrong password returns 401
* JWT has 24h expiration
```

### ❌ No file paths

```
* Modify the auth service ← Which one?

✅ With paths:
* Modify {{src/services/auth.service.ts}} — add refreshToken() method

## Rules

- Every task must have a clear Definition of Done — acceptance criteria stated as verifiable conditions, not vague descriptions
- Tasks that require front-end AND back-end changes must be split into separate component tasks linked under the same epic or story
- Use Jira Wiki markup for all task descriptions; plain text without formatting is not acceptable for structured tasks
- Task estimates must be included when the team uses story points or time tracking; estimateless tasks block sprint planning
- Bug tasks must include: steps to reproduce, expected behavior, and actual behavior — missing any of these is an incomplete bug report
```
