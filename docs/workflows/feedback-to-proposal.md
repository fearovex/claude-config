# Workflow: Feedback → Proposal → Implementation

## Overview

When a user provides feedback (observations, complaints, or improvement ideas), that session is a **feedback session**. Its only output is one or more `proposal.md` files. Implementation happens in a separate session.

This two-session model prevents valuable feedback from being lost when a chat session expires before a full SDD cycle completes.

---

## What Constitutes a Feedback Session

A feedback session is any session where the primary input from the user is:

- Observations about current behavior ("the skill X doesn't handle Y")
- Complaints or pain points ("I keep having to repeat Z")
- Improvement ideas ("it would be better if W")
- Post-mortem notes ("what went wrong was…")

It is **not** a feedback session when the user explicitly opens with an implementation command (`/sdd-explore`, `/sdd-propose`, etc.) — even if they also mention improvements.

---

## Orchestrator Behavior in a Feedback Session

1. Detect that the session is feedback-driven (content pattern, not a slash command).
2. For each distinct feedback item, create one proposal directory:
   ```
   openspec/changes/YYYY-MM-DD-<slug>/proposal.md
   ```
3. Do NOT start any SDD phase (`/sdd-explore`, `/sdd-spec`, `/sdd-design`, `/sdd-tasks`, `/sdd-apply`).
4. At the end of the session, list all proposals created with their paths.

---

## Proposal Quality Requirements

Each feedback-originated proposal must include:

| Section | Required content |
|---------|-----------------|
| `## Intent` | What the change achieves (one paragraph) |
| `## Motivation` | The specific feedback that triggered it — quoted or paraphrased |
| `## Scope` | `### Included` and `### Excluded` subsections |
| `## Success Criteria` | At least 3 verifiable, checkable items (`- [ ]`) |

Optional but recommended: `## Risks`, `## Effort Estimate`.

---

## How to Initiate Implementation

After the feedback session ends:

1. Open a **new session** in the project.
2. Reference the proposal: `"Implement openspec/changes/YYYY-MM-DD-<slug>/proposal.md"`.
3. Run `/sdd-propose <slug>` (skip exploration if proposal is already written) or `/sdd-explore <slug>` — the orchestrator reads the proposal and starts the SDD cycle.

---

## Folder Layout

```
openspec/
└── changes/
    ├── 2026-03-10-fix-skill-trigger-wording/
    │   └── proposal.md          ← created in feedback session
    ├── 2026-03-10-add-audit-badge/
    │   └── proposal.md          ← created in feedback session
    └── 2026-03-10-fix-skill-trigger-wording/   ← after /sdd-propose in new session
        ├── proposal.md
        ├── specs/
        ├── design.md
        ├── tasks.md
        └── verify-report.md
```

---

## Worked Example

**User feedback (in a feedback session):**

> "The sdd-spec skill sometimes generates scenarios that don't map to any requirement. It wastes time during review. Also, the design phase doesn't always create an ADR even when the decision is clearly architectural."

**Orchestrator action:**

Two distinct feedback items → two proposals created.

---

**Proposal 1:** `openspec/changes/2026-03-10-spec-scenario-traceability/proposal.md`

```markdown
# Proposal: spec-scenario-traceability

Date: 2026-03-10
Status: Draft

## Intent
Ensure every Given/When/Then scenario in sdd-spec output traces back to a named requirement, eliminating orphan scenarios.

## Motivation
During review, scenarios are sometimes generated that do not map to any stated requirement, requiring manual triage and deletion. Quoted feedback: "generates scenarios that don't map to any requirement — wastes time during review."

## Scope
### Included
- Update sdd-spec skill to require a `Covers: REQ-N` annotation on each scenario block
- Update spec template to include the annotation field

### Excluded
- Retroactive annotation of existing spec files
- Automated traceability tooling

## Success Criteria
- [ ] Every scenario block in new sdd-spec output includes a `Covers: REQ-N` annotation
- [ ] The spec template in sdd-spec/SKILL.md includes the annotation field
- [ ] /project-audit score remains >= previous after the change
```

---

**Proposal 2:** `openspec/changes/2026-03-10-design-adr-detection/proposal.md`

```markdown
# Proposal: design-adr-detection

Date: 2026-03-10
Status: Draft

## Intent
Make the ADR detection heuristic in sdd-design more sensitive to architectural decisions, reducing missed ADRs.

## Motivation
The design phase does not always create an ADR even when the decision is clearly architectural. Quoted feedback: "doesn't always create an ADR even when the decision is clearly architectural."

## Scope
### Included
- Expand the ADR trigger keyword list in sdd-design/SKILL.md
- Add examples of architectural decision patterns to the detection rules

### Excluded
- Retroactive ADR generation for past changes
- Automated ADR quality scoring

## Success Criteria
- [ ] Keyword list in sdd-design includes at least 5 additional architectural trigger terms
- [ ] A test change with a clear architectural decision produces an ADR
- [ ] /project-audit score remains >= previous after the change
```

---

**End of feedback session output:**

```
Feedback session complete. Proposals created:
  openspec/changes/2026-03-10-spec-scenario-traceability/proposal.md
  openspec/changes/2026-03-10-design-adr-detection/proposal.md

To implement, open a new session and run:
  /sdd-propose spec-scenario-traceability
  /sdd-propose design-adr-detection
```
