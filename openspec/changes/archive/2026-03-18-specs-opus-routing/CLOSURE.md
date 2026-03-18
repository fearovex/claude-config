# Closure: 2026-03-18-specs-opus-routing

Start date: 2026-03-18
Close date: 2026-03-18

## Summary

Added session-level and per-phase model routing to the SDD orchestrator (`sdd-ff` and `sdd-new`). Users can now invoke `/sdd-ff --opus <description>` or `/sdd-ff --power <description>` to run all SDD phases with `claude-opus-4-5`, and can configure per-phase model overrides in `openspec/config.yaml` under the new optional `model_routing:` section.

## Modified Specs

| Domain             | Action   | Change                                                                  |
| ------------------ | -------- | ----------------------------------------------------------------------- |
| config-schema      | Modified | 4 requirements added for `model_routing:` top-level key and resolution order |
| sdd-orchestration  | Modified | 7 requirements added for CLI flag propagation, session scoping, and Task call model injection |

## Modified Code Files

- `skills/sdd-ff/SKILL.md` — Step 0 pre-processing sub-step added; all 5 Task call blocks updated with `resolve()` model injection
- `skills/sdd-new/SKILL.md` — Step 0 pre-processing sub-step added; all 5 Task call blocks updated with `resolve()` model injection
- `openspec/config.yaml` — commented-out `model_routing:` template block added (lines 258–271)
- `openspec/specs/config-schema/spec.md` — model_routing requirements and rules appended
- `openspec/specs/sdd-orchestration/spec.md` — model routing requirements section appended
- `CLAUDE.md` — sub-agent launch pattern updated with `model:` field; Fast-Forward section updated with `--opus`/`--power` examples
- `docs/adr/036-opus-routing-convention.md` — new ADR created
- `docs/adr/README.md` — ADR 036 row added
- `ai-context/changelog-ai.md` — session entry added

## Key Decisions Made

- **Resolution priority chain**: CLI flag → per-phase config → Sonnet default — this order is fixed and cannot be overridden by any config key (ADR 036)
- **Duplication accepted**: resolution logic duplicated in `sdd-ff` and `sdd-new` instead of a shared skill, to keep each orchestrator self-contained (ADR 036)
- **Phase skills remain model-agnostic**: model selection is exclusively the orchestrator's responsibility — no phase SKILL.md files were modified
- **In-session scoping**: `use_opus` is an in-session variable; standalone phase invocations cannot inherit it from a prior session; `model_routing.phases` config is the mechanism for standalone routing
- **Full model IDs used**: `claude-opus-4-5` and `claude-sonnet-4-5` (not shorthands) to avoid Task tool ambiguity

## Lessons Learned

- The delta specs were already merged into master specs during the apply phase (the sdd-apply sub-agent appended them directly). The archive step confirmed this pattern — no additional merge work needed. Future changes should note that spec merging may occur during apply, making the archive merge step a verification pass rather than an action.
- No automated test runner exists for SKILL.md content; manual smoke test strategy is the accepted approach for this tech stack.

## User Docs Reviewed

N/A — this change modifies orchestrator skill behavior (model routing), not user-facing workflows documented in `scenarios.md`, `quick-reference.md`, or `onboarding.md`. The CLAUDE.md Fast-Forward section was updated as part of the change itself.
