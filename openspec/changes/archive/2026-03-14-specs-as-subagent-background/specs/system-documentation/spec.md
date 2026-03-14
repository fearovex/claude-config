# Delta Spec: system-documentation

Change: 2026-03-14-specs-as-subagent-background
Date: 2026-03-14
Base: openspec/specs/system-documentation/spec.md

## ADDED — New requirements

### Requirement: docs/SPEC-CONTEXT.md documents the spec-loading convention

A reference document MUST exist at `docs/SPEC-CONTEXT.md` that describes the spec context
loading convention for skill authors. The document MUST include:

1. **Purpose** — why spec files are loaded as background context (authoritative behavioral
   contracts vs. ai-context/ summaries)
2. **Orchestrator injection** — how the SPEC CONTEXT block is constructed in CLAUDE.md's
   sub-agent launch template
3. **Domain inference algorithm** — the 6-step slug-to-domain matching algorithm (split slug,
   list specs/, match tokens, rank, cap at 5, empty → omit block)
4. **Phase skill Step 0c template** — copy-paste ready block that skill authors insert into
   a SKILL.md `## Process` section
5. **Fallback behavior** — what sub-agents do when SPEC CONTEXT is absent
6. **Non-blocking contract** — all spec-loading steps are INFO-only on failure; `status:
   blocked` and `status: failed` are never triggered by Step 0c alone
7. **Precedence table** — spec files (authoritative) > ai-context/ (supplementary)

#### Scenario: New skill author adds Step 0c to a phase skill

- **GIVEN** a skill author is creating a new SDD phase skill that should load spec context
- **WHEN** they read `docs/SPEC-CONTEXT.md`
- **THEN** it MUST provide a copy-paste ready `### Step 0c — Load spec context` block
- **AND** the block MUST include the SPEC CONTEXT absent fallback instruction
- **AND** the block MUST include the non-blocking error handling instruction

#### Scenario: docs/SPEC-CONTEXT.md is discoverable from sdd-context-injection.md

- **GIVEN** a skill author reads `docs/sdd-context-injection.md`
- **WHEN** they look for information about spec-loading context
- **THEN** `docs/sdd-context-injection.md` MUST contain a reference or link to
  `docs/SPEC-CONTEXT.md`
- **AND** the reference MUST describe it as the companion document for spec-file loading
  (as opposed to ai-context/ loading)

