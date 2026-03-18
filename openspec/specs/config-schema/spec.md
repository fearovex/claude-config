# Spec: config-schema

Change: feature-docs-dimension
Date: 2026-02-26

---

## Overview

This spec describes the observable behavior of the `openspec/config.yaml` schema extension introduced by the `feature-docs-dimension` change. The `feature_docs` section is a new optional top-level key. Its presence modifies how `project-audit` runs Dimension 10; its absence is a valid configuration state.

---

## Requirements

### Requirement: feature_docs is an optional top-level section in openspec/config.yaml

`openspec/config.yaml` MUST accept a `feature_docs` top-level key. Its absence MUST NOT break any existing audit run or any other skill that reads `openspec/config.yaml`.

#### Scenario: config.yaml without feature_docs passes parsing without errors

- **GIVEN** a project whose `openspec/config.yaml` does not contain a `feature_docs` key
- **WHEN** `/project-audit` reads `openspec/config.yaml`
- **THEN** the audit runs without error and produces a valid report
- **AND** D10 falls back to heuristic detection (as specified in the audit-dimensions spec)

#### Scenario: config.yaml with a valid feature_docs section passes parsing without errors

- **GIVEN** a project whose `openspec/config.yaml` contains a `feature_docs` section with valid keys
- **WHEN** `/project-audit` reads `openspec/config.yaml`
- **THEN** D10 uses the declared configuration
- **AND** no parse errors or warnings are emitted about the `feature_docs` key

---

### Requirement: feature_docs section supports three convention values

The `convention` key under `feature_docs` MUST accept exactly three values: `skill`, `markdown`, and `mixed`. Any other value is invalid.

#### Scenario: convention: skill instructs D10 to look for SKILL.md files

- **GIVEN** `feature_docs.convention` is set to `skill`
- **WHEN** D10 evaluates structural quality (D10-b) for any detected feature
- **THEN** D10 applies the SKILL.md structural check (frontmatter + triggers + process + rules) to all detected docs
- **AND** D10 does NOT apply the markdown structural check (H1 + H2) to any doc

#### Scenario: convention: markdown instructs D10 to look for markdown files

- **GIVEN** `feature_docs.convention` is set to `markdown`
- **WHEN** D10 evaluates structural quality (D10-b) for any detected feature
- **THEN** D10 applies the markdown structural check (H1 + H2) to all detected docs
- **AND** D10 does NOT apply the SKILL.md structural check to any doc

#### Scenario: convention: mixed applies the check matching the file's extension

- **GIVEN** `feature_docs.convention` is set to `mixed`
- **WHEN** D10 evaluates structural quality (D10-b) for a detected feature
- **THEN** if the doc file is named `SKILL.md`, D10 applies the SKILL.md structural check
- **AND** if the doc file has a `.md` extension but is NOT named `SKILL.md`, D10 applies the markdown structural check

---

### Requirement: feature_docs.paths declares the directories to search for docs

The `paths` key under `feature_docs` MUST be a list of one or more directory paths (relative to the project root) where feature documentation is expected to be found.

#### Scenario: D10 searches only declared paths when feature_docs.paths is present

- **GIVEN** `feature_docs.paths` lists `["docs/features/", ".claude/skills/"]`
- **WHEN** D10 runs the coverage check (D10-a)
- **THEN** D10 searches for documentation only under `docs/features/` and `.claude/skills/`
- **AND** D10 does NOT scan directories outside the declared paths

#### Scenario: D10 treats paths as relative to the project root

- **GIVEN** `feature_docs.paths` contains `"docs/features/"`
- **WHEN** D10 resolves the path
- **THEN** it resolves to `<project-root>/docs/features/`
- **AND** a path starting with `/` (absolute) is treated as an absolute filesystem path

---

### Requirement: feature_docs.feature_detection declares how features are discovered

The `feature_detection` key under `feature_docs` MUST accept a `strategy` (one of: `directory`, `prefix`, `explicit`) and an optional `root` path and `exclude` list.

#### Scenario: strategy: directory enumerates subdirectories of root as features

- **GIVEN** `feature_detection.strategy` is `directory` and `feature_detection.root` is `src/features/`
- **WHEN** D10 enumerates features
- **THEN** each immediate subdirectory of `src/features/` is treated as a separate feature
- **AND** directories listed in `feature_detection.exclude` are skipped

#### Scenario: Excluded directories do not appear in the D10 coverage table

- **GIVEN** `feature_detection.exclude` lists `["shared", "utils"]` and both `src/features/shared/` and `src/features/utils/` exist
- **WHEN** D10 enumerates features using `strategy: directory`
- **THEN** neither `shared` nor `utils` appears as a row in the D10 coverage table

---

### Requirement: openspec/config.yaml schema documentation is updated

The schema documentation for `openspec/config.yaml` (in `ai-context/` or inline in the config file itself) MUST document the new `feature_docs` key with its sub-keys and accepted values.

#### Scenario: Schema documentation is discoverable in the project

- **GIVEN** a developer reads the `ai-context/` directory or `openspec/config.yaml` of the agent-config project
- **WHEN** they look for documentation of the `feature_docs` section
- **THEN** they find a description of the key, its sub-keys (`convention`, `paths`, `feature_detection`), accepted values, and at least one example block
- **AND** the documentation indicates that `feature_docs` is optional

---

---

### Requirement: verify: top-level section in openspec/config.yaml
*(Added in: 2026-03-17 by change "specs-verify-config")*

`openspec/config.yaml` MUST accept an optional `verify:` top-level key. Its absence MUST NOT break any existing skill run or verification behavior.

#### Scenario: config.yaml without verify: section does not affect sdd-verify behavior

- **GIVEN** a project whose `openspec/config.yaml` does not contain a `verify:` key
- **WHEN** `sdd-verify` reads `openspec/config.yaml`
- **THEN** all verification steps proceed using existing fallback behavior (auto-detection, verify_commands)
- **AND** no error or warning is emitted about the absence of `verify:`

#### Scenario: config.yaml with a valid verify: section is parsed without errors

- **GIVEN** a project whose `openspec/config.yaml` contains a `verify:` section with valid sub-keys
- **WHEN** any skill reads `openspec/config.yaml`
- **THEN** no parse errors or warnings are emitted about the `verify:` key
- **AND** skills that do not use `verify:` ignore it silently

---

### Requirement: verify.test_commands sub-key
*(Added in: 2026-03-17 by change "specs-verify-config")*

The `test_commands` key under `verify:` MUST be a list of strings. It is optional. When present and non-empty, it provides level 2 priority test commands for `sdd-verify`. An empty list MUST be treated as absent.

#### Scenario: verify.test_commands accepted as a list of strings

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    test_commands:
      - "npm test"
      - "npm run lint"
  ```
- **WHEN** `sdd-verify` reads the config
- **THEN** both commands are available for level 2 execution
- **AND** no validation error is emitted

#### Scenario: non-list verify.test_commands treated as absent with WARNING

- **GIVEN** `openspec/config.yaml` contains `verify.test_commands: "npm test"` (a string, not a list)
- **WHEN** `sdd-verify` reads the config
- **THEN** `verify.test_commands` is treated as absent
- **AND** a WARNING is emitted noting the invalid type

---

### Requirement: verify.build_command sub-key
*(Added in: 2026-03-17 by change "specs-verify-config")*

The `build_command` key under `verify:` MUST be a single string. It is optional. When present, it overrides the auto-detected build command in `sdd-verify`.

#### Scenario: verify.build_command accepted as a string

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    build_command: "npm run build:prod"
  ```
- **WHEN** `sdd-verify` runs the build/type-check step
- **THEN** `npm run build:prod` is used instead of the auto-detected build command

#### Scenario: non-string verify.build_command treated as absent with WARNING

- **GIVEN** `openspec/config.yaml` contains `verify.build_command: ["npm run build"]` (a list, not a string)
- **WHEN** `sdd-verify` reads the config
- **THEN** `verify.build_command` is treated as absent
- **AND** a WARNING is emitted noting the invalid type

---

### Requirement: verify.type_check_command sub-key
*(Added in: 2026-03-17 by change "specs-verify-config")*

The `type_check_command` key under `verify:` MUST be a single string. It is optional. When present, it overrides the auto-detected type check command in `sdd-verify`.

#### Scenario: verify.type_check_command accepted as a string

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    type_check_command: "npx tsc --noEmit --strict"
  ```
- **WHEN** `sdd-verify` runs the build/type-check step
- **THEN** `npx tsc --noEmit --strict` is used instead of the auto-detected type check command

---

### Requirement: project-setup populates verify: section on initialization
*(Added in: 2026-03-17 by change "specs-verify-config")*

The `project-setup` skill MUST conditionally emit a `verify:` section in the generated `openspec/config.yaml` when a test runner is detected during stack analysis.

#### Scenario: verify: section emitted when test runner is detected

- **GIVEN** `project-setup` detects a test runner (e.g., `npm test`, `pytest`, `make test`)
- **WHEN** it generates `openspec/config.yaml`
- **THEN** the generated file MUST include a `verify:` section with `test_commands` populated
- **AND** `build_command` and `type_check_command` are included when detected

#### Scenario: verify: section omitted when no test runner is detected

- **GIVEN** `project-setup` cannot detect any test runner
- **WHEN** it generates `openspec/config.yaml`
- **THEN** the `verify:` section MUST be omitted entirely
- **AND** the absence MUST NOT cause errors in any downstream skill

#### Scenario: detection failure does not abort config.yaml generation

- **GIVEN** stack detection encounters an error or inconclusive result
- **WHEN** `project-setup` generates `openspec/config.yaml`
- **THEN** `openspec/config.yaml` is generated without the `verify:` section
- **AND** the generation continues and completes successfully

---

### Requirement: memory-init optionally back-fills verify: section
*(Added in: 2026-03-17 by change "specs-verify-config")*

The `memory-init` skill MUST include a non-blocking final step that appends a `verify:` section to `openspec/config.yaml` when the file exists but the `verify:` key is absent.

#### Scenario: verify: section appended when config.yaml exists and verify: is absent

- **GIVEN** `openspec/config.yaml` exists in the project
- **AND** it does NOT contain a `verify:` key
- **WHEN** `memory-init` runs its verify: back-fill step
- **THEN** a `verify:` section is appended to `openspec/config.yaml`
- **AND** the INFO message `"verify: section added to openspec/config.yaml"` is emitted

#### Scenario: back-fill is idempotent when verify: is already present

- **GIVEN** `openspec/config.yaml` exists and already contains a `verify:` key
- **WHEN** `memory-init` runs its verify: back-fill step
- **THEN** the existing `verify:` section is NOT modified
- **AND** the step is skipped silently

#### Scenario: back-fill is skipped when config.yaml does not exist

- **GIVEN** `openspec/config.yaml` does NOT exist in the project
- **WHEN** `memory-init` runs its verify: back-fill step
- **THEN** the step is skipped
- **AND** at most an INFO-level note is emitted

#### Scenario: back-fill failure does not block memory-init

- **GIVEN** back-fill detection or write fails for any reason
- **WHEN** `memory-init` runs its verify: back-fill step
- **THEN** `memory-init` does NOT produce `status: blocked` or `status: failed`
- **AND** at most an INFO-level note is emitted

---

---

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

## Rules

- The `feature_docs` section is optional — its absence is always valid
- The three `convention` values (`skill`, `markdown`, `mixed`) are the only accepted values; any other value is treated as a configuration error by D10
- The `exclude` list under `feature_detection` applies to all heuristic-discovered features too (when falling back to heuristic mode, the same exclude names apply)
- Schema documentation is the authoritative source for what keys are accepted — SKILL.md should reference the schema documentation rather than duplicating it inline
- The `verify:` section is optional at the top level — its absence MUST NOT break any skill *(added: 2026-03-17)*
- `verify.test_commands` MUST be a list of strings; non-list values are treated as absent with a WARNING *(added: 2026-03-17)*
- `verify.build_command` and `verify.type_check_command` MUST be strings; non-string values are treated as absent with a WARNING *(added: 2026-03-17)*
- `project-setup` emits the `verify:` section only when a test runner is detected; omission is valid *(added: 2026-03-17)*
- `memory-init` back-fill is non-blocking: failures produce at most an INFO note *(added: 2026-03-17)*
- `model_routing:` is optional at the top level — its absence MUST NOT break any skill *(added: 2026-03-18)*
- `model_routing.phases` MUST be a string-to-string map; non-map values are treated as absent with a WARNING *(added: 2026-03-18)*
- Valid model identifiers are `sonnet` and `opus`; other values pass through to the Task tool without validation at the orchestrator level *(added: 2026-03-18)*
- The resolution order is: CLI flag → per-phase config → Sonnet default; this order is fixed and MUST NOT be altered by any config key *(added: 2026-03-18)*
