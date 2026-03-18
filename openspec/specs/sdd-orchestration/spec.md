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

---

## ADDED — Model Routing Requirements
*(Added in: 2026-03-18 by change "specs-opus-routing")*

### Requirement: CLI flag --opus and --power activate session-level Opus routing

The orchestrators `sdd-ff` and `sdd-new` MUST accept `--opus` and `--power` as optional flags in the user's argument string. When either flag is present, all Task calls in that session MUST use `model: opus`.

#### Scenario: --opus flag sets use_opus = true for the session

- **GIVEN** the user invokes `/sdd-ff --opus improve-cache-performance`
- **WHEN** the orchestrator processes the command at Step 0
- **THEN** it MUST detect `--opus` in the argument string and set `use_opus = true`
- **AND** it MUST strip `--opus` from the description before slug inference
- **AND** the inferred slug MUST be derived from "improve-cache-performance", not include "opus"

#### Scenario: --power flag is equivalent to --opus

- **GIVEN** the user invokes `/sdd-ff --power improve-cache-performance`
- **WHEN** the orchestrator processes the command at Step 0
- **THEN** it MUST detect `--power` and set `use_opus = true`
- **AND** it MUST strip `--power` from the description before slug inference
- **AND** all Task calls MUST use `model: opus`

#### Scenario: No flag leaves use_opus = false (default Sonnet behavior)

- **GIVEN** the user invokes `/sdd-ff improve-cache-performance` (no flag)
- **WHEN** the orchestrator processes the command
- **THEN** `use_opus` MUST remain false
- **AND** all Task calls MUST use `model: sonnet` (unless overridden by `model_routing.phases`)

#### Scenario: Flag is stripped before slug inference — no mangled slugs

- **GIVEN** the user invokes `/sdd-ff --opus fix-login-bug`
- **WHEN** the orchestrator applies slug inference
- **THEN** the slug MUST be `YYYY-MM-DD-fix-login-bug` (or similar — flag-free)
- **AND** the slug MUST NOT contain "opus" or "power"

---

### Requirement: Flag detection occurs at Step 0 before slug inference and config reading

Flag detection MUST be the first sub-step of Step 0, executed before slug inference and before reading `openspec/config.yaml`.

#### Scenario: Step 0 sub-step order is flag detection → slug inference → config read

- **GIVEN** the user invokes `/sdd-ff --opus add-payment-feature`
- **WHEN** the orchestrator executes Step 0
- **THEN** sub-step 1 MUST detect and strip `--opus`, setting `use_opus = true`
- **AND** sub-step 2 MUST infer the slug from the stripped description ("add-payment-feature")
- **AND** sub-step 3 MUST read `openspec/config.yaml` and extract `model_routing.phases` (if present)

---

### Requirement: use_opus flag is held as an in-session variable and propagated to all Task calls

The `use_opus` state set at Step 0 MUST persist for the entire orchestration session. It MUST be applied at every Task call block — both in `sdd-ff` and across all user-confirmation gates in `sdd-new`.

#### Scenario: sdd-ff propagates use_opus to all five phase Task calls

- **GIVEN** the user invokes `/sdd-ff --opus add-payment-feature`
- **WHEN** the orchestrator launches sub-agents for explore, propose, spec, design, and tasks
- **THEN** every Task call block MUST include `model: opus`
- **AND** no phase MUST silently revert to `model: sonnet`

#### Scenario: sdd-new propagates use_opus across confirmation gates

- **GIVEN** the user invokes `/sdd-new --opus add-payment-feature`
- **AND** the user approves each SDD gate (after explore, after propose, after spec+design)
- **WHEN** each subsequent Task call is built
- **THEN** the Task call MUST still include `model: opus`
- **AND** user confirmation does NOT reset `use_opus` to false

---

### Requirement: Model resolution at each Task call follows the defined priority chain

At each Task call block, the orchestrator MUST resolve the model to inject using the priority chain: CLI flag → per-phase config → Sonnet default. The resolution is deterministic.

#### Scenario: CLI flag overrides per-phase config

- **GIVEN** `model_routing.phases` maps `sdd-explore` to `sonnet` (explicitly)
- **AND** `use_opus = true` (CLI flag was given)
- **WHEN** the orchestrator builds the Task call for the explore phase
- **THEN** the Task call MUST use `model: opus`

#### Scenario: Per-phase config overrides Sonnet default when no CLI flag

- **GIVEN** `model_routing.phases` maps `sdd-design` to `opus`
- **AND** `use_opus = false` (no CLI flag)
- **WHEN** the orchestrator builds the Task call for the design phase
- **THEN** the Task call MUST use `model: opus`

#### Scenario: Sonnet default applies when neither source specifies a model

- **GIVEN** `use_opus = false` and `model_routing.phases` has no entry for `sdd-tasks`
- **WHEN** the orchestrator builds the Task call for the tasks phase
- **THEN** the Task call MUST use `model: sonnet`

---

### Requirement: Phase skills remain model-agnostic — model selection is the orchestrator's responsibility

Phase SKILL.md files (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) MUST NOT be modified to support model routing. Model selection is injected by the orchestrator via the Task tool call and is invisible to the phase skill.

#### Scenario: Phase skill executes without awareness of which model was selected

- **GIVEN** the orchestrator launches `sdd-design` with `model: opus` in its Task call
- **WHEN** the `sdd-design` sub-agent reads and follows `~/.claude/skills/sdd-design/SKILL.md`
- **THEN** the SKILL.md MUST contain no model-selection logic
- **AND** the sub-agent MUST produce the same outputs (design.md) regardless of model

#### Scenario: No changes required to phase SKILL.md files

- **GIVEN** the model routing feature is fully implemented
- **WHEN** the set of modified files is examined
- **THEN** MUST NOT include any of: sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify SKILL.md files
- **AND** only `sdd-ff/SKILL.md` and `sdd-new/SKILL.md` (orchestrators) MUST be modified

---

### Requirement: Standalone phase invocations cannot inherit CLI flag from a prior session

CLI flag propagation is scoped to the orchestrator session that received the flag. Standalone invocations (`/sdd-apply`, `/sdd-verify`, etc.) MUST NOT inherit the `use_opus` flag from a prior `/sdd-ff --opus` session.

#### Scenario: Standalone /sdd-verify uses Sonnet regardless of prior --opus session

- **GIVEN** the user previously ran `/sdd-ff --opus add-payment-feature` in a prior session
- **WHEN** the user runs `/sdd-verify add-payment-feature` in the current session
- **THEN** `sdd-verify` MUST use `model: sonnet` (or the model declared in `model_routing.phases.sdd-verify` if present)
- **AND** it MUST NOT inherit `use_opus = true` from the prior session

#### Scenario: Config-driven routing is the mechanism for standalone phase model selection

- **GIVEN** the user wants `sdd-verify` to always use `opus`
- **WHEN** they configure `model_routing.phases.sdd-verify: opus` in `openspec/config.yaml`
- **THEN** the orchestrator reads this config and applies `model: opus` when launching `sdd-verify` as a Task
- **AND** standalone invocations of `sdd-verify` that read `openspec/config.yaml` directly MAY apply this mapping (out of scope for V1 — informational only)

---

### Requirement: CLAUDE.md sub-agent launch pattern and Fast-Forward section are updated

The `CLAUDE.md` document MUST document the model routing capability in the Sub-agent launch pattern and Fast-Forward sections.

#### Scenario: Sub-agent launch pattern shows model field injection

- **GIVEN** a developer reads the CLAUDE.md "Sub-agent launch pattern" section
- **WHEN** they examine the Task tool template
- **THEN** they MUST see a `model: [resolved-model]` field in the template (or a note about model resolution)
- **AND** the resolution order MUST be documented inline or referenced

#### Scenario: Fast-Forward section documents --opus and --power flags

- **GIVEN** a developer reads the CLAUDE.md "Fast-Forward (/sdd-ff)" section
- **WHEN** they examine the invocation syntax
- **THEN** they MUST find `/sdd-ff --opus <description>` as a documented example or note
- **AND** the section MUST indicate that all phases use `model: opus` when the flag is present

---

## Rules (added: 2026-03-18)

- `--opus` and `--power` are session-scoped flags; they MUST be stripped from the description before slug inference *(added: 2026-03-18)*
- `use_opus` is an in-session variable set once at Step 0; it MUST NOT be reset by user confirmation gates or phase completion *(added: 2026-03-18)*
- Phase SKILL.md files MUST NOT contain model selection logic — model injection is exclusively the orchestrator's responsibility *(added: 2026-03-18)*
- Standalone phase invocations MUST NOT inherit CLI flags from prior sessions — config-driven `model_routing.phases` is the only mechanism for standalone model selection *(added: 2026-03-18)*
- The resolution order (CLI flag → per-phase config → Sonnet default) is fixed; no config key may redefine this order *(added: 2026-03-18)*
