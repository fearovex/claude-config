# Delta Spec: sdd-tasks — Removal and Replacement Task Generation from Supersedes

Change: 2026-03-19-feedback-sdd-cycle-context-gaps
Date: 2026-03-19
Base: (no base spec — this domain is new)

## ADDED — Task generation from proposal Supersedes section

### Requirement: sdd-tasks generates explicit removal and replacement tasks

When breaking down tasks, `sdd-tasks` MUST read the proposal's `## Supersedes` section and generate explicit tasks for each REMOVED or REPLACED item.

The task generation MUST:
1. For each REMOVED item: create a task titled "Remove: [feature name]" with clear acceptance criteria
2. For each REPLACED item: create a task sequence (Remove old → Implement new)
3. For each CONTRADICTED item: create an optional task for "Coordinate stakeholder impact" or "Execute deprecation announcement"
4. Link each removal/replacement task to the corresponding spec requirement in the delta spec

#### Scenario: Single removal generates one task

- **GIVEN** the proposal Supersedes section states:
  ```
  ### REMOVED
  - **Periodic membership refresh hook** (src/services/membership-refresh.ts)
    Reason: No longer needed; membership sync is now event-driven
  ```
- **WHEN** `sdd-tasks` generates the task breakdown
- **THEN** it MUST create a task:
  ```
  ### Task 1: Remove Periodic Membership Refresh Hook

  **Description**: Delete the periodic membership refresh hook implementation and all references.

  **Files to modify**:
  - src/services/membership-refresh.ts (DELETE)
  - src/hooks/index.ts (remove import and registration)
  - tests/services/membership-refresh.test.ts (DELETE)

  **Acceptance Criteria**:
  - [x] All files containing the hook are removed or cleaned
  - [x] No imports or references remain
  - [x] All tests pass without the hook
  - [x] Git status shows only expected deletions

  **Linked spec**: "Requirement: Event-driven membership sync"
  ```

#### Scenario: Replacement generates remove + add task sequence

- **GIVEN** the proposal states:
  ```
  ### REPLACED
  - **Periodic token refresh polling** (src/auth/token-poller.ts)
    New approach: Event-based refresh with sliding-window expiry
  ```
- **WHEN** `sdd-tasks` breaks down the change
- **THEN** it MUST create tasks in sequence:
  ```
  ### Task 2: Remove Periodic Token Refresh Polling

  **Description**: Delete the old 4-hour polling mechanism.

  **Files affected**: src/auth/token-poller.ts, tests/auth/token-poller.test.ts

  **Acceptance Criteria**: [as above — tokens removed, no references remain]

  ---

  ### Task 3: Implement Event-Based Token Refresh

  **Description**: Implement the new sliding-window expiry and event-driven refresh.

  **Files to create/modify**:
  - src/auth/token-refresh-event.ts (NEW)
  - src/auth/token-manager.ts (MODIFIED)
  - tests/auth/token-refresh-event.test.ts (NEW)

  **Acceptance Criteria**:
  - [x] Event listener properly triggers on auth events
  - [x] Sliding-window logic correctly expires tokens
  - [x] All existing tests pass with the new implementation
  - [x] No references to old polling mechanism remain

  **Linked spec**: "Requirement: Event-based token expiry"
  ```

#### Scenario: Pure addition has no removal tasks

- **GIVEN** the proposal states: "None — purely additive change"
- **WHEN** `sdd-tasks` generates the breakdown
- **THEN** no removal or replacement tasks are created
- **AND** only ADDED spec requirements generate their own implementation tasks

---

## ADDED — Removal task ordering and sequencing

### Requirement: Removal tasks are ordered before replacement or addition tasks

In the task breakdown, `sdd-tasks` MUST sequence removal/replacement tasks before independent addition tasks. The rationale is that removals must complete cleanly before new implementations are added to avoid conflicts.

#### Scenario: Phase 1 tasks are all removal/replacement; Phase 2 is new implementation

- **GIVEN** the change has 2 removals, 1 replacement (with its new implementation), and 3 new features
- **WHEN** `sdd-tasks` breaks down the tasks
- **THEN** tasks.md MUST be organized as:
  ```
  ## Phase 1: Removals and Replacements (MUST complete before Phase 2)
  - Task 1: Remove feature A
  - Task 2: Remove feature B
  - Task 3: Remove old implementation (replacement)

  ## Phase 2: New Implementation (depends on Phase 1)
  - Task 4: Implement new replacement
  - Task 5: Add new feature C
  - Task 6: Add new feature D
  - Task 7: Add new feature E
  ```

#### Scenario: Single removal then multiple additions

- **GIVEN** proposal: 1 REMOVED, 4 ADDED
- **WHEN** `sdd-tasks` sequences tasks
- **THEN** Task 1 is the removal; Tasks 2–5 are the additions

---

## Rules

- Every REMOVED or REPLACED item in the proposal Supersedes section MUST generate at least one task
- Removal tasks MUST include file paths and clear deletion acceptance criteria
- Replacement tasks MUST be sequenced: remove old (Task N), then implement new (Task N+1)
- Removal tasks MUST complete before any Phase 2 tasks can begin (sequential dependency)
- If Supersedes section is missing or empty, no removal tasks are needed (purely additive case)
- Each removal/replacement task MUST reference the affected spec requirement by name
- Removal tasks MAY include an optional "Verify no broken references" acceptance criterion
