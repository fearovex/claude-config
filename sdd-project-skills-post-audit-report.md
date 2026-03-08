# SDD and Project Skills Post-Audit Report

Date: 2026-03-08
Repository: `claude-config`
Scope: `skills/sdd-*/SKILL.md` and `skills/project-*/SKILL.md`
Method: Post-remediation static review of the active skill catalog, active docs, and active master specs.

## Executive Summary

The three medium findings from the previous focused audit are now resolved in the active catalog:

- SDD phase skills now use slash-command triggers.
- The affected procedural skills now expose a literal `## Process` heading.
- Active documentation, `project-audit`, and the active master specs now treat `## Rules` as the canonical terminal rules heading.

Current health for SDD and `project-*` skills: `Good with minor residual debt`

## Resolved Findings From The Previous Audit

### RESOLVED-1: Trigger syntax normalization

All previously affected SDD phase skills now expose slash-command triggers, and `project-setup` plus `project-update` now include their slash-command forms in `**Triggers**`.

### RESOLVED-2: Procedural section contract alignment

The affected procedural skills now use a literal `## Process` heading, including `sdd-ff`, `sdd-new`, `project-setup`, `project-audit`, and `project-fix`.

### RESOLVED-3: Canonical `## Rules` enforcement

The active catalog contract now consistently treats `## Rules` as the canonical terminal rules heading. `project-audit`, `docs/format-types.md`, and the relevant master specs no longer preserve `## Execution rules` as a passing equivalent for live validation.

## Residual Findings

### MEDIUM-1: `project-audit` report template contains malformed nested code-fence closure

**Evidence**

In `skills/project-audit/SKILL.md`, the `## Report Format` template opens a five-backtick outer fence and a four-backtick inner YAML fence, but the closing sequence is malformed:

- opening outer fence at line 774: ``````markdown`
- opening inner fence at line 787: `````yaml`
- inner close at line 1104: ````
- unexpected extra close at line 1105: `````
- additional stray fence at line 1107: ````

There is also a zero-width-character fence marker at line 834.

**Why it matters**

This is active skill content, not an archived artifact. The malformed fence sequence makes the embedded report template harder to read and increases the chance that a future edit or an executing agent misinterprets where the template begins and ends.

**Recommended fix**

Rewrite the `## Report Format` fenced example into one clean, balanced nesting pattern:

- one five-backtick outer markdown fence
- one four-backtick inner YAML fence
- one matching four-backtick YAML close
- one matching five-backtick markdown close

Remove the stray extra fence markers and any zero-width workaround characters.

### LOW-1: Template `TODO` markers remain embedded in active skill examples

**Evidence**

`TODO` placeholders remain present in active example/template blocks inside:

- `skills/project-fix/SKILL.md`
- `skills/project-claude-organizer/SKILL.md`

**Why it matters**

This is still low-risk because the placeholders are inside example/scaffold blocks, not live execution instructions. The remaining risk is audit noise if a future placeholder scan is not code-fence-aware.

**Recommended fix**

Only address this if placeholder-based audits become noisy:

- make the placeholder scan code-fence-aware, or
- move the large scaffold templates into dedicated example/template files.

## Validation Notes

- `openspec/changes/` is clean again: only `archive/` is present.
- The previous trigger and process-heading inconsistencies are no longer present in the active skill catalog.
- The known external validator mismatch for skill frontmatter (`format:`, `model:`, `thinking:`) remains a tooling warning outside the scope of this post-audit review.
- MCP registration remains dependent on the `claude` CLI being available in `PATH`.

## Recommended Next Step

If you want one final cleanup pass, the best remaining target is:

1. Fix the malformed nested code fences in `skills/project-audit/SKILL.md`.

After that, the remaining debt in this area is mostly optional audit-noise reduction, not contract inconsistency.
