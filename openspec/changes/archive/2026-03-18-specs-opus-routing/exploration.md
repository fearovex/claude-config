# Exploration: Opus Model Routing for SDD Orchestrator

Change: 2026-03-18-specs-opus-routing
Date: 2026-03-18

---

## Current State

### Model assignment in the codebase

Every sub-agent Task call in the current system specifies `model: sonnet` (or in one case `model: haiku` for the orchestrator skill itself). The SKILL.md frontmatter for each skill also carries a `model:` field, but that field is metadata-only — it does not drive runtime model selection. Actual model assignment happens inline in the Task tool call blocks within the orchestrator skills (`sdd-ff/SKILL.md`, `sdd-new/SKILL.md`) and in CLAUDE.md.

Current model assignments (from `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`):

| Phase | Model assigned in Task call |
|-------|-----------------------------|
| explore | `sonnet` |
| propose | `sonnet` |
| spec | `sonnet` |
| design | `sonnet` + `thinking: enabled` |
| tasks | `sonnet` |
| apply | not orchestrated by sdd-ff/sdd-new |
| verify | not orchestrated by sdd-ff/sdd-new |

The orchestrator skills themselves (`sdd-ff`, `sdd-new`) carry `model: haiku` in their frontmatter — they are lightweight dispatchers.

### config.yaml schema

`openspec/config.yaml` has no `model_routing` section. The current schema supports these top-level optional sections:
- `skill_overrides` — redirect a skill to a custom path
- `rules` — per-phase governance rules
- `testing` — audit strategy, minimum score
- `feature_docs` — D10 feature detection configuration
- `analysis` — project-analyze sampling controls
- `apply_max_retries` — circuit breaker threshold
- `tdd` — TDD mode for sdd-apply
- `diagnosis_commands` — read-only commands for sdd-apply Diagnosis Step
- `verify_commands` — custom verification commands (highest priority)
- `verify` — structured verification config (level 2 priority)
- `coverage` — coverage threshold configuration

The `config-schema` spec (`openspec/specs/config-schema/spec.md`) documents the existing schema. The `verify:` section was the most recent addition (2026-03-17).

### Orchestrator Task call pattern

Both `sdd-ff/SKILL.md` and `sdd-new/SKILL.md` hardcode `model: sonnet` in each Task tool block. The orchestrator CONTEXT block (as specified in `openspec/specs/sdd-orchestration/spec.md`) MUST contain only: project path, change name, and prior artifact paths — no spec context, no model hints.

### Relevant specs

The `sdd-orchestration` spec documents the orchestrator's sub-agent launch contract. It does not address model selection. The `config-schema` spec is the authoritative source for `openspec/config.yaml` keys.

---

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `skills/sdd-ff/SKILL.md` | HIGH | All 5 Task call blocks need conditional model selection logic |
| `skills/sdd-new/SKILL.md` | HIGH | Same — 5 Task call blocks (explore + propose + spec + design + tasks) |
| `CLAUDE.md` | MEDIUM | May need model routing documentation in the Fast-Forward section and sub-agent launch pattern |
| `openspec/config.yaml` | LOW | New `model_routing:` section to be added (commented-out template) |
| `openspec/specs/config-schema/spec.md` | MEDIUM | New requirement and scenarios for `model_routing:` key |
| `openspec/specs/sdd-orchestration/spec.md` | MEDIUM | New scenarios: CLI flag propagation, model resolution order |
| `docs/adr/` | LOW | Likely warrants an ADR for the model routing decision |
| `openspec/specs/index.yaml` | LOW | New domain entry if a new spec domain is created |

Skills NOT affected (they do not own Task call blocks):
- All phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`) — they execute inside a Task, they do not launch Tasks themselves
- All meta-tool skills

---

## Analyzed Approaches

### Approach A: Orchestrator-side model resolution (recommended)

**Description**: The orchestrators (`sdd-ff`, `sdd-new`) read `model_routing` from `openspec/config.yaml` before launching sub-agents. A resolution algorithm selects the model for each phase. The `--opus` CLI flag is passed as part of the initial invocation and propagated by the orchestrator. The resolved model is injected into each Task call block.

Resolution order:
1. CLI flag (`--opus` / `--power`) → override ALL phases to `opus`
2. `model_routing.phases.<phase>` in config.yaml → per-phase model
3. Default → `sonnet`

**Pros**:
- All model logic lives in one place (the orchestrator); phase skills remain model-agnostic
- Clean separation: orchestrators own dispatch, phase skills own content
- Consistent with existing architecture (orchestrator-delegates-everything pattern)
- Config-driven and flag-driven paths are independent and composable

**Cons**:
- Both `sdd-ff` and `sdd-new` need to be updated (two files, similar logic)
- CLI flag parsing requires defining a convention for passing flags through the user description argument

**Estimated effort**: Medium
**Risk**: Low

---

### Approach B: SKILL.md frontmatter model selection (phase-side)

**Description**: Each phase SKILL.md `model:` frontmatter field is treated as runtime-authoritative. The orchestrator reads the SKILL.md frontmatter before launching each Task and uses the `model:` value from there. A config.yaml overlay overrides the frontmatter value.

**Pros**:
- Phase skills declare their own model preference
- Per-skill model tuning is possible without changing orchestrator code

**Cons**:
- Violates the current architecture — SKILL.md frontmatter `model:` is metadata-only today; promoting it to runtime-authoritative is a breaking semantic change
- Adds a SKILL.md-read step before every Task launch (performance + complexity)
- sdd-archive currently reads memory-update SKILL.md inline — precedent exists but is not universal
- Harder to express session-level override (CLI flag would still need orchestrator logic)

**Estimated effort**: Medium-High
**Risk**: Medium (breaking semantic change to frontmatter convention)

---

### Approach C: Environment variable / settings.json flag

**Description**: A global preference is stored in `settings.json` or a `.env` file. The orchestrator reads it at start.

**Pros**: Session-persistent without re-typing the flag every time

**Cons**:
- `settings.json` is for Claude Code permissions and MCP config, not model selection — mixing concerns
- No per-project override path; every project on the machine gets the same setting
- No per-phase granularity possible
- Harder to version-control project-level preferences

**Estimated effort**: Low
**Risk**: Medium (wrong layer — settings.json is not a routing config)

---

## Approach Comparison

| Approach | Pros | Cons | Effort | Risk |
|---|---|---|---|---|
| A: Orchestrator-side resolution | Single location, clean separation, composable | Two files to update, CLI flag convention needed | Medium | Low |
| B: Frontmatter-driven (phase-side) | Per-skill declaration | Breaks metadata-only convention, complexity | Medium-High | Medium |
| C: settings.json / env var | Simple persistence | Wrong layer, no per-project or per-phase control | Low | Medium |

**Recommendation: Approach A** — orchestrator-side model resolution with config.yaml `model_routing` section and CLI flag opt-in.

---

## Recommendation

Implement Approach A with the following design:

**config.yaml `model_routing` section** (new optional top-level key):

```yaml
model_routing:
  enabled: true
  phases:
    explore: opus
    design: opus
    verify: opus
    propose: sonnet
    spec: sonnet
    tasks: sonnet
    apply: sonnet
```

**CLI flag**: `/sdd-ff --opus <description>` or `/sdd-ff --power <description>` — the orchestrator strips the flag from the description before slug inference and sets a session-level `use_opus=true` variable that overrides all per-phase config values.

**Resolution algorithm** (in sdd-ff and sdd-new):

```
1. Check for --opus/--power flag in $ARGUMENTS → use_opus = true (all phases override)
2. Read openspec/config.yaml model_routing section (if absent, no-op)
3. For each phase Task call:
   IF use_opus == true → model: opus
   ELSE IF model_routing.phases.<phase> is set → model: <that value>
   ELSE → model: sonnet (default)
```

**Files to modify**:
- `skills/sdd-ff/SKILL.md` — add flag parsing in Step 0, model resolution in each Task call block
- `skills/sdd-new/SKILL.md` — same
- `openspec/config.yaml` — add commented-out `model_routing:` template section
- `CLAUDE.md` — update sub-agent launch pattern to document model resolution

**New spec domains**:
- `openspec/specs/config-schema/spec.md` — append `model_routing` requirement (delta to existing spec)
- `openspec/specs/sdd-orchestration/spec.md` — append CLI flag and model resolution requirements

An ADR is warranted for this decision (model routing is an architectural pattern with long-term implications).

---

## Identified Risks

- **CLI flag stripping from description**: The slug inference algorithm must correctly strip `--opus` and `--power` before processing. If not handled, the flag becomes part of the slug. Risk: LOW — the stop-words filter in the slug algorithm runs after flag extraction, so this can be cleanly handled as a pre-processing step. Mitigation: add an explicit flag extraction step BEFORE slug inference in both orchestrators.

- **`sdd-new` has user confirmation gates**: sdd-new's model resolution must propagate the `use_opus` flag across the confirmation gates (the flag is parsed once at Step 0 and held for the duration of the session). Risk: LOW — the orchestrator maintains state between phases already (artifact paths); adding a boolean flag is identical in nature.

- **Opus availability**: The feature assumes `opus` is a valid model identifier in the Task tool. If the model ID changes or is unavailable, Task calls will fail. Risk: LOW — this is a runtime dependency, not an architectural one. Mitigation: document the exact model ID in the spec and add a fallback note.

- **`sdd-apply` and `sdd-verify` are not orchestrated by sdd-ff/sdd-new**: These phases are user-invoked directly, so the CLI flag from the initial `/sdd-ff --opus` invocation will not carry over to them. If the user wants Opus for verify, they need a separate mechanism. Risk: MEDIUM — the proposed phase-aware defaults (opus for explore, design, verify) include verify, but when verify is run standalone, there is no flag context. Mitigation: define the `model_routing.phases.verify` config key as the solution for standalone verify; CLI flag applies only to the phases orchestrated in that session.

- **Backward compatibility**: Adding `model_routing` to config.yaml must be additive (absent = existing behavior). The `config-schema` spec already establishes the precedent that optional keys with absent-equals-default behavior are safe. Risk: NONE.

---

## Open Questions

1. **Model identifier**: Is the correct model ID `claude-opus-4-5` or just `opus`? The Task tool blocks in sdd-ff use `model: sonnet` (shorthand) — confirm opus shorthand works identically.

2. **Flag syntax**: Should `--opus` be parsed by the orchestrator, or should there be a separate command alias (e.g., `/sdd-ff-opus`)? The flag approach is more discoverable but requires parsing logic. A command alias would be simpler but adds CLAUDE.md registry entries.

3. **Standalone `/sdd-apply --opus`**: Should the CLI flag also work on standalone phase invocations? If yes, all phase orchestrator steps would need the flag extraction. If no, document the limitation clearly in the spec.

4. **sdd-verify and sdd-archive**: These are not covered by sdd-ff/sdd-new orchestration. Should model routing apply to them when invoked standalone? The `model_routing.phases` map could include them as config-driven-only (no CLI flag path needed for standalone).

---

## Ready for Proposal

Yes — the scope is well-defined, the affected files are identified, the resolution algorithm is clear, and the risks are all low to medium with clear mitigations. The main open questions (model ID shorthand, flag vs. alias, standalone phase routing) are design choices that the proposal and spec phases can resolve.
