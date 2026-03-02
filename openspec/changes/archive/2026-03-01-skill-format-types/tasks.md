# Task Plan: skill-format-types

Date: 2026-03-01
Design: openspec/changes/skill-format-types/design.md

## Progress: 12/12 tasks

---

## Phase 1: Foundation — Canonical Reference Document

- [x] 1.1 Create `docs/format-types.md` ✓ defining the 3 canonical format types (`procedural`, `reference`, `anti-pattern`) with formal names, purpose descriptions, required section contracts, the default-to-procedural rule for absent declarations, and the INFO-finding rule for unknown values

---

## Phase 2: CLAUDE.md — Rule 2 Update

- [x] 2.1 Modify `CLAUDE.md` ✓ (project copy) — update Unbreakable Rule §2 ("Skill structure") to: (a) replace the single unconditional `## Process` requirement with a format-aware statement, (b) add `format:` frontmatter field documentation (valid values, default), and (c) add a reference link to `docs/format-types.md`

---

## Phase 3: project-audit — Format-Aware Validation

- [x] 3.1 Modify `skills/project-audit/SKILL.md` — update the D4 (Global Skills Quality) check ✓ to: parse YAML frontmatter for `format:` before structural validation; apply `## Process` check for `procedural` (or absent/unknown); apply `## Patterns` or `## Examples` check for `reference`; apply `## Anti-patterns` check for `anti-pattern`; emit MEDIUM finding keyed to the format's required section when missing; emit INFO finding when `format:` value is unrecognized
- [x] 3.2 Modify `skills/project-audit/SKILL.md` — update the D9 (Project Skills Quality) check ✓ with the identical format-aware logic applied in task 3.1 (D4 and D9 must be consistent)

---

## Phase 4: project-fix — Format-Aware Skeleton Repair

- [x] 4.1 Modify `skills/project-fix/SKILL.md` ✓ — update Phase 5.3 `add_missing_section` handler to: (a) read `format:` from the target skill's frontmatter at repair time (not solely from FIX_MANIFEST), (b) select the stub template matching the declared format: `## Process` for procedural/absent, `## Patterns` for reference, `## Anti-patterns` for anti-pattern, and (c) add the two new stub templates (`## Patterns`, `## Anti-patterns`) to the stub library section

---

## Phase 5: skill-creator — Format-Selection Step

- [x] 5.1 Modify `skills/skill-creator/SKILL.md` — insert Step 1b ✓ (format selection) after the existing information-gathering step: present the 3 format types with brief descriptions (referencing `docs/format-types.md`), apply inference heuristics (technology-name pattern → reference; `*-antipatterns` pattern → anti-pattern; action/verb pattern → procedural), always show the inferred or prompted type to the user for confirmation before proceeding
- [x] 5.2 Modify `skills/skill-creator/SKILL.md` — update Step 3 ✓ (skeleton generation) to branch by selected format: `procedural` → `## Process` skeleton + `format: procedural` in frontmatter; `reference` → `## Patterns` + `## Examples` skeletons + `format: reference` in frontmatter; `anti-pattern` → `## Anti-patterns` skeleton + `format: anti-pattern` in frontmatter; add fallback WARNING when `docs/format-types.md` is not found
- [x] 5.3 Modify `skills/skill-creator/SKILL.md` — add `## Rules` entry ✓: "If `docs/format-types.md` does not exist, default all new skills to `procedural` and emit WARNING: 'docs/format-types.md not found — skill-format-types change may not be applied'"

---

## Phase 6: Documentation and Memory

- [x] 6.1 Update `ai-context/architecture.md` ✓ — add entry for the skill format type system: `format:` frontmatter field, 3 valid values, default-to-procedural rule, and reference to `docs/format-types.md`
- [x] 6.2 Update `ai-context/conventions.md` ✓ — add section describing the SKILL.md `format:` convention and the format-to-required-section mapping table
- [x] 6.3 Update `ai-context/changelog-ai.md` ✓ — record the `skill-format-types` change: files modified, problem solved, key decisions
- [x] 6.4 Run `install.sh` ✓ to deploy updated skills and CLAUDE.md to `~/.claude/` (manual step — executor must run `bash install.sh` from project root after all file changes are applied)

---

## Implementation Notes

- Task 1.1 (docs/format-types.md) MUST be completed before tasks 3.1, 3.2, 4.1, 5.1 because those skills reference this file as the authoritative source — they must not embed inline copies of the contract
- Tasks 3.1 and 3.2 MUST stay in sync: D4 and D9 use the same frontmatter-parsing + format-aware logic; implement them together to avoid divergence
- Task 4.1: `project-fix` MUST read `format:` from the target skill file at repair time, not from the FIX_MANIFEST entry, because the FIX_MANIFEST may not carry the format value
- Task 5.1 and 5.2 are logically coupled steps within `skill-creator/SKILL.md` — edit them in the same pass to keep the process flow coherent
- Task 6.4 (install.sh) is a manual shell step, not a file edit — it must be run after all other tasks are complete
- No existing SKILL.md files are given `format:` declarations in this change — that migration is out of scope and tracked separately

## Blockers

None.
