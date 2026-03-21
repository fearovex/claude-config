# Delta Spec: Orchestrator Always-On Behavior

Change: 2026-03-19-feedback-sdd-cycle-context-gaps-p6
Date: 2026-03-19
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — New requirements

### Requirement: Spec-first Q&A for Questions about project domains

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

---

## MODIFIED — Modified requirements

### Requirement: Direct question is answered inline _(modified)_

**Previous:**
- GIVEN the user asks a question seeking factual or conceptual information
- WHEN the orchestrator classifies the intent
- THEN it MUST answer directly without routing to an SDD phase

**New description:**
The orchestrator MUST answer Questions directly. However, if the project has `openspec/specs/index.yaml`, the orchestrator MUST first check for matching specs and read them (see "Spec-first Q&A for Questions about project domains" requirement). Then it MUST use the spec as the authoritative source for the answer.

_(This modification clarifies that spec reading is now part of the Question pathway, not a separate phase.)_

---
