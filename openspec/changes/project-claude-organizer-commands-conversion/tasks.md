# Task Plan: project-claude-organizer-commands-conversion

Date: 2026-03-04
Design: openspec/changes/project-claude-organizer-commands-conversion/design.md

## Progress: 12/12 tasks

---

## Phase 1: LEGACY_PATTERN_TABLE and Step 3b scaffold strategy

- [x] 1.1 Modify `skills/project-claude-organizer/SKILL.md` — update the LEGACY_PATTERN_TABLE row for `commands/`: change `strategy: delegate` to `strategy: scaffold` and update its description to reflect the active scaffold behavior
- [x] 1.2 Modify `skills/project-claude-organizer/SKILL.md` — update Step 3b `commands/` pattern detail block: replace the advisory-only delegate description with the active scaffold description (derive skill name from stem, infer format type via 4-signal heuristic, check idempotency, write SKILL.md to `.claude/skills/<stem>/SKILL.md`)

## Phase 2: New Step 3c — Skills Audit

- [x] 2.1 Modify `skills/project-claude-organizer/SKILL.md` — insert new Step 3c immediately after Step 3b: enumerate all immediate subdirectories of `.claude/skills/`; apply three detection rules (scope_overlap HIGH, broken_shell MEDIUM, suspicious_name LOW); populate `SKILL_AUDIT_FINDINGS` list; skip entirely if `.claude/skills/` is absent
- [x] 2.2 Modify `skills/project-claude-organizer/SKILL.md` — document the `SKILL_AUDIT_FINDINGS` entry structure inline in Step 3c: fields `skill_name`, `finding_type`, `severity`, `detail`; include the scope-overlap detection logic (read CLAUDE.md Skills Registry, extract `~/.claude/skills/<name>/SKILL.md` paths, compare by directory name stem); document that multiple rules may fire per directory producing separate findings

## Phase 3: Step 4 dry-run display and Step 5.7.1 scaffold execution

- [x] 3.1 Modify `skills/project-claude-organizer/SKILL.md` — update Step 4 dry-run display: add scaffold strategy summary for `commands/` (show list of files to be scaffolded with inferred format type and idempotency status); add skills audit table display for `SKILL_AUDIT_FINDINGS` (columns: Skill, Finding, Severity)
- [x] 3.2 Modify `skills/project-claude-organizer/SKILL.md` — replace Step 5.7.1 delegate advisory logic with active scaffold logic: for each qualifying `.md` file in `commands/` execute (1) derive skill name via kebab-case stem, (2) infer format type via 4-signal heuristic, (3) check idempotency guard, (4) generate SKILL.md skeleton per format type using the three skeleton templates defined in design.md, (5) write to `.claude/skills/<stem>/SKILL.md`, (6) record outcome (scaffolded | already exists | non-qualifying); non-qualifying files continue to produce advisory notes only

## Phase 4: Report template — new sections

- [x] 4.1 Modify `skills/project-claude-organizer/SKILL.md` — update Step 6 report template: add `### Commands scaffolded` subsection listing per-file outcomes (`scaffolded (format: <type>)`, `[already exists — not overwritten]`, `advisory only (no qualifying signals)`); omit section when `commands/` was absent; add `### Skills audit` subsection rendering `SKILL_AUDIT_FINDINGS` as a table (Skill | Finding | Severity) when non-empty, `No issues detected in .claude/skills/.` when empty, omitted entirely when `.claude/skills/` was absent

## Phase 5: Metadata updates

- [x] 5.1 Modify `CLAUDE.md` (project root) — update the Skills Registry entry for `project-claude-organizer` in the System Audits section: revise the description to mention active commands/ scaffold and skills audit pass over `.claude/skills/`
- [x] 5.2 Modify `ai-context/architecture.md` — update the artifact table row for `claude-organizer-report.md`: extend the description to mention the new `### Skills audit` section and the `### Commands scaffolded` section
- [x] 5.3 Update `ai-context/changelog-ai.md` — record the project-claude-organizer-commands-conversion change: active scaffold strategy, Step 3c skills audit, updated report template, CLAUDE.md and architecture.md metadata edits

---

## Implementation Notes

- The 4-signal heuristic for format inference reuses the same signals already present in the existing Step 5.7.1 qualifying detection: `## Anti-patterns` heading → `anti-pattern` (highest precedence); `## Patterns` or `## Examples` heading → `reference`; step-numbered sections or process headings or no signals → `procedural` (default). Anti-pattern detection takes precedence over reference; reference takes precedence over procedural.
- The three SKILL.md skeleton templates (procedural / reference / anti-pattern) are fully specified in design.md — the implementer must copy them verbatim into Step 5.7.1.
- The scope-overlap detection reads `CLAUDE.md` inside the project being organized (not `~/.claude/CLAUDE.md`). It extracts paths matching `~/.claude/skills/<name>/SKILL.md` from the Skills Registry section and compares each `.claude/skills/` subdirectory name against the extracted set using case-sensitive string matching.
- The additive invariant (Rule 2 of the organizer) remains in force: idempotency guard (skip if SKILL.md already exists) must be checked before any write operation in Step 5.7.1.
- Source files in `.claude/commands/` must NEVER be modified or deleted — delegate invariant applies unconditionally regardless of scaffold outcome.
- All changes are confined to `skills/project-claude-organizer/SKILL.md`, `CLAUDE.md`, `ai-context/architecture.md`, and `ai-context/changelog-ai.md`. No other files are affected.
- After applying, run `install.sh` to deploy the updated `skills/project-claude-organizer/SKILL.md` to `~/.claude/skills/project-claude-organizer/SKILL.md`.

## Phase 6: Emoji normalization and readme.md migration

- [x] 6.1 Modify `skills/project-claude-organizer/SKILL.md` — update Step 5.7.2 section-distribute procedure: before comparing a heading against `STACK_HEADING_SIGNALS`, `ARCH_HEADING_SIGNALS`, or `ISSUES_HEADING_SIGNALS`, apply emoji normalization — strip leading Unicode emoji characters and any following whitespace from the heading text, then compare the normalized form against the signal lists; add an advisory output at the end of the section-distribute pass when zero headings matched after normalization (e.g., `Advisory: no headings in <filename> matched any signal list after emoji normalization — file content was not distributed`)
- [x] 6.2 Modify `skills/project-claude-organizer/SKILL.md` — update Step 3b LEGACY_PATTERN_TABLE: add a new row for `readme.md` as an explicit `LEGACY_MIGRATION` entry with strategy `user-choice`; remove `readme.md` from the `project.md` / `readme.md` shared pattern block so that `readme.md` is no longer classified as `section-distribute`; update the pattern description to reflect Option A (append full content to `CLAUDE.md` under a labeled marker `<!-- migrated from .claude/readme.md YYYY-MM-DD -->`) and Option B (copy to `docs/README-claude.md`)
- [x] 6.3 Modify `skills/project-claude-organizer/SKILL.md` — insert new Step 5.7.X user-choice procedure for `readme.md` in the execution order between `section-distribute` (5.7.2) and `copy` (5.7.3): present the user with Option A and Option B; on Option A, append the full file content to `PROJECT_ROOT/CLAUDE.md` under the labeled marker; on Option B, copy the file to `PROJECT_ROOT/docs/README-claude.md` (create `docs/` if absent); source file is never deleted; record outcome in report under a new `### readme.md migration` subsection

## Blockers

None.
