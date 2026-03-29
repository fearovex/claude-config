# Skill Resolution Strategy

> How Claude Code resolves skill paths in the SDD orchestrator.

## Overview

Skills in this system have two possible locations:

1. **Project-local** — `.claude/skills/<name>/SKILL.md` (versioned with the project)
2. **Global catalog** — `~/.claude/skills/<name>/SKILL.md` (user-wide installation)

Project-local skills always win. This lets projects override any global skill without modifying the global catalog.

---

## Resolution Order

```
1. Check .claude/skills/<name>/SKILL.md         (project-local — highest priority)
2. Check ~/.claude/skills/<name>/SKILL.md        (global catalog — fallback)
3. ERROR: skill not found — report and stop
```

### Precedence rules

- A project-local skill at `.claude/skills/<name>/SKILL.md` **always** takes precedence over `~/.claude/skills/<name>/SKILL.md`.
- The global catalog is the fallback when no project-local skill is found.
- Resolution failure is fatal: the skill MUST NOT silently fall back to a hardcoded path.

---

## Resolution Algorithm

Each SDD phase skill and meta-tool implements this algorithm in its Step 0:

```
function resolve_skill_path(skill_name, project_root):
  # 1. Check project-local
  local_path = project_root + "/.claude/skills/" + skill_name + "/SKILL.md"
  if file_exists(local_path):
    log INFO: "Skill resolution: [skill_name] → [local_path] (source: project-local)"
    return local_path

  # 2. Check global catalog
  global_path = "~/.claude/skills/" + skill_name + "/SKILL.md"
  if file_exists(global_path):
    log INFO: "Skill resolution: [skill_name] → [global_path] (source: global)"
    return global_path

  # 3. Not found
  log ERROR: "Skill resolution: [skill_name] not found in .claude/skills/ or ~/.claude/skills/"
  return ERROR
```

---

## Logging Format

Skills report their resolution path at Step 0:

```
Skill resolution:
  sdd-explore → ~/.claude/skills/sdd-explore/SKILL.md (source: global)
  sdd-apply   → .claude/skills/sdd-apply/SKILL.md    (source: project-local)
```

If not found anywhere:
```
ERROR: Skill [name] not found in .claude/skills/ or ~/.claude/skills/.
```

---

## Fallback Behavior

| Situation | Behavior |
|-----------|----------|
| Project-local not found | Fall through to global catalog |
| Global not found | ERROR — stop execution |
| `ai-context/` files missing | Non-blocking — log INFO, continue |

---

## Adding a Project-Local Skill Override

Use `/skill-create <name>` to copy a global skill into `.claude/skills/<name>/SKILL.md`. The copied file becomes the project-local version and will be resolved first from that point on.

Alternatively, create `.claude/skills/<name>/SKILL.md` manually for entirely custom project skills.

---

## See Also

- `skills/README.md` — skill authoring guide and registry
