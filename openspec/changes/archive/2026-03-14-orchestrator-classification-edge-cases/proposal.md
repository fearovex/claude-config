# Proposal: Orchestrator Classification Edge Cases

## Problem Statement
The intent classification decision table in `CLAUDE.md` covers happy-path examples but lacks edge cases. Ambiguous messages can be classified differently across sessions, making the orchestrator's behavior inconsistent.

## Proposed Solution
Extend the classification decision table in `CLAUDE.md` with explicit edge case examples covering:
- Implicit change intent (e.g. "the login is broken" → Change Request)
- Investigative phrasing that resembles change requests (e.g. "check the login flow" → Exploration)
- Questions that mention broken behavior (e.g. "why does login fail?" → Question)
- Ambiguous single-word commands (e.g. "login" → default Question)

## Success Criteria
- [ ] At least 10 new edge case examples added to the decision table
- [ ] Each edge case covers a pattern that previously had ambiguous classification
- [ ] Classification behavior is consistent across 3 independent test sessions with the same ambiguous inputs
