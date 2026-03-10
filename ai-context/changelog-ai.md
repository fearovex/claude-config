# AI Changelog — claude-config

> Log of significant changes made with AI assistance. Newest first.

---

## [2026-03-10] — sdd-project-context-awareness

**Type**: SDD full cycle (spec + design + tasks + apply + verify + archive)
**Agent**: Claude Sonnet 4.6 (sdd-archive inline)
**Change**: `sdd-project-context-awareness`

**What changed**:
- `skills/sdd-explore/SKILL.md`: Added `### Step 0 — Load project context` block as the first step in `## Process`. This was the only remaining SDD phase skill without Step 0 — all others already had it.
- `docs/sdd-context-injection.md`: Canonical reference for skill authors (Step 0 template, dual-block variant, graceful degradation rules, staleness threshold).
- `docs/adr/024-sdd-project-context-awareness-convention.md`: ADR documenting the convention.
- `docs/adr/README.md`: Row added for ADR 024.
- `ai-context/architecture.md`: Decision 11 added.
- `openspec/specs/sdd-context-loading/spec.md`: New master spec (5 requirements, 10 scenarios).

**Files modified**:
- `skills/sdd-explore/SKILL.md`
- `openspec/specs/sdd-context-loading/spec.md` (promoted master spec)
- SDD cycle artifacts archived at `openspec/changes/archive/2026-03-10-sdd-project-context-awareness/`

**Decisions made**:
- Per-skill Step 0 file reads chosen over Context Capsule (YAML object) — simpler, self-contained, no orchestrator changes required.
- Context Capsule deferred to a future change as an optional enhancement.
- Dual-block structure (0a/0b) preserved for sdd-propose and sdd-spec.

---

## [2026-03-10] — sdd-verify-enforcement

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-verify-enforcement`

**What changed**:
- `skills/sdd-verify/SKILL.md`: Step 6 now checks for `verify_commands` key in `openspec/config.yaml` before auto-detection; when present, runs each listed command in sequence and skips auto-detection entirely. Step 10 mandates `## Tool Execution` section in every `verify-report.md` (even when skipped). Evidence rule added: a criterion may only be marked `[x]` when backed by tool output or explicit user-provided evidence. Two new rules added to `## Rules` section.
- `skills/sdd-apply/SKILL.md`: Output to Orchestrator block no longer suggests `/commit` or `git commit`; replaced with `/sdd-verify <change-name>` as the only permitted next-step suggestion.
- `openspec/config.yaml`: Added `verify_commands` documentation block (commented, mirroring the `diagnosis_commands` pattern).
- `ai-context/changelog-ai.md`: This entry.
- `ai-context/architecture.md`: New architectural decision entry.

**Files modified**:
- `skills/sdd-verify/SKILL.md`
- `skills/sdd-apply/SKILL.md`
- `openspec/config.yaml`
- `openspec/specs/sdd-verify-execution/spec.md` (3 requirements added, 1 modified)
- `openspec/specs/sdd-apply-execution/spec.md` (1 requirement added)

**Decisions made**:
- `verify_commands` key is a `list[string]` at top level of `openspec/config.yaml` — mirrors `diagnosis_commands` pattern; not additive with auto-detection.
- `[x]` evidence rule enforced as prose (SKILL.md Rules + Step 10 inline instruction), not as a hard code guard — consistent with all other SDD constraint enforcement.
- `/commit` suggestion removed (not disclaimered) from `sdd-apply` to eliminate the temptation entirely.

---

## [2026-03-10] — codebase-teach-skill

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `codebase-teach-skill`

**What changed**:
- `skills/codebase-teach/SKILL.md`: New procedural meta-tool skill. Five-step pipeline: Step 0 loads project context (non-blocking); Step 1 scans bounded context candidates via directory heuristics (depth ≤ 2 on `src/`, `app/`, `features/`, `domain/`, `openspec/specs/`); Step 2 reads up to `teach_max_files_per_context` key files per context sequentially (default 10); Step 3 writes or updates `ai-context/features/<slug>.md` using six-section format with `[auto-updated]` markers, preserving human-authored content; Step 4 evaluates coverage and writes `teach-report.md`.
- `CLAUDE.md`: `/codebase-teach` added to Available Commands (Meta-tools table) and Skills Registry (Meta-tool Skills subsection).
- `openspec/specs/codebase-teach/spec.md`: New master spec created (was new domain with no prior master spec).

**Files modified**:
- `skills/codebase-teach/SKILL.md` (new)
- `CLAUDE.md`
- `openspec/specs/codebase-teach/spec.md` (new master spec, promoted from delta)

**Decisions made**:
- Directory heuristic context detection (consistent with `project-analyze`); no AST parsing required.
- Sequential context processing to prevent context window saturation.
- `teach_max_files_per_context` key in `openspec/config.yaml` (optional, default 10).
- `[auto-updated]` marker convention reused from `project-analyze`; human content preserved byte-for-byte.
- `_template.md` and all `_`-prefixed files excluded at all steps.
- Manual-only invocation — never auto-triggered by any other skill.

---

## [2026-03-10] — sdd-parallelism-adr

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-parallelism-adr`

**What changed**:
- `docs/adr/028-sdd-parallelism-model.md`: New ADR documenting the SDD parallelism model — maximum 2 parallel Tasks, file conflict boundary rule, and evaluation of bounded-context parallel apply.
- `docs/adr/README.md`: ADR 028 registered in the index table.
- `openspec/specs/sdd-parallelism/spec.md`: New master spec created from delta (was a new domain with no prior master spec).

**Files modified**:
- `docs/adr/028-sdd-parallelism-model.md` (new)
- `docs/adr/README.md`
- `openspec/specs/sdd-parallelism/spec.md` (new master spec, promoted from delta)

---

## [2026-03-10] — sdd-verify-enforcement

**Type**: SDD apply
**Agent**: Claude Sonnet 4.6 (sdd-apply)
**Change**: `sdd-verify-enforcement`

**What changed**:
- `skills/sdd-verify/SKILL.md`: Step 6 now checks `verify_commands` in `openspec/config.yaml` before auto-detection; when present, `verify_commands` overrides auto-detection entirely. Step 10 now mandates a `## Tool Execution` section in every `verify-report.md` (even when skipped); added `[x]` evidence rule — a criterion may only be marked `[x]` when backed by tool output or explicit user evidence. Two new rules added to `## Rules` enforcing the Tool Execution section and the evidence gate.
- `skills/sdd-apply/SKILL.md`: Output to Orchestrator block updated — `/commit` suggestion removed; replaced with `/sdd-verify <change-name>` as the only permitted next-step suggestion after implementation is complete.
- `openspec/config.yaml`: added `verify_commands` optional key documentation block (commented, mirrors `diagnosis_commands` pattern).

**Files modified**:
- `skills/sdd-verify/SKILL.md`
- `skills/sdd-apply/SKILL.md`
- `openspec/config.yaml`

---

## [2026-03-10] — sdd-apply-diagnose-first

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-apply-diagnose-first`

**What changed**:
- `skills/sdd-apply/SKILL.md`: inserted new Step 4 (Diagnosis Step) between Step 3 (verify work scope) and the implementation step; old Steps 4–6 renumbered to 5–7; added `DIAGNOSIS` block template (6 fields: files, command outputs, current behavior, data/state, hypothesis, risk); added `MUST_RESOLVE` warning protocol for contradiction detection; documented `diagnosis_commands` config key in Step 1.
- `openspec/config.yaml`: added `diagnosis_commands` optional key with commented example block.
- `openspec/specs/sdd-apply/spec.md`: 3 new requirements appended (Mandatory Diagnosis Step, MUST_RESOLVE on contradictions, diagnosis_commands config key) with 8 scenarios and 5 new Rules entries.
- Verified PASS (no critical issues, no warnings).

**Files modified**:
- `skills/sdd-apply/SKILL.md` — Step 4 Diagnosis Step added; steps renumbered
- `openspec/config.yaml` — `diagnosis_commands` optional key documented
- `openspec/specs/sdd-apply/spec.md` — 3 requirements + 8 scenarios + 5 rules merged from delta

**Decisions made**:
- Diagnosis Step placed after Step 0 (tech skills loaded, context available) and before implementation — front-loading prevents change-fail-change-fail loops
- Structured prose block (not JSON) — consistent with DEVIATION and QUALITY_VIOLATION formats already in the skill
- MUST_RESOLVE pause on contradictions — auto-proceed rejected; contradicting assumptions are high-risk
- `diagnosis_commands` in `openspec/config.yaml` — follows established convention; no new config file needed
- Universal applicability (all tasks including creation) — avoids sub-agent classification overhead
- Per-task `[skip-diagnosis]` annotation explicitly deferred to a future proposal

---

## [2026-03-10] — sdd-apply-retry-limit

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-apply-retry-limit`

**What changed**:
- `skills/sdd-apply/SKILL.md`: added Step 0b (in-memory retry counter initialization, `apply_max_retries` config read with default 3); modified task execution loop to track attempt counts, detect same-strategy loops, mark tasks `[BLOCKED]` on limit, and halt the phase.
- `openspec/config.yaml`: added optional `apply_max_retries` key documentation.
- `openspec/specs/sdd-apply/spec.md`: 6 new requirements appended (Retry Counter per Task, Same Strategy Detection, User Resume Path, Configuration of Max Retries, BLOCKED State Marking, Agent Stop Behavior on BLOCKED).
- Verified PASS WITH WARNINGS (one warning: no automated test runner; verified by code inspection only).

**Files modified**:
- `skills/sdd-apply/SKILL.md` — Step 0b + retry circuit breaker in task execution loop
- `openspec/config.yaml` — `apply_max_retries` optional key added
- `openspec/specs/sdd-apply/spec.md` — 6 new requirements merged from delta

**Decisions made**:
- In-memory counter per invocation (not persistent) — simplicity; per-invocation reset is sufficient
- Default max_attempts = 3 — conservative; surfaces manual intervention early
- `apply_max_retries` key in `openspec/config.yaml` — project config stays in one place
- Hash-based same-strategy detection — robust, conservative, avoids false positives
- `[BLOCKED]` inline in tasks.md — discoverable, single source of truth
- Phase halt on BLOCKED (fail-fast) — context degradation worse than stopping early
- Manual resume via `[BLOCKED]` → `[TODO]` — explicit user control; auto-retry risks loops

---

## [2026-03-10] — sdd-new-improvements

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-new-improvements`

**What changed**:
- `skills/sdd-new/SKILL.md`: added Step 0 (slug inference algorithm with stop-word filter, date prefix, collision detection); made `sdd-explore` unconditional as Step 1 (removed optional gate); subsequent steps renumbered.
- `skills/sdd-ff/SKILL.md`: added Step 0 (slug inference + `sdd-explore` launch); removed name-input gate; all subsequent steps renumbered. Fast-forward now runs: explore → propose → spec+design (parallel) → tasks.
- `CLAUDE.md` Fast-Forward section: updated to document new 6-step flow with mandatory Step 0 exploration.
- `openspec/specs/sdd-orchestration/spec.md`: new master spec created from delta (new domain).

**Files modified**:
- `skills/sdd-new/SKILL.md` — Step 0 slug inference + unconditional explore added
- `skills/sdd-ff/SKILL.md` — Step 0 explore added, name gate removed, steps renumbered
- `CLAUDE.md` — Fast-Forward section updated

**Decisions made**:
- Slug inference duplicated in both SKILL.md files (not extracted to a utility) — acceptable for a simple leaf operation
- Stop word list hardcoded (stable, avoids external config overhead)
- Collision handling uses numeric suffix (`-2`, `-3`) — human-readable

---

## [2026-03-10] — sdd-blocking-warnings

**Type**: SDD archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-blocking-warnings`

**What changed**:
- Added a two-tier warning classification system to `sdd-tasks` and `sdd-apply`.
- `sdd-tasks` Step 4a: classifies each warning as `MUST_RESOLVE` or `ADVISORY` with a reason; records both in `tasks.md` using `[WARNING: TYPE]` inline markers.
- `sdd-tasks` Step 4b: documents the exact tasks.md format for MUST_RESOLVE (Warning, Reason, Question, Answer, Answered fields) and ADVISORY (Warning, Reason fields) entries.
- `sdd-apply` Step 5a: before executing any MUST_RESOLVE-flagged task, presents a blocking gate (`⛔ BLOCKED`) with no skip option; records the user's answer + ISO 8601 timestamp in tasks.md; then resumes execution.
- ADVISORY warnings are logged inline with task progress output; execution continues without user input.
- Created master spec: `openspec/specs/sdd-warning-classification/spec.md`.
- Verified PASS WITH WARNINGS (one warning: no E2E run on Audiio V3 test project).

**Files modified**:
- `skills/sdd-tasks/SKILL.md` — Steps 4a and 4b added (warning classification and tasks.md format)
- `skills/sdd-apply/SKILL.md` — Step 5a added (MUST_RESOLVE blocking gate + ADVISORY log-and-continue)
- `openspec/specs/sdd-warning-classification/spec.md` — created (new master spec from delta)
- `openspec/changes/archive/2026-03-10-sdd-blocking-warnings/` — archived
- `ai-context/architecture.md` — decision #13 added
- `ai-context/changelog-ai.md` — this entry

**Decisions made**:
- Warnings are stored inline in `tasks.md` (not a separate manifest); all context co-located with tasks
- Classification happens at sdd-tasks phase, not sdd-apply — risks are visible before execution begins
- Blocking gate has no skip option — answer is required; bypassing is structurally prevented
- Answers are preserved permanently in `tasks.md` with exact user text + timestamp — serves as a decision log

---

## [2026-03-10] — sdd-apply-diagnose-first

**Type**: SDD apply
**Agent**: Claude Sonnet 4.6 (sdd-apply)
**Change**: `sdd-apply-diagnose-first`

**What changed**:
- Added mandatory Step 4 — Diagnosis to `skills/sdd-apply/SKILL.md`. The Diagnosis Step runs before any file modification for each task: reads files to be modified, runs `diagnosis_commands` from config (if configured), and writes a structured `DIAGNOSIS` block (6 fields: files, command outputs, current behavior, data/state, hypothesis, risk).
- When Diagnosis reveals contradictions with task assumptions, a `MUST_RESOLVE` warning is raised and execution pauses until the user confirms.
- Added `diagnosis_commands` documentation to Step 1 (Read full context) in `skills/sdd-apply/SKILL.md`.
- Renumbered old Steps 4→5, 5→6, 6→7 to maintain sequential numbering after the insertion.
- Added commented `diagnosis_commands` optional key documentation block to `openspec/config.yaml`, consistent with existing optional key conventions.

**Files modified**:
- `skills/sdd-apply/SKILL.md` — Diagnosis Step added (new Step 4), subsequent steps renumbered, `diagnosis_commands` doc added to Step 1
- `openspec/config.yaml` — `diagnosis_commands` optional key documented (commented example block)

**Decisions made**:
- Diagnosis Step is mandatory for every task, including file-creation tasks (pattern reference reads still required)
- `DIAGNOSIS` block must be written before any file write — hard gate enforced by instruction ordering
- Multiple contradictions in one task are listed together in a single `MUST_RESOLVE` block with one combined confirmation wait

---

## [2026-03-10] — sdd-project-context-awareness

**Type**: SDD apply + archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**Change**: `sdd-project-context-awareness`

**What changed**:
- Added mandatory Step 0 — Load project context block to all six SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`). Step 0 reads `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, and the project Skills Registry before any phase output.
- `sdd-propose` and `sdd-spec` use a dual sub-step structure: Step 0a (global context) + Step 0b (domain feature preload, unchanged).
- `sdd-apply` inserts Step 0a (global context load) inside its existing Step 0 (Technology Skill Preload), before the scope guard.
- `sdd-design` now cross-references the project Skills Registry; unregistered skills are marked `[optional — not registered in project]`.
- Created `docs/sdd-context-injection.md` — canonical reference and Step 0 template for future skill authors.
- All changes verified (8/8 criteria passed).

**Files modified**:
- `skills/sdd-explore/SKILL.md` — Step 0 added
- `skills/sdd-propose/SKILL.md` — Step 0a + 0b structure added
- `skills/sdd-spec/SKILL.md` — Step 0a + 0b structure added
- `skills/sdd-design/SKILL.md` — Step 0 + Skills Registry cross-reference added
- `skills/sdd-tasks/SKILL.md` — Step 0 added
- `skills/sdd-apply/SKILL.md` — Step 0a sub-step added inside Step 0
- `docs/sdd-context-injection.md` — created
- `openspec/specs/sdd-phase-context-loading/spec.md` — ADDED and MODIFIED requirements merged from delta
- `openspec/specs/skill-authoring-conventions/spec.md` — new master spec created from delta
- `ai-context/architecture.md` — decision #11 added
- `ai-context/changelog-ai.md` — this entry

**Decisions made**:
- Step 0 is unconditionally non-blocking: absent `ai-context/` files never abort or fail the skill
- Staleness check: warn if `Last updated:` date is older than 7 days (non-blocking)
- Dual-block naming (Step 0a / Step 0b) chosen to avoid conflicting with existing step numbering in `sdd-propose` and `sdd-spec`

---

## [2026-03-10] — sdd-feedback-persistence

**Type**: Config + Documentation
**Agent**: Claude Haiku 4.5 (sdd-apply)
**Change**: `sdd-feedback-persistence`

**What changed**:
- Added Rule 5 — Feedback persistence to the Unbreakable Rules section of `CLAUDE.md` (both repo and runtime via install.sh). Rule enforces that feedback sessions produce only `proposal.md` files and must not trigger any SDD implementation commands in the same session.
- Created `docs/workflows/feedback-to-proposal.md` — end-to-end protocol for the feedback → proposal → separate-implementation session pattern, including proposal quality requirements and a worked example with two proposals.

**Files modified**:
- `CLAUDE.md` — Rule 5 added after Rule 4
- `docs/workflows/feedback-to-proposal.md` — created

---

## [2026-03-08] — settings-write-permissions-for-project-tools

**Type**: Config update
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Updated the repo-authoritative Claude Code permissions so routine write/edit operations used by `project-audit`, `project-fix`, and `project-analyze` no longer trigger repeated file-write approval prompts.

### Changes
- `settings.json` — added `Write` and `Edit` to the allowed tool permissions alongside `Read`, `Glob`, `Grep`, and `Bash`.

### Decisions
- The change is intentionally narrow: it enables routine file writes and edits required by the existing project-management skills without broadening unrelated permissions.
- This addresses the operational friction where `project-audit` writes `.claude/audit-report.md`, `project-analyze` writes `analysis-report.md` plus `ai-context/` auto-updated sections, and `project-fix` applies file edits from the audit manifest.

---

## [2026-03-08] — clean-skill-template-noise (apply)

**Type**: SDD apply
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Reduced low-priority template noise in the active skill catalog by balancing the `project-audit` report example fences and replacing raw scaffold `TODO` markers with explicit scaffold wording.

### Changes
- `skills/project-audit/SKILL.md` — rebalanced the nested fenced example in `## Report Format` so the outer Markdown fence and inner YAML fence now close cleanly once each.
- `skills/project-fix/SKILL.md` — replaced raw `TODO` placeholder text in the active stub templates with explicit scaffold wording.
- `skills/project-claude-organizer/SKILL.md` — replaced raw `TODO` placeholder text in the generated-skill scaffold examples with explicit scaffold wording.
- `openspec/changes/clean-skill-template-noise/` — created proposal, design, tasks, delta spec, and verify artifacts for the active cleanup change.

### Decisions
- The cleanup stayed in-place inside the existing skills instead of moving templates into dedicated files, because the goal was to reduce audit noise without enlarging scope.
- Placeholder language now states explicitly that scaffold text must be replaced, but it no longer uses generic `TODO` markers in the targeted active examples.
- `bash install.sh` completed successfully after the cleanup; MCP registration remained skipped because the `claude` CLI is not in PATH.

---

## [2026-03-08] — clean-skill-template-noise (archive)

**Type**: SDD archive
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Archived the low-priority skill-template cleanup after promoting its requirements into the active master specs and moving the change into `openspec/changes/archive/`.

### Changes
- `openspec/specs/skill-template-noise/spec.md` — created as the master spec for balanced nested report fences and explicit scaffold placeholder wording.
- `openspec/changes/archive/2026-03-08-clean-skill-template-noise/` — archived change folder created.
- `openspec/changes/archive/2026-03-08-clean-skill-template-noise/CLOSURE.md` — created.

### Decisions
- The cleanup remains purely non-functional: it reduces active skill-template noise without changing command flow, mutation scope, or trigger behavior.
- The verify report remained `PASS WITH WARNINGS` because the known external `format:` validator mismatch and the missing `claude` CLI in `PATH` are outside the scope of this change.
- No user-facing workflow docs required updates because the change only touched active skill examples and report formatting.

---

## [2026-03-06] — normalize-skill-contract-debt (apply)

**Type**: SDD apply
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Normalized the active SDD and `project-*` skill contract so command triggers, procedural section headings, and audit validation now describe the same live structure.

### Changes
- `skills/sdd-explore/SKILL.md`, `skills/sdd-propose/SKILL.md`, `skills/sdd-spec/SKILL.md`, `skills/sdd-design/SKILL.md`, `skills/sdd-tasks/SKILL.md`, `skills/sdd-apply/SKILL.md`, `skills/sdd-verify/SKILL.md`, `skills/sdd-archive/SKILL.md` — replaced legacy `sdd:phase` trigger markers with slash-command triggers.
- `skills/sdd-ff/SKILL.md`, `skills/sdd-new/SKILL.md`, `skills/project-setup/SKILL.md`, `skills/project-fix/SKILL.md`, `skills/project-audit/SKILL.md` — normalized the top-level procedural section to literal `## Process`; `sdd-ff` and `sdd-new` now nest step headings beneath that section.
- `skills/project-update/SKILL.md` and `skills/project-setup/SKILL.md` — expose slash-command triggers.
- `skills/project-audit/SKILL.md` — tightened compatibility wording and active validation to require canonical `## Process` and `## Rules` headings.
- `docs/format-types.md`, `.github/copilot-instructions.md`, and `ai-context/conventions.md` — aligned active documentation with the canonical contract.
- `openspec/specs/skill-format-types/spec.md`, `openspec/specs/project-audit-core/spec.md`, and `openspec/specs/audit-execution/spec.md` — promoted the normalized contract into the active master specs.

### Decisions
- The repo now treats slash commands as the canonical trigger form for active SDD and `project-*` skills; natural-language trigger phrases remain allowed as secondary discoverability aids.
- Active procedural skills use a literal `## Process` heading; `### Step N` remains nested content inside that section rather than an alternative top-level structure.
- `## Execution rules` remains historical terminology only; active-catalog validation uses `## Rules` as the canonical terminal rules heading.
- `bash install.sh` completed successfully after the contract normalization; MCP registration remained skipped because the `claude` CLI is not in PATH.

---

## [2026-03-06] — normalize-skill-contract-debt (archive)

**Type**: SDD archive
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Archived the skill-contract debt cleanup after promoting the normalized trigger and heading contract into the active master specs and moving the change into `openspec/changes/archive/`.

### Changes
- `openspec/specs/skill-format-types/spec.md` — updated to describe canonical active `## Process` and `## Rules` headings.
- `openspec/specs/project-audit-core/spec.md` — updated so compatibility policy no longer implies legacy heading equivalence for active validation.
- `openspec/specs/audit-execution/spec.md` — updated so the batching constraint lives in the canonical `## Rules` section.
- `openspec/changes/archive/2026-03-06-normalize-skill-contract-debt/` — archived change folder created.
- `openspec/changes/archive/2026-03-06-normalize-skill-contract-debt/CLOSURE.md` — created.

### Decisions
- The active repository contract is now stricter than the historical archive: archived references may still mention older labels, but live skills, live docs, and live validation no longer preserve them as equivalent forms.
- The cycle closed as `PASS WITH WARNINGS` because automated tests for skill content still do not exist and MCP registration still depends on the missing `claude` CLI.

## [2026-03-06] — narrow-project-claude-organizer-scope (apply)

**Type**: SDD apply
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Narrowed the top-level contract of `project-claude-organizer` so the command now exposes an explicit organizer kernel, scope boundaries, and compatibility policy.

### Changes
- `skills/project-claude-organizer/SKILL.md` — added `## Organizer Kernel`, `## Scope Boundaries`, and `## Compatibility Policy`; clarified that unexpected structures remain advisory-first, skills audit does not expand mutation scope, and cleanup deletion is a follow-up opt-in step rather than organizer core behavior.
- `openspec/specs/project-claude-organizer/spec.md` — updated the cumulative organizer master spec with the narrowed-scope requirements.
- `openspec/changes/narrow-project-claude-organizer-scope/verify-report.md` — created verification artifact for the SDD cycle.

### Decisions
- This phase intentionally narrows the organizer contract without deleting the existing migration handlers.
- The cumulative `project-claude-organizer` spec remains the master spec domain; this cycle adds scope-control requirements to it rather than creating a new standalone master domain.
- `install.sh` was run successfully after the skill change; MCP registration remained skipped because the `claude` CLI is not in PATH.

---

## [2026-03-06] — narrow-project-claude-organizer-scope (archive)

**Type**: SDD archive
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Archived the organizer scope rewrite after promoting the narrowed-scope contract into the cumulative `project-claude-organizer` master spec and moving the active change into `openspec/changes/archive/`.

### Changes
- `openspec/specs/project-claude-organizer/spec.md` — updated cumulative organizer master spec with explicit kernel, scope-boundary, and advisory-first requirements.
- `openspec/changes/archive/2026-03-06-narrow-project-claude-organizer-scope/` — archived change folder created.
- `openspec/changes/archive/2026-03-06-narrow-project-claude-organizer-scope/CLOSURE.md` — created.

### Decisions
- The organizer rewrite sequence is now complete at the contract level: memory-layer extension, commands conversion, and scope narrowing all live in the same cumulative master spec.
- The cycle closed as `PASS WITH WARNINGS` because there is still no automated test suite for skill changes and runtime deployment still depends on a missing `claude` CLI for MCP registration.
- Any future organizer work should focus on reducing or extracting handlers rather than adding more scope to the live skill.

---

## [2026-03-06] — project-claude-organizer-commands-conversion (apply)

**Type**: SDD apply
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Completed the active organizer rewrite by formalizing commands/ scaffolding, project-local skills audit reporting, emoji-normalized section distribution, and explicit `readme.md` migration handling.

### Changes
- `skills/project-claude-organizer/SKILL.md` — exposes active `commands/` scaffolding, `### Step 3c — Skills Audit`, emoji-normalized `section-distribute`, explicit `readme.md` user-choice migration, and report sections for `### Commands scaffolded`, `### Skills audit`, and `### readme.md migration`.
- `openspec/specs/project-claude-organizer/spec.md` — promoted the active delta requirements into the master organizer spec without removing earlier memory-layer and cleanup requirements.
- `openspec/changes/project-claude-organizer-commands-conversion/verify-report.md` — created verification artifact for the cycle.

### Decisions
- The organizer keeps the additive-first safety model: `commands/` can scaffold new skills, but source files under `.claude/commands/` remain non-deletable.
- Skills audit remains advisory-only even when it reports HIGH findings; organizer does not gain permission to rewrite or delete local skills automatically.
- `install.sh` was run successfully after the artifact updates; MCP registration remained skipped because the `claude` CLI is not in PATH.

---

## [2026-03-06] — project-claude-organizer-commands-conversion (archive)

**Type**: SDD archive
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Archived the organizer commands-conversion cycle after promoting its requirements into the cumulative `project-claude-organizer` master spec and moving the active change into `openspec/changes/archive/`.

### Changes
- `openspec/specs/project-claude-organizer/spec.md` — updated as the cumulative master organizer spec, now including commands/ scaffold behavior, skills audit, emoji normalization, and `readme.md` migration requirements.
- `openspec/changes/archive/2026-03-06-project-claude-organizer-commands-conversion/` — archived change folder created.
- `openspec/changes/archive/2026-03-06-project-claude-organizer-commands-conversion/CLOSURE.md` — created.

### Decisions
- The organizer master spec remains cumulative because this skill already had an established domain that now carries multiple behavioral extensions.
- The cycle closed as `PASS WITH WARNINGS` because there is still no automated test suite for skill changes and runtime deployment still depends on a missing `claude` CLI for MCP registration.
- The next organizer rewrite, if pursued, should be a narrower scope reduction pass rather than another feature-expansion cycle.

---

## [2026-03-06] — simplify-project-fix-action-model (apply)

**Type**: SDD apply
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Reworked the top-level contract of `project-fix` so the command now exposes an explicit execution model, action classes, and compatibility policy.

### Changes
- `skills/project-fix/SKILL.md` — added `## Execution Model`, `## Action Classes`, and `## Compatibility Policy`; clarified action normalization in Step 1; added an explicit rule that unknown or deprecated action types never gain automatic side effects.
- `openspec/changes/simplify-project-fix-action-model/` — created proposal, PRD shell, spec, design, tasks, and verify artifacts for the SDD cycle.

### Decisions
- This phase intentionally rewrites the command contract, not the detailed logic of every Phase 1-5 handler.
- The existing `project-fix-behavior` and `fix-setup-behavior` specs remain valid detailed behavior specs; the new `project-fix-action-model` domain acts as the umbrella contract.
- `install.sh` was run successfully after the skill change; MCP registration remained skipped because the `claude` CLI is not in PATH.

---

## [2026-03-06] — simplify-project-fix-action-model (archive)

**Type**: SDD archive
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Archived the `simplify-project-fix-action-model` cycle after promoting the new `project-fix-action-model` master spec and moving the active change into `openspec/changes/archive/`.

### Changes
- `openspec/specs/project-fix-action-model/spec.md` — created as the new umbrella master spec for `project-fix`.
- `openspec/changes/archive/2026-03-06-simplify-project-fix-action-model/` — archived change folder created.
- `openspec/changes/archive/2026-03-06-simplify-project-fix-action-model/CLOSURE.md` — created.

### Decisions
- The new `project-fix-action-model` spec complements `project-fix-behavior` and `fix-setup-behavior`; it does not replace them.
- The cycle closed as `PASS WITH WARNINGS` because the repo still has no automated tests for skill changes and the `format:` validator mismatch remains external to this change.
- No user-doc update was needed because command names and onboarding workflows were unchanged.

## [2026-03-06] — rewrite-project-audit-core (apply)

**Type**: SDD apply
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Reworked the top-level contract of `project-audit` so the command now exposes an explicit audit kernel, dimension classes, and compatibility policy.

### Changes
- `skills/project-audit/SKILL.md` — added `## Audit Kernel`, `## Dimension Classes`, and `## Compatibility Policy`; changed the top-level process heading to `## Audit Process`; clarified that legacy `## Execution rules` acceptance is transitional compatibility only; added an explicit compatibility rule in `## Rules`.
- `openspec/changes/rewrite-project-audit-core/` — created proposal, PRD shell, spec, design, tasks, and verify artifacts for the SDD cycle.

### Decisions
- This phase intentionally rewrites the command contract, not the detailed logic of every dimension.
- The existing `audit-execution`, `audit-dimensions`, and `audit-scoring` specs remain valid cross-cutting detail specs; the new `project-audit-core` domain acts as the umbrella contract.
- `install.sh` was run successfully after the skill change; MCP registration remained skipped because the `claude` CLI is not in PATH.

---

## [2026-03-06] — rewrite-project-audit-core (archive)

**Type**: SDD archive
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Archived the `rewrite-project-audit-core` cycle after promoting the new `project-audit-core` master spec and moving the active change into `openspec/changes/archive/`.

### Changes
- `openspec/specs/project-audit-core/spec.md` — created as the new umbrella master spec for `project-audit`.
- `openspec/changes/archive/2026-03-06-rewrite-project-audit-core/` — archived change folder created.
- `openspec/changes/archive/2026-03-06-rewrite-project-audit-core/CLOSURE.md` — created.

### Decisions
- The new `project-audit-core` spec complements `audit-execution`, `audit-dimensions`, and `audit-scoring`; it does not replace them.
- The cycle closed as `PASS WITH WARNINGS` because the repo still has no automated tests for skill changes and the `format:` validator mismatch remains external to this change.
- No user-doc update was needed because command names and onboarding workflows were unchanged.

## [2026-03-06] — Project skills portfolio review

**Type**: Audit / Portfolio review
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Reviewed the `skills/project-*` catalog as a portfolio and assigned explicit disposition recommendations: keep, rewrite, merge, or deprecate.

### Changes
- `project-skills-portfolio-review.md` — created: portfolio review for `project-setup`, `project-onboard`, `project-audit`, `project-analyze`, `project-fix`, `project-update`, and `project-claude-organizer`.

### Decisions
- The `project-*` portfolio should be preserved as a group; no immediate merge or deprecate action is recommended.
- `project-audit`, `project-fix`, and `project-claude-organizer` are the three rewrite candidates because they concentrate the highest complexity and maintenance churn.
- `project-setup`, `project-onboard`, `project-analyze`, and `project-update` still have sufficiently distinct boundaries to keep without structural change.

---

## [2026-03-06] — Project skills rewrite roadmap

**Type**: Design / Roadmap
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Converted the portfolio review into an implementation-order roadmap for rewriting the three highest-cost `project-*` skills.

### Changes
- `project-skills-rewrite-roadmap.md` — created: rewrite goals, principles, sequencing, and suggested SDD change names for `project-audit`, `project-fix`, and `project-claude-organizer`.

### Decisions
- `project-audit` should be rewritten first because it defines the diagnostic contract consumed by the rest of the project-health flow.
- `project-fix` should be rewritten second against the stabilized audit contract, with a reduced action taxonomy.
- `project-claude-organizer` should be rewritten last with a narrower, more conservative migration scope.

## [2026-03-06] — Content and relevance audit for SDD and project skills

**Type**: Audit / Analysis
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Reviewed `skills/sdd-*` and `skills/project-*` for purpose, relevance, overlap, and contract consistency.

### Changes
- `sdd-project-skills-audit-report.md` — created: content and relevance audit focused on SDD phase skills and `project-*` meta-tool skills.

### Decisions
- The main debt in the SDD and `project-*` layer is not missing files but consistency debt: mixed trigger syntax, mixed procedural-section contracts, and audit rules that still accept legacy structure.
- The current SDD and `project-*` catalog is operationally relevant as a group; no immediate candidate for removal was identified in this pass.
- Future cleanup should prioritize command normalization and contract alignment before any merge/deprecate decisions.

---

## [2026-03-06] — Repository consistency corrections after full audit

**Type**: Documentation / Configuration
**Agent**: GitHub Copilot (GPT-5.4)
**Change**: Corrected active repository inconsistencies found during the full-project audit.

### Changes
- `README.md` — corrected `sync.sh` semantics to memory-only, updated contribution workflow to use `install.sh` for config changes, and removed stale session-sync guidance.
- `ai-context/known-issues.md` — removed obsolete full-runtime sync and `rsync` guidance; clarified the current split between `install.sh` and `sync.sh`.
- `ai-context/stack.md` — aligned the project description and directory comments with the memory-only `sync.sh` model; updated observed skill count to 49.
- `skills/project-fix/SKILL.md` — renamed the final `## Execution rules` section to canonical `## Rules`.
- `memory/MEMORY.md` — translated to English, removed outdated command forms, and updated the skill references.
- `.github/copilot-instructions.md` — updated the skill count and replaced the obsolete `rsync` note with the current cross-platform `sync.sh` behavior.
- `GEMINI.md` — updated the skill count and replaced the obsolete `rsync` note with the current cross-platform `sync.sh` behavior.
- `repo-audit-report.md` — preserved as the audit baseline and annotated to reflect the initial correction pass.

### Decisions
- `sync.sh` remains documented strictly as `~/.claude/memory/ -> repo/memory/`; no active file should describe it as a general runtime sync.
- Hardcoded skill counts are kept only where they add value and must reflect the current catalog size.
- `memory/MEMORY.md` remains versioned in the repo for now, but its content must still follow the English-only repository rule.

---

## [2026-03-04] — project-claude-organizer-commands-conversion (apply phases 1–5)

**Type**: SDD apply
**Agent**: Claude Sonnet 4.6 (sdd-apply)
**Change**: Extended `skills/project-claude-organizer/SKILL.md` with active commands/ scaffold, Step 3c skills audit, updated report template, and metadata updates across CLAUDE.md and architecture.md.

### Changes
- **Active scaffold strategy for commands/**: `LEGACY_PATTERN_TABLE` row for `commands/` changed from `strategy: delegate` to `strategy: scaffold`. Step 3b now actively derives a skill name from the file stem (kebab-case), infers format type via a 4-signal heuristic (anti-pattern heading → `anti-pattern`; Patterns/Examples heading → `reference`; step-numbered or process heading or no signals → `procedural`), checks idempotency (skip if SKILL.md already exists), and writes SKILL.md skeleton to `.claude/skills/<stem>/SKILL.md`. Source files in commands/ are never modified or deleted.
- **Step 3c skills audit**: New step inserted after Step 3b — enumerates all immediate subdirectories of `.claude/skills/`; applies three detection rules: scope-overlap (HIGH severity — skill present in both `.claude/skills/` and `~/.claude/skills/` per CLAUDE.md Skills Registry), broken-shell (MEDIUM severity — SKILL.md missing or empty), suspicious-name (LOW severity — directory name contains spaces, uppercase letters, or underscores). Findings accumulated in `SKILL_AUDIT_FINDINGS` list. Step skipped entirely when `.claude/skills/` is absent.
- **Updated report template**: Added `### Commands scaffolded` subsection listing per-file outcomes (scaffolded with format type, already exists — not overwritten, advisory only); section omitted when commands/ was absent. Added `### Skills audit` subsection rendering SKILL_AUDIT_FINDINGS as a Skill | Finding | Severity table; shows "No issues detected" message when empty; section omitted when .claude/skills/ was absent.
- **Emoji normalization in section-distribute strategy** (Phase 6, in progress): Step 5.7.2 will strip leading Unicode emoji characters and trailing whitespace before comparing headings against signal lists.
- **readme.md as explicit LEGACY_MIGRATION** (Phase 6, in progress): `readme.md` will be removed from the shared `project.md / readme.md` section-distribute block and classified as its own `user-choice` strategy entry with Option A (append to CLAUDE.md under labeled marker) and Option B (copy to docs/README-claude.md).
- **CLAUDE.md updated**: Skills Registry entry for `project-claude-organizer` in System Audits section updated to describe active scaffold and skills audit capabilities.
- **ai-context/architecture.md updated**: `claude-organizer-report.md` artifact row extended to mention `### Commands scaffolded` and `### Skills audit` report subsections.

### Decisions
- Skills audit detection rules use severity levels consistent with `claude-folder-audit` (HIGH/MEDIUM/LOW) for consistency across audit tools.
- Scope-overlap detection reads the project's own CLAUDE.md Skills Registry (not `~/.claude/CLAUDE.md`) and compares by directory name stem using case-sensitive string matching.
- Idempotency guard (skip if SKILL.md already exists) is mandatory before any scaffold write — preserves the additive invariant (Rule 2 of the organizer).

---

## [2026-03-04] — config-export-token-optimization (archive)

**Type**: SDD cycle closure
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: Archived change `config-export-token-optimization`. Synced delta specs to master specs: appended 2 new requirements + 4 new Rules entries to `openspec/specs/config-export-skill/spec.md`; appended 4 new requirements + 6 new Rules entries to `openspec/specs/config-export-targets/spec.md`. Change folder moved to `openspec/changes/archive/2026-03-04-config-export-token-optimization/`. verify-report.md had 5 [x] criteria with no critical blockers; 3 deferred criteria (output equivalence tests) pending next live `/config-export all` run.
**Modified files**:
- `openspec/specs/config-export-skill/spec.md` — added 2 requirements (Skills Registry skip, auto-updated section skip) + 4 filtering rules
- `openspec/specs/config-export-targets/spec.md` — added 4 requirements (shared STRIP preamble, Skills Registry exclusion per target, auto-updated exclusion per target, output equivalence) + 6 rules
- `openspec/changes/archive/2026-03-04-config-export-token-optimization/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Line-count criterion (≥30 lines reduction) was not met — actual net reduction was 9 lines. The primary value delivered was DRY consolidation and two new skip instructions (Skills Registry and `[auto-updated]` blocks), not raw content removal.
- Output-equivalence verification (criteria 5.2–5.4) deferred to next live `/config-export all` invocation; no structural change to transformation logic was made.

---

## [2026-03-04] — config-export-token-optimization (apply)

**Type**: SDD apply
**Agent**: Claude Sonnet 4.6 (sdd-apply)
**Change**: Refactored `skills/config-export/SKILL.md` to consolidate the three per-target STRIP lists into a single `#### Shared STRIP Preamble` sub-section; added skip instructions for the Skills Registry section and `[auto-updated]` blocks in ai-context/ files.

---

## [2026-03-04] — solid-ddd-quality-enforcement (archive)

**Type**: SDD cycle closure
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: Archived change `solid-ddd-quality-enforcement`. Synced delta specs to master specs: appended 3 new requirements + modified 1 requirement in `openspec/specs/sdd-apply/spec.md`; created new master spec `openspec/specs/solid-ddd-skill/spec.md` (no prior master existed). Change folder moved to `openspec/changes/archive/2026-03-04-solid-ddd-quality-enforcement/`. No verify-report.md was created; user confirmed archiving without it.
**Modified files**:
- `openspec/specs/sdd-apply/spec.md` — modified backward-compatibility requirement; added solid-ddd preload, Quality Gate, and tech-skills-as-acceptance-criteria requirements
- `openspec/specs/solid-ddd-skill/spec.md` — created (new master spec for solid-ddd skill)
- `openspec/changes/archive/2026-03-04-solid-ddd-quality-enforcement/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- No verify-report.md — user confirmed proceeding without it; archive rules permit this (non-blocking)

---

## 2026-03-04 — solid-ddd-quality-enforcement

### Summary
Introduced SOLID principles and DDD tactical patterns enforcement into the SDD apply workflow.

### Changes
- **Created** `skills/solid-ddd/SKILL.md` — new reference skill covering all 5 SOLID principles and 7 DDD tactical patterns (Entity, Value Object, Aggregate, Repository, Domain Service, Application Service, Domain Event) with concrete bad/good examples and anti-pattern detection signals
- **Modified** `skills/sdd-apply/SKILL.md`:
  - Added `solid-ddd` as unconditional preload row (first row) in Stack-to-Skill Mapping Table — loaded for all non-documentation code changes
  - Replaced `## Code standards` section with `## Quality Gate` — 7-item checklist (SRP, OCP, DIP, domain integrity, no anemic model, layer separation, naming clarity) that must be evaluated before marking any task [x]
- **Updated** `CLAUDE.md` (project + runtime) — added `### Design Principles` section to Skills Registry

### Motivation
Tech skills (react-19, typescript, etc.) covered framework patterns but no SOLID or DDD principles. The sdd-apply Code Standards section was too vague, resulting in low-quality code with poor separation of concerns, anemic domain models, and mixed responsibilities.

### ADR
`docs/adr/022-solid-ddd-quality-enforcement-pattern.md`

---

## [2026-03-04] — project-claude-organizer-cleanup-after-migrate (verify + archive)

**Type**: SDD cycle closure
**Agent**: Claude Sonnet 4.6 (sdd-verify + sdd-archive)
**What was done**: Verified implementation against specs (PASS WITH WARNINGS — 1 warning: tagline blockquote at line 17 still reads "Never deletes or moves files" despite frontmatter and Rules section being updated). Archived change to `openspec/changes/archive/2026-03-04-project-claude-organizer-cleanup-after-migrate/`. Applied delta spec to master `openspec/specs/project-claude-organizer/spec.md`: modified source-file preservation invariant, appended 3 new requirements (cleanup prompt, deletion confirmation, report subsection).
**Modified files**:
- `openspec/specs/project-claude-organizer/spec.md` — modified 1 requirement, added 3 new requirements
- `openspec/changes/archive/2026-03-04-project-claude-organizer-cleanup-after-migrate/` — archived
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Skill tagline blockquote was identified as a WARNING (stale language not covered by the 12 tasks); does not block archiving
- 12 scenarios in Spec Compliance Matrix all COMPLIANT — zero failing, zero untested, zero partial

---

## [2026-03-04] — project-claude-organizer-cleanup-after-migrate (apply + install)

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-apply all phases)
**What was done**: Implemented all 12 tasks for project-claude-organizer-cleanup-after-migrate. Added 5 cleanup sub-steps to `skills/project-claude-organizer/SKILL.md` — one per eligible migration strategy (5.7.3-cleanup, 5.7.4-cleanup, 5.7.5-cleanup, 5.7.6-cleanup, 5.7.7-cleanup). Each cleanup sub-step checks for successful migration outcomes, presents WILL_DELETE/WILL_PRESERVE lists, prompts user for deletion confirmation, and records outcomes. Updated frontmatter description to reflect conditional deletion behavior. Added Rule 5 (new source-file deletion invariant). Extended Step 6 report with "Deleted from .claude/" subsection and made the source-preservation footer conditional. Updated Step 4 dry-run plan note to reflect new conditional source-file handling. Confirmed ADR 021 exists and is indexed. Deployed via install.sh.
**Modified files**:
- `skills/project-claude-organizer/SKILL.md` — 5 cleanup sub-steps added, Rule 5 added, frontmatter updated, Step 4 note updated, Step 6 report extended
- `openspec/changes/project-claude-organizer-cleanup-after-migrate/tasks.md` — 12/12 tasks marked complete
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- delegate (commands/) and section-distribute (project.md/readme.md) strategies are permanently exempt from cleanup prompts
- Deletion granularity is per-file (not directory removal) — preserves skipped/failed files
- WILL_DELETE classification uses natural-language outcome labels: "copied to", "appended to", "scaffolded to"
- Source-preservation footer in report is conditional: shown only when no deletions occurred

---

## [2026-03-04] — project-claude-organizer-smart-migration (Phase 5 + 6)

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-apply Phase 5+6)
**What was done**: Extended project-claude-organizer skill with Legacy Directory Intelligence layer (Step 3b): 8-pattern recognition table (commands/, docs/, system/, plans/, requirements/, sops/, templates/, project.md/readme.md). Added Step 5.7 per-strategy apply handlers (delegate, section-distribute, copy, append, scaffold, user-choice). Extended Step 4 dry-run plan with Legacy migrations category. Extended Step 6 report with Legacy migrations subsection and updated summary line. commands/ uses advisory-only model that recommends /skill-create for qualifying workflow files. Deployed updated skill via install.sh.
**Modified files**:
- `skills/project-claude-organizer/SKILL.md` — extended with Step 3b Legacy Directory Intelligence, Step 5.7 apply handlers, Step 4 plan extension, Step 6 report extension
- `ai-context/changelog-ai.md` — this entry

---

## [2026-03-04] — project-claude-organizer-memory-layer archived

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: Archived the `project-claude-organizer-memory-layer` SDD cycle. Delta spec for `project-claude-organizer` domain promoted to new master spec at `openspec/specs/project-claude-organizer/spec.md` (no prior master spec existed — delta became full spec). Change folder moved to `openspec/changes/archive/2026-03-04-project-claude-organizer-memory-layer/`. Verification was PASS with no critical issues and no warnings.
**Modified files**:
- `openspec/specs/project-claude-organizer/spec.md` — created (new master spec from delta)
- `openspec/changes/archive/2026-03-04-project-claude-organizer-memory-layer/` — archive folder created
- `openspec/changes/archive/2026-03-04-project-claude-organizer-memory-layer/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- DOCUMENTATION_CANDIDATES classification (Signal 1: filename stem match, Signal 2: heading presence) is now a permanent spec in openspec/specs/project-claude-organizer/
- Copy-only invariant and source preservation are now canonical requirements in the master spec

---

## [2026-03-04] — project-claude-organizer-memory-layer applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-apply Phase 5)
**What was done**: Extended project-claude-organizer skill to detect .md documentation files inside .claude/ that belong in ai-context/ (DOCUMENTATION_CANDIDATES bucket). Added fourth plan category in dry-run display, copy-only apply step (Step 5.4), and Documentation copied to ai-context/ report section. Updated architecture.md artifact table entry for claude-organizer-report.md.
**Modified files**:
- `skills/project-claude-organizer/SKILL.md` — extended (Phases 1–4: classification, dry-run, apply, report)
- `ai-context/architecture.md` — updated claude-organizer-report.md artifact table entry
- `openspec/changes/project-claude-organizer-memory-layer/tasks.md` — all 8 tasks marked complete
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- DOCUMENTATION_CANDIDATES bucket uses closed KNOWN_AI_CONTEXT_TARGETS list plus heading-pattern fallback for broader detection
- Copy-only semantics (source always preserved) enforced as invariant in Step 5.4
- No-op condition guard in Step 4 updated to require DOCUMENTATION_CANDIDATES is also empty

---

## [2026-03-04] — project-claude-folder-organizer archived

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: Archived the `project-claude-folder-organizer` SDD cycle. Delta specs for `folder-organizer-execution` and `folder-organizer-reporting` promoted to master specs in `openspec/specs/`. Change folder moved to `openspec/changes/archive/2026-03-04-project-claude-folder-organizer/`. Verification was PASS WITH WARNINGS (0 critical — 2 warnings: manual integration tests not executed, install.sh execution not confirmed). CLOSURE.md created.
**Modified files**:
- `openspec/specs/folder-organizer-execution/spec.md` — created (new master spec)
- `openspec/specs/folder-organizer-reporting/spec.md` — created (new master spec)
- `openspec/changes/archive/2026-03-04-project-claude-folder-organizer/` — change folder archived here
- `openspec/changes/archive/2026-03-04-project-claude-folder-organizer/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- No master spec conflicts — both delta specs were entirely new domains, copied directly as initial master specs
- Unresolved warnings at archive: integration tests and install.sh confirmation are pending manual steps

## [2026-03-04] — project-claude-folder-organizer applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-ff + sdd-apply)
**What was done**: Added `project-claude-organizer` skill (procedural meta-tool) that reads project `.claude/` folder, compares against canonical SDD structure, and applies additive reorganization after user confirmation. Registered in CLAUDE.md Available Commands, dispatch table, and Skills Registry. Added `claude-organizer-report.md` row to architecture.md artifact table.
**Modified files**:
- `skills/project-claude-organizer/SKILL.md` — created; procedural meta-tool with 6-step process (resolve paths, enumerate observed items, compare against canonical expected set, build and present plan / dry-run, apply plan, write report); includes canonical expected item set inline, Windows path resolution chain, three-category plan format, and report structure
- `CLAUDE.md` — `/project-claude-organizer` row added to Available Commands table, dispatch table, and Skills Registry (System Audits section)
- `ai-context/architecture.md` — `claude-organizer-report.md` artifact row added to communication table (Producer: project-claude-organizer; Consumer: humans / operators)
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Apply step is strictly additive (mkdir + write stub only — no delete, move, or overwrite) — preserves existing user content unconditionally
- Skill reads live `.claude/` folder state, NOT `audit-report.md` — decoupled from audit cycle
- Target is always `PROJECT_ROOT/.claude/` — explicitly never `~/.claude/`
- User confirmation gate is mandatory and MUST NOT be skipped

## [2026-03-03] — enhance-claude-folder-audit archived

**Type**: Enhancement
**Agent**: Claude Sonnet 4.6 (sdd-ff + sdd-apply + sdd-verify + sdd-archive)
**What was done**: Completed full SDD cycle for `enhance-claude-folder-audit`. Extended the `claude-folder-audit` skill's project mode from 5 shallow structural checks to 8 meaningful audit dimensions. Added CLAUDE.md content quality sub-checks (P1 Phase C), SKILL.md frontmatter and section contract sub-checks (P2/P3 Phase C), ai-context/ memory layer check (P6), ai-context/features/ domain knowledge layer check (P7, ADR-015 V2), and .claude/ folder inventory check (P8). Created ADR-016. Change folder archived at `openspec/changes/archive/2026-03-03-enhance-claude-folder-audit/`. Verification: PASS WITH WARNINGS (0 critical, 2 cosmetic warnings).
**Modified files**:
- `skills/claude-folder-audit/SKILL.md` — added P1 Phase C, P2/P3 Phase C sub-checks, Check P6, P7, P8; extended report template and Rules section
- `ai-context/architecture.md` — added "claude-folder-audit: Check Inventory (project mode)" table documenting all 8 checks, Phase C sub-checks, section detection rule, and ADR-016 reference
- `docs/adr/016-enhance-claude-folder-audit-content-quality-convention.md` — created; Phase C sub-check convention
- `docs/adr/README.md` — ADR-016 row added
- `openspec/specs/folder-audit-execution/spec.md` — synced: P1 Phase C, P2/P3 Phase C, P6, P7, P8, modified "checks MUST all execute" (now covers P1–P8)
- `openspec/specs/folder-audit-reporting/spec.md` — synced: P6/P7/P8 section headers, report summary, Findings Summary, Recommended Next Steps, INFO collapsing
- `openspec/changes/claude-folder-audit-deep-inspection/` — removed (empty orphan directory)
**Decisions made**:
- Content quality checks are additive Phase C sub-checks inside existing checks, not new top-level check numbers — avoids identifier breaking changes (ADR-016 convention)
- All new content quality findings capped at MEDIUM; P7 features layer capped at LOW; P7 absence produces INFO only (per ADR-015 non-blocking design intent)
- `name:` field NOT validated in P2/P3 frontmatter sub-checks — only `format:` field validity matters for audit purposes (documented deviation from spec, tasks.md 5.3)
- Section detection: line-prefix matching (`## heading`; `**Triggers**` accepted for Triggers) — consistent with all other skill content scanning in the system
**Notes**: Verify PASS WITH WARNINGS. Warnings were cosmetic only: stale "15/17" tasks.md header (actual count is 15/15) and documented `name:` field spec deviation. Both are non-blocking. User docs review checkbox absent (pre-dates requirement).

## [2026-03-03] — config-export archived

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-ff + sdd-apply + sdd-verify + sdd-archive)
**What was done**: Full SDD cycle for `config-export` completed and archived. Verification PASS (8/8 tasks, all spec scenarios COMPLIANT, no critical issues). New `config-export` skill enables cross-tool portability of Claude configuration: reads CLAUDE.md + ai-context/ and uses LLM in-context transformation to generate tool-specific instruction files for GitHub Copilot, Google Gemini, and Cursor. Two new master specs created.
**Modified files**:
- `skills/config-export/SKILL.md` — new procedural skill (Steps 1–5: source collection, target selection, dry-run preview, file writing, summary; embedded transformation prompts for all 3 targets)
- `CLAUDE.md` — skills registry entry added under "Tools / Platforms"
- `openspec/specs/config-export-skill/spec.md` — new master spec (invocation contract, source collection, dry-run, idempotency)
- `openspec/specs/config-export-targets/spec.md` — new master spec (content requirements, strip/retain rules for all 3 targets)
**Key decisions**: procedural SKILL.md only (no helper scripts); Claude in-context transformation (no external API); canonical tool-expected output paths; dry-run default; `globs: ""` enforced; Claude target deferred to V2.

---

## [2026-03-03] — feature-domain-knowledge-layer archived

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-apply + sdd-verify + sdd-archive)
**What was done**: Full SDD cycle for `feature-domain-knowledge-layer` completed and archived. Verification PASS (19/19 tasks, all success criteria verified, no regressions). Added a Feature Intelligence Layer (`ai-context/features/`) to the SDD system so domain knowledge (business rules, invariants, integration points, decision logs, known gotchas) is captured once per bounded context and automatically preloaded into relevant SDD phases. Four new master specs created. Change folder moved to `openspec/changes/archive/2026-03-03-feature-domain-knowledge-layer/`.
**Modified files**:
- `ai-context/features/_template.md` — created (canonical six-section template for domain knowledge files)
- `ai-context/features/sdd-meta-system.md` — created (worked example feature file for the SDD meta-system bounded context)
- `skills/feature-domain-expert/SKILL.md` — created (new reference-format skill documenting how to author and consume feature files)
- `skills/sdd-propose/SKILL.md` — Step 0 domain context preload inserted (reads matching ai-context/features/<domain>.md, non-blocking)
- `skills/sdd-spec/SKILL.md` — Step 0 domain context preload inserted (identical heuristic, non-blocking)
- `skills/memory-init/SKILL.md` — Step 7 feature discovery block appended (generates ai-context/features/ stubs when directory absent)
- `skills/memory-update/SKILL.md` — Step 3b feature file update path added (persists session-acquired domain knowledge to existing feature files)
- `CLAUDE.md` — memory layer table row added for ai-context/features/*.md; Skill Overlap table updated; feature-domain-expert entry added to Skills Registry
- `ai-context/architecture.md` — artifact communication table row added for ai-context/features/*.md (Producer: memory-init/memory-update; Consumer: sdd-propose/sdd-spec)
- `openspec/specs/feature-domain-knowledge/spec.md` — created (new master spec, promoted from delta)
- `openspec/specs/memory-management/spec.md` — created (new master spec, promoted from delta)
- `openspec/specs/sdd-phase-context-loading/spec.md` — created (new master spec, promoted from delta)
- `openspec/specs/system-documentation/spec.md` — created (new master spec, promoted from delta)
- `openspec/changes/archive/2026-03-03-feature-domain-knowledge-layer/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Storage at `ai-context/features/<domain>.md` — extends the existing memory layer pattern; separates business context from observable behavior (openspec/specs/)
- Domain matching heuristic: filename-stem match (split change slug on hyphens, non-blocking on miss) — zero-config, convention-based
- `feature-domain-expert` placed in global tier (`skills/`) — meta-system authoring guide, not project-specific
- Write ownership strictly `memory-update` (session) + `memory-init` (scaffold); `project-analyze` explicitly does NOT write to `ai-context/features/`
- Template file approach (not a new `format:` value) — avoids cascading changes to project-audit, project-fix, skill-creator; V2 can add format type if audit enforcement is needed
- V1 activates memory side only; D10 `feature_docs:` audit integration deferred to V2
**Notes**: Verify verdict: PASS (0 criticals, 0 warnings, 0 deviations). Pre-existing D3f CLAUDE.md conflict with config-export resolved naturally when config-export was archived first.

---

## [2026-03-03] — tech-skill-auto-activation archived

**Type**: Archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: SDD cycle for `tech-skill-auto-activation` completed and archived. Verification PASS (all 8 criteria checked, 0 critical issues, 0 warnings). New master spec created at `openspec/specs/sdd-apply/spec.md` (4 requirements: Step 0 Technology Skill Preload, Stack-to-Skill Mapping Table, Detection Report, Backward Compatibility). Change folder moved to `openspec/changes/archive/2026-03-03-tech-skill-auto-activation/`.
**Modified files**:
- `openspec/specs/sdd-apply/spec.md` — created (new master spec domain; delta spec promoted verbatim)
- `openspec/changes/archive/2026-03-03-tech-skill-auto-activation/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- N/A (no new decisions at archive step — all decisions recorded in the apply entry below)

---

## [2026-03-03] — skill-compliance-fixes archived

**Type**: Compliance Fix
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: SDD cycle for `skill-compliance-fixes` completed and archived. Verification PASS WITH MINOR NOTE (4/5 criteria verified; criterion 5 — `/project-audit` score comparison — deferred as non-blocking; all structural changes are additive-only, no regression possible). Delta spec promoted to new master spec domain `skill-structure` (4 requirements, 12 scenarios). Change folder moved to `openspec/changes/archive/2026-03-03-skill-compliance-fixes/`.
**Modified files**:
- `skills/smart-commit/SKILL.md` — added `**Triggers**` bold-marker line before `## When to Use` (satisfies claude-folder-audit P2-C and project-audit D4b format contract check)
- `skills/project-analyze/SKILL.md` — added tool-sequence sentence in Step 6 after merge pseudocode: "Use the Read tool to load each target file, compute the merged content in-context, then use the Write tool to write the updated file. Do not use Bash or the Edit tool for this merge."
- `skills/config-export/SKILL.md` — added mechanism statement in Step 3 before Copilot transformation prompt: "These transformation prompts are self-instructions executed by the agent using its own in-context LLM reasoning. No external API call, subprocess, or tool invocation is required to apply them."
- `openspec/specs/skill-structure/spec.md` — created (new master spec domain; delta becomes canonical spec)
- `openspec/changes/archive/2026-03-03-skill-compliance-fixes/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- `**Triggers**` bold-pattern inserted as standalone line (not renaming `## When to Use`) — preserves the existing section heading while satisfying the format contract detector
- Merge tool sequence (Read + Write) codified explicitly — prevents future agents from using Edit or Bash for this merge operation
- Transformation prompt mechanism (in-context self-instruction) made explicit — removes ambiguity about external API calls

---

## [2026-03-03] — tech-skill-auto-activation applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-apply)
**What was done**: Added Step 0 — Technology Skill Preload to `skills/sdd-apply/SKILL.md`. The step reads `ai-context/stack.md` (primary) or `openspec/config.yaml project.stack` (secondary), matches technology keywords against an inline Stack-to-Skill Mapping Table (21 entries), reads matching skill files into implementation context, and produces a detection report. Includes a scope guard (skips for documentation-only changes) and is fully non-blocking. The `## Code standards` section forward-reference updated to point to Step 0. ADR-017 (`docs/adr/017-tech-skill-mapping-table-inline-convention.md`) was pre-created by the sdd-ff agent and confirmed present. Deployed via `install.sh`.
**Modified files**:
- `skills/sdd-apply/SKILL.md` — Step 0 inserted before Step 1; Stack-to-Skill Mapping Table embedded (21 rows); `## Code standards` forward reference updated
- `docs/adr/017-tech-skill-mapping-table-inline-convention.md` — pre-created by sdd-ff; no changes needed
- `docs/adr/README.md` — ADR-017 row pre-added by sdd-ff; no changes needed
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Mapping table embedded inline in `sdd-apply/SKILL.md` (ADR-017) — self-contained, portable, no external config dependency
- `react native` / `expo` matched before `react` in table to prevent shorter keyword absorbing longer compound keyword
- Step 0 carries loaded-skill list forward to Step 2 detection report output line

---

## [2026-03-03] — smart-commit-auto-stage archived

**Type**: Feature
**Agent**: Claude Sonnet 4.6 (sdd-apply + sdd-verify + sdd-archive)
**What was done**: Full SDD cycle for `smart-commit-auto-stage` completed and archived. Verification PASS (0 criticals, 0 warnings, 2 minor non-blocking observations). Step 1 of `skills/smart-commit/SKILL.md` rewritten to detect files from the full working tree via `git status --porcelain`, replacing the old `git diff --cached` guard. Auto-staging added to Step 5 — `git add` is issued per confirmed group immediately before `git commit`; skipped/aborted groups receive no `git add`. SR-10 through SR-13 added to master spec; SR-01 and SR-07 scope-extended. SKILL.md version bumped to 1.1. Change folder moved to `openspec/changes/archive/2026-03-03-smart-commit-auto-stage/`.
**Modified files**:
- `skills/smart-commit/SKILL.md` — Step 1 rewritten (full working-tree scan; three-category `git status --porcelain` parsing; staging-status tag `staged`/`unstaged`/`untracked` per file); Step 1b: staging-status tag travels through grouping; Step 1c: plan display annotates each file with `[staged]`, `[unstaged]`, or `[untracked]` before any `git add`; Step 5: per-group `git add` precondition for confirmed groups; skip/abort branches issue no `git add`; Rules: old "only staged files" rule removed, three replacement rules added; Anti-patterns: updated; YAML description and `metadata.version` bumped to `"1.1"`
- `openspec/specs/smart-commit/spec.md` — SR-10 through SR-13 appended (full working-tree detection, staging-status annotation, selective auto-staging, skip-preserves-state invariant); SR-01 and SR-07 modification blocks appended (scope extended to full working tree)
- `openspec/changes/archive/2026-03-03-smart-commit-auto-stage/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- `git status --porcelain` is the detection command (replaces `git diff --cached --stat` guard) — stable, machine-parseable, single-pass for all three file categories
- Three-value staging-status model (`staged` / `unstaged` / `untracked`) — not a boolean; preserves precise annotation and correct `git add` decisions
- Per-group, just-in-time staging: `git add` fires immediately before each confirmed group's `git commit`, never upfront — ensures rejected groups are never touched
- Clean-tree halt fires only when `git status --porcelain` returns empty output (truly clean working tree)
- Rename entries (`R old -> new`) split on arrow; both paths included in group to prevent silent omissions
**Notes**: Verify verdict: PASS (0 criticals, 0 warnings). Two minor observations documented in verify-report.md: (1) SR-09 prose in master spec not updated to match new wording (documentation gap only); (2) `git diff --cached` retained in Step 1 for content analysis — intentional per design, acknowledged known limitation for unstaged/untracked diffs.

---

## [2026-03-03] — smart-commit-functional-split archived

**Type**: Archive
**Agent**: Claude Sonnet 4.6 (sdd-apply + sdd-verify + sdd-archive)
**What was done**: SDD cycle for `smart-commit-functional-split` completed and archived. Verification PASS WITH WARNINGS (0 criticals, 1 non-blocking warning — design.md has a docs/config-infra priority order transposition vs. spec; implementation and spec are correct). New master spec created at `openspec/specs/smart-commit/spec.md` (SR-01 through SR-09). Change folder moved to `openspec/changes/archive/2026-03-03-smart-commit-functional-split/`.
**Modified files**:
- `skills/smart-commit/SKILL.md` — inserted Step 1b (priority-ordered grouping heuristic: test → config/infra → docs → directory prefix → misc fallback), Step 1c (multi-commit plan generation and pre-commit presentation), extended Step 5 (sequential per-group commit execution with "commit all", "step-by-step", "abort remaining" paths); updated Rules section to 9 rules
- `openspec/specs/smart-commit/spec.md` — created (first master spec for this domain; all 9 SR requirements from the delta become the canonical spec)
- `openspec/changes/archive/2026-03-03-smart-commit-functional-split/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Grouping heuristic placement: new Step 1b between Step 1 and Step 2 — all commit logic stays in one SKILL.md; hook remains context-injection only
- Priority order (spec-authoritative): test(1) → config/infra(2) → docs(3) → directory prefix(4) → misc fallback
- Single-group fast-path: one group → fall through to existing Steps 2–5, zero behavior change
- Full plan shown before first commit fires — user can abort before any side effect
- Error blocking: any ERROR in any group halts the entire plan; WARNINGs are non-blocking
- No external dependencies; only SKILL.md modified
**Notes**: WARNING-01 (design.md priority table transposition) is documentation drift only; no functional defect. The design.md priority table lists `test → docs → config/infra` while spec and SKILL.md correctly use `test → config/infra → docs`. Recommended follow-up: correct design.md in a cleanup pass.

---

## [2026-03-03] — claude-folder-audit-project-mode archived

**Type**: Archive
**Agent**: Claude Sonnet 4.6 (sdd-verify + sdd-archive)
**What was done**: SDD cycle for `claude-folder-audit-project-mode` completed and archived. Verification PASS WITH WARNINGS (0 critical, 1 warning — no automated tests, acknowledged constraint of this repo). Delta specs merged into two existing master specs: `folder-audit-execution` and `folder-audit-reporting`. CLOSURE.md created. Change folder moved to `openspec/changes/archive/2026-03-03-claude-folder-audit-project-mode/`.
**Modified files**:
- `skills/claude-folder-audit/SKILL.md` — extended with `project` execution mode: 3-branch mode detection, Checks P1–P5, mode-specific report path and report format
- `openspec/specs/folder-audit-execution/spec.md` — MODIFIED mode-detection requirement (2→3 branch); ADDED requirements for Checks P1–P5 and the "all checks run despite P1 HIGH" invariant; Rules section extended
- `openspec/specs/folder-audit-reporting/spec.md` — MODIFIED report-path requirement (mode-specific); MODIFIED header-metadata requirement; ADDED P1–P5 section label requirement, project-aware Findings Summary, project-aware Next Steps, git-exclusion footer; Rules section extended
- `openspec/changes/archive/2026-03-03-claude-folder-audit-project-mode/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry
**Decisions made**:
- Mode detection signal: `.claude/` directory at CWD (not `.claude/CLAUDE.md`) — CLAUDE.md absence is a P1 finding, not a mode-detection condition
- Priority order: `global-config` (highest) → `project` → `global` (lowest) — full backwards compatibility preserved
- P1 failure cascades to INFO-skip for P2+P3; P4+P5 still run against disk — "no early abort" invariant maintained
- Report written to `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md` in project mode (never to `~/.claude/`)
- P5 (scope tier overlap) severity permanently capped at LOW
- Substring match priority: `~/.claude/skills/` matched before `.claude/skills/` in P1 Skills Registry parsing
**Notes**: Verify verdict: PASS WITH WARNINGS. The single warning (no automated tests) is an acknowledged repo-level constraint documented in design.md and not introduced by this change. Minor bookkeeping note: tasks.md header said "7/7" but had 8 task items — no functional impact.

---

## [2026-03-03] — claude-folder-audit SDD cycle archived

**Type**: Archive
**Agent**: Claude Sonnet 4.6 (sdd-archive)
**What was done**: SDD cycle for `claude-folder-audit` completed and archived. Delta specs promoted to master specs in `openspec/specs/` (2 new domains: `folder-audit-execution`, `folder-audit-reporting`). CLOSURE.md created. Change folder moved to `openspec/changes/archive/2026-03-03-claude-folder-audit/`.
**Modified files**:
- `openspec/specs/folder-audit-execution/spec.md` — created (new master spec)
- `openspec/specs/folder-audit-reporting/spec.md` — created (new master spec)
- `openspec/changes/archive/2026-03-03-claude-folder-audit/CLOSURE.md` — created
- `ai-context/changelog-ai.md` — this entry + archive note
**Decisions made**:
- N/A (no new decisions at archive step)
**Notes**: Verify report: PASS (37/37 scenarios compliant). 2 non-blocking warnings documented in CLOSURE.md.

---

## [2026-03-03] — claude-folder-audit skill added

**Type**: New skill
**Agent**: Claude Sonnet 4.6
**What was done**: Full SDD cycle (explore → propose → spec + design → tasks → apply → verify) for the `claude-folder-audit` skill. The skill audits the `~/.claude/` runtime folder for installation drift, missing skill deployments, orphaned artifacts, and scope tier compliance. Read-only — produces `~/.claude/claude-folder-audit-report.md`.
**Modified files**:
- `skills/claude-folder-audit/SKILL.md` — created (new skill, format: procedural, 5 audit checks)
- `CLAUDE.md` — added `### System Audits` section to Skills Registry with entry for `claude-folder-audit`
- `skills/project-onboard/SKILL.md` — added non-blocking Check 7 (global-config mode only): drift hint to run `/claude-folder-audit`
- `docs/adr/009-claude-folder-audit-pattern.md` — created (architectural decision: standalone skill vs. D11 extension of project-audit)
- `docs/adr/README.md` — ADR-009 row appended
- `openspec/changes/claude-folder-audit/` — full SDD artifact set (exploration, proposal, prd, specs, design, tasks)
**Decisions made**:
- Standalone skill pattern chosen over extending project-audit with D11 (single-responsibility; independently invocable)
- Report location: `~/.claude/` (runtime artifact, not committed to repo)
- Drift detection uses mtime proxy (no `.installed-at` file yet — noted as future improvement)
- V1 is read-only; auto-fix companion (`claude-folder-fix`) deferred to a future cycle
- Check 4 (orphaned artifacts) generates MEDIUM noise from Claude Code internal files; known limitation — allowlist improvement deferred to V2

---

## [2026-03-02] — skill-scope-global-vs-project archived

**Type**: Archive
**Agent**: Claude Sonnet 4.6
**What was done**: SDD cycle for skill-scope-global-vs-project closed. Verification PASS (14/14 tasks, 17/17 spec scenarios compliant, 0 critical, 0 warnings). Delta specs merged to master specs: skill-placement (new domain created), skill-creation (requirement added), project-fix-behavior (new domain created). Change moved to archive.
**Modified files**:
- `openspec/specs/skill-placement/spec.md` — created (new master spec domain)
- `openspec/specs/skill-creation/spec.md` — appended new requirement: skill-creator defaults to project-local placement inside a project context (4 scenarios + 1 rule)
- `openspec/specs/project-fix-behavior/spec.md` — created (new master spec domain)
- `openspec/changes/archive/2026-03-02-skill-scope-global-vs-project/` — change archived
- `openspec/changes/archive/2026-03-02-skill-scope-global-vs-project/CLOSURE.md` — created
- `ai-context/architecture.md` — two-tier skill placement model added to Key architectural decisions (decision #6)
**Decisions made**:
- Local copy is the canonical default for project-local skill placement — this is now a permanent architectural decision recorded in architecture.md
**Notes**: The SDD cycle covered the full phase DAG: explore → propose → spec+design (parallel) → tasks → apply → verify → archive. No unresolved issues.

---

## [2026-03-02] — skill-scope-global-vs-project

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Modified files**:
- `skills/skill-add/SKILL.md` — Steps 5, 6, 7, 8, Rules: local copy is now the default strategy; Option A (global reference) is an explicit override; origin comment prepended on copy; collaborator notice added for Option A
- `skills/skill-creator/SKILL.md` — Step 1: context-detection block added; placement prompt shows [DEFAULT] marker; /skill-add section: addition strategy subsection removed (delegated to skill-add); format: procedural added to frontmatter
- `skills/project-fix/SKILL.md` — move-to-global handler: two-tier model explanation note added; confirmed as informational-only (no automation)
- `CLAUDE.md` — ## Skills Registry: two-tier comment block added explaining local vs global path distinction and .gitignore guidance
- `settings.json` — CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION: "true" added to env block
- `openspec/changes/skill-scope-global-vs-project/` — full SDD artifact set created (exploration, proposal, prd, specs x3, design, tasks)
- `docs/adr/008-skill-scope-local-copy-default.md` — ADR created
- `docs/adr/README.md` — ADR index updated

**Decisions made**:
- Approach D (hybrid) selected: local copy by default + explicit global override, no new commands
- skill-add Option B (local copy) promoted to default; Option A (global reference) requires explicit "A" at confirm prompt
- skill-creator context-detection uses install.sh presence + basename/config.yaml to identify claude-config repo
- project-fix move-to-global: already informational; two-tier explanation note added for clarity
- CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION enabled explicitly in settings.json

**Notes**: Skills created or added within a project now land in .claude/skills/ (versioned in repo) by default, making them available to all collaborators who clone. The ~/.claude/skills/ global catalog remains the source but is no longer the default placement target for project-specific work.

---

## 2026-03-01 — skill-format-types applied

**Change**: Formalized multiple SKILL.md format types to eliminate false-positive audit findings.
**Problem solved**: 19 of 44 skills (all reference/technology skills) were incorrectly flagged by D4/D9 for missing `## Process` — a section they intentionally do not have.
**Files created**:
- `docs/format-types.md` — canonical contract document for 3 format types
**Files modified**:
- `CLAUDE.md` — Rule 2 updated to reference `docs/format-types.md` and the format system
- `skills/project-audit/SKILL.md` — D4b and D9-3 now parse `format:` frontmatter before structural validation
- `skills/project-fix/SKILL.md` — Phase 5.3 generates format-correct stub sections
- `skills/skill-creator/SKILL.md` — Step 1b added: format-selection before skeleton generation
- `ai-context/architecture.md` — Skill format type system documented
- `ai-context/conventions.md` — SKILL.md structure convention updated with format mapping
**Key decisions**:
- `format:` absent defaults to `procedural` (backwards-compatible — no existing skills break)
- 3 valid values: `procedural` | `reference` | `anti-pattern`
- Migration of 44 existing skills to add `format:` declarations is a separate downstream change
- ADR 007 generated: `docs/adr/007-skill-format-types-convention.md`

---

## 2026-03-01 — project-fix executed

**Score before**: 93/100
**Actions executed**: 0 critical, 0 high, 5 medium (D12 ADR heading normalization)
**Files modified**:
- `docs/adr/001-skills-as-directories.md` — replaced `**Status:**` bold inline with `## Status` heading
- `docs/adr/002-artifacts-over-memory.md` — replaced `**Status:**` bold inline with `## Status` heading
- `docs/adr/003-orchestrator-delegates-everything.md` — replaced `**Status:**` bold inline with `## Status` heading
- `docs/adr/004-install-sh-repo-authoritative.md` — replaced `**Status:**` bold inline with `## Status` heading
- `docs/adr/005-skill-md-entry-point-convention.md` — replaced `**Status:**` bold inline with `## Status` heading
**SDD Readiness**: FULL → FULL
**Notes**: Cosmetic heading normalization only. ADRs 001–005 now use `## Status` heading consistent with ADR 006 and the D12 audit scanner requirement.

---

### 2026-03-01 — audit-improvements archived

**What was done**: SDD cycle for `audit-improvements` completed and archived. Delta specs merged into master specs for `audit-dimensions` and `audit-scoring`. Change folder moved to `openspec/changes/archive/2026-03-01-audit-improvements/`.
**Modified files**:
- `openspec/specs/audit-dimensions/spec.md` — ADDED sections for D2 placeholder detection, D3 hook script + conflict detection, D7 staleness penalty, D1 template path verification, D12 ADR Coverage, D13 Spec Coverage (7 requirements, 34 scenarios)
- `openspec/specs/audit-scoring/spec.md` — ADDED sections for D7 staleness scoring, D12/D13 informational scoring, non-regression requirement; MODIFIED D7 from informational-only to score-impacting
- `openspec/changes/archive/2026-03-01-audit-improvements/CLOSURE.md` — created
**Decisions made**:
- D12 and D13 are permanently registered in master specs as informational-only dimensions (N/A max points)
- D7 staleness behavior change is a permanent spec modification — it now deducts points, not just warns
**Notes**: All 18 tasks completed, 44 compliance scenarios verified. Live integration test on Audiio V3 recommended before next significant project-audit modification.

---

### 2026-03-01 — audit-improvements applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `skills/project-audit/SKILL.md` — extended with 7 new checks across 5 dimensions and 2 new informational dimensions

**Summary of checks added**:
- **D1 (CLAUDE.md Quality)**: Template path verification — reads `Documentation Conventions` section of CLAUDE.md, extracts `docs/templates/*.md` paths, and emits a MEDIUM finding per missing file on disk
- **D2 (Memory Layer)**: Placeholder phrase detection — scans each `ai-context/*.md` file for unfilled placeholder phrases (`[To be filled]`, `TODO`, `[empty]`, `[TBD]`, `[placeholder]`, `[To confirm]`, `[Empty]`); treats files with placeholders as functionally empty (HIGH finding). Also adds version count check: emits MEDIUM finding if `stack.md` contains fewer than 3 versioned technology lines
- **D3 (SDD Compliance)**: Hook script existence verification (sub-check 3e) — extracts all hook script paths from `settings.json`/`settings.local.json` and emits HIGH finding per missing script on disk. Active changes file conflict detection (sub-check 3f) — extracts File Change Matrix from each active `design.md`, computes path intersection across changes, emits MEDIUM finding per overlapping file path
- **D7 (Architecture)**: Staleness score penalty tiers — if `analysis-report.md` is 31–60 days old, deducts 1 point from D7 score (floor 0); if older than 60 days, deducts 2 points (floor 0); no penalty when file is absent or 30 days old or fresher
- **D12 (ADR Coverage)** — new informational dimension: checks `docs/adr/README.md` existence, scans each `docs/adr/NNN-*.md` for a `## Status` section; HIGH finding for missing README, MEDIUM per ADR missing Status; informational only — no score impact
- **D13 (Spec Coverage)** — new informational dimension: activated when `openspec/specs/` is non-empty; checks each domain directory for a `spec.md`, scans referenced paths for existence; MEDIUM per missing `spec.md`, INFO for stale path references; informational only — no score impact

**Decisions made**:
- All new checks are conditional — projects without the relevant artifacts receive N/A or a skip message, never a penalty
- D7 staleness penalty stacks with the drift penalty; combined floor is 0
- D12 and D13 are informational (N/A in Max Points column); HIGH/MEDIUM findings ARE placed in `required_actions` and are actionable by `/project-fix`, but do not reduce the base 100-point score
- D3 conflict detection normalizes paths with `lowercase + strip leading ./` before computing intersection

**Change**: audit-improvements | SDD cycle complete

---

### 2026-03-01 — sdd-cycle-prd-adr-integration archived

**What was done**: Integrated PRD and ADR as optional auto-generated artifacts into the SDD cycle. `sdd-propose` now auto-creates a `prd.md` shell (idempotent, skips if template absent or file already exists). `sdd-design` now auto-creates an ADR file in `docs/adr/` when a keyword-significant architectural decision is detected in the Technical Decisions table (non-blocking, skips if template or README absent). Both `openspec/config.yaml` and `CLAUDE.md` were updated to document these as optional artifacts.
**Modified files**:
- `skills/sdd-propose/SKILL.md` — added Step 5: PRD shell auto-creation (idempotent, non-blocking)
- `skills/sdd-design/SKILL.md` — added Step 5: ADR auto-creation (keyword heuristic, filesystem numbering, non-blocking)
- `openspec/config.yaml` — added `optional_artifacts` section listing prd.md and docs/adr/NNN-*.md with producing skill annotations
- `CLAUDE.md` — updated SDD Artifact Storage section: prd.md (optional) in change tree; docs/adr/NNN-*.md (optional, sdd-design) in overall tree
- `ai-context/architecture.md` — added two new artifact table rows for prd.md and docs/adr/NNN-*.md auto-generation
**Decisions made**:
- PRD is idempotent and non-blocking: existing `prd.md` is never overwritten; missing template skips silently with a warning
- ADR uses keyword heuristic (cross-cutting concern keywords, patterns absent from `ai-context/architecture.md`) — intentionally fuzzy; future cycles can formalize if needed
- ADR numbering uses filesystem count of `docs/adr/` files to avoid collisions — no global counter state needed
- Both steps return `status: ok` (or `status: warning`) on any failure path — never `status: blocked` or `status: failed`
- Step 5 heading added to `sdd-design` for structural symmetry with `sdd-propose` — accepted deviation, improves readability
**Notes**: Change-name delineation: `proposal-prd-and-adr-system` (previous cycle, 2026-03-01) created the templates and ADR index. This cycle (`sdd-cycle-prd-adr-integration`) wired those templates into the live SDD skill behavior.

---

## 2026-03-01 — proposal-prd-and-adr-system applied

**Type**: Feature / Documentation
**Agent**: Claude Sonnet 4.6
**Files created**:
- `docs/templates/prd-template.md` — PRD template with all 6 required sections (Problem Statement, Target Users, User Stories with MoSCoW tiers, Non-Functional Requirements, Acceptance Criteria, Notes); each section includes placeholder instructions
- `docs/templates/adr-template.md` — ADR template following Nygard format with 4 required sections (Title, Status, Context, Decision, Consequences); includes all valid status values and placeholder instructions
- `docs/adr/README.md` — ADR index with naming convention, numbering scheme, status vocabulary, lifecycle guidance, and table of all 5 ADRs
- `docs/adr/001-skills-as-directories.md` — Retroactive ADR: skills are stored as directories with SKILL.md entry points
- `docs/adr/002-artifacts-over-memory.md` — Retroactive ADR: all inter-skill state passed via named file artifacts, not conversation context
- `docs/adr/003-orchestrator-delegates-everything.md` — Retroactive ADR: CLAUDE.md orchestrator never executes SDD phase work inline; always delegates via Task tool
- `docs/adr/004-install-sh-repo-authoritative.md` — Retroactive ADR: install.sh is the sole authoritative deploy direction (repo → ~/.claude/); sync.sh is memory-only reverse
- `docs/adr/005-skill-md-entry-point-convention.md` — Retroactive ADR: SKILL.md is the mandatory, uniquely-named entry point for every skill directory
**Files modified**:
- `ai-context/conventions.md` — appended "PRD Convention" section explaining PRD is optional for technical changes, recommended for product-level changes, precedes proposal.md, template at docs/templates/prd-template.md
- `CLAUDE.md` — added "Documentation Conventions" subsection in Architecture section referencing docs/adr/README.md and docs/templates/prd-template.md
- `docs/architecture-definition-report.md` — prepended HTML disambiguation comment clarifying "ADR" = Architecture Definition Report, not Architecture Decision Record

**Decisions made**:
- All 5 ADRs use `Accepted (retroactive)` status — decisions predate the ADR system
- ADR content derived exclusively from ai-context/architecture.md — no new architectural claims invented
- PRD is positioned as optional upstream artifact, not a replacement for proposal.md
- docs/templates/ and docs/adr/ directories created as part of this change
- docs/architecture-definition-report.md disambiguation uses HTML comment (invisible in rendered Markdown)

**Change**: proposal-prd-and-adr-system | SDD cycle complete

---

## 2026-02-28 — integrate-memory-into-sdd-cycle archived

**Type**: Feature
**Agent**: Claude Opus 4.6
**Files modified**:
- `skills/sdd-archive/SKILL.md` — Replaced Step 6 (manual "Suggest updating memory") with auto-update: reads `~/.claude/skills/memory-update/SKILL.md` and executes inline with non-blocking error handling; updated Output JSON: `next_recommended` changed from `["memory-update"]` to `[]`, summary includes `Memory: [updated|failed|skipped]`
- `skills/sdd-ff/SKILL.md` — Added informational note in Step 5 summary: archive will auto-update ai-context/
- `skills/sdd-new/SKILL.md` — Added "(auto-updates ai-context/ memory)" to archive entry in Step 6 remaining phases
- `ai-context/architecture.md` — Added memory-update artifact row to communication table

**Specs created**:
- `openspec/specs/sdd-archive-execution/spec.md` — 5 requirements, 11 scenarios covering auto memory-update, non-blocking failure, output format, sdd-ff/sdd-new notes

**Decisions made**:
- Inline execution (not Task tool delegation) — follows convention that only sdd-ff/sdd-new use Task tool
- Step 6 replacement (not Step 7 addition) — keeps step count at 6
- Non-blocking: archive success is always independent of memory-update outcome
- memory-update reads session context naturally — no structured parameter interface needed

**Change**: integrate-memory-into-sdd-cycle | SDD cycle complete

---

## 2026-02-28 — project-fix executed (colon separators + stale references)

**Type**: Config
**Agent**: Claude Opus 4.6
**Score before**: 95/100
**Actions executed**: 0 critical, 0 high, 6 medium, 6 low
**Files modified**:
- `ai-context/stack.md` — Replaced `memory-manager/` with `memory-init/` + `memory-update/` in directory tree; updated Meta-tools count from 6 to 10 with correct skill list
- `ai-context/architecture.md` — Fixed `/sdd:ff` and `/sdd:apply` to `/sdd-ff` and `/sdd-apply` in SDD meta-cycle; replaced `memory-manager` with `memory-init / memory-update` as ai-context producer; updated drift note
- `ai-context/conventions.md` — Fixed `/sdd:ff` and `/sdd:apply` to `/sdd-ff` and `/sdd-apply` in SDD workflow
- `ai-context/known-issues.md` — Fixed `/project:audit` to `/project-audit` and `/skill:test` to `/skill-test`
- `CLAUDE.md` — Changed "9 dimensions" to "10 dimensions" in /project-audit description
- `README.md` — Replaced all colon separators with hyphens (30+ occurrences); replaced `memory-manager` with `memory-init` + `memory-update`; changed "9 dimensions" to "10 dimensions"; removed stale `openclaw-assistant` entry
- `skills/sdd-archive/SKILL.md` — Fixed `/sdd:verify` to `/sdd-verify`, `/memory:update` to `/memory-update`, `memory:update` to `memory-update`
- `skills/project-audit/SKILL.md` — Fixed 7 colon separator occurrences (`/project:fix`, `/project:audit`, `/sdd:new`, `/sdd:ff`, `/sdd:*`, `/skill:add`)
- `skills/project-fix/SKILL.md` — Fixed `/sdd:*` to `/sdd-*` in 2 locations
- `skills/sdd-explore/SKILL.md` — Fixed `/sdd:explore` to `/sdd-explore`

**SDD Readiness**: FULL → FULL
**Notes**: Comprehensive cleanup of legacy colon separator notation and stale memory-manager references after the skill split into memory-init + memory-update.

---

## 2026-02-28 — project-fix executed

**Type**: Config
**Agent**: Claude Opus 4.6
**Score before**: 97/100
**Actions executed**: 0 critical, 0 high, 1 medium
**Files modified**:
- `ai-context/stack.md` — Removed stale `openclaw-assistant` reference from Misc category (skill directory does not exist)

**SDD Readiness**: FULL → FULL
**Notes**: Minimal fix session — only one broken cross-reference to correct.

---

## 2026-02-27 — improve-project-analysis applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files created**:
- `skills/project-analyze/SKILL.md` — new standalone framework-agnostic analysis skill (`/project-analyze`); observes and describes only — never scores, never produces FIX_MANIFEST entries; produces `analysis-report.md` at project root and updates `ai-context/` `[auto-updated]` sections; 6-step process: config read, stack detection (manifest-first + extension fallback), structure mapping, convention sampling, architecture drift detection, write outputs
**Files modified**:
- `skills/project-audit/SKILL.md` — rewrote Dimension 7 (Architecture Compliance): D7 is now a consumer of `analysis-report.md` (produced by `/project-analyze`); framework-agnostic; scoring table: absent=0/5 CRITICAL, no architecture.md=2/5 HIGH, drift=none→5/5, minor→3/5, significant→0/5; staleness warning when `Last analyzed:` > 7 days; D7 violations go in `violations[]` only (not `required_actions`); Phase A extension: added `ANALYSIS_REPORT_EXISTS` and `ANALYSIS_REPORT_DATE` variables to the Phase A Bash script; D7 report output template updated
- `CLAUDE.md` — `/project-analyze` registered in: Available Commands table (Meta-tools section), execution routing table (`~/.claude/skills/project-analyze/SKILL.md`), Skills Registry (Meta-tool Skills subsection)
- `ai-context/architecture.md` — new row added to the "Communication between skills via artifacts" table: `analysis-report.md` (Producer: `project-analyze`, Consumer: `project-audit (D7), user`, Location: project root)
- `openspec/config.yaml` — appended optional `analysis` key comment block documenting `analysis.max_sample_files` (default: 20), `analysis.exclude_dirs` (optional list), `analysis.analysis_targets` (optional explicit override list)

**Decisions made**:
- `project-analyze` is a pure observation skill — no scoring, no FIX_MANIFEST, no severity labels
- `project-audit` D7 does NOT auto-invoke `project-analyze` — treats `analysis-report.md` as external input
- If `analysis-report.md` absent, D7 scores 0/5 with CRITICAL message instructing user to run `/project-analyze` first
- `[auto-updated]` marker strategy uses HTML comment syntax invisible in rendered Markdown — no collision with existing `ai-context/` content
- `project-analyze` NEVER creates `ai-context/` directory — if absent, writes only `analysis-report.md` and instructs user to run `/memory-init`
- Maximum 3 Bash calls per `project-analyze` execution: Steps 1+2 share 1 call, Step 3 = 1 call, Step 4 = 1 call

**Change**: improve-project-analysis | SDD cycle complete

---

## 2026-02-26 — feature-docs-dimension applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `skills/project-audit/SKILL.md` — added Dimension 10 (Feature Docs Coverage): Phase A discovery extension (`FEATURE_DOCS_CONFIG_EXISTS`), config-driven detection from `openspec/config.yaml`, heuristic fallback with three source patterns and exclusion list, four checks (D10-a through D10-d), D10 row in score summary table, D10 section in report template, D10 row in Detailed Scoring table; D10 findings are informational only and do NOT affect the score or appear in FIX_MANIFEST
- `openspec/config.yaml` — appended optional `feature_docs:` top-level section as a fully commented-out schema reference documenting `convention`, `paths`, and `feature_detection` sub-keys with all accepted values; the actual heuristic detection remains operative for this project

**Decisions made**:
- D10 is informational-only (N/A scoring) — no score deduction, no auto-fix by /project-fix
- D10 findings are explicitly excluded from `required_actions` and `skill_quality_actions` in FIX_MANIFEST
- Heuristic detection sources: `src/` subdirs, `docs/features/` dirs, local `.claude/skills/` dirs
- Config-driven detection takes precedence over heuristic when `feature_docs:` key is present in `openspec/config.yaml`
- `feature_docs:` section in `openspec/config.yaml` is commented out for claude-config itself (this repo has no feature subdirectories to audit in that sense)

**Motivation**: Users with feature-rich projects need visibility into which features have supporting documentation. D10 provides a non-blocking coverage audit that surfaced documentation gaps without disrupting the existing score contract.

---

## 2026-02-26 — user-docs-and-onboard-skill applied

**Type**: Feature / Documentation
**Agent**: Claude Sonnet 4.6
**Files created**:
- `ai-context/scenarios.md` — 6-case onboarding guide with symptoms, commands, expected outcomes, failure modes
- `ai-context/quick-reference.md` — compact single-page reference: situation table, SDD flow, command glossary, /sdd-ff vs /sdd-new
- `skills/project-onboard/SKILL.md` — automated project state diagnostic skill (/project-onboard)
**Files modified**:
- `skills/project-audit/SKILL.md` — D2: added freshness sub-checks for scenarios.md and quick-reference.md (LOW severity, no score deduction)
- `skills/sdd-archive/SKILL.md` — Step 1: surfaces user-docs review checkbox; CLOSURE.md template: User Docs Reviewed field; Step 5b: verify-report template checkbox
- `skills/project-update/SKILL.md` — Step 1b: stale-doc scan for all 3 user docs; Step 3: explicit confirmation before regeneration
- `CLAUDE.md` — /project-onboard in Available Commands, routing table, and Skills Registry
- `ai-context/architecture.md` — 3 new artifact table rows

**Decisions made**:
- project-onboard uses strict priority-order waterfall (not heuristic scoring) — deterministic, one case per run
- Check 4 (local skills) is non-blocking — project can be Case 6 and have local skill issues simultaneously
- sdd-archive user-docs checkbox is non-blocking — surfaced, not enforced
- project-update stale-doc regeneration requires explicit user confirmation — never automatic

**Motivation**: Users with multiple external projects need intuitive documentation to understand the correct SDD onboarding flow and know which commands to run in each project state.

---

## 2026-02-26 — enhance-project-audit-skill-review applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `skills/project-audit/SKILL.md` — appended Dimension 9 (Project Skills Quality): 5 sub-checks (skip, duplicate detection, structural completeness, language compliance, stack relevance); D9 section in report template; `skill_quality_actions` in FIX_MANIFEST schema; D9 rows in score and Detailed Scoring tables
- `skills/project-fix/SKILL.md` — appended Phase 5 (D9 Corrections): 4 action handlers (`delete_duplicate`, `add_missing_section`, `flag_irrelevant`, `flag_language`) + `move-to-global` informational message; `skill_quality_actions` added to Step 1 parsing
- `ai-context/architecture.md` — added `onboarding.md` row to artifacts communication table
**Files created**:
- `ai-context/onboarding.md` — canonical 4-step onboarding sequence for external projects

**Decisions made**:
- D9 scoring is N/A (no deduction) in iteration 1 — purely informational
- `skill_quality_actions` is a new top-level FIX_MANIFEST key to avoid collision with `required_actions` severity buckets
- `flag_language` in Phase 5 reports only — does NOT auto-modify files
- `move-to-global` has no automated handler — emits explicit manual promotion workflow
- `onboarding.md` placed in `ai-context/` (not `docs/`, not as a skill) — read-only documentation, not a command

**Motivation**: User has multiple external projects to migrate to SDD. Needed: D9 skill audit, Phase 5 fix handler, and documented onboarding workflow.

---

## 2026-02-26 — add-orchestrator-skills applied

**Type**: Feature
**Agent**: Claude Sonnet 4.6
**Files created**:
- `skills/sdd-ff/SKILL.md` — orchestrator: fast-forward SDD cycle (propose → parallel spec+design → tasks)
- `skills/sdd-new/SKILL.md` — orchestrator: full SDD cycle with optional explore + confirmation gates
- `skills/sdd-status/SKILL.md` — status reader: scans openspec/changes/ and renders artifact presence table
- `skills/skill-add/SKILL.md` — skill installer: adds global skills to project CLAUDE.md registry
**Files modified**:
- `CLAUDE.md` — routing table (4 new rows: sdd-ff, sdd-new, sdd-status, skill-add updated); Skills Registry (new SDD Orchestrators subsection + skill-add entry)
- `ai-context/conventions.md` — added Orchestrator skills subsection with Task tool delegation guidance
**Archived**: `openspec/changes/archive/2026-02-26-add-orchestrator-skills/`

**Decisions made**:
- Orchestrator skills (sdd-ff, sdd-new) are self-contained SKILL.md files that use Task tool directly — they do not rely on CLAUDE.md being read at runtime
- skill-add is a separate skill from skill-creator (add existing vs create new)
- sdd-ff has no user gates (fast-forward runs automatically); sdd-new has two confirmation gates (after propose, after spec+design)
- sdd-status is filesystem-only — no git inspection

**Motivation**: `/sdd-ff` returned "Unknown skill: sdd-ff" because CLAUDE.md documentation is insufficient for Claude Code CLI to register commands. Actual SKILL.md files are required.

---

## 2026-02-26 — sync-sh-redesign applied

**Type**: Refactor / Architecture clarity
**Agent**: Claude Sonnet 4.6
**Files modified**:
- `sync.sh` — rewritten: memory/ only. Removed cp for CLAUDE.md/settings.json and sync_dir for skills/hooks/openspec/ai-context. Added missing-dir guard.
- `install.sh` — header comment added documenting direction and scope. No logic changes.
- `ai-context/architecture.md` — per-directory direction diagram + decision #5 rewritten.
- `ai-context/conventions.md` — Workflow A/B model replacing old "sync before commit" instruction.
- `CLAUDE.md` — Tech Stack, Sync discipline, SDD meta-cycle line corrected.

**Decisions made**:
- `sync.sh` scope reduced to `memory/` only — the single directory that Claude Code writes automatically during any session.
- All other dirs (skills, CLAUDE.md, hooks, openspec, ai-context) are repo-authoritative: edit in repo → install.sh → commit.
- Names kept (sync.sh / install.sh) to avoid breaking documentation references.

---

## 2026-02-24 — project-fix round 3

**Type**: Config / Compliance fix
**Agent**: Claude Sonnet 4.6
**Score before**: 97/100
**Actions executed**: 0 critical, 0 high, 3 medium, 1 low
**Files modified**:
- `skills/skill-creator/SKILL.md` — full translation from Spanish to English + command notation fix
- `skills/jira-task/SKILL.md` — translated Spanish headings, rules, template bodies
- `skills/jira-epic/SKILL.md` — translated Spanish headings, template bodies, decomposition section
- `ai-context/stack.md` — Meta-tools count corrected from 5 to 6 (added skill-creator)
**SDD Readiness**: FULL → FULL

---

## 2026-02-24 — project-fix round 2

**Type**: Config / Compliance fix
**Agent**: Claude Sonnet 4.6
**Score before**: 93/100
**Actions executed**: 0 critical, 4 high, 1 medium, 1 low
**Files modified**:
- `skills/memory-manager/SKILL.md` — translated all Spanish to English, fixed command notation
- `skills/project-fix/SKILL.md` — translated all Spanish to English, fixed command notation
- `skills/project-setup/SKILL.md` — translated all Spanish to English, fixed command notation
- `skills/project-update/SKILL.md` — translated all Spanish to English, fixed command notation
- `openspec/config.yaml` — added tasks.md to required_artifacts_per_change
- `ai-context/stack.md` — updated Misc skill count from 3+ to 4, added image-ocr
**SDD Readiness**: FULL → FULL

---

## 2026-02-24 — project-fix executed

**Type**: Config / Compliance fix
**Agent**: Claude Sonnet 4.6
**Score before**: 88/100
**Actions executed**: 1 critical, 2 high, 2 medium
**Files modified**:
- `skills/project-audit/SKILL.md` — translated all Spanish headings to English, fixed command notation
- `skills/sdd-{explore,propose,spec,design,tasks,apply,verify,archive}/SKILL.md` — translated JSON output field names (resumen→summary, artefactos→artifacts, riesgos→risks, desviaciones→deviations)
- `CLAUDE.md` — added image-ocr to Skills Registry
**Files created**:
- `skills/image-ocr/SKILL.md` — synced from ~/.claude/skills/image-ocr/
- `openspec/changes/archive/2026-02-24-add-global-config-exception/` — archived completed change
- `openspec/changes/archive/*/tasks.md` (3 files) — retroactive stubs
**SDD Readiness**: FULL → FULL
**Decisions taken**:
- Command notation standardized: `/project:fix` → `/project-fix` in project-audit/SKILL.md
- `"desviaciones"` also translated in sdd-apply as it was a Spanish JSON key
- Fixes applied to ~/.claude/ directly (sync.sh captures that direction)

---

## 2026-02-23 — Bootstrap SDD infrastructure on claude-config

**Type:** Configuration / Meta
**Agent:** Claude Sonnet 4.6
**SDD cycle:** Applied retroactively (changes were made without prior SDD cycle — documented here as first archive entry)

**What changed:**
- `openspec/config.yaml` — Created: SDD configuration for this repo with English-only rules
- `ai-context/stack.md` — Created: project identity, file types, skill catalog inventory
- `ai-context/architecture.md` — Created: two-layer architecture, skill structure, artifact communication map
- `ai-context/conventions.md` — Created: naming, SKILL.md structure, git workflow, sync rules
- `ai-context/known-issues.md` — Created: rsync on Windows, install.sh directionality, GITHUB_TOKEN dependency
- `ai-context/changelog-ai.md` — Created: this file

**Decisions made:**
- `ai-context/` placed at repo root (not `docs/ai-context/`) since this is not a code project
- `openspec/config.yaml` uses English-only rules — this repo enforces the English standard
- Known issues documented immediately to capture technical debt visible at bootstrap time

---

## 2026-02-23 — Overhaul project-audit, create project-fix

**Type:** Feature
**Agent:** Claude Sonnet 4.6
**Commit:** `680ce20`
**SDD cycle:** NOT applied (retroactive — this was the change that motivated applying SDD to this repo)

**What changed:**
- `skills/project-audit/SKILL.md` — Full rewrite: 4 dimensions → 7 dimensions, added FIX_MANIFEST output, structured audit-report.md artifact
- `skills/project-fix/SKILL.md` — New skill: reads audit-report.md as spec, implements corrections phase by phase
- `CLAUDE.md` — Registered `/project:fix` in meta-tools table and skill routing table

**Why this change was made:**
Audit of the Audiio V3 project revealed that project-audit only checked file existence, not content quality or SDD readiness. The new audit generates a machine-readable report consumed by project-fix, implementing the audit→fix flow as a self-contained SDD meta-cycle.

**Technical debt created:**
- project-audit does not handle projects without package.json (affects claude-config itself)
- Both skills were written without prior SDD artifacts — violates the standard this repo enforces

---

## 2026-02-23 — Initial commit: SDD architecture setup

**Type:** Initial Setup
**Commit:** `4c62733`
**Agent:** Claude Sonnet 4.6 (prior session)

**What changed:**
- Initial CLAUDE.md with SDD orchestrator pattern
- Full SDD phase skill catalog (8 phases)
- Meta-tool skills: project-setup, project-audit, project-update
- Technology skill catalog (~25 skills)
- install.sh + sync.sh scripts
- settings.json with MCP server configuration
