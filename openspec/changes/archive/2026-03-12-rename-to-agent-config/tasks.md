# Task Plan: 2026-03-12-rename-to-agent-config

Date: 2026-03-12
Design: openspec/changes/2026-03-12-rename-to-agent-config/design.md

## Progress: 23/23 tasks

---

## Phase 1: Critical Configuration Files

- [x] 1.1 Modify `README.md` — replace "claude-config" with "agent-config" in project title and description (top 50 lines)
- [x] 1.2 Modify `CLAUDE.md` — update architecture diagram: change "claude-config (repo)" to "agent-config (repo)" and update path references from `~/claude-config` to `~/agent-config`
- [x] 1.3 Modify `openspec/config.yaml` — update `name` field from "claude-config" to "agent-config" and `root` field from `"~/claude-config"` to `"~/agent-config"`

---

## Phase 2: Project Memory and Context Files

- [x] 2.1 Modify `ai-context/stack.md` — update H1 title and project identity references from "claude-config" to "agent-config" (title, directory tree heading, project descriptions)
- [x] 2.2 Modify `ai-context/architecture.md` — update H1 title and architecture diagram labels that reference "claude-config" from "claude-config" to "agent-config"
- [x] 2.3 Modify `ai-context/conventions.md` — update H1 title from "claude-config" to "agent-config"
- [x] 2.4 Modify `ai-context/known-issues.md` — update H1 title if it references "claude-config" as project name

---

## Phase 3: Documentation and ADR Updates

- [x] 3.1 Modify `docs/adr/README.md` — update intro sentence and project-context references from "claude-config" to "agent-config" (preserve ADR historical content verbatim)
- [x] 3.2 Scan `docs/*.md` (excluding ADR bodies) and update any direct project-name references from "claude-config" to "agent-config"
- [x] 3.3 Scan `docs/templates/` and update template file references if they mention the project name

---

## Phase 4: Skill Documentation Updates

- [x] 4.1 Update SKILL.md files in skills/sdd-* (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-ff, sdd-new, sdd-status) — replace example paths and project-context references from `claude-config` to `agent-config`
- [x] 4.2 Update SKILL.md files in skills/project-* (project-setup, project-onboard, project-audit, project-analyze, project-fix, project-update) — replace example paths and project-context references from `claude-config` to `agent-config`
- [x] 4.3 Update SKILL.md files in skills/memory-* and skills/skill-* (memory-init, memory-update, skill-creator, skill-add) — replace example paths and project-context references from `claude-config` to `agent-config`
- [x] 4.4 Update remaining SKILL.md files (claude-code-expert, claude-folder-audit, config-export, feature-domain-expert, smart-commit) — replace example paths and project-context references from `claude-config` to `agent-config`
- [x] 4.5 Update technology skill SKILL.md files (react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, django-drf, spring-boot-3, etc.) — search for any "claude-config" project-name references and replace (many will have none)
  Warning: This task requires filtering through ~18 additional tech skills; focus only on files that actually contain "claude-config"

---

## Phase 5: Verification and Cleanup

- [x] 5.1 Run `grep -r "claude-config" . --exclude-dir=.git --exclude-dir=.claude` to identify remaining occurrences
- [x] 5.2 Review remaining "claude-config" matches and categorize: mark as intentional if they are historical references, `~/.claude/` path comments, or GitHub URL fragments; update or document each decision
- [x] 5.3 Run `bash install.sh` to verify the script executes without error and deploys to `~/.claude/`
- [x] 5.4 Run `bash sync.sh` to verify it executes without error (should be unchanged)
- [x] 5.5 Create `openspec/changes/2026-03-12-rename-to-agent-config/verify-report.md` with verification findings

---

## Implementation Notes

- **Stage ordering**: Follow phases in order — each phase builds on previous outcomes
- **Preserve immutable references**: Do NOT change `~/.claude/` path references — this directory is controlled by Claude Code and must remain unchanged
- **GitHub repo name**: Do NOT rename the GitHub repository itself — that is an out-of-scope administrative action
- **Historical ADR content**: In `docs/adr/NNN-*.md` files, preserve references to "claude-config" if they appear inside the decision body (only update the `docs/adr/README.md` index)
- **Verify script compatibility**: `install.sh` and `sync.sh` use relative paths and `$HOME/.claude`, so they require no changes
- **Careful SKILL.md review**: When scanning SKILL.md files, look specifically for:
  - Example paths containing `claude-config/`
  - Project-name descriptive text (e.g., "the claude-config repo")
  - Step descriptions that mention the project by name
  - Preserve `~/.claude/` runtime path references

---

## Blockers

None. This change has no external dependencies and can proceed immediately.

---

## Success Criteria (from spec)

- [x] All references to "claude-config" as the project name in user-facing docs (README, CLAUDE.md) are updated to "agent-config"
- [x] openspec/config.yaml metadata fields (`name`, `root`) reflect "agent-config"
- [x] ai-context/ files (stack.md, architecture.md, conventions.md, known-issues.md) are updated to reference "agent-config" in project identity sections
- [x] All 49+ SKILL.md files have been reviewed and updated where they reference the project name (example paths, step descriptions)
- [x] docs/ documentation files that reference the project name are updated (at least docs/adr/README.md)
- [x] Remaining grep search for "claude-config" returns <5 matches (only in examples, historical context, or incidental references)
- [x] `bash install.sh` runs without error and deploys changes to ~/.claude/
- [x] `bash sync.sh` runs without error (unchanged)
- [x] Verification step confirms all changes are semantically correct (not just text replacements)
