# ADR-033: Spec Context Loading as Phase-Skill-Owned Cross-Cutting Convention

## Status

Proposed

## Context

SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`) load `ai-context/` files as their primary background context via Step 0. `openspec/specs/` contains 55 master spec files — the authoritative, versioned behavioral contracts produced by all previous SDD cycles. These files are more precise than the narrative summaries in `ai-context/`, but are not part of the Step 0 loading contract.

Three approaches were evaluated for injecting relevant spec files into sub-agent context: orchestrator injection (sdd-ff/sdd-new build a SPEC CONTEXT block), phase-skill self-selection (each skill independently lists and filters `openspec/specs/`), and a hybrid of both. The phase-skill self-selection approach reuses the stem-based matching algorithm already established in `sdd-propose` Step 0b and `sdd-spec` Step 0b for `ai-context/features/` preloading.

## Decision

We will implement spec context loading as a **phase-skill-owned, self-selecting convention** rather than an orchestrator-injected block. Each affected phase skill adds a spec preload sub-step to its Step 0 block: it lists `openspec/specs/`, applies the existing stem-based slug matching heuristic, loads at most 3 matching spec files as enrichment context, and falls back silently when no domains match. Orchestrators (`sdd-ff`, `sdd-new`) are not modified. The convention is documented in `docs/SPEC-CONTEXT.md`.

## Consequences

**Positive:**

- Reuses a tested, in-production algorithm (same logic as `ai-context/features/` preloading in sdd-propose Step 0b)
- Orchestrators remain sequencers only — they do not become domain selectors
- Phase skills work correctly when invoked standalone (e.g., `/sdd-spec` without `/sdd-ff`)
- Non-blocking contract: no match → graceful fallback to ai-context/ only
- Spec files are explicitly promoted as authoritative behavioral contracts; ai-context/ is demoted to supplementary architecture context

**Negative:**

- Each sub-agent independently performs a `list openspec/specs/` filesystem call — 5 scans per `/sdd-ff` cycle instead of 1 (negligible in practice)
- No orchestrator-level visibility of which spec domains were selected per sub-agent
- Vocabulary mismatch between change slug and spec domain names causes silent miss; companion proposal `specs-search-optimization` would address this
