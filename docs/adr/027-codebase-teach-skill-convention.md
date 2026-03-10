# ADR-027: Codebase Teach Skill Convention — Manual Domain Knowledge Extraction into ai-context/features/

## Status

Proposed

## Context

SDD phase skills load project context via `ai-context/features/<domain>.md` files on every run
(Step 0b domain preload). However, these files are only populated through three paths: manual
authoring, `memory-init` scaffolding (stubs with placeholder text), and `memory-update` (session
decisions). No skill specifically analyzes existing source code to extract business rules,
invariants, and data model summaries into the features layer. This gap means that feature files
often remain as stubs, and SDD phases operate without meaningful domain enrichment even on mature
codebases. A dedicated analysis skill is needed to bridge the gap between source code and the
domain knowledge layer.

## Decision

We will introduce a new procedural meta-tool skill `codebase-teach` that, when manually invoked,
scans the project's bounded context directories, reads up to a configurable maximum of
implementation files per context (default 10, configurable via `openspec/config.yaml`
`teach_max_files_per_context`), extracts business rules and domain knowledge, and writes or
updates `ai-context/features/<context>.md` files using the `[auto-updated]` marker convention.
The skill also produces a `teach-report.md` with coverage metrics. `codebase-teach` is manual-only
— it is never invoked automatically by other skills.

## Consequences

**Positive:**

- `ai-context/features/` files can be populated from real source code, not just from session memory or manual authoring.
- SDD phase preloading (sdd-propose Step 0b, sdd-spec Step 0b) becomes more effective as feature files gain substantive content.
- The `[auto-updated]` marker convention from `project-analyze` is extended to feature files, preserving human-authored sections while allowing AI-refreshed sections.
- Consistent with the meta-tool pattern: one directory, one SKILL.md, registered in CLAUDE.md.

**Negative:**

- AI-extracted business rules may be incorrect or incomplete — the `[auto-updated]` marker signals that human review is required before treating extracted content as authoritative.
- Large codebases with many bounded contexts require sequential processing to stay within context window limits; a full run may be slow.
- Adds one more meta-tool that users must remember to run; codebase teaching is not automated.
