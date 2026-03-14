# Proposal: specs-as-subagent-background

Date: 2026-03-14
Status: Draft

## Intent

Load relevant master specs from `openspec/specs/` as structured background context in sub-agent prompts, replacing the current pattern where sub-agents rely solely on `ai-context/` as their primary source of truth.

## Motivation

`openspec/specs/` contains 55 master spec files that represent the authoritative, versioned, structured state of every behavior the system has defined. These files are the output of every previous SDD cycle — they are precise, organized by domain, and always current.

Sub-agents (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply) currently load `ai-context/` files as primary background. `ai-context/` is a session-written memory layer — summaries, changelog entries, and architecture notes. It is higher-level and less precise than the spec files it describes.

The result is that sub-agents execute against a generic, occasionally stale narrative rather than against the exact behavioral contracts the system enforces. As the system grows, the divergence between the memory layer and the spec layer widens, and output quality degrades silently.

## Scope

### Included

- Add a "spec context loading" instruction to the sub-agent prompt template in CLAUDE.md (the orchestrator launch pattern)
- Define domain selection logic: sub-agents filter relevant specs by matching the change slug and topic keywords against domain names — not "read all 55"
- Apply spec loading to the following phases: sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks
- sdd-apply already loads specs via the sdd-spec delta — no change needed
- Update the SKILL.md files for the affected phases to include the spec-loading step as a named phase step (not just an implicit prompt instruction)
- Document the loading convention in `docs/SKILL-RESOLUTION.md` or a new `docs/SPEC-CONTEXT.md`

### Excluded (explicitly out of scope)

- Changes to the content of any spec file
- Changes to the `ai-context/` layer or its role (it remains supplementary context — not removed)
- Automated domain selection (keyword matching is manual/heuristic in this proposal; see companion proposal for indexing)
- sdd-archive and sdd-verify phases (neither benefits significantly from domain-specific spec loading)

## Proposed Approach

**Step 1 — Update orchestrator sub-agent launch template (CLAUDE.md)**

Extend the sub-agent prompt template to include a "SPEC CONTEXT" block:

```
SPEC CONTEXT:
- Relevant domains for this change: [inferred from slug/topic]
- Read the following spec files before beginning phase work:
  - openspec/specs/<domain-1>/spec.md
  - openspec/specs/<domain-2>/spec.md
- Treat these spec files as the authoritative behavioral contract.
- ai-context/ files are supplementary — use them for architecture context only.
```

The orchestrator infers relevant domains from the change slug (word matching against known domain names under `openspec/specs/`). If no domains can be inferred, sub-agent loads no spec files and falls back to ai-context/ only.

**Step 2 — Update affected SKILL.md files**

Each of the five affected phase skills receives a new step at the top of its `## Process` section:

```
### Step 0: Load spec context
Read all spec files provided in SPEC CONTEXT.
If SPEC CONTEXT is absent, list `openspec/specs/` and load up to 3 most-relevant domains by name match.
```

**Step 3 — Document the convention**

Create `docs/SPEC-CONTEXT.md` with the domain selection heuristic, the spec-loading step contract, and guidance on when to override (e.g., cross-cutting changes with no clear domain match).

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `CLAUDE.md` (sub-agent launch template) | Modified (SPEC CONTEXT block added) | Medium |
| `skills/sdd-explore/SKILL.md` | Modified (Step 0 added) | Low |
| `skills/sdd-propose/SKILL.md` | Modified (Step 0 added) | Low |
| `skills/sdd-spec/SKILL.md` | Modified (Step 0 added) | Low |
| `skills/sdd-design/SKILL.md` | Modified (Step 0 added) | Low |
| `skills/sdd-tasks/SKILL.md` | Modified (Step 0 added) | Low |
| `docs/SPEC-CONTEXT.md` | New (convention doc) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Incorrect domain inference adds irrelevant specs to context | Medium | Low | Sub-agent reads at most 3-5 files; irrelevant content has bounded noise |
| Domain name mismatch (slug uses different vocabulary than spec dir name) | Medium | Low | Fallback: if no match, sub-agent lists `openspec/specs/` and selects by judgment |
| Token cost increase per sub-agent invocation | Low | Low | Spec files are small; 3-5 files adds ~2k-5k tokens, well within limits |
| Spec files contradict ai-context/ summaries (version drift) | Low | Medium | Spec files take precedence; ai-context/ is explicitly demoted to supplementary |

## Rollback Plan

All changes are to SKILL.md and CLAUDE.md files tracked in git. If outputs regress:

1. `git diff skills/ CLAUDE.md docs/` to identify changed files
2. `git checkout -- <file>` to restore any file individually
3. Run `install.sh` to re-deploy the restored runtime config

## Dependencies

- No external dependencies.
- Companion proposal `2026-03-14-specs-search-optimization` introduces an index that would make domain selection more reliable — but this proposal is independently deployable without it.

## Success Criteria

- [ ] sdd-explore reads relevant master specs from `openspec/specs/` as part of Step 0
- [ ] sdd-propose reads relevant master specs before writing proposal
- [ ] sdd-spec reads relevant master specs before writing deltas
- [ ] sdd-design reads relevant master specs before producing design
- [ ] sdd-tasks reads relevant master specs before breaking down tasks
- [ ] Domain selection is explicit (not "read all specs") — sub-agent filters by relevant domains
- [ ] ai-context/ remains as supplementary context, not primary source of truth for system behavior
- [ ] Convention is documented in `docs/SPEC-CONTEXT.md`

## Effort Estimate

Medium (hours) — five SKILL.md edits, one CLAUDE.md edit, one new doc file. No logic changes to the spec files themselves.
