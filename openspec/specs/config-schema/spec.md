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

## Rules

- The `feature_docs` section is optional — its absence is always valid
- The three `convention` values (`skill`, `markdown`, `mixed`) are the only accepted values; any other value is treated as a configuration error by D10
- The `exclude` list under `feature_detection` applies to all heuristic-discovered features too (when falling back to heuristic mode, the same exclude names apply)
- Schema documentation is the authoritative source for what keys are accepted — SKILL.md should reference the schema documentation rather than duplicating it inline
