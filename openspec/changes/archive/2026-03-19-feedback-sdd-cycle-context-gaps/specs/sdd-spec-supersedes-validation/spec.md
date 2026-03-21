# Delta Spec: sdd-spec — Validation Against Proposal Supersedes Section

Change: 2026-03-19-feedback-sdd-cycle-context-gaps
Date: 2026-03-19
Base: openspec/specs/sdd-phase-context-loading/spec.md

## MODIFIED — Step 1 extended to validate specs against Supersedes section

### Requirement: sdd-spec validates spec content against proposal Supersedes section

When writing delta specs, `sdd-spec` MUST perform a new validation step: cross-check the spec requirements against the proposal's `## Supersedes` section to ensure no unconfirmed preservation requirements are added.

The validation MUST:
1. Read the proposal.md `## Supersedes` section
2. For each REMOVED or REPLACED item, check if the delta spec contains any requirement that preserves or re-introduces that item
3. For each CONTRADICTED item, check if the delta spec contradicts the stated resolution in the proposal
4. Emit a MUST_RESOLVE warning if validation finds an inconsistency

#### Scenario: Spec tries to preserve a removed feature

- **GIVEN** the proposal states: "REMOVED: Periodic membership refresh hook — no longer needed"
- **AND** the delta spec includes: "Requirement: The system MUST periodically refresh membership status every 4 hours"
- **WHEN** `sdd-spec` executes the validation step
- **THEN** it MUST emit a MUST_RESOLVE warning:
  ```
  [WARNING: MUST_RESOLVE]
  Spec contradiction detected: spec includes a requirement to preserve the periodic membership refresh hook,
  but proposal Supersedes section marks this as REMOVED. Either: (1) correct the proposal to mark as REPLACED,
  or (2) remove the preservation requirement from the spec. User MUST resolve this before proceeding.
  ```
- **AND** `sdd-spec` MUST halt with status: `warning` (not blocked, but warning requires user confirmation before spec is accepted)

#### Scenario: Spec correctly reflects the removal

- **GIVEN** the proposal states: "REMOVED: Periodic refresh hook"
- **AND** the delta spec includes only ADDED requirements for new event-driven refresh behavior
- **WHEN** `sdd-spec` validates
- **THEN** no warning is emitted
- **AND** the spec proceeds normally with status: `ok`

#### Scenario: Spec addresses the contradiction stated in proposal

- **GIVEN** the proposal states: "CONTRADICTED: Backwards compatibility guarantee; Resolution: v1 API endpoint is sunsetting with 6-month deprecation"
- **AND** the delta spec includes: "Requirement: The system MUST emit deprecation warnings for v1 API calls during the 6-month sunset period"
- **WHEN** `sdd-spec` validates
- **THEN** no contradiction is detected — the spec aligns with the stated resolution
- **AND** the spec proceeds normally

---

## ADDED — Explicit rule: Do not invent preservation requirements

### Requirement: Specs MUST NOT add preservation requirements without explicit proposal language

`sdd-spec` MUST NOT unilaterally decide to preserve behavior that the proposal doesn't explicitly require. If the proposal is silent on something, the spec MUST NOT invent a "preserve" requirement without user confirmation.

#### Scenario: Proposal is silent; spec invents preservation

- **GIVEN** the proposal requests "improve the payment flow for mobile"
- **AND** the proposal does not mention the desktop payment flow
- **AND** the spec author considers: "We should preserve the existing desktop flow"
- **WHEN** the spec is written
- **THEN** the spec MUST NOT add a requirement: "The desktop payment flow MUST remain unchanged"
- **AND** instead, spec SHOULD note: `[Pending clarification: Desktop payment flow scope not mentioned in proposal]`
- **AND** this note MUST be listed in risks for user confirmation

#### Scenario: Proposal explicitly requires preservation

- **GIVEN** the proposal states: "Scope: Desktop flow MUST remain unchanged; mobile only"
- **WHEN** `sdd-spec` writes the spec
- **THEN** the spec MAY include the preservation requirement: "The desktop payment flow MUST NOT be modified"

---

## Rules

- Validation step is mandatory in every `sdd-spec` execution
- If validation finds a contradiction between spec and Supersedes section, emit MUST_RESOLVE warning and require user confirmation
- Specs MUST NOT preserve behavior not explicitly stated in the proposal
- The Supersedes section (with its REMOVED, REPLACED, CONTRADICTED items) is the source of truth for scope boundaries
- If the Supersedes section is absent or malformed in proposal.md, log a WARNING-level note and skip validation gracefully
