# Delta Spec: sdd-phase-context-loading

Change: sdd-project-context-awareness
Date: 2026-03-10
Base: openspec/specs/sdd-phase-context-loading/spec.md

---

## ADDED — New requirements

### Requirement: Mandatory project context loading step in all SDD phase skills

All six SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) MUST execute a **Step 0 — Load project context** block as the first step of their Process section, before any analysis or output generation.

Step 0 MUST attempt to read the following files from the project root:
1. `ai-context/stack.md` — tech stack and versions
2. `ai-context/architecture.md` — architectural decisions and rationale
3. `ai-context/conventions.md` — naming and code patterns

Step 0 MUST also read the **Skills Registry** section of the project's `CLAUDE.md` to identify which skills are registered for the project. The project CLAUDE.md is located at the project root (not `~/.claude/CLAUDE.md`).

If any of the above files is absent, Step 0 MUST log the missing file name as an INFO-level note and continue execution. Step 0 MUST NOT abort or set `status: blocked` or `status: failed` due to any missing file.

If all four sources are absent, Step 0 MUST log a single INFO-level note (e.g., "ai-context/ not found — proceeding with global defaults") and continue.

The loaded context MUST be used by subsequent steps of that phase skill to:
- Align output with the project's actual tech stack (not assumed defaults)
- Respect documented architectural decisions and constraints
- Apply project-specific naming and code conventions
- Reference only skills registered in the project's Skills Registry

#### Scenario: Step 0 loads all context files successfully

- **GIVEN** the project has `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, and a `CLAUDE.md` with a `## Skills Registry` section
- **WHEN** any SDD phase skill executes Step 0
- **THEN** all four sources are read before any other step begins
- **AND** the loaded content is available to all subsequent steps within that execution

#### Scenario: Step 0 gracefully handles missing ai-context files

- **GIVEN** the project does not have an `ai-context/` directory
- **WHEN** any SDD phase skill executes Step 0
- **THEN** Step 0 logs an INFO-level note listing the missing files
- **AND** the skill continues to its next step without error
- **AND** `status` in the output MUST be `ok` or `warning`, NEVER `blocked` or `failed` due to missing ai-context files alone

#### Scenario: Step 0 gracefully handles missing project CLAUDE.md

- **GIVEN** the project does not have a `CLAUDE.md` at the project root
- **WHEN** any SDD phase skill executes Step 0
- **THEN** Step 0 logs an INFO-level note that project CLAUDE.md was not found
- **AND** the skill proceeds to its next step without error
- **AND** skill recommendations in subsequent steps fall back to the global skill catalog

#### Scenario: Step 0 output informs phase skill output quality

- **GIVEN** the project's `ai-context/stack.md` documents "TypeScript 5.4, React 19, Tailwind 4"
- **AND** a sub-agent executes `sdd-design` for a UI change
- **WHEN** `sdd-design` completes its execution
- **THEN** the resulting `design.md` MUST reference TypeScript, React 19, and Tailwind 4 rather than generic or assumed stack defaults
- **AND** the `design.md` MUST NOT recommend a skill not registered in the project's CLAUDE.md Skills Registry

#### Scenario: Step 0 warns when ai-context files appear stale

- **GIVEN** `ai-context/stack.md` contains a `Last analyzed:` or `Last updated:` date older than 7 days from the current date
- **WHEN** any SDD phase skill executes Step 0
- **THEN** Step 0 SHOULD emit a WARNING-level note recommending the user run `/project-analyze` to refresh the context
- **AND** the skill MUST continue and use the stale data rather than aborting

#### Scenario: Step 0 applies only to the project being changed, not ~/.claude/

- **GIVEN** Claude is executing an SDD phase on a project at `/path/to/my-project`
- **WHEN** Step 0 runs
- **THEN** it reads `ai-context/stack.md` from `/path/to/my-project/ai-context/stack.md`
- **AND** it MUST NOT read from `~/.claude/ai-context/stack.md` as a substitute

---

### Requirement: sdd-design must cross-reference project Skills Registry

`sdd-design` MUST use the project Skills Registry loaded in Step 0 to constrain skill and technology recommendations. Specifically:

- When recommending a skill or technology pattern in `design.md`, `sdd-design` MUST check whether a corresponding skill exists in the project's Skills Registry.
- If a recommended approach has a registered skill, `sdd-design` MUST reference that skill by name (e.g., "See `react-19` skill for React patterns").
- If a relevant skill exists in the global catalog (`~/.claude/skills/`) but is NOT registered in the project, `sdd-design` MAY note it as an optional addition but MUST NOT treat it as available.

#### Scenario: Design references a registered skill

- **GIVEN** the project's CLAUDE.md Skills Registry includes `typescript` and `zod-4`
- **AND** the change requires input validation logic
- **WHEN** `sdd-design` produces `design.md`
- **THEN** `design.md` MUST reference the `zod-4` skill for validation patterns
- **AND** MUST NOT recommend a validation library not covered by registered skills without explicit justification

#### Scenario: Design notes an unregistered but relevant global skill

- **GIVEN** the project's Skills Registry does NOT include `playwright`
- **AND** the change involves UI behavior that could benefit from end-to-end testing
- **WHEN** `sdd-design` produces `design.md`
- **THEN** `design.md` MAY note that `playwright` is available in the global catalog as an optional addition
- **AND** MUST clearly mark it as not currently registered (e.g., "[optional — not registered in project]")

---

### Requirement: Context loading is non-intrusive to the existing domain context preload (Step 0 dual-block)

The existing optional domain context preload in `sdd-propose` and `sdd-spec` (specified in the base `sdd-phase-context-loading` spec) MUST remain in place after this change. The new mandatory Step 0 for project context loading MUST be sequenced **before** the existing domain context preload block, or merged into a single Step 0 with two sub-steps:

1. Sub-step A: Mandatory project context (stack.md, architecture.md, conventions.md, Skills Registry)
2. Sub-step B: Optional domain context preload (ai-context/features/ heuristic — unchanged from base spec)

The two sub-steps MUST NOT conflict. Sub-step B enrichment context is additive to Sub-step A.

#### Scenario: Both sub-steps execute together in sdd-spec

- **GIVEN** the project has `ai-context/stack.md` and `ai-context/features/auth.md`
- **AND** the change name is `auth-session-refresh`
- **WHEN** `sdd-spec` executes Step 0
- **THEN** Sub-step A reads `stack.md`, `architecture.md`, `conventions.md`, and `CLAUDE.md`
- **AND** Sub-step B loads `auth.md` as a domain context match
- **AND** the spec produced reflects both the tech stack conventions AND the auth domain business rules

#### Scenario: Sub-step A failure does not affect Sub-step B

- **GIVEN** `ai-context/stack.md` does not exist
- **AND** `ai-context/features/auth.md` exists and matches the change name
- **WHEN** `sdd-spec` executes Step 0
- **THEN** Sub-step A logs a missing-file INFO note for `stack.md`
- **AND** Sub-step B still executes and loads `auth.md` normally
- **AND** the spec proceeds without error

---

## MODIFIED — Modified requirements

### Requirement: sdd-spec optional domain context preload — placement clarification _(modified)_

The placement of the domain context preload (Sub-step B) within `sdd-spec` is updated to be explicit within the unified Step 0:

After this change, `sdd-spec` Step 0 reads BOTH:
- Project context files (stack.md, architecture.md, conventions.md, project CLAUDE.md)
- Matching `ai-context/features/<domain>.md` files via the slug-matching heuristic

Both reads happen in Step 0, before Step 1 (Read prior artifacts for spec content).
_(Before: domain context preload was described as part of Step 1 "Read prior artifacts")_

#### Scenario: Step 0 completes before Step 1 begins _(modified)_

- **GIVEN** `sdd-spec` is executing for change `auth-session-refresh`
- **WHEN** `sdd-spec` starts
- **THEN** Step 0 (project context + domain context preload) completes in full
- **AND** Step 1 (reading `proposal.md` and existing domain `spec.md`) begins only after Step 0 completes
