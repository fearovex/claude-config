# Proposal: sdd-project-context-awareness

Date: 2026-03-10
Status: Draft

## Intent

Ensure that SDD phase skills (`sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) consistently read and reflect the project's local configuration, `ai-context/` memory layer, and registered skills catalog before producing any output.

## Motivation

When SDD skills execute on a project, they operate from the global `~/.claude/skills/` catalog without loading the project's CLAUDE.md, `ai-context/` files, or local `.claude/` configuration. This means:

- Design and spec outputs don't align with the project's actual tech stack or conventions
- Skill recommendations reference global skills not registered in the project
- Decisions made in one session are not carried forward into subsequent SDD cycles
- The `ai-context/` memory layer exists but is not reliably consumed by sub-agents

The result is reduced quality in generated artifacts and the user needing to re-explain context in every session.

## Scope

### Included

- Add explicit `ai-context/` reading steps to `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, and `sdd-apply` SKILL.md files
- Each sub-agent prompt must include: read `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md` before producing output
- `sdd-design` must cross-reference the project's registered skills catalog (project CLAUDE.md Skills Registry) when recommending tools or patterns
- Document the context injection pattern in `docs/` for future skill authors

### Excluded

- Changes to `memory-init`, `memory-update`, or `project-analyze`
- Automatic detection of whether `ai-context/` is stale — that is handled by `project-analyze`
- Changes to the global orchestrator delegation pattern in CLAUDE.md

## Proposed Approach

Each SDD phase SKILL.md gains a mandatory **Context Loading** step as the first step of its Process section:

```
STEP 0 — Load project context:
  1. Read ai-context/stack.md (tech stack and versions)
  2. Read ai-context/architecture.md (architectural decisions)
  3. Read ai-context/conventions.md (naming and code patterns)
  4. Read project CLAUDE.md Skills Registry (registered skills)
  If any file is absent: note it and continue — do not abort.
```

This step precedes all analysis and output generation.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-explore/SKILL.md` | Modified | Medium |
| `skills/sdd-propose/SKILL.md` | Modified | Medium |
| `skills/sdd-spec/SKILL.md` | Modified | High |
| `skills/sdd-design/SKILL.md` | Modified | High |
| `skills/sdd-tasks/SKILL.md` | Modified | High |
| `skills/sdd-apply/SKILL.md` | Modified | High |
| `docs/sdd-context-injection.md` | New | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| `ai-context/` files absent on project — sub-agent aborts | Medium | High | Require graceful degradation: log missing files, continue with global defaults |
| Context loading increases token usage per sub-agent | High | Low | Files are small by design; acceptable cost |
| Sub-agents over-adapt to stale `ai-context/` | Medium | Medium | Sub-agents note `Last analyzed:` date; warn if older than 7 days |

## Success Criteria

- [ ] All 6 SDD phase skills have a Step 0 context loading block
- [ ] Running `/sdd-ff` on a project with populated `ai-context/` produces output that references the project's actual stack and conventions
- [ ] Running `/sdd-ff` on a project without `ai-context/` does not abort — it logs missing files and continues
- [ ] `verify-report.md` has at least one [x] criterion checked
