# Proposal: sdd-blocking-warnings

Date: 2026-03-10
Status: Draft

## Intent

Classify warnings raised during SDD cycles as either blocker (`MUST_RESOLVE`) or informational (`ADVISORY`), and enforce that all `MUST_RESOLVE` warnings are resolved before the cycle advances to the next phase.

## Motivation

During SDD cycles the AI raises open questions and warnings but then offers to continue anyway (e.g., "One open question before implementing Task 3.1 — confirm which Stripe invoice field to use for the failure date. Ready to implement?"). The user can proceed without resolving the question, embedding an unresolved ambiguity into the implementation.

This pattern creates technical debt: the implementation proceeds on an assumption that may be wrong, and the assumption is never recorded or revisited.

## Scope

### Included

- Define a two-tier warning classification system: `MUST_RESOLVE` and `ADVISORY`
- Add warning classification rules to `sdd-tasks` — tasks with unresolved design questions are flagged `MUST_RESOLVE`
- Add a gate in `sdd-apply`: before executing any task flagged `MUST_RESOLVE`, the agent must present the question and wait for an explicit user answer — it cannot offer to skip or proceed
- `MUST_RESOLVE` warnings must be answered and recorded in `tasks.md` before the task is marked `in-progress`
- `ADVISORY` warnings are logged in `tasks.md` but do not block execution
- Update `sdd-tasks` and `sdd-apply` SKILL.md files with classification rules and gate behavior

### Excluded

- Retroactive classification of warnings in archived changes
- Changes to `sdd-verify` or `sdd-archive`
- Automated resolution of warnings (all resolution is manual by the user)

## Proposed Approach

### Warning classification rules (in `sdd-tasks`)

A task warning is `MUST_RESOLVE` when:
- It involves a business rule decision (which field to use, which value to store, which behavior is correct)
- It involves an external system behavior that is ambiguous (API field semantics, webhook payload structure)
- It involves a data model choice with no clearly correct answer

A task warning is `ADVISORY` when:
- It is a performance consideration that does not affect correctness
- It is a style or naming preference
- It is a future-proofing suggestion not required for current task

### Gate behavior in `sdd-apply`

Before starting a task with a `MUST_RESOLVE` flag:

```
⛔ BLOCKED — Task X.Y has an unresolved MUST_RESOLVE warning:
  [warning text]

You must answer before implementation can proceed:
  → [question]

Type your answer to continue.
```

The agent records the answer in `tasks.md` under the task and proceeds only after receiving it.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-tasks/SKILL.md` | Modified | High — classification rules added |
| `skills/sdd-apply/SKILL.md` | Modified | High — blocking gate added |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Over-classification — too many `MUST_RESOLVE` blocks stall the cycle | Medium | Medium | Clear classification rules; `ADVISORY` is the default when in doubt |
| User bypasses the gate by rephrasing | Low | Medium | Gate requires an explicit answer recorded in `tasks.md` — not a "yes/no continue" prompt |

## Success Criteria

- [ ] `sdd-tasks` classifies each warning as `MUST_RESOLVE` or `ADVISORY` with a reason
- [ ] `sdd-apply` presents a blocking gate for `MUST_RESOLVE` items and records the answer in `tasks.md`
- [ ] `sdd-apply` does NOT offer to skip or proceed past a `MUST_RESOLVE` warning
- [ ] An `ADVISORY` warning is logged but does not interrupt the apply flow
- [ ] `verify-report.md` has at least one [x] criterion checked
