# Task Plan: 2026-03-20-remove-gentleman-programming

Date: 2026-03-20
Design: openspec/changes/2026-03-20-remove-gentleman-programming/design.md

## Progress: 28/28 tasks

---

## Phase 1: Removals and Replacements

### 1a — Remove `author: gentleman-programming` from skill frontmatter (17 files)

- [ ] 1.1 Remove `author: gentleman-programming` line from `skills/ai-sdk-5/SKILL.md` frontmatter
  Linked spec: N/A — no spec for this removal (pure metadata cleanup)
  Files: `skills/ai-sdk-5/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; all other frontmatter fields (`name`, `description`, `format`) preserved

- [ ] 1.2 Remove `author: gentleman-programming` line from `skills/django-drf/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/django-drf/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.3 Remove `author: gentleman-programming` line from `skills/electron/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/electron/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.4 Remove `author: gentleman-programming` line from `skills/github-pr/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/github-pr/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.5 Remove `author: gentleman-programming` line from `skills/hexagonal-architecture-java/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/hexagonal-architecture-java/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.6 Remove `author: gentleman-programming` line from `skills/jira-epic/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/jira-epic/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.7 Remove `author: gentleman-programming` line from `skills/jira-task/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/jira-task/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.8 Remove `author: gentleman-programming` line from `skills/nextjs-15/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/nextjs-15/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.9 Remove `author: gentleman-programming` line from `skills/playwright/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/playwright/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.10 Remove `author: gentleman-programming` line from `skills/pytest/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/pytest/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.11 Remove `author: gentleman-programming` line from `skills/react-19/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/react-19/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.12 Remove `author: gentleman-programming` line from `skills/react-native/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/react-native/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.13 Remove `author: gentleman-programming` line from `skills/spring-boot-3/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/spring-boot-3/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.14 Remove `author: gentleman-programming` line from `skills/tailwind-4/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/tailwind-4/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.15 Remove `author: gentleman-programming` line from `skills/typescript/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/typescript/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.16 Remove `author: gentleman-programming` line from `skills/zod-4/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/zod-4/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

- [ ] 1.17 Remove `author: gentleman-programming` line from `skills/zustand-5/SKILL.md` frontmatter
  Linked spec: N/A — pure metadata cleanup
  Files: `skills/zustand-5/SKILL.md` (MODIFY — delete `author:` line)
  Acceptance: Line absent; remaining frontmatter intact

### 1b — Replace brand-named labels and attribution references

- [ ] 1.18 Replace section header in `CLAUDE.md` — rename `### Technology Skills (global catalog — extracted from Gentleman-Skills)` to `### Technology Skills (global catalog)`
  Linked spec: Requirement: skill-metadata-attribution REQ-1 (section header neutralization)
  Files: `CLAUDE.md` (MODIFY — 1 line change; both project CLAUDE.md occurrences)
  Acceptance: No occurrence of "Gentleman-Skills" in the section header; all other content unchanged

- [ ] 1.19 Rephrase 3 explanatory notes in `docs/format-types.md` — remove `" from the Gentleman-Skills corpus"` / `"the Gentleman-Skills corpus"` suffix from variant heading exception clauses
  Linked spec: Requirement: format-contract REQ — variant heading exception preserved
  Files: `docs/format-types.md` (MODIFY — 3 occurrences)
  Acceptance: "Gentleman-Skills" absent; variant heading exception clause for `## Critical Patterns` and `## Code Examples` still present and semantically equivalent

- [ ] 1.20 Remove attribution line from `docs/architecture-definition-report.md` — delete `> **Reference**: Based on [agent-teams-lite](...) v2.0` line
  Linked spec: N/A — internal doc; no spec requires this line
  Files: `docs/architecture-definition-report.md` (MODIFY — delete 1 line)
  Acceptance: Line absent; no other content removed

- [ ] 1.21 Rephrase 2 requirement descriptions in `openspec/specs/format-contract/spec.md` — replace `"Gentleman-Skills corpus"` with `"externally-sourced skills"`
  Linked spec: Requirement: format-contract spec self-update (lines 13, 135)
  Files: `openspec/specs/format-contract/spec.md` (MODIFY — 2 occurrences)
  Acceptance: "Gentleman-Skills" absent; requirement semantics preserved — variant headings are accepted for externally-sourced skills

- [ ] 1.22 Rephrase 1 requirement description in `openspec/specs/skills-catalog-format/spec.md` — remove `"from the Gentleman-Skills corpus"` from requirement text
  Linked spec: Requirement: skills-catalog-format spec self-update (line 35)
  Files: `openspec/specs/skills-catalog-format/spec.md` (MODIFY — 1 occurrence)
  Acceptance: "Gentleman-Skills" absent; surrounding requirement text preserved

- [ ] 1.23 Rephrase 1 structural note in `ai-context/known-issues.md` — replace `"Gentleman-Skills corpus"` with `"externally-sourced skills"`
  Linked spec: N/A — live memory file; no spec requirement governs this note
  Files: `ai-context/known-issues.md` (MODIFY — 1 occurrence)
  Acceptance: "Gentleman-Skills" absent; note meaning preserved

---
⚠️ Phase 2 MUST NOT begin until all Phase 1 tasks are complete.
---

## Phase 2: Documentation and Memory Update

- [ ] 2.1 Append new session entry to `ai-context/changelog-ai.md` documenting the brand reference removal
  Files: `ai-context/changelog-ai.md` (MODIFY — append only; no existing lines edited)
  Acceptance: New entry present at end of file; all prior entries unchanged; entry describes the change as cosmetic brand cleanup across 7 file groups

## Phase 3: Deployment

- [ ] 3.1 Run `bash install.sh` from the project root to deploy updated `CLAUDE.md` (and all other changed files) to `~/.claude/`
  Files: `~/.claude/` (runtime deploy — not tracked in git)
  Acceptance: `install.sh` exits with code 0; `~/.claude/CLAUDE.md` no longer contains "Gentleman-Skills" in the section header

## Phase 4: Verification

- [ ] 4.1 Run `grep -ri "gentleman" skills/ docs/ openspec/specs/ CLAUDE.md ai-context/known-issues.md` — must return zero matches
  Files: read-only verification
  Acceptance: Exit code 1 (no matches) or empty output

- [ ] 4.2 Run `grep -r "^author:" skills/` — must return zero matches
  Files: read-only verification
  Acceptance: Exit code 1 (no matches) confirming all `author:` frontmatter lines removed

- [ ] 4.3 Run `grep -c "Critical Patterns" docs/format-types.md` — must return ≥ 1
  Files: read-only verification
  Acceptance: Count ≥ 1, confirming variant heading exception clause preserved

- [ ] 4.4 Run `git diff openspec/changes/archive/` — must show no changes
  Files: read-only verification
  Acceptance: Empty diff confirming archive files are untouched

- [ ] 4.5 Verify `ai-context/changelog-ai.md` has no deleted lines (only appended) — run `git diff ai-context/changelog-ai.md` and confirm no `-` lines in prior content
  Files: read-only verification
  Acceptance: No deletions in existing changelog lines; only new lines at the end

---

## Implementation Notes

- All Phase 1 edits are single-line or multi-line text replacements — no logic, no behavior, no skill functionality changes.
- The variant heading exception clause in `docs/format-types.md` (accepting `## Critical Patterns` and `## Code Examples` as valid section names for externally-sourced skills) MUST be preserved verbatim except for removal of the brand name. Verify after task 1.19.
- `CLAUDE.md` contains the section header in two places (project file and it is the same content — one file). Confirm both project `CLAUDE.md` occurrences are updated in task 1.18.
- `ai-context/changelog-ai.md` is append-only — task 2.1 MUST NOT modify any existing line.
- `docs/architecture-definition-report.md`: remove only the `> **Reference**: ...` attribution line; do not remove the external URL if it appears elsewhere in the document.
- Archive exclusion is absolute: `openspec/changes/archive/**` files MUST NOT be touched at any point during apply.

## Blockers

None.
