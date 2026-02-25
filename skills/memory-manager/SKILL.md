# memory-manager

> Initializes and updates the hybrid memory layer of the project (ai-context/).

**Triggers**: memory-init, memory-update, update memory, initialize memory, ai-context, project context, project memory

---

## Two modes of operation

### `/memory-init`
Generates the 5 memory files from scratch by reading the current project.
Use when: the project does not yet have `ai-context/`.

### `/memory-update`
Updates existing files with the work done in the current session.
Use when: significant work has been completed and the memory should reflect the current state.

---

## Process: /memory-init

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

## Process: /memory-update

### When to use
After:
- Completing an SDD cycle (/sdd-archive)
- Making significant architectural changes
- Resolving important bugs
- Changing project conventions or patterns
- At the end of a long work session

### Step 1 — Analyze what changed in this session

I review the context of the current session:
- Which files were created/modified
- What decisions were made
- What problems were found and resolved
- If the stack changed (new deps, updated versions)

### Step 2 — Determine which files to update

| If in the session... | I update |
|---------------------|----------|
| Dependencies were added/removed | `stack.md` |
| Architecture decisions were made | `architecture.md` |
| Conventions were defined/changed | `conventions.md` |
| Bugs were found/resolved | `known-issues.md` |
| Any significant change was made | `changelog-ai.md` |

### Step 3 — Update stack.md (if applicable)

I only update the sections that changed. I add without deleting history:
- New dependency: add it to the table with its version and purpose
- Removed dependency: mark it as `~~[name]~~ (removed [date])`
- Updated version: update the number

### Step 4 — Update architecture.md (if applicable)

If new decisions were made, I add them to the decisions table:
```markdown
| [new decision] | [choice] | [alternatives] | [actual reason] |
```

If the folder structure changed, I update the tree.

### Step 5 — Update known-issues.md (if applicable)

- Resolved issues: move them to a `## Resolved Issues` section with resolution date
- New issues found: add them to the corresponding section

### Step 6 — Add entry to changelog-ai.md

I always add an entry at the top (chronologically descending):

```markdown
### [YYYY-MM-DD] — [Descriptive name of the work]
**What was done**: [concise description]
**Modified files**:
- `path/file.ext` — [what changed]
**Decisions made**:
- [decision relevant for future sessions]
**Notes**: [anything important]
```

### Step 7 — Summary for the user

```
✅ Memory updated

Modified files:
  - ai-context/stack.md — 2 dependencies added
  - ai-context/known-issues.md — 1 issue resolved, 1 new
  - ai-context/changelog-ai.md — entry added

No changes:
  - ai-context/architecture.md
  - ai-context/conventions.md
```

---

## Rules

- I read real code to infer, I never invent
- I update incrementally, I never overwrite everything
- I mark with [To confirm] what I cannot determine with certainty
- I preserve history: resolved items are moved, not deleted
- If `ai-context/` does not exist and `/memory-update` is run, I suggest `/memory-init` first
