# Technical Design: sdd-project-context-awareness

Date: 2026-03-10
Proposal: openspec/changes/sdd-project-context-awareness/proposal.md

## General Approach

Add a mandatory **Step 0 — Load project context** block to all SDD phase skills. Each skill reads four files from
the project root before any analysis or output: `ai-context/stack.md`, `ai-context/architecture.md`,
`ai-context/conventions.md`, and the project's `CLAUDE.md` (Skills Registry section). The step is always
non-blocking — missing files emit INFO notes and execution continues. A reference document at
`docs/sdd-context-injection.md` provides the canonical template for skill authors.

The Context Capsule (structured YAML object passed from orchestrator to sub-agents) from the original proposal
is out of scope for this cycle. The simpler per-skill file read pattern is sufficient and already implemented
in sdd-propose, sdd-spec, sdd-design, sdd-tasks, and sdd-apply. The remaining gap is `sdd-explore`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Context loading pattern | Per-skill Step 0 block reads 4 files from project root | Context Capsule (YAML object passed by orchestrator); shared memory object | Per-skill reads are self-contained, require no orchestrator changes, no new conventions or message formats. Each sub-agent maintains full context independently. Simpler to audit and test per-skill. |
| Non-blocking contract | INFO-level notes for missing files; never `blocked` or `failed` | Hard-fail on missing context | `ai-context/` is optional in the SDD architecture. Grace degradation is the established pattern. |
| Staleness threshold | 7 days for `Last updated:` date check | No staleness check; 30 days | 7 days balances freshness signal with avoiding noise on frequently-used projects. |
| Dual-block structure for sdd-propose and sdd-spec | Step 0a (global) + Step 0b (domain features) | Merge into single Step 0; rename existing Step 0b | Preserves backward compatibility for step references. Each sub-step has a single responsibility. |
| Reference document | `docs/sdd-context-injection.md` — copy-paste template | Inline in CLAUDE.md; in each SKILL.md | Decoupled from individual skills; single source of truth; discoverable by skill authors. |
| sdd-design Skills Registry cross-reference | Annotate unregistered skills as `[optional — not registered]` | Silently omit unregistered skills; fail design if unregistered | Convention promotes registered skills without blocking the design phase. |

## Data Flow

```
Sub-agent launch (from sdd-ff / sdd-new)
        │
        ▼
  SDD Phase SKILL.md executes
        │
        ▼
  Step 0 — Load project context (non-blocking)
        │
        ├─ read ai-context/stack.md       → tech stack enrichment
        ├─ read ai-context/architecture.md → architectural decisions enrichment
        ├─ read ai-context/conventions.md  → naming/code conventions enrichment
        └─ read CLAUDE.md (Skills Registry) → skill recommendation enrichment
        │
        ▼
  Step 1+ — Phase-specific logic
  (uses loaded context as enrichment — does NOT override proposal/design content)
        │
        ▼
  Phase output artifacts (proposal.md / spec.md / design.md / tasks.md / ...)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-explore/SKILL.md` | Modify | Add Step 0 — Load project context block before existing Step 1 |
| `docs/sdd-context-injection.md` | Create | Reference guide: Step 0 template, dual-block variant, graceful degradation rules, staleness threshold, usage table |
| `docs/adr/024-sdd-project-context-awareness-convention.md` | Create | ADR documenting the architectural convention |
| `ai-context/architecture.md` | Modify | Add decision 11 — SDD phase skills load project context before any output |

Note: `skills/sdd-propose/SKILL.md`, `skills/sdd-spec/SKILL.md`, `skills/sdd-design/SKILL.md`,
`skills/sdd-tasks/SKILL.md`, and `skills/sdd-apply/SKILL.md` are already modified (Step 0 present).
Only `sdd-explore` remains to be updated.

## Interfaces and Contracts

The Step 0 block is a **SKILL.md prose template**, not a code interface. The contract is:

```markdown
### Step 0 — Load project context

This step is **non-blocking**: any failure MUST produce at most an INFO-level note.
This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md`
2. Read `ai-context/architecture.md`
3. Read `ai-context/conventions.md`
4. Read the project's `CLAUDE.md` — extract `## Skills Registry` section

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: check `Last updated:` date; if >7 days old: emit NOTE (staleness warning)

Loaded context is enrichment only — does NOT override explicit proposal/design content.
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual inspection | Each SKILL.md has a Step 0 or Step 0a block as first step in `## Process` | File inspection |
| Manual inspection | `docs/sdd-context-injection.md` exists and contains template, dual-block variant, graceful degradation rules | File inspection |
| Manual inspection | ADR 024 exists in `docs/adr/` and `docs/adr/README.md` index is updated | File inspection |
| Integration | Run `/project-audit` on claude-config — score MUST be >= 98 | /project-audit |

## Migration Plan

No data migration required. The Step 0 block is additive — it does not change existing step numbering
in skills that did not previously have a Step 0 (sdd-explore). In skills with existing Step 0 (sdd-apply),
the new content is inserted as a labeled sub-section (Step 0a) before the existing scope guard.

## Open Questions

None.
