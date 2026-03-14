# Delta Spec: Orchestrator Behavior — Classification Edge Cases

Change: 2026-03-14-orchestrator-classification-edge-cases
Date: 2026-03-14
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — New requirements

### Requirement: Implicit change intent MUST be classified as Change Request

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

#### Scenario: Implicit change intent — "it doesn't work" statement

- **GIVEN** the user sends "this validation doesn't work" directed at a specific feature
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request
- **AND** it MUST NOT respond with only an explanation

---

### Requirement: Investigative phrasing that resembles a change request MUST be classified as Exploration

When a user message uses investigative verbs ("check", "look at", "verify") that are directed at understanding or inspecting — not mutating — the system, the orchestrator MUST classify it as Exploration, not Change Request.

#### Scenario: "Check" verb without mutation intent

- **GIVEN** the user sends "check the login flow" (inspect, not modify)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration
- **AND** it MUST launch `sdd-explore` via Task tool or recommend `/sdd-explore`
- **AND** it MUST NOT classify it as Change Request

#### Scenario: "Look at" phrasing

- **GIVEN** the user sends "look at how retries are handled"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration

#### Scenario: "Verify" without specifying a change target

- **GIVEN** the user sends "verify that the auth module is correct"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration (inspection, not a change task)

---

### Requirement: Questions that mention broken behavior MUST be classified as Question, not Change Request

A message that ends with "?" or uses question phrasing MUST be classified as Question even when it references broken or incorrect behavior.

#### Scenario: "Why does X fail?" — remains a Question

- **GIVEN** the user sends "why does login fail?"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly without routing to an SDD phase
- **AND** it MUST NOT recommend `/sdd-ff` unless the user requests a change

#### Scenario: "Is X broken?" — Question, not Change Request

- **GIVEN** the user sends "is the payment system broken?"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer the question directly or state it cannot determine without investigation
- **AND** it MUST append the default ambiguity note if appropriate: "If you'd like me to implement this, I can start with `/sdd-ff <slug>`."

#### Scenario: "What's wrong with X?" — Question

- **GIVEN** the user sends "what's wrong with the retry logic?"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly

---

### Requirement: Ambiguous single-word or context-free messages MUST default to Question

A message with no context or a single word that does not contain an explicit intent verb or punctuation MUST be classified as Question (the default ambiguous class), not as a Change Request or Exploration.

#### Scenario: Single-word noun — defaults to Question

- **GIVEN** the user sends only "login" (a single noun, no verb, no "?")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question (default ambiguous)
- **AND** it MUST ask a single clarifying question or answer the most probable interpretation directly
- **AND** it MUST append: "If you'd like me to implement this, I can start with `/sdd-ff <slug>`."

#### Scenario: Single-word verb with no target

- **GIVEN** the user sends only "refactor" (a change verb, but no target specified)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question (default ambiguous) because the target is missing
- **AND** it MUST ask a clarifying question: "What would you like me to refactor?"

#### Scenario: Ambiguous acronym or label

- **GIVEN** the user sends only "auth" or "payments"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question (default ambiguous)
- **AND** it MUST respond with a clarifying question or a summary of the named component

---

### Requirement: Compound messages that mix intent classes MUST use the highest-priority class

When a single message contains signals for more than one intent class, the orchestrator MUST select the highest-priority class using the precedence order: Change Request > Exploration > Question.

#### Scenario: "Fix and explain" — Change Request wins

- **GIVEN** the user sends "fix the auth bug and explain why it broke"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request (not Question)
- **AND** it MUST recommend the SDD command first
- **AND** it MAY note that an explanation will be provided after the change is implemented

#### Scenario: "Analyze and update" — Change Request wins

- **GIVEN** the user sends "analyze the retry module and update the timeout values"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Change Request
- **AND** it MUST NOT route to `sdd-explore` exclusively

---

## MODIFIED — Modified requirements

### Requirement: Four intent classes with clear routing rules _(modified — extended decision table)_

The existing requirement is preserved. This delta adds precision to the classification signals by including implicit patterns and priority resolution.

_(Before: Classification relied only on explicit keyword matching. The decision table lacked examples for implicit change intent, investigative-but-not-change phrasing, question-with-broken-behavior, and single-word inputs.)_

#### Scenario: Implicit intent added to Change Request signals _(modified)_

- **GIVEN** the orchestrator loads its classification rules
- **WHEN** evaluating a user message for Change Request intent
- **THEN** the signal set MUST include both explicit verbs (fix, add, implement, etc.) AND implicit signals: state descriptions of breakage ("is broken", "doesn't work", "is wrong", "is missing") directed at a named codebase component
- **AND** the decision table in CLAUDE.md MUST list at least 10 edge case examples covering all four proposed edge case categories

#### Scenario: Decision table provides at least 10 edge case examples _(modified)_

- **GIVEN** the CLAUDE.md decision table is read by the orchestrator at session start
- **WHEN** an edge case message is received (implicit change, investigative phrasing, question with broken behavior, single-word input)
- **THEN** the orchestrator MUST resolve it deterministically using a matching example from the table
- **AND** the table MUST contain at minimum 10 such examples, with at least 2 examples per edge case category

