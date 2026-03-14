# Spec: Orchestrator Always-On Behavior

Change: 2026-03-12-orchestrator-always-on
Date: 2026-03-12

## Requirements

### Requirement: Intent classification before every response

The orchestrator MUST classify the user's intent before generating any response to a free-form message.

#### Scenario: Change request triggers SDD recommendation

- **GIVEN** a session is active and the user sends a free-form message containing change intent (e.g., "fix this bug", "add feature X", "implement Y")
- **WHEN** the orchestrator receives the message
- **THEN** it MUST NOT write implementation code, specs, or designs inline
- **AND** it MUST recommend the appropriate SDD command (`/sdd-ff <slug>` for most cases) or launch `sdd-explore` via Task tool

#### Scenario: Exploration request routes to sdd-explore

- **GIVEN** the user sends a message that is a review, investigation, or explanation request ("review this code", "analyze this module", "explore how X works")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration
- **AND** it MUST either launch `sdd-explore` via Task tool or recommend `/sdd-explore <topic>` to the user
- **AND** it MUST NOT write a direct analysis response if the analysis involves producing change-related artifacts

#### Scenario: Direct question is answered inline

- **GIVEN** the user asks a question seeking factual or conceptual information ("what does this function do?", "explain this pattern", "how does X work?")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly without routing to an SDD phase
- **AND** it MUST NOT suggest an SDD command for pure information requests

#### Scenario: Slash command is executed normally

- **GIVEN** the user sends a message that begins with a slash command (`/sdd-ff`, `/project-audit`, etc.)
- **WHEN** the orchestrator receives the message
- **THEN** it MUST execute the command as defined in the "How I Execute Commands" section
- **AND** it MUST NOT re-classify the intent — slash commands bypass the classification step

---

### Requirement: Four intent classes with clear routing rules _(extended — 2026-03-14; visibility signals added — 2026-03-14)_

The orchestrator MUST define exactly four intent classes: Change Request, Exploration, Question, and Meta-Command. Classification signals include both explicit keywords and implicit patterns. **All classifications MUST be visibly signaled to the user via a response preamble.**

#### Scenario: Change Request classification with signal _(modified 2026-03-14)_

- **GIVEN** a user message contains intent keywords: fix, add, implement, create, build, update, refactor, remove, delete, migrate, deploy, or similar action verbs directed at the codebase; **OR** the message contains implicit signals of breakage ("is broken", "doesn't work", "is wrong", "is missing") directed at a named codebase component
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify the intent as Change Request
- **AND** it MUST route to `sdd-ff` recommendation (default) or `sdd-new` recommendation for complex changes
- **AND** it MUST state the inferred slug before asking the user to confirm
- **AND** it MUST precede the response with the signal: `**Intent classification: Change Request**` _(added 2026-03-14)_

#### Scenario: Exploration classification with signal _(modified 2026-03-14)_

- **GIVEN** a user message contains investigative intent keywords: review, analyze, explore, examine, audit, investigate, "show me", "walk me through", "explain how it works"
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify the intent as Exploration
- **AND** it MUST route to `sdd-explore` sub-agent (via Task tool) or recommend `/sdd-explore <topic>`
- **AND** it MUST precede the response with the signal: `**Intent classification: Exploration**` _(added 2026-03-14)_

#### Scenario: Question classification with signal _(modified 2026-03-14)_

- **GIVEN** a user message is a question seeking information without requesting a code change (e.g., contains "what is", "how does", "why does", "explain", "describe", or ends with "?")
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly
- **AND** it MUST precede the response with the signal: `**Intent classification: Question**` _(added 2026-03-14)_

#### Scenario: Meta-Command classification

- **GIVEN** a user message starts with `/` followed by a known command name
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify it as Meta-Command
- **AND** it MUST skip intent classification and execute the command immediately

---

### Requirement: Orchestrator never writes implementation code inline

The orchestrator MUST NOT produce implementation code, delta specs, or design artifacts directly in conversation context.

#### Scenario: Change request results in SDD delegation, not inline code

- **GIVEN** the user says "fix the login bug" (a Change Request)
- **WHEN** the orchestrator responds
- **THEN** it MUST NOT write code in the response
- **AND** it MUST recommend `/sdd-ff fix-login-bug` or launch `sdd-explore` + `sdd-propose` via Task tool
- **AND** the response MUST explain why SDD discipline applies

#### Scenario: Sub-agent writes the code, not the orchestrator

- **GIVEN** the user has approved running `/sdd-apply`
- **WHEN** the orchestrator delegates implementation to a sub-agent via Task tool
- **THEN** the sub-agent (spawned via Task tool) writes all code
- **AND** the orchestrator MUST only relay the sub-agent's summary and artifact list

#### Scenario: Edge case — clarification question for ambiguous intent

- **GIVEN** a user message is ambiguous ("help with X", "do something about Y")
- **WHEN** the orchestrator cannot determine intent class with confidence
- **THEN** it MUST ask one clarifying question: "Is this a change request or a question?"
- **AND** it MUST NOT generate code or SDD artifacts before the user confirms intent

---

### Requirement: CLAUDE.md documents the Always-On Orchestrator behavior

CLAUDE.md MUST contain a dedicated section that defines intent classification rules, the four intent classes, and the routing table.

#### Scenario: Section exists and is findable

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Always-On Orchestrator" or "Intent Classification"
- **THEN** they MUST find a section with that heading
- **AND** the section MUST contain the four intent classes and their routing actions
- **AND** the section MUST state the "never inline code" rule

#### Scenario: CLAUDE.md updated in global and project files

- **GIVEN** the change is applied
- **WHEN** `install.sh` is run
- **THEN** the updated CLAUDE.md MUST be deployed to `~/.claude/CLAUDE.md`
- **AND** the behavior MUST apply to all projects that use the global CLAUDE.md without modification

---

### Requirement: Project-level CLAUDE.md can override intent classification

A project-local CLAUDE.md MUST be able to disable or refine the global intent classification behavior.

#### Scenario: Project disables always-on classification

- **GIVEN** a project has a `.claude/CLAUDE.md` that explicitly disables intent classification
- **WHEN** the user sends a free-form change request in that project
- **THEN** the orchestrator MUST NOT apply intent classification
- **AND** it MAY respond directly as per the project-level instructions

#### Scenario: Project restricts classification to specific intent classes

- **GIVEN** a project configures intent classification to only route Change Requests (not Explorations)
- **WHEN** the user sends an exploration message in that project
- **THEN** the orchestrator MUST answer directly without routing to `sdd-explore`

---

---

### Requirement: Implicit change intent MUST be classified as Change Request _(added 2026-03-14)_

When a user message implies that something is broken or needs to be fixed without using explicit change-intent verbs, the orchestrator MUST still classify the message as a Change Request.

#### Scenario: Implicit change intent — broken behavior statement

- **GIVEN** the user sends a message such as "the login is broken" (no explicit verb like "fix")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request (not Question)
- **AND** it MUST recommend `/sdd-ff fix-login` (or a contextually appropriate slug)
- **AND** it MUST NOT answer the message as a factual question

#### Scenario: Implicit change intent — complaint without verb

- **GIVEN** the user sends "the payment flow is completely wrong"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request
- **AND** it MUST recommend the appropriate SDD command

#### Scenario: Implicit change intent — absence statement

- **GIVEN** the user sends "the retry logic is missing"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request

#### Scenario: Implicit change intent — broken behavior after a change

- **GIVEN** the user sends "tests are failing after my last change"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request

---

### Requirement: Investigative phrasing MUST be classified as Exploration _(added 2026-03-14)_

When a user message uses investigative verbs ("check", "look at", "go through") directed at understanding — not mutating — the system, the orchestrator MUST classify it as Exploration.

#### Scenario: "Check" verb without mutation intent

- **GIVEN** the user sends "check the auth module"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration
- **AND** it MUST launch `sdd-explore` via Task tool or recommend `/sdd-explore`

#### Scenario: "Look at" phrasing

- **GIVEN** the user sends "look at the payment flow"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration

#### Scenario: "Go through" phrasing

- **GIVEN** the user sends "go through the retry logic"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration

---

### Requirement: Questions about broken behavior MUST remain Question _(added 2026-03-14)_

A message that ends with "?" or uses question phrasing MUST be classified as Question even when it references broken or incorrect behavior.

#### Scenario: "Why does X fail?" — remains a Question

- **GIVEN** the user sends "why does login fail?"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly without routing to an SDD phase

#### Scenario: "What's wrong with X?" — Question

- **GIVEN** the user sends "what's wrong with the retry logic?"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question

#### Scenario: "Is X broken?" — Question, not Change Request

- **GIVEN** the user sends "is the payment system broken?"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question

---

### Requirement: Ambiguous single-word messages MUST default to Question _(added 2026-03-14)_

A message with a single word that does not contain an explicit intent verb or punctuation MUST be classified as Question (the default ambiguous class).

#### Scenario: Single-word noun — defaults to Question

- **GIVEN** the user sends only "login"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question (default ambiguous)
- **AND** it MUST append: "If you'd like me to implement this, I can start with `/sdd-ff <slug>`."

#### Scenario: Single-word verb with no target

- **GIVEN** the user sends only "refactor"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question (default ambiguous)
- **AND** it MUST ask: "What would you like me to refactor?"

#### Scenario: Ambiguous acronym or label

- **GIVEN** the user sends only "auth"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question (default ambiguous)

---

### Requirement: Compound messages MUST use the highest-priority class _(added 2026-03-14)_

When a single message contains signals for more than one intent class, the orchestrator MUST select the highest-priority class using: Change Request > Exploration > Question.

#### Scenario: "Fix and explain" — Change Request wins

- **GIVEN** the user sends "fix the auth bug and explain why it broke"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request
- **AND** it MUST recommend the SDD command first

#### Scenario: "Analyze and update" — Change Request wins

- **GIVEN** the user sends "analyze the retry module and update the timeout values"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request

---

### Requirement: Decision table contains at least 10 edge case examples _(added 2026-03-14)_

The CLAUDE.md Classification Decision Table MUST contain at least 10 edge case examples covering all four edge case categories (implicit change intent, investigative phrasing, question with broken behavior, single-word input), with at least 2 examples per category.

---

---

### Requirement: Session-start orchestrator banner _(added 2026-03-14)_

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

_(Modified in: 2026-03-14 by change "orchestrator-visibility")_

---

### Requirement: Intent classification signal in response preamble _(added 2026-03-14)_

The orchestrator MUST prefix every response to a free-form message with a visible signal indicating which intent class was assigned to that message.

#### Scenario: Meta-Command bypasses signal

- **GIVEN** the user sends a message that starts with `/` (a slash command)
- **WHEN** the orchestrator receives the command
- **THEN** the orchestrator MUST NOT include an intent class signal
- **AND** the orchestrator MUST execute the command directly, skipping classification

#### Scenario: Ambiguous message shows fallback signal

- **GIVEN** the user sends a message that is ambiguous or cannot be clearly classified
- **WHEN** the orchestrator applies the default Question classification
- **THEN** the response MUST include a signal: `**Intent classification: Question (default)**` or similar phrasing
- **AND** the response MUST explicitly note that the message was ambiguous and the intent was inferred as Question

_(Modified in: 2026-03-14 by change "orchestrator-visibility")_

---

### Requirement: `/orchestrator-status` skill for on-demand state query _(added 2026-03-14)_

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

_(Modified in: 2026-03-14 by change "orchestrator-visibility")_

---

## Validation Criteria

- [ ] CLAUDE.md contains a dedicated "Always-On Orchestrator" section
- [ ] Four intent classes (Change Request, Exploration, Question, Meta-Command) are defined and documented
- [ ] Routing table maps each intent class to the correct action
- [ ] "Never write implementation code inline" rule is stated explicitly in the section
- [ ] Slash commands bypass classification and execute directly
- [ ] Questions are answered directly without SDD routing
- [ ] Project CLAUDE.md override mechanism is described
- [ ] Section is positioned in CLAUDE.md such that it is loaded at session start
- [x] Decision table contains at least 10 edge case examples (≥2 per category) — added 2026-03-14
- [x] Implicit change intent signals ("is broken", "doesn't work", "is wrong", "is missing") included in Change Request triggers — added 2026-03-14
- [x] "Check", "look at", "go through" classified as Exploration — added 2026-03-14
- [x] Questions about broken behavior ("why does X fail?", "is X broken?") classified as Question — added 2026-03-14
- [x] Single-word / no-target inputs default to Question — added 2026-03-14
- [x] Compound messages use highest-priority class (Change Request > Exploration > Question) — added 2026-03-14
- [x] Session-start banner added to CLAUDE.md confirming orchestrator is active — added 2026-03-14
- [x] Intent classification signal (`**Intent classification: <Class>**`) injected in response preamble for all free-form messages — added 2026-03-14
- [x] `/orchestrator-status` skill created and registered — added 2026-03-14
