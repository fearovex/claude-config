# Delta Spec: sdd-orchestration

Change: 2026-03-14-specs-as-subagent-background
Date: 2026-03-14
Base: openspec/specs/sdd-orchestration/spec.md

## MODIFIED — Orchestrator sub-agent launch contract

### Requirement: Orchestrators do not inject SPEC CONTEXT blocks

The sub-agent prompt templates in CLAUDE.md (used by sdd-ff and sdd-new) MUST NOT include
a SPEC CONTEXT block for spec file delivery. Spec context delivery is handled exclusively
by each phase skill's own Step 0 sub-step (self-selection).

Observable contract:
1. sdd-ff and sdd-new CONTEXT blocks contain: project path, change name, prior artifact paths
2. sdd-ff and sdd-new CONTEXT blocks do NOT contain: SPEC CONTEXT blocks, domain name lists,
   spec file path lists, or precedence declarations for spec files
3. Phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks) receive spec
   context through their own Step 0 sub-step — not through the orchestrator prompt

#### Scenario: Sub-agent prompt template contains no SPEC CONTEXT block

- **GIVEN** the orchestrator builds a sub-agent Task prompt via sdd-ff or sdd-new
- **WHEN** the prompt is inspected
- **THEN** it MUST contain a CONTEXT block with project path, change name, prior artifact paths
- **AND** it MUST NOT contain a SPEC CONTEXT block, domain name list, or spec file path list
- **AND** it MUST NOT contain any precedence declaration injected by the orchestrator

#### Scenario: Phase skill self-selects spec context independently

- **GIVEN** a sub-agent receives a Task prompt from sdd-ff or sdd-new
- **WHEN** the sub-agent executes its Step 0
- **THEN** it MUST independently list openspec/specs/, apply stem matching, and load matching
  spec files as enrichment context (per docs/SPEC-CONTEXT.md contract)
- **AND** the orchestrator MUST NOT have pre-loaded or pre-selected these files
