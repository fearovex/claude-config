# Delta Spec: sdd-orchestration

Change: 2026-03-14-fix-sdd-orchestration-delta-spec
Date: 2026-03-14
Base: openspec/specs/sdd-orchestration/spec.md

## MODIFIED — Modified requirements

### Requirement: Orchestrators do not inject spec context — phase skills self-select

_(Before: orchestrators inject a SPEC CONTEXT block into every sub-agent Task prompt, listing
domain names and explicit file paths inferred from the change slug.)_

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
