# Proposal: sdd-new-improvements

Date: 2026-03-10
Status: Draft

## Intent

Improve `sdd-new` and `sdd-ff` by: (1) auto-generating the change name from the user's description without asking, and (2) making exploration mandatory as the first step of every SDD cycle instead of optional.

## Motivation

Two UX friction points identified:

### Issue 1 — Asking for a name is irrelevant

`sdd-new` and `sdd-ff` ask the user to provide a change name. The user's input is a description of what they want — the name is an internal artifact identifier. Asking for it interrupts the flow and puts an unnecessary burden on the user.

The AI can derive a suitable slug from the description: short, lowercase, hyphenated, date-prefixed. The user should never need to think about this.

### Issue 2 — Exploration is optional but should be mandatory

`sdd-new` currently prompts: "Do you want to run an exploration phase first?" This creates a gate that the user often skips, sacrificing codebase understanding. The result: proposals and specs are written without grounding in the actual code.

Exploration is not optional — it is what ensures the subsequent phases (propose, spec, design) are based on reality rather than assumption. Making it mandatory removes the gate and improves all downstream artifacts.

## Scope

### Included

- `sdd-new`: remove the name-input gate; infer slug from user description using pattern `YYYY-MM-DD-<inferred-slug>`
- `sdd-ff`: same — infer slug automatically, do not ask user for a name
- `sdd-new`: remove the "do you want exploration?" gate; `sdd-explore` runs unconditionally as Step 1
- `sdd-ff`: add `sdd-explore` as Step 0 before `sdd-propose` (making fast-forward: explore → propose → spec+design → tasks)
- Document slug inference rules: max 5 words, lowercase, hyphens, strip stop words
- Update CLAUDE.md Fast-Forward section to reflect the new `sdd-ff` flow

### Excluded

- Changes to any other SDD phase skills
- Changes to how `sdd-explore` operates internally
- Changes to the `openspec/changes/` directory naming convention (still uses `YYYY-MM-DD-<slug>`)

## Proposed Approach

### Slug inference rule

Given user input: "Fix subscription renewal date showing wrong year for expired users"

Inferred slug: `fix-subscription-renewal-date-expired`

Rules:
1. Take the 4-5 most meaningful words (strip: fix, add, update, the, a, an, for, of, in, with)
2. Lowercase, hyphenated
3. Max 50 characters total
4. Prefix with today's date: `YYYY-MM-DD-`

If the slug collides with an existing directory, append `-2`, `-3`, etc.

### Updated `sdd-ff` flow

```
Step 0: sdd-explore  ← NEW: mandatory, no gate
Step 1: sdd-propose  (reads exploration.md)
Step 2: sdd-spec + sdd-design  (parallel)
Step 3: sdd-tasks
Step 4: Present summary → ask before sdd-apply
```

### Updated `sdd-new` flow

```
Step 0: Infer slug from user description  ← NEW: no name gate
Step 1: sdd-explore  ← NEW: mandatory, no gate
Step 2: sdd-propose
Step 3: sdd-spec + sdd-design (parallel)
Step 4: sdd-tasks
Step 5: Present summary → ask before sdd-apply
```

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-new/SKILL.md` | Modified | High — name gate removed, explore made mandatory |
| `skills/sdd-ff/SKILL.md` | Modified | High — name gate removed, explore added as Step 0 |
| `CLAUDE.md` Fast-Forward section | Modified | Low — updated flow description |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Inferred slug is ambiguous or too long | Low | Low | Slug is internal only; user never needs to type it |
| Mandatory exploration slows fast-forward significantly | Medium | Low | sdd-ff is already a multi-phase command; exploration adds one sub-agent call |
| User wanted a specific name for organizational reasons | Low | Low | User can rename the directory manually; the slug is just a folder name |

## Success Criteria

- [ ] `sdd-new` infers the change name from the user's description without asking
- [ ] `sdd-ff` infers the change name from the user's description without asking
- [ ] `sdd-new` runs `sdd-explore` as Step 1 without prompting the user
- [ ] `sdd-ff` runs `sdd-explore` as Step 0 without prompting the user
- [ ] Generated `exploration.md` is referenced by `sdd-propose` in the same cycle
- [ ] CLAUDE.md Fast-Forward section reflects the updated flow
- [ ] `verify-report.md` has at least one [x] criterion checked
