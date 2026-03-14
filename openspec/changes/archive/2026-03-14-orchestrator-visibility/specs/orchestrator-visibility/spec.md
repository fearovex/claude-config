# Delta Spec: Orchestrator Visibility

Change: 2026-03-14-orchestrator-visibility
Date: 2026-03-14
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — New visibility signal requirements

### Requirement: Session-start orchestrator banner

The orchestrator MUST display a banner at the start of every session informing the user that the SDD Orchestrator is active and intent classification is enabled.

#### Scenario: User sees orchestrator banner on session start

- **GIVEN** a new session has started and the user sends their first message or views the system context
- **WHEN** Claude reads the system prompt (CLAUDE.md)
- **THEN** the orchestrator MUST display a session banner confirming orchestrator is active
- **AND** the banner MUST state that intent classification is enabled and route-ready
- **AND** the banner MUST appear exactly once per session (no repetition in multi-turn conversations)
- **AND** the banner MUST be placed before any response to the first user message

#### Scenario: Banner content includes orchestrator status

- **GIVEN** the orchestrator displays the session banner
- **WHEN** the user reads the banner
- **THEN** the banner MUST include:
  - Confirmation that "SDD Orchestrator is active"
  - Statement that "Intent classification is enabled"
  - Brief explanation of what that means (e.g., "free-form messages will be routed to Change Request, Exploration, or Question pathways")
  - Optional reference to `/orchestrator-status` for on-demand state query

---

### Requirement: Intent classification signal in response preamble

The orchestrator MUST prefix every response to a free-form message with a visible signal indicating which intent class was assigned to that message.

#### Scenario: Change Request shows class signal

- **GIVEN** the user sends a free-form message classified as Change Request (e.g., "fix the login bug")
- **WHEN** the orchestrator responds
- **THEN** the response MUST begin with a signal indicating the class was detected
- **AND** the signal MUST be phrased as: `[ROUTED: Change Request]` or similar clear indicator
- **AND** the signal MUST appear before the main response text
- **AND** the signal MUST NOT be repeated if the user sends follow-up messages in the same conversation turn

#### Scenario: Exploration shows class signal

- **GIVEN** the user sends a free-form message classified as Exploration (e.g., "review the auth module")
- **WHEN** the orchestrator responds
- **THEN** the response MUST begin with a signal: `[ROUTED: Exploration]` (or similar)
- **AND** if the orchestrator launches `sdd-explore` via Task tool, the signal MUST reference this action

#### Scenario: Question shows class signal

- **GIVEN** the user sends a free-form message classified as Question (e.g., "how does intent classification work?")
- **WHEN** the orchestrator responds with a direct answer
- **THEN** the response MUST begin with a signal: `[ROUTED: Question]` (or similar)
- **AND** the signal MUST confirm that the response is being answered directly without SDD routing

#### Scenario: Meta-Command bypasses signal

- **GIVEN** the user sends a message that starts with `/` (a slash command)
- **WHEN** the orchestrator receives the command
- **THEN** the orchestrator MUST NOT include an intent class signal
- **AND** the orchestrator MUST execute the command directly, skipping classification

#### Scenario: Ambiguous message shows fallback signal

- **GIVEN** the user sends a message that is ambiguous or cannot be clearly classified
- **WHEN** the orchestrator applies the default Question classification
- **THEN** the response MUST include a signal: `[ROUTED: Question (default)]` or similar phrasing
- **AND** the response MUST explicitly note that the message was ambiguous and the intent was inferred as Question

---

### Requirement: `/orchestrator-status` skill for on-demand state query

The orchestrator MUST provide a `/orchestrator-status` command that returns the current orchestrator state on demand without modifying any system state.

#### Scenario: User queries orchestrator status

- **GIVEN** the user invokes `/orchestrator-status`
- **WHEN** the orchestrator executes the skill
- **THEN** the skill MUST return a status report within 2 seconds
- **AND** the report MUST NOT require any arguments (skill is invoked bare: `/orchestrator-status`)

#### Scenario: Status report includes classification state

- **GIVEN** `/orchestrator-status` is invoked
- **WHEN** the skill generates its report
- **THEN** the report MUST include:
  - `Orchestrator active: yes|no`
  - `Intent classification: enabled|disabled`
  - List of current active SDD changes (if any) with their paths
  - List of loaded skills categories (SDD phases, meta-tools, tech stack)
  - Timestamp of report generation (ISO 8601 format)

#### Scenario: Status report shows loaded skills

- **GIVEN** the `/orchestrator-status` skill executes
- **WHEN** it queries the skill environment
- **THEN** the report MUST list:
  - Count of SDD phase skills (explore, propose, spec, design, tasks, apply, verify, archive)
  - Count of meta-tool skills (project-*, memory-*, skill-*)
  - Count of technology skills (grouped by category: frontend, backend, testing, tooling)
  - Total skill count

#### Scenario: Status report detects active SDD changes

- **GIVEN** the `/orchestrator-status` skill runs
- **WHEN** it scans `openspec/changes/` for pending, in_progress, or completed changes
- **THEN** the report MUST list:
  - Path to each active change (not archived)
  - Status of each change (from tasks.md or change folder state)
  - Estimated progress (e.g., "3 of 5 phases complete")

#### Scenario: Status report is non-blocking and read-only

- **GIVEN** `/orchestrator-status` is invoked
- **WHEN** the skill executes
- **THEN** it MUST NOT modify any files
- **AND** it MUST NOT trigger any SDD phases or sub-agents
- **AND** it MUST be safe to invoke at any time without side effects

---

## MODIFIED — Update existing requirements from orchestrator-behavior spec

### Requirement: Four intent classes with clear routing rules _(updated to include visibility signals)_

The orchestrator MUST define exactly four intent classes: Change Request, Exploration, Question, and Meta-Command. Classification signals include both explicit keywords and implicit patterns. **As of this change, all classifications MUST be visibly signaled to the user.**

#### Scenario: Change Request classification with signal _(modified)_

- **GIVEN** a user message contains intent keywords: fix, add, implement, create, build, update, refactor, remove, delete, migrate, deploy, or similar action verbs directed at the codebase; **OR** the message contains implicit signals of breakage ("is broken", "doesn't work", "is wrong", "is missing") directed at a named codebase component
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify the intent as Change Request
- **AND** it MUST route to `sdd-ff` recommendation (default) or `sdd-new` recommendation for complex changes
- **AND** it MUST state the inferred slug before asking the user to confirm
- **AND it MUST precede the response with the signal: `[ROUTED: Change Request]`** _(new in this change)_

#### Scenario: Exploration classification with signal _(modified)_

- **GIVEN** a user message contains investigative intent keywords: review, analyze, explore, examine, audit, investigate, "show me", "walk me through", "explain how it works"
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify the intent as Exploration
- **AND** it MUST route to `sdd-explore` sub-agent (via Task tool) or recommend `/sdd-explore <topic>`
- **AND it MUST precede the response with the signal: `[ROUTED: Exploration]`** _(new in this change)_

#### Scenario: Question classification with signal _(modified)_

- **GIVEN** a user message is a question seeking information without requesting a code change (e.g., contains "what is", "how does", "why does", "explain", "describe", or ends with "?")
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly
- **AND it MUST precede the response with the signal: `[ROUTED: Question]`** _(new in this change)_

---

## REMOVED — None

No existing requirements are removed. This change is purely additive to the orchestrator-behavior spec.
