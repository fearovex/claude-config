# Delta Spec: config-schema

Change: 2026-03-18-specs-opus-routing
Date: 2026-03-18
Base: openspec/specs/config-schema/spec.md

## ADDED — New requirements

### Requirement: model_routing is an optional top-level section in openspec/config.yaml
*(Added in: 2026-03-18 by change "specs-opus-routing")*

`openspec/config.yaml` MUST accept an optional `model_routing:` top-level key. Its absence MUST NOT break any existing SDD phase invocation or orchestrator run.

#### Scenario: config.yaml without model_routing proceeds with Sonnet default

- **GIVEN** a project whose `openspec/config.yaml` does not contain a `model_routing:` key
- **WHEN** the orchestrator (`sdd-ff` or `sdd-new`) reads `openspec/config.yaml` at Step 0
- **THEN** all Task calls use `model: sonnet` for every phase
- **AND** no error or warning is emitted about the absence of `model_routing:`

#### Scenario: config.yaml with a valid model_routing section is parsed without errors

- **GIVEN** a project whose `openspec/config.yaml` contains a `model_routing:` section with valid sub-keys
- **WHEN** any SDD skill reads `openspec/config.yaml`
- **THEN** no parse errors or warnings are emitted about the `model_routing:` key
- **AND** skills that do not use `model_routing:` ignore it silently

---

### Requirement: model_routing.phases sub-key maps phase names to model identifiers
*(Added in: 2026-03-18 by change "specs-opus-routing")*

The `phases` key under `model_routing:` MUST be a map of phase name strings to model identifier strings. It is optional. When present, each entry overrides the default model for the named phase.

#### Scenario: model_routing.phases accepted as a string-to-string map

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  model_routing:
    phases:
      sdd-explore: opus
      sdd-design: opus
      sdd-verify: opus
  ```
- **WHEN** the orchestrator reads the config at Step 0
- **THEN** the phases map is available for per-Task model resolution
- **AND** no validation error is emitted

#### Scenario: Named phase uses config-specified model when CLI flag is absent

- **GIVEN** `model_routing.phases` maps `sdd-design` to `opus`
- **AND** the user invokes `/sdd-ff fix-something` (no `--opus` flag)
- **WHEN** the orchestrator builds the Task call for the `sdd-design` sub-agent
- **THEN** the Task call MUST use `model: opus`
- **AND** phases not listed in `model_routing.phases` MUST use `model: sonnet`

#### Scenario: Unrecognized phase name in model_routing.phases is ignored

- **GIVEN** `model_routing.phases` contains `sdd-unknown: opus`
- **WHEN** the orchestrator reads the config
- **THEN** the unrecognized phase name is silently ignored
- **AND** no error or warning is emitted

#### Scenario: non-map model_routing.phases treated as absent with WARNING

- **GIVEN** `openspec/config.yaml` contains `model_routing.phases: "opus"` (a string, not a map)
- **WHEN** the orchestrator reads the config
- **THEN** `model_routing.phases` is treated as absent
- **AND** a WARNING is emitted noting the invalid type

---

### Requirement: Model resolution order is CLI flag → per-phase config → Sonnet default
*(Added in: 2026-03-18 by change "specs-opus-routing")*

The orchestrator MUST resolve the model for each Task call using the following deterministic priority chain, evaluated top-to-bottom:
1. CLI flag (`--opus` or `--power`) — if present, all phases use `opus`
2. `model_routing.phases.<phase-name>` — per-phase config override
3. `model: sonnet` — hardcoded default

#### Scenario: CLI flag takes priority over per-phase config

- **GIVEN** `model_routing.phases` maps `sdd-explore` to `sonnet` (explicitly)
- **AND** the user invokes `/sdd-ff --opus fix-something`
- **WHEN** the orchestrator builds the Task call for `sdd-explore`
- **THEN** the Task call MUST use `model: opus` (CLI flag wins)
- **AND** the `model_routing.phases` entry for `sdd-explore` is ignored

#### Scenario: Per-phase config takes priority over Sonnet default

- **GIVEN** `model_routing.phases` maps `sdd-verify` to `opus`
- **AND** the user invokes `/sdd-ff fix-something` (no CLI flag)
- **WHEN** the orchestrator builds the Task call for `sdd-verify`
- **THEN** the Task call MUST use `model: opus` (config wins over default)

#### Scenario: Sonnet default applies when neither CLI flag nor config specifies a model

- **GIVEN** `model_routing.phases` does not contain an entry for `sdd-propose`
- **AND** the user invokes `/sdd-ff fix-something` (no CLI flag)
- **WHEN** the orchestrator builds the Task call for `sdd-propose`
- **THEN** the Task call MUST use `model: sonnet`

---

### Requirement: Commented-out model_routing template is present in openspec/config.yaml
*(Added in: 2026-03-18 by change "specs-opus-routing")*

The `openspec/config.yaml` file MUST include a commented-out `model_routing:` template block so that users can discover and enable model routing by uncommenting it.

#### Scenario: Template block is present and syntactically commented out

- **GIVEN** a project whose `openspec/config.yaml` was set up by this change
- **WHEN** a developer opens `openspec/config.yaml`
- **THEN** they MUST find a commented `# model_routing:` template section
- **AND** the template MUST show at least the `phases:` sub-key with example phase entries
- **AND** the commented block MUST NOT affect YAML parsing (all template lines begin with `#`)

---

## Rules (additions)

- `model_routing:` is optional at the top level — its absence MUST NOT break any skill *(added: 2026-03-18)*
- `model_routing.phases` MUST be a string-to-string map; non-map values are treated as absent with a WARNING *(added: 2026-03-18)*
- Valid model identifiers are `sonnet` and `opus`; other values pass through to the Task tool without validation at the orchestrator level *(added: 2026-03-18)*
- The resolution order is: CLI flag → per-phase config → Sonnet default; this order is fixed and MUST NOT be altered by any config key *(added: 2026-03-18)*
