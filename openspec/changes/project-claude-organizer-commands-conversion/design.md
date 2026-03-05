# Technical Design: project-claude-organizer-commands-conversion

Date: 2026-03-04
Proposal: openspec/changes/project-claude-organizer-commands-conversion/proposal.md

## General Approach

The change is surgical and self-contained within `skills/project-claude-organizer/SKILL.md`. The existing advisory `commands/` delegate strategy (Steps 3b and 5.7.1) is replaced with an active `scaffold` strategy that writes a minimal but valid `SKILL.md` per qualifying source file. A new Step 3c is inserted immediately after Step 3b to introduce the skills-audit sub-step, which enumerates `.claude/skills/` and flags scope-overlap, broken-shell, and suspicious-name findings. The report template gains a new `### Skills audit` section. Two minor description-text edits are made to `CLAUDE.md` and `ai-context/architecture.md`. No other files are affected.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| commands/ strategy replacement | Change strategy from `delegate` to `scaffold` — active SKILL.md generation per qualifying file | Keep advisory-only (status quo); full interactive `/skill-create` flow per file | The proposal explicitly requires one-shot automation. Keeping advisory defeats the goal. Full interactive flow would require one sub-agent per file and breaks the single-invocation contract. Scaffold is the minimal active step: it writes a valid skeleton without user input per file. |
| Idempotency guard for scaffold | Skip if `.claude/skills/<stem>/SKILL.md` already exists; surface as `[already exists]` in report | Overwrite existing; prompt per file | Additive invariant is a core constraint of the organizer skill (Rule 2). Overwrite would violate it. Per-file prompt would require interrupting the batch. Skip + report preserves safety and composability. |
| Format inference for scaffold | Reuse existing 4-signal heuristic (step-numbered sections, trigger patterns, process headings, filename-stem keywords) to infer `procedural`/`reference`/`anti-pattern`; default to `procedural` | Hardcode all scaffolds as procedural; ask user per file | The 4-signal heuristic already exists in Step 5.7.1 for qualifying detection. Reusing it for format inference introduces no new complexity. Hardcoding as procedural would produce incorrect skeletons for reference-style commands. Per-file prompting breaks one-shot automation. |
| Skills-audit placement | New Step 3c inserted between Step 3b and Step 4; `SKILL_AUDIT_FINDINGS` list consumed by report Step 6 | Add as a separate sub-step inside Step 4; add as a new Step 7 after report | Step 3c placement mirrors Step 3b (discovery phase). Running it in Step 3 means findings are available when the plan is built in Step 4 and displayed to the user before confirmation — consistent with the existing pattern for LEGACY_MIGRATIONS. |
| Scope-overlap detection source | Cross-reference `.claude/skills/` subdirectory names against CLAUDE.md Skills Registry path entries (project-local CLAUDE.md only) | Cross-reference against global `~/.claude/skills/` filesystem; cross-reference against a hardcoded catalog list | Reading CLAUDE.md is in-scope and reliable. Filesystem enumeration of `~/.claude/skills/` would require home-directory resolution and may not be present on all machines. Hardcoded list drifts. CLAUDE.md is the authoritative registry per the two-tier skill model (ADR-008). |
| Non-qualifying commands/ files | Continue to list as advisory notes in the `### Skills audit` report section | Ignore non-qualifying files; move them to UNEXPECTED | Advisory notes are the current behavior and remain useful. Silently ignoring them would reduce transparency. Moving them to UNEXPECTED is incorrect — they are already under a known legacy directory. |
| SKILL_AUDIT_FINDINGS structure | Each finding: `skill_name`, `finding_type` (scope_overlap \| broken_shell \| suspicious_name), `severity` (HIGH \| MEDIUM \| LOW), `detail` | Flat text list without severity; grouped by severity | Structured findings with severity allow the report to produce a clean table with per-finding severity. This matches the pattern used in `claude-folder-audit` (P5 scope-overlap, P3 broken shells). |
| Report section for skills audit | New `### Skills audit` subsection inside the existing `## Plan Executed` section | Separate top-level `## Skills Audit` section; inline in `### Unexpected items` | Placing inside `## Plan Executed` keeps report structure consistent with all other subsections. A top-level section would imply it is a separate pass, which it is not. Inline in Unexpected items would conflate two different concepts. |
| Architecture pattern introduced | Scaffold strategy convention for `commands/` as a new LEGACY_PATTERN_TABLE entry | Keep delegate strategy but add optional scaffold flag | Replacing the strategy entry cleanly updates the canonical table. A flag-based variant would create conditional logic in every step that references the strategy name. The strategy name `scaffold` is already used for `requirements/` — reuse is consistent. |

## Data Flow

```
Step 3 — canonical classification
  OBSERVED_ITEMS → MISSING_REQUIRED / DOCUMENTATION_CANDIDATES / UNEXPECTED / PRESENT

Step 3b — Legacy Directory Intelligence (existing)
  UNEXPECTED → scan names against LEGACY_PATTERN_TABLE
             → commands/ match → LEGACY_MIGRATIONS (strategy: scaffold)
                                  (was: strategy: delegate)

Step 3c — Skills Audit (NEW)
  PROJECT_CLAUDE_DIR/skills/ → enumerate immediate subdirectories
                              → for each subdir:
                                (a) name in CLAUDE.md Skills Registry? → scope_overlap HIGH
                                (b) SKILL.md absent? → broken_shell MEDIUM
                                (c) name matches _* / test-* / draft-*? → suspicious_name LOW
                              → SKILL_AUDIT_FINDINGS[]

Step 4 — Dry-run plan display
  LEGACY_MIGRATIONS + SKILL_AUDIT_FINDINGS → presented to user (scaffold strategy shown for commands/)
                                           → skills audit summary shown as a table

Step 5.7.1 — scaffold strategy (commands/) (MODIFIED from delegate)
  For each qualifying .md file in commands/:
    1. derive skill_name (kebab-case stem)
    2. infer format type (4-signal heuristic)
    3. check idempotency: .claude/skills/<stem>/SKILL.md exists? → [already exists]
    4. generate SKILL.md skeleton (frontmatter + format-correct sections + copy source content)
    5. write to .claude/skills/<stem>/SKILL.md
    6. record outcome: scaffolded | already exists | non-qualifying

  Non-qualifying files:
    record: <filename> — non-qualifying. Advisory note in report.

Step 6 — Report
  All outcomes → claude-organizer-report.md
  ### Legacy migrations → commands/ section shows scaffold outcomes
  ### Skills audit (NEW section) → SKILL_AUDIT_FINDINGS as table (skill | finding | severity)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-claude-organizer/SKILL.md` | Modify | (1) LEGACY_PATTERN_TABLE row for `commands/`: strategy changed from `delegate` to `scaffold`; (2) Step 3b `commands/` pattern detail block: description updated to scaffold strategy; (3) New Step 3c inserted after Step 3b: SKILL_AUDIT_FINDINGS enumeration logic; (4) Step 4 dry-run display: scaffold summary for commands/, skills audit table display; (5) Step 5.7.1: replace delegate advisory logic with active scaffold logic; (6) Step 6 report template: add `### Skills audit` subsection |
| `CLAUDE.md` | Modify | Skills Registry entry for `project-claude-organizer`: update description to mention active commands/ scaffold and skills audit |
| `ai-context/architecture.md` | Modify | Artifact table entry for `claude-organizer-report.md`: update description to mention the new `### Skills audit` section |

## Interfaces and Contracts

### SKILL_AUDIT_FINDINGS entry structure

```
SKILL_AUDIT_FINDING = {
  skill_name:    string,          // directory name under .claude/skills/
  finding_type:  "scope_overlap"  // skill name matches a global registry entry in CLAUDE.md
               | "broken_shell"   // directory contains no SKILL.md
               | "suspicious_name",// name matches _*, test-*, or draft-* pattern
  severity:      "HIGH"           // scope_overlap
               | "MEDIUM"         // broken_shell
               | "LOW",           // suspicious_name
  detail:        string           // human-readable detail, e.g. "also registered as ~/.claude/skills/react-19/"
}
```

### SKILL.md skeleton generated for qualifying commands/ files

The skeleton structure depends on the inferred format type:

**Procedural (default):**
```markdown
---
name: <stem>
description: >
  <stem> — migrated from .claude/commands/<filename>.md
format: procedural
---

# <stem>

> <stem> procedure.

**Triggers**: <stem>

---

## Process

<source file content copied here>

---

## Rules

- <!-- Add rules and constraints here. -->
```

**Reference:**
```markdown
---
name: <stem>
description: >
  <stem> — migrated from .claude/commands/<filename>.md
format: reference
---

# <stem>

> <stem> reference.

**Triggers**: <stem>

---

## Patterns

<source file content copied here>

---

## Rules

- <!-- Add rules and constraints here. -->
```

**Anti-pattern:**
```markdown
---
name: <stem>
description: >
  <stem> — migrated from .claude/commands/<filename>.md
format: anti-pattern
---

# <stem>

> <stem> anti-patterns.

**Triggers**: <stem>

---

## Anti-patterns

<source file content copied here>

---

## Rules

- <!-- Add rules and constraints here. -->
```

### Format inference heuristic (for scaffold)

Uses same signals as the existing 4-marker qualifying detection:
- Contains `## Anti-patterns` heading → `anti-pattern`
- Contains `## Patterns` or `## Examples` heading (without step-numbered sections) → `reference`
- Otherwise (step-numbered sections, process headings, trigger patterns, or keyword stem, or no signals) → `procedural`

Anti-pattern detection takes precedence; reference detection is second; `procedural` is the default fallback.

### Scope-overlap detection logic

```
1. Read PROJECT_CLAUDE_DIR/CLAUDE.md
2. Extract all paths from the Skills Registry section matching the pattern:
   `~/.claude/skills/<name>/SKILL.md`
3. Build GLOBAL_REGISTRY_NAMES = set of <name> values
4. For each immediate subdirectory D of PROJECT_CLAUDE_DIR/skills/:
   if D.name in GLOBAL_REGISTRY_NAMES:
     add SKILL_AUDIT_FINDING(skill_name=D.name, finding_type="scope_overlap",
                              severity="HIGH",
                              detail="also referenced as ~/.claude/skills/" + D.name + "/")
```

### Skills audit report section format

```markdown
### Skills audit

<!-- Present only when SKILL_AUDIT_FINDINGS is non-empty. Otherwise: "None." -->

| Skill | Finding | Severity |
|-------|---------|----------|
| `react-19` | scope_overlap — also referenced as `~/.claude/skills/react-19/` | HIGH |
| `_draft-auth` | suspicious_name — leading underscore prefix | LOW |
| `my-broken-skill` | broken_shell — no SKILL.md found in directory | MEDIUM |

> Findings are advisory only. No files were deleted or modified as part of skills audit.
> Remediate scope_overlap findings by removing the local copy or de-registering the global path from CLAUDE.md.
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — scaffold happy path | Run `/project-claude-organizer` on a project with a `commands/` dir containing a qualifying `.md` file; verify `SKILL.md` is created under `.claude/skills/<stem>/` | Manual invocation |
| Manual — idempotency | Run a second time on the same project; verify no overwrite occurs and `[already exists]` appears in report | Manual invocation |
| Manual — non-qualifying passthrough | Verify non-qualifying `commands/` files produce advisory notes, not scaffold files | Manual invocation |
| Manual — skills audit HIGH | Place a project-local skill with the same name as a global registry entry; verify HIGH finding appears in report | Manual invocation |
| Manual — skills audit MEDIUM | Create an empty `.claude/skills/my-skill/` dir (no SKILL.md); verify MEDIUM finding appears | Manual invocation |
| Manual — skills audit LOW | Create `.claude/skills/test-foo/SKILL.md`; verify LOW finding appears | Manual invocation |
| Manual — project-audit D4b | Run `/project-audit` on a project after scaffold; verify generated SKILL.md files pass section-contract check | `/project-audit` invocation |

## Migration Plan

No data migration required.

The change is a forward-compatible extension to an existing Markdown procedural skill. Prior behavior (advisory-only for `commands/`) is replaced; no rollback of previously generated SKILL.md files is needed since none exist by definition (the previous strategy produced zero file writes).

## Open Questions

None.
