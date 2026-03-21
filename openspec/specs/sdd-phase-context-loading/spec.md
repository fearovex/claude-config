# Spec: sdd-phase-context-loading

Change: feature-domain-knowledge-layer
Date: 2026-03-03

---

## Requirements

### Requirement: sdd-propose optional domain context preload

`sdd-propose` MUST gain an optional domain context preload step. The step reads `ai-context/features/<domain>.md` when a filename match is found and uses the content to enrich the proposal's context. The step MUST be non-blocking: when no match is found, `sdd-propose` proceeds normally without error.

The domain slug matching heuristic MUST work as follows:
1. List all `.md` files in `ai-context/features/` (excluding `_template.md` and files with leading underscores).
2. Compare each filename stem against the change name — a match occurs when the change name **contains** or **starts with** the domain slug, or when the domain slug **contains** the change name stem (case-insensitive, hyphen-normalized).
3. If a match is found, read the file and treat its content as enrichment context before writing the proposal.
4. If multiple files match, load all matching files.
5. If the `ai-context/features/` directory does not exist, skip this step silently.

The preload step MUST be placed **after** reading `exploration.md`, `openspec/config.yaml`, and `ai-context/architecture.md` (existing Step 1) and **before** Step 2 (understand the request in depth).

#### Scenario: Preload succeeds with a matching feature file

- **GIVEN** `ai-context/features/payments.md` exists and contains domain knowledge for the payments bounded context
- **AND** the change name is `add-payment-gateway`
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** `payments.md` is identified as a match (change name contains `payment`)
- **AND** the file is read and its content is available as enrichment context during proposal authoring
- **AND** the resulting `proposal.md` reflects awareness of the domain's business rules and invariants

#### Scenario: Preload is skipped when no file matches

- **GIVEN** `ai-context/features/` contains only `auth.md` and `_template.md`
- **AND** the change name is `add-payment-gateway`
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** no file is loaded (no slug matches `add-payment-gateway` against `auth`)
- **AND** `sdd-propose` proceeds to Step 2 without error or warning
- **AND** `proposal.md` is produced normally

#### Scenario: Preload is skipped when features directory is absent

- **GIVEN** the project does not have an `ai-context/features/` directory
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** the step is silently skipped
- **AND** `sdd-propose` proceeds to Step 2 without error or warning

#### Scenario: Preload does not block proposal creation on file read error

- **GIVEN** `ai-context/features/payments.md` exists but cannot be read (e.g., permissions issue)
- **WHEN** `sdd-propose` attempts the domain context preload step
- **THEN** the preload step logs an INFO-level warning in the orchestrator output
- **AND** `sdd-propose` continues and produces `proposal.md` without error
- **AND** `status` in the orchestrator output MUST be `ok` or `warning`, NEVER `blocked` or `failed` due to this step alone

#### Scenario: Template file is never loaded

- **GIVEN** `ai-context/features/` contains `_template.md` and no other files
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** `_template.md` is NOT loaded regardless of the change name
- **AND** the step is silently skipped

---

### Requirement: sdd-spec optional domain context preload

`sdd-spec` MUST gain the same optional domain context preload capability as `sdd-propose`. The heuristic, behavior on miss, and non-blocking contract are identical to the `sdd-propose` requirement above.

The preload step in `sdd-spec` MUST be placed within Step 1 (Read prior artifacts), executed **after** reading `proposal.md` and any existing `openspec/specs/<domain>/spec.md` but **before** identifying affected domains (Step 2).

The feature file content MUST be used to:
- Identify business rules that should be reflected as requirements in the spec
- Surface known invariants that must appear as THEN clauses in scenarios
- Avoid writing scenarios that contradict documented business rules

The feature file content MUST NOT:
- Replace the need to read the existing `openspec/specs/<domain>/spec.md` when it exists
- Cause `sdd-spec` to write implementation details into the spec
- Produce scenarios that are not grounded in observable behavior

#### Scenario: sdd-spec enriches spec with domain knowledge from feature file

- **GIVEN** `ai-context/features/auth.md` exists and documents an invariant: "A user account MUST be verified before it can perform privileged operations"
- **AND** the change name is `auth-privilege-escalation-fix`
- **WHEN** `sdd-spec` executes the domain context preload step
- **THEN** `auth.md` is identified as a match and read
- **AND** the generated spec MUST include a requirement or scenario that reflects the verification invariant as an observable precondition (GIVEN clause or requirement constraint)

#### Scenario: sdd-spec preload does not replace reading the existing domain spec

- **GIVEN** `ai-context/features/auth.md` exists
- **AND** `openspec/specs/auth/spec.md` also exists
- **WHEN** `sdd-spec` runs Step 1
- **THEN** BOTH `openspec/specs/auth/spec.md` AND `ai-context/features/auth.md` are read
- **AND** the feature file is treated as contextual enrichment, not as a replacement for the existing behavioral spec

#### Scenario: sdd-spec proceeds normally with no feature file match

- **GIVEN** `ai-context/features/` contains only `payments.md`
- **AND** the change name is `notification-retry-policy`
- **WHEN** `sdd-spec` executes the domain context preload step
- **THEN** no file matches (`notification` does not match `payments`)
- **AND** `sdd-spec` proceeds to Step 2 without error or warning
- **AND** the produced spec is complete and valid

#### Scenario: Preload outcome is communicated to the orchestrator

- **GIVEN** `sdd-spec` loads one or more feature files during preload
- **WHEN** `sdd-spec` returns its orchestrator output
- **THEN** the `summary` field MUST note that domain context was preloaded (e.g., "domain context loaded from ai-context/features/auth.md")
- **AND** the loaded file paths MUST appear in the `artifacts` list (read, not written)

---

### Requirement: sdd-spec optional domain context preload — placement clarification _(Modified in: 2026-03-10 by change "sdd-project-context-awareness")_

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

---

### Requirement: Mandatory project context loading step in all SDD phase skills _(Added in: 2026-03-10 by change "sdd-project-context-awareness")_

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

### Requirement: sdd-design must cross-reference project Skills Registry _(Added in: 2026-03-10 by change "sdd-project-context-awareness")_

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

### Requirement: Context loading is non-intrusive to the existing domain context preload (Step 0 dual-block) _(Added in: 2026-03-10 by change "sdd-project-context-awareness")_

The existing optional domain context preload in `sdd-propose` and `sdd-spec` MUST remain in place after this change. The new mandatory Step 0 for project context loading MUST be sequenced **before** the existing domain context preload block, or merged into a single Step 0 with two sub-steps:

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

### Requirement: sdd-explore loads master specs from SPEC CONTEXT before analysis

_(Added in: 2026-03-14 by change "specs-as-subagent-background")_

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

_(Added in: 2026-03-14 by change "specs-as-subagent-background")_

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

_(Added in: 2026-03-14 by change "specs-as-subagent-background")_

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

_(Added in: 2026-03-14 by change "specs-as-subagent-background")_

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

_(Added in: 2026-03-14 by change "specs-as-subagent-background")_

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

_(Added in: 2026-03-14 by change "specs-as-subagent-background")_

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

---

## ADDED — sdd-spec Supersedes Validation
*(Added in: 2026-03-19 by change "feedback-sdd-cycle-context-gaps")*

### Requirement: sdd-spec validates spec content against proposal Supersedes section

When writing delta specs, `sdd-spec` MUST perform a new validation step: cross-check the spec requirements against the proposal's `## Supersedes` section to ensure no unconfirmed preservation requirements are added.

The validation MUST:
1. Read the proposal.md `## Supersedes` section
2. For each REMOVED or REPLACED item, check if the delta spec contains any requirement that preserves or re-introduces that item
3. For each CONTRADICTED item, check if the delta spec contradicts the stated resolution in the proposal
4. Emit a MUST_RESOLVE warning if validation finds an inconsistency

#### Scenario: Spec tries to preserve a removed feature

- **GIVEN** the proposal states: "REMOVED: Periodic membership refresh hook — no longer needed"
- **AND** the delta spec includes: "Requirement: The system MUST periodically refresh membership status every 4 hours"
- **WHEN** `sdd-spec` executes the validation step
- **THEN** it MUST emit a MUST_RESOLVE warning:
  ```
  [WARNING: MUST_RESOLVE]
  Spec contradiction detected: spec includes a requirement to preserve the periodic membership refresh hook,
  but proposal Supersedes section marks this as REMOVED. Either: (1) correct the proposal to mark as REPLACED,
  or (2) remove the preservation requirement from the spec. User MUST resolve this before proceeding.
  ```
- **AND** `sdd-spec` MUST halt with status: `warning` (not blocked, but warning requires user confirmation before spec is accepted)

#### Scenario: Spec correctly reflects the removal

- **GIVEN** the proposal states: "REMOVED: Periodic refresh hook"
- **AND** the delta spec includes only ADDED requirements for new event-driven refresh behavior
- **WHEN** `sdd-spec` validates
- **THEN** no warning is emitted
- **AND** the spec proceeds normally with status: `ok`

#### Scenario: Spec addresses the contradiction stated in proposal

- **GIVEN** the proposal states: "CONTRADICTED: Backwards compatibility guarantee; Resolution: v1 API endpoint is sunsetting with 6-month deprecation"
- **AND** the delta spec includes: "Requirement: The system MUST emit deprecation warnings for v1 API calls during the 6-month sunset period"
- **WHEN** `sdd-spec` validates
- **THEN** no contradiction is detected — the spec aligns with the stated resolution
- **AND** the spec proceeds normally

---

### Requirement: Specs MUST NOT add preservation requirements without explicit proposal language

`sdd-spec` MUST NOT unilaterally decide to preserve behavior that the proposal doesn't explicitly require. If the proposal is silent on something, the spec MUST NOT invent a "preserve" requirement without user confirmation.

#### Scenario: Proposal is silent; spec invents preservation

- **GIVEN** the proposal requests "improve the payment flow for mobile"
- **AND** the proposal does not mention the desktop payment flow
- **AND** the spec author considers: "We should preserve the existing desktop flow"
- **WHEN** the spec is written
- **THEN** the spec MUST NOT add a requirement: "The desktop payment flow MUST remain unchanged"
- **AND** instead, spec SHOULD note: `[Pending clarification: Desktop payment flow scope not mentioned in proposal]`
- **AND** this note MUST be listed in risks for user confirmation

#### Scenario: Proposal explicitly requires preservation

- **GIVEN** the proposal states: "Scope: Desktop flow MUST remain unchanged; mobile only"
- **WHEN** `sdd-spec` writes the spec
- **THEN** the spec MAY include the preservation requirement: "The desktop payment flow MUST NOT be modified"

---

## Rules (sdd-spec supersedes validation — added 2026-03-19)

- Validation step is mandatory in every `sdd-spec` execution
- If validation finds a contradiction between spec and Supersedes section, emit MUST_RESOLVE warning and require user confirmation
- Specs MUST NOT preserve behavior not explicitly stated in the proposal
- The Supersedes section (with its REMOVED, REPLACED, CONTRADICTED items) is the source of truth for scope boundaries
- If the Supersedes section is absent or malformed in proposal.md, log a WARNING-level note and skip validation gracefully

