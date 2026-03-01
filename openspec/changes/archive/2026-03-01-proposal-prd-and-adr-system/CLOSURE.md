# CLOSURE — proposal-prd-and-adr-system

## Dates

- Start date: 2026-03-01
- Close date: 2026-03-01

## Summary

Added PRD template system and ADR system with 5 retroactive ADRs, integrated both into
`ai-context/conventions.md` and `CLAUDE.md`. The changes establish documentation infrastructure
for product-level requirements (PRD) and architectural decision records (ADR) without altering
any existing SDD workflow or skill files.

## Modified Specs

| Domain | Action |
|--------|--------|
| prd-system | Created (promoted to master spec at openspec/specs/prd-system/spec.md) |
| adr-system | Created (promoted to master spec at openspec/specs/adr-system/spec.md) |

## Modified Code Files

| File | Change |
|------|--------|
| `docs/templates/prd-template.md` | Created — PRD template with MoSCoW user stories and all required sections |
| `docs/templates/adr-template.md` | Created — ADR template in Nygard format (Title, Status, Context, Decision, Consequences) |
| `docs/adr/README.md` | Created — ADR index with lifecycle explanation and full ADR listing |
| `docs/adr/001-skills-as-directories.md` | Created — Retroactive ADR for skills-as-directories decision |
| `docs/adr/002-artifacts-over-memory.md` | Created — Retroactive ADR for artifacts-over-in-memory-state decision |
| `docs/adr/003-orchestrator-delegates-everything.md` | Created — Retroactive ADR for orchestrator delegation decision |
| `docs/adr/004-openspec-artifact-storage.md` | Created — Retroactive ADR for openspec artifact storage convention |
| `docs/adr/005-install-sync-separation.md` | Created — Retroactive ADR for install/sync discipline separation |
| `docs/architecture-definition-report.md` | Created — Disambiguation document clarifying ADR vs architecture-definition-report naming |
| `ai-context/conventions.md` | Updated — Added PRD usage guidance and ADR convention section |
| `CLAUDE.md` | Updated — Added Documentation System section referencing docs/templates/ and docs/adr/ |
| `ai-context/changelog-ai.md` | Updated — Logged this SDD cycle |

## Key Decisions

1. **PRD is optional** — not a mandatory gate for SDD cycles; most useful for user-facing or product-level changes; feeds into `proposal.md` rather than replacing it.
2. **ADRs use Nygard format** — Title, Status, Context, Decision, Consequences; valid statuses: Proposed, Accepted, Deprecated, Superseded.
3. **Retroactive ADRs** — sourced from `ai-context/architecture.md`; status set to "Accepted (retroactive)" with a note that the decision predates the ADR system.
4. **ADR system complements, not replaces, `ai-context/architecture.md`** — both coexist; architecture.md remains prose-based narrative; ADRs provide structured per-decision records.
5. **`docs/` is deployed by `install.sh`** — templates and ADR files are available at runtime under `~/.claude/docs/`.

## Lessons Learned

- **ADR naming collision**: `architecture-definition-report.md` already existed in `docs/`, which shares the "ADR" abbreviation. Resolved by creating `docs/architecture-definition-report.md` with a disambiguation comment clarifying it is not an Architectural Decision Record.
- **ADR heading style inconsistency in retroactive ADRs**: Retroactive ADR files use bold (`**Status:**`) rather than H2 (`## Status`) for section headings, differing from the template. This is a one-time exception for retroactive files; the template is correct and new ADRs should follow the H2 convention.

## User Docs Reviewed

NO — this change adds documentation infrastructure only. It does not affect any user-facing workflows, commands, or skill triggers. No user documentation updates were required beyond what was created as part of the change itself.

## Verify Report Result

PASS WITH WARNINGS — 0 critical failures. All 11 spec requirements verified. Warnings noted:
- W01: Retroactive ADR heading style (bold vs H2) — one-time exception, template correct
- W02: Naming collision comment is a workaround, not a rename — acceptable given scope
- W03: CLAUDE.md reference is in Documentation System section, not a dedicated conventions section — acceptable per spec intent
