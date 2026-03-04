# Proposal: project-claude-folder-organizer

Date: 2026-03-04
Status: Draft

## Intent

Create a new standalone meta-tool skill `project-claude-organizer` that reads a project's `.claude/` folder, compares it against the canonical SDD structure, and applies a structural reorganization after user confirmation.

## Motivation

The SDD meta-system currently has a read-only audit skill (`claude-folder-audit`) that identifies structural problems in a project's `.claude/` folder, but no skill that actually fixes them. ADR-009 explicitly anticipated this companion fix skill as future work under the name `claude-folder-fix`. Today, when `claude-folder-audit` or `project-audit` finds structural problems (missing `CLAUDE.md`, absent `skills/` directory, legacy `commands/` artifacts, unexpected items), the only remediation path is manual — the user must reorganize the folder by hand. This gap is especially painful for projects that have accumulated ad-hoc `.claude/` content over time and need to be brought into SDD compliance.

## Scope

### Included

- New skill directory: `skills/project-claude-organizer/SKILL.md`
- Skill behavior: read project `.claude/` folder state, compare against canonical SDD structure, produce a reorganization plan, apply after user confirmation, write a completion report
- Detection of: missing `CLAUDE.md`, missing `skills/` directory, presence of legacy `commands/` directory, unexpected items at `.claude/` root
- Dry-run preview step before any writes (user sees the plan before it is applied)
- Completion report written to `.claude/claude-organizer-report.md` in the target project
- Registration in global `CLAUDE.md` Skills Registry under System Audits / Meta-tool Skills
- Registration in project `CLAUDE.md` under `/project-claude-organizer` command table
- New entry in the `Available Commands` table in `CLAUDE.md`
- Update to `ai-context/architecture.md` artifact table to document the new report artifact

### Excluded (explicitly out of scope)

- Content migration: converting `commands/*.md` files into proper `skills/<name>/SKILL.md` format is excluded — structural cleanup first, content migration in a future change
- Reorganizing `ai-context/` or `openspec/` directories — those are handled by `memory-init` and `project-setup`
- Modifying `~/.claude/` (the runtime) — the organizer targets project `.clone/` folders only, never the user-level runtime
- Fixing issues found in `audit-report.md` — that remains `project-fix`'s job; this skill works directly from the live `.clone/` folder state, not from an audit report
- Automatic invocation from within `project-fix` — remains fully independent in V1
- Updating the allowlist inside `claude-folder-audit` to resolve the Check 4 false-positive issue — separate concern, separate change

## Proposed Approach

The skill follows the same structural pattern as other meta-tool skills: a procedural SKILL.md with a multi-step process. The key steps are:

1. **Discover** — resolve the project root and enumerate what currently exists under `.claude/`
2. **Compare** — compare the observed contents against the canonical expected item set (defined inside the skill as a reference table, consistent with `claude-folder-audit` Check P8)
3. **Plan** — produce a human-readable reorganization plan listing items to create, items to flag as legacy/unexpected, and items that are already correct
4. **Confirm** — present the plan to the user and wait for explicit approval before applying any changes
5. **Apply** — execute the approved plan: create missing directories and stub files, flag unexpected items with a warning comment (do not delete)
6. **Report** — write `.clone/claude-organizer-report.md` summarizing what was changed

This approach is intentionally conservative: the skill creates missing items and flags unexpected ones, but never deletes or moves files without explicit user instruction. This prevents data loss on projects with custom files in `.clone/`.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-claude-organizer/SKILL.md` | New | High — this is the deliverable |
| `CLAUDE.md` (global) | Modified | Medium — new command entry + Skills Registry entry |
| `ai-context/architecture.md` | Modified | Low — new artifact table row for `claude-organizer-report.md` |
| `ai-context/known-issues.md` | Modified | Low — note that Check 4 false-positive is adjacent but out of scope here |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Overlap with `project-fix` causes user confusion about which skill to run | Medium | Low | Document clearly in both SKILL.md files: `project-fix` consumes `audit-report.md`; `project-claude-organizer` reads the live `.claude/` folder directly and independently |
| Canonical structure definition diverges between `claude-folder-audit` and the new skill | Medium | Medium | Define the canonical structure as a reference table inside the organizer SKILL.md and note which check in `claude-folder-audit` it corresponds to (P8 expected set) |
| User accidentally confirms a plan that removes needed files | Low | High | Skill is write-only additive: it creates missing items and flags (comments) unexpected items but never deletes or moves files |
| Windows path resolution issues (`~` vs `$USERPROFILE`) | Low | Medium | Follow the exact same path normalization pattern used by `claude-folder-audit` Step 1 |

## Rollback Plan

The change is purely additive:
1. If the new skill causes problems, delete `skills/project-claude-organizer/` from the repo
2. Remove the Skills Registry entry from `CLAUDE.md`
3. Remove the command entry from the `Available Commands` table in `CLAUDE.md`
4. Remove the artifact row from `ai-context/architecture.md`
5. Run `install.sh` to deploy the reverted config
6. Commit with message: `revert: remove project-claude-organizer skill`

No existing skills or artifacts are modified by this change (other than registry entries), so rollback cannot cause regressions in other skills.

## Dependencies

- `claude-folder-audit` SKILL.md must be readable to confirm the P8 expected item set definition (reference only — no runtime dependency)
- `docs/templates/prd-template.md` must exist for the PRD shell (already confirmed present)
- No other SDD cycle or external change must be completed first — this is a fully independent additive change

## Success Criteria

- [ ] `skills/project-claude-organizer/SKILL.md` exists, passes `project-audit` P3-C checks (valid frontmatter, `format: procedural`, required sections: `**Triggers**`, `## Process`, `## Rules`)
- [ ] The skill is registered in global `CLAUDE.md` Skills Registry and the `Available Commands` table
- [ ] When invoked on a test project with a partial `.claude/` folder, the skill correctly identifies missing items and presents a plan before applying changes
- [ ] When invoked on a test project, the skill creates `.claude/claude-organizer-report.md` summarizing the changes
- [ ] The skill does NOT delete any existing files or directories — only creates missing items and flags unexpected ones
- [ ] `install.sh` runs without errors after the change is deployed
- [ ] `/project-audit` on `claude-config` scores >= previous score after the change is applied

## Effort Estimate

Low-Medium (1 new SKILL.md file + minor edits to CLAUDE.md and ai-context/architecture.md — approximately half a day)
