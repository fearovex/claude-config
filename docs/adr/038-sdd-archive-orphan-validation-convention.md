# ADR-038: SDD Archive Orphan Validation Convention — Two-Tier Severity Gate Before Archiving

## Status

Proposed

## Context

`sdd-archive` is the only terminal node in the SDD phase DAG. It is an irreversible operation. Prior to this change it validated only `verify-report.md` — it did not check whether the other required SDD artifacts (`proposal.md`, `tasks.md`, `design.md`, `specs/`) were present. This allowed incomplete or abandoned change directories to be archived without any signal that the SDD cycle was not completed.

Historical analysis of 65 archived changes shows `proposal.md` and `tasks.md` are present in 100% of cases, `design.md` and `specs/` in ~86%, and `exploration.md` in only ~34%. This empirical data establishes a clear required/optional boundary. Four orphan changes were accumulating in `openspec/changes/` with no mechanism to surface their incompleteness.

The system needed a way to distinguish between truly incomplete cycles (missing foundational artifacts) and legitimately abbreviated cycles (skipping design or spec for trivial hotfixes), and to surface the distinction at the only point where it cannot be ignored: the archive gate.

## Decision

We will insert a two-tier completeness validation block at the top of `sdd-archive` Step 1, before the existing `verify-report.md` check, using the same severity model already established in `sdd-tasks`:

- **CRITICAL** (maps to MUST_RESOLVE): `proposal.md` and `tasks.md` absent → hard block, no proceed option.
- **WARNING** (maps to ADVISORY-with-gate): `design.md` or `specs/` absent → two-option prompt; option 2 (archive with acknowledgment) is always available and records skipped phases in `CLOSURE.md`.

The check is terminal-only, inline in `sdd-archive/SKILL.md`, with no config key and no changes to other phase skills.

## Consequences

**Positive:**

- Incomplete cycles are surfaced at the only irreversible point in the DAG, preventing silent accumulation of orphan changes.
- The two-tier model gives users an escape hatch for legitimate abbreviated cycles (hotfix, trivial change) while still creating a paper trail in `CLOSURE.md`.
- Reuses the MUST_RESOLVE/ADVISORY mental model from `sdd-tasks` — no new severity concepts to learn.
- The existing 4 orphan changes will surface naturally the next time a user attempts to archive them.

**Negative:**

- Users attempting to archive incomplete changes for the first time will be blocked or prompted — this is intentional but may feel surprising.
- The WARNING prompt adds a user interaction step for cycles that skip design/spec phases, even when the skip is clearly intentional.
