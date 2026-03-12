# Spec: global-permissions

Change: batch-audit-bash-calls
Date: 2026-02-26

## Overview

This spec describes the observable state of `settings.json` after this change is applied. It covers only the addition of `Bash` to the `permissions.allow` array. All other fields (`alwaysThinkingEnabled`, `effortLevel`, `model`, `mcpServers`) are out of scope and MUST NOT be modified.

---

## Requirements

### Requirement: Bash tool pre-approved in settings.json

`settings.json` MUST contain `"Bash"` as an entry in the `permissions.allow` array after this change is applied.

#### Scenario: settings.json after apply contains Bash permission

- **GIVEN** the change has been applied and `install.sh` has been run
- **WHEN** `~/.claude/settings.json` is read
- **THEN** the `permissions.allow` array contains `"Bash"`
- **AND** the array still contains `"Read"`, `"Glob"`, and `"Grep"` (existing entries are preserved)

#### Scenario: No other settings.json fields are modified

- **GIVEN** the pre-change `settings.json` has `alwaysThinkingEnabled: true`, `effortLevel: "medium"`, `model: "sonnet"`, and the two `mcpServers` entries
- **WHEN** the change is applied
- **THEN** all of those fields remain identical in value and structure
- **AND** no new top-level keys are added to `settings.json`
- **AND** the `mcpServers` block is unchanged

#### Scenario: Bash entry is a plain string in the allow array

- **GIVEN** the existing `permissions.allow` entries are plain strings (`"Read"`, `"Glob"`, `"Grep"`)
- **WHEN** `"Bash"` is added
- **THEN** it is added as a plain string in the same array, not as an object or nested structure

---

### Requirement: settings.json remains valid JSON after the change

The file MUST be parseable as valid JSON after the edit.

#### Scenario: JSON validity check

- **GIVEN** the change has been applied
- **WHEN** `settings.json` is parsed by a JSON parser
- **THEN** parsing succeeds with no syntax errors
- **AND** the file passes `jq . settings.json` without error (or equivalent JSON validation)

---

### Requirement: settings.json in repo is the source of truth

The edit MUST be made to `settings.json` in the `agent-config` repo, not directly in `~/.claude/settings.json`.

#### Scenario: Repo file is edited, then deployed via install.sh

- **GIVEN** the change is applied to `C:/Users/juanp/agent-config/settings.json`
- **WHEN** `install.sh` is run
- **THEN** `~/.claude/settings.json` reflects the updated `permissions.allow` array
- **AND** no direct edits were made to `~/.claude/settings.json`

---

## Rules

- Only `permissions.allow` is modified — no other key in `settings.json` is touched
- The `Bash` entry does not narrow scope (no path restrictions, no command restrictions) — it pre-approves Bash tool calls globally, consistent with how `Read`, `Glob`, and `Grep` are pre-approved
- The security implication (global Bash pre-approval) is accepted per the proposal's risk analysis: the audit skill enforces read-only by convention in SKILL.md, not by permission scoping
