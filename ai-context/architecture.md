# Architecture — agent-config

> Last updated: 2026-03-22

## System role

`agent-config` is the global brain of Claude Code. It defines:
1. **How Claude orchestrates** — the SDD workflow, delegation patterns, phase DAG
2. **What Claude knows** — skill catalog covering SDD phases, meta-tools, tech stacks
3. **How projects are managed** — setup, audit, fix, update lifecycle

## Two-layer architecture

```
agent-config (repo)          ~/.claude/ (runtime)
      │                              │
      ├── CLAUDE.md    ──install──►  ├── CLAUDE.md       ← Claude reads at session start
      ├── skills/      ──install──►  ├── skills/          ← Claude reads on demand
      ├── settings.json ─install──►  ├── settings.json    ← Claude Code config
      ├── hooks/       ──install──►  ├── hooks/           ← Event hooks
      ├── openspec/    ──install──►  ├── openspec/        ← SDD artifacts
      ├── ai-context/  ──install──►  ├── ai-context/      ← Project memory
      └── memory/      ──install──►  └── memory/          ← User memory snapshot
                            ◄──sync────  (memory/ only — Claude writes here during sessions)
```

- `install.sh` : repo/ → ~/.claude/  (all directories — the deploy operation)
- `sync.sh`    : ~/.claude/memory/ → repo/memory/  (memory only — periodic capture)

## Skill architecture

Every skill is a directory with a `SKILL.md` entry point:

```
skills/
└── skill-name/
    └── SKILL.md       # Instructions Claude reads and executes
```

A SKILL.md must contain (authoritative contract: `docs/format-types.md`):
- **Trigger definition** — when to use this skill
- **Format-specific main section** — depends on the `format:` frontmatter field:
  - `procedural` (default): `## Process` — step-by-step instructions
  - `reference`: `## Patterns` or `## Examples` — technology patterns and code examples
  - `anti-pattern`: `## Anti-patterns` — catalog of bad practices with fixes
- **Rules** — constraints and invariants

### Skill format type system

Every `SKILL.md` declares its structural type via the `format:` YAML frontmatter field:

```yaml
---
name: react-19
description: >
  React 19 patterns with React Compiler...
format: reference   # valid values: procedural | reference | anti-pattern
---
```

| `format:` value | Required main section | Used for |
|-----------------|----------------------|---------|
| `procedural` (default when absent) | `## Process` | SDD phases, meta-tools, orchestrators |
| `reference` | `## Patterns` or `## Examples` | Technology and library skills |
| `anti-pattern` | `## Anti-patterns` | Anti-pattern catalog skills |

- Absent `format:` defaults to `procedural` (backwards-compatible).
- Unrecognized values default to `procedural` with an INFO audit finding.
- `project-audit` D4b and D9-3 validate structural compliance per declared format.
- `project-fix` Phase 5.3 generates format-correct stub sections.
- `skill-creator` Step 1b prompts for format and generates the matching skeleton.

## SDD meta-cycle (applied to this repo itself)

Any change to a skill or the global CLAUDE.md must go through:

```
/sdd-explore <change-name>  →  /sdd-propose <change-name>  →  review  →  /sdd-apply  →  install.sh + git commit
```

This is the minimum cycle. For breaking changes to core skills (orchestrator, SDD phases), full cycle is required.

## Communication between skills via artifacts

Skills that need to pass state to each other use **file artifacts**:

| Artifact | Producer | Consumer | Location |
|----------|---------|---------|----------|
| `audit-report.md` | project-audit | project-fix | `.claude/audit-report.md` in project |
| `openspec/config.yaml` | project-setup / project-fix | all SDD phases | `openspec/` in project — also contains the optional `feature_docs:` top-level key (config-driven detection source for D10); when absent, project-audit falls back to heuristic detection |
| `openspec/changes/*/proposal.md` | sdd-propose | sdd-spec, sdd-design | `openspec/changes/<name>/` |
| `openspec/changes/*/tasks.md` | sdd-tasks | sdd-apply | `openspec/changes/<name>/` |
| `ai-context/*.md` | memory-manage / project-fix | all skills | `ai-context/` in project |
| `ai-context/onboarding.md` | (human / project-fix) | humans / new project sessions | `ai-context/` in project — canonical external project onboarding sequence |
| `ai-context/scenarios.md` | (human / project-onboard) | humans / new project sessions | `ai-context/` in project — 6-case onboarding guide, case-based entry point for users at different project states |
| `ai-context/quick-reference.md` | (human) | humans | `ai-context/` in project — single-page SDD quick reference: situation table, command glossary, flow diagram |
| `skills/project-onboard/SKILL.md` | SDD cycle | Claude at session start / on demand | `~/.claude/skills/project-onboard/` — automated project state diagnostic, triggered by `/project-onboard` |
| `~/.claude/skills/memory-manage/SKILL.md` | (read by sdd-archive Step 6) | sdd-archive sub-agent | `~/.claude/skills/memory-manage/` — auto-invoked inline by sdd-archive after successful archive; non-blocking (archive success is independent of memory-manage outcome) |
| `docs/templates/prd-template.md` | proposal-prd-and-adr-system SDD cycle | humans / Claude sessions starting product-level changes | `docs/templates/` — optional PRD template; feeds into `proposal.md`, not a replacement |
| `docs/templates/adr-template.md` | proposal-prd-and-adr-system SDD cycle | humans adding new ADRs | `docs/templates/` — Nygard format ADR template |
| `docs/adr/README.md` + `docs/adr/NNN-*.md` | proposal-prd-and-adr-system SDD cycle | humans / Claude sessions making architectural decisions | `docs/adr/` — ADR index + individual decision records; must be updated when new ADRs are added |
| `openspec/changes/*/prd.md` | sdd-propose (Step 5, optional) | humans / product-level change authors | `openspec/changes/<name>/` — auto-created shell when `docs/templates/prd-template.md` exists and no `prd.md` is present; idempotent (never overwrites existing file); non-blocking if template absent |
| `docs/adr/NNN-<slug>.md` | sdd-design (Step 5, optional) | humans / architecture reviewers | `docs/adr/` — auto-created when Technical Decisions table in `design.md` contains a keyword-significant architectural decision; numbering via filesystem count; non-blocking if template or README.md absent |
| `docs/adr/` (D12 — ADR Coverage) | N/A (human-maintained) | project-audit (D12) | `docs/adr/` — informational audit dimension; no score impact. Checks `README.md` existence (HIGH finding if absent) and each `docs/adr/NNN-*.md` for a `## Status` section (MEDIUM finding per ADR missing Status). Activated only when CLAUDE.md references `docs/adr/`; skipped with "N/A" when no reference found. Findings placed in `required_actions` and are actionable by `/project-fix`. |
| `openspec/specs/` (D13 — Spec Coverage) | sdd-spec | project-audit (D13) | `openspec/specs/` — informational audit dimension; no score impact. Activated when `openspec/specs/` exists and is non-empty. Checks each domain directory for a `spec.md` (MEDIUM finding per missing file) and scans referenced paths in each spec for existence (INFO finding per stale path, added to `violations[]` only). Skipped with "N/A" when directory is absent or empty. Findings placed in `required_actions` and are actionable by `/project-fix`. |
| `ai-context/features/*.md` | `memory-manage` (scaffold on first run, session updates) / human authors | `sdd-propose` (Step 0, optional), `sdd-spec` (Step 0, optional) | `ai-context/features/` in project | `_template.md` is never loaded by SDD phases |

## Key architectural decisions

29. **Slim orchestrator context — inline-vs-skill boundary for CLAUDE.md** (added 2026-03-22, change: 2026-03-22-slim-orchestrator-context, ADR-041) — The global CLAUDE.md was refactored to reduce always-loaded context from ~91k characters to ~25k characters. Sections removed from CLAUDE.md: `## Teaching Principles`, `## Communication Persona`, `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, `## How I Execute Commands`. Presentation-layer content (session banner, communication persona, teaching principles, new-user detection) was extracted to a new skill `skills/orchestrator-persona/SKILL.md` loaded on demand on the first free-form response per session. Skills Registry condensed to path-only format; Available Commands condensed to single-line format. A budget governance comment block was added to CLAUDE.md with three enforced budgets: global CLAUDE.md ≤ 20,000 chars, project CLAUDE.md ≤ 5,000 chars, new orchestrator skills ≤ 8,000 chars. Classification-critical content (Decision Table, Scope Estimation, Ambiguity Heuristics, Unbreakable Rules, Response Signal format) remains inline in CLAUDE.md. Master spec extended at `openspec/specs/orchestrator-behavior/spec.md`.

**Inline-vs-skill boundary:**
- INLINE (classification-critical, zero-latency): Classification Decision Table, Scope Estimation Heuristic, Ambiguity Detection Heuristics, Unbreakable Rules, Response Signal format
- ON-DEMAND skill: session banner, tone/persona, teaching, new-user detection

**Budget governance (enforced by project-audit D14):**
- Global CLAUDE.md: 20,000 chars max (currently: ~19,856 chars)
- Project CLAUDE.md: 5,000 chars max (override-only projects)
- New orchestrator skills: 8,000 chars max

30. **Pre-flight advisory gates for Change Request routing** (added 2026-03-22, change: 2026-03-21-orchestrator-action-control-gates) — Two advisory-only pre-flight checks run before any Change Request is routed: Gate 1 scans `openspec/changes/` (excluding `archive/`) for in-flight cycles with slug token overlap (stop-word filtered, length > 3), and emits an advisory if a semantic match is found. Gate 2 keyword-matches the change description against `openspec/specs/index.yaml` domain keywords, surfacing a spec drift advisory for up to 3 matched domains. Both gates are non-blocking — the routing recommendation always follows regardless of advisory output. `index.yaml` absence degrades gracefully (Gate 2 skips silently). `sdd-spec` was updated with Sub-step 3.0: create `index.yaml` when absent on first domain spec write (idempotent, non-blocking side effect). Master spec extended at `openspec/specs/orchestrator-behavior/spec.md`. New domain spec created at `openspec/specs/sdd-spec-index-creation/spec.md`.

28. **Communication Persona presentation layer for orchestrator responses** (added 2026-03-22, change: 2026-03-21-orchestrator-natural-language) — A new `## Communication Persona` section in CLAUDE.md (between Teaching Principles and Plan Mode Rules) defines how the orchestrator expresses itself: warm/direct/confident/pedagogical tone profile, natural prose response templates per intent class, a deny-list of forbidden mechanical phrases (e.g., "Rule 7 confirmation required", "Auto-launching sdd-explore"), adaptive formality (mirror user register, default neutral-warm), and a rewritten session banner in welcoming tone. All changes are purely presentational — no routing logic, classification rules, or sub-agent execution patterns are modified. The intent classification signal (`**Intent classification: X**`) is preserved exactly. Master spec extended at `openspec/specs/orchestrator-behavior/spec.md`. _(Note: Communication Persona and Teaching Principles sections were subsequently relocated to `skills/orchestrator-persona/SKILL.md` in change 2026-03-22-slim-orchestrator-context — see decision 29.)_

27. **Scope estimation heuristic for Change Request routing** (added 2026-03-22, change: 2026-03-21-orchestrator-scope-estimation) — A new `### Scope Estimation Heuristic` subsection in CLAUDE.md (under `## Always-On Orchestrator — Intent Classification`, after the Classification Decision Table) defines three scope tiers: Trivial, Moderate, and Complex. Trivial requires ALL conditions (keyword match + single-file scope + no structural keywords) and offers inline apply as a formal Rule 1 exception — artifact-free, user must explicitly choose it. Complex triggers on ANY signal keyword (rearchitect, migrate, rewrite, etc.) and routes to `/sdd-new`. Moderate is the default/residual tier, preserving existing `/sdd-ff` behavior. The Classification Decision Table's Change Request branch gains a scope estimation cross-reference. Unbreakable Rule 1 gains a parenthetical exception clause for Trivial. Response signals MAY include tier suffix for Trivial and Complex. Master spec extended at `openspec/specs/orchestrator-behavior/spec.md`.

26. **Teaching principles layer — cross-cutting behavioral annotations for orchestrator responses** (added 2026-03-22, change: 2026-03-21-orchestrator-teaching) — A new `## Teaching Principles` section in CLAUDE.md (between Unbreakable Rules and Plan Mode Rules) defines 5 concise rules: why-framing (risk sentence on Change Requests), educational gates (consequence sentence on confirmation prompts), error reformulation (cause+action on blocked/failed in sdd-ff), post-cycle reflection (narrative paragraph in sdd-ff Step 4), and progressive disclosure (new-user detection via `openspec/changes/archive/` directory count). All changes are purely additive — no routing logic, classification rules, or sub-agent execution patterns are modified. sdd-ff gains error reformulation and post-cycle narrative; CLAUDE.md gains new-user detection logic. Master spec extended at `openspec/specs/orchestrator-behavior/spec.md`.

32. **Uniform natural language gate pattern for all SDD phase completion messages** (added 2026-03-22, change: standardize-phase-completion-messages) — All SDD phase skills that present a completion message now use the canonical two-line template: "Continue with <next phase>? Reply **yes** to proceed or **no** to pause." / "_(Manual: `/sdd-<phase> <slug>`)_". Three skills were updated: `sdd-new` (was "Ready to implement? Run: /sdd-apply"), `sdd-apply` (was "Implementation complete. Next step: /sdd-verify"), `sdd-verify` (had no gate — one was added for the sdd-archive transition). Five skills confirmed unchanged (JSON-only output — no prose gate exists): sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks. sdd-ff Step 4 was explicitly excluded (already compliant). Master spec: `openspec/specs/sdd-phase-completion-messages/spec.md`.

31. **Model routing — Opus for propose and design phases** (added 2026-03-22) — `openspec/config.yaml` `model_routing` block was activated: `propose` and `design` phases route to `claude-opus-4-5`; all other phases (`explore`, `spec`, `tasks`, `apply`, `verify`, `archive`) route to `claude-sonnet-4-5`. Rationale: `proposal.md` is the only context bridge between the user's conversational session and all downstream sub-agent phases; the propose phase synthesizes multi-turn conversation into a structured artifact that spec, design, tasks, and apply all read as their primary input — this phase has the highest leverage for quality investment. The design phase produces the architectural blueprint sub-agents follow during apply — second-highest leverage. All other phases operate on already-structured artifacts where Sonnet delivers sufficient quality.

25. **Context-aware session handoff heuristic — replaces opt-in Rule 6 trigger** (implemented 2026-03-22, change: 2026-03-21-orchestrator-mandatory-new-session, ADR-043) — Rule 6 in CLAUDE.md was rewritten from an opt-in explicit-language trigger ("new session", "next chat", "context reset") to a two-branch context-aware heuristic. Branch A: when significant prior context exists (~5+ messages or other topics discussed), orchestrator creates `proposal.md` immediately with conversation context, displays the path, recommends a new session, and offers `/memory-update`. Branch B: when the session is clean (change request is first or near-first message), orchestrator recommends `/sdd-ff <slug>` directly without a session jump. `sdd-ff` Step 4 was also updated: command-as-gate pattern ("Ready to implement? Run: /sdd-apply") replaced with natural language confirmation ("Continue with implementation? Reply yes to proceed."). Archived at `openspec/changes/archive/2026-03-22-orchestrator-mandatory-new-session/`.

19. **Sub-agent governance context injection — orchestrators pass CLAUDE.md path; phase skills read full governance at Step 0a** (added 2026-03-12, change: fix-subagent-project-context) — Both orchestrator skills (`sdd-ff`, `sdd-new`) now include a `Project governance: <absolute-path>/CLAUDE.md` line in the CONTEXT block of every sub-agent Task prompt. All six SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) expand Step 0a to read the full project CLAUDE.md (not just Skills Registry) and log a governance summary line: `Governance loaded: [N] unbreakable rules, tech stack: [stack], intent classification: [enabled|disabled]`. Governance loading is non-blocking (missing CLAUDE.md emits INFO note). Model corrections applied: explore, propose, and tasks sub-agents corrected to `model: sonnet`. Master specs at `openspec/specs/sub-agent-governance-injection/spec.md`, `openspec/specs/step-0a-governance-discovery/spec.md`, `openspec/specs/sub-agent-execution-contract-update/spec.md`.

24. **Spec authority in Q&A and spec garbage collection skill** (added 2026-03-19, change: feedback-sdd-cycle-context-gaps-p6) — Two complementary improvements to spec handling: (1) The orchestrator's Question routing now includes Step 8 (Spec-first Q&A): when `openspec/specs/index.yaml` exists, the orchestrator reads matching domain specs (keyword/stem matching, top-3 cap) before answering any Question. Specs are the authoritative source; contradictions between code and spec are surfaced as ⚠️ warnings inline. This ensures Q&A answers from spec intent, not just observed code. (2) New `sdd-spec-gc` skill at `~/.claude/skills/sdd-spec-gc/SKILL.md` audits master specs for PROVISIONAL, ORPHANED_REF, CONTRADICTORY, SUPERSEDED, and DUPLICATE requirements. Workflow: dry-run report → user confirmation gate → apply removals → record GC comment in spec + changelog entry. ORPHANED_REF detection is best-effort (grep); uncertain matches are flagged UNCERTAIN and require user confirmation, never auto-removed. GC runs independently (`/sdd-spec-gc <domain>` or `/sdd-spec-gc --all`); recommended cadence: every 5–10 archived cycles. Both changes are purely additive and gracefully degrade when `index.yaml` is absent. Convention documented in `docs/SPEC-CONTEXT.md` (Orchestrator Spec-first Q&A section).

23. **SDD cycle context gap overhaul — replacement detection, supersedes semantics, contradiction gate** (added 2026-03-19, change: feedback-sdd-cycle-context-gaps) — Six interconnected architectural additions address blind spots when the SDD cycle handles replacement changes and removal intents: (1) `sdd-explore` adds Branch Diff (git status scan for prior local edits), Prior Attempts (archive search for prior cycle attempts on the same domain), and Contradiction Analysis (CERTAIN/UNCERTAIN classification of intent vs. documented constraints) sections to every `exploration.md`; (2) `sdd-propose` adds a mandatory `## Supersedes` section (REMOVED/REPLACED/CONTRADICTED subtypes) and optional `## Context` section capturing explicit user intents from conversation; (3) `sdd-spec` adds a Supersedes validation step — emits MUST_RESOLVE warning if delta spec preserves behavior that proposal marks REMOVED; (4) `sdd-tasks` generates explicit removal/replacement tasks from proposal Supersedes section, sequenced as Phase 1 before addition tasks; (5) `sdd-ff` adds a pre-populated skeleton `proposal.md` before launching explore, and a contradiction gate between explore and propose (gate fires only for UNCERTAIN contradictions; CERTAIN ones are already captured in exploration); (6) CLAUDE.md Unbreakable Rule 7 (context extraction before /sdd-ff handoff) — when user message includes removal/replacement language, orchestrator confirms intent before recommending /sdd-ff. Master specs: `openspec/specs/sdd-explore-replacement-detection/spec.md` (new), `openspec/specs/sdd-propose-supersedes-section/spec.md` (new), `openspec/specs/sdd-tasks-removal-tasks/spec.md` (new), `openspec/specs/sdd-phase-context-loading/spec.md` (extended), `openspec/specs/sdd-orchestration/spec.md` (extended), `openspec/specs/orchestrator-behavior/spec.md` (extended).

22. **Spec index for targeted keyword-driven domain selection** (added 2026-03-14, change: specs-search-optimization) — `openspec/specs/index.yaml` is a flat YAML file with one entry per spec domain (56 entries after archiving this change). Each entry has `domain`, `summary`, `keywords` (3–8 terms), and optional `related` fields. Sub-agents that need background spec context read this index first, score entries by stem overlap with the change slug, and select the top 3 matches — replacing blind directory listing or exhaustive loading. Fallback: when `index.yaml` is absent, sub-agents use the existing stem-based directory-name matching algorithm. `sdd-archive` now includes a Step 3a: when a delta merge creates a new domain directory, `sdd-archive` appends its entry to `index.yaml` (creates a minimal `index.yaml` if absent). Index maintenance failure is non-blocking. ADR 034 documents the SQLite/FTS5 migration path for projects reaching 100+ domains (status: Proposed). Documented in `docs/SPEC-CONTEXT.md` under "Using the spec index". Master specs at `openspec/specs/spec-index/spec.md` and `openspec/specs/sdd-archive-execution/spec.md`.

21. **Clarification gate for ambiguous inputs — pre-Question disambiguation step added to Classification Decision Table** (added 2026-03-14, change: add-clarification-gate-for-ambiguous-inputs) — A new `ELSE IF` branch is inserted before the final default `ELSE` (Question) in the CLAUDE.md Classification Decision Table. When a user message matches one of four ambiguity heuristics (H1: single-word input matching `^[a-z0-9-]+$`, H2: standalone action verb with no object, H3: vague noun phrase ≤ 4 words with no action verb, H4: compound phrase with weak binding), the orchestrator presents a 3-option clarification prompt instead of immediately defaulting to Question. User response (1/2/3 or free text) is routed: `1` → Change Request, `2` → Exploration, `3` → Question, free text → re-classify via standard rules. A reserved exclusion list (`yes`, `no`, `true`, `false`, etc.) prevents natural reply words from triggering the gate. Non-ambiguous inputs (explicit intent verbs, `?` punctuation, slash commands) are caught by earlier branches and bypass the gate entirely. Gate is pure inline logic in CLAUDE.md — no new skill or architectural layer. Extends ADR 029 (orchestrator-always-on) and directly addresses the ambiguous-input edge case documented in ADR 031. Master spec at `openspec/specs/orchestrator-behavior/spec.md`.

20. **Orchestrator visibility signals — session banner, per-response intent signal, and on-demand `/orchestrator-status` skill** (added 2026-03-14, change: orchestrator-visibility) — Three complementary visibility signals make the SDD Orchestrator's behavior transparent to users. (1) Session-start banner: static H3 section in CLAUDE.md displays at session start via the orchestrator's natural CLAUDE.md read; confirms orchestrator active + four intent classes. (2) Intent classification signal: orchestrator prefixes every response to free-form messages with `**Intent classification: <Class>**`; scope is strictly free-form messages (slash commands and sub-agent responses are excluded). (3) `/orchestrator-status` skill: procedural skill at `~/.claude/skills/orchestrator-status/SKILL.md`; reads CLAUDE.md + openspec/changes/ + Skills Registry; returns structured JSON block + prose interpretation; read-only with no side effects. No ADR generated — changes are implementation-level refinements of the existing orchestrator-always-on pattern (ADR 029). Master spec extended at `openspec/specs/orchestrator-behavior/spec.md`.

18. **Always-on intent classification adds a proactive cross-cutting orchestration layer** (added 2026-03-12, change: orchestrator-always-on) — ADR 029 (`docs/adr/029-orchestrator-always-on-intent-classification.md`) documents the decision to implement proactive intent classification in the orchestrator. Every user message is classified into one of four intent classes (Meta-Command, Change Request, Exploration, Question) via keyword-based heuristics inline in CLAUDE.md (no new skill). The classification gate runs before any response is generated. Change Requests route to SDD recommend (non-blocking); Explorations auto-launch sdd-explore via Task; Questions are answered directly; Meta-Commands execute immediately. This introduces a system-wide behavioral pattern where the orchestrator is no longer purely reactive — it now proactively routes requests based on intent, teaching users the SDD discipline. Master spec at `openspec/specs/orchestrator-behavior/spec.md`.

17. **SDD parallelism model is formally bounded at 2 concurrent Tasks** (added 2026-03-10, change: sdd-parallelism-adr) — ADR 028 (`docs/adr/028-sdd-parallelism-model.md`) documents the SDD parallelism model: maximum 2 simultaneously running Task sub-agents; the only safe parallel pair in the current SDD cycle is `sdd-spec` + `sdd-design` (they write to non-overlapping files). File conflict boundary rule: Tasks writing to the same files MUST be sequential; Tasks with non-overlapping file sets MAY run in parallel. Bounded-context parallel apply (independent domains in `sdd-apply`) is evaluated as conditionally feasible under 3 explicit conditions, but implementation is deferred to a separate change. CLAUDE.md Fast-Forward and Apply Strategy sections accurately reflect the model and were not modified. ADR 028 master spec at `openspec/specs/sdd-parallelism/spec.md`.

1. **Skills are directories, not files** — allows co-locating templates, examples, or sub-skills
2. **SKILL.md is the convention** — every skill directory has exactly one entry point named `SKILL.md`
3. **Artifacts over in-memory state** — skills communicate via files, never via conversation context alone
4. **Orchestrator delegates everything** — the global CLAUDE.md never executes work itself, always spawns subagents via Task tool
5. **install.sh is repo-authoritative** — all directories flow repo → ~/.claude/. The only reverse direction is `sync.sh`, which captures `memory/` only. Every other directory (skills/, CLAUDE.md, hooks/, openspec/, ai-context/) must always be edited in the repo — never in ~/.claude/ directly.
8. **sdd-apply enforces a structured Quality Gate before task completion** (added 2026-03-04, change: solid-ddd-quality-enforcement) — The vague "Code Standards" section in `sdd-apply` is replaced by a 7-item numbered Quality Gate (SRP, abstraction appropriateness, DIP, domain model integrity, ISP, no scope creep, no over-engineering). Sub-agents MUST evaluate each criterion before marking a task `[x]` complete. QUALITY_VIOLATION is non-blocking by default; escalates to DEVIATION only when it contradicts a spec scenario. `solid-ddd` skill is loaded unconditionally for all non-documentation code changes via the Stack-to-Skill Mapping Table (no keyword match required).

9. **solid-ddd is a universal design principles skill, not a tech-stack skill** (added 2026-03-04, change: solid-ddd-quality-enforcement) — `skills/solid-ddd/SKILL.md` is `format: reference` and covers language-agnostic SOLID + DDD tactical patterns. Unlike technology skills (react-19, typescript, etc.) which are keyword-triggered, `solid-ddd` is unconditional — loaded for every non-documentation code change. It co-exists with `hexagonal-architecture-java` (which covers Java-specific Hexagonal implementation idioms); both skills are complementary.

7. **Runtime-auditing skill is standalone, not a project-audit dimension** (added 2026-03-03, change: claude-folder-audit) — `claude-folder-audit` audits `~/.claude/` installation state (drift, missing skills, orphans, scope tier compliance) as a standalone procedural skill, not as a D11 extension of `project-audit`. Rationale: single-responsibility and independently invocable from any context. Report written to `~/.claude/claude-folder-audit-report.md` (runtime artifact, never committed). V1 is read-only; auto-fix companion (`claude-folder-fix`) is future work.

11. **SDD phase skills load project context before any output** (added 2026-03-10, change: sdd-project-context-awareness) — All six SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) execute a mandatory Step 0 — Load project context block as the first step. Step 0 reads `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, and the project's CLAUDE.md Skills Registry. Missing files emit an INFO-level note and execution continues (non-blocking). `sdd-propose` and `sdd-spec` use a dual sub-step structure: Step 0a = global project context; Step 0b = domain feature preload (unchanged from feature-domain-knowledge-layer). `sdd-design` must cross-reference the project Skills Registry when recommending tools; unregistered global-catalog skills are marked `[optional — not registered in project]`. Reference: `docs/sdd-context-injection.md`.

13. **sdd-tasks classifies warnings as MUST_RESOLVE or ADVISORY; sdd-apply enforces a blocking gate for MUST_RESOLVE warnings** (added 2026-03-10, change: sdd-blocking-warnings) — During task planning, `sdd-tasks` classifies every warning into one of two tiers: `MUST_RESOLVE` (blocks execution until the user provides an explicit answer) or `ADVISORY` (logged but does not interrupt execution). Classifications and reasons are recorded inline in `tasks.md` with `[WARNING: TYPE]` markers. Before executing any `MUST_RESOLVE`-flagged task, `sdd-apply` presents a blocking gate (`⛔ BLOCKED`) with no skip option; the user's answer is recorded in `tasks.md` with an ISO 8601 timestamp. ADVISORY warnings are logged to progress output and execution continues immediately. Default classification is ADVISORY when in doubt (style, performance, naming preferences). MUST_RESOLVE is reserved for business rule decisions, external system ambiguities, and data model choices with no clearly correct answer.

16. **sdd-verify enforces an evidence gate before archiving** (added 2026-03-10, change: sdd-verify-enforcement) — `verify-report.md` MUST include a `## Tool Execution` section recording the command run, exit code, and output summary; this section is written on every invocation — even when skipped (stating "Test Execution: SKIPPED — no test runner detected"). Criteria marked `[x]` MUST have verifiable evidence: tool output or an explicit user evidence statement; abstract reasoning or code inspection alone MUST NOT suffice. The `verify_commands` optional key in `openspec/config.yaml` overrides auto-detection entirely when present. `sdd-apply` no longer suggests `/commit` — after implementation the only permitted next-step suggestion is `/sdd-verify <change-name>`.

15. **sdd-apply mandates a Diagnosis Step before every task implementation** (added 2026-03-10, change: sdd-apply-diagnose-first) — Before making any file change, the `sdd-apply` sub-agent MUST execute a Diagnosis Step: read files to be modified, run read-only diagnostic commands (auto-detected or from `openspec/config.yaml` `diagnosis_commands` key), and write a structured `DIAGNOSIS` block (6 fields: files, command outputs, current behavior, data/state, hypothesis, risk). No file write is permitted before the `DIAGNOSIS` block is written. When diagnostic findings contradict task assumptions, a `MUST_RESOLVE` warning is raised and execution pauses for explicit user confirmation. The Diagnosis Step is universal — applies to all tasks including file-creation tasks. It complements (not replaces) the existing Quality Gate.

12. **sdd-apply enforces a per-task retry circuit breaker** (added 2026-03-10, change: sdd-apply-retry-limit) — The task execution loop in `sdd-apply` tracks an in-memory attempt counter per task (reset each invocation). When a task fails after `max_attempts` attempts (default 3, configurable via `openspec/config.yaml` key `apply_max_retries`), it is marked `[BLOCKED]` in `tasks.md` with a full attempt summary, the final error, and a specific resolution instruction. The phase halts immediately — no subsequent tasks are processed. Same-strategy detection is also enforced: if two consecutive attempts modify the same files in the same way, the task is marked `[BLOCKED]` with message "Identical strategy attempted twice — manual intervention required". Resume requires the user to change the task status back to `[TODO]` and re-run `/sdd-apply <change-name>`; the counter resets for that task on re-invocation.

14. **sdd-new and sdd-ff auto-infer change slug; exploration is mandatory** (added 2026-03-10, change: sdd-new-improvements) — Both orchestrator skills (`sdd-new`, `sdd-ff`) infer the change slug from the user's description using a stop-word-filtered algorithm (max 5 meaningful words, lowercase, hyphenated, date-prefixed, collision-safe with numeric suffix). No name-input gate exists. `sdd-new` runs `sdd-explore` unconditionally as Step 1. `sdd-ff` runs `sdd-explore` as new Step 0 — fast-forward sequence is now: explore → propose → spec+design (parallel) → tasks. CLAUDE.md Fast-Forward section updated. Master spec created at `openspec/specs/sdd-orchestration/spec.md`.

10. **Feedback sessions produce only proposals — never SDD cycles** (added 2026-03-10, change: sdd-feedback-persistence) — Rule 5 in CLAUDE.md Unbreakable Rules enforces a two-session model: when a user provides feedback (observations, complaints, improvement ideas), the orchestrator MUST only create `proposal.md` files and MUST NOT start any SDD command (`/sdd-ff`, `/sdd-new`, `/sdd-apply`, etc.) in the same session. Implementation happens in a separate session. The rule is placed in Unbreakable Rules (not a skill) to ensure it is loaded at session start without additional file reads. Workflow documented at `docs/workflows/feedback-to-proposal.md`.

6. **Two-tier skill placement model** (added 2026-03-02, change: skill-scope-global-vs-project) — Skills have two placement tiers: global (`~/.claude/skills/`) and project-local (`.claude/skills/`). When `/skill-add` or `/skill-creator` is used inside a project (not `agent-config`), the default placement is project-local — the skill file is copied into the repo and versioned alongside project source code. Global placement remains available as an explicit override. `project-fix` treats `move-to-global` as informational only (no automated file moves). Project-local skills MUST be committed to the repo; no `.gitignore` rule should exclude `.claude/skills/`. The CLAUDE.md Skills Registry uses `.claude/skills/<name>/SKILL.md` for local copies and `~/.claude/skills/<name>/SKILL.md` for global references — both formats can coexist.

## claude-folder-audit: Check Inventory (project mode)

Project mode runs **8 checks** (P1–P8). Each check is listed below with its sub-phases and severity caps.

| Check | Name | Sub-phases | Max severity |
|-------|------|-----------|-------------|
| P1 | CLAUDE.md presence and content quality | A: file presence; B: openspec/config.yaml; C: section headings, line count, SDD commands, Skills Registry paths | MEDIUM (Phase C caps at MEDIUM) |
| P2 | Global skills reachability and content quality | A: existence at ~/.claude/skills/; B: reachability; C: SKILL.md frontmatter, format: field, section contract, body length, TODO marker | MEDIUM |
| P3 | Local skills reachability and content quality | A: existence in .claude/skills/; B: reachability; C: SKILL.md frontmatter, format: field, section contract, body length, TODO marker | MEDIUM |
| P4 | Orphaned global skills | Detects skills present in ~/.claude/skills/ but not referenced in CLAUDE.md | MEDIUM |
| P5 | Scope tier overlap | Detects skills registered in both global and local tiers simultaneously | HIGH |
| P6 | Memory layer (ai-context/) | Presence of ai-context/ directory; presence of each of the five required files (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md); line count per file | MEDIUM |
| P7 | Feature domain knowledge layer (ai-context/features/) | Presence of ai-context/features/; non-template file count; section headings per domain file (Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas); line count per file | LOW (severity cap — never above LOW) |
| P8 | .claude/ folder inventory | Unexpected items directly under .claude/ vs. expected set; empty hook files in hooks/ | MEDIUM |

**Phase C content quality sub-checks (P1-C, P2-C, P3-C):**
- P1-Phase C: Reads CLAUDE.md and validates mandatory section headings (`## Tech Stack`, `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`, `## Skills Registry`); line count thresholds (MEDIUM if <30 lines, LOW if 30–50 lines); SDD command presence (`/sdd-explore` or `/sdd-propose`); Skills Registry path entries.
- P2-Phase C and P3-Phase C: Validates SKILL.md frontmatter presence (leading `---` block); extracts `format:` value (LOW if absent or unrecognized, defaults to procedural); runs section contract per format type (procedural: `**Triggers**`/`## Triggers` + `## Process`/`### Step N` + `## Rules`; reference: `**Triggers**`/`## Triggers` + `## Patterns`/`## Examples` + `## Rules`; anti-pattern: `**Triggers**`/`## Triggers` + `## Anti-patterns` + `## Rules`); body line count (LOW if <30); TODO marker detection (INFO).
- P4 orphaned skills are explicitly excluded from Phase C content sub-checks.

**Section detection rule (uniform across P1-C, P2-C, P3-C, P7):** A section is present when at least one line STARTS with `## <section-name>`. Lines inside fenced code blocks are not exempt from this rule. Bold-trigger pattern (`**Triggers**`) is also a valid match for the Triggers section specifically.

**ADR reference:** P7 is the V2 audit integration deferred in ADR-015 (feature-domain-knowledge-layer-architecture). ADR-016 (enhance-claude-folder-audit-content-quality-convention) documents the Phase C sub-check convention.

<!-- [auto-updated]: structure-mapping — last run: 2026-03-08 -->
## Observed Structure (auto-detected)

Organization pattern: **feature-based** (confidence: high)
Each `skills/` subdirectory is a distinct capability with one `SKILL.md` entry point.

```
agent-config/ (observed 2026-03-08)
├── CLAUDE.md, README.md, settings.json, install.sh, sync.sh, .gitattributes
├── skills/          ~33 skill directories
│   ├── sdd-*/       9 SDD phase skills (explore, propose, spec,
│   │                  design, tasks, apply, verify, archive, status)
│   ├── project-*/   4 meta-tool skills (setup, onboard, audit, fix)
│   ├── memory-manage/  1 unified memory management skill
│   ├── skill-creator/  1 skill management skill
│   ├── config-export/  1 config export skill
│   ├── feature-domain-expert/  1 domain knowledge skill
│   ├── smart-commit/   1 commit automation skill
│   ├── solid-ddd/, go-testing/  2 design/testing skills
│   └── [tech-skills]   ~10 technology catalog skills
├── hooks/           smart-commit-context.js (Node.js)
├── openspec/        config.yaml + changes/ (0 active) + specs/ (38 domains) + archive/
├── ai-context/      8 files: stack, architecture, conventions, known-issues,
│                    changelog-ai, onboarding, quick-reference, scenarios
│                    + features/ sub-directory (domain knowledge scaffold)
├── docs/            adr/ (23 ADRs + README.md) + templates/ (prd, adr) + copilot-templates/
└── memory/          MEMORY.md + topic files
```

Active SDD changes: none — all changes archived as of 2026-03-08.

<!-- [/auto-updated] -->

<!-- [auto-updated]: drift-summary — last run: 2026-03-08 -->
## Architecture Drift (auto-detected)

Drift level: **minor** (2 informational entries)

Summary of drift vs. `architecture.md` baseline (2026-03-08):
- Skill count: stack.md manual section documents skill categories with outdated sub-counts; 49 observed (natural catalog growth — 2 additional skills since last analysis on 2026-03-03)
- ai-context/ file count: stack.md Skill categories table references "5 core files"; 8 files observed (onboarding.md, quick-reference.md, scenarios.md are documented in the architecture.md artifact table but stack.md manual count section is stale)

All drift is informational. No structural mismatches detected. All documented architectural layers (skills/, hooks/, openspec/, ai-context/, docs/adr/, docs/templates/, memory/) are present and correctly positioned.

<!-- [/auto-updated] -->
