# Technical Design: skills-catalog-analysis

Date: 2026-03-14
Proposal: openspec/changes/skills-catalog-analysis/proposal.md

---

## General Approach

The change resolves format contract violations and structural inconsistencies in the skills catalog in two sequential phases:

**Phase 1** updates the format contract definition to accept variant section names used by externally-sourced tech skills (`## Critical Patterns`, `## Code Examples`), then fixes the three hard violations (`elixir-antipatterns`, `claude-code-expert`, `sdd-verify`). This is a 3-file change with no content impact.

**Phase 2** adds a governance loading block to `sdd-verify` for consistency and creates documentation of the slug algorithm. This is a 4-file change with documentation-only impact.

Result: All 22 tech skills that use variant headings pass audit; hard violations are fixed; zero cascading risk.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Format contract extension | Extend `docs/format-types.md` and `project-audit/SKILL.md` detection rule to accept `## Critical Patterns` and `## Code Examples` as valid `reference` format variants | Rename all 19 tech skills to use canonical `## Patterns`/`## Examples` | Minimal change, zero content risk, aligns with Gentleman-Skills corpus convention already documented in the contract. Audit score improves immediately. Variant headings are already approved alternatives in the updated contract. |
| `elixir-antipatterns` fix | Rename `## Critical Patterns` → `## Anti-patterns` in the heading on line 28 | Keep as-is with contract change | Current state is a hard violation: declared `format: anti-pattern` but missing required `## Anti-patterns` heading. Contract change alone does not fix this; the skill's structure must be corrected. |
| `claude-code-expert` cleanup | Remove duplicate `## Description` section (line 13) and duplicate `**Triggers**` occurrence (line 23) | Leave as-is | Duplicate sections violate procedural clarity and create redundancy. Both headings appear in first 25 lines; cleanup is safe and improves readability. |
| `sdd-verify` governance block | Copy Step 0 from another SDD phase skill (exact template from `sdd-propose` or `sdd-design`), trim to Step 0 for read-only context, insert after H1/blockquote | Omit governance block | Consistency: all other SDD phase skills have Step 0. Non-blocking per SKILL.md spec. Provides context clarity without execution risk. |
| Slug algorithm documentation | Create `docs/sdd-slug-algorithm.md` with canonical algorithm description; add reference notes in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md` | Omit documentation | ADR 014 (sdd-new-improvements) introduced slug algorithm but never documented it canonically. Documentation-only change; zero behavior impact; improves future maintainability. |

---

## Data Flow

```
Phase 1 (Contract + Fixes)
  ├─ docs/format-types.md
  │  └─ extend reference format: accept ## Critical Patterns, ## Code Examples
  ├─ skills/project-audit/SKILL.md (D4b section)
  │  └─ update regex: ^## (Patterns|Critical Patterns) and ^## (Examples|Code Examples)
  ├─ skills/elixir-antipatterns/SKILL.md
  │  └─ rename ## Critical Patterns → ## Anti-patterns
  └─ skills/claude-code-expert/SKILL.md
     └─ remove duplicate ## Description and **Triggers**

Phase 2 (Consistency + Docs)
  ├─ skills/sdd-verify/SKILL.md
  │  └─ insert Step 0 governance block after **Triggers**
  ├─ docs/sdd-slug-algorithm.md
  │  └─ new file: canonical algorithm description
  ├─ skills/sdd-ff/SKILL.md
  │  └─ add reference note to Step 2
  └─ skills/sdd-new/SKILL.md
     └─ add reference note to orchestration section
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `docs/format-types.md` | Modify | Line 115: Update `## Critical Patterns` acceptance for `reference` format |
| `skills/project-audit/SKILL.md` | Modify | D4b section (line ~320): Update regex patterns to accept variant headings |
| `skills/elixir-antipatterns/SKILL.md` | Modify | Line 28: Rename `## Critical Patterns` → `## Anti-patterns` |
| `skills/claude-code-expert/SKILL.md` | Modify | Lines 13, 23: Remove duplicate `## Description` and redundant `**Triggers**` |
| `skills/sdd-verify/SKILL.md` | Modify | Insert Step 0 (governance loading block) after **Triggers** |
| `docs/sdd-slug-algorithm.md` | Create | New file: canonical slug algorithm documentation |
| `skills/sdd-ff/SKILL.md` | Modify | Add reference note to slug algorithm docs |
| `skills/sdd-new/SKILL.md` | Modify | Add reference note to slug algorithm docs |

---

## Interfaces and Contracts

### Format Contract Extension (docs/format-types.md)

**Current state (reference format):**
```
| `reference` | Patterns (one of) | `## Patterns` **or** `## Critical Patterns` (at least one) | ✅ Required |
| `reference` | Examples (one of) | `## Examples` **or** `## Code Examples` (at least one) | ✅ Required |
```

**New state (no change to table; variant headings already listed):**
The contract already accepts variants. No update needed to the text; clarification only: Line 115 in format-types.md explicitly states:
```
> **Variant headings**: `## Critical Patterns` is semantically equivalent to `## Patterns`;
> `## Code Examples` is equivalent to `## Examples`. Both standard and variant names are
> equally valid — variants appear in externally-sourced skills from the Gentleman-Skills corpus.
```

**Verification approach:** The contract already permits variant headings. No structural change required. The audit finding is a false positive caused by the detection rule in `project-audit/SKILL.md` (D4b) not using the correct regex.

### project-audit Detection Rule (skills/project-audit/SKILL.md, D4b section)

**Current logic (approximately line 320):**
```
reference skill [name] missing (## Patterns or ## Critical Patterns)
or (## Examples or ## Code Examples) section
```

**Updated detection (exact regex required):**
```regex
^## (Patterns|Critical Patterns)      # Case-sensitive, at line start
^## (Examples|Code Examples)          # Case-sensitive, at line start
```

These patterns must detect both standard and variant names. Multiline search required (one pattern per line, not in code blocks).

### elixir-antipatterns Heading Rename

**Current (incorrect):**
```markdown
## Critical Patterns
```

**Updated (correct for anti-pattern format):**
```markdown
## Anti-patterns
```

Content inside section remains unchanged. This corrects a hard format violation.

### claude-code-expert Cleanup

**Current (duplicate sections):**
- Line 13: `## Description` — explains the skill
- Line 23: `**Triggers**` — trigger definition
- Line 27 onwards: `## File Structure for Claude Code` — the actual content

**Issue:** Line 13 is labeled `## Description` but `## File Structure...` is the real patterns section. The `## Description` heading duplicates the blockquote description. Additionally, line 23 shows `**Triggers**` inline, which is redundant with the trigger line above it.

**Updated:**
- Remove line 13 `## Description` entirely
- Keep line 9-11 blockquote (serves as description)
- Remove redundant `**Triggers**:` text from line 23 (already declared on line 11 as standalone blockquote)
- Rename line 27 section to `## Patterns` (currently `## File Structure for Claude Code`)

Result: Skill becomes a proper `reference` format skill with Blockquote → Triggers → Patterns → Rules structure.

### sdd-verify Governance Block

**Location:** After `**Triggers**` line (line 14), insert new section:

```markdown
---

### Step 0 — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the full project `CLAUDE.md` (at project root). Extract and log:
   - Count of items listed under `## Unbreakable Rules`
   - Value of the primary language from `## Tech Stack`
   - Whether `intent_classification:` is `disabled` (check for Override section)
   Output a single governance log line:
   `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`
   If CLAUDE.md is absent: log `INFO: project CLAUDE.md not found — governance falls back to global defaults.`

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`

Loaded context is used as enrichment throughout all subsequent steps. It informs verification
decisions and scope assessment—but does NOT override explicit content in the artifacts.

---
```

**Rationale:** All other SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`) have identical Step 0. `sdd-verify` is currently the only phase skill without it. This is a copy-paste operation with no behavioral change.

### docs/sdd-slug-algorithm.md (New File)

Create file at `docs/sdd-slug-algorithm.md` with the following structure:

```markdown
# SDD Change Slug Algorithm

> Canonical reference for the slug generation algorithm used by `/sdd-ff` and `/sdd-new`.

## Overview

When a user invokes `/sdd-ff <description>` or `/sdd-new <description>`, the orchestrator
infers a short slug from the description using a deterministic algorithm. The slug becomes
the directory name in `openspec/changes/[slug]/` and the identifier for all related artifacts.

## Algorithm

1. **Input normalization**: Convert input string to lowercase, strip leading/trailing whitespace.

2. **Stop word removal**: Remove the following words (case-insensitive):
   - Articles: `a`, `an`, `the`
   - Prepositions: `to`, `for`, `with`, `in`, `of`, `by`, `on`, `at`, `from`
   - Conjunctions: `and`, `or`, `but`
   - Auxiliaries: `is`, `are`, `was`, `be`
   - Other: `the`, `this`, `that`, `fix`, `add`, `improve`, `update`, `refactor`

3. **Split on whitespace and non-alphanumeric characters**: Tokenize the remaining string.
   Keep only tokens that start with a letter or digit.

4. **Take first 5 meaningful tokens** (after stop-word removal): These become the slug base.

5. **Hyphenate**: Join tokens with `-`.

6. **Collision avoidance**: If a slug already exists in `openspec/changes/`, append `-N`
   where N is an auto-incrementing integer (starting at 2).

## Examples

- Input: `fix the authentication bug in login flow`
  → Stop words removed: `authentication`, `bug`, `login`, `flow`
  → Slug: `authentication-bug-login-flow`

- Input: `add payment feature`
  → Stop words removed: `payment`, `feature`
  → Slug: `payment-feature`

- Input: `improve project audit dimension D4b for reference format skills`
  → Stop words removed: `improve`, `project`, `audit`, `dimension`, `d4b`, `reference`, `format`, `skills`
  → First 5: `project`, `audit`, `dimension`, `d4b`, `reference`
  → Slug: `project-audit-dimension-d4b-reference`

## Used by

- `/sdd-ff` — Step 0: infer slug from description, launch explore with the inferred slug
- `/sdd-new` — Step 2: same algorithm, collision detection, then launch propose

## Notes

- The algorithm is deterministic: same input always produces the same slug.
- Collision avoidance is transparent to the user.
- Slugs are human-readable but automatically generated — users cannot override them.
```

---

## Testing Strategy

| Layer | What to test | Tool | Success criteria |
|-------|--------------|------|------------------|
| Format contract | Regex patterns detect variant headings correctly | grep/regex on sample skills | 19 tech skills with `## Critical Patterns` or `## Code Examples` pass audit without MEDIUM findings |
| elixir-antipatterns | Section heading present and correct | grep `^## Anti-patterns` | Skill contains exactly one `## Anti-patterns` heading |
| claude-code-expert | No duplicate sections, proper format structure | grep for `## Description\|**Triggers**` | Exactly one blockquote description, exactly one `**Triggers**` declaration, `## Patterns` section present |
| sdd-verify | Step 0 governance block present and non-blocking | Read SKILL.md | Step 0 exists after **Triggers**, non-blocking logic matches other phase skills |
| project-audit D4b | Detection rule correctly updated | Run `/project-audit` on this repo | Zero MEDIUM findings for 19 tech skills; `elixir-antipatterns` passes anti-pattern check; `claude-code-expert` passes reference check |
| Integration | All changes together produce zero audit regressions | Run `/project-audit` | Audit score same or higher than baseline before changes |

---

## Migration Plan

No data migration required. All changes are markdown edits to configuration/documentation files. Rollback is via `git revert`.

**Deployment order (Phase 1, then Phase 2):**
1. Apply Phase 1 changes (4 files)
2. Run `bash install.sh` and `/project-audit` to verify
3. Commit Phase 1
4. Apply Phase 2 changes (4 files)
5. Run `bash install.sh` to deploy
6. Commit Phase 2

---

## Open Questions

None. The proposal is detailed and unambiguous. All changes are straightforward markdown edits with no behavioral implications.

---

## Rollback Plan

Each phase is committed separately. Rollback is:

```bash
# Revert Phase 1 only
git revert <commit-sha-phase-1>

# Or revert both
git revert <commit-sha-phase-2>
git revert <commit-sha-phase-1>

# Then redeploy
bash install.sh
```

---

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Regex in project-audit matches incorrectly (false positive or false negative) | Low | Medium | After change, run `/project-audit` and manually verify 2-3 known-compliant skills and 2-3 known-violating skills |
| Step 0 in sdd-verify copied incorrectly (syntax error or logic mismatch) | Low | Low | Copy exact text from sdd-design or sdd-apply Step 0; compare side-by-side after insertion |
| Slug algorithm doc is wrong | Very low | Low | Algorithm is already implemented in sdd-ff and sdd-new; documentation just captures existing behavior |

---

## Architecture Notes

- **No breaking changes**: All changes are backwards-compatible. Variant headings are already in the contract; detection rule update aligns with documented intent.
- **Governance consistency**: Step 0 in `sdd-verify` matches the template used in all other phase skills (100% copy-paste).
- **Documentation-only Phase 2**: Slug algorithm documentation adds no new functionality—it captures and clarifies existing behavior.

