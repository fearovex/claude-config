---
name: sdd-explore
description: >
  Investigates and analyzes an idea or codebase area before committing to changes. Pure research, no writes.
  Trigger: /sdd-explore <topic>, explore, investigate codebase, research feature, analyze before changing.
---

# sdd-explore

> Investigates and analyzes an idea or area of the codebase before committing to changes.

**Triggers**: sdd:explore, explore, investigate codebase, analyze before changing, research feature

---

## Purpose

The exploration phase is **optional but valuable**. Its goal is to understand the terrain before proposing changes. It creates no code and modifies nothing. It only reads and analyzes.

Use it when:
- The request is vague or complex
- You are unsure of the scope of the change
- You want to understand the impact before committing
- There are multiple possible approaches

---

## Process

### Step 1 — Understand the request

I classify what type of exploration is needed:
- **New feature**: What already exists? Where would it fit?
- **Bug**: Where is the problem? What is the root cause?
- **Refactor**: What code is affected? What are the risks?
- **Integration**: What exists to connect? What is missing?

### Step 2 — Investigate the codebase

I read real code following this hierarchy:
1. Entry points of the affected area
2. Files related to the functionality
3. Existing tests (they reveal expected behavior)
4. Relevant configurations
5. `ai-context/architecture.md` if it exists (to understand past decisions)

### Step 3 — Analyze approaches

For each possible approach I generate a comparison table:

| Approach | Pros | Cons | Effort | Risk |
|----------|------|------|--------|------|
| [Option A] | | | Low/Medium/High | Low/Medium/High |
| [Option B] | | | | |

### Step 4 — Identify risks and dependencies

- Code that would break with the change
- Dependencies that would need to be updated
- Tests that would fail
- Non-obvious side effects

### Step 5 — Save if a change name was specified

If invoked as `/sdd-explore <change-name>`, I save to:
`openspec/changes/<change-name>/exploration.md`

```markdown
# Exploration: [topic]

## Current State
[What currently exists in the codebase]

## Affected Areas
| File/Module | Impact | Notes |
|-------------|--------|-------|

## Analyzed Approaches

### Approach A: [name]
**Description**: [how it would work]
**Pros**: [advantages]
**Cons**: [disadvantages]
**Estimated effort**: Low/Medium/High
**Risk**: Low/Medium/High

### Approach B: [name]
[same format]

## Recommendation
[Recommended approach and why]

## Identified Risks
- [risk]: [impact] — [suggested mitigation]

## Open Questions
- [things that need clarification before proposing]

## Ready for Proposal
[Yes/No — and why if No]
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "summary": "Analysis of [topic]: [2-3 lines of the main finding]",
  "artifacts": ["openspec/changes/<name>/exploration.md"],
  "next_recommended": ["sdd-propose"],
  "risks": ["[risk if found]"]
}
```

---

## Rules

- I ONLY read code — I never modify anything in this phase
- I read real code, never assume or invent
- If I find something unexpected (technical debt, inconsistencies), I report it
- I keep the analysis concise: the goal is to inform, not to write a thesis
- If the exploration reveals that the change is trivial, I say so clearly
