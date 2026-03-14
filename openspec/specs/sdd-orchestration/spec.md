# Spec: SDD Orchestration (sdd-new / sdd-ff)

Change: sdd-new-improvements
Date: 2026-03-10
Base: N/A (new domain spec)

## MODIFIED — Orchestrator sub-agent launch contract

### Requirement: Orchestrators do not inject spec context — phase skills self-select

_(Modified in: 2026-03-14 by change "fix-sdd-orchestration-delta-spec")_

The orchestrator skills (`CLAUDE.md`, `sdd-ff`, `sdd-new`) MUST NOT inject a SPEC CONTEXT block
into sub-agent Task prompts. Sub-agents MUST NOT receive spec context through orchestrator-side
injection.

Instead, each SDD phase skill (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`,
`sdd-tasks`) MUST independently self-select relevant master spec files during its own Step 0
sub-step (Step 0c for `sdd-propose` and `sdd-spec`; a named Step 0 sub-step for the remaining
three skills). Self-selection applies the stem-based matching heuristic defined in
`docs/SPEC-CONTEXT.md`.

The observable contract for the orchestrator domain is therefore one of **absence**: no
orchestrator-side injection mechanism exists or is required.

#### Scenario: Sub-agent Task prompt contains no SPEC CONTEXT block

- **GIVEN** the orchestrator (`sdd-ff` or `sdd-new`) builds a sub-agent Task prompt for any SDD phase
- **WHEN** the prompt is passed to the sub-agent via the Task tool
- **THEN** the prompt MUST NOT contain a SPEC CONTEXT block
- **AND** the prompt MUST NOT contain an explicit list of `openspec/specs/<domain>/spec.md` paths
  injected by the orchestrator
- **AND** the prompt MUST NOT instruct the sub-agent to treat any orchestrator-provided path list
  as an authoritative spec source

#### Scenario: Sub-agent receives spec context through its own Step 0 self-selection

- **GIVEN** a sub-agent is launched for any of the five spec-loading phase skills
  (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`)
- **WHEN** the sub-agent executes its Step 0 spec context preload sub-step
- **THEN** it MUST independently list `openspec/specs/` and apply stem-based matching
  against the change slug
- **AND** it MUST load at most 3 matching spec files as enrichment context
- **AND** this loading MUST occur without any instruction from the orchestrator Task prompt

#### Scenario: Orchestrator CONTEXT block is unchanged — no spec-loading fields added

- **GIVEN** the orchestrator constructs a sub-agent Task prompt CONTEXT block
- **WHEN** the CONTEXT block fields are examined
- **THEN** the CONTEXT block MUST contain only: project path, change name, and prior artifact paths
- **AND** the CONTEXT block MUST NOT contain any spec domain inference results,
  matched domain names, or spec file path lists

#### Scenario: Phase skill falls back to ai-context/ when no spec domain matches

- **GIVEN** a sub-agent's Step 0 spec context preload sub-step finds no matching domain
  under `openspec/specs/` for the current change slug
- **WHEN** the sub-agent proceeds to its main phase work
- **THEN** the sub-agent MUST proceed without error — the self-selection step is non-blocking
- **AND** `ai-context/architecture.md`, `ai-context/stack.md`, and related files remain the
  primary enrichment context
- **AND** the orchestrator is NOT informed of the skip — it requires no notification

#### Scenario: No orchestrator change required when a new phase skill is added

- **GIVEN** a new SDD phase skill is created and needs access to master spec context
- **WHEN** the skill author implements spec loading
- **THEN** the skill MUST implement its own Step 0 spec context preload sub-step
  per `docs/SPEC-CONTEXT.md` convention
- **AND** the orchestrator skills (`sdd-ff`, `sdd-new`, `CLAUDE.md`) MUST NOT be modified
  to support the new skill's spec loading

---

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
