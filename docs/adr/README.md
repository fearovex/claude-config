# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the claude-config system. An ADR captures a significant architectural decision: the context that motivated it, the decision itself, and its consequences.

---

## Naming Convention

ADR filenames follow the pattern:

```
NNN-short-title.md
```

- `NNN` — zero-padded three-digit sequential number (e.g., `001`, `042`)
- `short-title` — lowercase, hyphen-separated summary of the decision topic (e.g., `skills-as-directories`)

Examples: `001-skills-as-directories.md`, `042-new-caching-strategy.md`

---

## Numbering Scheme

Numbers are assigned sequentially starting from `001`. Once assigned, a number is never reused, even if the ADR is deprecated or superseded. The number identifies the record permanently.

---

## Status Vocabulary

| Status | Meaning |
|--------|---------|
| `Proposed` | The decision is under discussion and has not yet been accepted |
| `Accepted` | The decision was made and is currently in effect |
| `Accepted (retroactive)` | The decision was made before the ADR system existed and is recorded retroactively to document the rationale |
| `Deprecated` | The decision was once accepted but is no longer in effect; no replacement exists |
| `Superseded by ADR-NNN` | The decision has been replaced by a newer ADR (reference the superseding ADR number) |

---

## Lifecycle

1. **Proposed** — Create the ADR file with status `Proposed` and open it for review.
2. **Accepted** — Update the status to `Accepted` once the decision is approved. Commit the file.
3. **Superseded** — If a later decision replaces this one, update the status to `Superseded by ADR-NNN` and create the new ADR. Do not delete the old record.
4. **Deprecated** — If a decision is retired with no replacement, update the status to `Deprecated`.

ADR files are append-only by convention: once accepted, the original Context, Decision, and Consequences sections are not rewritten. Add a note at the top of the file if significant clarification is needed after acceptance.

---

## ADR Index

| Number | Title | Status |
|--------|-------|--------|
| [001](001-skills-as-directories.md) | Skills are directories, not single files | Accepted (retroactive) |
| [002](002-artifacts-over-memory.md) | Skills communicate via file artifacts, not conversation context | Accepted (retroactive) |
| [003](003-orchestrator-delegates-everything.md) | Orchestrator (CLAUDE.md) never executes work inline | Accepted (retroactive) |
| [004](004-install-sh-repo-authoritative.md) | install.sh is the single authoritative deploy direction | Accepted (retroactive) |
| [005](005-skill-md-entry-point-convention.md) | SKILL.md is the mandatory, uniquely-named entry point for every skill directory | Accepted (retroactive) |
| [006](006-audit-improvements-convention.md) | New audit dimensions default to informational-only until explicitly promoted to scored | Proposed |
| [007](007-skill-format-types-convention.md) | Skill format types convention — `format:` frontmatter field distinguishes procedural, reference, and anti-pattern skills | Proposed |
