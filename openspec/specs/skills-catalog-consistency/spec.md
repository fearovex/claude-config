# Spec: skills-catalog-consistency

Change: skills-catalog-analysis
Date: 2026-03-14
Base: openspec/specs (none — this is a new domain with no prior spec)

## ADDED — New requirements

### Requirement: sdd-verify skill includes Step 0 governance loading block

Description: The `skills/sdd-verify/SKILL.md` skill MUST include a Step 0 block that loads project context (stack.md, architecture.md, conventions.md, and CLAUDE.md) before executing any verification logic. This ensures consistency with all other SDD phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply) which all have this block.

**RFC 2119 Keywords**: The following scenarios use "MUST" and "MUST NOT" to define requirements.

#### Scenario: sdd-verify Step 0 loads governance from project CLAUDE.md

- **GIVEN** that `skills/sdd-verify/SKILL.md` is read
- **WHEN** the file is processed by Claude at skill invocation
- **THEN** the skill MUST contain a Step 0 section (before any other processing steps)
- **AND** Step 0 MUST read the project CLAUDE.md file (from the provided absolute path)
- **AND** Step 0 MUST extract and log: unbreakable rules count, tech stack primary language, intent classification enabled/disabled status
- **AND** Step 0 MUST emit a log line matching the pattern: `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`

#### Scenario: sdd-verify Step 0 is non-blocking

- **GIVEN** that a project's CLAUDE.md file is missing or unreadable
- **WHEN** sdd-verify Step 0 executes
- **THEN** the skill MUST NOT halt execution or raise a `status: blocked` error
- **AND** it MUST emit an INFO-level note: `INFO: project CLAUDE.md not found — governance falls back to global defaults.`
- **AND** verification MUST continue to the next step

#### Scenario: sdd-verify ai-context file staleness is noted

- **GIVEN** that ai-context/stack.md, ai-context/architecture.md, or ai-context/conventions.md files exist
- **WHEN** Step 0 loads them and extracts a "Last updated:" or "Last analyzed:" date
- **AND** that date is older than 7 days from today
- **THEN** Step 0 MUST emit a NOTE-level message suggesting the user run `/memory-update` or `/project-analyze`

#### Scenario: sdd-verify matches other phase skills' governance pattern

- **GIVEN** that the SDD phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply) all have an identical Step 0a block
- **WHEN** sdd-verify Step 0 is added
- **THEN** its structure, log messages, and non-blocking behavior MUST match the existing pattern in those skills
- **AND** the step MUST be placed before all other processing steps

### Requirement: sdd-slug-algorithm documentation created and referenced

Description: A new canonical documentation file `docs/sdd-slug-algorithm.md` MUST be created documenting the STOP_WORDS algorithm used by `sdd-ff` and `sdd-new` to infer change slugs from user descriptions. This file MUST serve as the single source of truth for the slug algorithm logic, and both orchestrator skills MUST reference it.

#### Scenario: sdd-slug-algorithm.md exists with complete algorithm documentation

- **GIVEN** that `docs/sdd-slug-algorithm.md` is created
- **WHEN** the file is read
- **THEN** it MUST document: the algorithm name (STOP_WORDS), the set of stop words used, the maximum word limit, the normalization rules (lowercase, hyphenation, collision handling with numeric suffix), and concrete examples of input descriptions and resulting slugs
- **AND** it MUST explain when the algorithm is triggered (in sdd-ff and sdd-new, Step 0)
- **AND** it MUST include the rationale for the current stop-words set

#### Scenario: sdd-ff references the slug algorithm documentation

- **GIVEN** that `skills/sdd-ff/SKILL.md` is read after this requirement is satisfied
- **WHEN** searching for references to the slug algorithm
- **THEN** there MUST be at least one note in the skill that directs the reader to `docs/sdd-slug-algorithm.md` for the authoritative algorithm definition
- **AND** the reference MUST be in a prominent location (e.g., Step 0 or Process section introduction)

#### Scenario: sdd-new references the slug algorithm documentation

- **GIVEN** that `skills/sdd-new/SKILL.md` is read after this requirement is satisfied
- **WHEN** searching for references to the slug algorithm
- **THEN** there MUST be at least one note in the skill that directs the reader to `docs/sdd-slug-algorithm.md` for the authoritative algorithm definition
- **AND** the reference MUST match the structure and placement as in sdd-ff (for consistency)

#### Scenario: sdd-slug-algorithm.md does not alter slug behavior

- **GIVEN** that the algorithm documentation is created
- **WHEN** sdd-ff or sdd-new infers a slug from a user description
- **THEN** the inferred slug MUST be identical to what was produced before the documentation was created
- **AND** no changes to the algorithm logic or behavior are permitted (documentation only)

## Risks and clarifications

### Step 0 pattern consistency is critical

The Step 0 block added to sdd-verify MUST be identical in structure and semantics to the pattern used in other phase skills. Any deviation (e.g., different log message format, different file read order) would create inconsistency and audit violations. The implementation MUST copy the exact pattern from one of the reference skills (e.g., sdd-propose).

### Algorithm documentation is a non-normative artifact

The `docs/sdd-slug-algorithm.md` file serves as documentation only — it MUST NOT change the behavior of the algorithm. If future changes to the algorithm are needed, a separate SDD cycle MUST be used to update both the algorithm (in sdd-ff and sdd-new) and the documentation in lockstep.
