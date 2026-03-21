# Technical Design: 2026-03-18-context-handoff-between-sessions

Date: 2026-03-18
Proposal: openspec/changes/2026-03-18-context-handoff-between-sessions/proposal.md

## General Approach

Add a two-part mechanism for cross-session intent continuity: (1) a new Unbreakable Rule 6 in `CLAUDE.md` that obliges the orchestrator to seed a `proposal.md` before recommending a `/sdd-ff` that will execute in a new session; and (2) a non-blocking sub-step in `sdd-explore` Step 0 that reads a pre-seeded `proposal.md` when one exists in the change directory, treating it as supplemental intent enrichment — not a replacement for live codebase analysis. No new skills, no ADR-level orchestration changes; both modifications are additive and non-breaking.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| --- | --- | --- | --- |
| Placement of cross-session handoff rule | Unbreakable Rules section of CLAUDE.md (Rule 6) | Fast-Forward section only; new standalone skill | Unbreakable Rules are loaded at session start without additional file reads — highest enforcement guarantee. Mirrors Rule 5 (Feedback persistence) pattern exactly. This is a convention, not a new architectural layer. |
| Handoff consumption point | sdd-explore Step 0 sub-step (non-blocking, pre-investigation) | sdd-ff Step 0 pre-flight; sdd-propose enrich mode | sdd-explore runs before any other phase. Enriching explore with handoff context maximally influences exploration.md, which is what sdd-propose consumes. This closes the "cold explore" gap at the lowest cost. |
| Handoff file format | Reuse existing `proposal.md` at `openspec/changes/<slug>/proposal.md` | New `handoff-context.md` artifact; `ai-context/changelog-ai.md` entry | Reuse avoids introducing a new artifact type. proposal.md is already the canonical intent document for a change. The seeded file follows the same path the cycle would write — no new conventions. |
| Proposal overwrite by sdd-propose | Accept overwrite — explore already consumed context | sdd-propose enrich mode; rename seeded file | Low cost, sufficient outcome: the seeded proposal.md serves as explore input. After exploration.md is written, the seeded proposal.md has fulfilled its purpose. sdd-propose rewrites from exploration.md, which now contains the handoff context indirectly. Avoiding overwrite logic keeps sdd-propose simple. |
| Trigger signal for Rule 6 | Explicit user signal ("in a new session", "when context resets") OR orchestrator detects imminent compaction | Always-on (every ff recommendation) | Always-on would add noise and unnecessary artifacts for same-session ff cycles. An explicit signal keeps the rule targeted. Mirrors how Rule 5 is scoped to explicit feedback sessions. |
| Scope of this change | CLAUDE.md + sdd-explore/SKILL.md only | Full Approach C (CLAUDE.md + sdd-explore + sdd-ff/sdd-propose) | Approach C adds sdd-ff/propose enrichment logic with unclear ROI: propose consumes exploration.md, which already carries handoff context via the explore sub-step. Three-file change with corner-case complexity not justified by the benefit delta. |

## Data Flow

```
Originating session (session A):
  User message → orchestrator classifies as Change Request
  Orchestrator detects: user signals ff will run in new session
       │
       ▼
  [Rule 6 gate]
  Orchestrator writes openspec/changes/<slug>/proposal.md
    (fields: decision rationale, goal, explore targets, constraints)
       │
       ▼
  Orchestrator presents /sdd-ff <slug> recommendation
    + path to proposal.md + reminder to /memory-update
       │
  [session A ends]

New session (session B):
  User triggers /sdd-ff <slug>
       │
       ▼
  sdd-ff Step 0: infer slug → launch sdd-explore sub-agent
       │
       ▼
  sdd-explore Step 0 — Load project context
    [reads ai-context/stack.md, architecture.md, conventions.md, CLAUDE.md]
       │
       ▼
  sdd-explore Step 0 — Spec context preload
    [reads matching openspec/specs/<domain>/spec.md via stem match]
       │
       ▼
  sdd-explore Step 0 — Handoff context preload  ← NEW SUB-STEP
    check: openspec/changes/<slug>/proposal.md exists?
      YES → read proposal.md, extract intent fields
             log: "Handoff context loaded from: openspec/changes/<slug>/proposal.md"
             surface as "Handoff Context" section in exploration.md output
      NO  → skip silently (INFO note, non-blocking)
       │
       ▼
  sdd-explore Steps 1–5: investigate codebase (full analysis)
    → exploration.md written with optional "## Handoff Context" section
       │
       ▼
  sdd-ff Step 1: launch sdd-propose (reads exploration.md)
    → sdd-propose writes new proposal.md (overwrites seeded file — acceptable)
       │
       ▼
  sdd-ff Steps 2–4: spec + design (parallel) → tasks
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` (repo root) | Modify | Add Rule 6 — Cross-session ff handoff, after Rule 5 in Unbreakable Rules section |
| `skills/sdd-explore/SKILL.md` | Modify | Add "Handoff context preload" sub-step after Spec context preload in Step 0; non-blocking; reads `openspec/changes/<slug>/proposal.md` if present |

Note: The repo `CLAUDE.md` is the authoritative source. `~/.claude/CLAUDE.md` is deployed from it via `install.sh` — the apply step targets the repo file only.

## Interfaces and Contracts

### Rule 6 insertion point in CLAUDE.md

Position: immediately after Rule 5 (Feedback persistence), before the `---` separator and `## Plan Mode Rules`.

Rule 6 text contract:
```
### 6. Cross-session ff handoff
- When recommending a `/sdd-ff` that the user will run in a **new session**
  (trigger: user states "new session", "next chat", "context reset", or context compaction is imminent),
  I MUST first create `openspec/changes/<slug>/proposal.md` with:
  1. The architectural or design decision that triggered the change
  2. The specific goal of the ff (what success looks like)
  3. The files and artifacts the explore should target
  4. Any constraints or "do not do" items discovered in this session
- I MUST include the proposal path in the recommendation message.
- I MUST offer to run `/memory-update` inline or remind the user to run it.
- This rule does NOT apply to same-session `/sdd-ff` cycles.
```

### sdd-explore Step 0 sub-step: Handoff context preload

Position: after the Spec context preload sub-step, before Step 1.

Sub-step contract:
```
### Step 0 sub-step — Handoff context preload

This sub-step is **non-blocking**: any failure (missing file, unreadable file, no slug) MUST produce
at most an INFO-level note. This sub-step MUST NOT produce `status: blocked` or `status: failed`.

1. Resolve the change slug from the invocation context (same slug used in the change directory path).
2. Check whether `openspec/changes/<slug>/proposal.md` exists.
3. If absent: skip silently — log `INFO: no pre-seeded proposal.md found — proceeding without handoff context.`
4. If present: read the file. Treat its content as **supplemental intent enrichment**:
   - It informs what the explore should prioritize, not what the codebase shows.
   - It MUST NOT override live codebase findings.
   - Log: `Handoff context loaded from: openspec/changes/<slug>/proposal.md`
5. When loaded, include a `## Handoff Context` section in the exploration.md output
   (placed before `## Current State`) summarizing:
   - Decision that triggered the change
   - Goal and success criteria from the seeded proposal
   - Explore targets listed in the proposal
   - Constraints ("do not do" items)
```

### exploration.md output contract (addendum)

When handoff context is loaded, `exploration.md` gains an optional leading section:

```markdown
## Handoff Context

> Pre-seeded from openspec/changes/<slug>/proposal.md — intent from originating session.

**Decision**: [extracted from proposal]
**Goal**: [extracted from proposal]
**Explore targets**: [extracted from proposal]
**Constraints**: [extracted from proposal]
```

## Testing Strategy

| Layer | What to test | Tool |
| --- | --- | --- |
| Manual | Rule 6 fires when user says "new session" — orchestrator creates proposal.md | Manual orchestrator session |
| Manual | Rule 6 does NOT fire for same-session /sdd-ff cycles | Manual orchestrator session |
| Manual | sdd-explore reads pre-seeded proposal.md and includes Handoff Context section in exploration.md | Run /sdd-ff on a slug with a pre-seeded proposal.md |
| Manual | sdd-explore skips gracefully when no proposal.md exists (INFO only, no blocked) | Run /sdd-ff on a fresh slug with no proposal.md |
| Audit | /project-audit verifies CLAUDE.md still passes section headings check (Rule 6 addition is additive) | /project-audit |

No automated test runner in this project. Verification is done manually and via `/sdd-verify`.

## Migration Plan

No data migration required. Both changes are additive — no existing artifacts, skill behaviors, or CLAUDE.md rules are modified. The seeded `proposal.md` for this change already exists and will be consumed by the first `/sdd-ff` run against this slug.

## Open Questions

- Should `exploration.md` include the full text of the seeded proposal.md or only a structured summary? Recommended: structured summary (4 fields) to keep exploration.md scannable. Full text adds noise.
- Should the Handoff Context section be included in exploration.md when the seeded proposal.md has no `## Context for Next Session` marker? Recommended: yes — load any non-empty proposal.md, not just ones with the marker. Keeps the rule simple and the marker optional.
