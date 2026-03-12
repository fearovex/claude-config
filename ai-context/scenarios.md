# Scenarios — Project Onboarding Guide

> Last verified: 2026-02-26

This guide covers the six project states you are most likely to encounter when setting up Claude Code SDD in an existing or new project. Find your case, follow the command sequence, and check the expected outcomes.

Not sure which case applies? Run `/project-onboard` — it reads your project automatically and tells you.

---

### Case 1 — Brand-New Project (no Claude config at all)

**Symptoms**:
- No `.claude/` directory in the project root
- No `CLAUDE.md` anywhere in the project
- Running `/project-audit` returns "CLAUDE.md not found — CRITICAL"

**Command sequence**:
1. `/project-setup`
2. `/memory-init`
3. `/project-audit`
4. `/project-fix`

**Expected outcome per command**:
- `/project-setup`: creates `.claude/CLAUDE.md` with SDD section, creates `openspec/config.yaml`, creates skeleton `ai-context/` directory
- `/memory-init`: reads the project from scratch and generates `ai-context/stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md` with real content
- `/project-audit`: produces `.claude/audit-report.md`; score may be 50–75 at this stage — that is expected
- `/project-fix`: applies all critical and high corrections; score should reach ≥ 75 after this

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| `/project-setup` creates duplicate CLAUDE.md if one exists at root | Remove or rename the existing file first, then re-run |
| `/memory-init` generates placeholder stack.md (no package.json) | Edit `ai-context/stack.md` manually with the real stack |
| `/project-fix` stops with "audit-report.md not found" | Run `/project-audit` first — project-fix requires the report |
| Score stays below 50 after fix | Re-run `/project-audit` and repeat `/project-fix` — some fixes require two passes |

---

### Case 2 — Has CLAUDE.md but No SDD Infrastructure

**Symptoms**:
- `.claude/CLAUDE.md` exists
- No `openspec/` directory in the project
- Running `/project-audit` returns "openspec/ missing — CRITICAL" or "openspec/config.yaml missing — CRITICAL"
- `ai-context/` may be partially present or absent

**Command sequence**:
1. `/project-audit` — to understand the full scope of what is missing
2. `/project-fix` — applies the critical fixes (creates `openspec/config.yaml`, adds SDD section to CLAUDE.md)
3. `/memory-init` — if `ai-context/` is empty or absent
4. `/project-audit` — verify the score improved

**Expected outcome per command**:
- `/project-audit`: score will be 50–80 depending on how complete the existing CLAUDE.md is; FIX_MANIFEST will list the SDD gaps
- `/project-fix`: creates `openspec/` structure, updates CLAUDE.md with SDD commands, fills missing `ai-context/` files
- `/memory-init`: generates or enriches the `ai-context/` files based on real project code
- Second `/project-audit`: score should reach ≥ 75; SDD Readiness should be FULL or PARTIAL

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| `project-fix` proposes changes that conflict with existing CLAUDE.md content | Review and confirm each change manually — project-fix always asks before writing |
| `openspec/config.yaml` created with wrong stack | Edit `openspec/config.yaml` manually and correct the `stack:` section |
| SDD Readiness stays at PARTIAL after fix | Run `/project-audit` again — check which dimension is still failing and address it |

---

### Case 3 — Partial SDD (openspec/ present but ai-context/ sparse)

**Symptoms**:
- `openspec/config.yaml` exists
- `ai-context/` directory exists but has fewer than 3 populated files, or files are mostly empty/template stubs
- `/project-audit` score is in the 60–80 range; D2 (Memory) dimension shows multiple warnings

**Command sequence**:
1. `/memory-init` — regenerates all ai-context/ files from real project state
2. `/project-audit` — verify D2 score improved
3. `/project-fix` — address any remaining issues

**Expected outcome per command**:
- `/memory-init`: replaces stub files with real content; existing files with substantial content are not overwritten
- `/project-audit`: D2 should show ✅ for most files; overall score should reach ≥ 80
- `/project-fix`: cleans up any remaining medium/low findings (cross-references, missing sections, etc.)

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| `/memory-init` leaves files as stubs because no source code found | The project may have an unusual structure — edit `ai-context/` files manually using the real code as reference |
| D2 still fails after memory-init | Check each file manually: does it have > 30 lines? Does it have real content (not just headings)? |
| `conventions.md` inference is vague | Sample 3–5 code files manually and add the real conventions to the file |

---

### Case 4 — Has Local Skills in `.claude/skills/` Needing Review

**Symptoms**:
- `.claude/skills/` directory exists with one or more skill subdirectories
- Running `/project-audit` shows a Dimension 9 section listing duplicates, structural issues, or non-English content
- Some local skills may duplicate global skills in `~/.claude/skills/`

**Command sequence**:
1. `/project-audit` — read the Dimension 9 findings
2. `/project-fix` — run Phase 5 to handle skill quality actions
3. Manual review — for any `move-to-global` recommendations

**Expected outcome per command**:
- `/project-audit`: Dimension 9 table shows each local skill with Duplicate / Structural / Language / Stack relevant columns and a Disposition
- `/project-fix` Phase 5: prompts you for each action — deletes duplicates on confirmation, adds missing structural stubs, flags irrelevant skills
- Manual review: skills with `move-to-global` disposition need to be promoted to `~/.claude/skills/` manually (project-fix provides the exact steps)

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| A local skill is flagged as duplicate but has custom modifications | Answer `N` when project-fix asks to delete — keep the local version |
| `add_missing_section` adds a stub but the skill still doesn't work | Fill in the stub with real content — the stub is a placeholder, not a complete implementation |
| D9 shows `Stack relevance check skipped` | No `ai-context/stack.md` or `package.json` found — run `/memory-init` first |
| Global catalog unreadable warning | `~/.claude/skills/` may not be fully set up — run `bash ~/agent-config/install.sh` |

---

### Case 5 — Orphaned or Stale SDD Changes

**Symptoms**:
- `openspec/changes/` contains folders that are not inside `archive/`
- Changes are 14+ days old without a `verify-report.md`
- `/project-audit` D3 lists orphaned changes

**Command sequence**:
1. `/sdd-status` — see which changes are active and what artifacts each has
2. For each stale change, one of:
   - `/sdd-apply <change>` — if it has tasks.md but was never implemented
   - `/sdd-verify <change>` — if it was implemented but never verified
   - `/sdd-archive <change>` — if it is complete but was never archived
3. `/project-audit` — verify D3 shows no orphaned changes

**Expected outcome per command**:
- `/sdd-status`: shows a table of active changes with present/absent artifacts and inferred current phase
- `/sdd-apply`, `/sdd-verify`, `/sdd-archive`: advances the stale change to the next phase
- Final `/project-audit`: D3 should show "Orphaned changes: none"

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| A stale change is a dead experiment you want to discard | Manually move it to `openspec/changes/archive/YYYY-MM-DD-<name>/` |
| `/sdd-apply` fails because tasks.md is missing | The change may need to go back to `/sdd-tasks <change>` first |
| `/sdd-archive` refuses due to unresolved critical issues | Run `/sdd-verify <change>` and address the issues in the verify-report.md |

---

### Case 6 — Fully Configured (Ready to Start a New Feature)

**Symptoms**:
- `.claude/CLAUDE.md` exists and has SDD section
- `openspec/config.yaml` exists
- `ai-context/` has 5 populated files
- `/project-audit` score is ≥ 80
- SDD Readiness: FULL

**Command sequence**:
- For a well-understood change: `/sdd-ff <change-name>`
- For a complex or vague change: `/sdd-new <change-name>`
- After fast-forward: `/sdd-apply <change-name>`

**Expected outcome per command**:
- `/sdd-ff <change>`: runs propose → spec+design (parallel) → tasks automatically, then asks before apply
- `/sdd-new <change>`: offers optional explore phase, runs full DAG with confirmation gates, reminds you of remaining phases
- `/sdd-apply <change>`: implements tasks phase by phase, marks progress in tasks.md

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| `/sdd-ff` returns "Unknown skill: sdd-ff" | Run `bash ~/agent-config/install.sh` — the skill files need to be deployed to `~/.claude/` |
| `/sdd-apply` is blocked on a task | Check the task description and the relevant spec — the issue is usually an ambiguity in the design |
| Score drops after a change | Run `/project-audit` to see which dimension regressed, then `/project-fix` or manual fix |
| `openspec/changes/` accumulates stale entries | Run `/sdd-status` to see what is open, then resolve or archive each one |
