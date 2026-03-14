# Technical Design: 2026-03-14-orchestrator-classification-edge-cases

Date: 2026-03-14
Proposal: openspec/changes/2026-03-14-orchestrator-classification-edge-cases/proposal.md

## General Approach

The change is purely additive: extend the `Classification Decision Table` fenced code block inside the `## Always-On Orchestrator — Intent Classification` section of `CLAUDE.md` (and its deployed copy at `~/.claude/CLAUDE.md`) with at least 10 new edge-case examples. No new skill, no new file, no structural change to the table — only new example lines appended to each branch of the decision tree. After editing the repo copy, `install.sh` deploys the update to the runtime.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Where to add edge cases | Inline in the `Classification Decision Table` fenced code block in `CLAUDE.md` | New dedicated `edge-cases.md` file; separate skill | The decision table is already the canonical classification reference. Adding examples here keeps context co-located and avoids requiring a new file read at classification time — consistent with the existing pattern used for happy-path examples. |
| Format for new examples | Append to existing `✓` / `✗` example lines under each `IF` branch | New sub-section, new table | Maintains the exact existing format (boolean tick + quoted message + arrow + class). Claude parses this block as a flat classification reference — adding rows in the same format avoids introducing a new convention. |
| Scope of edge cases | Four categories from proposal (implicit change, investigative-resembling-change, broken-behavior question, ambiguous single-word) | Exhaustive enumeration of all possible inputs | The four categories cover the observed failure patterns. Exhaustive enumeration would grow the table unboundedly; targeting the known ambiguous patterns keeps the table actionable. |
| Deployment mechanism | Edit repo `CLAUDE.md` → run `install.sh` | Direct edit of `~/.claude/CLAUDE.md` | Architecture rule: never edit `~/.claude/` directly. Repo is authoritative; `install.sh` deploys. No exceptions. |

## Data Flow

```
User sends free-form message
        │
        ▼
Orchestrator reads CLAUDE.md (loaded at session start)
        │
        ▼
Classification Decision Table evaluated top-to-bottom
        │
   ┌────┴─────────────────────────────┐
   │  IF starts with /                │
   │    → Meta-Command                │
   │  ELSE IF change intent keywords  │
   │    → Change Request              │
   │    (new: implicit change phrases │
   │     like "X is broken" included) │
   │  ELSE IF investigative keywords  │
   │    → Exploration                 │
   │    (new: "check X", "look at X"  │
   │     examples clarify boundary)   │
   │  ELSE                            │
   │    → Question (direct answer)    │
   │    (new: "why does X fail?",     │
   │     single-word inputs default)  │
   └──────────────────────────────────┘
        │
        ▼
Routing action executed
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add ≥10 edge-case example lines in the `Classification Decision Table` fenced block, distributed across Change Request, Exploration, and Question branches |

> Note: `~/.claude/CLAUDE.md` is the runtime copy, updated automatically via `install.sh` after the repo edit — it is NOT edited directly.

## Interfaces and Contracts

No code interfaces involved. The "contract" is the classification grammar inside the fenced block:

```
✓ "<input message>"   → <Intent Class> (reason note)
✗ "<input message>"   → <Intent Class> (contrast note)
```

New edge-case examples MUST follow this exact format to remain parseable by the orchestrator's inline classification heuristic.

### Edge Case Coverage Plan (≥10 examples)

The following edge cases will be distributed across the three non-default branches:

**Change Request branch (implicit change intent):**
1. `✓ "the login is broken"` → Change Request (implicit fix intent, no explicit verb)
2. `✓ "the retry logic is missing"` → Change Request (implicit add intent)
3. `✓ "tests are failing after my last change"` → Change Request (implicit fix)
4. `✗ "why does the login break?"` → Question (interrogative, not directive)

**Exploration branch (investigative phrases resembling changes):**
5. `✓ "check the auth module"` → Exploration (audit/investigate intent)
6. `✓ "look at the payment flow"` → Exploration (examine intent)
7. `✓ "go through the retry logic"` → Exploration (walk-me-through intent)
8. `✗ "fix what you find in the auth module"` → Change Request (explicit fix directive)

**Question branch / Default (questions about broken behavior + ambiguous single tokens):**
9. `✓ "why does login fail?"` → Question (interrogative, ends with ?)
10. `✓ "what causes the payment error?"` → Question (what-is pattern)
11. `✓ "login"` → Question/Default (single ambiguous word, no intent signal)
12. `✓ "auth"` → Question/Default (single ambiguous word)

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual / session | Send each of the 12 new example inputs to the orchestrator in 3 independent sessions; verify routing matches expected class | Human evaluation (no automated test runner for CLAUDE.md content) |
| Audit | Run `/project-audit` after applying; verify score >= previous | `/project-audit` (project-local integration test) |

> No automated unit test runner applies to CLAUDE.md content — validation is manual session-based as stated in the proposal Success Criteria.

## Migration Plan

No data migration required. This is a documentation-only change to `CLAUDE.md`. No schema, database, or data structure is modified.

## Open Questions

None.
