# Delta Spec: sdd-phase-context-loading

Change: 2026-03-14-specs-as-subagent-background
Date: 2026-03-14
Base: openspec/specs/sdd-phase-context-loading/spec.md

## ADDED — New requirements

### Requirement: sdd-explore loads master specs from SPEC CONTEXT before analysis

`sdd-explore` MUST read all spec files listed in the SPEC CONTEXT block of its prompt before
beginning any analysis work. If no SPEC CONTEXT block is present, `sdd-explore` MUST list
`openspec/specs/` and select up to 3 most-relevant domain directories by slug word matching,
then read the corresponding `spec.md` files.

This spec-loading step MUST be added as a named step at the start of the `sdd-explore`
`## Process` section, immediately after Step 0 (Load project context).

The step MUST be non-blocking: if a listed spec file does not exist or cannot be read, the
sub-agent logs an INFO-level note and continues.

#### Scenario: sdd-explore reads spec files from SPEC CONTEXT before analyzing

- **GIVEN** the orchestrator provides a SPEC CONTEXT block listing `openspec/specs/sdd-orchestration/spec.md`
- **WHEN** `sdd-explore` begins execution
- **THEN** it MUST read `openspec/specs/sdd-orchestration/spec.md` before writing `exploration.md`
- **AND** the `exploration.md` MUST reflect awareness of the behavioral contracts defined in that spec
- **AND** the exploration MUST NOT describe existing behavior that contradicts the loaded spec

#### Scenario: sdd-explore falls back to self-selected domains when SPEC CONTEXT is absent

- **GIVEN** `sdd-explore` receives a prompt with no SPEC CONTEXT block
- **WHEN** `sdd-explore` begins its spec-loading step
- **THEN** it MUST list `openspec/specs/` to discover available domains
- **AND** it MUST load up to 3 spec files that most closely match the change slug words
- **AND** if `openspec/specs/` is empty or absent, it MUST skip this step silently

#### Scenario: Unreadable spec file does not block exploration

- **GIVEN** the SPEC CONTEXT block lists a spec file that does not exist
- **WHEN** `sdd-explore` attempts to read the file
- **THEN** it MUST log an INFO-level note: `INFO: [path] not found — skipping.`
- **AND** exploration MUST continue normally

---

### Requirement: sdd-propose loads master specs from SPEC CONTEXT before writing proposal

`sdd-propose` MUST read all spec files listed in the SPEC CONTEXT block before writing
`proposal.md`. The spec-loading step MUST be added as a named sub-step within Step 0,
immediately after Step 0a (project context) and Step 0b (domain feature preload), as Step 0c.

When SPEC CONTEXT is absent, `sdd-propose` MUST apply the same fallback heuristic as
`sdd-explore` (self-select up to 3 relevant domains from `openspec/specs/`).

The spec-loading step MUST be non-blocking.

#### Scenario: sdd-propose reads spec files before authoring proposal

- **GIVEN** the orchestrator provides SPEC CONTEXT listing `openspec/specs/sdd-orchestration/spec.md`
- **WHEN** `sdd-propose` executes Step 0c
- **THEN** it MUST read the listed spec file
- **AND** the written `proposal.md` MUST NOT propose behavior that directly contradicts the
  loaded spec's existing requirements

#### Scenario: Step 0c is additive to Steps 0a and 0b

- **GIVEN** `sdd-propose` executes with a project containing both `ai-context/` files and a matching
  `ai-context/features/<domain>.md`
- **WHEN** Step 0 runs
- **THEN** Step 0a reads global project context files (non-blocking)
- **AND** Step 0b reads matching feature domain files (non-blocking)
- **AND** Step 0c reads relevant master spec files from SPEC CONTEXT or fallback (non-blocking)
- **AND** all three sets of context are available to subsequent steps

---

### Requirement: sdd-spec loads master specs from SPEC CONTEXT as Step 0c

`sdd-spec` MUST add Step 0c (spec context loading) identical in contract to the `sdd-propose`
Step 0c: reads SPEC CONTEXT files, falls back to self-selection, non-blocking.

The loaded master spec files inform the delta spec author by:
- Revealing which requirements already exist (so the delta correctly uses MODIFIED or REMOVED)
- Surfacing terminology and scenario patterns used in the existing spec
- Preventing duplication of already-specified behavior

#### Scenario: sdd-spec uses loaded master spec to correctly classify a requirement as MODIFIED

- **GIVEN** `openspec/specs/sdd-orchestration/spec.md` defines a requirement named
  "Automatic slug inference from user description"
- **AND** the change modifies that behavior
- **WHEN** `sdd-spec` executes with that spec loaded via Step 0c
- **THEN** the delta spec MUST classify the requirement under `## MODIFIED — Modified requirements`
- **AND** it MUST NOT create a duplicate requirement under `## ADDED`

#### Scenario: sdd-spec avoids re-specifying unchanged behavior

- **GIVEN** `sdd-spec` loads the master spec for a domain with 10 existing requirements
- **AND** the current change only modifies 2 of them
- **WHEN** `sdd-spec` writes the delta spec
- **THEN** only the 2 modified requirements MUST appear (in `## MODIFIED`)
- **AND** the other 8 unchanged requirements MUST NOT be re-listed

---

### Requirement: sdd-design loads master specs from SPEC CONTEXT before producing design

`sdd-design` MUST read all spec files listed in SPEC CONTEXT before writing `design.md`.
The step MUST be integrated as a named step within Step 0 (project context loading) as Step 0c.
When SPEC CONTEXT is absent, `sdd-design` applies the same fallback heuristic (self-select up
to 3 relevant domains). Non-blocking.

#### Scenario: sdd-design references spec requirements when justifying technical decisions

- **GIVEN** a master spec defines a requirement "Domain inference MUST be deterministic"
- **WHEN** `sdd-design` writes `design.md`
- **THEN** the design MUST cite or reference this requirement when documenting the slug
  inference algorithm
- **AND** the design MUST NOT propose an implementation that would violate the loaded spec
  requirements

#### Scenario: sdd-design does not invent spec requirements

- **GIVEN** the loaded master specs do not mention a requirement for "caching"
- **WHEN** `sdd-design` produces its design
- **THEN** `design.md` MUST NOT add caching as a requirement — it MAY suggest it as a future
  optimization note only, clearly marked as out-of-scope for this change

---

### Requirement: sdd-tasks loads master specs from SPEC CONTEXT before task breakdown

`sdd-tasks` MUST read all spec files listed in SPEC CONTEXT before producing `tasks.md`.
The step is integrated as Step 0c within Step 0. Fallback heuristic applies when absent.
Non-blocking.

#### Scenario: sdd-tasks links tasks to spec requirements

- **GIVEN** a loaded spec defines 3 requirements for a domain
- **WHEN** `sdd-tasks` produces `tasks.md`
- **THEN** each task in `tasks.md` MUST be traceable to at least one requirement in the loaded spec
- **AND** `tasks.md` MUST NOT include tasks that implement behavior not described in the spec

#### Scenario: sdd-tasks uses loaded spec to detect scope creep

- **GIVEN** a loaded spec does NOT include a requirement for logging behavior
- **AND** the proposal also does not mention logging
- **WHEN** `sdd-tasks` drafts tasks
- **THEN** it MUST NOT add a task for "add structured logging"
- **AND** if logging is genuinely needed, it MUST flag it as an ADVISORY warning in `tasks.md`

---

### Requirement: Step 0c is non-blocking in all five affected phase skills

In all five skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`),
Step 0c MUST be non-blocking. The following conditions MUST NOT cause `status: blocked` or
`status: failed`:

- SPEC CONTEXT block absent from prompt
- `openspec/specs/` directory absent from the project
- One or more spec files listed in SPEC CONTEXT not found on disk
- `openspec/specs/` directory present but empty

#### Scenario: All spec files missing does not block phase execution

- **GIVEN** a sub-agent receives a SPEC CONTEXT block listing 3 spec files
- **AND** none of those files exist in the project
- **WHEN** Step 0c runs
- **THEN** it logs INFO-level notes for each missing file
- **AND** the phase continues normally using ai-context/ as its sole context source
- **AND** `status` MUST be `ok` or `warning`, NEVER `blocked` or `failed` for this reason alone

