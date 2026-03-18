# Verification Report: 2026-03-18-specs-opus-routing

Date: 2026-03-18
Verifier: sdd-verify

## Summary

| Dimension            | Status         |
| -------------------- | -------------- |
| Completeness (Tasks) | ✅ OK          |
| Correctness (Specs)  | ✅ OK          |
| Coherence (Design)   | ✅ OK          |
| Testing              | ⚠️ WARNING     |
| Test Execution       | ⏭️ SKIPPED     |
| Build / Type Check   | ℹ️ INFO        |
| Coverage             | ⏭️ SKIPPED     |
| Spec Compliance      | ✅ OK          |

## Verdict: PASS WITH WARNINGS

---

## Detail: Completeness

### Completeness

| Metric               | Value |
| -------------------- | ----- |
| Total tasks          | 13    |
| Completed tasks [x]  | 13    |
| Incomplete tasks [ ] | 0     |

All 13 tasks marked `[x]` in tasks.md. Progress header confirms: `## Progress: 13/13 tasks`.

---

## Detail: Correctness

### Correctness (Specs)

**Config-schema spec requirements:**

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| `model_routing` is an optional top-level section | ✅ Implemented | Commented-out template block present in `openspec/config.yaml` lines 258–271; no active key — does not break parsing |
| `model_routing.phases` maps phase names to model IDs | ✅ Implemented | Template shows `phases:` sub-map with five entries; base spec updated with requirement and scenarios |
| Model resolution order: CLI flag → per-phase config → Sonnet default | ✅ Implemented | `resolve()` function in both `sdd-ff` and `sdd-new` SKILL.md implements the three-level chain exactly |
| Commented-out `model_routing:` template present in config.yaml | ✅ Implemented | Template block present at lines 258–271 of `openspec/config.yaml`, all lines prefixed with `#` |

**SDD-orchestration spec requirements:**

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| `--opus` and `--power` activate session-level Opus routing | ✅ Implemented | Pre-processing sub-step in both SKILL.md files detects both flags |
| Flag detection occurs before slug inference and config reading | ✅ Implemented | Sub-step order is explicit: flag detect → strip → slug inference → config read |
| `use_opus` propagated to all Task calls | ✅ Implemented | All five Task blocks in `sdd-ff` (explore, propose, spec, design, tasks) and all five in `sdd-new` use `resolve(phase, use_opus, phase_map)` |
| Phase SKILL.md files remain model-agnostic | ✅ Implemented | Only `sdd-ff/SKILL.md` and `sdd-new/SKILL.md` modified; no phase skills altered |
| CLAUDE.md sub-agent launch pattern updated | ✅ Implemented | `model: [resolved: claude-opus-4-5 if --opus/--power flag, else phase_map[phase] if set, else claude-sonnet-4-5]` present |
| CLAUDE.md Fast-Forward section documents `--opus`/`--power` | ✅ Implemented | Bullet list with `/sdd-ff --opus <description>` and `/sdd-ff --power <description>` present |

### Scenario Coverage

| Scenario | Status |
| -------- | ------ |
| `config.yaml` without `model_routing` proceeds with Sonnet default | ✅ Covered — `resolve()` returns `claude-sonnet-4-5` when `phase_map = {}` |
| `config.yaml` with valid `model_routing` parses without errors | ✅ Covered — commented template does not affect YAML parsing |
| `model_routing.phases` accepted as string-to-string map | ✅ Covered — template shows correct structure; spec appended to base spec |
| Named phase uses config model when CLI flag absent | ✅ Covered — `resolve()` checks `phase_map[phase]` at priority 2 |
| Unrecognized phase name in `model_routing.phases` silently ignored | ✅ Covered — `resolve()` only checks the named phase key; unknown keys are not referenced |
| Non-map `model_routing.phases` treated as absent with WARNING | ✅ Covered — catch block in pre-processing sub-step handles non-map values |
| CLI flag takes priority over per-phase config | ✅ Covered — `resolve()` checks `use_opus` first |
| Per-phase config takes priority over Sonnet default | ✅ Covered — `resolve()` checks `phase_map[phase]` before returning Sonnet |
| Sonnet default applies when neither CLI flag nor config present | ✅ Covered — `resolve()` returns `claude-sonnet-4-5` as fallback |
| `--opus` sets `use_opus = true` and strips flag from description | ✅ Covered — explicit flag strip before slug inference in both SKILL.md files |
| `--power` is equivalent to `--opus` | ✅ Covered — both tokens checked in the same condition |
| No flag leaves `use_opus = false` | ✅ Covered — `else` branch sets `use_opus = false` |
| Flag stripped before slug inference — no mangled slugs | ✅ Covered — `description` (flag-stripped) is used for slug algorithm; explicit note present |
| Sub-step order: flag detect → slug inference → config read | ✅ Covered — order is explicit in the pre-processing sub-step pseudocode |
| `sdd-ff` propagates `use_opus` to all five phase Task calls | ✅ Covered — all five Task blocks updated |
| `sdd-new` propagates `use_opus` across confirmation gates | ✅ Covered — all Task blocks in Steps 1–4 use `resolve()` |
| Phase skill executes without awareness of model selected | ✅ Covered — no phase SKILL.md modified |
| No changes required to phase SKILL.md files | ✅ Covered — modified files list matches design expectation |
| Standalone invocations cannot inherit CLI flag from prior session | ✅ Covered — `use_opus` is an in-session variable; not persisted |
| Sub-agent launch pattern shows model field | ✅ Covered — CLAUDE.md updated |
| Fast-Forward section documents `--opus`/`--power` flags | ✅ Covered — CLAUDE.md Fast-Forward section updated |

---

## Detail: Coherence

### Coherence (Design)

| Decision | Followed? | Notes |
| -------- | --------- | ----- |
| Full model ID `claude-opus-4-5` (not shorthand) | ✅ Yes | Both SKILL.md files use `claude-opus-4-5` and `claude-sonnet-4-5` explicitly |
| Flag extraction before slug tokenization | ✅ Yes | Pre-processing sub-step runs first; slug algorithm note states it operates on `description` (flag-stripped) |
| Both `--opus` and `--power` as aliases → `use_opus = true` | ✅ Yes | Single condition covers both in pre-processing sub-step |
| `model_routing.phases` under dedicated top-level key (consistent with `verify:` pattern, ADR 035) | ✅ Yes | Template block uses `model_routing:` → `phases:` nesting |
| Priority chain: CLI flag → per-phase config → Sonnet default | ✅ Yes | `resolve()` function implements exactly this order |
| Resolution logic inline in `sdd-ff` and `sdd-new` (not a shared skill) | ✅ Yes | Near-identical sub-steps in both files; ADR 036 documents the duplication |
| Phase SKILL.md files not modified | ✅ Yes | Only orchestrator files modified |
| ADR warranted and created | ✅ Yes | `docs/adr/036-opus-routing-convention.md` created with all four required sections |
| `openspec/config.yaml` model_routing template as commented block | ✅ Yes | All lines begin with `#`; YAML parsing unaffected |
| CLAUDE.md updated with model field in sub-agent launch pattern | ✅ Yes | `model: [resolved: ...]` field present in template |

No design deviations detected.

---

## Detail: Testing

### Testing

| Area | Tests Exist | Notes |
| ---- | ----------- | ----- |
| Flag detection logic (`--opus`, `--power`) | ⚠️ No automated test | Inline pseudocode; manual smoke test strategy documented in design |
| `resolve()` priority chain | ⚠️ No automated test | Logic is documented; no unit test runner exists for SKILL.md files |
| Slug integrity (no flag in slug) | ⚠️ No automated test | Manual inspection recommended per design testing strategy |
| `openspec/config.yaml` YAML validity | ✅ Structural — YAML is commented-out | Template block does not break parsing |
| ADR 036 sections | ✅ Inspected — all four sections present | Status, Context, Decision, Consequences all present |
| ADR README row 036 | ✅ Confirmed | Row present in `docs/adr/README.md` |
| install.sh deployment | ✅ Confirmed | `~/.claude/skills/sdd-ff/SKILL.md` contains the `resolve()` logic — install.sh ran successfully |
| changelog-ai.md entry | ✅ Confirmed | Entry `[2026-03-18] — specs-opus-routing` present |

This project has no automated test runner for SKILL.md content — the tech stack is Markdown + YAML + Bash. The design explicitly documents a manual smoke test strategy. No automated test infrastructure exists or is expected.

---

## Tool Execution

| Command | Exit Code | Result |
|---------|-----------|--------|
| N/A | N/A | Test Execution: SKIPPED — no test runner detected |

Test Execution: SKIPPED — no test runner detected. Tech stack is Markdown + YAML + Bash. No `package.json`, `pyproject.toml`, `Makefile` with test target, `build.gradle`, or `mix.exs` found.

---

## Detail: Test Execution

| Metric        | Value              |
| ------------- | ------------------ |
| Runner        | none detected      |
| Command       | N/A                |
| Exit code     | N/A                |
| Tests passed  | N/A                |
| Tests failed  | N/A                |
| Tests skipped | N/A                |

No test runner detected. Skipped.

---

## Detail: Build / Type Check

| Metric    | Value                                                              |
| --------- | ------------------------------------------------------------------ |
| Command   | N/A                                                                |
| Exit code | N/A                                                                |
| Errors    | none                                                               |

No build command detected. Skipped. This is expected for a Markdown + YAML project with no compilation step.

---

## Spec Compliance Matrix

| Spec Domain | Requirement | Scenario | Status | Evidence |
| ----------- | ----------- | -------- | ------ | -------- |
| config-schema | `model_routing` is optional top-level section | `config.yaml` without `model_routing` proceeds with Sonnet default | COMPLIANT | `resolve()` returns `claude-sonnet-4-5` when `phase_map = {}` (code inspection) |
| config-schema | `model_routing` is optional top-level section | `config.yaml` with valid `model_routing` parses without errors | COMPLIANT | Template block is fully commented out; YAML parsing unaffected (code inspection) |
| config-schema | `model_routing.phases` maps phase names to model IDs | Accepted as string-to-string map | COMPLIANT | Template shows correct nesting; base spec updated (code inspection) |
| config-schema | `model_routing.phases` maps phase names to model IDs | Named phase uses config model when CLI flag absent | COMPLIANT | `resolve()` priority 2 checks `phase_map[phase]` before Sonnet default (code inspection) |
| config-schema | `model_routing.phases` maps phase names to model IDs | Unrecognized phase name silently ignored | COMPLIANT | `resolve()` only queries the named phase key; non-existent keys fall to Sonnet default (code inspection) |
| config-schema | `model_routing.phases` maps phase names to model IDs | Non-map `phases` treated as absent with WARNING | COMPLIANT | catch block sets `phase_map = {}` for parse errors and non-map values (code inspection) |
| config-schema | Model resolution order: CLI flag → per-phase config → Sonnet default | CLI flag takes priority over per-phase config | COMPLIANT | `resolve()` checks `use_opus` first — returns `claude-opus-4-5` unconditionally when true (code inspection) |
| config-schema | Model resolution order: CLI flag → per-phase config → Sonnet default | Per-phase config takes priority over Sonnet default | COMPLIANT | `resolve()` checks `phase_map[phase]` at priority 2 (code inspection) |
| config-schema | Model resolution order: CLI flag → per-phase config → Sonnet default | Sonnet default when neither CLI flag nor config specifies model | COMPLIANT | `resolve()` returns `claude-sonnet-4-5` as final fallback (code inspection) |
| config-schema | Commented-out template present in `openspec/config.yaml` | Template block present and syntactically commented out | COMPLIANT | Lines 258–271 in `openspec/config.yaml` begin with `#`; template shows `phases:` sub-key with 5 entries (code inspection) |
| sdd-orchestration | CLI flag `--opus` / `--power` activate Opus routing | `--opus` sets `use_opus = true` and strips flag | COMPLIANT | Pre-processing sub-step in both SKILL.md files; slug algorithm note confirms operation on stripped `description` (code inspection) |
| sdd-orchestration | CLI flag `--opus` / `--power` activate Opus routing | `--power` is equivalent to `--opus` | COMPLIANT | Both tokens checked in same condition in pre-processing sub-step (code inspection) |
| sdd-orchestration | CLI flag `--opus` / `--power` activate Opus routing | No flag leaves `use_opus = false` | COMPLIANT | `else` branch in pre-processing sub-step (code inspection) |
| sdd-orchestration | CLI flag `--opus` / `--power` activate Opus routing | Flag stripped before slug — no mangled slugs | COMPLIANT | Explicit note: "slug inference operates on `description` (flag-stripped), never on raw `$ARGUMENTS`" (code inspection) |
| sdd-orchestration | Flag detection at Step 0 before slug and config | Sub-step order: flag detect → slug inference → config read | COMPLIANT | Pre-processing sub-step is numbered 1–3 in exact order (code inspection) |
| sdd-orchestration | `use_opus` propagated to all Task calls | `sdd-ff` propagates to all five phase Task calls | COMPLIANT | All five Task blocks (explore, propose, spec, design, tasks) use `resolve(phase, use_opus, phase_map)` (code inspection + `~/.claude` install verified) |
| sdd-orchestration | `use_opus` propagated to all Task calls | `sdd-new` propagates across confirmation gates | COMPLIANT | All Task blocks in Steps 1–4 of `sdd-new` use `resolve()` (code inspection) |
| sdd-orchestration | Phase skills remain model-agnostic | Phase skill executes without model awareness | COMPLIANT | No phase SKILL.md files modified (code inspection of file change matrix) |
| sdd-orchestration | Phase skills remain model-agnostic | Only orchestrator files modified | COMPLIANT | Modified files: `sdd-ff/SKILL.md`, `sdd-new/SKILL.md`, `config.yaml`, two base specs, `CLAUDE.md`, ADR — no phase skills (code inspection) |
| sdd-orchestration | Standalone invocations cannot inherit CLI flag | Standalone `/sdd-verify` uses Sonnet regardless of prior session | COMPLIANT | `use_opus` is in-session only; not persisted to any file (code inspection) |
| sdd-orchestration | Standalone invocations cannot inherit CLI flag | Config-driven routing is the mechanism for standalone phase selection | COMPLIANT | `model_routing.phases` documented in config and spec; scenario documented in ADR (code inspection) |
| sdd-orchestration | CLAUDE.md updated | Sub-agent launch pattern shows model field | COMPLIANT | `model: [resolved: claude-opus-4-5 if --opus/--power flag, else phase_map[phase] if set, else claude-sonnet-4-5]` present in CLAUDE.md (code inspection) |
| sdd-orchestration | CLAUDE.md updated | Fast-Forward section documents `--opus`/`--power` | COMPLIANT | `/sdd-ff --opus <description>` and `/sdd-ff --power <description>` listed in Fast-Forward section (code inspection) |

---

## Issues Found

### CRITICAL (must be resolved before archiving):

None.

### WARNINGS (should be resolved):

- No automated test coverage for the `resolve()` priority chain or flag-detection logic. The design explicitly documents a manual smoke test strategy (Claude Code session). This is appropriate for a Markdown + YAML skill system with no test runner, but the slug integrity and model resolution behavior should be validated manually before relying on this in production sessions.

### SUGGESTIONS (optional improvements):

- Consider adding a `/sdd-ff --opus` invocation to the next real session as a smoke test to confirm slug does not contain "opus" and Task calls show `claude-opus-4-5` in the session log.
- The duplication of the resolution sub-step in `sdd-ff` and `sdd-new` is an acknowledged consequence (ADR 036). A future ADR could define a shared pseudocode reference file to reduce divergence risk.
