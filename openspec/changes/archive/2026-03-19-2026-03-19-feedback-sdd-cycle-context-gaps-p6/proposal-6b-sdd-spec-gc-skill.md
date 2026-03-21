# Proposal: New Skill sdd-spec-gc — Spec Garbage Collection

## Problem Statement

Master specs in `openspec/specs/` grow indefinitely as SDD cycles merge delta specs into them. Each merge adds new requirements but never removes requirements that became:
- **Obsolete** — superseded by a later cycle's requirements
- **Provisional** — marked "temporary", "pending X", "will be replaced" but never cleaned up
- **Contradictory** — two requirements in the same spec that cannot both be true
- **Orphaned** — reference artifacts (files, functions, types) that no longer exist in the codebase

The result is that master specs become historical records rather than descriptions of the current desired state. The AI reads them as authoritative and inherits stale constraints as binding rules.

This is a project-agnostic problem — it affects any project using the SDD architecture.

## Proposed Solution

Create a new skill `sdd-spec-gc` (spec garbage collection) that audits one or all master specs and produces a clean version after user confirmation.

### Trigger

```
/sdd-spec-gc [domain]          — audit one domain's master spec
/sdd-spec-gc --all             — audit all domains in openspec/specs/index.yaml
```

### Process

**Step 1 — Discovery**
- Read `openspec/specs/index.yaml` to list all domains
- For `[domain]` mode: read that domain's spec only
- For `--all` mode: read all specs

**Step 2 — Candidate detection**

For each spec, scan requirements and scenarios for:

| Category | Detection Pattern |
|----------|------------------|
| `PROVISIONAL` | Text contains: "provisional", "temporary", "will be replaced", "pending X", "when X is ready", "TODO", "scaffold", "placeholder" |
| `SUPERSEDED` | A later requirement in the same spec or a different spec explicitly replaces this one (contradictory requirements) |
| `ORPHANED_REF` | Requirement references a file, function, type, or component that no longer exists in the codebase (verified via search) |
| `DUPLICATE` | Two requirements express the same constraint with different wording |
| `CONTRADICTORY` | Two requirements in the same spec that cannot both be satisfied simultaneously |

**Step 3 — Present candidates to user**

Produce a report (dry-run, no writes):

```markdown
## Spec GC Report — openspec/specs/<domain>/spec.md

### PROVISIONAL (2 found)
- REQ-7: "Mark Complete button is provisional pending EWP integration"
  → Suggestion: REMOVE or UPDATE to reflect current state

- REQ-12: "Welcome video completion stored in localStorage as temporary measure"
  → Suggestion: REMOVE (SP persistence now implemented)

### ORPHANED_REF (1 found)
- REQ-4: references `usePeriodicMembershipRefresh.ts`
  → File not found in codebase
  → Suggestion: REMOVE requirement

### CONTRADICTORY (1 found)
- REQ-3 says "must use FYStepView directly"
- REQ-9 says "toItemType() mapping is the correct lookup pattern"
  → Suggestion: REMOVE REQ-9 (superseded by REQ-3 per fy-eliminate-learning-path-item-type)

Total: 4 candidates for removal, 0 for update
```

**Step 4 — User confirmation**

Present options:
```
What would you like to do?
  1. Remove all candidates (4 items)
  2. Review each candidate individually
  3. Cancel — make no changes
```

**Step 5 — Apply**

For confirmed removals: rewrite the spec file with the selected requirements removed. Preserve all other requirements, scenarios, and formatting unchanged.

**Step 6 — Record**

Add a comment at the top of the spec:
```markdown
<!-- Last GC: YYYY-MM-DD — N requirements removed (provisional/orphaned/contradictory) -->
```

Update `changelog-ai.md` with a brief entry.

### Rules

- **Read-only until confirmed** — Step 3 produces a dry-run report; no writes until user confirms Step 4
- **Never removes without surfacing reason** — every candidate has a detection category and suggestion
- **Preserves format** — the cleaned spec must maintain the same structure, headers, and section order
- **Does not rewrite** — only removes; it never rephrases or consolidates requirements
- **Codebase search is best-effort** — ORPHANED_REF detection searches for the referenced name; if search is inconclusive, it flags as UNCERTAIN rather than removing
- **Works on any project** — no project-specific assumptions; reads from `openspec/specs/` path relative to project root

## Success Criteria

- [ ] `/sdd-spec-gc fy-video-wiring` finds and surfaces the "provisional pending EWP" requirement as a PROVISIONAL candidate
- [ ] `/sdd-spec-gc --all` processes all domains in index.yaml without error
- [ ] No requirements are removed without explicit user confirmation
- [ ] After GC, the cleaned spec contains no requirements marked as provisional/temporary
- [ ] `changelog-ai.md` records what was removed and when
- [ ] The skill works on any project with `openspec/specs/` — not specific to AT&T or agent-config

## Files to Create

- `~/.claude/skills/sdd-spec-gc/SKILL.md` — new skill
- `CLAUDE.md` (global) — register in Skills Registry under "SDD Skills (phases)"
- `openspec/specs/index.yaml` — no change needed (skill reads existing index)

## Notes

This skill is complementary to `sdd-archive`. Archive merges delta specs in; `sdd-spec-gc` periodically cleans what accumulates. Recommended cadence: run after every 5-10 archived cycles on a domain, or whenever a cycle surfaces a contradiction with prior specs.
