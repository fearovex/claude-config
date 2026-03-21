# ADR-040: Context Contradiction Handling Convention

## Status

Proposed

## Context

The SDD workflow (explore → propose → spec → design → tasks → apply) was originally designed for greenfield changes and incremental additions. Three critical failures emerged when users requested replacement changes (removing old implementations, contradicting documented constraints, or changing prior decisions):

1. **Auth flow replacement session**: User requested "remove the periodic membership refresh hook" but sdd-explore did not identify the hook as existing code; sdd-propose omitted the removal request; sdd-spec invented a requirement to KEEP the hook. The user had to argue against their own specs.

2. **Mark Complete button session**: User requested "replace in-memory simulation with SharePoint write-back" but context notes said "provisional, pending EWP integration". sdd-explore did not surface this contradiction; sdd-propose omitted it; agent silently refused to implement because specs protected the provisional behavior.

3. **Cross-session repeat**: A new session user requested "implement feature X" but did not know that feature X was already attempted and failed two weeks ago in an archived change. sdd-explore did not check the archive, so the agent repeated the same failing approach.

The root cause is architectural: the phase flow and artifact contracts were not designed to pass contextual metadata (prior implementations, archived attempts, conversation constraints) through the cycle. Each phase operated in isolation, unable to detect when user intent contradicted documented state.

## Decision

We will implement a unified context-contradiction handling convention across six SDD phase skills and one global orchestrator rule. The convention establishes:

1. **Three new sections in exploration.md**:
   - Branch Diff: git-scanned modified files on the current branch
   - Prior Attempts: list of archived attempts with outcomes
   - Contradiction Analysis: CERTAIN vs UNCERTAIN status for each detected contradiction

2. **Supersedes section in proposal.md**:
   - Always present; explicitly states "None — purely additive change" if nothing is superseded
   - Enumerates removals, replacements, and their reasons
   - Becomes the authoritative source-of-truth for what is being removed/replaced

3. **Cross-checks in spec and tasks**:
   - sdd-spec validates that no scenario says "preserve X" when proposal says "remove X"
   - sdd-tasks generates removal tasks from Supersedes section
   - Both skills tolerate missing sections from old proposals (backward compatible)

4. **Conversation context pre-population in sdd-ff**:
   - sdd-ff Step 0 extracts conversation patterns ("remove X", "careful with Y", "mobile must not...")
   - Pre-populates proposal.md with Context Notes before launching explore
   - Ensures explore reads user intent explicitly, not implicitly

5. **Contradiction gate in sdd-ff**:
   - If exploration.md contains UNCERTAIN contradictions, sdd-ff presents a blocking confirmation gate
   - User must explicitly confirm or clarify before proposing
   - Prevents silent refusals due to contradictions

6. **Unbreakable Rule 6b in CLAUDE.md**:
   - Orchestrator must extract conversation context before confirming /sdd-ff launch
   - Patterns to extract: removal intents, constraints, prior-state notes, mobile restrictions

This convention ensures that:
- Prior implementations are discovered and listed (Branch Diff)
- Prior failed attempts are visible (Prior Attempts)
- Contradictions between user request and archived state are flagged (Contradiction Analysis)
- User intent about removals is explicit and traceable (Supersedes section)
- Downstream skills can validate consistency (cross-checks in spec/tasks)
- Users are not silently refused due to undetected contradictions (contradiction gate)

## Consequences

**Positive:**

- Users can request replacement/removal changes and have them properly tracked
- Contradictions with archived constraints are detected and surface to the user for decision
- Prior failed attempts are visible, avoiding repeated failures in the same approach
- Artifact chain is complete and traceable: conversation → proposal → spec → tasks → apply
- New sessions can learn from archive (cross-session awareness)
- Backward compatible with all archived proposals (new sections are optional)

**Negative:**

- Six SDD phase skills must be updated in coordinated order (propose before spec; spec before tasks)
- Integration complexity increases: downstream skills must validate upstream sections
- Users must learn new Supersedes section semantics and fill it out for removal changes
- Contradiction gate may delay some cycles when contradictions are discovered (acceptable; user decides)
- Verify step becomes more complex (must test all six skills working together with new sections)
- Archive scanning for prior attempts scales linearly; future optimization path needed at 100+ archived changes (ADR 034 migration to SQLite/FTS5)

**Implementation sequence (enforced in apply):**
- Phase 1: Update sdd-explore, sdd-propose
- Phase 2: Update sdd-spec, sdd-tasks (depends on Phase 1 artifacts)
- Phase 3: Update sdd-ff, CLAUDE.md (depends on Phase 1 & 2)
- Circuit breaker: halt immediately on any phase failure; no partial deployments

**Data model stability:**
- exploration.md new sections become stable once accept (no future breaking changes without new ADR)
- Supersedes section format is stable (table with Item/Removal/Replacement/Reason columns)
- Both artifacts are SDD phase input/output contracts and will not be restructured casually
