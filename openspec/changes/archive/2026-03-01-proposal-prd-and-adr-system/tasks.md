# Task Plan: proposal-prd-and-adr-system

Date: 2026-03-01
Design: openspec/changes/proposal-prd-and-adr-system/design.md

## Progress: 13/13 tasks

---

## Phase 1: Directory Structure and Templates

- [x] 1.1 Create `docs/templates/prd-template.md` — PRD template with all required sections in order: Problem Statement, Target Users, User Stories (MoSCoW: Must/Should/Could/Won't), Non-Functional Requirements, Acceptance Criteria, Notes — each section MUST include a placeholder comment or instruction (e.g., `<!-- describe the problem here -->`)
- [x] 1.2 Create `docs/templates/adr-template.md` — ADR template following the Nygard format with all required sections in order: Title (H1), Status (listing all valid values: Proposed / Accepted / Deprecated / Superseded by ADR-NNN), Context, Decision, Consequences — each section MUST include a placeholder instruction

## Phase 2: ADR Index and Retroactive ADRs

- [x] 2.1 Create `docs/adr/README.md` — ADR index explaining: naming convention (`NNN-short-title.md`), numbering scheme (zero-padded three-digit sequential), status vocabulary (Proposed / Accepted / Deprecated / Superseded), lifecycle guidance, and a table listing all 5 ADRs (number, title, current status) that will be created in tasks 2.2–2.6
- [x] 2.2 Create `docs/adr/001-skills-as-directories.md` — Retroactive ADR: "Skills are directories, not single files"; Status: `Accepted (retroactive)`; Context: needs to explain forces that led to the directory approach; Decision: every skill is a directory with a uniquely-named `SKILL.md` entry point; Consequences: allows co-locating templates and examples, requires stricter naming discipline; add retroactive note stating this decision predates the ADR system
- [x] 2.3 Create `docs/adr/002-artifacts-over-memory.md` — Retroactive ADR: "Skills communicate via file artifacts, not conversation context"; Status: `Accepted (retroactive)`; Context: long SDD chains require state to persist across sub-agent boundaries; Decision: all inter-skill state is passed through named file artifacts (list concrete examples from `ai-context/architecture.md`: audit-report.md, tasks.md, analysis-report.md, etc.); Consequences: deterministic handoffs but requires artifact discipline; add retroactive note
- [x] 2.4 Create `docs/adr/003-orchestrator-delegates-everything.md` — Retroactive ADR: "Orchestrator (CLAUDE.md) never executes work inline"; Status: `Accepted (retroactive)`; Context: monolithic execution in one context window leads to context overflow and poor separation of concerns; Decision: global CLAUDE.md always spawns sub-agents via Task tool for each SDD phase — it never writes specs, proposals, or implementation directly; Consequences: clean separation, fresh context per phase, but requires discipline in orchestrator skills; add retroactive note
- [x] 2.5 Create `docs/adr/004-install-sh-repo-authoritative.md` — Retroactive ADR: "install.sh is the single authoritative deploy direction"; Status: `Accepted (retroactive)`; Context: editing `~/.claude/` directly leads to divergence with the repo; Decision: all directories flow repo → `~/.claude/` via `install.sh`; `sync.sh` is the ONLY reverse direction and captures `memory/` only; NEVER edit `~/.claude/` directly; Consequences: single source of truth in repo, requires install.sh run after every config change; add retroactive note
- [x] 2.6 Create `docs/adr/005-skill-md-entry-point-convention.md` — Retroactive ADR: "SKILL.md is the mandatory, uniquely-named entry point for every skill directory"; Status: `Accepted (retroactive)`; Context: skills need a predictable, discoverable entry point — arbitrary filenames make routing ambiguous; Decision: every skill directory contains exactly one file named `SKILL.md` (UPPER_CASE, no alternatives); Consequences: Claude can locate any skill without scanning; naming is strict; add retroactive note

## Phase 3: Integration — Modify Existing Files

- [x] 3.1 Modify `ai-context/conventions.md` — append a new section titled "PRD Convention" (after the existing "SDD workflow for this repo" section) that explains: (a) PRD is optional for purely technical changes, (b) PRD is recommended for user-facing or product-level changes, (c) PRD precedes `proposal.md` and feeds into it — it does not replace it, (d) template is at `docs/templates/prd-template.md`; must not contradict the existing SDD workflow description
- [x] 3.2 Modify `CLAUDE.md` (project root) — add a brief reference to both doc conventions in the Architecture section; the reference MUST mention `docs/adr/README.md` for ADRs and `docs/templates/prd-template.md` for PRDs; place it as a "Documentation Conventions" subsection within the existing Architecture section; content must be a pointer (2–4 lines), not a full reproduction

## Phase 4: Disambiguation

- [x] 4.1 Add a disambiguation note to `docs/architecture-definition-report.md` — prepend a one-line HTML comment or Markdown note at the top of the file clarifying that "ADR" in this filename stands for "Architecture Definition Report" (not "Architecture Decision Record"); example: `<!-- Note: "ADR" here = Architecture Definition Report, not Architecture Decision Record. See docs/adr/ for decision records. -->`

## Phase 5: Validation and Cleanup

- [x] 5.1 Verify all 9 new files exist: `docs/templates/prd-template.md`, `docs/templates/adr-template.md`, `docs/adr/README.md`, `docs/adr/001-skills-as-directories.md`, `docs/adr/002-artifacts-over-memory.md`, `docs/adr/003-orchestrator-delegates-everything.md`, `docs/adr/004-install-sh-repo-authoritative.md`, `docs/adr/005-skill-md-entry-point-convention.md` — confirm all required sections are present in each file by checklist inspection
- [x] 5.2 Verify all 3 modified files: `ai-context/conventions.md` has "PRD Convention" section, `CLAUDE.md` has Documentation Conventions reference, `docs/architecture-definition-report.md` has disambiguation note — no existing content was removed or altered beyond the specified additions
- [x] 5.3 Update `ai-context/changelog-ai.md` — add an entry for this change: date 2026-03-01, change name `proposal-prd-and-adr-system`, summary of what was added (PRD template, ADR system with 5 retroactive ADRs, integration in conventions.md and CLAUDE.md)

---

## Implementation Notes

- All ADR files derive content ONLY from `ai-context/architecture.md` — do not invent new architectural claims
- All retroactive ADRs use `Accepted (retroactive)` as their Status value and MUST include a note such as: "This decision predates the ADR system and is recorded retroactively."
- The `docs/templates/` directory must be created as part of task 1.1 (it does not exist yet)
- The `docs/adr/` directory must be created as part of task 2.1 (it does not exist yet)
- `docs/` already exists with one file (`architecture-definition-report.md`) — no conflict
- Do NOT touch `ai-context/architecture.md` — it must remain unchanged per spec requirement
- CLAUDE.md edit (task 3.2) only touches the project root `CLAUDE.md`; the global `~/.claude/CLAUDE.md` is updated automatically when `bash install.sh` is run (outside the scope of sdd-apply)
- ADR README (task 2.1) must list all 5 ADRs in its table — write it last or update it after tasks 2.2–2.6 are completed; ordering: complete 2.2–2.6 first, then finalize 2.1's table

## Blockers

None.
