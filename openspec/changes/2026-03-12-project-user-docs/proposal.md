# Proposal: Project User Documentation

## Problem Statement

The project (`agent-config`) lacks user-facing documentation explaining what it does, what capabilities it provides, and how the global/local CLAUDE.md relationship works. A new user (or the owner returning after time) has no entry point beyond reading the raw CLAUDE.md.

Specific gaps:
- No explanation of what the user gains by running `install.sh`
- No documentation of how global vs. local `CLAUDE.md` interact (combination, precedence, conflict resolution)
- No guide on how to resolve conflicts between global and project-level config
- No overview doc aimed at a human reader (not an AI agent)

## Proposed Solution

Create a `docs/user-guide.md` covering:

1. **What this project is** — a meta-config system that deploys AI assistant capabilities to all your projects
2. **How it works** — `install.sh` → `~/.claude/` → picked up by every Claude Code session
3. **Global vs. local CLAUDE.md** — how they combine, what takes precedence, and when conflicts occur
4. **Conflict resolution guide** — step-by-step: `/project-audit` → `/project-fix` → `/project-update`
5. **Available commands** — human-readable summary of what you can do (SDD cycle, meta-tools, memory)
6. **Quick-start** — for someone setting up a new project from scratch

## Success Criteria

- [ ] `docs/user-guide.md` exists and covers all 6 sections above
- [ ] The global/local CLAUDE.md interaction is explained with a concrete example
- [ ] Conflict resolution workflow is documented step-by-step
- [ ] Document is written for a human reader, not an AI agent
- [ ] Linked from `README.md`
