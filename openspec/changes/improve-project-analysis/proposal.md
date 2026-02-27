# Proposal: improve-project-analysis

Date: 2026-02-27
Status: Draft

## Intent

Transform `project-audit` into an orchestrator that calls specialized sub-skills (mirroring the proven SDD orchestrator pattern), and create a dedicated `project-analyze` skill that performs deep, framework-agnostic codebase analysis — ensuring Claude genuinely understands a project before any SDD work begins.

## Motivation

`project-audit` was designed to verify that the Claude/SDD configuration layer is correctly set up. It serves that purpose well. However, it has drifted into a second, fundamentally different responsibility: architecture compliance checking (D7), which requires reading and interpreting source code.

This has two concrete consequences:

1. **D7 is framework-bound and therefore cosmetic on most projects.** It hardcodes Next.js/Prisma-specific patterns. On a Django, Spring Boot, or pure Markdown project, D7 produces either false positives or meaningless output. The skill's own rules (max 3 Bash calls per audit) prevent the deeper sampling that real architecture analysis requires.

2. **Global SDD skills operate without project context.** When `/sdd-ff` is run on a project, the sub-agents for spec, design, and tasks have no reliable knowledge of the project's actual architecture, naming conventions, file organization, or technology patterns. The `ai-context/` layer exists to bridge this gap — but nothing currently ensures it is populated, accurate, or re-verified after the project evolves.

The result: Claude requires the user to re-explain project structure in every session, and architecture compliance checks are either shallow or ignored.

The user has identified the core requirement: **`project-audit` should guarantee that Claude is ready to be used in the project** — not just that config files are structurally present, but that Claude holds a working understanding of how the project is actually built.

The architectural decision reached through discussion: mirror the SDD orchestrator pattern. `project-audit` becomes an orchestrator that calls sub-skills in sequence. `project-analyze` is one of those sub-skills — the one responsible for deep codebase understanding.

## Scope

### Included

- **New skill: `project-analyze`** — a dedicated, standalone skill for deep, framework-agnostic project analysis. It reads the real codebase and produces:
  - Updates to `ai-context/` (permanent — stack, architecture, conventions populated with real observed patterns)
  - `analysis-report.md` (working artifact — structured, consumed by subsequent audit sub-skills)
- **Refactor: `project-audit` as orchestrator** — `project-audit` delegates to sub-skills in sequence rather than executing all analysis internally. The orchestration sequence is:
  1. `project-analyze` (codebase understanding → `analysis-report.md` + `ai-context/` update)
  2. Config health sub-skills (D1, D2, D3, D4, D6, D8 — currently embedded in project-audit, extracted into callable units)
  3. Final `audit-report.md` assembly (accumulated from sub-skill outputs)
- **D7 replacement** — the current hardcoded architecture compliance dimension is replaced by `project-analyze` output. D7 reads `analysis-report.md` instead of sampling source files directly.
- **Updated CLAUDE.md and Skills Registry** — `project-analyze` is registered as a meta-tool, and the orchestrator pattern for `project-audit` is documented.
- **Updated artifact table in `ai-context/architecture.md`** — `analysis-report.md` added as a first-class artifact with producer/consumer documentation.
- **Updated `openspec/config.yaml`** — `analysis_targets` optional key added for config-driven convention verification.

### Excluded (explicitly out of scope)

- **D9 (local skill quality) and D10 (feature docs coverage)**: These remain embedded in `project-audit` for this cycle. They are informational dimensions with no score impact and their extraction is a lower-priority change.
- **`project-fix` changes**: `project-fix` reads the final `audit-report.md` as today. No changes to the FIX_MANIFEST format or `project-fix` logic in this cycle.
- **`memory-manager` changes**: `memory-init` and `memory-update` remain unchanged. `project-analyze` complements them; it does not replace them. The distinction: `memory-init` writes `ai-context/` for the first time; `project-analyze` re-analyzes and updates it for established projects.
- **Convention verification depth beyond sampling**: `project-analyze` will describe observed patterns (naming, file organization, module structure) but will NOT perform exhaustive linting or diff `conventions.md` line by line. Verification remains heuristic and sampling-based.
- **SDD sub-agent context injection**: While `project-analyze` populates `ai-context/` for SDD sub-agents to read, changes to the sub-agent launch pattern (adding explicit `ai-context/` reading instructions) are deferred to a follow-on change.

## Proposed Approach

### `project-analyze` skill design

The skill performs five analysis steps, each producing a structured section in `analysis-report.md`:

1. **Structure mapping** — reads the folder tree, identifies the organization pattern (feature-based, layer-based, monorepo, flat), maps it against `architecture.md` if it exists.
2. **Stack detection** — reads `package.json`, `requirements.txt`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `mix.exs`, or equivalent. Falls back to file extension sampling if no manifest is found. No hardcoded framework assumptions.
3. **Convention sampling** — reads a representative sample of source files (configurable via `openspec/config.yaml`; default: up to 20 files across the detected source directories). Observes naming conventions (files, classes, functions, variables), import patterns, and error handling patterns.
4. **Architecture drift detection** — compares the folder structure and file organization observed against what `architecture.md` documents (if it exists). Reports discrepancies, not as failures but as informational drift entries.
5. **`ai-context/` update** — writes observed facts to `stack.md`, `architecture.md`, and `conventions.md`. Uses an append/update strategy: sections marked `[auto-updated]` are overwritten; sections without that marker are left intact (protecting human edits). Sets a `Last analyzed:` date in each file.

Output: `analysis-report.md` saved to the project root (alongside `audit-report.md`). Format: structured sections matching the five steps above, with a summary block at the top.

### `project-audit` as orchestrator

`project-audit` is restructured into a two-phase skill:

**Phase A — Discovery and analysis** (today's Phase A Bash batch + `project-analyze` invocation):
- Run the existing Phase A Bash discovery batch (file system checks, path existence, link validation)
- Call `project-analyze` as a sub-step, reading its `analysis-report.md` output for D7

**Phase B — Dimension scoring** (today's Phase B, refactored):
- D1, D2, D3, D4, D6, D8: unchanged logic, same scoring
- D7: reads `analysis-report.md` drift section instead of sampling source files directly. Score based on whether documented architecture matches observed structure (binary: matches / drifted).
- D9, D10: unchanged (informational, no score impact)

**Artifact handoff** (file-based, as per existing architecture):
- `analysis-report.md` → produced by `project-analyze`, consumed by `project-audit` D7 and any future sub-skill
- `audit-report.md` → produced by `project-audit` (assembled from all dimensions including D7 input from `analysis-report.md`), consumed by `project-fix`

### Memory strategy

The file-based artifact handoff is consistent with the existing architecture (see `ai-context/architecture.md` artifact table):

| Artifact | Producer | Consumer | Location |
|----------|----------|----------|----------|
| `analysis-report.md` | `project-analyze` | `project-audit` (D7), user | project root |
| `audit-report.md` | `project-audit` | `project-fix` | `.claude/` in project |
| `ai-context/*.md` | `project-analyze` (update), `memory-manager` (init) | all SDD sub-agents | `ai-context/` in project |

### Reversibility

Changes to `ai-context/` and `CLAUDE.md` in other projects are tracked by those projects' git history. The append/update strategy (preserving sections without `[auto-updated]` marker) means `project-analyze` never silently overwrites human decisions. Reverting a `project-analyze` run in any project is a standard `git checkout` on the affected `ai-context/` files.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-analyze/` | New | High — new skill, new entry point |
| `skills/project-audit/SKILL.md` | Modified | High — restructured as orchestrator, D7 rewritten |
| `CLAUDE.md` | Modified | Medium — `project-analyze` added to meta-tools table and skill registry |
| `ai-context/architecture.md` | Modified | Low — `analysis-report.md` added to artifact table |
| `openspec/config.yaml` (schema) | Modified | Low — `analysis_targets` optional key documented |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| `project-analyze` becomes a second project-audit (scope creep) | Medium | High | Strict skill rule: `project-analyze` observes and describes, never scores or produces FIX_MANIFEST entries |
| `analysis-report.md` becomes stale | Medium | Medium | `Last analyzed:` date field in report; `project-audit` warns if report is older than 7 days |
| `project-audit` orchestration increases its complexity | Medium | Medium | Phase A Bash batch is unchanged; orchestration adds one sequential step (call project-analyze), not N parallel calls |
| `ai-context/` human edits overwritten | Low | High | Append/update strategy: only `[auto-updated]` sections are overwritten; unmarked sections preserved |
| `project-analyze` context window overload on large repos | Medium | Medium | Configurable sample size (default 20 files); `openspec/config.yaml` allows explicit `analysis_targets` declaration |
| D7 scoring becomes dependent on `project-analyze` having run first | High | Low | `project-audit` checks for `analysis-report.md` existence; if absent, D7 scores 0 with a clear explanation message and instruction to run `project-analyze` first |

## Rollback Plan

**For changes to `claude-config` (this repo):**
- All changes are committed to git. Any skill file revert is `git checkout HEAD~1 -- skills/project-audit/SKILL.md` (or the affected file).
- New `skills/project-analyze/` directory: `git rm -r skills/project-analyze/` + commit.

**For changes to other projects (where `project-analyze` is run):**
- `ai-context/` files modified by `project-analyze` are tracked by that project's git.
- Revert command: `git checkout HEAD -- ai-context/` in the target project.
- `analysis-report.md` is a working artifact (not tracked by default if in `.gitignore`). If tracked: `git rm analysis-report.md`.

**For `project-audit` orchestrator refactor:**
- The FIX_MANIFEST format and `project-fix` interface are unchanged. If the orchestrator introduces a regression, `git revert` on the `project-audit/SKILL.md` commit restores the previous monolithic version.

## Dependencies

- `project-analyze` must be created and tested before `project-audit` D7 is rewritten to depend on it
- `openspec/config.yaml` schema extension (`analysis_targets`) is documented in this cycle but optional — existing projects without it still work (project-analyze falls back to auto-detection)
- No external dependencies — all operations use Claude's native file reading and Bash

## Success Criteria

- [ ] `skills/project-analyze/SKILL.md` exists with valid Trigger, Process, Rules, and Output sections
- [ ] `project-analyze` run on the canonical test project (Audiio V3) produces `analysis-report.md` and updates `ai-context/` without overwriting human-edited sections
- [ ] `project-audit` D7 reads `analysis-report.md` instead of sampling source files directly — verified by running `/project-audit` on a non-Next.js project and getting a meaningful D7 score
- [ ] `project-audit` warns clearly when `analysis-report.md` is absent (D7 = 0 + instruction message)
- [ ] `project-audit` overall score on `claude-config` itself is >= score from previous audit run
- [ ] `CLAUDE.md` and Skills Registry updated with `project-analyze` entry
- [ ] `ai-context/architecture.md` artifact table updated with `analysis-report.md` row
- [ ] `verify-report.md` has at least one [x] criterion checked
- [ ] `install.sh` deploys the new skill successfully (verified by `ls ~/.claude/skills/project-analyze/`)

## Effort Estimate

Medium — estimated 2-3 days:
- Day 1: `project-analyze` SKILL.md spec, design, and implementation
- Day 2: `project-audit` D7 refactor + orchestration wiring
- Day 3: Testing on Audiio V3 + `claude-config` audit score verification + SDD artifact completion
