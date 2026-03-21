# Delta Spec: CLAUDE.md Global Orchestrator — Context Extraction Rule

Change: 2026-03-19-feedback-sdd-cycle-context-gaps
Date: 2026-03-19
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — Unbreakable Rule: Extraction of conversation context before SDD handoff

### Requirement: Orchestrator instructs user to confirm removal/replacement intent

A new Unbreakable Rule MUST be added to CLAUDE.md Unbreakable Rules section (after Rule 5, Feedback Persistence). The rule establishes that when the user requests a Change Request (triggering `/sdd-ff` recommendation), the orchestrator MUST attempt to extract conversation context for replacement or removal intent before confirming the handoff.

The rule MUST state:

```
### 7. Context extraction before SDD handoff

When recommending `/sdd-ff` in response to a Change Request that includes explicit removal,
replacement, or contradictory language ("remove X", "change X to Y instead", "X is wrong"),
the orchestrator MUST confirm the user's intent before recommending the command.

Confirmation pattern:

  User: "Fix the login is broken"
  Orchestrator: "I understand — you want to fix the login. Before I recommend /sdd-ff,
                 I need to confirm: Does your fix involve removing or replacing any
                 existing behavior? (e.g., changing auth flow, removing features, etc.)

                 Please clarify, or I'll proceed with the standard recommendation."

This extraction step ensures that removal/replacement intent is captured before
the SDD cycle begins and is available to sdd-explore for context gap detection.

When no removal/replacement language is detected, the orchestrator proceeds directly
to the /sdd-ff recommendation without additional confirmation.
```

#### Scenario: User message includes removal intent

- **GIVEN** the user says: "The periodic membership refresh hook is broken — remove it"
- **WHEN** the orchestrator classifies this as a Change Request
- **THEN** it MUST emit a confirmation prompt:
  ```
  Got it — you want to remove the periodic membership refresh hook.

  Is this correct?
  - Yes, remove it entirely → I'll recommend /sdd-ff
  - No, fix it instead → clarify what fix you want
  - Wait, I was wrong → re-explain your intent
  ```

#### Scenario: User message implies replacement

- **GIVEN** the user says: "The payment flow doesn't work on mobile. Make it work without the polling mechanism."
- **WHEN** the orchestrator detects both explicit problem (doesn't work on mobile) and implicit replacement (remove polling)
- **THEN** it MUST confirm:
  ```
  I see a few possible intents here:
  1. Fix the mobile payment flow (keep polling)
  2. Replace polling with something else (what?)
  3. Remove polling entirely on mobile

  Which best describes what you want?
  ```

#### Scenario: User message is purely additive

- **GIVEN** the user says: "Add email notifications for order updates"
- **WHEN** the orchestrator detects no removal/replacement language
- **THEN** no additional confirmation is needed
- **AND** the orchestrator proceeds: "I recommend `/sdd-ff add-email-notifications`"

---

## MODIFIED — Intent Classification Decision Table extended

### Requirement: Clarification gate considers removal/replacement language as explicit signal

The Classification Decision Table in CLAUDE.md MUST be updated to explicitly note that removal/replacement language ("remove", "delete", "change X to Y", "replace") is a strong Change Request signal and MAY trigger the context extraction confirmation.

The table MUST include an example:
```
✓ "remove the periodic refresh hook"    → Change Request; orchestrator confirms intent
✓ "change from polling to events"       → Change Request; replacement language detected
✓ "the login is broken"                 → Change Request; implies fix intent (may be implicit remove)
```

---

## Rules

- Context extraction applies only to Change Requests, not to Questions or Explorations
- When removal/replacement language is ambiguous, the orchestrator MUST ask for clarification
- When intent is clear and additive, no additional confirmation is needed
- User confirmation at context extraction step feeds directly into the sdd-ff pre-population (Step 0)
- This rule is inline logic in CLAUDE.md; no new skill or artifact is required
- The rule MUST NOT block /sdd-ff — it only adds a confirmation gate for clarity
