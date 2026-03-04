# ADR-015: Feature Domain Knowledge Layer — ai-context/features/ as a Named Memory Sub-Layer

## Status

Proposed

## Context

The `ai-context/` memory layer captures system-wide project memory (stack, architecture, conventions,
known-issues, changelog). It does not capture feature-level or bounded-context-level knowledge:
business rules, domain invariants, integration contracts, and known failure modes for individual
feature areas (e.g., auth, payments, notifications).

Before SDD adoption in projects, "feature-expert" reference skills served this role. When SDD was
adopted, that per-feature domain knowledge layer was not carried forward. As a result, every SDD
cycle that touches a known domain starts from zero context — the sub-agent must re-infer business
rules from code. This risks shallow specs and design decisions that violate established domain
invariants.

Two structural alternatives were considered: (A) extending `ai-context/` with a `features/`
subdirectory of free-form Markdown files, and (B) creating per-feature reference-format SKILL.md
files alongside project source code. A third alternative (C) was to enrich `openspec/specs/<domain>/spec.md`
with a permanent "Domain Context" section, conflating observable-behavior specs with business
context narrative.

The forces at play:
- Adding a `features/` subdirectory reuses the existing memory layer pattern with no new format types.
- Per-feature SKILL.md files (Approach B) would leverage format validation but do not integrate
  naturally with `memory-update` (session memory cannot be automatically written back to SKILL.md).
- Conflating domain context into spec files (Approach C) creates a two-concern file and leaves
  the proposal phase without domain context (sdd-propose does not read specs).
- The `openspec/config.yaml` already contains a commented-out `feature_docs:` block, confirming
  that feature documentation was anticipated in the system design.

## Decision

We will introduce `ai-context/features/` as a named, permanent sub-layer of the `ai-context/`
memory layer. Each file in this directory is a bounded-context knowledge document named
`<domain>.md` (e.g., `auth.md`, `payments.md`). A canonical template (`ai-context/features/_template.md`)
defines six required sections: Domain Overview, Business Rules and Invariants, Data Model Summary,
Integration Points, Decision Log, and Known Gotchas.

Write ownership is assigned exclusively:
- `memory-init` generates stub files on first-time project setup when `features/` is absent.
- `memory-update` appends session-acquired domain knowledge to existing feature files.
- `project-analyze` does NOT write to `features/` — it is an observer skill only.
- Human authors are the primary quality gate for feature file content.

The SDD phase integration is minimal and non-blocking:
- `sdd-propose` gains an optional Step 0 that reads a matching `ai-context/features/<domain>.md`
  before writing `proposal.md`. Domain matching uses a filename-stem heuristic on the change slug.
- `sdd-spec` gains the same optional Step 0 preload.
- A miss (no matching feature file) is silent — phases proceed normally.

A new `feature-domain-expert` skill (format: `reference`, placed globally in
`skills/feature-domain-expert/`) serves as the authoring guide and usage reference for this layer.

Tier 2 (per-feature SKILL.md reference skills in `.claude/skills/`) is explicitly deferred to V2
to be introduced only after the free-form `features/` convention is validated in practice.

## Consequences

**Positive:**

- Feature-level domain knowledge is captured once and automatically enriches SDD phases — reduces
  context re-discovery from code on each cycle.
- Purely additive change: no existing skill behavior is altered; no files are deleted. Rollback is
  a directory deletion and git revert.
- Consistent with the existing `ai-context/` memory pattern — no new format types or infrastructure
  required.
- Clear write-ownership rule (memory-update writes, project-analyze reads-only) prevents conflict
  between the two update mechanisms.
- Non-blocking integration: projects without `ai-context/features/` are unaffected.

**Negative:**

- Feature files are free-form Markdown with no automated structural validation in V1 — quality
  depends on author discipline and the template.
- Filename-stem heuristic matching is imprecise: a change named `add-payment-gateway` matches
  `features/payments.md` correctly, but a change named `improve-audit-pipeline` will not find
  `features/sdd-meta-system.md` without explicit annotation. Explicit `domains:` frontmatter
  is deferred to V2.
- Two related artifacts now exist for mature domains: `openspec/specs/<domain>/spec.md`
  (observable behavior) and `ai-context/features/<domain>.md` (business context). Authors must
  understand the distinction or risk duplicating content.
- Feature files can become stale over time. No automated staleness detection is included in V1.
