# Proposal: proposal-prd-and-adr-system

Date: 2026-03-01
Status: Draft

## Intent

Introduce a PRD (Product Requirements Document) template for structured change proposals and an ADR (Architecture Decision Records) system for documenting architectural decisions, giving the project a lightweight but formal way to capture both product-level intent and architectural rationale.

## Motivation

Currently, the SDD cycle starts with `proposal.md`, which covers intent and scope but is optimized for technical change tracking rather than product-level requirements. Two gaps exist:

1. **No PRD layer**: When a change originates from a user/product need, there is no standard format to capture stakeholder requirements, user stories, or acceptance criteria before entering the SDD cycle. The existing `proposal.md` format conflates product intent with technical approach.

2. **No ADR system**: Architectural decisions (e.g., "skills communicate only via file artifacts", "orchestrator never executes work inline") are currently documented informally inside `ai-context/architecture.md` as prose. There is no structured, queryable record with explicit decision status, context, and consequences. New contributors (human or AI) cannot easily discover why a decision was made or whether it is still active.

As the system grows, undocumented architectural decisions become a source of drift and inconsistency.

## Scope

### Included

- A PRD template file (`docs/templates/prd-template.md`) following standard PRD structure (problem, users, requirements, acceptance criteria)
- A skill or guidance document explaining when to use a PRD vs. going directly to `/sdd-ff`
- An ADR directory convention (`docs/adr/`) with a numbered ADR template (`docs/templates/adr-template.md`)
- A `docs/adr/README.md` index that describes the convention and lists existing ADRs
- Retroactive ADRs for the 3–5 most significant architectural decisions already in place (e.g., skills-as-directories, artifacts-over-memory, orchestrator-delegates-everything)
- Integration guidance in `CLAUDE.md` or `ai-context/conventions.md` pointing to both systems

### Excluded (explicitly out of scope)

- Automation of ADR creation via a new `/adr-create` skill — this is a future candidate but adds complexity not needed now
- Enforcement of PRD-before-SDD as a hard gate in the SDD flow — the PRD is advisory, not blocking
- Migrating existing `ai-context/architecture.md` prose into ADRs — the existing file remains authoritative; ADRs complement, not replace it
- Changes to `openspec/config.yaml` schema — no config-driven ADR integration at this stage
- Integration with external tools (Notion, Confluence, GitHub Discussions)

## Proposed Approach

**PRD template**: Create a Markdown template at `docs/templates/prd-template.md` with sections for: problem statement, target users, user stories (MoSCoW priority), non-functional requirements, and acceptance criteria. Add a usage note in `ai-context/conventions.md` clarifying that a PRD is appropriate when a change has user-facing product implications, and that it feeds into the `proposal.md` (SDD entry point) rather than replacing it.

**ADR system**: Adopt the established Markdown ADR convention (inspired by Michael Nygard's format). Each ADR is a numbered file `docs/adr/NNN-short-title.md` with sections: Title, Status (Proposed / Accepted / Deprecated / Superseded), Context, Decision, Consequences. Create the directory, a template, a README index, and 3–5 retroactive ADRs capturing decisions already embedded in the architecture.

**No new skills needed**: Both systems are documentation conventions, not automation. The existing SDD cycle absorbs them naturally — a PRD can precede `/sdd-ff`, and an ADR can be created as part of `/sdd-apply` when a significant architectural choice is made.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `docs/` directory | New (created) | Low — new top-level directory, does not affect runtime |
| `docs/templates/prd-template.md` | New | Low — reference artifact only |
| `docs/templates/adr-template.md` | New | Low — reference artifact only |
| `docs/adr/` directory + README | New | Low — documentation only |
| `docs/adr/NNN-*.md` (3–5 files) | New | Low — retroactive decision records |
| `ai-context/conventions.md` | Modified | Low — adds PRD usage guidance paragraph |
| `CLAUDE.md` (project + global) | Modified | Low — adds reference to ADR and PRD conventions |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ADR format becomes stale and is not maintained | Medium | Low | Keep ADR scope narrow (architectural, not operational); enforce via verify-report checklist |
| PRD template adds friction to small changes | Low | Low | Explicitly document that PRD is optional for purely technical changes |
| Retroactive ADRs misrepresent original intent | Low | Medium | Mark all retroactive ADRs as "Accepted (retroactive)" with a note; draw from existing `ai-context/architecture.md` prose |
| `docs/` directory conflicts with existing project conventions | Low | Low | Project has no existing `docs/` directory; no naming conflict detected |

## Rollback Plan

Both systems are purely additive documentation artifacts. Rollback procedure:

1. Delete `docs/` directory: `rm -rf docs/`
2. Revert changes to `ai-context/conventions.md` and `CLAUDE.md` via `git revert` or manual removal of added paragraphs
3. Run `bash install.sh` to redeploy reverted config
4. Commit with message: `revert: remove PRD and ADR systems`

No code execution paths, no config-driven behavior, and no skill logic changes are involved. The rollback is safe and lossless.

## Dependencies

- None: `docs/` directory does not exist yet and can be created freely
- Existing `ai-context/architecture.md` must be read before writing retroactive ADRs to ensure accuracy
- `CLAUDE.md` edits must be consistent between repo root and the deployed `~/.claude/CLAUDE.md` (via `install.sh`)

## Success Criteria

- [ ] `docs/templates/prd-template.md` exists with all required sections (problem, users, user stories, acceptance criteria)
- [ ] `docs/templates/adr-template.md` exists following the Nygard ADR format (Title, Status, Context, Decision, Consequences)
- [ ] `docs/adr/README.md` exists and lists at least 3 ADRs
- [ ] At least 3 retroactive ADRs exist in `docs/adr/` covering key architectural decisions
- [ ] `ai-context/conventions.md` contains a paragraph explaining when to use a PRD
- [ ] `CLAUDE.md` references the `docs/adr/` convention so new sessions are aware of it
- [ ] `bash install.sh` completes without errors after all files are added
- [ ] `/project-audit` score on claude-config does not drop below the current baseline

## Effort Estimate

Low (hours) — all deliverables are Markdown files; no skill logic changes required. The main work is writing accurate retroactive ADRs from existing architecture documentation.
