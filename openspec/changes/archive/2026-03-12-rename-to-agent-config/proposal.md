# Proposal: Rename project from `claude-config` to `agent-config`

Date: 2026-03-12
Status: Draft

## Intent

Rename the project from `claude-config` to `agent-config` to better reflect its role as a global agent configuration system for Claude Code, improving clarity and reducing naming confusion with the Claude AI model itself.

## Motivation

The project currently uses the name `claude-config`, which can be confusing because:
1. "Claude" could refer to the LLM model, while the project is really about Claude Code — the platform for building AI agents
2. The runtime directory `~/.claude/` already uses "claude" as the canonical name
3. "agent-config" more accurately describes the project's purpose: serving as the source-of-truth configuration for AI agents built with Claude Code
4. The long-term vision is to support configuration for multiple agent platforms and models (GitHub Copilot, Gemini, Cursor, future agents)

This change improves both internal clarity and external communication about what the system does.

## Scope

### Included

- Rename all references to "claude-config" in user-facing documentation (README.md, CLAUDE.md)
- Update project metadata (openspec/config.yaml)
- Update all internal project-context references in ai-context/ files (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md)
- Update example code, step descriptions, and path references in all 49 SKILL.md files where they reference the project name
- Update ADR documentation index and contextual references (docs/adr/README.md)
- Update other documentation files (docs/*.md) that reference the project name
- Update GitHub Copilot integration file (.github/copilot-instructions.md) if present
- Update any helper scripts or configuration files referencing the old name

### Excluded (explicitly out of scope)

- The runtime directory `~/.claude/` — this is controlled by Claude Code itself and is immutable
- GitHub repository rename — this is an administrative action that happens separately after code changes are ready
- Git history rewriting — this is a one-way operation that should not be done
- Examples or historical references in ADRs where the old name is part of the historical record (preserve ADR content verbatim for accuracy)

## Proposed Approach

**Targeted semantic replacement** — categorize files by type and apply strategic replacements:

1. **Stage 1: Critical config files** — Direct replacement in README.md, CLAUDE.md (8 occurrences), openspec/config.yaml (2 occurrences in `name` and `root` fields)

2. **Stage 2: AI context / project memory** — Update ai-context/ files to reflect the new project name (30 occurrences across 5 memory files)

3. **Stage 3: Skill documentation** — Systematically update 49 SKILL.md files where they reference the project name in step descriptions and examples (280+ occurrences distributed)

4. **Stage 4: Documentation** — Update docs/ directory files including ADR index (docs/adr/README.md) and other architectural docs (20+ occurrences)

5. **Stage 5: Verification** — Confirm install.sh and sync.sh work unchanged (they already use relative paths), spot-check for incidental references that should remain

**Key principle**: Use targeted find-and-replace with careful review rather than blind global replacement. Preserve intentional references (example code, historical ADR context) while updating project-identity references.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| README.md | Modified | Direct project name references (title, description) |
| CLAUDE.md | Modified | Architecture diagram, install/sync path examples |
| openspec/config.yaml | Modified | Project name and root path metadata |
| ai-context/ (5 files) | Modified | Project identity in stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md |
| SKILL.md files (49 files) | Modified | Path examples, step descriptions, project context |
| docs/adr/README.md | Modified | ADR index and contextual references |
| docs/*.md (other) | Modified | Documentation referencing project context |
| .github/copilot-instructions.md | Modified | Project description (if exists) |
| install.sh | None | Uses relative paths — no changes needed |
| sync.sh | None | Uses $HOME/.claude — no changes needed |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Unintended replacements in code examples or inline docs | Medium | Medium | Carefully review each file category before bulk replacement; spot-check skill examples |
| Incomplete coverage — missing scattered references | Medium | Low | Use structured grep to find all remaining "claude-config" references after apply phase |
| Accidental breakage of paths in shell commands | Low | Medium | Verify install.sh and sync.sh continue to work with relative paths (they are immune) |
| Commits to wrong branch during implementation | Low | Medium | Use SDD apply phase which enforces branch discipline |

## Rollback Plan

**Revert via Git:**
1. `git diff HEAD~1..HEAD` — verify the commit contains only rename changes
2. `git revert <commit-hash>` — safely reverts all changes
3. `bash install.sh && git commit` — redeploy original config

Alternatively, if changes are staged but not committed:
- `git checkout -- .` — discard all unstaged changes
- `git reset` — unstage all staged changes

## Dependencies

- None. This change is independent and does not depend on other work.

## Success Criteria

- [ ] All references to "claude-config" as the project name in user-facing docs (README, CLAUDE.md) are updated to "agent-config"
- [ ] openspec/config.yaml metadata fields (`name`, `root`) reflect "agent-config"
- [ ] ai-context/ files (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md) are updated to reference "agent-config" in project identity sections
- [ ] All 49 SKILL.md files have been reviewed and updated where they reference the project name (example paths, step descriptions)
- [ ] docs/ documentation files that reference the project name are updated (at least docs/adr/README.md)
- [ ] Remaining grep search for "claude-config" returns <5 matches (only in examples, historical context, or incidental references)
- [ ] `bash install.sh` runs without error and deploys changes to ~/.claude/
- [ ] `bash sync.sh` runs without error (unchanged)
- [ ] Verification step confirms all changes are semantically correct (not just text replacements)

## Effort Estimate

Medium (1-2 days)

Breakdown:
- Stage 1 (config files): ~30 minutes
- Stage 2 (ai-context): ~30 minutes
- Stage 3 (49 SKILL.md files): ~4-6 hours (requires careful review per file)
- Stage 4 (docs): ~1-2 hours
- Stage 5 (verification): ~1 hour
