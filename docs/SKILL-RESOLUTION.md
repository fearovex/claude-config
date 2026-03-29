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
2. Check openspec/config.yaml skill_overrides    (explicit redirect — overrides both)
3. Check ~/.claude/skills/<name>/SKILL.md        (global catalog — fallback)
4. ERROR: skill not found — report and stop
```

### Precedence rules

- A project-local skill at `.claude/skills/<name>/SKILL.md` **always** takes precedence over `~/.claude/skills/<name>/SKILL.md`.
- If `openspec/config.yaml` has a `skill_overrides` entry for `<name>`, that path is used instead of both locations (absolute paths supported).
- The global catalog is the fallback when neither of the above is found.
- Resolution failure is fatal: the skill MUST NOT silently fall back to a hardcoded path.

---

## Config Override (optional)

Add a `skill_overrides` section to `openspec/config.yaml` to redirect specific skills to custom paths:

```yaml
skill_overrides:
  sdd-explore: ".claude/skills/custom-explore/SKILL.md"    # relative to project root
  sdd-apply: "/absolute/path/to/my-apply/SKILL.md"         # absolute path
```

Override paths may be absolute or relative to the project root. Relative paths are resolved from the project root (where `openspec/config.yaml` lives).

---

## Resolution Algorithm

Each SDD phase skill and meta-tool implements this algorithm in its Step 0:

```
function resolve_skill_path(skill_name, project_root):
  # 1. Check openspec/config.yaml for explicit override
  config = read(project_root + "/openspec/config.yaml")
  if config.skill_overrides[skill_name] exists:
    override_path = config.skill_overrides[skill_name]
    resolved = absolute(override_path, base=project_root)
    if file_exists(resolved):
      log INFO: "Skill resolution: [skill_name] → [resolved] (source: config override)"
      return resolved
    else:
      log WARNING: "Skill resolution: override path [resolved] not found — falling through"

  # 2. Check project-local
  local_path = project_root + "/.claude/skills/" + skill_name + "/SKILL.md"
  if file_exists(local_path):
    log INFO: "Skill resolution: [skill_name] → [local_path] (source: project-local)"
    return local_path

  # 3. Check global catalog
  global_path = "~/.claude/skills/" + skill_name + "/SKILL.md"
  if file_exists(global_path):
    log INFO: "Skill resolution: [skill_name] → [global_path] (source: global)"
    return global_path

  # 4. Not found
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

If an override path is missing:
```
WARNING: Skill resolution: override for [name] not found at [path] — falling through to project-local/global.
```

If not found anywhere:
```
ERROR: Skill [name] not found in .claude/skills/ or ~/.claude/skills/.
```

---

## Fallback Behavior

| Situation | Behavior |
|-----------|----------|
| Config override path doesn't exist | Log WARNING, fall through to project-local then global |
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
