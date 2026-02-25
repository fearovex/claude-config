# Tasks: add-global-config-exception

## Task 1 — Add project-type detection to project-audit Dimension 1

**File:** `skills/project-audit/SKILL.md`
**Where:** At the top of `### Dimensión 1 — CLAUDE.md`, before the checks table

Add a detection block:

```
**Project type detection (run before checks):**

Check if the project is a `global-config` repo:
- Condition: `install.sh` + `sync.sh` exist at project root, OR
- Condition: `openspec/config.yaml` contains `framework: "Claude Code SDD meta-system"`

If detected as global-config:
  - Accept `CLAUDE.md` at root as equivalent to `.claude/CLAUDE.md`
  - Note in report header: `Project Type: global-config`
  - The CLAUDE.md path check passes without penalty
```

## Task 2 — Update the CLAUDE.md existence check row

**File:** `skills/project-audit/SKILL.md`
**Where:** The checks table in Dimension 1

Change:
```
| Existe `.claude/CLAUDE.md` | Intento leerlo | ❌ CRÍTICO |
```
To:
```
| Existe `.claude/CLAUDE.md` (or root `CLAUDE.md` for global-config repos) | Intento leerlo | ❌ CRÍTICO |
```

## Verification

- Run `/project:audit` on `claude-config` → expect 100/100
- Run `/project:audit` on Audiio V3 → score must not change (exception should not trigger)
