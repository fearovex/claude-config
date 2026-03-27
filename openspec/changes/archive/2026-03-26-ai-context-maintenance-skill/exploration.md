# Exploration: ai-context-maintenance-skill

## Handoff Context

No pre-seeded proposal.md found — proceeding without handoff context.

---

## Current State

### Governance

Governance loaded: 7 unbreakable rules, tech stack: Markdown + YAML + Bash, intent classification: enabled

NOTE: `ai-context/stack.md` last updated 2026-03-06 — context may be stale. Consider running /memory-update or /project-analyze.
NOTE: `ai-context/conventions.md` last updated 2026-02-23 — context may be stale. Consider running /memory-update or /project-analyze.
NOTE: `ai-context/known-issues.md` last updated 2026-03-06 — context may be stale. Consider running /memory-update or /project-analyze.

Spec context loaded from index: memory-management/spec.md (keyword match: `memory`, `ai-context`)

### Memory Layer Files

`ai-context/` contains:
- `stack.md` — tech stack
- `architecture.md` — architectural decisions
- `conventions.md` — naming patterns
- `known-issues.md` — known issues + gotchas
- `changelog-ai.md` — 2373 lines, newest-first log of AI-assisted changes
- `onboarding.md` — external onboarding sequence
- `quick-reference.md` — single-page SDD quick reference
- `scenarios.md` — 6-case onboarding guide
- `features/` — bounded-context domain knowledge files

**No existing `ai-context/index.md` file** — the index entry point does not currently exist.

### Current Skills Related to Memory Layer

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `memory-init` | `/memory-init` | Generates 5 core ai-context/ files from scratch |
| `memory-update` | `/memory-update` | Incrementally updates ai-context/ files after a session |
| `codebase-teach` | `/codebase-teach` | Fills `ai-context/features/` from source code reading |
| `project-analyze` | `/project-analyze` | Deep codebase scan; updates `[auto-updated]` sections |
| `project-audit` | `/project-audit` | Audits SDD config health; produces `audit-report.md` |

None of these skills performs periodic maintenance of the memory layer itself (archiving old entries, separating open/resolved issues, generating an index entry point, detecting CLAUDE.md gaps).

### changelog-ai.md Growth

The changelog has grown to **2373 lines**. It is a prepend-only append log. There is no archiving mechanism. As the file grows, it is increasingly expensive to load in a context window and becomes less useful as a quick-reference for recent decisions.

### known-issues.md Structure

`known-issues.md` has no formal OPEN vs RESOLVED separation. Looking at its content:
- All items listed appear to be known issues with some marked as FIXED inline (e.g., "CRLF line endings break bash scripts (FIXED)")
- No `## Resolved Issues` section yet (though `memory-update` Step 5 mentions moving resolved issues to `## Resolved Issues`)
- The file does not grow as fast as changelog-ai.md but the same problem of accumulation applies

### ai-context/index.md

No `index.md` file exists. There is no single-page entry point that summarizes what files exist in `ai-context/`, when each was last updated, what each covers, and how to navigate the memory layer.

### CLAUDE.md Active Constraints Section

The global `CLAUDE.md` does NOT have an "Active Constraints" section at the top. The file starts with `## Identity and Purpose`. This is a feature the proposed skill would flag — it's a detection-only capability, not something the maintenance skill would create automatically.

### Naming Convention Analysis

Meta-tool skills follow the pattern `[category]-[action]`. Candidates:
- `memory-maintain` — consistent with `memory-init`, `memory-update` family
- `memory-gc` — "gc" for garbage collection (like `sdd-spec-gc`)
- `ai-context-audit` — more specific but deviates from `memory-*` prefix
- `memory-housekeeping` — readable but slightly non-standard

The `memory-*` prefix family is the cleanest fit since the skill operates on the `ai-context/` memory layer. `memory-maintain` follows the `memory-init` / `memory-update` verb pattern.

Slash command: `/memory-maintain`

---

## Branch Diff

INFO: branch diff unavailable or empty — git status returned no modified files.

---

## Prior Attempts

Prior archived changes related to this topic (keyword: `memory`, `context`, `maintenance`, `audit`):

- `2026-02-28-integrate-memory-into-sdd-cycle`: COMPLETED (memory layer integration with SDD phases)
- `2026-03-04-project-claude-organizer-memory-layer`: COMPLETED (memory layer added to organizer skill)
- `2026-03-10-sdd-project-context-awareness`: COMPLETED (context loading across sub-agent boundaries)
- `2026-03-12-fix-subagent-project-context`: COMPLETED (context loading fix for sub-agents)
- `2026-03-19-2026-03-18-context-handoff-between-sessions`: COMPLETED (cross-session context handoff)
- `2026-03-22-slim-orchestrator-context`: COMPLETED (reduced orchestrator context size to ~20k chars)

No prior attempts found for a dedicated maintenance/cleanup skill for ai-context/ files. This is a new capability gap.

---

## Contradiction Analysis

- Item: `memory-update` Step 5 mentions "Resolved issues: move them to a `## Resolved Issues` section"
  Status: UNCERTAIN — `memory-update` already has a resolved-issues move instruction, but it only applies within the current session. The proposed skill's `known-issues.md` cleanup feature would do a one-time audit of existing accumulated items. This is complementary, not contradictory.
  Severity: INFO
  Resolution: Clarify in proposal that `memory-maintain` handles backlog cleanup; `memory-update` handles session-by-session updates.

- Item: `memory-management` spec (REQ: memory-update feature file update path) — feature files can only be updated, never created by `memory-update`.
  Status: UNCERTAIN — The maintenance skill would audit feature files but not create or update them, so no conflict.
  Severity: INFO
  Resolution: No action needed — the maintenance skill is read-only or structurally reorganizes existing files.

- Item: No contradictions found between the proposed features and existing specs.

---

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `skills/` | New directory + SKILL.md | New skill: `memory-maintain/SKILL.md` |
| `ai-context/changelog-ai.md` | Written by skill | Archives old entries to `changelog-ai-archive.md` |
| `ai-context/changelog-ai-archive.md` | Created by skill | New file — receives archived changelog entries |
| `ai-context/known-issues.md` | Written by skill | Separates RESOLVED items to archive file |
| `ai-context/known-issues-archive.md` | Created by skill | New file — receives resolved known-issues entries |
| `ai-context/index.md` | Created by skill | New file — entry point for the memory layer |
| `CLAUDE.md` (project) | Read-only by skill | Flagged if missing "Active Constraints" section |
| `CLAUDE.md` global | Read-only by skill | Flagged if missing "Active Constraints" section |
| `openspec/specs/memory-management/spec.md` | Delta spec needed | New requirements for the maintenance skill |
| `openspec/specs/index.yaml` | New entry needed | New domain `memory-maintenance` or `memory-maintain` |
| `CLAUDE.md` Skills Registry | Registration needed | New command entry: `/memory-maintain` |

---

## Analyzed Approaches

### Approach A: Standalone `memory-maintain` skill (Recommended)

**Description**: Create a new skill in `skills/memory-maintain/SKILL.md` with a `/memory-maintain` trigger. The skill performs all 5 maintenance operations as steps in a single procedural flow: (1) changelog archiving, (2) known-issues separation, (3) index.md generation/update, (4) CLAUDE.md Active Constraints detection. The user runs it periodically (e.g., after 5+ SDD cycles or when files get large).

**Pros**:
- Fits cleanly into the `memory-*` skill family (`memory-init`, `memory-update`, `memory-maintain`)
- Single command, composable steps — user can skip steps by editing or answering prompts
- No changes to existing skills — purely additive
- Consistent with how `sdd-spec-gc` handles cleanup for specs

**Cons**:
- Adds one more command to the catalog — users need to know to run it
- `changelog-ai-archive.md` and `known-issues-archive.md` are new file conventions — need to be documented

**Estimated effort**: Medium (1 SKILL.md + delta spec + spec index entry + CLAUDE.md update)
**Risk**: Low

---

### Approach B: Extend `memory-update` with housekeeping logic

**Description**: Add a Step 7 "Housekeeping" to the existing `memory-update` skill. After updating the standard files, check if `changelog-ai.md` exceeds a threshold (e.g., 100 entries), and if so, prompt to archive old entries.

**Pros**:
- No new command to learn — maintenance is automatic at session end
- Changelog threshold check is triggered naturally

**Cons**:
- `memory-update` becomes a larger, more complex skill (currently ~150 lines — adding 5 features would ~double it)
- Mixes concerns: session recording vs. periodic maintenance
- Harder to invoke independently (can't run "just the archiving" without a full session update)
- Would require modifying an existing skill — needs its own SDD cycle anyway

**Estimated effort**: Medium (modifying existing skill + delta spec)
**Risk**: Medium — risk of regression in core memory-update behavior

---

### Approach C: Extend `project-audit` with memory health dimension

**Description**: Add a new dimension D15 to `project-audit` that checks ai-context/ file sizes, flags large files, detects resolved issues in known-issues.md, and recommends running a dedicated tool. The audit would flag but not fix.

**Pros**:
- Audit-only approach: no risk of corrupting memory files
- User already runs `/project-audit` periodically

**Cons**:
- Does not implement the actual cleanup — user still needs a separate step
- `project-audit` is already large (7 scored + 8 informational dimensions)
- CLAUDE.md Active Constraints detection could be a dimension but the fix action still needs to be documented elsewhere
- Does not address the core request (cleanup, not just detection)

**Estimated effort**: Low for audit-only; Medium if combined with a fix companion
**Risk**: Low

---

## Recommendation

**Approach A — Standalone `memory-maintain` skill** is recommended.

Rationale:
1. It cleanly mirrors `sdd-spec-gc` (which handles spec cleanup) as the memory-layer equivalent
2. The `memory-*` prefix family is established and intuitive
3. No risk of regression in existing skills
4. All 5 requested features fit naturally as ordered steps in a procedural SKILL.md
5. Archive file conventions (`changelog-ai-archive.md`, `known-issues-archive.md`) are simple extensions of the established pattern

The skill should be clearly scoped as **periodic maintenance** — not a replacement for `memory-update`. A recommended cadence of "after every 5 SDD cycles or when changelog-ai.md exceeds 100 entries" should be documented in the skill's `## Purpose` section.

**Key design decisions to settle in proposal:**
1. What is the default `N` for "keep last N entries" in changelog archiving? (Suggest: 30 entries)
2. Should `index.md` generation be idempotent (update existing) or always regenerate? (Suggest: update)
3. Should the CLAUDE.md Active Constraints check flag a WARNING or just an INFO note? (Suggest: INFO — advisory only)
4. Should the skill be interactive (confirm before each step) or non-interactive (run all steps, report at end)?

---

## Identified Risks

- **Archive file conventions are new**: `changelog-ai-archive.md` and `known-issues-archive.md` are not currently documented in `ai-context/conventions.md` or the specs. The proposal should include updating those docs.
  Impact: Low — can be addressed in the same SDD cycle.

- **`index.md` naming collision**: `ai-context/index.md` is a new file that doesn't exist yet. Need to verify no SDD skill currently creates a file with that name in `ai-context/`.
  Impact: Low — confirmed absent in current directory listing.

- **Marker-awareness gap**: `ai-context/` files that contain `[auto-updated]` sections (written by `/project-analyze`) must not be corrupted by the maintenance skill. The skill must respect those marker boundaries.
  Impact: Low — explicitly callout in skill rules.

- **CLAUDE.md Active Constraints detection scope**: The requirement is to "detect if CLAUDE.md is missing an 'Active Constraints' section." However, this section does not exist in the current global CLAUDE.md by design — it may be a convention for project-local CLAUDE.md files only. Needs clarification in the proposal.
  Impact: Medium — scope of detection (global vs. project) should be decided in proposal.

---

## Open Questions

1. Should `memory-maintain` operate on **global** `~/.claude/ai-context/` (this repo) or **project-local** `ai-context/` or both?
2. What is the threshold for "old entries" in changelog-ai.md — count-based (e.g., keep last 30) or date-based (e.g., keep last 90 days)?
3. Is the "Active Constraints" section a real planned convention or is it ad-hoc? If it's a new convention, the proposal should define it and add it to the spec.
4. Should `index.md` be a static summary (generated once and maintained) or a dynamic table (regenerated every run)?
5. Should the skill be added to the global catalog only, or should it be registered in the project CLAUDE.md as well?

---

## Ready for Proposal

**Yes** — enough context exists to write a focused proposal. The approach is clear (Approach A), the naming is settled (`memory-maintain`), the affected files are identified, and the open questions are scoped. The proposal should address the 5 open questions above before the spec phase.
