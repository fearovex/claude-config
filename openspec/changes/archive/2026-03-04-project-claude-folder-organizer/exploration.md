# Exploration: project-claude-folder-organizer

## Current State

### What currently exists

The SDD meta-system has two tools that touch the `.claude/` folder of projects:

1. **`claude-folder-audit`** — A read-only audit skill (P1–P8 checks) that diagnoses the health of a project's `.claude/` configuration. It detects missing CLAUDE.md, unregistered skills, orphaned artifacts, memory layer gaps, and unexpected items. It produces `claude-folder-audit-report.md`. It is STRICTLY read-only — it identifies problems but never reorganizes anything.

2. **`project-setup`** — Creates the initial project scaffolding: `CLAUDE.md`, `ai-context/` (5 files), and `openspec/config.yaml`. It does not place files inside `.claude/` — it creates files at the project root.

3. **`project-fix`** — Reads `audit-report.md` from `project-audit` and applies fixes. It can create `.claude/CLAUDE.md`, register skills, and create `ai-context/` stubs. However, its scope is limited to what `project-audit` identifies — it does not organize the `.claude/` folder structure as a whole.

### What files/directories accumulate in a project's .claude/ folder

Based on the `claude-folder-audit` skill (Check P8 expected item set) and the `claude-code-expert` reference skill, a project's `.claude/` directory can contain:

**Defined/expected items (per claude-folder-audit P8):**
- `CLAUDE.md` — project memory file
- `skills/` — local skill copies (added via `/skill-add`)
- `audit-report.md` — output of `/project-audit`
- `claude-folder-audit-report.md` — output of `/claude-folder-audit`
- `settings.json` — Claude Code configuration
- `settings.local.json` — local machine-specific config (not committed)
- `openspec/` — SDD artifacts (some projects place these inside .claude/)
- `ai-context/` — memory layer (some projects place these inside .claude/)
- `hooks/` — event hook scripts

**Items not in the P8 expected set but known to accumulate (undefined territory):**
- `commands/` — legacy Claude Code slash commands directory (deprecated; project-setup and project-fix explicitly prohibit creating it)
- `agents/` — Claude Code agents (referenced in claude-code-expert)
- Any analysis, exploration, or one-off files placed manually

**Gap identified:** The expected set in P8 is defined as a hardcoded list, but there is no skill that actively ORGANIZES or RESTRUCTURES an existing `.claude/` folder. The `claude-folder-audit` detects anomalies; nobody fixes the structure.

### How the current .claude/ runtime folder accumulates noise

Looking at `~/.claude/` (the runtime, not a project), it accumulates Claude Code internal directories that are NOT part of the user-managed config:
- `backups/`, `cache/`, `debug/`, `file-history/`, `history.jsonl`, `ide/`, `image-cache/`, `paste-cache/`, `plans/`, `plugins/`, `projects/`, `shell-snapshots/`, `stats-cache.json/`, `statsig/`, `tasks/`, `telemetry/`, `todos/`

This is the root of the known issue documented in `known-issues.md`: Check 4 of `claude-folder-audit` generates false-positive MEDIUM findings because these runtime directories are not in the allowlist.

### What is missing

There is currently **no skill** that:
1. Reads a project's `.claude/` folder and proposes a reorganization plan
2. Detects and migrates legacy patterns (`commands/` → `skills/`)
3. Moves misplaced files to their canonical locations
4. Establishes the SDD-compliant folder structure when it is absent or partial
5. Produces a canonical `.claude/` state from a messy or ad-hoc accumulation

---

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `skills/claude-folder-audit/SKILL.md` | High — closely related | The audit detects problems; the organizer would fix them |
| `skills/project-setup/SKILL.md` | Medium — overlapping concern | project-setup creates initial structure but doesn't fix existing .claude/ |
| `skills/project-fix/SKILL.md` | Medium — parallel tool | project-fix fixes audit findings; organizer is about structural reorganization |
| `CLAUDE.md` (global) | Low — needs registry entry | Any new skill must be registered |
| `docs/adr/README.md` | Low — may need ADR | A new architectural decision for the organizer pattern |
| `openspec/specs/` | Low — may need spec | A new master spec for `.claude/` canonical structure |
| `known-issues.md` | Low — related bug | The Check 4 false-positive issue is adjacent to this scope |

---

## Analyzed Approaches

### Approach A: New standalone `project-claude-organizer` skill

**Description**: Create a new skill dedicated entirely to organizing a project's `.claude/` folder. When invoked as `/project-claude-organizer` (or `/claude-organize`), it:
1. Reads the current `.claude/` folder contents
2. Identifies deviations from the canonical structure
3. Proposes a reorganization plan (which files to move, create, or flag for deletion)
4. After user confirmation, applies the restructuring
5. Updates CLAUDE.md Skills Registry if needed
6. Writes a brief report of what was changed

**Pros**:
- Single responsibility — does exactly one thing
- Does not complicate existing skills (`claude-folder-audit`, `project-fix`)
- Can be independently improved or versioned
- Follows the established pattern: one concern = one skill directory

**Cons**:
- Adds a new command users need to learn
- Some overlap with `project-fix` (both apply corrections to `.claude/`)
- Risk of divergence: both skills need to know the canonical `.claude/` structure

**Estimated effort**: Medium (1 new SKILL.md + 1 SDD cycle)
**Risk**: Low — additive change, no breaking modifications to existing skills

---

### Approach B: Extend `project-fix` with a `.claude/` reorganization phase

**Description**: Add a new phase to `project-fix` that, after applying audit-report.md corrections, also reorganizes the `.claude/` folder structure. The organizer logic is embedded inside `project-fix` as a new "Phase 6 — `.claude/` Folder Normalization".

**Pros**:
- No new command — users already know `/project-fix`
- Keeps the audit→fix pipeline consolidated
- Fewer SKILL.md files to maintain

**Cons**:
- `project-fix` already delegates to sub-agents per phase; adding a phase that does structural reorganization changes its nature
- `project-fix` operates from `audit-report.md` as its spec — the organizer needs to read the live `.claude/` folder, not the audit report
- Increases `project-fix` scope and complexity significantly
- Breaking change to `project-fix` semantics (currently it ONLY implements FIX_MANIFEST items)

**Estimated effort**: Medium-High (modifying a critical skill + full SDD cycle required for breaking changes)
**Risk**: Medium — modifies a core meta-tool, risk of regression

---

### Approach C: Extend `claude-folder-audit` with an apply mode

**Description**: Add an `--apply` or `--fix` flag to `claude-folder-audit` that changes it from read-only to read-write. When run with the apply mode, it reorganizes what it detects.

**Pros**:
- Single skill handles both audit and fix for `.claude/` folder

**Cons**:
- `claude-folder-audit` is explicitly defined as "strictly read-only" (its SKILL.md and ADR-009/010 both specify this)
- ADR-009 states: "V1 is read-only; auto-fix companion (`claude-folder-fix`) is future work" — a write mode was explicitly deferred
- Changing the read-only contract of an existing skill is a high-risk ADR-breaking change
- The audit skill already has extensive logic (P1–P8, 8 checks) — adding write mode makes it very large

**Estimated effort**: High (requires modifying a core skill with an ADR-mandated read-only contract)
**Risk**: High — violates ADR-009 read-only constraint

---

### Approach D: Two-skill pipeline (new `claude-folder-plan` + extend `claude-folder-audit`)

**Description**: Create a lightweight planning skill (`claude-folder-plan`) that reads the `.claude/` folder and produces a `claude-folder-plan.md` reorganization plan. A separate apply step (either manual or via a future `claude-folder-apply`) implements the plan.

**Pros**:
- Aligns with SDD philosophy: separate plan and apply phases
- Keeps the audit skill read-only (respects ADR-009)
- Planning phase alone has immediate value even without an apply phase

**Cons**:
- Two new skills to learn and maintain
- The planning output (a plan file) doesn't directly map to the existing artifact communication pattern
- Over-engineering for what is essentially a reorganization operation

**Estimated effort**: High (two skills, two SDD cycles, more coordination)
**Risk**: Low individually, but fragmented user experience

---

## Recommendation

**Approach A — New standalone `project-claude-organizer` skill** is the recommended approach.

Rationale:
1. **Single responsibility**: The existing `claude-folder-audit` audits; the new skill organizes. These are distinct verbs and distinct user needs.
2. **No ADR violations**: Approach C and B both require modifying skills with explicitly defined read-only or narrow-scope contracts.
3. **Aligns with ADR-009**: That ADR explicitly anticipated a "companion" fix skill (`claude-folder-fix`) as future work. The organizer is exactly this companion.
4. **Established pattern**: The `project-audit` → `project-fix` pairing is the model. Similarly, `claude-folder-audit` → new companion skill is the natural extension.
5. **Incremental value**: The skill can be minimal in V1 (detect + propose + apply canonical structure) and extended later with migration of legacy patterns (`commands/` → `skills/`).

**Recommended skill name**: `project-claude-organizer`
- Follows the `project-[action]` naming convention for meta-tools
- Distinguishes it from `claude-folder-audit` (the read-only sister skill)

**Scope for V1**:
1. Detect the project's `.claude/` folder state
2. Compare against the canonical SDD `.claude/` structure
3. Detect: missing CLAUDE.md, missing `skills/`, legacy `commands/` directory, misplaced files
4. Propose a reorganization (create missing directories/files, flag unexpected items for user review)
5. After user confirmation, apply the changes
6. Write a brief completion report

**Out of scope for V1**:
- Migrating content from `commands/` to `skills/` (content migration is complex — structural cleanup first)
- Reorganizing `ai-context/` or `openspec/` (those are handled by `memory-init` and `project-setup`)
- Updating `~/.claude/` (the runtime) — the organizer targets project `.claude/` folders only

---

## Identified Risks

- **Overlap with `project-fix`**: Both skills can create `.claude/CLAUDE.md` and `skills/` directories. This could cause confusion about which to run first. Mitigation: document in both skills that `project-fix` targets audit-report.md items while `project-claude-organizer` targets structural organization independently of any audit report.

- **Canonical structure definition**: The skill needs a clear canonical `.claude/` structure definition. Currently this is implicitly defined in `claude-folder-audit` Check P8's expected item set. Mitigation: extract the canonical structure definition into the organizer skill's SKILL.md as a reference table, and ensure both skills reference the same definition.

- **Confirmation UX**: Unlike read-only skills, the organizer writes to the project. User confirmation before applying changes is essential to prevent accidental restructuring. Mitigation: implement a dry-run preview step before any writes (similar to `config-export` which has a dry-run mode).

- **Windows path handling**: The project runs on Windows (Git Bash). Path normalization using `$USERPROFILE` instead of `~` is required. Mitigation: follow the same path normalization pattern as `claude-folder-audit` (Step 1 path resolution chain).

---

## Open Questions

1. **Canonical structure source of truth**: Should the canonical `.claude/` structure be defined in the organizer skill only, or should it be extracted into a shared spec (e.g., `openspec/specs/claude-folder-canonical/spec.md`) that both `claude-folder-audit` and `project-claude-organizer` reference?

2. **Relationship to `project-fix`**: Should the organizer be invocable from within `project-fix` (as a sub-step), or should it remain entirely independent? Making it a sub-step would provide a unified "fix everything" experience but increases coupling.

3. **ADR needed?**: Given that ADR-009 already anticipates a companion fix skill, does this organizer require a new ADR, or is it simply implementing the deferred "future work" item from ADR-009?

4. **Handling `.claude/commands/` migration**: If a project has a `commands/` directory with actual command files, should the organizer offer to migrate those to `skills/`, or just flag them as legacy and defer to the user? The content migration (`.md` command → `SKILL.md` with frontmatter) is non-trivial.

5. **Trigger name**: `/project-claude-organizer` is descriptive but verbose. Alternatives: `/claude-organize`, `/project-organize`, `/claude-folder-fix`. The `project-[action]` naming convention would suggest `/project-organize` but that is too generic.

---

## Ready for Proposal

**Yes** — the exploration reveals a clear gap (no skill exists to reorganize a project's `.claude/` folder), a well-defined recommended approach (Approach A: new standalone skill), and a focused V1 scope. The change is additive, non-breaking, and aligns with the existing `claude-folder-audit` → companion pattern anticipated by ADR-009.

The main open questions (canonical structure definition location, ADR requirement, trigger naming) can be resolved in the proposal and design phases.
