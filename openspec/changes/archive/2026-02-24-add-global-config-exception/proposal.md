# Proposal: Add Global-Config Repo Exception to project-audit

**Date:** 2026-02-24
**Change:** add-global-config-exception

## Problem

`project-audit` Dimension 1 checks for `.claude/CLAUDE.md` (nested path). For normal projects this is correct. But for a global-config repo like `claude-config`, the CLAUDE.md lives at root by design — it installs to `~/.claude/CLAUDE.md` via `install.sh`. The audit permanently penalizes this repo -4 points for a structural pattern that is intentional and correct.

## Solution

Add a project-type detection step at the start of the audit. When a repo has `install.sh` + `sync.sh` at root (or has `openspec/config.yaml` with `framework: "Claude Code SDD meta-system"`), classify it as `type: global-config` and:
- Accept CLAUDE.md at root as equivalent to `.claude/CLAUDE.md`
- Note the type in the report header

## Success Criteria

- `/project:audit` on `claude-config` scores 100/100
- The exception does NOT affect audits of normal projects
- The detection logic is documented in Dimension 1 of the skill
