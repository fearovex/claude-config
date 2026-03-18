# Task Plan: 2026-03-18-specs-opus-routing

Date: 2026-03-18
Design: openspec/changes/2026-03-18-specs-opus-routing/design.md

## Progress: 13/13 tasks

---

## Phase 1: Foundation — Config and Specs

- [x] 1.1 Modify `openspec/config.yaml` — append a commented-out `model_routing:` template block after the existing `verify:` section comment block; block must include `phases:` sub-key with example entries for `explore`, `propose`, `spec`, `design`, and `tasks`; all lines must start with `#` so YAML parsing is unaffected

- [x] 1.2 Modify `openspec/specs/config-schema/spec.md` — append the full content of `openspec/changes/2026-03-18-specs-opus-routing/specs/config-schema/spec.md` (delta spec) to the end of the existing base spec file; preserve the existing `## Rules` section by inserting the new rules entries at the end of the existing `## Rules` section rather than duplicating it

- [x] 1.3 Modify `openspec/specs/sdd-orchestration/spec.md` — append the full content of `openspec/changes/2026-03-18-specs-opus-routing/specs/sdd-orchestration/spec.md` (delta spec) to the end of the existing base spec file; preserve the existing `## Rules` section using the same merge pattern as 1.2

---

## Phase 2: ADR and Documentation

- [x] 2.1 Verify `docs/adr/036-opus-routing-convention.md` exists and contains `## Status`, `## Context`, `## Decision`, and `## Consequences` sections — file was pre-created by the design phase; if all four sections are present mark complete; if any section is missing or contains template placeholder text (`We will ...`), fill in from the design's Technical Decisions table content

- [x] 2.2 Verify `docs/adr/README.md` already contains the ADR 036 row (`036-opus-routing-convention.md`) — row was pre-written by the design phase; if present mark complete; if missing, append `| [036](036-opus-routing-convention.md) | Model Routing Convention — Three-Level Priority Chain for Orchestrator Task Calls | Proposed | 2026-03-18 |` to the ADR Index table

---

## Phase 3: Core — Orchestrator Skill Modifications

- [x] 3.1 Modify `skills/sdd-ff/SKILL.md` — insert a "Pre-processing sub-step" block at the top of `### Step 0 — Infer slug and run exploration`, before the slug inference algorithm; the sub-step must:
  (a) detect `--opus` or `--power` in `$ARGUMENTS` and set `use_opus = true`, stripping the flag token from the description before slug inference
  (b) state that if neither flag is present, `use_opus = false`
  (c) read `openspec/config.yaml` and extract `model_routing.phases` into `phase_map`; if the key is absent or the file is unreadable, set `phase_map = {}` (non-blocking)
  (d) define the `resolve(phase, use_opus, phase_map)` inline pseudocode: returns `"claude-opus-4-5"` if `use_opus`, else `phase_map[phase]` if present, else `"claude-sonnet-4-5"` [WARNING: ADVISORY]
  Warning: `sdd-ff` and `sdd-new` will contain near-identical resolution sub-steps — future edits to the algorithm must be applied to both files.
  Reason: style or naming preference — no impact on current task; duplication is an explicitly documented consequence in ADR 036

- [x] 3.2 Modify `skills/sdd-ff/SKILL.md` — update the `model:` field in the **explore Task call block** (Step 0 Task) from `model: sonnet` to `model: resolve("explore", use_opus, phase_map)` with a comment showing the three-level priority; use the canonical string `[resolved: claude-opus-4-5 if use_opus, else phase_map["explore"] if set, else claude-sonnet-4-5]`

- [x] 3.3 Modify `skills/sdd-ff/SKILL.md` — update the `model:` field in the **propose Task call block** (Step 1), the **spec Task call block** (Step 2), the **design Task call block** (Step 2), and the **tasks Task call block** (Step 3) to the corresponding `resolve(phase, ...)` expression; each Task block must name its own phase in the resolve call

- [x] 3.4 Modify `skills/sdd-new/SKILL.md` — insert the same "Pre-processing sub-step" block added in task 3.1 into `### Step 0 — Infer slug from description`, before the slug inference algorithm; the sub-step content is identical to 3.1 (a)–(d)

- [x] 3.5 Modify `skills/sdd-new/SKILL.md` — update the `model:` field in all Task call blocks (explore in Step 1, propose in Step 2, spec and design in Step 3, tasks in Step 4) to the corresponding `resolve(phase, use_opus, phase_map)` expression, matching the pattern applied in tasks 3.2–3.3

---

## Phase 4: CLAUDE.md Documentation Update

- [x] 4.1 Modify `CLAUDE.md` — update the "Sub-agent launch pattern" example block under `### SDD Orchestrator — Delegation Pattern` to include a `model: [resolved]` field after `subagent_type: "general-purpose"`; add an inline comment or note stating the resolution order: `CLI flag → per-phase config → claude-sonnet-4-5 default`

- [x] 4.2 Modify `CLAUDE.md` — update the "Fast-Forward (/sdd-ff)" section to document the `--opus` and `--power` flags; add a note or example line showing `/sdd-ff --opus <description>` and stating that all phases use `model: claude-opus-4-5` when the flag is present

---

## Phase 5: Cleanup and Memory

- [x] 5.1 Run `bash install.sh` from the project root to deploy all modified skills and CLAUDE.md to `~/.claude/` — verify exit code 0

- [x] 5.2 Update `ai-context/changelog-ai.md` — append a session entry recording the addition of `--opus`/`--power` CLI flag support and `model_routing.phases` config key to `sdd-ff` and `sdd-new`; note the delta spec appends, ADR 036 creation, and the three-level priority chain convention

---

## Implementation Notes

- **Slug integrity is critical**: the flag pre-processing sub-step (tasks 3.1, 3.4) MUST run before the slug inference algorithm. The description passed to the slug algorithm must never contain `--opus` or `--power` tokens.
- **Exact model ID**: use `claude-opus-4-5` (full ID) for Opus, `claude-sonnet-4-5` (full ID) for Sonnet — not shorthand aliases. This is a design decision documented in the Technical Decisions table.
- **Non-blocking config read**: when reading `openspec/config.yaml` for `model_routing.phases`, any failure (missing file, missing key, non-map value) sets `phase_map = {}` and emits at most an INFO note — it MUST NOT produce `status: blocked`.
- **Phase names in resolve()**: the phase name passed to `resolve()` must match the sub-agent name used as a string identifier (e.g. `"explore"`, `"propose"`, `"spec"`, `"design"`, `"tasks"`).
- **ADR README already updated**: the ADR 036 index row was pre-inserted by the design phase. Tasks 2.1–2.2 are verification-only unless gaps are found.
- **Delta spec merge**: tasks 1.2–1.3 append delta content to existing spec files; the delta `## Rules` entries must be merged into the existing `## Rules` section, not added as a duplicate heading.

## Blockers

None.
