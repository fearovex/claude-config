# Delta Spec: SDD Orchestration — Model Routing

Change: 2026-03-18-specs-opus-routing
Date: 2026-03-18
Base: openspec/specs/sdd-orchestration/spec.md

## ADDED — New requirements

### Requirement: CLI flag --opus and --power activate session-level Opus routing
*(Added in: 2026-03-18 by change "specs-opus-routing")*

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
*(Added in: 2026-03-18 by change "specs-opus-routing")*

Flag detection MUST be the first sub-step of Step 0, executed before slug inference and before reading `openspec/config.yaml`.

#### Scenario: Step 0 sub-step order is flag detection → slug inference → config read

- **GIVEN** the user invokes `/sdd-ff --opus add-payment-feature`
- **WHEN** the orchestrator executes Step 0
- **THEN** sub-step 1 MUST detect and strip `--opus`, setting `use_opus = true`
- **AND** sub-step 2 MUST infer the slug from the stripped description ("add-payment-feature")
- **AND** sub-step 3 MUST read `openspec/config.yaml` and extract `model_routing.phases` (if present)

---

### Requirement: use_opus flag is held as an in-session variable and propagated to all Task calls
*(Added in: 2026-03-18 by change "specs-opus-routing")*

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
*(Added in: 2026-03-18 by change "specs-opus-routing")*

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
*(Added in: 2026-03-18 by change "specs-opus-routing")*

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
*(Added in: 2026-03-18 by change "specs-opus-routing")*

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
*(Added in: 2026-03-18 by change "specs-opus-routing")*

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

## Rules (additions)

- `--opus` and `--power` are session-scoped flags; they MUST be stripped from the description before slug inference *(added: 2026-03-18)*
- `use_opus` is an in-session variable set once at Step 0; it MUST NOT be reset by user confirmation gates or phase completion *(added: 2026-03-18)*
- Phase SKILL.md files MUST NOT contain model selection logic — model injection is exclusively the orchestrator's responsibility *(added: 2026-03-18)*
- Standalone phase invocations MUST NOT inherit CLI flags from prior sessions — config-driven `model_routing.phases` is the only mechanism for standalone model selection *(added: 2026-03-18)*
- The resolution order (CLI flag → per-phase config → Sonnet default) is fixed; no config key may redefine this order *(added: 2026-03-18)*
