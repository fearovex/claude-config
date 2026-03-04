# ADR-018: Project Claude Folder Organizer Convention

## Status

Proposed

## Context

The `claude-folder-audit` skill defines a canonical P8 expected item set for project `.claude/` folders and detects structural violations as findings. A companion fix skill (`project-claude-organizer`) was anticipated in ADR-009 as future work. When implementing this companion skill, a design decision arises about how to define the canonical expected item set: should the organizer reference the same definition used by `claude-folder-audit` at runtime, or should it define the set inline as a standalone reference table? There is no runtime import or include mechanism in the SKILL.md system — skills are stateless Markdown files read by Claude. Defining the expected set in two places risks divergence. The organizer's P8 expected set must remain aligned with `claude-folder-audit`'s P8 expected set.

## Decision

We will define the canonical `.claude/` expected item set inline in `skills/project-claude-organizer/SKILL.md` as a reference table, accompanied by an explicit cross-reference comment pointing to `claude-folder-audit` Check P8. This makes the organizer skill self-contained (no runtime dependency on another skill file) while making the alignment obligation visible and auditable. When `claude-folder-audit` P8's expected set is updated in future changes, the organizer's inline table must also be updated in the same SDD change — the cross-reference comment is the coupling contract.

## Consequences

**Positive:**

- The organizer skill is self-contained and can be invoked without relying on any other skill being readable at runtime.
- The cross-reference comment makes the coupling between the two skills explicit and traceable by any reviewer.
- The pattern is consistent with how all other skills in this repo handle shared reference data — inline definition with commentary.

**Negative:**

- The expected item set is defined in two places (the organizer and `claude-folder-audit`), introducing a manual sync obligation for future changes that modify the P8 expected set.
- There is no automated enforcement of the sync; keeping the two definitions aligned depends on the SDD change author remembering the cross-reference.
