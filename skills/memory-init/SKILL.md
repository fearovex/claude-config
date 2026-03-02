---
name: memory-init
description: >
  Generates the 5 ai-context/ memory files from scratch by reading the current project.
  Trigger: /memory-init, initialize memory, generate ai-context.
format: procedural
---

# memory-init

> Generates the hybrid memory layer (ai-context/) from scratch by reading the project.

**Triggers**: /memory-init, initialize memory, generate ai-context, create project memory

---

## Purpose

Creates the 5 core memory files by deeply reading the project's source code, configuration, and structure. Use when the project does not yet have `ai-context/`.

---

## Process

### Step 1 — Project inventory

I read in depth:
- Configuration files (package.json, pyproject.toml, etc.)
- Folder structure
- README.md and any existing documentation
- Representative code files (entry points, models, main components)
- Existing tests
- CI/CD configurations if they exist

### Step 2 — Generate stack.md

```markdown
# Technical Stack

Last updated: [YYYY-MM-DD]

## Main Language
- **[Language]** [version]

## Framework(s)
- **[Framework]** [version] — [purpose]
- **[Framework2]** [version] — [purpose]

## Database
- **[DB]** [version] — [ORM if applicable]

## Testing
- **[Testing framework]** [version]
- Command: `[command to run tests]`
- Coverage: [if configured]

## Build & Dev
- **[Bundler/Builder]** [version]
- Dev: `[command]`
- Build: `[command]`
- Preview: `[command if it exists]`

## Key Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| [name] | [version] | [what it does in the project] |

## Quality Tools
- Linter: [eslint/flake8/etc. + config]
- Formatter: [prettier/black/etc.]
- Type checker: [tsc/mypy/etc.]
```

### Step 3 — Generate architecture.md

```markdown
# Project Architecture

Last updated: [YYYY-MM-DD]

## Overview
[2-3 lines describing what the project does]

## Architectural Pattern
[Feature-based / Layer-based / Clean Architecture / Hexagonal / etc.]
[Rationale if it can be inferred]

## Folder Structure
```
[main folder tree with description of each]
```

## Architecture Decisions
| Decision | Choice | Alternatives | Inferred Reason |
|----------|--------|--------------|-----------------|
| [decision] | [what was chosen] | [alternatives] | [why] |

## Main Flow
[Description of the most common data flow / request]

## Entry Points
- [File/path]: [what it is]

## External Integrations
- [Service/API]: [how it integrates]
```

### Step 4 — Generate conventions.md

```markdown
# Project Conventions

Last updated: [YYYY-MM-DD]

## Naming
- **Files**: [detected: kebab-case / snake_case / PascalCase]
- **Variables/Functions**: [detected]
- **Classes/Types/Interfaces**: [detected]
- **Constants**: [detected]
- **Tests**: [detected pattern: *.test.ts / test_*.py / etc.]

## File Organization
[How files are organized according to the detected pattern]
[Where tests live relative to code]

## Detected Code Patterns
[Recurring patterns observed in real code]

## Commits
[Convention if detected in history: conventional commits, etc.]

## Branches
[Strategy if detected: main/develop, feature branches, etc.]
```

### Step 5 — Generate known-issues.md

```markdown
# Known Issues and Gotchas

Last updated: [YYYY-MM-DD]

## Detected Technical Debt
[Code with TODO/FIXME/HACK comments]
[Problematic patterns observed]

## Project Gotchas
[Unusual or non-obvious things detected in the code]

## Current Limitations
[Functional limitations evident in the code]

## Workarounds in Use
[If there are workarounds documented in the code, list them here]

---
*This file is updated during development. Run /memory-update after resolving issues.*
```

### Step 6 — Generate changelog-ai.md

```markdown
# AI Changelog

This file records significant changes made by Claude.
Updated by running /memory-update at the end of a work session.

## Format
### [YYYY-MM-DD] — [Change name]
**What was done**: [description]
**Modified files**: [list]
**Decisions made**: [relevant decisions]
**Notes**: [anything important for future sessions]

---

*Empty history — will be filled during development.*
```

---

## Rules

- I read real code to infer, I never invent
- I mark with [To confirm] what I cannot determine with certainty
- I never overwrite existing ai-context/ files without asking — offer intelligent merge
- If `ai-context/` already exists, I warn the user and suggest `/memory-update` instead
- All generated content MUST be based on real detected evidence, not templates with placeholders
