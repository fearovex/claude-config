# Technical Design: 2026-03-13-fix-skills-structural

Date: 2026-03-13
Proposal: openspec/changes/2026-03-13-fix-skills-structural/proposal.md
Exploration: openspec/changes/2026-03-13-fix-skills-structural/exploration.md

## General Approach

Apply four targeted surgical edits to repair structural compliance violations in the skill catalog. Each edit is minimal, isolated, and independently reversible. The approach uses the Edit tool with exact string matching to ensure precision. After all edits, verify each file against the format contract in `docs/format-types.md` and run `/project-audit` dimension D4b to validate structural compliance.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|----------------|
| Editing strategy | Use Edit tool with precise old_string/new_string matching | Manual sed/awk substitution via Bash; interactive text editor (vim/nano) | Edit tool provides atomic, reversible edits with clear diff output; Bash risks unintended matches; interactive editors lack auditability. |
| File verification | Read each file before and after edit to confirm changes | Trust Edit tool output alone | Files are small and critical; re-reading ensures data integrity and catches edge cases. |
| Rollback mechanism | Git checkout per file (reverses all edits in one file) | Manual reversal of Edit calls | Git provides atomic, clean rollback; matches project workflow in proposal.md. |
| Format validation | Manual inspection against `docs/format-types.md` + `/project-audit` D4b | Automated linting tool | Project has no lint rules for SKILL.md structure; manual inspection is transparent and matches existing audit practices. |
| Scope | Fix exactly 4 files; no full catalog audit | Comprehensive audit of all 51 skills | Scope creep risk; proposal explicitly excludes full audit; deferring comprehensive audit to a separate change keeps this focused and low-risk. |

## Data Flow

```
Input: 4 SKILL.md files with compliance violations
  ├── skills/skill-creator/SKILL.md (dead /skill-add block at lines 294–319)
  ├── skills/pytest/SKILL.md (Spanish comment at line 51)
  ├── skills/elixir-antipatterns/SKILL.md (wrong section heading at line 28)
  └── skills/claude-code-expert/SKILL.md (duplicate sections at lines 13–24, 165–171)
  │
  ├── PROCESS: Read files → Apply edits → Verify changes
  │
  └─► Output: 4 corrected SKILL.md files
      ├── skill-creator: /skill-add documentation removed; /skill-create docs intact
      ├── pytest: Spanish comment translated to English; no code changes
      ├── elixir-antipatterns: Section heading renamed to satisfy format contract
      └── claude-code-expert: Duplicate sections removed; all patterns and rules preserved
```

## File Change Matrix

| File | Action | What is added/modified | Lines | Risk |
|------|--------|------------------------|-------|------|
| `skills/skill-creator/SKILL.md` | Modify | Delete lines 294–319: `/skill-add` mode documentation | 25 lines removed | Low — dead code; `/skill-add` fully delegated to `skill-add/SKILL.md` |
| `skills/pytest/SKILL.md` | Modify | Line 51: Translate Spanish comment `# Teardown automático` → `# Teardown automatic` | 1 line modified | Low — comment only; no code behavior change |
| `skills/elixir-antipatterns/SKILL.md` | Modify | Line 28: Rename section `## Critical Patterns` → `## Anti-patterns` | 1 line modified | Medium — fixes format contract; content unchanged |
| `skills/claude-code-expert/SKILL.md` | Modify | Remove duplicate `## Description` (lines 13–24) and duplicate `**Triggers**` (line 23); consolidate into single clean pair | 2 sections deduplicated | Medium — preserves all patterns/examples/rules; structure only |

## Interfaces and Contracts

**Before and After Validation:**

Each file will be validated against its declared format contract from `docs/format-types.md`:

### skill-creator (format: procedural)
**Required sections**: `**Triggers**`, `## Process`, `## Rules`
**Change**: Remove `/skill-add` documentation block (lines 294–319)
**Impact on contract**: No impact — all three required sections remain intact. `/skill-create` mode docs are unaffected.

### pytest (format: procedural)
**Required sections**: `**Triggers**`, `## Process`, `## Rules`
**Change**: Translate comment on line 51
**Impact on contract**: No impact — comment is inside a code example, not a section heading. Content integrity preserved.

### elixir-antipatterns (format: anti-pattern)
**Required sections**: `**Triggers**`, `## Anti-patterns`, `## Rules`
**Before**: Declares `format: anti-pattern` (line 11) but has `## Critical Patterns` (line 28)
**After**: Rename `## Critical Patterns` → `## Anti-patterns`
**Impact on contract**: Fixes violation — now declares `anti-pattern` and has the required `## Anti-patterns` section.

### claude-code-expert (format: reference)
**Required sections**: `**Triggers**`, `## Patterns` or `## Examples`, `## Rules`
**Before**: Two `## Description` blocks (lines 13–24, 165–171) and two `**Triggers**` declarations
**After**: Single consolidated front-section pair; duplicate blocks removed
**Impact on contract**: Fixes violation — maintains required sections and all patterns/examples/rules; removes only duplicate metadata headings.

## Validation Strategy

### Step 1 — Read each file before editing
Confirm current state matches exploration.md findings.

### Step 2 — Apply Edit tool with exact string matching
- skill-creator: Delete `/skill-add` documentation block (lines 295–318 inclusive)
- pytest: Change line 51 comment from Spanish to English
- elixir-antipatterns: Rename section heading on line 28
- claude-code-expert: Remove duplicate sections and consolidate

### Step 3 — Re-read each file after editing
Verify changes applied correctly; confirm no unintended side effects.

### Step 4 — Manual format contract validation
Scan each file against `docs/format-types.md` required sections:
- skill-creator: Has `**Triggers**`, `## Process`, `## Rules` ✓
- pytest: Has `**Triggers**`, `## Process`, `## Rules` ✓
- elixir-antipatterns: Has `**Triggers**`, `## Anti-patterns`, `## Rules` ✓ (after rename)
- claude-code-expert: Has `**Triggers**`, `## Patterns`, `## Rules` ✓ (after deduplication)

### Step 5 — Project audit (dimension D4b)
Run `/project-audit` and check dimension D4b (Structural Compliance). Should report zero format contract violations for the four modified skills.

## Migration Plan

No data migration required. These are pure documentation changes to skill catalog files. No schema, configuration, or runtime behavior is affected.

## Open Questions

None. All problems are confirmed, scoped, and approach is agreed upon in proposal.md.

## Rollback Plan

Each file is independently reversible via git:

```bash
git checkout skills/skill-creator/SKILL.md
git checkout skills/pytest/SKILL.md
git checkout skills/elixir-antipatterns/SKILL.md
git checkout skills/claude-code-expert/SKILL.md
```

Or revert all changes in a single atomic operation:
```bash
git checkout skills/
```

If any edit creates unexpected side effects, re-run `/project-audit` dimension D4b will immediately detect new issues. The full audit is non-destructive and requires no remediation tools — it only reports findings.

## Implementation Sequence

1. **Read skill-creator/SKILL.md** — verify lines 294–319 contain `/skill-add` documentation
2. **Apply Edit: skill-creator** — remove dead block
3. **Re-read skill-creator/SKILL.md** — verify removal
4. **Read pytest/SKILL.md** — verify line 51 has Spanish comment
5. **Apply Edit: pytest** — translate comment
6. **Re-read pytest/SKILL.md** — verify translation
7. **Read elixir-antipatterns/SKILL.md** — verify line 28 has `## Critical Patterns`
8. **Apply Edit: elixir-antipatterns** — rename section
9. **Re-read elixir-antipatterns/SKILL.md** — verify rename
10. **Read claude-code-expert/SKILL.md** — verify duplicate sections at lines 13–24, 165–171
11. **Apply Edit: claude-code-expert** — remove duplicates
12. **Re-read claude-code-expert/SKILL.md** — verify deduplication and structure
13. **Run `/project-audit`** — verify D4b passes for all four skills

## Risks and Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Edit tool finds non-unique old_string | Low | Edit fails; no file is modified | Pre-read files and provide context around each string to ensure uniqueness; wrap in surrounding paragraph if needed. |
| Unintended content deletion from skill-creator | Low | Loss of `/skill-create` documentation | Verify `/skill-create` block (lines 1–293) is not affected; only delete `/skill-add` block. Scope deletion explicitly. |
| Comment mistranslation in pytest | Very low | Changed intent of comment | Translation is straightforward: Spanish "automático" = English "automatic". Comment context is fixture teardown — no special mechanism. |
| Format contract violation after edits | Very low | `/project-audit` D4b fails | All edits are targeted at structural violations; no cutting corners on content integrity. Files will be re-read to confirm. |

---

## Summary for Orchestrator

**Status**: Ready for implementation

**Approach**: Four surgical edits using the Edit tool with atomic, reversible changes. Minimal scope, low risk, independently verifiable.

**Files affected**: 4 SKILL.md files in skills/

**Validation**: Manual format contract check + `/project-audit` dimension D4b

**Rollback**: `git checkout skills/` or per-file revert via git

**Next phase**: `/sdd-apply` to execute edits and verification; then `/sdd-verify` with `/project-audit` output; finally `/sdd-archive` after verification passes.
