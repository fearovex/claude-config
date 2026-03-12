---
title: Rename Project from claude-config to agent-config
status: Draft
author: Claude Code
date: 2026-03-12
related-change: openspec/changes/2026-03-12-rename-to-agent-config/
---

# PRD: Rename Project from claude-config to agent-config

## Problem Statement

The project is named `claude-config`, which creates confusion because:
1. "Claude" could refer to the Anthropic LLM, when the project is actually a configuration system for Claude Code (a platform for building AI agents)
2. The runtime directory `~/.claude/` already uses "claude" as the canonical platform name
3. The long-term vision is to support configuration for multiple agent platforms (GitHub Copilot, Gemini, Cursor, future integrations), but the current name locks us to a single company/model perspective
4. "agent-config" better reflects the project's purpose and is more future-proof

## Target Users

- Primary: Developers using Claude Code who clone and deploy this configuration
- Secondary: Maintainers and contributors to the claude-config project
- Tertiary: Future teams building configurations for other AI agent platforms

## User Stories

### Must Have

- As a developer, I want the project name to accurately describe what it does so that I understand it is a general agent configuration system, not Claude-specific
- As a future contributor, I want the project name to be future-proof so that it can extend to other platforms without becoming misleading
- As a project maintainer, I want consistent terminology across all documentation so that users don't encounter conflicting references

### Should Have

- As a developer, I want all examples and documentation updated to use the new name so that I don't copy outdated paths
- As a maintainer, I want all internal references updated so that the codebase is coherent and maintainable

### Could Have

- As a user reading the code, I want ADRs and historical documentation to remain historically accurate so that future decisions can learn from context

### Won't Have

- Renaming the `~/.claude/` runtime directory — OUT OF SCOPE: this is controlled by Claude Code itself
- GitHub repository rename — OUT OF SCOPE: this is an administrative operation separate from code changes
- Functional changes to skills or the SDD system — OUT OF SCOPE: this is purely a naming change

## Non-Functional Requirements

- All Markdown and YAML files must remain valid and parseable after the rename
- `install.sh` and `sync.sh` must continue to work without modification (they use relative paths and are immune to the rename)
- No functional changes to any skill, script, or system behavior — only text updates
- All references must be semantically correct (project identity, not incidental examples)
- Change must be reversible via `git revert` if needed

## Acceptance Criteria

- [ ] All user-facing documentation (README, CLAUDE.md) reflects "agent-config" as the project name
- [ ] openspec/config.yaml project metadata (`name`, `root`) updated to "agent-config"
- [ ] ai-context/ memory files (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md) updated with new project name
- [ ] All 49 SKILL.md files reviewed and updated for project-name references in path examples and step descriptions
- [ ] Documentation files (docs/adr/README.md, docs/*.md) updated to reference "agent-config"
- [ ] Remaining grep search for "claude-config" returns only incidental matches (examples, historical records, or code comments)
- [ ] `bash install.sh` executes without error and correctly deploys to ~/.claude/
- [ ] `bash sync.sh` executes without error and memory capture functions as before
- [ ] No broken symbolic links, paths, or file references introduced

## Notes

- This change is low-risk because the project name is a documentation/metadata concern, not a functional component
- The name change is particularly important because it aligns with the SDD meta-system's vision of being a general-purpose agent configuration framework
- Implementation should be staged by file category (config → memory → skills → docs) to allow incremental validation
