# Technical Design: sdd-cycle-prd-adr-integration

Date: 2026-03-01
Proposal: openspec/changes/sdd-cycle-prd-adr-integration/proposal.md

## General Approach

Two additive steps are inserted into existing skills — one in `sdd-propose` (PRD shell generation after `proposal.md` is written) and one in `sdd-design` (ADR creation after `design.md` is written). Both steps are non-blocking: failure or skip conditions produce a warning in the orchestrator output but do not halt the cycle. `openspec/config.yaml` and `CLAUDE.md` receive documentation-only additions describing the new optional artifacts.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| PRD detection by file existence | Check `openspec/changes/<name>/prd.md` before creating | Check proposal.md metadata, require explicit flag | File presence is the simplest idempotent guard — no state beyond the filesystem. Consistent with how `sdd-propose` already checks for `exploration.md`. |
| PRD creation as template copy + frontmatter fill | Copy `docs/templates/prd-template.md`, fill title/date/related-change in frontmatter | Generate PRD content from proposal via LLM inference | Proposal explicitly excludes automated LLM-generated content. Template copy is deterministic, auditable, and zero-risk of hallucinated requirements. |
| ADR significance heuristic: keyword scan of Technical Decisions table | Flag a decision as significant if it matches cross-cutting keywords (pattern, convention, cross-cutting, replaces, introduces, architecture) | Require explicit `[ADR]` tag in design.md, always create ADR, never create ADR | Keyword scan is conservative and requires no change to the design.md format. User can always delete a spurious ADR; missing a real one is worse. Explicit tagging adds ceremony that contradicts the non-blocking intent. |
| ADR number determination at runtime | Count existing `NNN-*.md` files in `docs/adr/` + 1 | Parse README.md index, maintain a counter in config.yaml | Filesystem count is authoritative and collision-resistant even if README.md drifts. Does not require parsing markdown tables. |
| ADR slug from change-name + decision keyword | Derive slug as `<change-name>-<keyword>` truncated to reasonable length | UUID, timestamp, free-form input | Change-name + keyword produces a human-readable, traceable slug without requiring user input at skill execution time. |
| config.yaml update: add `optional_artifacts` key | New top-level key under `testing:` block | Inline comment only, separate file, separate section | Mirrors the existing `required_artifacts_per_change` pattern. YAML key is machine-readable for future tooling while human-readable as documentation. |
| CLAUDE.md update: extend artifact tree only | Add `prd.md (optional)` inside change directory and `docs/adr/` subtree at project level | Add prose paragraph, add new top-level section | The existing ASCII tree in "SDD Artifact Storage" is the canonical reference. Extending it in-place keeps all artifact information in one place. |

## Data Flow

### PRD integration in sdd-propose

```
sdd-propose Step 4 (write proposal.md) completes
      │
      ▼
Step 5: PRD Shell Generation
      │
      ├─ Check: does openspec/changes/<name>/prd.md exist?
      │         YES → skip (log: "PRD already exists, skipping")
      │         NO  → continue
      │
      ├─ Check: does docs/templates/prd-template.md exist?
      │         NO  → log warning "PRD template not found, skipping" → exit step (non-blocking)
      │         YES → continue
      │
      ├─ Copy template to openspec/changes/<name>/prd.md
      ├─ Fill frontmatter:
      │     title: <change-name> (spaces replaced with hyphens)
      │     date: <current date YYYY-MM-DD>
      │     related-change: openspec/changes/<name>
      │
      └─ Add prd.md to artifacts list in orchestrator output
             │
             ▼
Step 6: Summary to orchestrator (was Step 5)
```

### ADR integration in sdd-design

```
sdd-design Step 3 (write design.md) completes
      │
      ▼
Step 4: ADR Detection and Generation
      │
      ├─ Scan Technical Decisions table in design.md
      │   Look for rows containing any of these keywords (case-insensitive):
      │     pattern, convention, cross-cutting, replaces, introduces,
      │     architecture, global, system-wide, breaking
      │
      ├─ Significant decisions found?
      │         NO  → skip silently, proceed to Step 5
      │         YES → continue
      │
      ├─ Determine next ADR number:
      │     Count files matching docs/adr/[0-9][0-9][0-9]-*.md
      │     next_n = count + 1, zero-padded to 3 digits
      │
      ├─ Derive slug:
      │     <NNN>-<change-name>[-<first-matched-keyword>]
      │     Truncate to 50 chars max, lowercase, hyphens only
      │
      ├─ Copy docs/templates/adr-template.md to docs/adr/<slug>.md
      ├─ Pre-fill:
      │     Title line: "ADR-<NNN>: <change-name> — <decision summary>"
      │     Status: Proposed
      │     Context: extracted from the matching decision row (Justification column)
      │     Decision: "We will <Choice column text>"
      │     Consequences section left for human completion
      │
      ├─ Append entry to docs/adr/README.md ADR Index table:
      │     | [<NNN>](<slug>.md) | <title> | Proposed |
      │
      └─ Add docs/adr/<slug>.md to artifacts list
             │
             ▼
Step 5: Summary to orchestrator (was Step 4)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-propose/SKILL.md` | Modify | Insert Step 5 (PRD shell generation) between current Step 4 and Step 5; renumber old Step 5 to Step 6 |
| `skills/sdd-design/SKILL.md` | Modify | Insert Step 4 (ADR detection and generation) between current Step 3 and Step 4; renumber old Step 4 to Step 5 |
| `openspec/config.yaml` | Modify | Add `optional_artifacts` key under `testing:` section listing `prd.md` and `docs/adr/NNN-*.md` |
| `CLAUDE.md` | Modify | Extend SDD Artifact Storage ASCII tree to show `prd.md (optional)` under change directory and `docs/adr/` subtree at project root level |

## Interfaces and Contracts

### PRD frontmatter contract (filled by sdd-propose Step 5)

```yaml
---
title: <change-name>
status: Draft
author: <!-- Your name or team -->
date: <YYYY-MM-DD>
related-change: openspec/changes/<change-name>
---
```

Lines with `<!-- ... -->` placeholders are left in place for the human to fill.

### ADR pre-fill contract (filled by sdd-design Step 4)

```markdown
# ADR-<NNN>: <change-name> — <decision summary>

## Status

Proposed

## Context

<Justification column text from the matching Technical Decisions row>

## Decision

We will <Choice column text from the matching row>

## Consequences

**Positive:**

- <!-- Benefit 1 -->

**Negative:**

- <!-- Trade-off or constraint 1 -->
```

The `Consequences` section is intentionally left as template placeholders. The skill fills only what it can derive mechanically; human judgment completes the rest.

### openspec/config.yaml optional_artifacts addition

```yaml
testing:
  # ... existing keys ...
  optional_artifacts:
    - "prd.md"           # created by sdd-propose if template exists and no prd.md present
    - "docs/adr/NNN-*.md"  # created by sdd-design when a significant architectural decision is detected
```

### CLAUDE.md SDD Artifact Storage extension

```
openspec/
├── config.yaml
├── specs/
│   └── {domain}/spec.md
└── changes/
    ├── {change-name}/
    │   ├── exploration.md
    │   ├── proposal.md
    │   ├── prd.md            ← optional; created by sdd-propose if template exists
    │   ├── specs/{domain}/spec.md
    │   ├── design.md
    │   ├── tasks.md
    │   └── verify-report.md
    └── archive/
        └── YYYY-MM-DD-{name}/

docs/
└── adr/
    ├── README.md             ← updated by sdd-design when a new ADR is created
    └── NNN-<slug>.md         ← optional; created by sdd-design when a significant architectural decision is detected
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — PRD idempotency | Run sdd-propose twice on the same change; confirm prd.md not overwritten | Manual file inspection |
| Manual — PRD skip on missing template | Temporarily rename template; confirm propose completes without error | Manual + git restore |
| Manual — ADR creation | Run sdd-design on a change whose design.md contains "introduces a new pattern"; confirm ADR file created and README.md updated | Manual file inspection |
| Manual — ADR skip | Run sdd-design on a change with no significant decision keywords; confirm no ADR file created | Manual file inspection |
| Integration — full cycle | Run /sdd-ff on a new change end-to-end; confirm all expected artifacts present | /project-audit + file listing |

No automated test framework is applicable — the "code" is Markdown skill instructions executed by an LLM agent. Testing is behavioral and verified by /project-audit.

## Migration Plan

No data migration required. Both changes are purely additive:
- No existing `prd.md` files exist in any change directory (confirmed by directory scan).
- No existing ADR files will be touched by the new step.
- The `openspec/config.yaml` and `CLAUDE.md` changes are documentation additions that do not affect any existing behavior.

## Open Questions

None. All design decisions are resolved based on the proposal scope, existing templates, and current skill patterns.
