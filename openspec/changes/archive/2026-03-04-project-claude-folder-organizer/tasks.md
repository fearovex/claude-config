# Task Plan: project-claude-folder-organizer

Date: 2026-03-04
Design: openspec/changes/project-claude-folder-organizer/design.md

## Progress: 9/9 tasks

---

## Phase 1: Skill File

- [x] 1.1 Create `skills/project-claude-organizer/SKILL.md` ✓ — new meta-tool skill with `format: procedural`, YAML frontmatter (name, description, format), `**Triggers**` line, `## Process` section with exactly 6 numbered `### Step N` sub-sections (Step 1: resolve paths, Step 2: enumerate observed items, Step 3: compare against canonical expected set, Step 4: build and present plan / dry-run, Step 5: apply plan, Step 6: write report), and `## Rules` section. The skill MUST include: the canonical expected item set inline (cross-referenced to `claude-folder-audit` Check P8); explicit scope note stating it reads live `.claude/` folder state — NOT `audit-report.md`; explicit note that it MUST NOT target `~/.claude/`; the CLAUDE.md stub content (5 section headings as specified in design.md); the `$HOME / $USERPROFILE / $HOMEDRIVE+$HOMEPATH` path resolution chain for Windows compatibility; the three-category plan format (missing / unexpected / already-correct); and report structure per the `folder-organizer-reporting` spec.

---

## Phase 2: CLAUDE.md Registration

- [x] 2.1 Modify `CLAUDE.md` (Available Commands table, `### Meta-tools — Project Management` section) — add row `| /project-claude-organizer | Reads the project .claude/ folder, compares against canonical SDD structure, and applies reorganization after user confirmation |` immediately after the `/memory-update` row. ✓

- [x] 2.2 Modify `CLAUDE.md` (How I Execute Commands dispatch table, `### Meta-tools` section) — add row `| /project-claude-organizer | ~/.claude/skills/project-claude-organizer/SKILL.md |` immediately after the `/memory-update` row. ✓

- [x] 2.3 Modify `CLAUDE.md` (Skills Registry, `### System Audits` section) — add entry `- ~/.claude/skills/project-claude-organizer/SKILL.md — reads project .claude/ folder, compares against canonical SDD structure, and applies additive reorganization after user confirmation` immediately after the `claude-folder-audit` entry. ✓

---

## Phase 3: Architecture Memory Update

- [x] 3.1 Modify `ai-context/architecture.md` (artifact table under "Communication between skills via artifacts") — add a new row for `claude-organizer-report.md` with: Producer = `project-claude-organizer`; Consumer = humans / operators; Location = `.claude/claude-organizer-report.md` in the target project (runtime artifact, never committed). Insert the row after the `~/.claude/claude-folder-audit-report.md` row to keep related audit artifacts adjacent. ✓

---

## Phase 4: Verification Prep

- [x] 4.1 Verify `skills/project-claude-organizer/SKILL.md` passes structural compliance checks manually: confirm YAML frontmatter with `---` delimiters is present; `format: procedural` is declared; `**Triggers**` marker line is present; `## Process` section with `### Step` sub-sections is present; `## Rules` section is present; body is at least 30 lines. ✓

- [x] 4.2 Verify `CLAUDE.md` diff is correct: three rows added (Available Commands, dispatch table, Skills Registry); no existing rows removed or modified; Markdown table alignment is valid. ✓

- [x] 4.3 Verify `ai-context/architecture.md` diff is correct: one new row added to the artifact table; all existing rows preserved; no `[auto-updated]` sections inadvertently modified. ✓

---

## Phase 5: Cleanup

- [x] 5.1 Update `ai-context/changelog-ai.md` — add an entry recording: date 2026-03-04, change `project-claude-folder-organizer`, description "Added `project-claude-organizer` skill (procedural meta-tool) that reads project `.claude/` folder, compares against canonical SDD structure, and applies additive reorganization after user confirmation. Registered in CLAUDE.md Available Commands, dispatch table, and Skills Registry. Added `claude-organizer-report.md` row to architecture.md artifact table." ✓

---

## Implementation Notes

- The SKILL.md must be fully self-contained — do NOT reference any runtime imports or other skill files at execution time. The canonical expected item set MUST be defined inline (not imported from `claude-folder-audit`).
- The apply step is strictly additive: only `mkdir` operations for `skills/` and `hooks/` directories, and `write stub` for `CLAUDE.md`. No delete, move, or overwrite operations.
- The CLAUDE.md stub written by the skill (when `CLAUDE.md` is missing) must contain the exact 5 section headings from design.md (Tech Stack, Architecture, Unbreakable Rules, Plan Mode Rules, Skills Registry) — this ensures `claude-folder-audit` P1-C section-heading sub-check passes after the organizer runs.
- The `## Rules` section in SKILL.md must explicitly state: (1) target is `PROJECT_ROOT/.claude/` only — never `~/.claude/`; (2) apply step is strictly additive; (3) user confirmation gate MUST NOT be skipped; (4) canonical expected item set MUST remain consistent with `claude-folder-audit` Check P8.
- Report format follows `folder-organizer-reporting` spec: structured header (run date, project root, target, summary), `## Plan Executed` section with three subsections (Created / Unexpected items / Already correct), stub content description when files are created, `## Recommended Next Steps`, and a footer `.gitignore` reminder.

## Blockers

None.
