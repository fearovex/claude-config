# Technical Design: 2026-03-18-specs-opus-routing

Date: 2026-03-18
Proposal: openspec/changes/2026-03-18-specs-opus-routing/proposal.md

## General Approach

Add a two-source model routing layer to the `sdd-ff` and `sdd-new` orchestrators. A pre-processing sub-step at Step 0 extracts the `--opus` / `--power` flag from `$ARGUMENTS` and reads `openspec/config.yaml` for a `model_routing.phases` map. Each subsequent Task call block receives a resolved model identifier derived from a deterministic three-level priority chain (CLI flag → per-phase config → Sonnet default). Phase skills are not modified; they execute inside Tasks and remain model-agnostic. Spec deltas and a config template comment are added to document the new behavior.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Model identifier for Opus in Task calls | `claude-opus-4-5` (full model ID) | `opus` shorthand, `claude-opus-latest` | Claude Code Task tool requires explicit model IDs — shorthand aliases are not guaranteed to resolve. Using the full ID prevents ambiguous routing. A fallback note documents behavior when the ID is invalid at runtime. |
| Flag placement in $ARGUMENTS | Pre-slug extraction at Step 0 (first sub-step before tokenization) | Post-slug extraction, separate `--model` flag | Extracting flags before slug inference prevents the flag token from polluting the slug algorithm. A single sub-step is cleanest; a `--model` flag was rejected to keep the user-facing API minimal. |
| Flag names | `--opus` and `--power` (aliases for same effect) | `--model opus`, `--high`, `--smart` | Proposal specifies both names as synonyms. `--power` is the informal alias; `--opus` is the explicit model reference. Both map to the same `use_opus = true` in-session variable. |
| Config schema structure | `model_routing.phases` map with phase name keys | `model_routing` as a flat string, `per_phase_models`, nested under `artifact_store` | A named map under a dedicated `model_routing` top-level key is consistent with the existing `verify:` top-level grouping convention (ADR 035). Phase-name keys match the sub-agent names already used as string identifiers in the orchestrators. |
| Resolution priority chain | CLI flag → per-phase config → `claude-sonnet-4-5` default | Config-first, runtime detection, env var | CLI flag is the most explicit user intent signal and must always win. Config provides per-project defaults without requiring a flag on every invocation. Sonnet is the established default; the existing behavior is preserved as the lowest-priority fallback. This is a cross-cutting convention introduced system-wide. |
| Where resolution logic lives | Inline in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md` | Shared skill, external config-reader | The orchestrators are the single point of Task call construction. Keeping resolution inline avoids a new file-read skill, maintains the "orchestrator owns Task construction" pattern (ADR 003), and keeps the logic auditable in one place per orchestrator. |
| Modification scope for phase SKILL.md files | No modification | Add model-selection step inside each phase skill | Phase skills are model-agnostic by design (they execute inside Tasks and cannot influence their own model parameter). Keeping them unchanged preserves single-responsibility: the orchestrator selects the model, the phase executes within it. |
| ADR warranted? | Yes — new cross-cutting convention for model resolution order | Inline comment only | The resolution priority chain is a system-wide architectural pattern that future sessions must understand and respect. It satisfies the ADR criteria: significant, long-lived, cross-cutting. |

---

## Data Flow

```
User: /sdd-ff --opus add payment flow
          │
          ▼
sdd-ff Step 0 — Pre-processing sub-step
  1. Detect --opus or --power in $ARGUMENTS → use_opus = true
  2. Strip flag token from description → "add payment flow"
  3. Infer slug from stripped description → "2026-03-18-payment-flow"
  4. Read openspec/config.yaml → extract model_routing.phases (if present)
          │
          ▼
sdd-ff Step 0 — Slug output + explore sub-agent launch
  Task(model: resolve("explore", use_opus, phase_map))
  → resolve() returns "claude-opus-4-5" (CLI flag wins)
          │
          ▼
sdd-ff Step 1 — propose sub-agent
  Task(model: resolve("propose", use_opus, phase_map))
          │
          ▼
sdd-ff Step 2 — spec + design sub-agents (parallel)
  Task(model: resolve("spec", use_opus, phase_map))
  Task(model: resolve("design", use_opus, phase_map), thinking: enabled)
          │
          ▼
sdd-ff Step 3 — tasks sub-agent
  Task(model: resolve("tasks", use_opus, phase_map))

resolve(phase, use_opus, phase_map):
  if use_opus → return "claude-opus-4-5"
  if phase_map[phase] exists → return phase_map[phase]
  return "claude-sonnet-4-5"   ← existing default
```

**No flag case (existing behavior preserved):**
```
User: /sdd-ff add payment flow
  use_opus = false, phase_map = {}
  → all Task calls use model: claude-sonnet-4-5 (unchanged)
```

**Config-only case:**
```
openspec/config.yaml:
  model_routing:
    phases:
      design: claude-opus-4-5

User: /sdd-ff add payment flow (no flag)
  use_opus = false, phase_map = {design: claude-opus-4-5}
  → explore: sonnet, propose: sonnet, spec: sonnet,
    design: opus (phase_map match), tasks: sonnet
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-ff/SKILL.md` | Modify | Step 0 expanded: add "Pre-processing sub-step" block (flag detection, strip, `use_opus` variable, `phase_map` read); each Task call block gets a `model: resolve(...)` note showing the priority chain |
| `skills/sdd-new/SKILL.md` | Modify | Same pre-processing sub-step added to Step 0; each Task call block updated with `model: resolve(...)` |
| `openspec/config.yaml` | Modify | Add commented-out `model_routing:` template section with `phases:` map example |
| `openspec/specs/config-schema/spec.md` | Modify | Append new requirement section: `model_routing` is an optional top-level key; scenarios covering absent key, valid key, CLI-flag override priority |
| `openspec/specs/sdd-orchestration/spec.md` | Modify | Append new scenarios: flag parsing (strip before slug), `use_opus` propagation across all Task blocks, three-level priority chain |
| `CLAUDE.md` | Modify | Update sub-agent launch pattern example to show `model: [resolved]`; update Fast-Forward section to document `--opus`/`--power` flag |
| `docs/adr/036-opus-routing-convention.md` | Create | ADR documenting the model resolution priority chain as a cross-cutting convention |
| `docs/adr/README.md` | Modify | Append ADR 036 row to the index table |

---

## Interfaces and Contracts

### In-session variables (sdd-ff and sdd-new Step 0)

```
use_opus: boolean
  true  → CLI flag --opus or --power was detected in $ARGUMENTS
  false → no flag present (default)

phase_map: { [phase_name: string]: model_id: string }
  Populated from openspec/config.yaml → model_routing.phases
  Empty map {} when key is absent or config.yaml is unreadable (non-blocking)
  Valid phase names: explore | propose | spec | design | tasks | apply | verify | archive

resolve(phase, use_opus, phase_map) → model_id: string
  Priority:
    1. if use_opus == true → "claude-opus-4-5"
    2. if phase_map[phase] exists → phase_map[phase]
    3. → "claude-sonnet-4-5"
```

### config.yaml model_routing schema

```yaml
# model_routing (optional) — Per-phase model selection for SDD orchestrators
# Supports two activation modes:
#   1. CLI flag: /sdd-ff --opus <description>  (overrides all phases)
#   2. Per-phase: model_routing.phases map     (overrides named phases only)
# Resolution order: CLI flag > per-phase config > Sonnet default
#
# model_routing:
#   phases:
#     explore: claude-opus-4-5    # sdd-explore phase
#     propose: claude-sonnet-4-5  # sdd-propose phase
#     spec:    claude-sonnet-4-5  # sdd-spec phase
#     design:  claude-opus-4-5    # sdd-design phase (recommended: Opus for architectural reasoning)
#     tasks:   claude-sonnet-4-5  # sdd-tasks phase
```

### SKILL.md Task block pattern (updated)

```
Task tool:
  subagent_type: "general-purpose"
  model: [resolved: claude-opus-4-5 if use_opus, else phase_map["explore"] if set, else claude-sonnet-4-5]
  prompt: |
    ...
```

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual smoke test | `/sdd-ff --opus add payment flow` — verify all Task call blocks use `claude-opus-4-5` | Claude Code session |
| Manual smoke test | `/sdd-ff add payment flow` — verify all Task call blocks use `claude-sonnet-4-5` | Claude Code session |
| Manual smoke test | `model_routing.phases.design: claude-opus-4-5` in config + no flag — verify only design Task uses Opus | Claude Code session |
| Slug integrity | `/sdd-ff --opus add payment flow` slug must be `2026-MM-DD-payment-flow`, not include "opus" | Manual inspection |
| `/project-audit` | Score must remain >= previous | project-audit skill |

---

## Migration Plan

No data migration required. All changes are additive text modifications to SKILL.md and spec files. Existing invocations without the `--opus` flag are unaffected — `use_opus` defaults to `false` and the existing Sonnet model path is unchanged.

---

## Open Questions

None.
