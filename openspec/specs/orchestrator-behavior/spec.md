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

#### Scenario: Direct question is answered inline _(modified — 2026-03-19 by change "feedback-sdd-cycle-context-gaps-p6")_

- **GIVEN** the user asks a question seeking factual or conceptual information ("what does this function do?", "explain this pattern", "how does X work?")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly without routing to an SDD phase
- **AND** it MUST NOT suggest an SDD command for pure information requests
- **AND** if the project has `openspec/specs/index.yaml`, the orchestrator MUST first check for matching specs and read them (see "Spec-first Q&A for Questions about project domains" requirement) — then MUST use the spec as the authoritative source for the answer
_(This modification clarifies that spec reading is now part of the Question pathway, not a separate phase.)_

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

### Requirement: Ambiguous single-word messages MUST trigger clarification gate _(modified 2026-03-14 by change "add-clarification-gate-for-ambiguous-inputs")_

A message with a single word that does not contain an explicit intent verb or punctuation MUST trigger a clarification gate UNLESS the word is a natural response (yes, no, etc.) or ends with punctuation.

_(Before: "MUST be classified as Question (the default ambiguous class)")_

#### Scenario: Single-word noun — triggers clarification (modified)

- **GIVEN** the user sends only "login"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST trigger the clarification gate, NOT immediately default to Question
- **AND** the gate MUST ask: "Is this a change request, exploration, or question?"
- **THEN** the user MUST respond before routing proceeds

#### Scenario: Single-word verb with no target (modified)

- **GIVEN** the user sends only "refactor"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST trigger the clarification gate
- **AND** it MUST NOT ask "What would you like me to refactor?" (too directive)
- **AND** it MUST offer three equally-weighted options (Change Request, Exploration, Question)

#### Scenario: Ambiguous acronym or label (modified)

- **GIVEN** the user sends only "auth"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST trigger the clarification gate
- **AND** the gate MUST NOT default to Question

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

### Requirement: Ambiguous input detection and clarification gate _(added 2026-03-14 by change "add-clarification-gate-for-ambiguous-inputs")_

The orchestrator MUST detect ambiguous inputs and present a **clarification gate** before defaulting to Question classification. An ambiguous input is one that lacks a clear action verb or target and could reasonably map to Change Request, Exploration, or Question.

#### Scenario: Single-word ambiguous noun triggers clarification

- **GIVEN** the user sends only "auth" (a single word with no action verb)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST detect the ambiguity
- **AND** it MUST NOT immediately default to Question
- **AND** it MUST present a clarification prompt before routing
- **AND** the prompt MUST offer three options aligned to Change Request, Exploration, and Question
- **THEN** the user MUST respond with 1, 2, 3, or clarify in their own words
- **AND** the orchestrator MUST then route to the selected intent class

#### Scenario: Single-word verb with no target triggers clarification

- **GIVEN** the user sends only "refactor"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST detect that this is a change verb but lacks a target ("refactor what?")
- **AND** it MUST present the clarification prompt with three options
- **THEN** the user response is routed to the selected intent class

#### Scenario: Ambiguous phrase with weak intent signal triggers clarification

- **GIVEN** the user sends "improve the system" (vague object, no clear scope)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST detect the vagueness
- **AND** it MUST present a clarification prompt
- **THEN** the user response determines the route

#### Scenario: Non-ambiguous inputs bypass the gate

- **GIVEN** the user sends "fix the login bug" (explicit action verb + clear target)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST route directly to Change Request

#### Scenario: Explicit questions bypass the gate

- **GIVEN** the user sends "what is auth?" (ends with ?, contains "what is" pattern)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST route directly to Question

---

### Requirement: Clarification prompt structure _(added 2026-03-14 by change "add-clarification-gate-for-ambiguous-inputs")_

The clarification prompt MUST present exactly three options corresponding to the three most common intent interpretations: Change Request, Exploration, and Question.

#### Scenario: Prompt format and content

- **GIVEN** the orchestrator has detected an ambiguous input and decided to present a clarification
- **WHEN** the prompt is displayed
- **THEN** it MUST include:
  - A summary of what was ambiguous (e.g., "I'm not sure what you'd like me to do with 'auth'")
  - Three numbered options:
    1. Change Request interpretation (e.g., "Refactor/fix some specific code (change request)")
    2. Exploration interpretation (e.g., "Explore/review auth patterns in the codebase (exploration)")
    3. Question interpretation (e.g., "Learn what auth is/how it works (question)")
  - An instruction: "Just reply with 1, 2, 3, or clarify in your own words."
- **AND** the prompt MUST be phrased in natural language (not a menu format)
- **AND** each option MUST be on its own line for readability

#### Scenario: Option 1 — Change Request context

- **GIVEN** the clarification prompt is displayed for an ambiguous verb like "refactor"
- **WHEN** Option 1 is shown
- **THEN** it MUST frame the Change Request interpretation contextually:
  - "Refactor some specific code" OR "Fix/improve a specific part of the system"
  - MUST include "(change request)" label

#### Scenario: Option 2 — Exploration context

- **GIVEN** the clarification prompt is displayed
- **WHEN** Option 2 is shown
- **THEN** it MUST frame the Exploration interpretation:
  - "Explore/review [the thing] in the codebase" OR "Show me how [the thing] works"
  - MUST include "(exploration)" label

#### Scenario: Option 3 — Question context

- **GIVEN** the clarification prompt is displayed
- **WHEN** Option 3 is shown
- **THEN** it MUST frame the Question interpretation:
  - "Learn what [the thing] is" OR "Understand how [the thing] works"
  - MUST include "(question)" label

---

### Requirement: Routing after clarification response _(added 2026-03-14 by change "add-clarification-gate-for-ambiguous-inputs")_

After the user responds to a clarification prompt, the orchestrator MUST route to the selected intent class with the same behavior as if the original message had contained that intent.

#### Scenario: User selects Change Request (option 1)

- **GIVEN** the user responds to a clarification prompt with "1" (or clarifies as a change request)
- **WHEN** the orchestrator processes the response
- **THEN** it MUST treat the original input as a Change Request
- **AND** it MUST recommend `/sdd-ff <inferred-slug>` or `/sdd-new` as appropriate
- **AND** it MUST infer the slug from the original ambiguous input + context

#### Scenario: User selects Exploration (option 2)

- **GIVEN** the user responds to a clarification prompt with "2" (or clarifies as exploration)
- **WHEN** the orchestrator processes the response
- **THEN** it MUST treat the original input as Exploration
- **AND** it MUST launch `sdd-explore` via Task tool or recommend `/sdd-explore <topic>`

#### Scenario: User selects Question (option 3)

- **GIVEN** the user responds to a clarification prompt with "3" (or clarifies as a question)
- **WHEN** the orchestrator processes the response
- **THEN** it MUST treat the original input as Question
- **AND** it MUST answer directly with factual/conceptual information about the topic

#### Scenario: User provides custom clarification

- **GIVEN** the user responds to a clarification prompt with their own clarification (not 1, 2, or 3)
- **WHEN** the orchestrator processes the custom text
- **THEN** it MUST apply the standard intent classification rules to the clarification
- **AND** it MUST route based on the standard classification of that text
- **AND** the response MUST acknowledge the clarification before routing

---

### Requirement: Ambiguity detection heuristics _(added 2026-03-14 by change "add-clarification-gate-for-ambiguous-inputs")_

The orchestrator MUST define clear heuristics for when to trigger the clarification gate. An input is ambiguous if it matches one or more of these patterns:

1. **Single-word input** — exactly one word with no punctuation or modifiers
   - Examples: "auth", "login", "refactor", "help"
   - Exception: single-word inputs that are obviously part of a complete thought ("yes", "no", "true", "false") are NOT ambiguous

2. **Standalone action verb with no object** — a verb from the change verb list ("refactor", "fix", "improve") with no clear target
   - Examples: "refactor", "fix", "improve"
   - Exception: "refactor everything" has an object, so it is NOT ambiguous

3. **Vague noun phrase** — a phrase that references something but provides no context or verb
   - Examples: "the system", "the flow", "the layer"
   - Criterion: phrase length ≤ 4 words AND no action verb present

4. **Compound phrase with weak binding** — a phrase where multiple interpretations are equally plausible
   - Examples: "help with X", "something about Y", "deal with Z"
   - Criterion: contains "with", "about", "deal with", "look into" without a clear intent verb ("fix", "review", "understand")

#### Scenario: Detection accuracy — single-word nouns

- **GIVEN** the user sends "auth"
- **WHEN** the orchestrator applies heuristic 1
- **THEN** it MUST classify as ambiguous

#### Scenario: Detection accuracy — standalone verbs

- **GIVEN** the user sends "refactor"
- **WHEN** the orchestrator applies heuristic 2
- **THEN** it MUST classify as ambiguous

#### Scenario: Non-ambiguous single-word cases are excluded

- **GIVEN** the user sends "yes" or "help" (a natural response word)
- **WHEN** the orchestrator applies heuristics
- **THEN** it MUST NOT classify as ambiguous (these are contextual responses, not change intent)

#### Scenario: Phrases with objects are not ambiguous

- **GIVEN** the user sends "refactor the auth module"
- **WHEN** the orchestrator applies heuristics
- **THEN** it MUST NOT classify as ambiguous (has clear action verb + object)

---

### Requirement: Clarification gate does not interfere with slash commands or strong signals _(added 2026-03-14 by change "add-clarification-gate-for-ambiguous-inputs")_

The clarification gate MUST NOT activate for messages that are already clearly classified via other mechanisms.

#### Scenario: Slash commands bypass the gate

- **GIVEN** the user sends `/sdd-ff refactor-auth`
- **WHEN** the orchestrator processes the message
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST execute the slash command directly

#### Scenario: Messages with explicit intent verbs bypass the gate

- **GIVEN** the user sends "fix the auth bug"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate (clear Change Request signal)

#### Scenario: Messages ending with ? bypass the gate

- **GIVEN** the user sends "auth?" (single word but ends with ?)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST classify as Question (punctuation is a strong signal)

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
- [x] Ambiguity detection heuristics (4 categories: H1–H4) defined in CLAUDE.md — added 2026-03-14
- [x] Clarification prompt template (summary + 3 options + instruction) implemented — added 2026-03-14
- [x] Single-word ambiguous inputs trigger clarification gate, NOT default Question — added 2026-03-14
- [x] Routing after clarification: 1→Change Request, 2→Exploration, 3→Question, free text→re-classify — added 2026-03-14
- [x] Gate bypass for slash commands, explicit verbs, and ? punctuation — added 2026-03-14

---

## ADDED — Context Extraction Rule Before SDD Handoff
*(Added in: 2026-03-19 by change "feedback-sdd-cycle-context-gaps")*

### Requirement: Orchestrator confirms removal/replacement intent before /sdd-ff handoff

When the orchestrator classifies a message as a Change Request that includes explicit removal, replacement, or contradictory language ("remove X", "change X to Y instead", "X is wrong"), the orchestrator MUST confirm the user's intent before recommending `/sdd-ff`.

The confirmation MUST present:
- Detected intent (removal/replacement)
- Confirmation options (yes/no/re-explain)

This extraction ensures removal/replacement intent is captured before the SDD cycle begins and is available to `sdd-explore` for context gap detection.

When no removal/replacement language is detected, the orchestrator proceeds directly to the `/sdd-ff` recommendation without additional confirmation.

#### Scenario: User message includes removal intent

- **GIVEN** the user says: "The periodic membership refresh hook is broken — remove it"
- **WHEN** the orchestrator classifies this as a Change Request
- **THEN** it MUST emit a confirmation prompt asking to confirm the removal intent before recommending `/sdd-ff`

#### Scenario: User message implies replacement

- **GIVEN** the user says: "The payment flow doesn't work on mobile. Make it work without the polling mechanism."
- **WHEN** the orchestrator detects both explicit problem and implicit replacement (remove polling)
- **THEN** it MUST confirm the intent by presenting the possible interpretations before recommending `/sdd-ff`

#### Scenario: User message is purely additive

- **GIVEN** the user says: "Add email notifications for order updates"
- **WHEN** the orchestrator detects no removal/replacement language
- **THEN** no additional confirmation is needed
- **AND** the orchestrator proceeds directly: "I recommend `/sdd-ff add-email-notifications`"

---

### Requirement: Classification Decision Table extended for removal/replacement language

The Classification Decision Table MUST include examples showing that removal/replacement language is a strong Change Request signal and MAY trigger the context extraction confirmation:

```
✓ "remove the periodic refresh hook"    → Change Request; orchestrator confirms intent
✓ "change from polling to events"       → Change Request; replacement language detected
✓ "the login is broken"                 → Change Request; implies fix intent (may be implicit remove)
```

---

## Rules (context extraction — added 2026-03-19)

- Context extraction applies only to Change Requests, not to Questions or Explorations
- When removal/replacement language is ambiguous, the orchestrator MUST ask for clarification
- When intent is clear and additive, no additional confirmation is needed
- User confirmation at context extraction step feeds directly into the sdd-ff pre-population (Step 0)
- This rule is inline logic in CLAUDE.md; no new skill or artifact is required
- The rule MUST NOT block /sdd-ff — it only adds a confirmation gate for clarity

---

### Requirement: Spec-first Q&A for Questions about project domains
*(Added in: 2026-03-19 by change "feedback-sdd-cycle-context-gaps-p6")*

Before answering any Question that references a named component, feature, flow, or behavior in a project that has `openspec/specs/index.yaml`, the orchestrator MUST check for matching specs and read them before answering.

#### Scenario: Question about domain with matching spec

- **GIVEN** the user asks a question about an existing project feature or behavior (e.g., "what happens when the welcome video completes?", "how does the retry logic work?")
- **AND** the project has `openspec/specs/index.yaml` with a domain whose keywords match the question topic
- **WHEN** the orchestrator classifies the intent as Question
- **THEN** it MUST read `openspec/specs/index.yaml` and find matching domain(s) using keyword matching (case-insensitive stem matching against the question text)
- **AND** it MUST read the matching spec file(s) from `openspec/specs/<domain>/spec.md`
- **AND** it MUST use the spec as the authoritative source for the answer (not code)
- **AND** if code behavior contradicts the spec, it MUST surface the discrepancy explicitly with a note like: "⚠️ Note: The current code does X, but the spec requires Y (openspec/specs/<domain>/spec.md REQ-N). This may indicate spec drift or an incomplete implementation."

#### Scenario: Question about domain with no spec coverage

- **GIVEN** the user asks a question about a project component
- **AND** the project has `openspec/specs/index.yaml` but no domain's keywords match the question topic
- **WHEN** the orchestrator searches for matching specs
- **THEN** it MUST NOT produce an error
- **AND** it MUST answer directly from code as today (no change in behavior)

#### Scenario: Spec-first Q&A does not apply to Change Requests or Explorations

- **GIVEN** a user message is classified as Change Request or Exploration
- **WHEN** the orchestrator applies routing
- **THEN** it MUST NOT apply the spec-first Q&A rule
- **AND** it MUST follow the existing Change Request or Exploration routing rules
