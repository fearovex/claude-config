# Technical Design: specs-as-subagent-background

Date: 2026-03-14
Proposal: openspec/changes/2026-03-14-specs-as-subagent-background/proposal.md

## General Approach

Extend the existing Step 0 context-loading block in each of the five affected SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`) to include a self-selecting spec file preload. Each skill lists `openspec/specs/`, applies the same filename-stem matching heuristic already used in `sdd-propose`/`sdd-spec` Step 0b for `ai-context/features/`, loads at most 3–5 matching spec files as enrichment context, and falls back silently when no domains match. A new `docs/SPEC-CONTEXT.md` convention document defines the loading contract and guidance for skill authors.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Spec selection approach | Approach B — Phase-skill self-selection (each skill lists and filters `openspec/specs/` independently) | Approach A: Orchestrator-injected SPEC CONTEXT block; Approach C: Hybrid | Consistent with the existing `ai-context/features/` preload pattern already in `sdd-propose` and `sdd-spec`. Orchestrators remain sequencers — they don't grow into domain selectors. Trivial filesystem cost vs. reduced blast radius and alignment with existing conventions. |
| Matching heuristic | Same stem-based algorithm as Step 0b: split change slug on hyphens, discard single-char stems, match when domain slug appears in change name OR any stem appears in domain slug | Fuzzy-matching, keyword index lookup, AI-assisted selection | Reuses a tested algorithm already in production in two skills. Deterministic and readable. No new dependencies. |
| Load cap | 3 matching spec files maximum (hard cap) | 5 files, no cap | Bounds token cost reliably. 3 is sufficient for most domain-scoped changes; broader changes trigger fallback to ai-context/ which is designed for that use case. Companion proposal (specs-search-optimization) can revisit if a better index exists. |
| Placement in Step 0 structure | New sub-step 0c for `sdd-propose` and `sdd-spec` (which already have 0a + 0b); new sub-step for standard Step 0 skills (sdd-explore, sdd-design, sdd-tasks) | Separate Step -1 before Step 0; inline within Step 0 body | Preserves the existing ordered sub-step structure in dual-block skills. Additive: does not rewrite existing Step 0 logic. `sdd-context-injection.md` reference doc is updated alongside. |
| Convention document | New `docs/SPEC-CONTEXT.md` (separate from `docs/sdd-context-injection.md`) | Append to `docs/sdd-context-injection.md` | `sdd-context-injection.md` already documents Step 0 as a stable published reference. Creating a focused `SPEC-CONTEXT.md` introduces cross-cutting convention for spec loading without touching the existing Step 0 reference document. Both documents remain independently coherent. |
| Master spec update | Extend `openspec/specs/sdd-context-loading/spec.md` with spec-loading requirement and scenarios | Create new domain spec | The spec loading behavior is a direct extension of the Step 0 contract. It belongs in the same spec domain rather than fragmenting context-loading requirements across multiple files. |
| `sdd-apply` exclusion | No change — `sdd-apply` is excluded from spec loading | Include `sdd-apply` | `sdd-apply` executes against `openspec/changes/<change>/specs/` (the change's delta spec files), not against master specs. Adding master spec loading to apply would introduce a second, potentially conflicting spec source at execution time. |

## Data Flow

```
/sdd-ff <description>
         │
         ▼
  sdd-ff (orchestrator)
  ├── Step 0: infer slug
  └── Launch sub-agents sequentially/parallel
         │
         ▼
  Sub-agent receives CONTEXT block (unchanged — no SPEC CONTEXT injected)
         │
         ▼
  Phase skill Step 0 — Load project context (existing)
  ├── ai-context/stack.md
  ├── ai-context/architecture.md
  ├── ai-context/conventions.md
  └── CLAUDE.md (governance)
         │
         ▼
  Phase skill Step 0 [sub-step] — Spec context preload (NEW)
  ├── List openspec/specs/ → get domain directory names
  ├── Apply stem matching: change slug stems vs. domain names
  ├── If matches found (≤ 3): read spec files → enrichment context
  │   └── Mark spec files as read in sub-agent context
  └── If no matches: skip silently, proceed with ai-context/ only
         │
         ▼
  [For sdd-propose, sdd-spec: Step 0b — features preload (unchanged)]
         │
         ▼
  Phase work (Steps 1–N) executes with enriched context
  Spec files are treated as authoritative behavioral contracts.
  ai-context/ files are treated as supplementary architecture context.
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-explore/SKILL.md` | Modify | Add spec context preload sub-step to Step 0 |
| `skills/sdd-propose/SKILL.md` | Modify | Add Step 0c — spec context preload (after existing 0b) |
| `skills/sdd-spec/SKILL.md` | Modify | Add Step 0c — spec context preload (after existing 0b) |
| `skills/sdd-design/SKILL.md` | Modify | Add spec context preload sub-step to Step 0 |
| `skills/sdd-tasks/SKILL.md` | Modify | Add spec context preload sub-step to Step 0 |
| `docs/SPEC-CONTEXT.md` | Create | Convention doc: selection heuristic, load cap, fallback behavior, relationship to companion proposal |
| `openspec/specs/sdd-context-loading/spec.md` | Modify | Add new Requirement: spec context preload + scenarios |
| `docs/sdd-context-injection.md` | Modify | Add cross-reference to `docs/SPEC-CONTEXT.md` for spec loading |

## Interfaces and Contracts

### Spec context preload sub-step contract (all five phase skills)

```
Step 0[c / new sub-step] — Spec context preload

Non-blocking: any failure (missing directory, unreadable file, no match)
MUST produce at most an INFO-level note.
MUST NOT produce status: blocked or status: failed.

Algorithm:
  stems = change_name.split("-").filter(s => s.length > 1)
  candidates = list(openspec/specs/) → subdirectory names
  matches = []
  for domain in candidates:
    if domain in change_name OR any stem in domain:
      matches.append(domain)
  matches = matches[:3]   ← hard cap at 3

  if matches is empty:
    skip silently — proceed to next step
  else:
    for domain in matches:
      read openspec/specs/<domain>/spec.md
      inject content as enrichment (marked as authoritative behavioral contract)
    log: "Spec context loaded from: [domain1/spec.md, domain2/spec.md, ...]"
    include in artifacts list (read, not written)

Priority: spec files take precedence over ai-context/ for behavioral contracts.
ai-context/ remains supplementary for architecture and naming context.
```

### SPEC-CONTEXT.md outline

```markdown
# Spec Context Loading — Convention Reference

## Purpose
## Selection Algorithm (stem-based matching)
## Load Cap (3 files maximum)
## Non-Blocking Contract
## Precedence Rule (spec files > ai-context/ for behavioral contracts)
## Fallback Behavior (no match → ai-context/ only)
## Skills This Applies To
## Relationship to Companion Proposal (specs-search-optimization)
## When to Override (cross-cutting changes with no domain match)
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual validation | Run `/sdd-ff specs-as-subagent-background` after apply; verify `sdd-explore` Step 0 output includes spec context log line (or a graceful skip) | `/project-audit` + manual run |
| Manual validation | Run `/sdd-explore sdd-context-loading` and confirm `openspec/specs/sdd-context-loading/spec.md` is loaded | Manual session |
| Structural | Run `/project-audit` after apply; verify no regressions in skill structure compliance (D4, D9) | `/project-audit` |
| Manual validation | Verify a change slug with no spec domain match (e.g., `add-payment-flow` on this repo) silently skips spec loading with no error | Manual session |

No automated test runner exists in this project (tech stack: Markdown + YAML + Bash). Validation is manual + `/project-audit`.

## Migration Plan

No data migration required. All changes are additive SKILL.md edits and new/updated documentation files. Rollback:
1. `git checkout -- skills/ docs/openspec/specs/` to restore any changed file.
2. `bash install.sh` to re-deploy the restored runtime config.

## Open Questions

- **sdd-apply spec loading exclusion confirmation**: The exploration flagged this as an open question (Q2). The design confirms the exclusion is correct — `sdd-apply` already operates against `openspec/changes/<change>/specs/` delta files injected via `sdd-spec`. Adding master spec loading at apply time would introduce a second authoritative spec source with undefined conflict resolution. Exclusion stands.
- **Load cap (3 vs 5)**: Proposal said 3–5; exploration recommended a hard cap. This design sets the hard cap at 3 to bound token cost. If use cases reveal 3 is insufficient, the SPEC-CONTEXT.md document can be updated without changing the skills (the skill steps reference the convention doc).
