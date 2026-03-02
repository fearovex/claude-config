# SKILL.md is the mandatory, uniquely-named entry point for every skill directory

## Status

Accepted (retroactive)

> This decision predates the ADR system and is recorded retroactively.

---

## Context

ADR-001 established that each skill is a directory, not a single file. Once a skill lives in a directory, a second question arises: what is the entry point file called?

Without a convention, entry points could be named anything: `README.md`, `index.md`, `instructions.md`, `skill.md`, or the skill's own name (e.g., `sdd-apply.md`). Arbitrary naming creates several problems:

- **Routing ambiguity**: Claude cannot deterministically locate a skill's instructions without scanning the directory for an entry point — or maintaining a separate registry mapping skill names to filenames.
- **Discoverability**: a contributor looking at an unfamiliar skill directory cannot immediately identify which file to read.
- **Tooling consistency**: scripts, hooks, and meta-skills that reference skill files (e.g., the Skills Registry in CLAUDE.md) need a predictable path pattern. A variable filename breaks the pattern `skills/<name>/SKILL.md`.
- **Case sensitivity**: on case-sensitive filesystems, `Skill.md` and `skill.md` are different files. A canonical casing eliminates the ambiguity.

---

## Decision

Every skill directory contains exactly one file named `SKILL.md` — UPPER_CASE, with no alternatives or aliases permitted. This file is the sole entry point Claude reads when a skill is invoked.

The path pattern is always:

```
skills/<skill-name>/SKILL.md
```

No other file in the directory serves as an entry point. Supporting files (templates, examples, sub-skill fragments) may exist in the same directory but are referenced explicitly from within `SKILL.md`, not auto-loaded.

A valid `SKILL.md` must contain at minimum:
- **Trigger definition** — when to use this skill
- **Process** — step-by-step instructions Claude follows
- **Rules** — constraints and invariants

---

## Consequences

**Positive:**
- Claude can locate any skill without directory scanning: the path `skills/<name>/SKILL.md` is fully deterministic.
- The Skills Registry in CLAUDE.md uses a uniform `~/.claude/skills/<name>/SKILL.md` pattern consistently across all 43+ skills.
- Contributors always know which file to open when reading or editing a skill.
- Scripts and meta-skills can reference skill entry points programmatically without a lookup table.

**Negative:**
- The naming is strict: any deviation (`skill.md`, `Skill.md`, `README.md`) silently breaks routing. There is no fallback.
- New contributors must learn the convention before creating or editing skills.
- The UPPER_CASE convention for `.md` files is non-standard and may feel surprising to contributors accustomed to lowercase filenames.
