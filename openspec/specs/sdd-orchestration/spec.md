# Spec: SDD Orchestration (sdd-new / sdd-ff)

Change: sdd-new-improvements
Date: 2026-03-10
Base: N/A (new domain spec)

## Requirements

### Requirement: Automatic slug inference from user description

The orchestrator MUST infer a change slug from the user's description without asking the user to provide a name.

#### Scenario: Simple multi-word description

- **GIVEN** the user provides the description "Add email notification system for order updates"
- **WHEN** the orchestrator processes the description
- **THEN** it MUST generate a slug matching pattern `YYYY-MM-DD-add-email-notification-order-updates` (today's date prefixed, max 5 meaningful words)
- **AND** the slug MUST be lowercase, hyphenated, between 10–50 characters total

#### Scenario: Slug collision with existing directory

- **GIVEN** a slug `2026-03-10-fix-auth-flow` already exists in `openspec/changes/`
- **WHEN** the orchestrator generates the same slug from a new description
- **THEN** it MUST append `-2` to produce `2026-03-10-fix-auth-flow-2`
- **AND** if that also exists, append `-3`, `-4`, etc. until a unique slug is found

#### Scenario: Strip stop words and extract meaningful keywords

- **GIVEN** the user description "Fix subscription renewal date showing wrong year for expired users"
- **WHEN** the orchestrator applies the slug inference rule
- **THEN** it MUST extract the 4–5 most meaningful words: "subscription renewal date expired"
- **AND** it MUST discard stop words: fix, add, update, the, a, an, for, of, in, with, showing, wrong, year
- **AND** the result MUST be `2026-03-10-fix-subscription-renewal-date-expired` (or with collision suffix if needed)

### Requirement: Mandatory exploration phase in sdd-new

The `sdd-new` command MUST run exploration as Step 1 without prompting the user.

#### Scenario: Exploration runs unconditionally

- **GIVEN** the user invokes `/sdd-new fix-payment-flow`
- **WHEN** the orchestrator processes the command
- **THEN** it MUST invoke `sdd-explore` as Step 1 with no user gate
- **AND** it MUST pass the inferred slug to `sdd-explore` (e.g., `2026-03-10-fix-payment-flow`)
- **AND** the generated `exploration.md` MUST be available to the next phase (`sdd-propose`)

#### Scenario: Exploration failure blocks proposal

- **GIVEN** `sdd-explore` returns `status: failed`
- **WHEN** the next phase would be proposed
- **THEN** the orchestrator MUST stop and report the failure to the user
- **AND** it MUST NOT continue to `sdd-propose`

### Requirement: Mandatory exploration phase in sdd-ff

The `sdd-ff` command MUST run exploration as Step 0 before proposal, without prompting the user.

#### Scenario: Fast-forward includes exploration as Step 0

- **GIVEN** the user invokes `/sdd-ff improve-cache-performance`
- **WHEN** the orchestrator processes the command
- **THEN** it MUST infer the slug from the description (no name argument)
- **AND** it MUST invoke `sdd-explore` as Step 0 with no user gate
- **AND** it MUST proceed to `sdd-propose` (Step 1), reading the generated `exploration.md`

#### Scenario: Fast-forward sequence is explore → propose → spec + design → tasks

- **GIVEN** all prior phases complete successfully
- **WHEN** the orchestrator reaches the end of the cycle
- **THEN** it MUST present a summary showing all four phases (explore, propose, spec, design, tasks)
- **AND** the phase order in the output MUST be: explore, propose, spec, design, tasks

### Requirement: Updated CLAUDE.md Fast-Forward section

The CLAUDE.md document MUST be updated to reflect the new sdd-ff flow.

#### Scenario: CLAUDE.md documents the new sdd-ff flow

- **GIVEN** a user reads CLAUDE.md section "## Fast-Forward (/sdd-ff)"
- **WHEN** they examine the flow diagram
- **THEN** it MUST show Step 0: sdd-explore (NEW)
- **AND** subsequent steps MUST be: propose, spec+design (parallel), tasks
- **AND** the prose MUST note that exploration is mandatory

### Requirement: No user intervention for name input in sdd-ff

The `sdd-ff` command MUST NOT ask the user to provide a change name.

#### Scenario: User provides description, name is inferred

- **GIVEN** the user invokes `/sdd-ff improve-authentication-performance`
- **WHEN** the orchestrator receives the description argument
- **THEN** it MUST NOT prompt "What is the kebab-case change name?"
- **AND** it MUST infer the slug from the provided text automatically

#### Scenario: No name validation from user

- **GIVEN** the orchestrator infers a slug
- **WHEN** the slug is generated
- **THEN** the user MUST NOT be asked to approve, rename, or confirm the slug
- **AND** the inferred slug MUST be used for the entire cycle

---

## Validation Criteria

- [x] Slug inference algorithm correctly strips stop words
- [x] Slug collision detection works (unique suffix appended)
- [x] Slug length stays within 50-character limit
- [x] sdd-new Step 1 runs exploration unconditionally
- [x] sdd-ff Step 0 runs exploration unconditionally
- [x] Exploration.md is available to proposal phase
- [x] CLAUDE.md Fast-Forward section updated with new flow diagram
- [x] No user name-input gate in either orchestrator

---

## Notes

- The slug is internal to the filesystem; the user never needs to think about it
- Slug inference is deterministic given the same description (except for collision handling)
- Both `sdd-new` and `sdd-ff` use the same slug inference logic
