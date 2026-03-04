# Technical Design: project-claude-folder-organizer

Date: 2026-03-04
Proposal: openspec/changes/project-claude-folder-organizer/proposal.md

## General Approach

A new procedural skill `project-claude-organizer` is created at `skills/project-claude-organizer/SKILL.md`. It follows the exact same structural conventions as all other meta-tool skills: YAML frontmatter with `format: procedural`, a `**Triggers**` line, numbered `### Step N` sections inside `## Process`, and a `## Rules` section. The skill resolves paths using the same `$HOME / $USERPROFILE / $HOMEDRIVE+$HOMEPATH` priority chain as `claude-folder-audit`, detects the target `.claude/` directory, compares observed contents against the canonical P8 expected item set, presents a dry-run plan to the user, and only applies changes (create missing directories / stub files) after explicit confirmation. A completion report is written to `.claude/claude-organizer-report.md` in the target project. After the skill is authored, two CLAUDE.md registry entries are added (Available Commands table and Skills Registry under System Audits) and `ai-context/architecture.md` gains a new row in the artifact table.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Skill format | `format: procedural` | `reference`, `anti-pattern` | This is a multi-step meta-tool that executes an ordered sequence of operations. All meta-tool skills in this repo use `procedural`. |
| Canonical item set source | Redefine the P8 expected set inline in the skill as a reference table, with a cross-reference comment to `claude-folder-audit` Check P8 | Import or link to claude-folder-audit at runtime | Skills are stateless and read-only files; there is no runtime import mechanism. Inline definition keeps the skill self-contained and auditable. The cross-reference comment prevents divergence from becoming invisible. |
| Change strategy for unexpected items | Flag with a warning comment in the report; never delete or move | Auto-delete unexpected items, prompt for each item | The skill is intended to be additive and non-destructive. Unexpected items may be intentional custom files. Deleting without explicit per-item confirmation would violate the principle stated in the proposal ("never deletes or moves files"). |
| Change strategy for missing items | Create missing directories (`skills/`, `hooks/`) and minimal stub files (`CLAUDE.md` stub if absent) | Silently skip, emit finding only | The organizer's value proposition is to fix what it can automatically. Creating directories and stub files is safe additive work; it does not overwrite anything. |
| User confirmation gate | Single confirmation covers the entire plan before any writes | Per-item confirmation, no confirmation | One confirmation is the established pattern in all SDD apply phases. Per-item confirmation is disruptive for multi-item plans. No confirmation would skip the intentional dry-run guarantee from the proposal. |
| Report artifact location | `.claude/claude-organizer-report.md` inside the target project | `~/.claude/`, project root, openspec/ | Consistent with `claude-folder-audit-report.md` location in project mode. The `.claude/` folder is the scope of the tool; the report belongs there. |
| Path normalization | `$HOME / $USERPROFILE / $HOMEDRIVE+$HOMEPATH` priority chain (same as `claude-folder-audit` Step 1) | Shell tilde expansion | Windows compatibility; exact mirror of the existing convention in `claude-folder-audit` and `install.sh`. Reusing the same chain avoids introducing a second path-resolution pattern into the codebase. |
| CLAUDE.md stub content | Generate a minimal stub with the five required sections (headings only, no content) | Full CLAUDE.md generation, link to `/project-setup` | Full generation is `/project-setup`'s job. The organizer creates the minimum viable structure so that `claude-folder-audit` P1 no longer fires HIGH. The stub's comments direct the user to run `/project-setup` for full initialization. |
| Skill placement tier | Global (`skills/project-claude-organizer/SKILL.md`) | Project-local (`.claude/skills/`) | This is a meta-tool skill for use in any project, matching the placement of all other meta-tool skills in this repo. |

## Data Flow

```
User invokes /project-claude-organizer [path?]
        │
        ▼
Step 1 — Resolve paths
  - HOME priority chain → CLAUDE_DIR
  - Detect PROJECT_ROOT (cwd or explicit arg)
  - Verify .claude/ exists at PROJECT_ROOT
        │
        ▼
Step 2 — Enumerate observed items
  - List all items directly under PROJECT_ROOT/.claude/ (1 level)
  - Record: files, directories
        │
        ▼
Step 3 — Compare against canonical expected set
  - Expected set (mirrors claude-folder-audit P8):
      CLAUDE.md, skills/, audit-report.md,
      claude-folder-audit-report.md, claude-organizer-report.md,
      settings.json, settings.local.json, openspec/, ai-context/, hooks/
  - Compute:
      MISSING  = expected_required − observed    (CLAUDE.md, skills/ only — others optional)
      UNEXPECTED = observed − expected_set
      PRESENT  = observed ∩ expected_set
        │
        ▼
Step 4 — Build and present plan (dry-run)
  - Display table: Item | Status | Action
      - MISSING required items → "Create (stub/directory)"
      - UNEXPECTED items       → "Flag (no change — review recommended)"
      - PRESENT items          → "OK"
  - Ask: "Apply this plan? (yes/no)"
        │
        ├─── no → stop, no writes
        │
        ▼
Step 5 — Apply plan
  - For each MISSING required item:
      - skills/   → mkdir .claude/skills/
      - hooks/    → mkdir .claude/hooks/
      - CLAUDE.md → write minimal stub (5 section headings)
  - For UNEXPECTED items → no file changes; log to report only
        │
        ▼
Step 6 — Write report
  - Write .claude/claude-organizer-report.md
      - Run date, project root
      - Summary table (created/flagged/unchanged)
      - Recommended next steps
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-claude-organizer/SKILL.md` | Create | New meta-tool skill (procedural format, 6-step process) |
| `CLAUDE.md` | Modify | (1) Add row `\| /project-claude-organizer \| ... \|` to Available Commands table; (2) Add row to "How I Execute Commands" dispatch table; (3) Add entry under `### System Audits` in Skills Registry |
| `ai-context/architecture.md` | Modify | Add new row to the "Communication between skills via artifacts" table for `claude-organizer-report.md` |

## Interfaces and Contracts

```
# Canonical expected .claude/ item set (V1)
# Cross-reference: claude-folder-audit Check P8
EXPECTED_SET = {
  # Required (absence triggers create action):
  "CLAUDE.md",
  "skills/",
  # Optional (absence is informational only):
  "hooks/",
  "audit-report.md",
  "claude-folder-audit-report.md",
  "claude-organizer-report.md",  # this skill's own output
  "settings.json",
  "settings.local.json",
  "openspec/",
  "ai-context/",
}

# CLAUDE.md minimal stub (written when absent)
"""
# [Project Name] — Claude Configuration

## Tech Stack

<!-- Add your project tech stack here. -->

## Architecture

<!-- Describe the project architecture here. -->

## Unbreakable Rules

<!-- Add project-specific rules here. -->

## Plan Mode Rules

<!-- Add plan mode rules here. -->

## Skills Registry

<!-- List skills used by this project here.
     Global skills: ~/.claude/skills/<name>/SKILL.md
     Local skills:  .claude/skills/<name>/SKILL.md
     Run /project-setup for full initialization. -->
"""

# Report artifact schema
{
  "run_date": "ISO-8601",
  "project_root": "absolute path",
  "items_created": ["list of items created"],
  "items_flagged": ["list of unexpected items"],
  "items_unchanged": ["list of expected items already present"],
  "next_steps": ["recommended actions"]
}
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual integration | Invoke skill on a project with partial `.claude/` — verify plan output, confirm, verify files created | Manual / project-audit |
| Manual integration | Invoke skill on a project with a clean `.claude/` — verify plan shows all OK | Manual |
| Manual integration | Invoke skill on a project with unexpected items — verify they are flagged but not deleted | Manual |
| Regression | Run `/project-audit` on `claude-config` after applying this change — score must be >= prior score | `/project-audit` |

## Migration Plan

No data migration required. This change is purely additive: one new skill file, minor edits to two existing files.

## Open Questions

None.
