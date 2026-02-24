# sdd-propose

> Creates a change proposal with clear intent, defined scope, and technical approach.

**Triggers**: sdd:propose, create proposal, define change, sdd proposal

---

## Purpose

The proposal defines the **WHAT and WHY** before entering into technical details. It is the scope contract of the change. Without an approved proposal, there are no specs or design.

---

## Process

### Step 1 — Read prior context

If `openspec/changes/<change-name>/exploration.md` exists, I read it first.
If `openspec/config.yaml` exists, I read the project rules.
If `docs/ai-context/architecture.md` exists, I consult it for coherence.

### Step 2 — Understand the request in depth

If the request is ambiguous, I ask:
- What is the problem or need that motivates this change?
- Are there known constraints (performance, compatibility, etc.)?
- Are there parts that are explicitly OUT of scope?

### Step 3 — Create the change directory

```
openspec/changes/<change-name>/
```

### Step 4 — Write proposal.md

I create `openspec/changes/<change-name>/proposal.md`:

```markdown
# Proposal: [change-name]

Date: [YYYY-MM-DD]
Status: Draft

## Intent
[One clear sentence: what problem it solves or what need it covers]

## Motivation
[Why this is necessary now. Business or technical context.]

## Scope

### Included
- [deliverable 1]
- [deliverable 2]
- [deliverable 3]

### Excluded (explicitly out of scope)
- [what will NOT be done and why]

## Proposed Approach
[High-level description of the technical solution.
Does not go into implementation detail — that is the design's job.
Explains the "how" at a conceptual level.]

## Affected Areas
| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| [area] | New/Modified/Removed | Low/Medium/High |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [risk] | Low/Medium/High | Low/Medium/High | [how to mitigate] |

## Rollback Plan
[How to revert if something goes wrong.
Must be concrete: which files, which commands, which steps.]

## Dependencies
- [What must exist/be completed before starting]
- [Changes in other parts of the system that this requires]

## Success Criteria
- [ ] [measurable and verifiable criterion 1]
- [ ] [measurable and verifiable criterion 2]
- [ ] [measurable and verifiable criterion 3]

## Effort Estimate
[Low (hours) / Medium (1-2 days) / High (several days)]
```

### Step 5 — Summary to orchestrator

I return a clear executive summary:

```
Proposal created: [change-name]

Intent: [one line]
Scope: [N deliverables included, M excluded]
Approach: [one line]
Risk: Low/Medium/High
Next step: specs + design (can run in parallel)
```

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Proposal [name]: [intent in one line]. Risk [level].",
  "artefactos": ["openspec/changes/<name>/proposal.md"],
  "next_recommended": ["sdd-spec", "sdd-design"],
  "riesgos": ["[main risk if any]"]
}
```

---

## Rules

- ALWAYS create `proposal.md` — it is the entry point for all subsequent phases
- Every proposal MUST have a rollback plan and success criteria
- Success criteria must be MEASURABLE and VERIFIABLE (not vague)
- Excluded scope is as important as included scope — it prevents scope creep
- I do not go into implementation details — that is the job of `sdd-design`
- If the proposal is trivial (1-2 line change), I indicate it and suggest skipping the full cycle
