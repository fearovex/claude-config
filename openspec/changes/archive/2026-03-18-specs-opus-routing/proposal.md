# Proposal: 2026-03-18-specs-opus-routing

Date: 2026-03-18
Status: Draft

## Intent

Enable per-phase and session-level model selection (Sonnet vs. Opus) in the SDD orchestrator so that users can invoke higher-capability models for reasoning-intensive phases without manually editing skill files.

## Motivation

All SDD sub-agent Task calls currently hardcode `model: sonnet`. Phases like `sdd-explore`, `sdd-design`, and `sdd-verify` involve complex reasoning, ambiguity resolution, and architectural judgment where Claude Opus would produce meaningfully better output. Users have no mechanism — neither a CLI flag nor a config key — to opt into Opus for these phases. The absence of model routing forces a binary choice: always use Sonnet (fast, cheaper) or globally reconfigure the system (risky, manual). A structured routing mechanism allows project teams to tune model selection per-phase or activate Opus for an entire session with a single flag.

## Scope

### Included

- New optional `model_routing:` top-level section in `openspec/config.yaml` that maps phase names to model identifiers
- CLI flag support: `/sdd-ff --opus <description>` and `/sdd-ff --power <description>` override all phases to Opus for that session
- Flag parsing and model resolution logic added to `skills/sdd-ff/SKILL.md` (Step 0 pre-processing + per-Task injection)
- Flag parsing and model resolution logic added to `skills/sdd-new/SKILL.md` (same pattern)
- Commented-out `model_routing:` template section added to `openspec/config.yaml`
- Delta spec appended to `openspec/specs/config-schema/spec.md` documenting the new key
- Delta spec appended to `openspec/specs/sdd-orchestration/spec.md` documenting CLI flag propagation and model resolution order
- ADR for the model routing architectural decision

### Excluded (explicitly out of scope)

- Model routing for standalone phase invocations (`/sdd-apply --opus`, `/sdd-verify --opus`) — these are not orchestrated by `sdd-ff`/`sdd-new`; standalone phases can only use config-driven routing via `model_routing.phases`
- Runtime validation that the model identifier is a valid Claude model ID — this is a deploy-time concern; an invalid ID will produce a Task tool error at execution time
- UI or settings.json-level persistence of model preference — environment-variable and settings.json approaches are explicitly out of scope (see exploration.md Approach C analysis)
- Auto-selection heuristics (e.g., automatically choosing Opus when task complexity exceeds a threshold) — manual opt-in only for V1
- Modifying any phase SKILL.md (`sdd-explore`, `sdd-propose`, etc.) — phase skills remain model-agnostic; model selection is the orchestrator's responsibility

## Proposed Approach

The orchestrator (`sdd-ff` and `sdd-new`) gains a pre-processing step at Step 0 that:
1. Detects `--opus` or `--power` in the user's arguments and sets `use_opus = true`, stripping the flag from the description before slug inference.
2. Reads `openspec/config.yaml` and extracts the `model_routing.phases` map (if present).
3. At each Task call block, resolves the model using a priority chain: CLI flag → per-phase config → Sonnet default.

The resolution algorithm is deterministic and requires no new infrastructure — it operates entirely within the existing orchestrator SKILL.md instruction set. Phase skills are unchanged; they execute inside Tasks and are unaware of model selection.

The `config-schema` spec is extended with a new `model_routing` requirement section. The `sdd-orchestration` spec is extended with new scenarios covering CLI flag propagation and model resolution order. An ADR documents the architectural decision.

## Affected Areas

| Area/Module | Type of Change | Impact |
|---|---|---|
| `skills/sdd-ff/SKILL.md` | Modified | High — Step 0 addition, 5 Task call blocks updated |
| `skills/sdd-new/SKILL.md` | Modified | High — Step 0 addition, 5 Task call blocks updated |
| `openspec/config.yaml` | Modified | Low — commented-out template section only |
| `openspec/specs/config-schema/spec.md` | Modified | Medium — new requirement and scenarios appended |
| `openspec/specs/sdd-orchestration/spec.md` | Modified | Medium — new scenarios appended |
| `docs/adr/` | New file | Low — one new ADR |
| `CLAUDE.md` | Modified | Medium — sub-agent launch pattern and Fast-Forward section updated |

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| CLI flag not stripped before slug inference, producing mangled slugs like `opus-my-change` | Low | Medium | Define explicit flag extraction as the first sub-step in Step 0, before the slug inference algorithm runs |
| `use_opus` flag not propagated across `sdd-new` user confirmation gates | Low | Low | Flag is parsed once at Step 0 and held as an in-session variable — same pattern as artifact path state |
| `opus` shorthand not valid in Task tool (model ID format mismatch) | Low | Medium | Spec must document the exact model identifier; add a note to use the shortest working shorthand and fallback to `sonnet` if Task tool rejects the ID |
| Standalone `/sdd-verify` run cannot inherit CLI flag from prior `/sdd-ff --opus` session | Medium | Low | Clearly documented as out-of-scope for V1; config-driven `model_routing.phases.verify` is the solution for standalone verify model selection |
| Two-file duplication of resolution logic (sdd-ff and sdd-new) diverges over time | Low | Low | Resolution algorithm is documented in the spec as the authoritative source; both skills must match it |

## Rollback Plan

All changes are additive text modifications to SKILL.md files and spec files. Rollback steps:

1. Revert `skills/sdd-ff/SKILL.md` to the previous version via `git revert` or `git checkout HEAD~N -- skills/sdd-ff/SKILL.md`
2. Revert `skills/sdd-new/SKILL.md` identically
3. Revert `openspec/config.yaml` to remove the `model_routing:` commented section
4. The new ADR file may be left in place (it documents a decision that was made and then reverted) or deleted
5. Run `install.sh` to deploy the reverted skills to `~/.claude/`

No database migrations, no external dependencies, no data mutations — full rollback in under 5 minutes.

## Dependencies

- `openspec/specs/config-schema/spec.md` must exist and be writable (it does — confirmed in exploration)
- `openspec/specs/sdd-orchestration/spec.md` must exist and be writable (it does — confirmed in exploration)
- `openspec/config.yaml` must exist (it does)
- No new external tools or services required

## Success Criteria

- [ ] `/sdd-ff --opus fix-something` launches all phases (explore, propose, spec, design, tasks) using `model: opus` in their Task call blocks
- [ ] `/sdd-ff fix-something` (no flag) continues to use `model: sonnet` for all phases — existing behavior is unchanged
- [ ] A `model_routing:` section in `openspec/config.yaml` overrides the default model for named phases; the CLI flag takes priority over the config section
- [ ] The `config-schema` spec includes at least one scenario validating the `model_routing` key and its resolution order
- [ ] The `sdd-orchestration` spec includes at least one scenario covering CLI flag parsing and model resolution
- [ ] An ADR is present in `docs/adr/` documenting the model routing decision
- [ ] `install.sh` deploys the updated skills to `~/.claude/` successfully

## Effort Estimate

Medium (1–2 days) — two parallel SKILL.md edits with similar logic, two spec delta appends, one config template change, one ADR.
