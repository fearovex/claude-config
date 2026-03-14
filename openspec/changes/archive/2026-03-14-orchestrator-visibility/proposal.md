# Proposal: Orchestrator Visibility

## Problem Statement
There is no visible signal that the SDD Orchestrator is active in a session. Users cannot tell whether intent classification is being applied without explicitly asking Claude. This creates uncertainty about system behavior.

## Proposed Solution
1. Add a session banner rule in `CLAUDE.md` that Claude displays at the start of every session, confirming the orchestrator is active and showing the intent classification status.
2. Add a consistent conversational voice — prefix intent classification decisions in responses so the user always sees which class was assigned.
3. Create a `/orchestrator-status` skill that returns current orchestrator state on demand: classification active, active SDD changes, loaded skills.

## Intent
Add visible signals in every session confirming the SDD Orchestrator is active and showing which intent classes are being applied.

## Motivation
Users need confidence that the intent classification system is operating. Without visible feedback, users may:
- Doubt whether their free-form messages are being routed correctly
- Manually invoke `/sdd-ff` when intent classification would have triggered it
- Lose trust in the orchestrator's autonomous behavior

## Scope

### Included
- Session-start banner in system prompt (CLAUDE.md modification)
- Intent classification signal in responses (orchestrator behavior change)
- `/orchestrator-status` skill (new, on-demand status query)
- Documentation of new signal format in CLAUDE.md

### Excluded
- Persistent logging of intent classification decisions (no audit trail)
- User preference toggle for banner visibility (always-on for now)
- Programmatic API for intent classification (CLI only)

## Affected Areas

| Area | Impact | Notes |
|------|--------|-------|
| `CLAUDE.md` | Moderate | Add system prompt section for banner; update Always-On Orchestrator rules |
| Orchestrator behavior | Moderate | Inject intent-class signal into response preamble for free-form messages |
| Skills catalog | Low | Add new `/orchestrator-status` skill |
| User docs | Low | Update `docs/orchestrator.md` with signal examples |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Banner spam in multi-turn conversations | Medium | Users may find repeated banners annoying | Banner appears once per session; no repetition per turn |
| Intent class signal breaks existing workflows | Low | Users relying on opaque orchestrator behavior | Signal is informational only; does not change routing |
| `/orchestrator-status` command collides with future skills | Low | Command namespace pollution | Use clear naming; document in CLAUDE.md registry |

## Rollback Plan

If the feature creates confusion or degrades UX:
1. Remove banner section from system prompt (revert CLAUDE.md)
2. Disable intent-class signal injection (revert orchestrator code)
3. Remove `/orchestrator-status` skill from registry (delete .claude/skills/orchestrator-status/)
4. Revert user docs changes
5. Test in a fresh session to confirm silence

## Dependencies

- CLAUDE.md must be read and parsed by orchestrator (already true)
- Skills registry must support `/orchestrator-status` routing (already true)
- No external dependencies

## Effort Estimate

**Low** — This is primarily configuration and behavioral signaling:
- Banner text: 10 minutes
- Intent signal injection: 20 minutes (mostly orchestrator logic)
- `/orchestrator-status` skill: 20 minutes (query and render)
- Docs: 10 minutes
- **Total**: ~1 hour

## Success Criteria
- [ ] Every new session starts with a visible orchestrator banner
- [ ] Every response to a free-form message shows the intent class assigned
- [ ] `/orchestrator-status` returns meaningful state in under 2 seconds
- [ ] Rollback plan is tested and documented
- [ ] All three approaches from Proposed Solution are implemented
