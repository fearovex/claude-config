# Skills are directories, not single files

## Status

Accepted (retroactive)

> This decision predates the ADR system and is recorded retroactively.

---

## Context

The claude-config system is built around a catalog of skills — discrete capabilities that Claude reads and executes on demand. Early on, a choice had to be made about how to store each skill: as a single flat file (e.g., `skills/sdd-apply.md`) or as a named directory containing a primary entry point.

The forces at play:

- Skills often need companion files: prompt templates, example outputs, sub-skill fragments, or configuration snippets. A single file cannot hold structured co-located assets without becoming unwieldy.
- Routing must be predictable and scannable. Claude needs to locate a skill's instructions without ambiguous matching across a flat namespace.
- Future evolution of skills (adding templates, sub-steps, or versioned examples) should not require restructuring the catalog layout.
- A flat-file approach works for simple skills but creates friction as skills grow in scope or develop supporting artifacts.

The directory approach solves all of these forces at the cost of requiring a consistent naming convention inside each directory.

---

## Decision

Every skill is stored as a named directory under `skills/`. Each directory contains exactly one uniquely-named entry point file: `SKILL.md`. Supporting files (templates, examples, sub-skill fragments) may be co-located in the same directory.

```
skills/
└── skill-name/
    └── SKILL.md        # Instructions Claude reads and executes
    └── [optional supporting files]
```

Claude resolves any skill invocation by reading `skills/<skill-name>/SKILL.md`. No other file in the directory is treated as an executable entry point.

---

## Consequences

**Positive:**
- Supporting files (templates, examples) can be co-located with the skill that owns them, keeping related content together.
- Routing is unambiguous: the path `skills/<name>/SKILL.md` is deterministic.
- Skills can evolve (adding helper files) without changing the directory layout or routing logic.

**Negative:**
- Requires strict naming discipline: the entry point must always be named `SKILL.md` (UPPER_CASE, exact spelling). Deviations silently break routing.
- Directory overhead is higher than a flat file for trivial skills that will never need co-located assets.
- Contributors must remember to create the directory, not just the file.
