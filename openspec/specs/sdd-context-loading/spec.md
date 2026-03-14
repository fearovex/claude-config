# Spec: sdd-context-loading

Change: sdd-project-context-awareness
Date: 2026-03-10

## Requirements

### Requirement: Step 0 — Load project context is present in all SDD phase skills

Every SDD phase skill (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) MUST
include a named **Step 0 — Load project context** block as the first step of its `## Process` section.

The block MUST read the following files from the project root:

1. `ai-context/stack.md`
2. `ai-context/architecture.md`
3. `ai-context/conventions.md`
4. Project `CLAUDE.md` — Skills Registry section only

#### Scenario: Happy path — all four context files present

- **GIVEN** a project has `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, and `CLAUDE.md`
- **WHEN** any SDD phase skill executes its Step 0 — Load project context
- **THEN** all four files are read and their contents are available as enrichment context for subsequent steps
- **AND** no error or warning is emitted

#### Scenario: Partial context — some files missing

- **GIVEN** a project is missing one or more of the four context files (e.g., `ai-context/conventions.md` is absent)
- **WHEN** Step 0 runs
- **THEN** for each missing file an INFO-level note is logged: `INFO: [filename] not found — proceeding without it.`
- **AND** execution continues immediately to the next file (non-blocking)
- **AND** the step MUST NOT set `status: blocked` or `status: failed`

#### Scenario: All context files absent

- **GIVEN** a project has no `ai-context/` directory and no `CLAUDE.md`
- **WHEN** Step 0 runs
- **THEN** a single INFO note is logged: `ai-context/ not found — proceeding with global defaults.`
- **AND** the step completes without error and execution proceeds to Step 1

#### Scenario: Stale context file detected

- **GIVEN** a project context file (e.g., `ai-context/architecture.md`) contains a `Last updated: YYYY-MM-DD` date older than 7 days from today
- **WHEN** Step 0 reads the file
- **THEN** a NOTE-level message is emitted: `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`
- **AND** the file content is still used as enrichment (execution continues normally)

---

### Requirement: Dual-block structure for sdd-propose and sdd-spec

The skills `sdd-propose` and `sdd-spec` MUST use a dual-block structure to preserve their existing domain feature preload step:

- `Step 0a — Load project context` (global files)
- `Step 0b — Domain context preload` (ai-context/features/ matching)

The two sub-steps MUST NOT conflict. Sub-step B enrichment is additive to Sub-step A.

#### Scenario: Dual-block executes in order

- **GIVEN** `sdd-propose` or `sdd-spec` is invoked on a project with both `ai-context/*.md` and `ai-context/features/auth.md`
- **WHEN** the change slug matches the `auth` feature file
- **THEN** Step 0a loads the global context files first
- **AND** Step 0b then loads `ai-context/features/auth.md`
- **AND** both sets of context are available as enrichment for subsequent steps

#### Scenario: Step 0a failure does not affect Step 0b

- **GIVEN** all `ai-context/*.md` global files are absent
- **WHEN** Step 0a logs INFO notes and completes
- **THEN** Step 0b still runs and loads any matching feature files
- **AND** the phase continues without error

---

### Requirement: Context enriches output but does not override explicit content

Loaded context (from Step 0) MUST be treated as enrichment only. It informs architectural coherence,
naming consistency, and skill alignment checks — it MUST NOT override explicit content in `proposal.md`,
`design.md`, or other SDD artifacts.

#### Scenario: Context suggests different naming convention

- **GIVEN** `ai-context/conventions.md` specifies kebab-case naming
- **AND** a `proposal.md` explicitly uses camelCase for a specific field
- **WHEN** a phase skill generates its output
- **THEN** the explicit content in `proposal.md` is preserved as-is
- **AND** the naming convention from context is applied only to new content not explicitly defined in the proposal

---

### Requirement: Reference documentation exists for skill authors

A reference document MUST exist at `docs/sdd-context-injection.md` describing:

- The Step 0 block template (copy-paste ready)
- The dual-block variant for sdd-propose and sdd-spec
- Graceful degradation rules
- Staleness warning threshold (7 days)
- How loaded context is used by subsequent steps

#### Scenario: New skill author adds Step 0

- **GIVEN** a skill author is creating a new SDD phase skill
- **WHEN** they look up context loading conventions
- **THEN** `docs/sdd-context-injection.md` provides a complete, copy-paste ready template block
- **AND** the document explains when to use the standard vs. dual-block variant

---

### Requirement: sdd-design cross-references Skills Registry

When `sdd-design` recommends a technology skill or library pattern, it MUST cross-reference the project's
Skills Registry (loaded in Step 0 from project CLAUDE.md) and annotate recommendations accordingly:

- Registered skill → reference by exact registered name
- Global catalog skill not registered in project → mark `[optional — not registered in project; add via /skill-add <name>]`
- Skill not in global catalog → flag as new dependency for review

#### Scenario: Design recommends a skill registered in the project

- **GIVEN** the project's CLAUDE.md Skills Registry contains `typescript`
- **WHEN** `sdd-design` recommends using TypeScript patterns
- **THEN** the design references it as `typescript` (exact registered name)
- **AND** no additional annotation is added

#### Scenario: Design recommends an unregistered global skill

- **GIVEN** the project's CLAUDE.md Skills Registry does NOT contain `playwright`
- **AND** the global catalog includes `playwright`
- **WHEN** `sdd-design` recommends end-to-end testing with Playwright
- **THEN** the design marks it as `[optional — not registered in project; add via /skill-add playwright]`

---

---

### Requirement: Spec context preload sub-step is present in all five applicable SDD phase skills

The skills `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, and `sdd-tasks` MUST include a spec context preload sub-step within Step 0. The sub-step MUST:

1. List subdirectory names in `openspec/specs/`.
2. Apply the stem-based matching algorithm: split the change slug on hyphens, discard single-character stems, match when the domain slug appears in the change name OR any stem appears in the domain slug.
3. Load at most 3 matching spec files (hard cap).
4. Treat loaded spec files as authoritative behavioral contracts (taking precedence over `ai-context/` for behavioral questions).
5. Emit the log line `Spec context loaded from: [domain1/spec.md, ...]` when one or more files are loaded.
6. Skip silently when no domains match — no error or warning.

The sub-step is **non-blocking**: any failure (missing directory, unreadable file, no match) MUST produce at most an INFO-level note and MUST NOT produce `status: blocked` or `status: failed`.

**Placement:**
- `sdd-explore`, `sdd-design`, `sdd-tasks`: new sub-step appended to existing Step 0 block
- `sdd-propose`, `sdd-spec`: Step 0c (after existing Step 0b — domain features preload)

**Excluded:** `sdd-apply` — operates against `openspec/changes/<change>/specs/` delta files; adding master spec loading would introduce a conflicting spec source.

#### Scenario: Match found — spec files loaded

- **GIVEN** a SDD phase skill is invoked for change `fix-auth-token-refresh`
- **AND** `openspec/specs/` contains a domain directory named `auth`
- **WHEN** the spec context preload sub-step runs
- **THEN** `openspec/specs/auth/spec.md` is read and its content is available as enrichment context
- **AND** the log line `Spec context loaded from: [auth/spec.md]` is emitted
- **AND** the spec file content is treated as an authoritative behavioral contract (precedence over `ai-context/` for behavioral questions)

#### Scenario: No match — silent skip

- **GIVEN** a SDD phase skill is invoked for change `add-resilience-layer`
- **AND** no domain in `openspec/specs/` shares lexical stems with the change slug
- **WHEN** the spec context preload sub-step runs
- **THEN** no spec files are loaded
- **AND** no error or warning is emitted
- **AND** the phase continues with `ai-context/` as the sole supplementary context source

#### Scenario: openspec/specs/ directory absent

- **GIVEN** the project has no `openspec/specs/` directory
- **WHEN** the spec context preload sub-step runs
- **THEN** an INFO-level note is logged: `INFO: openspec/specs/ not found — skipping spec context preload`
- **AND** the sub-step completes without error and execution proceeds to the next step
- **AND** `status: blocked` and `status: failed` are NOT set

---

## Scenarios Not Covered (out of scope)

- Context Capsule (YAML/JSON structured object) generation and passing between orchestrator and sub-agents — deferred; see proposal Excluded section
- Automated context caching or memoization
- Changes to Task tool prompt format in sdd-ff or sdd-new beyond what already exists
