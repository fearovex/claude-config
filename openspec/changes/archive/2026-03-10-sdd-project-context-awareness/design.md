# Technical Design: sdd-project-context-awareness

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-project-context-awareness/proposal.md

## General Approach

Add a mandatory **Step 0 — Load project context** block to six SDD phase SKILL.md files
(`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`).
The step reads `ai-context/stack.md`, `ai-context/architecture.md`, and `ai-context/conventions.md`
before any analysis or output. Files that are absent are noted at INFO level; the step is
non-blocking in all cases. A reference document is created in `docs/` for future skill authors.

Note: `sdd-propose` already has a domain context preload step (Step 0) focused on
`ai-context/features/` files. In this skill the new global context block is inserted as
a new **Step 0a** (or retitled as a distinct sub-step) to avoid conflicting with the
existing Step 0 numbering. `sdd-spec` has the same situation (Step 0 inside Step 1) and
is handled consistently.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Placement of context load | New Step 0 block before all existing steps | Inline reads scattered per phase | A single named step is discoverable, auditable, and testable; consistent convention across all 6 skills |
| Blocking behavior on missing files | Non-blocking — note at INFO level and continue | Abort with `status: blocked` | The ai-context/ layer is optional by architecture design; graceful degradation is the established pattern (see sdd-apply scope guard) |
| Staleness check | Include `Last updated:` date inspection; warn if > 7 days | Ignore dates entirely | Risk mitigation from proposal; low-cost signal for stale context |
| Context injection pattern documentation | New file `docs/sdd-context-injection.md` | Update only CLAUDE.md conventions | A standalone reference doc is more discoverable by skill authors; CLAUDE.md is already dense |
| Step naming in sdd-propose and sdd-spec | Insert as `Step 0a` — global context load; existing feature preload becomes `Step 0b` | Renumber all existing steps | Minimal diff; preserves existing step numbers in sdd-propose and sdd-spec for backwards reference |
| Architecture coverage | All 6 phase skills (explore, propose, spec, design, tasks, apply) | Only the 4 "high-impact" skills | The proposal scopes all 6; consistent application prevents context gaps in lighter phases |

## Data Flow

```
/sdd-ff <change-name>  (or any individual /sdd-* command)
         |
         ▼
  Sub-agent spawned
         |
         ▼
  Step 0 — Load project context  (NEW — all 6 skills)
    ├── read ai-context/stack.md        → tech stack keywords, versions
    ├── read ai-context/architecture.md → architectural decisions and rationale
    ├── read ai-context/conventions.md  → naming + code patterns
    └── if any file absent: INFO note, continue
         |
         ▼
  [Existing steps 0/1/2/... unchanged]
    — proposal authoring, spec writing, design, tasks, apply —
    — outputs now reflect actual project stack & conventions —
```

Staleness check (within Step 0):
```
for each loaded file:
  extract "Last updated: YYYY-MM-DD" or "> Last updated: YYYY-MM-DD"
  if date < (today - 7 days):
    note: "[file] was last updated [date] — context may be stale. Consider /memory-update."
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-explore/SKILL.md` | Modify | Add Step 0 — Load project context block before existing Step 1 |
| `skills/sdd-propose/SKILL.md` | Modify | Rename current Step 0 to "Step 0b — Domain context preload"; add new "Step 0a — Load project context" before it |
| `skills/sdd-spec/SKILL.md` | Modify | Rename current Step 0 (inside Step 1) to "Step 0b — Domain context preload"; add "Step 0a — Load project context" before Step 1 |
| `skills/sdd-design/SKILL.md` | Modify | Add Step 0 — Load project context block before existing Step 1 |
| `skills/sdd-tasks/SKILL.md` | Modify | Add Step 0 — Load project context block before existing Step 1 |
| `skills/sdd-apply/SKILL.md` | Modify | Add Step 0a — Load project context sub-step inside the existing Step 0 preamble, before the scope guard |
| `docs/sdd-context-injection.md` | Create | Reference document: the Step 0 pattern, block template, non-blocking contract, staleness check |

## Interfaces and Contracts

### Step 0 block template (to be inserted verbatim or adapted per skill)

```markdown
### Step 0 — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update.`

Loaded context is used as enrichment throughout all subsequent steps. It is NOT used
to override explicit content in the proposal or design — it informs, does not replace.
```

### For sdd-propose and sdd-spec: split naming

```markdown
### Step 0a — Load project context
[global context block above]

### Step 0b — Domain context preload
[existing feature file matching logic — unchanged]
```

### For sdd-apply: placement within existing Step 0

In `sdd-apply`, Step 0 is the "Technology Skill Preload" step. The global context read is
inserted as a distinct labeled sub-section **before** the scope guard:

```markdown
### Step 0 — Context and Technology Skill Preload

#### Project context load (non-blocking)
[global context block]

#### Scope guard
[existing scope guard logic — unchanged]

#### Stack detection
[existing logic — now can also use context from ai-context/stack.md loaded above]
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual integration | Run `/sdd-ff` on a project with populated `ai-context/` — verify output references stack and conventions | human review |
| Manual integration | Run `/sdd-ff` on a project without `ai-context/` — verify no abort, INFO notes in output | human review |
| Audit | Run `/project-audit` after apply — verify score >= 98 (current baseline) | /project-audit |

No automated unit tests apply — this repo's test surface is manual integration + /project-audit.

## Migration Plan

No data migration required. All changes are additive modifications to SKILL.md files (plain text).
Existing openspec/ artifacts in archive/ are not affected. Any active change that was already at
the `apply` phase before this change lands can continue using the old skill version — the Step 0
block does not break backward compatibility since it is non-blocking.

## Open Questions

None.
