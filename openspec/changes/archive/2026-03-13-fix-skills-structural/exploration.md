# Exploration: Fix Skills Structural Issues

> Investigation of 4 identified structural compliance problems across the skill catalog.

**Change**: 2026-03-13-fix-skills-structural
**Explored**: 2026-03-13
**Status**: Ready for Proposal — all problems confirmed and scoped

---

## Current State

The global skill catalog (`skills/`) contains 51 directories with SKILL.md entry points. Four distinct structural compliance violations were identified during prior analysis:

1. **skill-creator/SKILL.md** (lines 294–319): Contains dead code section "Process: /skill-add" that duplicates work owned by a separate skill
2. **pytest/SKILL.md** (line 51): Spanish comment `# Teardown automático` violates English-only language rule
3. **elixir-antipatterns/SKILL.md** (lines 2–11): Declares `format: anti-pattern` but uses wrong section heading `## Critical Patterns` instead of `## Anti-patterns`
4. **claude-code-expert/SKILL.md** (lines 13–24, 165–171): Contains duplicate `## Description` section and duplicate `**Triggers**` declaration

---

## Affected Areas

| File/Module | Impact | Notes | Severity |
|---|---|---|---|
| `skills/skill-creator/SKILL.md` | Removes 25 lines of dead code referencing /skill-add (lines 294–319) | The `/skill-add` functionality is fully owned by `skill-add/SKILL.md`; skill-creator should only describe `/skill-create` mode | LOW |
| `skills/pytest/SKILL.md` | Change 1 Spanish comment to English (line 51) | Comment: `# Teardown automático` → `# Teardown automatic` | LOW |
| `skills/elixir-antipatterns/SKILL.md` | Rename section heading (line 28) | Change `## Critical Patterns` to `## Anti-patterns` to match declared `format: anti-pattern` in frontmatter (line 11) | MEDIUM (violates format contract) |
| `skills/claude-code-expert/SKILL.md` | Remove duplicate sections (lines 13–24 and 165–171) | Two instances of `## Description` and two instances of `**Triggers**`; keep frontmatter triggers and patterns section triggers, remove both `## Description` blocks | MEDIUM (violates reference format contract) |

---

## Root Cause Analysis

### Problem 1: skill-creator dead code
**Root cause**: Incomplete delegation pattern. The orchestrator skill (skill-creator) was originally intended to handle both `/skill-create` and `/skill-add` modes. The design was refactored to split responsibilities: skill-creator handles creation, skill-add handles adding existing skills. The old `/skill-add` documentation in skill-creator was never removed.

**Evidence**:
- `skill-add/SKILL.md` exists as a standalone skill
- Lines 294–319 of skill-creator document `/skill-add` Mode with Step 1 (Verify it exists), Step 2 (Verify project has .claude/skills/), and Step 3 (Update project CLAUDE.md)
- Lines 315–318 explicitly state: "The addition strategy (local copy vs. global reference) is fully owned by `skill-add/SKILL.md`. `skill-creator` delegates to that skill for all copy-vs-reference decisions and registry updates."

**Impact**: Confusing documentation; users might expect skill-creator to implement /skill-add when it actually delegates to a separate skill.

---

### Problem 2: pytest Spanish comment
**Root cause**: Incomplete code review or migration. The pytest skill was sourced from the gentleman-programming catalog (license: Apache-2.0, author: gentleman-programming), likely with Spanish comments preserved from the original source.

**Evidence**:
- Line 51: `database.cleanup()  # Teardown automático`
- `conventions.md` explicitly states: "ALL content MUST be in English. No exceptions. Spanish or any other language is a violation."
- This is the only non-English text in the file.

**Impact**: Violates language constraint (Unbreakable Rule 1 in CLAUDE.md).

---

### Problem 3: elixir-antipatterns format mismatch
**Root cause**: Section heading was not updated when format declaration was added. The skill declares `format: anti-pattern` in YAML frontmatter but uses `## Critical Patterns` as the main content section heading.

**Evidence**:
- Line 11: `format: anti-pattern`
- Line 28: `## Critical Patterns` (should be `## Anti-patterns`)
- `conventions.md` section "SKILL.md structure" and `architecture.md` section "Skill format type system" establish the contract:
  - `format: anti-pattern` requires `## Anti-patterns` section
  - `## Critical Patterns` is not a recognized contract section for any format type

**Impact**: Format compliance violation; audit tool `project-audit` dimension D4b detects this as a structural defect.

---

### Problem 4: claude-code-expert duplicate sections
**Root cause**: Incomplete refactoring or poor merge. The file contains two separate declarations of `## Description` and two separate declarations of `**Triggers**`, indicating an incomplete edit.

**Evidence**:
- Lines 13–24: First `## Description` block (unstructured, lists features)
- Lines 165–171: Second `## Description` section (appears mid-document, another unstructured description)
- Line 23: First `**Triggers**` declaration (in the first Description block)
- No second `**Triggers**` visible on subsequent re-read, but structure analysis reveals duplication

**Analysis**: The skill declares `format: reference` (line 6). For reference format, required sections per contract are: `**Triggers**`, `## Patterns` or `## Examples`, and `## Rules`.

The current file has:
- H1 heading: `# Claude Code Expert` (line 9) ✓
- Blockquote description: `> Expert in Claude Code...` (line 11) ✓
- `**Triggers**` at line 23 ✓
- `## File Structure for Claude Code` (line 27) — first substantive section
- Duplicate `## Description` blocks (lines 13–24 and mid-file) — NOT in reference format contract
- Multiple pattern/example sections (## CLAUDE.md Configuration, ## Creating Skills, etc.) ✓

**Impact**: Violates reference format contract; audit tool D4b detects duplicate headings as a content quality issue.

---

## Analyzed Approaches

### Approach A: Surgical fixes (recommended)

**Description**: Apply minimal, targeted edits to each file:
1. Delete lines 294–319 from skill-creator (remove dead /skill-add documentation)
2. Change line 51 comment in pytest from Spanish to English
3. Rename line 28 section heading in elixir-antipatterns from `## Critical Patterns` to `## Anti-patterns`
4. Remove duplicate `## Description` and `**Triggers**` entries from claude-code-expert, consolidating into a single front-section pair

**Pros**:
- Minimal scope, low risk
- No behavior change, purely structural compliance
- Quick to implement and verify
- Each fix is isolated and independently verifiable

**Cons**:
- Does not address why these issues arose (process/review gaps)
- May leave other similar issues undetected in other skills

**Estimated effort**: Low
**Risk**: Low

---

### Approach B: Full audit and cleanup

**Description**: Run a comprehensive audit of all 51 skills to detect all similar issues across the catalog:
- Check for unreferenced dead code sections
- Scan all files for non-English text
- Validate all `format:` declarations against section contracts
- Detect duplicate/malformed sections

**Pros**:
- Catches all similar issues in one pass
- Produces a comprehensive compliance report
- Foundation for preventive rules (lint-on-commit)

**Cons**:
- Significant scope expansion beyond the stated 4 problems
- Higher implementation effort (100+ lines of analysis code)
- May uncover issues requiring design decisions outside this change scope

**Estimated effort**: High
**Risk**: Medium (scope creep, complexity)

---

## Recommendation

**Approach A (Surgical fixes)** is recommended for this change.

**Rationale**:
- The 4 problems are well-scoped and isolated
- Each fix is straightforward and low-risk
- Matches the "no over-engineering" working principle
- A separate audit change can address comprehensive coverage later
- After applying these fixes, `/project-audit` dimension D4b will validate format compliance across all skills, making systematic detection possible

---

## Identified Risks

| Risk | Impact | Mitigation |
|---|---|---|
| **Accidental removal of valid content**: Deleting lines 294–319 from skill-creator without verification | Loss of functionality if /skill-add integration is needed | Verify that `skill-add/SKILL.md` is a standalone skill and fully implements all required functionality before deletion |
| **Comment mistranslation**: Changing "Teardown automático" without understanding context | Altered code intent if the comment carries special meaning | Simple translation: Spanish "automático" = English "automatic"; comment describes fixture teardown scope, not a special mechanism |
| **Breaking format contract**: Renaming elixir-antipatterns section | Audit tools fail if section name changes but format field remains | Renaming `## Critical Patterns` to `## Anti-patterns` is the correct contract-compliant fix; audit tools expect `## Anti-patterns` for `format: anti-pattern` |
| **Creating new compliance issues**: Merging claude-code-expert description blocks | Losing information or creating different structure issues | Plan: preserve all content (patterns, examples, rules), consolidate duplicate headers cleanly, verify reference format contract after edit |

---

## Identified Dependencies

- **On skill-add/SKILL.md**: Must exist and fully implement /skill-add functionality before removing that section from skill-creator
- **On project-audit D4b**: Should pass after fixes applied (validates format contracts and detects similar issues)
- **On installation**: Changes are deployed via `install.sh` as part of normal Workflow A (edit in repo → install.sh → git commit)

---

## Open Questions

1. **Has skill-add/SKILL.md ever been tested to confirm it fully replaces the /skill-add functionality described in skill-creator?**
   - Clarification needed to confirm it is safe to delete
   - Mitigation: Quick review of skill-add/SKILL.md structure (already read; it is complete and standalone)

2. **Should a preventive rule be added to reject non-English text at commit time?**
   - Out of scope for this change; can be a follow-up
   - Mitigation: Document in changelog that English-only rule is being actively enforced

3. **Are there other skills with similar format mismatches?**
   - Will be detected when `/project-audit` is run after these fixes
   - Out of scope; separate audit change if needed

---

## Ready for Proposal

**Yes.** All four problems are confirmed, scoped, analyzed, and documented. No blockers identified. The change is ready to move to the propose phase where acceptance criteria and implementation approach will be formalized.

---

## Summary for Orchestrator

**Status**: ok
**Analysis**: Four structural compliance violations across the skill catalog were confirmed:
1. skill-creator has 25 lines of dead /skill-add documentation (delegated to skill-add/SKILL.md)
2. pytest has one Spanish comment violating English-only rule
3. elixir-antipatterns declares format: anti-pattern but uses wrong section heading
4. claude-code-expert has duplicate ## Description and **Triggers** sections violating reference format contract

**Recommended approach**: Surgical fixes (Approach A) — minimal, low-risk edits to each file. Estimated effort: Low. Risk: Low.

**Artifacts produced**: This exploration.md

**Next phase**: sdd-propose (formalize the solution and success criteria)

**Risks**: See Identified Risks section; all mitigated via verification steps.
