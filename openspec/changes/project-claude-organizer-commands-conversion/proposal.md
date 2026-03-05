# Proposal: project-claude-organizer-commands-conversion

Date: 2026-03-04
Status: Draft

## Intent

Upgrade the `project-claude-organizer` skill so that `commands/` directories are migrated into real skill files rather than just receiving advisory messages, and add a duplicate/irrelevant skill detection pass over `.claude/skills/`.

## Motivation

The current `commands/` delegate strategy is advisory-only: when the organizer finds qualifying `.md` files in `.claude/commands/`, it tells the user to run `/skill-create` per file but writes nothing itself. This means the user must manually execute an additional step for each qualifying file — defeating the purpose of an automated organizer. A project that already went through the effort of authoring command descriptions in `commands/` should be able to surface them as proper skills with a single invocation.

Separately, the organizer currently has no awareness of the `.claude/skills/` directory itself. It does not detect:
- Skills that duplicate a global catalog entry (same name already registered in `~/.claude/skills/`).
- Skill directories that contain no `SKILL.md` (empty or broken shells).
- Skills with names that suggest they are obsolete or test artifacts (e.g. `_draft-*`, `test-*`).

Without this detection, organizer runs can leave a project's `.claude/skills/` in an unreviewed state, allowing drift to accumulate silently.

## Scope

### Included

- **commands/ active migration**: Replace the `delegate — advisory only` strategy with an active scaffold strategy. For each qualifying `.md` file in `commands/`, the organizer generates a minimal but valid `SKILL.md` under `.claude/skills/<stem>/SKILL.md`, inferring format type from the source file's content. Non-qualifying files continue to be listed as advisory-only with a clear note.
- **Skill scaffold quality**: Generated SKILL.md files must satisfy the section contract for their inferred format (`procedural`, `reference`, or `anti-pattern`), include a valid YAML frontmatter with `format:`, and copy all recognizable content from the source `.md` file into the appropriate section.
- **Duplicate/irrelevant skill detection in `.claude/skills/`**: Add a new audit sub-step that scans the project's `.claude/skills/` directory and flags:
  - Skills whose directory name matches a global catalog entry registered in the project CLAUDE.md Skills Registry (scope-tier overlap).
  - Skill directories that contain no `SKILL.md` file (broken shells).
  - Skill directories whose name matches a suspicious pattern: leading underscore (`_*`), `test-*`, or `draft-*` prefixes.
- **Report integration**: Flagged skills appear in a new `### Skills audit` section of `claude-organizer-report.md` with per-finding severity (HIGH for scope overlap, MEDIUM for broken shells, LOW for suspicious names).
- **CLAUDE.md and architecture.md updates**: Update the Skills Registry entry for `project-claude-organizer` with the revised description; update `architecture.md` artifact table entry for `claude-organizer-report.md`.

### Excluded (explicitly out of scope)

- **Auto-deleting or auto-moving existing skill files**: The organizer remains additive; it never removes content from `.claude/skills/` automatically. Flagged items are reported; remediation is manual or via a future companion skill.
- **Full `/skill-create` interactive flow**: The scaffold produced for `commands/` files is a minimal non-interactive skeleton — it does not invoke the `skill-creator` skill nor prompt for additional information per file. The intent is one-shot automation; interactivity would require a separate sub-agent per file.
- **Scanning nested subdirectories inside `commands/`**: The existing no-recursion invariant is preserved. Only immediate `.md` files at `commands/` level are processed.
- **Global `~/.claude/skills/` auditing**: The duplicate detection targets `.claude/skills/` (project-local) only. Global skill auditing remains the domain of `claude-folder-audit`.
- **Auto-fix for flagged skills**: Detection only in this change; an auto-fix pass is future work.

## Proposed Approach

The `commands/` strategy is changed from `delegate` (advisory) to `scaffold` (active). The content-analysis heuristic (three qualifying signals) that already exists is preserved and repurposed: qualifying files are scaffolded as skills; non-qualifying files are still listed as advisory notes.

For each qualifying source file, the organizer:
1. Derives a skill name from the filename stem (kebab-case normalization).
2. Infers the format type using the same three-signal heuristic (step-numbered sections → `procedural`; patterns/examples headings → `reference`; anti-pattern headings → `anti-pattern`; default → `procedural`).
3. Generates a SKILL.md skeleton that copies the source content into the correct section, adds minimal YAML frontmatter, and satisfies the section contract.
4. Writes the skeleton to `.claude/skills/<stem>/SKILL.md`.
5. Follows the existing additive invariant: if `.claude/skills/<stem>/SKILL.md` already exists, skips with an `[already exists]` note rather than overwriting.

The duplicate/irrelevant skill detection is added as a new Step 3c immediately after the existing Step 3b (`Legacy Directory Intelligence`). Step 3c enumerates all immediate subdirectories of `.claude/skills/`, applies the three detection rules (scope overlap, broken shell, suspicious name), and populates a `SKILL_AUDIT_FINDINGS` list consumed by the report step.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-claude-organizer/SKILL.md` | Modified — Steps 3b, 5.7.1, report template | High |
| `CLAUDE.md` (project + global) | Modified — Skills Registry description | Low |
| `ai-context/architecture.md` | Modified — artifact table entry for claude-organizer-report.md | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Scaffold overwrites a valid hand-authored skill | Low | High | Idempotency guard: skip if `.claude/skills/<stem>/SKILL.md` already exists; surface as `[already exists]` in report |
| Inferred format type is wrong for a given source file | Medium | Low | Generated skeleton is always valid per format contract; user reviews report before confirming; source file is never deleted |
| Step 3c detection produces false positives on legitimate local skills | Low | Low | Suspicious-name detection only flags predictable patterns (`_*`, `test-*`, `draft-*`); scope-overlap check requires explicit match in CLAUDE.md Skills Registry |
| SKILL.md growth makes the skill harder to read | Medium | Low | New content is confined to clearly delimited sub-steps; the overall step numbering is preserved |

## Rollback Plan

1. Revert `skills/project-claude-organizer/SKILL.md` to the version at the prior commit (`git checkout HEAD~1 -- skills/project-claude-organizer/SKILL.md`).
2. Run `install.sh` to deploy the reverted file to `~/.claude/`.
3. No other files are affected by this change except CLAUDE.md description text and architecture.md artifact table — both can be reverted via the same `git checkout` pattern.
4. Skills scaffolded in target projects by the active strategy are not automatically removed; operators must delete them manually if the rollback is needed at a project level.

## Dependencies

- The `skill-creator/SKILL.md` format-type inference heuristic is reused conceptually in the `commands/` scaffold logic; no code dependency exists since this is a procedural Markdown skill. Both skills are independent.
- `install.sh` must be run after applying the change to deploy the updated `project-claude-organizer/SKILL.md` to `~/.claude/skills/`.

## Success Criteria

- [ ] Running `/project-claude-organizer` on a project with a populated `commands/` directory that contains qualifying `.md` files produces a `SKILL.md` file per qualifying source file under `.claude/skills/<stem>/`, without user having to issue additional `/skill-create` commands.
- [ ] Generated `SKILL.md` files pass the `project-audit` D4b/P3-C section-contract check (valid frontmatter, correct sections for the inferred format).
- [ ] Non-qualifying `commands/` files continue to appear in the report as advisory notes, not as scaffolded skills.
- [ ] Running `/project-claude-organizer` on a project whose `.claude/skills/` contains a skill with the same name as a global catalog entry produces a `### Skills audit` report section with a HIGH-severity scope-overlap finding for that skill.
- [ ] Running the organizer a second time on the same project produces the same report without overwriting any previously scaffolded skills (idempotency).
- [ ] `claude-organizer-report.md` includes the new `### Skills audit` section; its absence constitutes a failure.

## Effort Estimate

Medium (1-2 days) — the core logic is localized to one SKILL.md; the content-analysis heuristic already exists and only needs to be extended to write output rather than advise.
