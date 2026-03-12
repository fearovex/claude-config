# Closure: 2026-03-12-rename-to-agent-config

Start date: 2026-03-12
Close date: 2026-03-12

## Summary

Renamed the project from `claude-config` to `agent-config` across all user-facing documentation, project metadata, ai-context memory files, and SKILL.md example paths. Historical ADR body content and runtime `~/.claude/` paths were intentionally preserved.

## Modified Specs

| Domain           | Action  | Change                                                  |
| ---------------- | ------- | ------------------------------------------------------- |
| project-identity | Created | New master spec documenting project name identity rules |

## Modified Code Files

- README.md — project title and description updated to "agent-config"
- CLAUDE.md — architecture diagram and path examples updated
- openspec/config.yaml — `name` and `root` fields updated
- ai-context/stack.md — project identity heading updated
- ai-context/architecture.md — project identity references updated
- ai-context/conventions.md — project name references updated
- ai-context/known-issues.md — project name references updated
- ai-context/changelog-ai.md — project identity header updated
- skills/ (49 SKILL.md files) — `~/claude-config` path examples and step descriptions updated
- docs/adr/README.md — contextual references updated
- docs/*.md (other) — project-context references updated
- .github/copilot-instructions.md — project description updated
- GEMINI.md — project description updated
- install.sh — echo message updated to "Installing agent-config →"

## Key Decisions Made

- Historical ADR body content (docs/adr/001, 002, 004, 017) preserved verbatim as intentional historical record — "claude-config" in those files is not a project-identity reference but a historical record.
- Runtime `~/.claude/` paths were not changed — these are controlled by Claude Code itself and are immutable.
- GitHub repository name (`claude-config`) was left unchanged — this is an out-of-scope administrative action.
- changelog-ai.md session-level prose was left intact where ambiguous; only project-identity headers were updated.
- install.sh and sync.sh required no path changes — they use relative paths and `$HOME/.claude` respectively. Only the echo message in install.sh was updated.

## Lessons Learned

- Targeted semantic replacement (per-file-category approach) worked well. The stage ordering (Config → memory → skills → docs → verification) made the change systematic and reviewable.
- grep-based verification was effective as a post-apply check — 0 unintentional matches remaining confirmed comprehensive coverage.
- Live execution of install.sh and sync.sh was not performed in the verification session, but grep confirmed no functional paths were altered. Recommended as a follow-up before the next deploy.

## User Docs Reviewed

N/A — pre-dates this requirement. This change does not affect user-facing workflows (scenarios.md, quick-reference.md, onboarding.md) — it is a project identity rename only.
