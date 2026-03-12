# Feature: SDD Meta-System

> The specification-driven development orchestration layer that governs how Claude Code plans,
> implements, and archives changes in any project using this configuration.

Last updated: 2026-03-03
Related specs: openspec/specs/feature-domain-knowledge/spec.md

---

## Domain Overview

The SDD meta-system is the Claude Code configuration and skill orchestration framework that lives in
`agent-config` (repo) and is deployed to `~/.claude/` (runtime). It provides two primary
capabilities: (1) a library of reusable skills — each a directory with a `SKILL.md` entry point —
that Claude loads on demand; and (2) an SDD (Specification-Driven Development) phase pipeline
(`sdd-propose` → `sdd-spec` + `sdd-design` → `sdd-tasks` → `sdd-apply` → `sdd-verify` →
`sdd-archive`) that governs how changes are made to any project using this config. The system is
self-hosting: changes to its own skills and CLAUDE.md must follow the same SDD cycle it imposes on
other projects.

---

## Business Rules and Invariants

- Every skill modification MUST be preceded by at minimum `/sdd-ff` before `/sdd-apply`. No skill
  file may be changed without a completed proposal, spec, design, and tasks plan on record.
- Every archived change MUST have a `verify-report.md` with at least one `[x]` criterion. A change
  without a verify-report is ineligible for archiving.
- `sync.sh` MUST only move `memory/` from `~/.claude/` to the repo. It MUST NOT sync skills, hooks,
  ai-context, or CLAUDE.md. Those flow in the opposite direction via `install.sh`.
- `install.sh` is the ONLY mechanism for deploying config changes (skills, CLAUDE.md, hooks,
  ai-context) from the repo to `~/.claude/`. Running `sync.sh` for config changes silently
  discards them.
- Developers MUST NOT edit files under `~/.claude/` directly. Edits to `~/.claude/` that are not
  reflected in the repo will be overwritten the next time `install.sh` is run.
- `spec` and `design` SDD phases MUST be run in parallel. `tasks` requires both to be complete
  before it can begin.
- `archive` is irreversible: the orchestrator MUST confirm with the user before proceeding.
- All content — skills, YAML, scripts, docs, commits — MUST be in English without exception.
- Each SKILL.md MUST declare a `format:` field in its YAML frontmatter (`procedural`, `reference`,
  or `anti-pattern`) and satisfy that format's section contract.
- The SDD orchestrator MUST delegate each SDD phase to a sub-agent via the Task tool. The
  orchestrator MUST NOT write specs, proposals, or implementation code directly in its own context.

---

## Data Model Summary

| Entity | Key Fields | Constraints |
|--------|------------|-------------|
| Skill | Directory name (kebab-case), `SKILL.md` entry point, YAML frontmatter (`name`, `description`, `format`) | One SKILL.md per directory; `format` must be `procedural`, `reference`, or `anti-pattern` |
| SDD Change | `proposal.md`, `specs/<domain>/spec.md`, `design.md`, `tasks.md`, optional `verify-report.md` | Stored under `openspec/changes/<change-name>/`; archived to `openspec/changes/archive/YYYY-MM-DD-<name>/` |
| ai-context file | One of: `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md` | Live in `ai-context/`; updated by `memory-init`, `memory-update`, and `project-analyze` |
| Feature file | `ai-context/features/<domain>.md`; six sections: Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas | Flat directory — no subdirectories; `_template.md` is excluded from SDD phase preloading |
| openspec config | `openspec/config.yaml`; controls SDD mode, domains, and optional feature_docs block | `feature_docs:` block is commented out in V1 |

Relationships: a single SDD Change owns one proposal, one or more domain specs (under `specs/`), one
design, one tasks file, and one optional verify-report. Skills and ai-context files are independent
of individual changes — they represent the durable system state.

---

## Integration Points

| System / Service | Direction | Contract |
|-----------------|-----------|----------|
| `install.sh` | outbound | Copies repo root (`skills/`, `CLAUDE.md`, `ai-context/`, `hooks/`, `settings.json`) to `~/.claude/`. Must be run after any config change before the next Claude session picks up the updates. |
| `sync.sh` | inbound | Copies `~/.claude/memory/` back into `repo/memory/`. Used for persisting Claude's automatic memory notes. Does NOT touch skills, hooks, or ai-context. |
| `~/.claude/` (runtime) | outbound | The live Claude Code runtime directory. Claude reads SKILL.md files from here. This is the deployment target — never the source of truth. |
| `git` (version control) | outbound | All config changes committed to the `agent-config` repo after `install.sh` runs. Conventional commit prefix: `feat:`, `fix:`, `docs:`, `chore:`. |
| Sub-agents (Task tool) | outbound | The SDD orchestrator launches one sub-agent per SDD phase. Each sub-agent reads its phase SKILL.md from `~/.claude/skills/sdd-<phase>/SKILL.md` and returns a structured JSON result. |
| `openspec/config.yaml` | inbound | Controls which SDD features are active (mode, optional blocks). SDD phase skills read this file at runtime to determine behavior. |

---

## Decision Log

### 2026-02-23 — Three-tier skill architecture (global vs. project-local vs. orchestrator)

**Decision**: Skills are categorized into three tiers: (1) global skills deployed to `~/.claude/`
for all projects, (2) project-local skills in `.claude/skills/` for a specific project, and (3)
orchestrator skills (sdd-ff, sdd-new) that use the Task tool to delegate to sub-agents.

**Rationale**: Global placement avoids duplication across projects. Project-local placement isolates
domain-specific skills. The orchestrator tier acknowledges that coordinating multiple long-running
SDD phases requires fresh context isolation per phase.

**Impact**: Any new meta-system skill (memory-init, project-audit, etc.) belongs in the global
catalog and is deployed via `install.sh`. Project-specific skills must not be placed in the global
catalog. The Task tool delegation pattern is mandatory for orchestrator-type skills.

### 2026-02-27 — sync.sh vs. install.sh separation of concerns

**Decision**: `sync.sh` is strictly a one-direction tool (`~/.claude/memory/ → repo/memory/`). All
config changes (skills, CLAUDE.md, hooks, ai-context) flow exclusively via `install.sh`
(`repo → ~/.claude/`).

**Rationale**: Bidirectional sync creates merge conflicts and ambiguity about which copy is
authoritative. Splitting by concern (memory = auto-generated, everything else = manually authored)
makes the source-of-truth unambiguous.

**Impact**: Developers must remember to run `install.sh` after any config change. Running `sync.sh`
after a skill edit does nothing — the skill change will not be deployed.

### 2026-03-03 — Add ai-context/features/ as Tier 1 domain knowledge layer

**Decision**: Introduce `ai-context/features/<domain>.md` as a permanent sub-layer of the project
memory. Each file encodes business rules, invariants, data model summary, integration points,
decision log, and known gotchas for one bounded context. A canonical `_template.md` enforces the
six-section structure.

**Rationale**: SDD phase skills (sdd-propose, sdd-spec) lack access to stable business context
between cycles. openspec/specs/ files encode behavioral deltas (GIVEN/WHEN/THEN) but not the
durable domain rules that predate and outlast any individual change. The features/ layer fills this
gap without altering the existing spec format.

**Impact**: `sdd-propose` and `sdd-spec` each gain a non-blocking Step 0 that preloads matching
feature files as enrichment context. `memory-init` gains a Step 7 that scaffolds stubs on first
run. `memory-update` gains a Step 3b that appends session-acquired domain knowledge. The new
`feature-domain-expert` skill serves as the authoring guide. `project-analyze` explicitly does NOT
write to `ai-context/features/`.

### 2026-03-04 — project-claude-organizer: post-migration cleanup with confirmed deletion

**Decision**: After each applicable legacy migration category (`copy`, `append`, `scaffold`, `user-choice`) completes in Step 5.7, the skill offers to delete the successfully migrated source files via an explicit per-category yes/no prompt. `delegate` and `section-distribute` strategies are permanently exempt. Deletion is per-file (not directory), and only files with successful migration outcomes are eligible.
> Added: 2026-03-04

**Rationale**: The previous "never delete" invariant left `.claude/` structurally unchanged after migration, defeating the purpose of reorganization. Users had to manually remove source directories after the skill ran.

**Impact**: ADR 021 documents this convention. Rule 5 was added to `project-claude-organizer/SKILL.md`. The source-file preservation invariant is now conditional (dual condition: successful migration AND explicit user confirmation). The skill tagline blockquote at line 17 was not updated in this cycle and remains stale — a future cleanup should address it.

---

## Known Gotchas

- **`sync.sh` does NOT deploy skills.** A common mistake is running `sync.sh` after editing a
  skill file, expecting Claude to pick up the change. `sync.sh` only moves `memory/` from the
  runtime back to the repo — it never touches `skills/`. After any skill edit, you must run
  `bash install.sh`.

- **Direct edits to `~/.claude/` are silently lost.** If you edit a skill file directly in
  `~/.claude/skills/` (e.g., to test a quick fix), those changes will be overwritten the next time
  `install.sh` is run from the repo. Always edit in the repo first, then run `install.sh`.

- **`_template.md` is excluded from the domain preload heuristic.** Any file in
  `ai-context/features/` whose name starts with an underscore is never returned as a match by the
  slug-matching algorithm used in `sdd-propose` Step 0 and `sdd-spec` Step 0. This is intentional:
  the template is a structural guide, not domain knowledge.

- **The `feature_docs:` block in `openspec/config.yaml` is commented out in V1.** Audit
  integration for feature files is deferred. Do not uncomment the block expecting it to do anything
  — it has no effect until the project-audit D10 validator is implemented in V2.
