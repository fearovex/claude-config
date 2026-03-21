# Proposal: SDD Cycle Context Gaps — System Overhaul

Date: 2026-03-19
Status: Draft

## Intent

Fix six interconnected failures in the SDD orchestrator and phase skills that occur when users request changes involving replacement of prior implementations, contradictions with documented constraints, or removal of artifacts not just addition.

## Motivation

During recent sessions, three critical system failures emerged that reveal architectural gaps in how the SDD meta-system handles replacement changes and context contradictions:

1. **Auth flow replacement session**: User requested "redirect to login on 401, and remove the periodic membership refresh hook." The `sdd-explore` skill did NOT identify the prior hook implementation; `sdd-propose` generated a proposal with zero mention of removal; `sdd-spec` invented a requirement to KEEP the hook. User had to argue against their own specs to get the removal they requested.

2. **Mark Complete button session**: User requested "make the Mark Complete button do SharePoint write-back instead of in-memory simulation." `sdd-explore` did NOT surface prior context notes saying "provisional pending EWP integration"; `sdd-propose` omitted mobile constraints mentioned in conversation. Agent silently refused to implement because specs protected the provisional behavior; user never learned why.

3. **Cross-session repeat**: User (in a new session) requested "implement feature X." `sdd-explore` did NOT check archived prior attempts on feature X. Agent repeated the same approach that already failed in a previous cycle.

These failures reveal that the SDD phase flow was not designed to handle replacement changes, contradictions between user intent and documented state, or removal of prior artifacts. The root cause is architectural: explore, propose, and spec phases operate in isolation without explicit handling of:
- Branch-local diffs and prior implementations
- Prior failed attempts in archive
- Context contradictions between user input, conversation history, and documented constraints
- Explicit removal semantics (Supersedes section in proposal)

## Scope

### Included

1. **sdd-explore SKILL.md** — Add branch-local diff scan, prior attempts detection (archive search), and context contradiction identification
2. **sdd-propose SKILL.md** — Add `## Supersedes` section to proposal template; enumerate removals and replacements; preserve conversation context
3. **sdd-spec SKILL.md** — Add rule to prevent unconfirmed preservation requirements; cross-check against proposal Supersedes section
4. **sdd-tasks SKILL.md** — Add rule to generate removal tasks from Supersedes section
5. **sdd-ff SKILL.md** — Add pre-population of proposal.md before launching explore; add gate for UNCERTAIN contradictions
6. **CLAUDE.md (global)** — Add orchestrator instruction to extract conversation context before confirming /sdd-ff launch

### Excluded (explicitly out of scope)

- Changes to sdd-design, sdd-apply, sdd-verify, sdd-archive (they do not participate in the context-gap failures)
- Addition of a new artifact type or storage mechanism (we remain file-based, no database)
- New skills or commands — we only modify existing phase mechanics
- Orchestrator session context passing via environment variables (we stay inline in SKILL.md)

## Proposed Approach

**Unified SDD cycle** for all six skill updates and orchestrator changes. This approach:

1. **Consolidates the six feedback items into one coherent architectural overhaul** — all items address the same root cause (missing context at each phase boundary)
2. **Specifies unified artifact contracts** — defines the proposal.md `Supersedes` section, exploration.md new sections (Branch Diff, Prior Attempts, Contradiction Analysis), and how spec/tasks consume these sections
3. **Enforces sequencing in apply** — propose → spec → tasks must happen in strict order so downstream phases can rely on upstream artifacts
4. **Single verify step** — tests that explore, propose, spec, and tasks work together with the new sections
5. **Single archive step** — all skills updated coherently together

**Why unified instead of six separate changes or two phased changes:**
- Six separate changes = high coordination risk; loose coupling between skills means integration failures late in the cycle
- Two phased changes = Phase 1 leaves system partially broken (proposal.md exists but orchestrator never pre-populates it); Phase 2 has hard dependency
- One unified change = architectural contracts defined upfront; sequenced apply prevents integration surprises; single verify ensures coherence; single archive is a clean point

## Affected Areas

| Area/Module | Type of Change | Impact | Risk |
| --- | --- | --- | --- |
| `~/.claude/skills/sdd-explore/SKILL.md` | Modified (Steps 1–3 expanded) | Exploration.md gains three new sections; no breakage of existing output | Low (additive; existing sections preserved) |
| `~/.claude/skills/sdd-propose/SKILL.md` | Modified (Step 4 extended, new Step 7) | Proposal.md gains Supersedes section; conversation context captured | Low (Supersedes optional for purely additive changes) |
| `~/.claude/skills/sdd-spec/SKILL.md` | Modified (Step 1 extended) | New cross-check rule reads proposal Supersedes; prevents unconfirmed preservation requirements | Medium (may reject invalid specs; users must fix) |
| `~/.claude/skills/sdd-tasks/SKILL.md` | Modified (Step 3 new logic) | Task generation now includes removal tasks inferred from Supersedes section | Low (additive; existing task logic unchanged) |
| `~/.claude/skills/sdd-ff/SKILL.md` | Modified (Step 0 new substep, Step 2 new gate) | Proposal.md pre-populated with context; new UNCERTAIN contradiction gate | Medium (introduces confirmation gate; may delay some cycles) |
| CLAUDE.md (global) | Modified (Unbreakable Rules 5 extension) | New instruction: orchestrator extracts conversation context before confirming /sdd-ff | Low (inline rule; no new skill) |
| Archive/Docs | Optional: ADR 040 documenting context-contradiction handling convention | Supplementary; not blocking | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| **Integration gap if apply sequencing is wrong** | Medium | Apply updates spec before propose finishes → specs fail reading Supersedes section | Apply must follow strict sequence; Phase dependencies enforced in tasks.md; verification step tests the full chain |
| **Backwards compatibility with archived proposals** | Low | Archived proposal.md and exploration.md files won't have new sections | New sections are optional (backfill not required); phases tolerate missing prior sections |
| **Breaking active SDD cycles** | Low | User with in-progress /sdd-ff when overhaul installs → new contracts may break during apply | Skills changes live immediately; users' in-progress cycles inherit new rules (acceptable since sdd-ff is re-startable) |
| **Proposal verification complexity** | Medium | Verify step must test explore, propose, spec, tasks all work together with new sections | Create a test scenario in verify including a proposal with Supersedes, context contradictions, and prior attempts |
| **Documentation lag** | Low | CLAUDE.md global instructions out of sync with skill updates | Proposal lists exact CLAUDE.md rules needed; sdd-design surfaces this as a documentation action item |
| **User confusion with Supersedes section** | Low | Users unfamiliar with the new section may omit it or misuse it | Document in sdd-propose Step 5 that Supersedes is always present (say "None — purely additive" if empty); default template clarifies intent |

## Rollback Plan

If the integrated changes break active SDD cycles or introduce critical spec bugs:

1. **Via git**: `git checkout HEAD~1` in the agent-config repo (reverts all six skills + CLAUDE.md in one commit)
2. **Via install.sh**: `bash install.sh` re-deploys the reverted skills to `~/.claude/`
3. **Sessions in progress**: Re-run `/sdd-ff` to pick up the reverted skill behavior; in-progress tasks.md will be stale but users can discard and restart
4. **No data loss**: All artifacts (openspec/changes/, ai-context/) remain intact; only skill behavior reverts

## Dependencies

- All six SDD phase skills must update in coordinated order (see sequencing in Apply Strategy below)
- CLAUDE.md global orchestrator rule injection depends on all skills being updated (otherwise orchestrator extracts context but no skill consumes it)
- No upstream dependencies: this change does not require prior skills to be modified; it only adds new capability

## Success Criteria

- [ ] **explore.md now includes three new sections** (Branch Diff, Prior Attempts, Contradiction Analysis) with no loss of existing content
- [ ] **proposal.md always includes Supersedes section** — if nothing is superseded, explicitly states "None — purely additive change"
- [ ] **spec.md respects proposal Supersedes** — validation rule prevents adding "preserve existing X" when proposal says "remove X"
- [ ] **tasks.md includes removal tasks** — when Supersedes section lists removals, corresponding task entries are generated in tasks breakdown
- [ ] **sdd-ff gate prevents contradictions** — contradictions marked UNCERTAIN in exploration.md trigger a confirmation gate before proposing
- [ ] **Orchestrator context extraction works** — /sdd-ff prompts user to confirm any removal or replacement intent stated in conversation
- [ ] **Verify reports positive test case** — test scenario includes proposal with Supersedes, contradiction analysis, prior attempts; verify passes
- [ ] **No regressions in existing cycles** — existing proposals without Supersedes (old format) are still accepted and processed correctly
- [ ] **Documentation updated** — ADR 040 added (if creating one); sdd-propose help text clarifies Supersedes semantics

## Effort Estimate

**Medium** (2–3 days)
- sdd-explore: ~6–8 hours (new diff scan, archive search, contradiction detection logic)
- sdd-propose: ~4–6 hours (Supersedes section, conversation context preservation)
- sdd-spec: ~3–4 hours (cross-check rule against Supersedes)
- sdd-tasks: ~2–3 hours (removal task generation from Supersedes)
- sdd-ff: ~4–5 hours (proposal pre-population, contradiction gate)
- CLAUDE.md: ~1–2 hours (orchestrator rule injection)
- verify + archive: ~3–4 hours (test scenario, documentation)

Total: ~23–33 hours. Given SDD cycle structure (explore → propose → spec+design → tasks → apply → verify → archive) with careful sequencing, realistic timeline is 2–3 session-days.

---

## Open Questions Resolved by Exploration

1. **Should prior attempts trigger a user gate?** → Gate only on UNCERTAIN contradictions; prior attempts logged as INFO and included in exploration.md for user awareness
2. **How much conversation context to extract?** → Explicit patterns in sdd-ff: "remove X", "careful with Y", "mobile must not..."
3. **Is Supersedes always required?** → Yes, always present; if nothing superseded, explicitly state "None — purely additive"
4. **What scope of constraint matters?** → Constraints captured as stated; spec phase elaborates technical implications

---

## Next Steps

Ready for spec + design phases (can run in parallel).

Spec phase: Define unified artifact contracts for exploration.md, proposal.md, and their consumption by spec/tasks.
Design phase: Create detailed skill-update plan with pseudocode for each new section/rule.
