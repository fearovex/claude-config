# Task Plan: 2026-03-18-context-handoff-between-sessions

Date: 2026-03-18
Design: openspec/changes/2026-03-18-context-handoff-between-sessions/design.md

## Progress: 5/5 tasks

## Phase 1: CLAUDE.md Rule Addition

- [x] 1.1 Modify `CLAUDE.md` (repo root) — insert Unbreakable Rule 6 "Cross-session ff handoff" immediately after Rule 5 (Feedback persistence) and before the `---` separator that precedes `## Plan Mode Rules`. Rule text must include: trigger signals (user states "new session", "next chat", "context reset", or compaction is imminent), four required fields for the seeded proposal.md (decision rationale, specific goal, explore targets, constraints/do-not-do items), obligation to include proposal path in the recommendation message, obligation to offer /memory-update, and explicit exclusion of same-session /sdd-ff cycles.

## Phase 2: sdd-explore Skill Update

- [x] 2.1 Modify `skills/sdd-explore/SKILL.md` — add "Handoff context preload" sub-step immediately after the existing "Spec context preload" sub-step in Step 0, and before Step 1. The sub-step must: (a) resolve the change slug from invocation context, (b) check for `openspec/changes/<slug>/proposal.md`, (c) skip silently with INFO note if absent, (d) if present: read the file, treat it as supplemental intent enrichment (non-overriding), log `Handoff context loaded from: openspec/changes/<slug>/proposal.md`, and (e) specify that exploration.md must include a `## Handoff Context` section (before `## Current State`) summarizing the four fields: decision, goal, explore targets, constraints.

## Phase 3: Deployment

- [x] 3.1 Run `install.sh` from the repo root (`C:/Users/juanp/claude-config/`) to deploy the modified `CLAUDE.md` and `skills/sdd-explore/SKILL.md` to `~/.claude/`. Verify the deployed `~/.claude/CLAUDE.md` contains Rule 6 and `~/.claude/skills/sdd-explore/SKILL.md` contains the Handoff context preload sub-step.

## Phase 4: Verification

- [x] 4.1 Manually verify Rule 6 trigger precision: confirm the rule text distinguishes between new-session triggers (explicit user signal or compaction warning) and same-session /sdd-ff cycles (Rule 6 must NOT fire). Confirm the four required proposal.md fields are enumerated in the rule.
- [x] 4.2 Manually verify sdd-explore sub-step: confirm the sub-step is non-blocking (absent proposal.md → INFO only, no blocked/failed), confirm the Handoff Context section placement in exploration.md output contract is specified, and confirm it does not override live codebase findings.

## Phase 5: Cleanup

- [x] 5.1 Update `ai-context/changelog-ai.md` — record this session's changes: Rule 6 added to CLAUDE.md, Handoff context preload sub-step added to sdd-explore/SKILL.md, install.sh run.

---

## Implementation Notes

- Both file modifications are purely additive — no existing content in CLAUDE.md or sdd-explore/SKILL.md is removed or changed. Only insertions.
- The repo `CLAUDE.md` is the authoritative source; `~/.claude/CLAUDE.md` is a deployed copy. Task 1.1 targets the repo file only. Task 3.1 (install.sh) handles runtime deployment.
- The sdd-explore sub-step must use the same non-blocking pattern as the existing Spec context preload sub-step — examine that sub-step's wording as a reference for consistency.
- The `exploration.md` output contract addendum (Handoff Context section with four fields) is specified in the design — the sub-step text in SKILL.md must name these four fields explicitly so the explore sub-agent knows what to extract.
- Do NOT modify `sdd-ff/SKILL.md` or `sdd-propose/SKILL.md` — explicitly out of scope per proposal.

## Blockers

None.
