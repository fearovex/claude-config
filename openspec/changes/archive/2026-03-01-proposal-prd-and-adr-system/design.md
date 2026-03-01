# Technical Design: proposal-prd-and-adr-system

Date: 2026-03-01
Proposal: openspec/changes/proposal-prd-and-adr-system/proposal.md

## General Approach

Introduce two lightweight documentation systems — a PRD template and an ADR convention — as purely additive Markdown files under a new `docs/` top-level directory. No skill logic changes, no config-driven behavior, and no new SKILL.md files are required. The work is: create directory structure, write templates, write 3–5 retroactive ADRs from existing `ai-context/architecture.md` decisions, and add two integration paragraphs (one in `ai-context/conventions.md`, one in `CLAUDE.md`). A `docs/` directory already exists with one file (`architecture-definition-report.md`) so `docs/adr/` and `docs/templates/` subdirectories can be created cleanly alongside it.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| ADR numbering format | `NNN-short-title.md` (three-digit zero-padded integer) | UUID-based, date-prefixed (`YYYY-MM-DD-title`) | Three-digit integers are universally understood, easily sorted, and match the Nygard convention. Date-prefix conflicts with the SDD archive naming scheme already used in `openspec/changes/archive/` — reusing that pattern in ADRs would create confusion. |
| ADR status vocabulary | `Proposed / Accepted / Deprecated / Superseded by ADR-NNN` | Custom statuses, boolean active/inactive | Nygard's four statuses are the industry standard, recognized by tooling and future contributors. They express the full lifecycle of a decision without ambiguity. |
| Retroactive ADR marking | `Accepted (retroactive)` status with a note | `Accepted` (no distinction), separate `legacy/` subdirectory | Transparency about provenance prevents misrepresenting original intent. A status note is lighter than a separate directory and does not require special tooling. |
| PRD relationship to proposal.md | PRD feeds into proposal.md — PRD is upstream input, not a replacement | PRD replaces proposal.md, PRD is an optional appendix inside proposal.md | The SDD entry point is `proposal.md`. A PRD captures product-level intent before technical framing begins. Keeping them separate preserves the SDD artifact schema and the clean separation of product vs. technical concerns. |
| Integration point in CLAUDE.md | Single paragraph in the Architecture section referencing `docs/adr/` | New table row in Available Commands, new SKILL.md for ADR creation | ADR creation is not a command — it is a convention followed during `/sdd-apply`. Adding a command row would misrepresent its nature. A prose reference in the Architecture section is accurate and sufficient. |
| Templates directory placement | `docs/templates/` | `openspec/templates/`, root-level `templates/` | `docs/` is the emerging documentation root (already contains `architecture-definition-report.md`). Placing templates there is consistent with the existing structure. `openspec/` is reserved for SDD artifacts, not reference documentation. |
| Number of retroactive ADRs | 5 (covering the 5 key architectural decisions documented in `ai-context/architecture.md`) | 3 (minimum from proposal), 7+ (all informal decisions) | The 5 decisions listed in `ai-context/architecture.md` under "Key architectural decisions" are explicitly documented and accurately sourced, making them safe to retroactively formalize. Stopping at 5 avoids over-formalizing decisions that are better left as prose. |

## Data Flow

PRD + ADR systems are documentation-only. The flow when they interact with the SDD cycle:

```
User identifies product-level change
        │
        ▼
  [optional] Create PRD using docs/templates/prd-template.md
        │
        ▼  (PRD informs the problem statement)
  /sdd-ff <change-name>
        │
        ▼
  proposal.md  ←  references PRD if one exists
        │
        ▼
  spec + design (parallel)
        │
        ▼
  tasks.md
        │
        ▼
  /sdd-apply
        │
        ▼
  If architectural decision made during apply:
        │
        ▼
  Create docs/adr/NNN-short-title.md
  using docs/templates/adr-template.md
        │
        ▼
  /sdd-verify + /sdd-archive
```

ADR index (docs/adr/README.md) is updated manually whenever a new ADR is added. No automation required.

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `docs/templates/prd-template.md` | Create | PRD template with sections: Problem Statement, Target Users, User Stories (MoSCoW), Non-Functional Requirements, Acceptance Criteria, Notes |
| `docs/templates/adr-template.md` | Create | ADR template following Nygard format: Title, Status, Context, Decision, Consequences |
| `docs/adr/README.md` | Create | ADR index: convention description, status vocabulary, usage guidance, table listing all ADRs |
| `docs/adr/001-skills-as-directories.md` | Create | Retroactive ADR: skills are directories with SKILL.md, not single files |
| `docs/adr/002-artifacts-over-memory.md` | Create | Retroactive ADR: skills communicate via file artifacts, not conversation context |
| `docs/adr/003-orchestrator-delegates-everything.md` | Create | Retroactive ADR: CLAUDE.md never executes work inline — always delegates via Task tool |
| `docs/adr/004-install-sh-repo-authoritative.md` | Create | Retroactive ADR: install.sh is the single deploy direction; sync.sh captures memory/ only |
| `docs/adr/005-skill-md-entry-point-convention.md` | Create | Retroactive ADR: SKILL.md is the mandatory, uniquely-named entry point for every skill directory |
| `ai-context/conventions.md` | Modify | Append a "PRD Convention" section explaining when to use a PRD vs. going directly to /sdd-ff |
| `CLAUDE.md` (project) | Modify | Append a note in the Architecture section referencing `docs/adr/` as the architectural decision record |
| `CLAUDE.md` (global, via install.sh) | Deployed (not edited directly) | Automatically updated when `bash install.sh` is run after repo edits |

## Interfaces and Contracts

No code interfaces. The two template "contracts" define the required sections for each document type:

**PRD template sections (required):**
```markdown
## Problem Statement       — What problem does this solve? For whom?
## Target Users            — Who are the affected users/personas?
## User Stories            — MoSCoW-prioritized: Must / Should / Could / Won't
## Non-Functional Reqs     — Performance, security, compatibility constraints
## Acceptance Criteria     — Verifiable, binary checklist
## Notes                   — Optional: open questions, links, references
```

**ADR template sections (required):**
```markdown
## Title        — Short imperative phrase (e.g., "Use SKILL.md as skill entry point")
## Status       — Proposed | Accepted | Deprecated | Superseded by ADR-NNN
## Context      — Forces at play — why was this decision needed?
## Decision     — What was decided (active voice: "We will...")
## Consequences — Trade-offs, positive and negative outcomes
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual verification | All files listed in the File Change Matrix exist and have required sections | Checklist in verify-report.md |
| Integration | `bash install.sh` completes without errors | Bash — run after all files are created |
| Regression | `/project-audit` score on claude-config is >= baseline (97/100) | /project-audit command |

No automated tests are applicable — deliverables are Markdown documentation files.

## Migration Plan

No data migration required. All changes are additive. The existing `docs/architecture-definition-report.md` is unaffected. The `ai-context/architecture.md` prose remains the authoritative source; ADRs are a complementary structured layer, not a replacement.

## Open Questions

- **ADR for `docs/adr/` itself**: The decision to introduce this ADR system could itself be recorded as ADR-006. However, self-referential bootstrapping ADRs can be confusing. Recommendation: skip for now — the `docs/adr/README.md` index explanation serves the same purpose.
- **PRD guidance placement**: The proposal specifies adding PRD guidance to `ai-context/conventions.md`. This is the correct location (it's a workflow convention). However, if the user later adds a `/prd-create` skill, the guidance would need to move to that SKILL.md. This is low risk — deferred.
