# Proposal: Context Handoff Between Sessions

Date: 2026-03-18
Status: Draft

## Intent

Enable the orchestrator to persist its reasoning and intent when a `/sdd-ff` recommendation must be executed in a new session, so `sdd-explore` does not run cold.

## Motivation

When a conversation approaches context compaction (or when the user explicitly defers a change to a new session), the orchestrator recommends a `/sdd-ff <slug>` command. The architectural reasoning behind that recommendation — what problem was found, what constraints were identified, what the explore should focus on — lives only in the conversation context and is lost when the session ends.

The next session starts with only `ai-context/` and `CLAUDE.md` as orientation. `sdd-explore` runs Step 0 without any record of the "why" from the originating session, and `sdd-propose` synthesizes from exploration alone. The change may still succeed, but it may miss the specific concern or constraint that motivated it.

The feedback-session Rule 5 pattern (Unbreakable Rule 5) partially addresses this — but only for explicit user-feedback sessions. The common case — orchestrator recommends a fix mid-conversation, user defers to a new session — is not covered by any rule.

The current change is itself proof of the gap: a `proposal.md` was manually seeded in this change directory by the originating session, and the exploration phase was able to orient itself because of it. That behavior should be a rule, not an accident.

## Scope

### Included

- Add **Unbreakable Rule 6** to `CLAUDE.md` (both repo and global): cross-session ff handoff rule requiring the orchestrator to create a `proposal.md` before closing a recommendation that will execute in a new session
- Update `skills/sdd-explore/SKILL.md` Step 0 to read a pre-seeded `proposal.md` if present in the change directory and treat it as **supplemental intent context** (non-blocking, additive)
- Run `install.sh` to deploy the updated files to `~/.claude/`

### Excluded (explicitly out of scope)

- Changes to `sdd-ff/SKILL.md` propose phase — `sdd-propose` already reads `exploration.md`; the pre-seeded `proposal.md` serves explore, not propose (accepted: sdd-propose will overwrite it with a proper proposal built from exploration findings)
- A new `/context-handoff` skill — Rule 6 in CLAUDE.md is sufficient; a dedicated skill would add friction and overhead for what is an orchestrator behavioral convention
- Modifying `sdd-ff/SKILL.md` propose orchestration to merge or enrich pre-seeded proposals — complexity with unclear ROI (Approach C, rejected)
- `/memory-update` integration — while the originating `proposal.md` mentioned this, it is already addressed by the existing changelog-ai.md workflow; not required for the handoff mechanism

## Proposed Approach

**Approach B** (recommended by exploration phase):

1. **Supply side — CLAUDE.md Rule 6**: Add a new Unbreakable Rule to CLAUDE.md specifying that when the orchestrator recommends a `/sdd-ff` the user will run in a new session, it MUST first create `openspec/changes/<slug>/proposal.md` with: the decision rationale, the specific goal, the artifacts/files the explore should target, and any constraints or "do not do" items. The rule must define the trigger signals precisely (explicit user statement, context compaction warning, or end-of-session deferral) to avoid over-application in same-session cycles.

2. **Demand side — sdd-explore Step 0 sub-step**: Add a non-blocking sub-step to `sdd-explore` Step 0 that checks whether `openspec/changes/<slug>/proposal.md` already exists before starting investigation. If present, the file is read and its content is treated as supplemental intent context — the same pattern used by spec context preload (Step 0c). This orients the explore's investigation without overriding what the codebase shows.

Together these form a closed loop: the orchestrator seeds the proposal (supply); sdd-explore consumes it (demand). The seeded proposal's content flows into `exploration.md` and then indirectly into `sdd-propose`, which creates the final `proposal.md` from exploration findings.

## Affected Areas

| Area/Module | Type of Change | Impact |
| --- | --- | --- |
| `CLAUDE.md` (global + repo) | Modified — new Unbreakable Rule 6 added | High |
| `skills/sdd-explore/SKILL.md` | Modified — Step 0 gains proposal.md sub-step | Medium |
| `install.sh` (deploy) | Run, not modified | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| sdd-propose overwrites pre-seeded proposal.md, losing originating session context | Low | Low | Accepted: the seeded proposal is consumed by sdd-explore, which writes findings into exploration.md; sdd-propose reads exploration.md. The handoff context reaches sdd-propose indirectly. The seeded file is advisory, not final. |
| Rule 6 trigger ambiguity — "will run in a new session" is subjective | Medium | Medium | The rule spec must enumerate explicit trigger signals: user says "in a new session", context compaction warning appears, or user explicitly defers the ff command. Same-session cycles must be excluded. |
| Two CLAUDE.md files to update (repo + runtime) | Low | Low | Standard: install.sh deploys repo → ~/.claude/. Apply step targets repo file only; install.sh handles the rest. |
| sdd-explore Step 0 addition breaks existing explore flow | Low | Low | Sub-step is non-blocking — if proposal.md is absent, skip silently. Existing explore logic is unchanged. |

## Rollback Plan

Both changes are additive:

1. **CLAUDE.md Rule 6**: Remove the Rule 6 section from `CLAUDE.md` (repo file) and re-run `install.sh`. No artifacts created by the rule are permanent — any `proposal.md` files created under the rule are inert if the rule is removed.
2. **sdd-explore Step 0 sub-step**: Remove the sub-step lines from `skills/sdd-explore/SKILL.md` (repo) and re-run `install.sh`. The sub-step is non-blocking — its removal has no downstream effect.

Both files are under git version control. A simple `git revert` of the commit that applies these changes restores the prior state.

## Dependencies

- No external dependencies
- `install.sh` must be run after apply to deploy the changes to `~/.claude/`
- The SDD apply phase must target the repo files (`C:/Users/juanp/claude-config/`), not `~/.claude/` directly

## Success Criteria

- [ ] `CLAUDE.md` (repo) contains an explicit Unbreakable Rule 6 titled "Cross-session ff handoff"
- [ ] Rule 6 defines at least two named trigger signals (user deferral statement, context compaction warning)
- [ ] Rule 6 specifies the required content of the seeded `proposal.md` (decision rationale, goal, explore targets, constraints)
- [ ] `skills/sdd-explore/SKILL.md` Step 0 includes a sub-step that reads a pre-existing `proposal.md` if present and treats it as supplemental intent context
- [ ] The sdd-explore sub-step is non-blocking: absent `proposal.md` → silent skip; present → enriches investigation scope
- [ ] `install.sh` is run after apply and the changes are deployed to `~/.claude/`
- [ ] A new session starting `/sdd-ff 2026-03-18-context-handoff-between-sessions` on a cold context can orient its explore from the pre-seeded `proposal.md` without requiring a long seed message

## Effort Estimate

Low (hours) — two file modifications, both additive. No new skills, no schema changes, no orchestration rewiring.
