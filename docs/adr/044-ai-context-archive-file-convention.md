# ADR-044: Establish Archive File Convention For Ai Context Memory Layer

## Status

Proposed

## Context

The `ai-context/` memory layer has two files that grow unboundedly: `changelog-ai.md` (currently 2373 lines) and `known-issues.md` (accumulates resolved items without separation). There is no established convention for where old or resolved content should be moved. The new `memory-maintain` skill needs a target location for archived entries.

Alternatives considered:
- A separate `ai-context/archive/` subdirectory — adds directory nesting for simple flat files
- Date-stamped archive files (e.g., `changelog-ai-archive-2026-03.md`) — adds rotation complexity without clear benefit at current scale
- No archival, just truncation — loses historical data permanently

## Decision

We will use flat archive files in `ai-context/` following the naming convention `<original-name>-archive.md`. Specifically:

- `ai-context/changelog-ai-archive.md` — receives changelog entries beyond the 30-entry retention threshold
- `ai-context/known-issues-archive.md` — receives known-issues items marked as FIXED or RESOLVED

Archive files are append-only: new archived content is prepended (newest-first, matching the source file convention). Archive files are not loaded by SDD phase skills during context preload — they exist for historical reference only.

## Consequences

**Positive:**

- Simple, predictable naming — archive file is always `<source>-archive.md` in the same directory
- No directory structure changes — `ai-context/` remains flat
- Archive files preserve historical data that would otherwise be lost on truncation
- Convention is extensible to other files if needed in the future

**Negative:**

- Archive files will grow unboundedly over time (acceptable — they are rarely loaded)
- Two new files in `ai-context/` that `index.md` must account for
- Skills that walk `ai-context/` must be aware that `-archive.md` files are historical, not active context
