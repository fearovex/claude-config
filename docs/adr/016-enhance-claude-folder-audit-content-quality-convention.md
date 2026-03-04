# ADR-016: Claude Folder Audit Content Quality Convention — Additive Sub-Phase Pattern for Project Mode

## Status

Accepted

## Context

The `claude-folder-audit` project mode (ADR-010) originally checked only file and directory
existence in five checks (P1–P5): whether CLAUDE.md exists, whether registered skills are
deployed, whether local skills are orphaned, and whether skill scope tiers overlap. No SKILL.md
content was read. No `ai-context/` memory layer was inspected. No CLAUDE.md content quality was
verified.

As the skill was used on real projects, it consistently produced shallow audit output — a single
LOW finding on a project with significant `.claude/` content and multiple undetected compliance
gaps. The root cause is that structural existence checks do not enforce the content contracts
defined in CLAUDE.md Unbreakable Rule 2 (SKILL.md `format:` field and section contracts per
`docs/format-types.md`) or the memory layer conventions established in ADR-015
(`ai-context/features/`).

Two extension approaches were available: (A) restructure checks into named groups with new
identifiers (A/B/C/D/E), breaking all existing P-prefixed references; or (B) attach content
quality sub-phases to their structural parent checks and append new numbered checks for wholly
new audit dimensions (P6, P7, P8). A third alternative (C) added all new checks as flat
extensions P6–P10 without sub-phase grouping, losing the logical association between a structural
check and its content quality extension.

## Decision

We will extend project-mode audit checks using an **additive sub-phase pattern**:

- Content quality extensions to an existing check are added as Phase C (or Phase D, etc.) sub-phases
  within the same check block, immediately after the structural check sub-phases (Phase A, Phase B).
  The check identifier (P1, P2, P3) remains stable; the new phase is a logical extension, not a
  new check.
- Wholly new audit dimensions that have no existing check parent are added as new numbered checks
  (P6, P7, P8, ...) appended to the project-mode check block.
- All new content quality checks are severity-capped at MEDIUM or below. HIGH severity is reserved
  exclusively for failures that prevent Claude from functioning (CLAUDE.md absent, skill not
  deployed). Content gaps are advisory signals, not blockers.
- The project-mode report template is extended to include a `## Check PN` section for each new
  numbered check.

This pattern is applied in the `enhance-claude-folder-audit` change:
- P1-Phase C: CLAUDE.md content quality (mandatory sections, line count, SDD command references)
- P2-Phase C / P3-Phase C: SKILL.md frontmatter + section contract validation per `format:` type
- P6: `ai-context/` core files presence and content length
- P7: `ai-context/features/` layer (ADR-015 V2 audit integration)
- P8: `.claude/` folder inventory (unexpected items, hooks script non-emptiness)

## Consequences

**Positive:**

- Existing P-prefixed check identifiers remain stable across the enhancement — no breaking change
  to references in documentation, remediation scripts, or human workflows.
- New content quality extensions are logically grouped with their structural parent, making the
  skill easier to read and the report easier to interpret.
- The severity cap convention (content quality <= MEDIUM, structural failures = HIGH) is
  explicitly documented and can be enforced in future extensions and in `project-audit`'s
  D4-equivalent dimensions.
- The additive sub-phase pattern creates a clear extension point for future V2 work (e.g.,
  global-mode content quality checks, config-driven `openspec/config.yaml` feature_docs activation).

**Negative:**

- Check blocks grow longer as sub-phases are added, increasing the SKILL.md size and the
  cognitive overhead of reading and modifying individual checks.
- The sub-phase naming convention (Phase A, Phase B, Phase C...) is informal — it exists only
  in the SKILL.md prose, not in any structured schema. Future contributors must know to follow
  this convention or risk creating inconsistent extension structures.
- Content quality checks depend on text-scanning heuristics (line-prefix matching) that can
  produce false positives if required sections are documented inside code fences or are indented.
  The convention documents the matching rule explicitly, but cannot eliminate the heuristic risk.
