# Skills communicate via file artifacts, not conversation context

## Status

Accepted (retroactive)

> This decision predates the ADR system and is recorded retroactively.

---

## Context

The SDD workflow in claude-config chains multiple skills across an entire development cycle: propose → spec → design → tasks → apply → verify → archive. Each phase produces output that the next phase must consume.

The naive approach is to pass state through the conversation context: the orchestrator reads the output of one sub-agent and injects it into the next. This works for short chains but breaks down quickly:

- Claude's context window has a finite limit. Long SDD chains with detailed proposals, specs, and designs can exceed it.
- Sub-agents launched via the Task tool start with fresh context. They cannot see prior conversation turns unless that state is explicitly injected — and injecting full document content is expensive and error-prone.
- Debugging and auditing a failed phase is impossible if the state only existed in memory. There is no artifact to inspect.
- Parallel phases (spec + design run simultaneously) cannot share a sequential conversation context. They must each read independently.

A file-artifact pattern solves all of these problems: each phase writes its output to a named file; the next phase reads that file by path.

---

## Decision

All inter-skill state is passed through named file artifacts stored at deterministic paths. No phase relies on conversation context alone to receive input from a prior phase.

Concrete artifact examples derived from the architecture:

| Artifact | Produced by | Consumed by | Location |
|----------|-------------|-------------|----------|
| `audit-report.md` | `project-audit` | `project-fix` | `.claude/` in project |
| `analysis-report.md` | `project-analyze` | `project-audit` (D7), user | project root |
| `openspec/config.yaml` | `project-setup` / `project-fix` | all SDD phases | `openspec/` in project |
| `proposal.md` | `sdd-propose` | `sdd-spec`, `sdd-design` | `openspec/changes/<name>/` |
| `tasks.md` | `sdd-tasks` | `sdd-apply` | `openspec/changes/<name>/` |
| `ai-context/*.md` | `memory-init` / `memory-update` | all skills | `ai-context/` in project |

The orchestrator (CLAUDE.md) maintains only file paths between phases — not document contents.

---

## Consequences

**Positive:**
- Handoffs between phases are deterministic: any phase can be re-run or debugged independently by pointing at the same artifact paths.
- Context window pressure is reduced: sub-agents read files directly rather than receiving document content as injected strings.
- Parallel phases (spec + design) can each read the same `proposal.md` independently without coordination.
- The artifact trail serves as an audit log of the entire SDD cycle.

**Negative:**
- Requires artifact discipline: if a phase fails to write its output file, downstream phases are blocked with no fallback.
- File paths must be consistent and documented; ad hoc naming breaks the chain.
- Local filesystem dependency: the system assumes a shared filesystem accessible to all sub-agents. Remote or sandboxed execution models require adaptation.
