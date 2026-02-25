# project-setup

> Deploys the complete SDD architecture with a hybrid memory layer in the current project.

**Triggers**: project-setup, initialize project, setup sdd, configure claude project, new sdd project

---

## What this skill does

When the user runs `/project-setup`, I analyze the current project and generate:
1. `CLAUDE.md` at the project root with real detected context
2. `docs/ai-context/` with the 5 memory files initialized
3. `openspec/config.yaml` for the SDD cycle
4. Registry of relevant skills based on the detected stack

---

## Setup Process

### Step 1 — Project detection

I read and analyze:
- `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `pom.xml`
- Folder structure (src/, app/, lib/, tests/, etc.)
- Configuration files (tsconfig, eslint, prettier, etc.)
- README.md if it exists
- Existing docs folders
- `.git/` to confirm it is a repository

**I infer:**
- Main language and version
- Framework(s) in use
- Database / ORM
- Testing tools
- Build / bundler tools
- Detected naming conventions (camelCase, snake_case, etc.)
- Folder structure (feature-based, layer-based, monorepo, etc.)

### Step 2 — Generate project CLAUDE.md

I create `CLAUDE.md` at the root with these sections:

```markdown
# [Project Name]

## Stack
[Detected stack with versions]

## Architecture
[Explained folder structure]
[Detected architectural pattern]

## Conventions
[Detected naming conventions]
[Observed code patterns]

## Important Commands
[Scripts from package.json / Makefile / etc.]

## Project Memory
At the start of each session, read the relevant files in docs/ai-context/:
- docs/ai-context/stack.md — Detailed technical stack
- docs/ai-context/architecture.md — Architecture decisions
- docs/ai-context/conventions.md — Team conventions
- docs/ai-context/known-issues.md — Known bugs and gotchas
- docs/ai-context/changelog-ai.md — AI change history

After completing significant work: update the relevant files or
run /memory-update so the AI updates them.

## Active Skills
[List of relevant skills for this project]

## SDD — Spec-Driven Development
This project uses SDD. Artifacts live in openspec/.
To start a change: /sdd-new <change-name>
For fast cycle: /sdd-ff <change-name>
```

### Step 3 — Initialize docs/ai-context/

I create the 5 files with real content based on what was detected:

#### `docs/ai-context/stack.md`
```markdown
# Technical Stack

Last updated: [date]

## Language
- [Language]: [version]

## Main Framework
- [Framework]: [version]
- [Relevant configuration details]

## Database / ORM
- [If applicable]

## Testing
- [Testing framework]
- [Commands to run tests]

## Build / Bundler
- [Tool]: [version]
- [Build command]
- [Dev command]

## Key Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| [name] | [version] | [what it does] |
```

#### `docs/ai-context/architecture.md`
```markdown
# Project Architecture

Last updated: [date]

## Architectural Pattern
[Detected: feature-based / layer-based / clean architecture / etc.]

## Folder Structure
[Explained tree with the purpose of each folder]

## Architecture Decisions
| Decision | Choice | Alternatives | Reason |
|----------|--------|--------------|--------|
[Inferred from existing code]

## Data Flow
[Description of the main flow]

## Entry Points
[Main entry points of the system]
```

#### `docs/ai-context/conventions.md`
```markdown
# Project Conventions

Last updated: [date]

## Naming
- Files: [detected]
- Variables/Functions: [detected]
- Classes/Types: [detected]
- Constants: [detected]

## File Structure
[How files of each type are organized]

## Code Patterns
[Patterns detected in existing code]

## Git
[Commit conventions if detected]
[Branch strategy if detected]

## Testing
[Where tests live]
[Test naming conventions]
```

#### `docs/ai-context/known-issues.md`
```markdown
# Known Issues

Last updated: [date]

## Active Bugs
[Empty at start — filled during development]

## Gotchas and Limitations
[Anything unusual detected in existing code]

## Identified Technical Debt
[Problematic patterns detected]

## Workarounds in Use
[If there are workarounds in the code, document them here]
```

#### `docs/ai-context/changelog-ai.md`
```markdown
# AI Changelog

This file records significant changes made by Claude.

## Entry Format
### [YYYY-MM-DD] — [Change name]
**What was done**: [description]
**Modified files**: [list]
**Decisions made**: [relevant decisions]
**Notes**: [anything important]

---

[Entries are added here chronologically]
```

### Step 4 — Create openspec/config.yaml

```yaml
project:
  name: "[detected name]"
  description: "[description from README or inferred]"
  stack:
    language: "[language]"
    framework: "[framework]"
    database: "[db or none]"
  conventions:
    naming: "[snake_case|camelCase|kebab-case]"
    structure: "[feature|layer|mono]"

artifact_store:
  mode: openspec

rules:
  proposal:
    - "Must include rollback plan"
    - "Must define measurable success criteria"
  specs:
    - "Use Given/When/Then for all scenarios"
    - "Include edge cases and error states"
  design:
    - "Each decision must have a justification"
    - "Prefer existing project patterns"
  tasks:
    - "Atomic and verifiable tasks"
    - "Include file paths in description"
  apply:
    - "Follow project conventions"
    - "Run tests before marking complete"
  verify:
    - "Verify compliance with specs first"
    - "Then verify adherence to design"
```

### Step 5 — Final report

I present to the user:
```
✅ Project configured: [name]

Detected stack:
  - [language + version]
  - [framework + version]
  - [testing framework]

Files created:
  - CLAUDE.md
  - docs/ai-context/stack.md
  - docs/ai-context/architecture.md
  - docs/ai-context/conventions.md
  - docs/ai-context/known-issues.md
  - docs/ai-context/changelog-ai.md
  - openspec/config.yaml

Next steps:
  1. Review and adjust CLAUDE.md with details I could not detect
  2. To start a change: /sdd-new <name>
  3. To create project-specific skills: /skill-create <name>
```

---

## Rules

- NEVER overwrite existing files without warning and asking for confirmation
- If `CLAUDE.md` already exists, I offer an intelligent merge or creating a backup
- If `docs/ai-context/` already exists, I offer to update only what is missing
- I always read real code — I never invent the stack
- If I cannot determine something with certainty, I mark it as `[To confirm]`
