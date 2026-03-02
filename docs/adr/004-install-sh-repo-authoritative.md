# install.sh is the single authoritative deploy direction

## Status

Accepted (retroactive)

> This decision predates the ADR system and is recorded retroactively.

---

## Context

The claude-config system has two locations for its files:

- `~/claude-config/` — the Git repository (source of truth, version-controlled)
- `~/.claude/` — the runtime location (where Claude Code reads CLAUDE.md, skills, hooks, and settings)

Because both locations exist, there is a temptation to edit `~/.claude/` directly for quick fixes or experiments. This creates a divergence problem: the repo and the runtime fall out of sync, changes made directly in `~/.claude/` are invisible to Git and cannot be reviewed, rolled back, or shared, and the next `install.sh` run will silently overwrite direct edits.

A second temptation is to use `sync.sh` — which copies from `~/.claude/` back to the repo — for more than its intended purpose. Using `sync.sh` for skills or CLAUDE.md would reverse the authoritative direction and introduce a dual-write conflict.

The forces at play:
- Changes need to be version-controlled and reviewable
- The runtime `~/.claude/` must always reflect the repo state after a deploy
- Memory files (`~/.claude/memory/`) are written by Claude during sessions and need a path back to the repo — but this is a special case, not a general pattern
- Contributors need a clear, unambiguous rule for where to make changes

---

## Decision

`install.sh` is the single authoritative deploy direction: **repo → `~/.claude/`**. All directories (`skills/`, `CLAUDE.md`, `hooks/`, `openspec/`, `ai-context/`) flow from the repo to the runtime via `install.sh`.

`sync.sh` is the only permitted reverse direction and is narrowly scoped to `memory/` only: `~/.claude/memory/ → repo/memory/`. It exists solely to capture memory that Claude writes during sessions. It MUST NOT be used to sync skills, CLAUDE.md, hooks, or any other directory.

**The rule is absolute: never edit `~/.claude/` directly.** All changes happen in the repo and are deployed via `install.sh`.

The workflow for any config change is:

```
1. Edit files in ~/claude-config/ (repo)
2. Run install.sh  →  deploys to ~/.claude/
3. git commit
```

---

## Consequences

**Positive:**
- Single source of truth: the repo always reflects the intended state of the runtime.
- All changes are version-controlled, reviewable, and reversible via Git.
- `install.sh` is idempotent and safe to run repeatedly.
- The rule is simple enough to state in one sentence: "edit in the repo, deploy with install.sh."

**Negative:**
- Every config change — even a one-line fix — requires running `install.sh` before it takes effect in the runtime.
- Contributors unfamiliar with the architecture may instinctively edit `~/.claude/` and lose their changes on the next install.
- Memory sync (`sync.sh`) is a special case that can be confusing: it looks like a reverse deploy but is strictly limited to one directory.
