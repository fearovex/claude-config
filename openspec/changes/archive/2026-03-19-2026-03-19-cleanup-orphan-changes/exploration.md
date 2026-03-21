# Exploration: cleanup-orphan-changes

Date: 2026-03-19

## Current State

`openspec/changes/` contains 5 non-archive directories. Two of them are orphans — incomplete SDD change directories that never reached the archive:

| Directory | Artifact(s) present | Missing |
| --- | --- | --- |
| `spec-hygiene/` | `exploration.md` | proposal, design, tasks, verify-report |
| `2026-03-14-specs-sqlite-store/` | `proposal.md` | exploration, design, tasks, verify-report |
| `2026-03-14-spec-headers-domain-consolidation/` | exploration, proposal, prd, design, tasks | verify-report (complete minus verify) |
| `2026-03-18-context-handoff-between-sessions/` | exploration, proposal, tasks, design, verify-report | — (complete, in-progress) |

The three complete or near-complete change directories (`2026-03-14-spec-headers-domain-consolidation/`, `2026-03-18-context-handoff-between-sessions/`, plus the newly started `2026-03-19-cleanup-orphan-changes/`) are not orphans and should not be touched.

This exploration focuses on the two genuine orphans:

---

## Orphan Analysis

### Orphan 1 — `spec-hygiene/`

**Status**: Exploration-only orphan. Contains a single `exploration.md` — a read-only audit of the spec corpus as of 2026-03-14.

**Content value**: High informational value. The exploration documents:
- 55 master spec domains, all healthy and fully traceable
- 63 archived changes as of the audit date
- Two minor hygiene findings (5 legacy inline `*Created by*` headers vs. structured `Change:` headers; mild `sdd-apply` / `sdd-apply-execution` domain overlap)
- Three approaches: no action (recommended), backfill headers (low effort), merge overlapping specs (medium effort)
- Conclusion: "No action needed" — the finding was informational, not actionable

**Why it stopped here**: The exploration concluded there was nothing to fix. No proposal was ever created because the recommendation was "no action required." The directory name also lacks the `YYYY-MM-DD-` date prefix required by the naming convention for active (non-archived) changes.

**Git origin**: Committed in `6a9b1d4` (feat(sdd): implement spec context preload and archive both SDD cycles), suggesting it was produced as a side investigation during another change cycle and never promoted.

**Cleanup strategy**: **Archive as-is** with a CLOSURE.md note marking it informational. The data is still valid — the spec corpus health snapshot has historical value.

---

### Orphan 2 — `2026-03-14-specs-sqlite-store/`

**Status**: Proposal-only orphan. Contains a single `proposal.md` — a detailed design for an SQLite-backed spec store with FTS5 full-text search.

**Content value**: Very high. The proposal is complete and well-specified:
- SQLite `specs.db` built from markdown sources (gitignored)
- `openspec/bin/spec-query` — Python stdlib CLI (zero external deps)
- `openspec/bin/spec-index` — Python stdlib indexer with `--upsert` mode
- Three-layer progressive disclosure: domain list → preview → full content
- Integration points with `sdd-archive`, `sdd-explore`, `sdd-propose`, `sdd-spec`
- Full risk table, rollback plan, and success criteria

**Why it stopped here**: The proposal was written but the SDD cycle was never started. The companion proposal (`2026-03-14-specs-as-subagent-background`) was archived as `2026-03-14-specs-as-subagent-background` and `2026-03-14-specs-search-optimization` (which implemented the lighter `index.yaml` approach instead). ADR 034 in that archive explicitly notes the SQLite/FTS5 migration as a "proposed" deferred path once spec count reaches 100+ domains.

**Git origin**: Same commit `6a9b1d4` — the SQLite approach was superseded by `index.yaml` in the same session.

**Cleanup strategy**: **Discard (delete)** — the change was superseded. Its core idea (FTS5 migration for 100+ domain scale) is already documented in ADR 034. The proposal adds no actionable value now and would mislead future sessions into thinking this feature is in-progress.

---

## Affected Areas

| File/Directory | Action | Rationale |
| --- | --- | --- |
| `openspec/changes/spec-hygiene/` | Archive as-is + CLOSURE.md | Informational audit; no follow-up needed |
| `openspec/changes/2026-03-14-specs-sqlite-store/` | Delete | Superseded by index.yaml + ADR 034 |

---

## Analyzed Approaches

### Approach A: Archive spec-hygiene as-is + delete specs-sqlite-store (Recommended)

**Description**: Move `spec-hygiene/` → `openspec/changes/archive/2026-03-14-spec-hygiene/` with a brief `CLOSURE.md`. Delete `openspec/changes/2026-03-14-specs-sqlite-store/` entirely.
**Pros**: Clean changes directory; spec-hygiene findings preserved for historical reference; no ambiguity about superseded proposals.
**Cons**: Minimal — deleting the proposal is irreversible (but git history preserves it at `6a9b1d4`).
**Estimated effort**: Low (move 1 directory, delete 1 directory, write 1 CLOSURE.md)
**Risk**: Low

### Approach B: Archive both orphans as-is (no delete)

**Description**: Archive both directories with CLOSURE.md notes.
**Pros**: Nothing deleted — fully conservative.
**Cons**: `specs-sqlite-store` remains archived as a "proposal" that was never pursued and is superseded — risks confusing future sessions.
**Estimated effort**: Low
**Risk**: Low (but creates low-grade confusion)

### Approach C: Delete both orphans

**Description**: Delete both directories.
**Pros**: Cleanest state.
**Cons**: spec-hygiene audit findings (historically valuable) are lost from the artifact layer (though preserved in git at `6a9b1d4`).
**Estimated effort**: Minimal
**Risk**: Low

---

## Recommendation

**Approach A** — archive `spec-hygiene/` with a CLOSURE.md (renaming to add the date prefix `2026-03-14-spec-hygiene`), and delete `2026-03-14-specs-sqlite-store/`.

Rationale:
- `spec-hygiene/` contains a completed, self-contained audit. Archiving it preserves the artifact in the standard location and adds the date prefix that was missing.
- `specs-sqlite-store/` is unambiguously superseded. Keeping it risks triggering accidental `/sdd-apply` cycles. Git preserves the proposal at `6a9b1d4` if it's ever needed.

---

## Convention Gap: Orphan Detection

No existing convention defines what constitutes an "orphan change" or what to do with one. This cleanup reveals the gap.

**Proposed convention** (to be written into a spec or CLAUDE.md):

> An SDD change directory in `openspec/changes/` is **orphaned** if it has been present for more than 7 days and is missing both `tasks.md` and `verify-report.md`. Orphaned changes must be explicitly handled — either revived (started with `/sdd-ff`), archived with a CLOSURE.md, or deleted — before archiving the host change.

This convention should live in `openspec/specs/sdd-archive-execution/spec.md` as an orphan-detection precondition for the archive phase, and optionally in `CLAUDE.md` under Plan Mode Rules.

---

## Identified Risks

- Deleting `specs-sqlite-store/proposal.md`: Low risk — ADR 034 already documents the SQLite migration path; git preserves the file at commit `6a9b1d4`.
- Archiving `spec-hygiene/` with date rename: Low risk — pure directory move.
- Convention gap: Medium long-term — without a written rule, orphans will continue to accumulate silently.

---

## Open Questions

- Should the orphan-detection convention be added to `sdd-archive-execution/spec.md` only, or also to CLAUDE.md Plan Mode Rules?
- Is the 7-day age threshold appropriate, or should it be change-count-based (e.g., "more than 3 subsequent changes since creation")?

---

## Ready for Proposal

Yes. Two actions and one convention addition are clearly defined. All are low-risk and low-effort.
