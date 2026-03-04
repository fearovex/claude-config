# ADR-020: Project Claude Organizer Smart Migration Pattern

## Status

Proposed

## Context

The `project-claude-organizer` skill classifies items found in a project's `.claude/` directory into three buckets: MISSING_REQUIRED, PRESENT, and UNEXPECTED. Items in the UNEXPECTED bucket currently receive a generic "review manually" flag with no actionable guidance. In practice, real projects accumulate a predictable set of legacy directories that predate formal SDD adoption: `commands/`, `docs/`, `system/`, `plans/`, `requirements/`, `sops/`, `templates/`, and root-level overview files. Each has a well-defined SDD-compliant destination. Without a classification layer for these known patterns, every migration to the SDD layout requires the operator to manually determine the destination — defeating the purpose of a structural assistant. The change also introduces the first instance of a skill-to-skill advisory pattern (where the organizer recommends invocation of `/skill-create` for `commands/` content rather than auto-invoking it), which establishes a boundary for organizer authority.

## Decision

We will add a "Legacy Directory Intelligence" layer (Step 3b) to `project-claude-organizer` that intercepts UNEXPECTED items whose names match 8 predefined legacy patterns and reclassifies them into a LEGACY_MIGRATIONS collection before the dry-run plan is presented. Each matched item carries a strategy (SKILL_ADVISORY, AI_CONTEXT_FEATURES, AI_CONTEXT_SYSTEM, OPENSPEC_CHANGES, OPENSPEC_PROPOSALS, DUAL_DEST_CHOICE, DOCS_TEMPLATES, or AI_CONTEXT_SECTIONS), one or more destination paths, and a per-category user confirmation requirement. Items matching no pattern remain in UNEXPECTED unchanged. Pattern matching is limited to top-level `.claude/` items only — no recursive scanning. The `commands/` pattern uses advisory-only delegation: the organizer surfaces a recommendation; the operator invokes `/skill-create` separately. All writes are strictly additive (copy or scaffold only — no deletes, overwrites, or moves of source files).

## Consequences

**Positive:**

- Operators migrating legacy Claude Code projects to the SDD layout receive concrete, actionable migration destinations for the 8 most common legacy patterns instead of a generic "review manually" flag
- The advisory model for `commands/` establishes a clear boundary: the organizer is an advisor, not an orchestrator — it does not invoke other skills autonomously
- The top-level-only scope constraint prevents unbounded recursive processing and maintains the existing performance characteristic of the skill
- All changes are gated by user confirmation, so false positives (a `docs/` directory that does not follow the expected convention) cause no harm

**Negative:**

- The SKILL.md grows significantly in length; readability is maintained only through disciplined sub-section structure and the pattern table format
- The 8 patterns are hardcoded — any new legacy pattern requires a future SDD change (no auto-discovery)
- The `plans/` active-vs-archived distinction requires per-item user input because no automated signal reliably distinguishes active from archived plan files
