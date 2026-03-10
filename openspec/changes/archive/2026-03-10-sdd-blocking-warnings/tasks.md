# Task Plan: sdd-blocking-warnings

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-blocking-warnings/design.md

## Progress: 8/8 tasks

## Phase 1: sdd-tasks — Add warning classification rules and documentation

- [x] 1.1 Update `~/.claude/skills/sdd-tasks/SKILL.md` Step 4 — add new subsection 4a: Warning Classification Rules (with MUST_RESOLVE and ADVISORY definitions and examples) ✓
- [x] 1.2 Update `~/.claude/skills/sdd-tasks/SKILL.md` Step 4 — add new subsection 4b: Record warnings in tasks.md (format specification and placement rules) ✓
- [x] 1.3 Update `~/.claude/skills/sdd-tasks/SKILL.md` — add example to the Process section showing a task with a MUST_RESOLVE warning in tasks.md format ✓

## Phase 2: sdd-apply — Add MUST_RESOLVE blocking gate

- [x] 2.1 Update `~/.claude/skills/sdd-apply/SKILL.md` Step 3 (task execution loop) — add sub-step 3a: Check for MUST_RESOLVE warnings before executing task ✓
- [x] 2.2 Update `~/.claude/skills/sdd-apply/SKILL.md` Step 3 — add blocking gate message format and user input handling logic ✓
- [x] 2.3 Update `~/.claude/skills/sdd-apply/SKILL.md` Step 3 — add answer recording logic (append to tasks.md with timestamp) ✓

## Phase 3: sdd-apply — Handle ADVISORY warnings inline

- [x] 3.1 Update `~/.claude/skills/sdd-apply/SKILL.md` Step 3 (task execution loop) — add handling for ADVISORY warnings (log but do not block) ✓
- [x] 3.2 Update `~/.claude/skills/sdd-apply/SKILL.md` — add rule clarifying that ADVISORY warnings do not require user input ✓

## Phase 4: Finalization and documentation

- [x] 4.1 Run `bash install.sh` to deploy updated SKILL.md files to `~/.claude/` ✓
- [x] 4.2 Verify `~/.claude/skills/sdd-tasks/SKILL.md` contains the warning classification rules ✓
- [x] 4.3 Verify `~/.claude/skills/sdd-apply/SKILL.md` contains the blocking gate and answer recording logic ✓
- [x] 4.4 Commit changes to git: `git add -A && git commit -m "feat(sdd): add blocking warnings system to sdd-tasks and sdd-apply"` ✓

