# Spec: system-documentation

Change: feature-domain-knowledge-layer
Date: 2026-03-03

---

## Requirements

### Requirement: CLAUDE.md memory layer table updated

`CLAUDE.md` (both the repo copy at `agent-config/CLAUDE.md` and the runtime copy deployed via `install.sh`) MUST be updated to document `ai-context/features/*.md` as a first-class memory artifact in the Project Memory section.

The update MUST add a row to the memory layer table:

| File | Content |
|------|---------|
| `ai-context/features/*.md` | Feature-level domain knowledge: business rules, invariants, data model summary, integration points, decision log, known gotchas per bounded context |

#### Scenario: CLAUDE.md memory table includes the new row after apply

- **GIVEN** the change is applied
- **WHEN** `CLAUDE.md` is opened and the Project Memory section is read
- **THEN** the memory layer table contains a row for `ai-context/features/*.md`
- **AND** the row's Content column accurately describes what goes in feature files

#### Scenario: Skill Overlap table is updated or remains consistent

- **GIVEN** the Skill Overlap table in CLAUDE.md documents when to use `/memory-init`, `/project-analyze`, and `/memory-update`
- **WHEN** the change is applied
- **THEN** the Skill Overlap table MUST mention that `memory-init` creates `ai-context/features/` stubs when the directory is absent
- **AND** the table MUST mention that `memory-update` updates `ai-context/features/<domain>.md` with session-acquired domain knowledge
- **AND** the table MUST clarify that `project-analyze` does NOT write to `ai-context/features/` (explicit ownership rule)

---

### Requirement: CLAUDE.md Skills Registry updated

`CLAUDE.md` Skills Registry MUST include an entry for the new `feature-domain-expert` skill.

The entry MUST be placed in the appropriate category (Tools / Platforms or a new "Domain Knowledge" category if warranted) with the format:
```
- `~/.claude/skills/feature-domain-expert/SKILL.md` — [brief description]
```

#### Scenario: CLAUDE.md Skills Registry contains feature-domain-expert entry after apply

- **GIVEN** the change is applied
- **WHEN** `CLAUDE.md` is opened and the Skills Registry section is read
- **THEN** an entry for `~/.claude/skills/feature-domain-expert/SKILL.md` is present
- **AND** the entry description accurately summarizes what the skill does

---

### Requirement: ai-context/architecture.md updated with new artifact entry

`ai-context/architecture.md` MUST be updated to document `ai-context/features/*.md` in the Communication between skills via artifacts table.

The new row MUST specify:
- **Artifact**: `ai-context/features/*.md`
- **Producer**: `memory-init` (scaffold, fires only when directory absent) / `memory-update` (session updates)
- **Consumer**: `sdd-propose`, `sdd-spec` (optional domain context preload)
- **Location**: `ai-context/features/` in project
- **Notes**: a brief note clarifying that `project-analyze` does NOT write to `ai-context/features/` — only `memory-update` does; and that `_template.md` is never loaded by SDD phases

#### Scenario: architecture.md artifact table includes the new entry after apply

- **GIVEN** the change is applied
- **WHEN** `ai-context/architecture.md` is opened and the artifact communication table is read
- **THEN** a row for `ai-context/features/*.md` is present with Producer, Consumer, and Location columns filled
- **AND** the notes column or an adjacent comment clarifies the write-ownership rule

#### Scenario: architecture.md write-ownership rule is explicit

- **GIVEN** the new artifact table row for `ai-context/features/*.md`
- **WHEN** a developer reads the architecture doc
- **THEN** it is unambiguous that `memory-update` is the only skill that writes to `ai-context/features/*.md` during a session
- **AND** it is unambiguous that `project-analyze` does NOT touch `ai-context/features/`

---

### Requirement: install.sh deploys ai-context/features/ to runtime

`install.sh` already copies all `ai-context/` contents to `~/.claude/ai-context/`. After this change is applied, `ai-context/features/` and its contents MUST be included in the deployed runtime without any modification to `install.sh` (assuming `install.sh` uses a wildcard or directory-level copy operation).

#### Scenario: install.sh deploys ai-context/features/ correctly

- **GIVEN** `ai-context/features/` exists in the repo with `_template.md` and at least one example feature file
- **WHEN** `install.sh` is run
- **THEN** `~/.claude/ai-context/features/` is created at the destination
- **AND** all files in `ai-context/features/` are present at `~/.claude/ai-context/features/`
- **AND** the contents of each file are identical to the source

#### Scenario: install.sh does not need modification

- **GIVEN** `install.sh` uses a wildcard or directory copy that includes all of `ai-context/`
- **WHEN** `ai-context/features/` is added to the repo
- **THEN** `install.sh` deploys it without any change to the script
- **AND** the `--no change needed` assertion holds: this requirement is verifiable by running `install.sh` after apply and checking for `~/.claude/ai-context/features/`

