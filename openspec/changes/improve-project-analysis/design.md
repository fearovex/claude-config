# Technical Design: improve-project-analysis

Date: 2026-02-27
Proposal: openspec/changes/improve-project-analysis/proposal.md

---

## General Approach

Create a new `project-analyze` skill that performs deep, framework-agnostic codebase analysis and writes structured output to both `analysis-report.md` (transient working artifact) and `ai-context/` (permanent memory with `[auto-updated]` section protection). Refactor `project-audit` to invoke `project-analyze` as a sub-step within Phase A, then use `analysis-report.md` as the data source for a rewritten, framework-agnostic D7. The file-based artifact handoff mirrors the existing `audit-report.md → project-fix` pattern — no in-memory coupling between skills.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Sub-skill invocation model | `project-audit` calls `project-analyze` as a sequential sub-step inside Phase A, reading its output file after completion | Parallel Task launch; embedding analysis directly in D7 | Sequential is simpler and guarantees `analysis-report.md` exists before D7 scoring. Parallel would be valid but adds orchestration complexity with no time benefit since D7 depends on the analysis output. Embedding in D7 would re-create the existing monolithic problem. |
| `[auto-updated]` section protection | Marker placed as a H3/H4 heading comment immediately before auto-generated content blocks; unmarked sections are never touched | Full-file overwrite; line-by-line diff | Full-file overwrite silently destroys human edits — rejected. Line-by-line diff is complex and fragile. Section-marker approach is the same pattern used by many static site generators and is reversible via git. |
| `analysis-report.md` location | Project root (alongside `audit-report.md`) | `.claude/analysis-report.md`; `openspec/` | Project root keeps both diagnostic reports co-located and visible. `.claude/` is reserved for Claude config layer artifacts. `openspec/` is SDD artifacts, not diagnostics. |
| D7 scoring input | `analysis-report.md` drift section (binary: documented architecture matches observed / drifted) | Continue sampling source code in D7; remove D7 entirely | Sampling source code in D7 is the current failing approach — rejected. Removing D7 reduces the audit score max and breaks backward compatibility with existing projects' score history. Binary drift score is simple, verifiable, and framework-agnostic. |
| Context window protection | Configurable sample size via `openspec/config.yaml` key `analysis.max_sample_files` (default: 20); if key absent, default applies | Unlimited sampling; fixed hardcoded limit | Unlimited sampling risks context overflow on large repos. Fixed hardcoded limit is better but `openspec/config.yaml` already provides a config-driven extension point (proven by `feature_docs:` key in D10). Following the same pattern maintains consistency. |
| `project-analyze` responsibility boundary | Observes and describes only — never scores, never produces FIX_MANIFEST entries | Allow project-analyze to emit warnings that feed FIX_MANIFEST | Allowing project-analyze to produce FIX_MANIFEST entries creates two sources of truth for corrections (project-audit and project-analyze). Strict single-responsibility: analyze = describe, audit = score and diagnose. |
| Stack detection approach | Manifest-first (package.json, requirements.txt, pom.xml, build.gradle, go.mod, Cargo.toml, mix.exs), fall back to file extension sampling | Framework-specific heuristics; user-declared only | Manifest-first is framework-agnostic and works for all known package ecosystems. File extension fallback handles projects with no standard manifest (e.g., pure Bash, pure Markdown). User-declared config (`analysis_targets`) is an override, not the primary detection method. |
| `analysis-report.md` staleness guard | `project-audit` emits a warning (D7 = 0 + instruction message) if `analysis-report.md` is absent; adds `Last analyzed:` date field if present but older than 7 days | Blocking error; silent skip | Blocking error is too disruptive for first runs. Silent skip produces confusing scores. Warning with explicit instruction is the existing pattern used by `project-fix` for stale `audit-report.md`. |

---

## Data Flow

```
/project-audit invoked
        │
        ▼
  Phase A — Discovery Bash batch (unchanged)
  + Phase A extension: invoke project-analyze sub-step
        │
        │  project-analyze sub-agent:
        │    1. Stack detection (manifests → file extensions fallback)
        │    2. Structure mapping (folder tree → organization pattern)
        │    3. Convention sampling (up to N files, configurable)
        │    4. Architecture drift detection (observed vs architecture.md)
        │    5. ai-context/ update ([auto-updated] sections only)
        │    6. Write analysis-report.md
        │
        ▼
  analysis-report.md  ←─────────────── written to project root
        │
        ▼
  Phase B — Dimension scoring
        │
        ├── D1, D2, D3, D4, D6, D8 — unchanged logic
        │
        └── D7 (rewritten):
              Read analysis-report.md → Drift section
              If absent: score = 0, emit instruction
              If present: score = 5 if no drift detected,
                          score = 2 if minor drift (informational entries only),
                          score = 0 if critical drift (structural mismatches)
        │
        ▼
  audit-report.md assembled (D7 score now sourced from analysis-report.md)
        │
        ▼
  /project-fix reads audit-report.md (unchanged interface)
```

```
project-analyze internal flow:

  openspec/config.yaml
        │
        ▼  read analysis.max_sample_files (default: 20)
        │  read analysis.analysis_targets (optional overrides)
        │
        ▼
  Manifest detection (parallel read attempts):
    package.json / requirements.txt / pom.xml / build.gradle /
    go.mod / Cargo.toml / mix.exs / pyproject.toml / composer.json
        │
        ▼  if no manifest found → file extension sampling
        │
        ▼
  Folder structure mapping (ls -la style read, 2 levels deep)
        │
        ▼
  Source file sampling (up to max_sample_files, distributed
  across detected source directories proportionally)
        │
        ▼
  ai-context/architecture.md read (if exists) → drift comparison
        │
        ▼
  ai-context/ update ([auto-updated] sections only)
        │
        ▼
  analysis-report.md write
```

---

## analysis-report.md Structure

The file is written to `[project_root]/analysis-report.md`. It has a fixed section structure so that `project-audit` D7 can reliably parse it without fragile heuristics.

```markdown
# Analysis Report — [Project Name]

Last analyzed: [YYYY-MM-DD HH:MM]
Analyzer: project-analyze
Config: sample_size=[N], targets=[auto-detected|configured]

---

## Summary

[3-5 line human-readable summary of what the project is and how it is structured]

Stack detected: [language(s)] / [framework(s)] / [database if any]
Organization pattern: [feature-based|layer-based|monorepo|flat|mixed|unknown]
Architecture drift: [none|minor|significant]
Conventions documented: [yes|partial|no]

---

## Stack

Source: [manifest filename(s) | file-extension-sampling]

| Category | Detected | Source |
|----------|----------|--------|
| Language | [value] | [manifest key or extension count] |
| Framework | [value] | [manifest key] |
| Database | [value] | [manifest key or none] |
| Testing | [value] | [manifest key or test file pattern] |
| Build tool | [value] | [manifest key or config file] |

Key dependencies (top 10 by apparent importance):
| Package | Version | Inferred purpose |
|---------|---------|-----------------|
| [name] | [version] | [inferred] |

---

## Structure

Organization pattern: [feature-based|layer-based|monorepo|flat|mixed|unknown]
Confidence: [high|medium|low] — [reason]

Top-level layout:
```
[folder tree, 2 levels deep, annotated with detected purpose]
```

Source root(s): [list of detected source directories]
Test root(s): [list of detected test directories, or "none detected"]
Entry point(s): [list of detected entry points]

---

## Conventions Observed

Sample size: [N] files across [M] directories

### Naming
- Files: [detected pattern: kebab-case|snake_case|PascalCase|mixed]
  Example: [concrete file name from sample]
- Functions/methods: [detected: camelCase|snake_case|PascalCase|mixed]
  Example: [concrete function name from sample]
- Classes/types: [detected pattern]
  Example: [concrete type name from sample]
- Constants: [detected pattern]
  Example: [concrete constant from sample]

### Import style
[Detected pattern: absolute|relative|alias-based|mixed]
Example: [concrete import from sample]

### Error handling
[Detected pattern: try/catch|Result type|exceptions|mixed|not detected]
Example: [concrete pattern from sample]

### Module/layer boundaries
[Detected: what calls what, based on import graph sampling]

---

## Architecture Drift

[This section is the primary input for project-audit D7]

Basis for comparison: [ai-context/architecture.md exists|ai-context/architecture.md not found — no drift comparison possible]

### Documented vs Observed

| Documented (architecture.md) | Observed in repo | Status |
|------------------------------|------------------|--------|
| [folder/pattern documented] | [what was found] | ✅ match / ⚠️ minor drift / ❌ significant drift |

### Drift Summary

[none|minor|significant]

Drift entries:
- [description of each discrepancy, if any]
  - Documented: [what architecture.md says]
  - Observed: [what was actually found]
  - Impact: [informational|architectural]

[If no drift: "No structural drift detected between architecture.md and observed folder structure."]
[If architecture.md not found: "No architecture.md found — drift comparison not possible. D7 will score 0 until architecture.md is created (via /memory-init or manually)."]

---

## ai-context/ Update Log

Files modified:
- [filename]: [what was updated — which [auto-updated] sections]
- [filename]: [unchanged — no auto-updated sections found with differences]

Human-edited sections preserved:
- [filename] → [section headings that were left untouched]

[If no ai-context/ exists: "ai-context/ not found — no update performed. Run /memory-init to create the memory layer."]
```

**Downstream consumption rules:**
- `project-audit D7` reads only the `## Architecture Drift` section, specifically the `Drift Summary` line (`none|minor|significant`) and the `Drift entries` list.
- The `## Summary` block's `Architecture drift:` field is a human-readable duplicate of the same data.
- All other sections are for human consumption or future sub-skill consumption.

---

## `[auto-updated]` Marker Strategy for ai-context/

The challenge: `project-analyze` must update `ai-context/` files with fresh observed facts without overwriting sections that a human (or `memory-manager`) has written with context that cannot be re-derived from the code alone.

### Marker syntax

Auto-updated sections are delimited by HTML comment markers placed as headings:

```markdown
<!-- [auto-updated]: stack-detection — last run: 2026-02-27 -->
## Stack (auto-detected)

[content written by project-analyze]

<!-- [/auto-updated] -->
```

Rules:
1. `project-analyze` ONLY writes inside `<!-- [auto-updated]: <section-id> -->` ... `<!-- [/auto-updated] -->` blocks.
2. Any content outside those markers is never read for modification — only read for context.
3. If the opening marker exists, `project-analyze` replaces the entire block between the markers (inclusive).
4. If the opening marker does NOT exist in the file, `project-analyze` APPENDS a new auto-updated block at the end of the file rather than inserting inline — preserving all existing content.
5. If `ai-context/` does not exist, `project-analyze` does NOT create it — it notes this in the `## ai-context/ Update Log` section of `analysis-report.md` and instructs the user to run `/memory-init` first.

### Section IDs per file

Each auto-updated block has a unique `section-id` so multiple auto-updated sections can coexist in one file:

| File | section-id | What is written |
|------|-----------|-----------------|
| `ai-context/stack.md` | `stack-detection` | Auto-detected stack table from manifests |
| `ai-context/architecture.md` | `structure-mapping` | Observed folder tree + organization pattern |
| `ai-context/architecture.md` | `drift-summary` | Summary of last drift detection run |
| `ai-context/conventions.md` | `observed-conventions` | Naming, import style, error handling from samples |

`known-issues.md` and `changelog-ai.md` are NOT written by `project-analyze` — they require human context (`known-issues`) or chronological append logic (`changelog-ai`, handled by `memory-manager`).

### Merge algorithm (per file)

```
READ full file content
PARSE: split into blocks:
  - auto-updated block: starts at <!-- [auto-updated]: X --> and ends at <!-- [/auto-updated] -->
  - human block: everything else

FOR each auto-updated block project-analyze wants to write:
  IF matching <!-- [auto-updated]: section-id --> found in file:
    REPLACE content between markers with new content
    UPDATE the "last run" date in the opening marker
  ELSE:
    APPEND new block at end of file

WRITE updated file
```

This algorithm is deterministic and idempotent: running `project-analyze` twice produces the same file state.

---

## D7 Redesign

### Current D7 (deprecated)

D7 currently samples 3 API routes, 3 domain services, 2 components and checks for framework-specific indicators (PrismaClient, withSegmentAPI). It is effectively Next.js/Prisma-only.

### New D7 (reads from analysis-report.md)

D7 becomes a consumer of `project-analyze` output rather than a direct code reader.

**Input**: `analysis-report.md` — `## Architecture Drift` section.

**Scoring logic:**

| Condition | Score | Status |
|-----------|-------|--------|
| `analysis-report.md` absent | 0/5 | ❌ CRITICAL — emit: "Run /project-analyze first. D7 requires analysis-report.md." |
| `analysis-report.md` present, `ai-context/architecture.md` absent | 2/5 | ⚠️ HIGH — emit: "No architecture.md found. Create it via /memory-init then re-run /project-analyze for full D7 score." |
| Drift summary = `none` | 5/5 | ✅ |
| Drift summary = `minor` | 3/5 | ⚠️ MEDIUM — list informational drift entries |
| Drift summary = `significant` | 0/5 | ❌ HIGH — list structural mismatch entries |

**FIX_MANIFEST behavior:** D7 violations are NOT added to `required_actions` — architecture drift is informational and cannot be auto-corrected by `project-fix` (it requires human architectural decisions). D7 violations go in the `violations[]` list (same as today).

**Staleness warning:** If `analysis-report.md` exists but its `Last analyzed:` date is older than 7 days, D7 emits a warning:
```
⚠️ analysis-report.md is [N] days old. Re-run /project-analyze for accurate D7 scoring.
```
Score is still computed from the existing report (not zeroed out).

---

## project-audit Orchestration Pattern

The existing `project-audit` is NOT refactored into a full Task-tool orchestrator (that is deferred to a follow-on change, as stated in the proposal's Excluded section). Instead, the minimal change is:

**Phase A extension**: After the existing Bash discovery batch completes, `project-audit` adds a sub-step:

```
Phase A — Bash discovery batch (unchanged)
        ↓
Phase A extension — project-analyze sub-step:
  1. Check if analysis-report.md exists and age
  2. If absent or if user passes --fresh flag: invoke project-analyze
  3. Read analysis-report.md into Phase B state
        ↓
Phase B — Dimension scoring (D7 now reads analysis-report.md)
```

**Invocation contract**: `project-audit` does NOT spawn a Task sub-agent for `project-analyze`. Instead, it reads `~/.claude/skills/project-analyze/SKILL.md` and instructs the Claude agent to execute it inline (same session context). This is the minimal viable integration — it avoids Task tool overhead for a simple sequential operation.

**Why not Task tool here?** The SDD orchestrator pattern (Task tool delegation) is appropriate when phases are independent and context-heavy. `project-analyze` is lightweight and must complete before D7 can score — sequential inline execution is simpler and has no correctness downside. Full Task-tool orchestration of project-audit sub-skills is deferred as noted in the proposal.

**State passing**: Via file only — `project-analyze` writes `analysis-report.md`; `project-audit` reads it. No in-memory state is passed between the two skills.

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-analyze/SKILL.md` | Create | New skill: full process, rules, output format |
| `skills/project-audit/SKILL.md` | Modify | Phase A extension (project-analyze sub-step) + D7 complete rewrite |
| `CLAUDE.md` | Modify | `project-analyze` added to meta-tools table and Skills Registry |
| `ai-context/architecture.md` | Modify | `analysis-report.md` row added to artifact table |
| `openspec/config.yaml` | Modify | `analysis` optional key documented (comment block, like existing `feature_docs` comment) |

No files are deleted. No existing skill interfaces are broken.

---

## project-analyze SKILL.md Architecture

The skill has the standard four sections required by the Unbreakable Rules:

### Trigger definition
```
/project-analyze — deep framework-agnostic project analysis
Triggers: /project-analyze, analyze project, project analysis, understand project codebase
Also invoked by: project-audit Phase A extension (internal)
```

### Process steps (6 steps)

**Step 1 — Read config** (max 1 Bash call)
Read `openspec/config.yaml` to extract:
- `analysis.max_sample_files` (default: 20)
- `analysis.analysis_targets` (optional explicit file list — overrides auto-sampling)
- `analysis.exclude_dirs` (optional — directories to skip, e.g. `node_modules`, `.git`)

**Step 2 — Stack detection** (max 1 Bash call — manifest existence check)
Attempt to read in order: `package.json`, `pyproject.toml`, `requirements.txt`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `mix.exs`, `composer.json`. Read the first one(s) found. If none found, use file extension distribution (via Bash: `find . -name "*.X" | head -5` per extension) to determine dominant language.

**Step 3 — Structure mapping** (max 1 Bash call — tree listing)
Run `ls -la` + `find [project_root] -maxdepth 2 -type d` to get the 2-level folder tree. Identify:
- Organization pattern from directory names (features/, modules/, domain/, layers/ → feature-based; api/, services/, components/, models/ → layer-based; packages/ with multiple package.json → monorepo; everything at root → flat)
- Source roots: directories containing source files vs config/data directories
- Test roots: directories named test/, tests/, spec/, __tests__/, or containing test files

**Step 4 — Convention sampling** (max 1 Bash call — multi-file read batch)
Select up to `max_sample_files` source files distributed proportionally across detected source directories. Build a single Bash command that reads them all. From the sample, observe:
- File naming patterns (basename analysis)
- Function/class naming (regex over content)
- Import style (relative vs absolute vs alias)
- Error handling patterns (try/catch, Result, panic, etc.)

**Step 5 — Architecture drift detection** (reads ai-context/architecture.md)
Read `ai-context/architecture.md` if it exists. Extract:
- Documented folder structure (any fenced code block after `## Folder Structure`)
- Documented architectural decisions (table rows)
- Documented entry points
Compare each documented path/pattern against what Step 3 observed. Classify each as: match / minor drift / significant drift.

**Step 6 — Write outputs**
- Update `ai-context/` files using the `[auto-updated]` marker strategy
- Write `analysis-report.md` to project root
- Print summary to user

### Rules section
- NEVER scores or assigns severity levels to findings — descriptions only
- NEVER produces FIX_MANIFEST entries
- NEVER modifies content outside `[auto-updated]` markers
- NEVER creates `ai-context/` if it does not exist (instructs user to run `/memory-init`)
- Maximum 5 Bash calls per execution (Steps 1+2 share 1, Step 3 = 1, Step 4 = 1, Step 5 reads a file = 0 Bash, Step 6 = 0 Bash = total 3 Bash calls)
- Always writes `Last analyzed:` date to `analysis-report.md`
- Always reports which sections of `ai-context/` were updated vs preserved

### Output format
`analysis-report.md` at project root (format defined in the "analysis-report.md Structure" section above).

---

## Interfaces and Contracts

### openspec/config.yaml — new optional `analysis` key

```yaml
# analysis (optional) — Configuration for /project-analyze
# Without this section, project-analyze uses safe defaults.
#
# analysis:
#   max_sample_files: 20        # max source files to read during convention sampling
#   exclude_dirs:               # directories to exclude from all analysis
#     - node_modules
#     - .git
#     - dist
#     - build
#   analysis_targets:           # explicit file list (overrides auto-sampling)
#     - src/index.ts
#     - src/domain/user/user.service.ts
```

This follows the exact same pattern as the existing `feature_docs` optional key — documented as a comment block, enabling opt-in configuration without breaking existing projects.

### analysis-report.md — D7 consumption contract

D7 must be able to parse `analysis-report.md` by reading:
1. The `Last analyzed:` field in line 3 (for staleness check)
2. The `Architecture drift:` field in the `## Summary` block (for quick status)
3. The `Drift Summary` line under `## Architecture Drift` (for scoring)
4. The `Drift entries:` list under `## Architecture Drift` (for FIX_MANIFEST violations)

These four items are at fixed positions in a fixed section structure — D7 does not need to parse arbitrary markdown.

### ai-context/ update contract

`project-analyze` only writes to files that already exist. It never creates new ai-context/ files. Boundary with `memory-manager`:
- `memory-manager /memory-init` — creates all 5 ai-context/ files from scratch for a new project
- `project-analyze` — updates specific `[auto-updated]` sections in existing files based on re-analysis
- `memory-manager /memory-update` — updates files based on session work (human-driven, not analysis-driven)

---

## Testing Strategy

| Layer | What to test | How |
|-------|-------------|-----|
| project-analyze skill | Run on `claude-config` itself (Markdown/YAML/Bash project) — verify analysis-report.md is produced with correct sections | Manual run + visual inspection |
| project-analyze skill | Run on Audiio V3 (Next.js/TypeScript) — verify stack detected correctly, ai-context/ [auto-updated] sections updated without overwriting human content | Manual run + git diff on ai-context/ |
| project-analyze [auto-updated] | Add a human comment in ai-context/stack.md outside markers, run project-analyze twice — verify comment persists | Manual + git diff |
| D7 rewrite | Run /project-audit on claude-config — verify D7 score is 5/5 (architecture.md matches observed structure) | Manual run, read audit-report.md D7 section |
| D7 rewrite | Run /project-audit on a project with no analysis-report.md — verify D7 = 0 with clear instruction message | Manual run |
| D7 rewrite | Run /project-audit on Audiio V3 (non-Next.js D7 was previously broken) — verify a meaningful score is returned | Manual run |
| Backward compatibility | Run /project-audit on claude-config — verify overall score >= previous score (75+) | Manual run, compare to last audit-report.md |

No automated tests (this is a Markdown/Bash skill system; integration tests are manual audit runs per the `openspec/config.yaml` testing strategy).

---

## Migration Plan

No data migration required. The changes are purely additive:
- New skill file created
- Existing skill file modified (D7 section replaced, Phase A extended)
- No existing artifact formats changed
- `project-fix` interface unchanged (reads audit-report.md FIX_MANIFEST as before)
- Projects that have not run `project-analyze` yet will see D7 = 0 with a clear instruction on their next `project-audit` run — this is a deliberate degradation that guides users toward the correct workflow

---

## Approach Comparison

The proposal's Approach C (full responsibility split) was considered during design:

| Approach | D7 quality | project-audit complexity | Implementation effort | Breaking changes |
|----------|-----------|-------------------------|----------------------|-----------------|
| **A (chosen): project-analyze as sub-step + file handoff** | High — framework-agnostic, analysis-report.md driven | Low increase — one added Phase A step | Medium | None |
| B: enhance D7 inline | Medium — still in project-audit, still limited by Rule 8 | High increase — more Bash calls, larger SKILL.md | Low | None |
| C: full responsibility split (Task tool orchestration) | High | Rewrite project-audit entirely | High | Yes — audit score formula changes, user workflow changes |

Approach A is the right balance: it achieves the quality goal of framework-agnostic D7 with the minimum structural change to the existing audit → fix pipeline.

---

## Open Questions

None — all open questions from the exploration were resolved in the proposal:

1. **Output target**: Both `analysis-report.md` (transient) and `ai-context/` (permanent with markers) — resolved.
2. **Trigger point**: On-demand (`/project-analyze`) plus automatically invoked by `project-audit` Phase A — resolved.
3. **Framework detection**: Manifest-first, file-extension fallback, config-driven override via `analysis_targets` — resolved.
4. **D7 fate in this cycle**: Rewritten in same cycle to read `analysis-report.md` — resolved (not deferred).
