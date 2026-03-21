# Technical Design: 2026-03-20-remove-gentleman-programming

Date: 2026-03-20
Proposal: openspec/changes/2026-03-20-remove-gentleman-programming/proposal.md

## General Approach

All changes are single-line or multi-line text replacements across 8 file groups. No logic, no behavior, and no skill functionality is altered. The apply pass performs a targeted find-and-replace: remove `author:` frontmatter lines from 17 skill files, rename one CLAUDE.md section header, rephrase 3 notes in `docs/format-types.md`, remove one attribution line in `docs/architecture-definition-report.md`, rephrase 2 spec lines in `openspec/specs/format-contract/spec.md`, rephrase 1 spec line in `openspec/specs/skills-catalog-format/spec.md`, rephrase 1 note in `ai-context/known-issues.md`, and append one entry to `ai-context/changelog-ai.md`. After file edits, `install.sh` is run to propagate the CLAUDE.md change to `~/.claude/`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| How to remove `author:` lines | Delete the entire `author:` line from YAML frontmatter (no replacement) | Replace with a different author value; leave field empty | The field has no functional role in the SDD system. Removing it entirely is cleaner than substitution. All other frontmatter fields (`name`, `description`, `format`) are preserved. |
| CLAUDE.md section header replacement | Rename to `### Technology Skills (global catalog)` | Keeping the full original label; using a different neutral phrasing | Minimal diff — only the parenthetical suffix changes. The new label is accurate and self-contained. |
| Scope: archive and changelog exclusion | Exclude all `openspec/changes/archive/` files and all existing `ai-context/changelog-ai.md` lines from edits | Edit archives for consistency | Archives are sealed historical records. Editing them would corrupt the SDD audit trail. Changelog is append-only by project convention. |
| Spec rephrase strategy | Replace `"from the Gentleman-Skills corpus"` / `"Gentleman-Skills corpus"` with `"externally-sourced skills"` / `"externally-sourced"` in place | Removing the entire sentence; rewriting the spec requirement | Preserves the meaning of the requirement (variant headings are accepted for externally-sourced skills). Only the brand name is removed. |
| Apply tooling | Manual file edits via Edit tool (one edit per target line) | Scripted sed/grep replacement | Targeted edits are auditable, reversible, and produce a clean git diff. Scripted replacements risk unintended matches in archived content. |

## Data Flow

```
apply agent
    │
    ├── Edit skills/*/SKILL.md (17 files)
    │       remove: author: gentleman-programming (1 line per file)
    │
    ├── Edit CLAUDE.md (1 line)
    │       rename: ### Technology Skills (global catalog — extracted from Gentleman-Skills)
    │           →   ### Technology Skills (global catalog)
    │
    ├── Edit docs/format-types.md (3 lines)
    │       rephrase: "from the Gentleman-Skills corpus" → removed
    │
    ├── Edit docs/architecture-definition-report.md (1 line)
    │       remove: > **Reference**: Based on [agent-teams-lite](...) v2.0
    │
    ├── Edit openspec/specs/format-contract/spec.md (2 lines)
    │       rephrase: "Gentleman-Skills corpus" → "externally-sourced skills"
    │
    ├── Edit openspec/specs/skills-catalog-format/spec.md (1 line)
    │       rephrase: "from the Gentleman-Skills corpus" → (neutral)
    │
    ├── Edit ai-context/known-issues.md (1 line)
    │       rephrase: "Gentleman-Skills corpus" → "externally-sourced skills"
    │
    ├── Append ai-context/changelog-ai.md (1 new entry)
    │
    └── Run install.sh → deploys CLAUDE.md to ~/.claude/
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/ai-sdk-5/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/django-drf/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/electron/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/github-pr/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/hexagonal-architecture-java/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/jira-epic/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/jira-task/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/nextjs-15/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/playwright/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/pytest/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/react-19/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/react-native/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/spring-boot-3/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/tailwind-4/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/typescript/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/zod-4/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `skills/zustand-5/SKILL.md` | Modify | Remove `author: gentleman-programming` from frontmatter |
| `CLAUDE.md` | Modify | Rename `### Technology Skills (global catalog — extracted from Gentleman-Skills)` → `### Technology Skills (global catalog)` (applies to both occurrences — project CLAUDE.md and installed `~/.claude/CLAUDE.md` via install.sh) |
| `docs/format-types.md` | Modify | Rephrase 3 notes: remove `" from the Gentleman-Skills corpus"` / `"the Gentleman-Skills corpus"` — keep all other text |
| `docs/architecture-definition-report.md` | Modify | Remove line: `> **Reference**: Based on [agent-teams-lite](...) v2.0` |
| `openspec/specs/format-contract/spec.md` | Modify | Rephrase 2 occurrences: `"Gentleman-Skills corpus"` → `"externally-sourced skills"` |
| `openspec/specs/skills-catalog-format/spec.md` | Modify | Rephrase 1 occurrence: `"from the Gentleman-Skills corpus"` → removed |
| `ai-context/known-issues.md` | Modify | Rephrase 1 note: `"Gentleman-Skills corpus"` → `"externally-sourced skills"` |
| `ai-context/changelog-ai.md` | Modify | Append new session entry documenting brand reference removal |

## Interfaces and Contracts

No interface or type changes. All changes are to Markdown/YAML text content only.

**Frontmatter contract after edits (representative):**
```yaml
---
name: react-19
description: >
  [existing description unchanged]
format: reference
---
```
The `author:` line is simply absent. No other field changes.

**Format contract variant heading note after edits (docs/format-types.md):**
The exception clause remains functionally identical — only the brand attribution suffix is removed:

Before: `…Both standard and variant names are equally valid — variants appear in externally-sourced skills from the Gentleman-Skills corpus.`
After:  `…Both standard and variant names are equally valid — variants appear in externally-sourced skills.`

**Success verification command:**
```bash
grep -ri "gentleman" skills/ docs/ openspec/specs/ CLAUDE.md ai-context/known-issues.md
# Must return zero matches after apply
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Verification grep | Zero "gentleman" matches in live files | `grep -ri "gentleman" skills/ docs/ openspec/specs/ CLAUDE.md ai-context/known-issues.md` |
| Frontmatter integrity | No `author:` field present in any skill under `skills/` | `grep -r "^author:" skills/` → must return no matches |
| Format contract exception preserved | Variant headings clause still present in `docs/format-types.md` | `grep -c "Critical Patterns" docs/format-types.md` → must return ≥ 1 |
| Archive integrity | No changes to archive files or prior changelog entries | `git diff openspec/changes/archive/` → must show no changes |
| Install deploy | `install.sh` runs without errors | `bash install.sh` → exit code 0 |

No unit or integration test infrastructure exists in this repo — verification is manual grep + git diff as defined in the proposal's Success Criteria.

## Migration Plan

No data migration required. All changes are to text files under version control.

## Open Questions

None.
