# Exploration: remove-gentleman-programming

## Current State

The term "gentleman programming" (and its variants: "Gentleman-Skills", "gentleman-programming", "Gentleman Programming") appears across 41 files in the repository. The references fall into distinct categories based on their nature and mutability:

### Category 1 — Live skill YAML frontmatter (17 files, HIGH priority)

All 17 technology skills carry `author: gentleman-programming` in their YAML frontmatter. These are the primary live references:

- `skills/react-19/SKILL.md`
- `skills/nextjs-15/SKILL.md`
- `skills/typescript/SKILL.md`
- `skills/zustand-5/SKILL.md`
- `skills/zod-4/SKILL.md`
- `skills/tailwind-4/SKILL.md`
- `skills/ai-sdk-5/SKILL.md`
- `skills/react-native/SKILL.md`
- `skills/electron/SKILL.md`
- `skills/django-drf/SKILL.md`
- `skills/spring-boot-3/SKILL.md`
- `skills/hexagonal-architecture-java/SKILL.md`
- `skills/jira-task/SKILL.md`
- `skills/jira-epic/SKILL.md`
- `skills/github-pr/SKILL.md`
- `skills/playwright/SKILL.md`
- `skills/pytest/SKILL.md`

Each has `author: gentleman-programming` on line 8 of its YAML frontmatter.

### Category 2 — CLAUDE.md Skills Registry header (1 line)

```
CLAUDE.md line 651: ### Technology Skills (global catalog — extracted from Gentleman-Skills)
```

This section header labels the tech skill block in the Skills Registry. It would need to be renamed to a neutral label.

### Category 3 — docs/format-types.md variant notes (3 occurrences)

`docs/format-types.md` lines 120, 202, 272 contain explanatory notes that variant section headings (`## Critical Patterns`, `## Code Examples`) are accepted because they "appear in externally-sourced skills from the Gentleman-Skills corpus." These notes exist to explain an audit exception — if the label is removed, the notes need rewording but the audit exception logic itself is NOT tied to the name.

### Category 4 — docs/architecture-definition-report.md (1 reference)

Line 8: `> **Reference**: Based on [agent-teams-lite](https://github.com/Gentleman-Programming/agent-teams-lite) v2.0`

This is a URL reference (external GitHub org). The URL itself is factual attribution — removing "Gentleman-Programming" from the URL would break the link. The question is whether to remove the line entirely, keep it as-is, or neutralize the label.

### Category 5 — ai-context/ memory files (2 references)

- `ai-context/known-issues.md` line 110: references "Gentleman-Skills corpus" in explaining a structural finding.
- `ai-context/changelog-ai.md` line 536: references "Gentleman-Skills corpus skills" in a historical changelog entry.

These are historical records. The changelog entry especially should NOT be edited (it records what actually happened).

### Category 6 — openspec/specs/ master specs (4 occurrences, live specs)

- `openspec/specs/format-contract/spec.md` lines 13 and 135 — live master spec for format-contract domain.
- `openspec/specs/skills-catalog-format/spec.md` line 35 — live master spec for skills-catalog-format domain.

These contain requirements referencing the corpus by name; they need rephrasing.

### Category 7 — openspec/changes/archive/ (25+ references)

Multiple archived SDD change folders contain historical references:
- `2026-02-27-global-config-skill-audit/` — verify-report.md, CLOSURE.md
- `2026-02-28-normalize-tech-skill-structure/` — proposal.md, CLOSURE.md
- `2026-03-13-fix-format-contract/` — exploration.md, proposal.md, prd.md, design.md, tasks.md, specs/, CLOSURE.md
- `2026-03-14-skills-catalog-analysis/` — exploration.md, design.md, tasks.md, specs/, CLOSURE.md
- `2026-03-13-fix-skills-structural/` — exploration.md

Archives are historical records and are generally **not recommended to edit** — they preserve the rationale of past decisions including the original source attribution.

---

## Branch Diff

Files modified in current branch relevant to this change:
- No files in the current branch directly related to the gentleman-programming removal (the dirty branch state is from unrelated concurrent changes to SDD skills and orphan cleanup).

---

## Prior Attempts

No prior attempts found in archive matching slug stems "remove", "gentleman", "programming".

---

## Contradiction Analysis

- Item: `author:` field in skill YAML frontmatter
  Status: UNCERTAIN — The `author:` field is metadata attribution. No spec requires it to be present or absent. Removing it is safe but deletes provenance.
  Severity: INFO
  Resolution: Remove `author: gentleman-programming` lines — they carry no functional meaning for the SDD system.

- Item: `docs/format-types.md` variant notes
  Status: UNCERTAIN — The format contract exception (accepting variant headings) is NOT tied to the name "Gentleman-Skills". The logic is sound regardless of source attribution. Rewording to "externally-sourced skills" or "imported skills" preserves the rule without the brand name.
  Severity: INFO
  Resolution: Rephrase to "externally-sourced skills" — no loss of semantic meaning.

- Item: `docs/architecture-definition-report.md` URL reference
  Status: UNCERTAIN — The GitHub URL contains "Gentleman-Programming" as the org name. Removing the URL would break external attribution. The line is a reference note, not a functional requirement.
  Severity: INFO
  Resolution: Either remove the line entirely or keep the URL as-is (factual external attribution). Recommend removing the line since the report is internal documentation.

- Item: Archive files
  Status: CERTAIN — Archive files are historical records. Editing them alters the project's decision history.
  Severity: WARNING
  Resolution: Do NOT edit archive files. Leave them as-is. They record what happened; the name is historical fact, not a live policy reference.

- Item: `ai-context/changelog-ai.md`
  Status: CERTAIN — Changelog entries are append-only historical records.
  Severity: WARNING
  Resolution: Do NOT edit existing changelog entries. A new entry can note the removal.

---

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `CLAUDE.md` | LOW | 1 line — section header rename |
| `skills/*/SKILL.md` (17 files) | LOW | Remove `author: gentleman-programming` frontmatter line |
| `docs/format-types.md` | LOW | Rephrase 3 explanatory notes to "externally-sourced skills" |
| `docs/architecture-definition-report.md` | LOW | Remove or keep URL line (attribution) |
| `openspec/specs/format-contract/spec.md` | LOW | Rephrase 2 references to "externally-sourced skills" |
| `openspec/specs/skills-catalog-format/spec.md` | LOW | Rephrase 1 reference |
| `ai-context/known-issues.md` | INFO | Rephrase 1 explanatory note (not historical) |
| `ai-context/changelog-ai.md` | NO CHANGE | Historical record — do not edit |
| `openspec/changes/archive/**` | NO CHANGE | Historical records — do not edit |

---

## Analyzed Approaches

### Approach A: Full removal — all live files only, archives untouched

**Description**: Remove or rephrase all "gentleman" references from live files (CLAUDE.md, skills/, docs/, openspec/specs/, ai-context/known-issues.md). Leave all archive files and changelog-ai.md unchanged.

**Pros**:
- Clean forward-looking state with no brand references in active configuration
- Archives preserve historical decision record (audit trail intact)
- Changelog entry is historically accurate
- Low risk — all changes are cosmetic (metadata, labels, notes)

**Cons**:
- The `docs/format-types.md` notes still need rephrasing to explain variant headings without the source attribution — slightly less informative

**Estimated effort**: Low
**Risk**: Low

### Approach B: Full removal — all files including archives

**Description**: Remove every occurrence across all 41 files.

**Pros**: Zero occurrences anywhere.

**Cons**:
- Corrupts historical records and decision audit trail
- Archives are referenced artifacts from completed SDD cycles — editing them violates `sdd-archive` rules
- Changelog entries should be append-only

**Estimated effort**: Low-Medium
**Risk**: Medium (historical record integrity)

### Approach C: Partial removal — frontmatter only

**Description**: Only remove `author: gentleman-programming` from the 17 skill files. Leave CLAUDE.md, docs/, and specs/ unchanged.

**Pros**: Minimal scope.

**Cons**: CLAUDE.md still has the explicit "extracted from Gentleman-Skills" label; docs/format-types.md still mentions the corpus. Incomplete.

**Estimated effort**: Very Low
**Risk**: Low

---

## Recommendation

**Approach A** is recommended: remove/rephrase all live file references, leave archives and changelog untouched.

**Specific actions:**

1. **17 skill SKILL.md files** — remove the `author: gentleman-programming` line from YAML frontmatter.
2. **CLAUDE.md** — rename the section header from `### Technology Skills (global catalog — extracted from Gentleman-Skills)` to `### Technology Skills (global catalog)`.
3. **docs/format-types.md** — rephrase 3 notes: replace "externally-sourced skills from the Gentleman-Skills corpus" with "externally-sourced skills".
4. **docs/architecture-definition-report.md** — remove the `> **Reference**: Based on...` line (internal doc, attribution not required).
5. **openspec/specs/format-contract/spec.md** — rephrase 2 references.
6. **openspec/specs/skills-catalog-format/spec.md** — rephrase 1 reference.
7. **ai-context/known-issues.md** — rephrase 1 note.
8. **ai-context/changelog-ai.md** and **openspec/changes/archive/** — NO CHANGES (historical records).

Total: 24 file edits across 7 file types. All changes are purely cosmetic (metadata, labels, notes) — no functional behavior is altered.

---

## Identified Risks

- **Format contract regression risk**: LOW — The variant heading exception in `docs/format-types.md` must be preserved even after rephrasing. The logic (accept `## Critical Patterns` and `## Code Examples`) is unchanged; only the attribution label is removed.
- **No functional impact**: The `author:` field in YAML frontmatter is metadata only; no SDD phase reads or uses it.
- **Archive integrity**: MEDIUM if archive files are edited — the recommendation is to leave them unchanged.

---

## Open Questions

- Should `docs/architecture-definition-report.md` line 8 be removed entirely or is the external URL reference (GitHub org) considered factual attribution worth keeping?
- Should a new `ai-context/changelog-ai.md` entry be added documenting this removal?

---

## Ready for Proposal

Yes — scope is fully mapped, approach is clear, risks are low. All changes are cosmetic. Ready for `sdd-propose`.
