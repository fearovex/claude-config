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

### Step 7 — Feature discovery

**Goal**: Scaffold `ai-context/features/` with domain stub files so that SDD phases (sdd-propose, sdd-spec) can preload bounded-context knowledge on future runs.

#### 7.1 — Idempotency check

Check whether `ai-context/features/` already exists in the project.

- **If it exists**: skip this step entirely. Log: `"ai-context/features/ already exists — skipping feature discovery"`. Proceed to the final summary.
- **If it does not exist**: continue with 7.2.

#### 7.2 — Detect domain slugs

Collect candidate domain slugs from two sources:

**Priority 1 — `openspec/specs/` subdirectory names:**
If `openspec/specs/` exists, read its top-level subdirectory names. Each subdirectory name is a candidate domain slug (e.g., `openspec/specs/auth/` → slug `auth`).

**Priority 2 — Source code top-level subdirectory names:**
Check whether any of `src/`, `app/`, or `lib/` exist in the project root. If one or more are present, read their top-level subdirectory names as additional candidate domain slugs. Use agent discretion to skip obvious utility/cross-cutting directories (e.g., `shared`, `common`, `utils`, `helpers`, `types`, `assets`) that are unlikely to represent bounded contexts.

After collecting from both sources, **deduplicate** the full slug list (case-insensitive). The final list may be empty.

#### 7.3 — Create `ai-context/features/_template.md`

Always create `ai-context/features/_template.md`, even when no domain slugs were detected.

Use this exact content:

```markdown
<!-- _template.md — DO NOT load this file in SDD phases. Copy it to <domain>.md and fill in each section. -->

# Feature: <Domain Name>

> One-line description of this bounded context.

Last updated: YYYY-MM-DD
Related specs: openspec/specs/<domain>/spec.md

---

## Domain Overview

Write 2–4 sentences describing what this feature or bounded context does, who owns it, and what
core responsibility it holds within the larger system. Explain the problem it solves and its
primary role. Avoid implementation detail here — focus on purpose and scope.

---

## Business Rules and Invariants

List the always-true constraints this domain enforces regardless of code path. Each item should be
a declarative statement that holds in every state of the system. Examples of what to write:

- [Rule 1: state what is always true — e.g. "A refund cannot exceed the original payment amount"]
- [Rule 2: another invariant the domain guarantees]
- [Rule 3: edge-case constraint that distinguishes valid from invalid state]

Do not document implementation choices here — only rules that would remain true even if the
implementation were rewritten from scratch.

---

## Data Model Summary

Describe the key entities this domain owns, their relationships, and any critical field constraints.
This is NOT a full schema — write in plain prose or use a small table for the most important
entities. The goal is to orient a developer quickly, not to duplicate the database schema.

| Entity | Key Fields | Constraints |
|--------|------------|-------------|
| [EntityName] | [field1, field2] | [e.g. "field1 must be unique", "field2 is required"] |
| [EntityName] | [field1, field2] | [constraints] |

Add any relationship notes below the table (e.g. "Order has many OrderItems; an Order with zero
items is invalid").

---

## Integration Points

Document every external system, service, or domain that this bounded context depends on or exposes
an interface to. Include both inbound (things that call into this domain) and outbound (things this
domain calls or emits to).

| System / Service | Direction | Contract |
|-----------------|-----------|----------|
| [ServiceName] | inbound | [what it sends and what this domain expects] |
| [ServiceName] | outbound | [what this domain calls and what it expects back] |
| [OtherDomain] | inbound/outbound | [contract description] |

Add notes for async contracts (events, queues) or infrastructure dependencies (external APIs,
third-party providers) below the table.

---

## Decision Log

Record significant design or implementation decisions made for this domain, in chronological order.
Each entry answers: what was decided, why, and what it constrains going forward. Add entries as
decisions are made — never delete old entries.

### [YYYY-MM-DD] — [Decision name]

**Decision**: [What was decided — state it as a fact, e.g. "We use optimistic locking for
inventory updates rather than pessimistic locking."]

**Rationale**: [Why this decision was made — constraints, trade-offs, context at the time]

**Impact**: [What changed or what future changes are now constrained by this decision]

---

## Known Gotchas

List unexpected behaviors, operational hazards, historical defects, or non-obvious constraints that
a developer working in this domain MUST be aware of. Include things that caused bugs in the past,
edge cases that are easy to miss, and anything that tripped up previous contributors.

- [Gotcha 1: describe the non-obvious behavior and when it manifests]
- [Gotcha 2: describe another hazard, historical failure mode, or surprising constraint]
```

#### 7.4 — Generate domain stub files

For each slug in the deduplicated list (skip if slug is `_template` or starts with `_`):

Create `ai-context/features/<slug>.md` using the canonical six-section structure. Replace the template header comment with the auto-generated header:

```
<!-- Auto-generated by memory-init on [YYYY-MM-DD]. Fill in each section with actual domain knowledge. -->
```

Replace `<Domain Name>` in the title with a title-cased version of the slug (e.g., `auth` → `Auth`, `payments` → `Payments`). Replace `<domain>` in the `Related specs:` line with the actual slug. All placeholder text within the six sections is kept as-is from the template.

**Never** generate a stub file named `_template.md`.

#### 7.5 — Summary entry

Include in the `memory-init` final summary:

- The number of feature stub files generated (e.g., `"Feature discovery: 3 stubs generated (auth, payments, notifications)"`)
- A reminder: `"Stubs contain placeholder text — fill in each section with actual domain knowledge before relying on feature preloading in SDD phases."`
- If the step was skipped due to idempotency: `"Feature discovery skipped — ai-context/features/ already exists."`
- If no slugs were detected: `"Feature discovery: 0 stubs generated. Only _template.md was created in ai-context/features/."`

---

### Step 8 — verify: back-fill (non-blocking)

This step appends a `verify:` section to `openspec/config.yaml` when the file exists but the `verify:` key is absent. It is **non-blocking**: any failure (config.yaml absent, detection error, write error) MUST produce at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

#### 8.1 — Existence check

```
if openspec/config.yaml does not exist:
    → log: "INFO: openspec/config.yaml not found — verify: back-fill skipped"
    → return (skip this step entirely)
```

#### 8.2 — Idempotency check

```
if openspec/config.yaml already contains a verify: key:
    → skip silently (idempotent — never overwrite user-set values)
    → return
```

#### 8.3 — Command detection

Use the same detection logic as `project-setup` Step 4:

```
detect_test_runner():
  if package.json with scripts.test → "npm test" (or yarn/pnpm variant)
  elif pyproject.toml / pytest.ini / setup.cfg → "pytest"
  elif Makefile with test target → "make test"
  elif build.gradle or gradlew → "./gradlew test"
  elif mix.exs → "mix test"
  else → None

detect_build_command():
  if package.json with scripts.build → "npm run build" (or yarn/pnpm variant)
  elif package.json with scripts.typecheck → "npm run typecheck"
  elif tsconfig.json + TypeScript in devDependencies → "npx tsc --noEmit"
  else → None
```

If detection fails for any reason, log `"INFO: verify: back-fill — command detection failed"` and return.

#### 8.4 — Append verify: section

If a test runner was detected, append the following block to `openspec/config.yaml`:

```yaml

# ---------------------------------------------------------------------------
# verify (optional) — Auto-detected verification commands for /sdd-verify
# ---------------------------------------------------------------------------
# Added by memory-init back-fill. Edit as needed.
# Priority: verify_commands (level 1) > verify.test_commands (level 2) > auto-detection (level 3)
verify:
  test_commands:
    - "[detected test command]"
  # build_command: "[detected build command]"     # uncomment if needed
  # type_check_command: "[detected type check]"   # uncomment if needed
```

If no test runner was detected, omit the `verify:` section (absence is valid).

If the write fails for any reason, log `"INFO: verify: back-fill — could not write to openspec/config.yaml"` and return.

#### 8.5 — Emit INFO on success

```
→ log: "INFO: verify: section added to openspec/config.yaml"
```

Include in the `memory-init` final summary:
- `"verify: back-fill: section added to openspec/config.yaml"` (if written)
- `"verify: back-fill: skipped (config.yaml absent)"` (if no config.yaml)
- `"verify: back-fill: skipped (verify: already present)"` (if idempotent)
- `"verify: back-fill: skipped (no test runner detected)"` (if no runner found)

---

## Rules

- I read real code to infer, I never invent
- I mark with [To confirm] what I cannot determine with certainty
- I never overwrite existing ai-context/ files without asking — offer intelligent merge
- If `ai-context/` already exists, I warn the user and suggest `/memory-update` instead
- All generated content MUST be based on real detected evidence, not templates with placeholders
- The verify: back-fill step (Step 8) is non-blocking — any failure produces at most an INFO note and MUST NOT produce `status: blocked` or `status: failed`
