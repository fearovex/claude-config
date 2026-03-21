# Delta Spec: sdd-ff — Contradiction Gate and Proposal Pre-population

Change: 2026-03-19-feedback-sdd-cycle-context-gaps
Date: 2026-03-19
Base: openspec/specs/sdd-orchestration/spec.md

## MODIFIED — Step 0 includes pre-population of proposal.md with context

### Requirement: sdd-ff pre-populates proposal.md before launching explore

Before launching the `sdd-explore` sub-agent, `sdd-ff` MUST extract conversation context and pre-populate a skeleton `proposal.md` with explicit intents and constraints.

The pre-population MUST:
1. Extract patterns from the user's original request (the argument to `/sdd-ff`)
2. Identify any explicit removal language: "remove X", "no longer X", "delete X"
3. Identify any platform/constraint language: "mobile must", "not on web", "performance critical"
4. Write a skeleton proposal.md with:
   - Problem statement (extracted from request)
   - Initial Supersedes section (preliminary, to be refined by propose phase)
   - Identified constraints (to be confirmed by exploration)

#### Scenario: User requests feature removal

- **GIVEN** the user invokes `/sdd-ff remove the periodic membership refresh hook`
- **WHEN** `sdd-ff` executes Step 0 pre-population
- **THEN** it MUST create a skeleton proposal.md with:
  ```
  # Proposal: [inferred-slug]

  ## Problem

  User request: Remove the periodic membership refresh hook

  ## Scope

  ### Removals

  - Periodic membership refresh hook (to be confirmed and detailed in exploration)

  ## Supersedes

  ### REMOVED

  - **Periodic membership refresh hook**
    Preliminary reason: User explicitly requested removal

  [Details to be filled in by sdd-propose phase]
  ```

#### Scenario: User mentions a mobile-specific change

- **GIVEN** the user invokes `/sdd-ff improve payment flow for mobile, sub-500ms latency required`
- **WHEN** `sdd-ff` pre-populates the proposal
- **THEN** it MUST capture:
  ```
  ## Scope

  ### Platform Constraints

  - Mobile: MUST achieve sub-500ms latency
  ```

#### Scenario: Generic description with no removals

- **GIVEN** the user invokes `/sdd-ff add email notification system`
- **WHEN** `sdd-ff` pre-populates
- **THEN** the Supersedes section MUST state: "None — purely additive change" (provisional)

---

## ADDED — Step 2 includes contradiction gate

### Requirement: sdd-ff presents a confirmation gate for UNCERTAIN contradictions

After exploration completes and before launching propose, `sdd-ff` MUST check the exploration.md `## Contradiction Analysis` section. If any UNCERTAIN contradictions are found, `sdd-ff` MUST present a user confirmation gate.

The gate MUST:
1. List each UNCERTAIN contradiction with its description and severity
2. Ask the user: "Does the proposal intend to [action]?" for each contradiction
3. Record the user's explicit confirmation in the proposal.md as a `## Decisions` section
4. Halt the cycle if the user cannot confirm (return to exploration with clarification request)

#### Scenario: One UNCERTAIN contradiction detected

- **GIVEN** exploration.md reports:
  ```
  ### Contradiction: Mobile constraint in conversation, missing from proposal
  Classification: UNCERTAIN
  Severity: WARNING
  ```
- **WHEN** `sdd-ff` presents the gate
- **THEN** the user sees:
  ```
  ⚠️  UNCERTAIN CONTRADICTION DETECTED

  Exploration found that you mentioned in conversation: "mobile must not make this request"
  but the proposal doesn't explicitly require it.

  Question: Should the proposal REQUIRE that mobile clients skip this request?
  - Yes, add mobile constraint → proceed to propose
  - No, discard the constraint → proceed to propose
  - Clarify → return to exploration with new context

  Your answer:
  ```

#### Scenario: No contradictions — no gate

- **GIVEN** exploration.md reports: "No contradictions detected"
- **WHEN** `sdd-ff` checks for the gate
- **THEN** no gate is presented; propose phase is launched immediately

#### Scenario: CERTAIN contradictions do not trigger gate (already handled in exploration)

- **GIVEN** exploration reports: "Contradiction: User requests REMOVAL but contract GUARANTEES presence (CERTAIN)"
- **WHEN** `sdd-ff` checks the gate
- **THEN** no gate is presented (CERTAIN contradictions are already recorded in proposal; user has made an explicit decision)
- **AND** the proposal is expected to include the contradiction resolution

---

## ADDED — User confirmation is recorded in proposal.md

### Requirement: User answers at the contradiction gate are recorded as Decisions section

If the user confirms or clarifies at the contradiction gate, `sdd-ff` MUST record the decision in the proposal.md `## Decisions` section.

#### Scenario: User confirms mobile constraint

- **GIVEN** the user answers "Yes, add mobile constraint" at the gate
- **WHEN** `sdd-ff` records the decision
- **THEN** the proposal.md `## Decisions` section is updated to:
  ```
  ## Decisions

  ### Mobile Constraint Confirmation
  **Date**: 2026-03-19T15:42Z
  **User answer**: Confirmed — mobile clients MUST NOT make this request

  This decision was recorded at the contradiction gate and overrides proposal scope
  that was silent on mobile behavior.
  ```

---

## Rules

- Pre-population step (Step 0) is non-blocking; missing context does not halt `sdd-ff`
- Contradiction gate is mandatory only when UNCERTAIN contradictions are found
- User confirmation at the gate is binding — it updates the proposal.md and flows to all downstream phases
- If user cannot confirm at the gate (chooses "Clarify"), `sdd-ff` MUST return to exploration with clarification request
- Pre-populated proposal.md is a skeleton only; `sdd-propose` phase may refine or override all sections
- Gate only appears between exploration and propose; not at any other phase boundary
