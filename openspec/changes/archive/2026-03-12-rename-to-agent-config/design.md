# Technical Design: 2026-03-12-rename-to-agent-config

Date: 2026-03-12
Proposal: openspec/changes/2026-03-12-rename-to-agent-config/proposal.md

## General Approach

This change is a **semantic text replacement** across the repository — not a structural or behavioral change. The project name `claude-config` is replaced with `agent-config` in all user-facing and project-identity contexts while preserving intentional references (historical ADR content, comments explaining the runtime directory `~/.claude/`, shell command examples that use relative paths). The replacement is organized in 5 stages of decreasing priority: critical config files → ai-context memory layer → skill documentation → docs/ → verification. No file moves or renames are required.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Replacement strategy | Targeted per-file review, not global regex replace | Global `sed -i 's/claude-config/agent-config/g'` | Global replace would corrupt occurrences where "claude-config" refers to the GitHub repo URL, historical ADR content, or the runtime path `~/.claude/` — all of which must be preserved |
| Stage ordering | Config → memory → skills → docs → verification | Alphabetical, random, single-batch | Highest-impact files first; verification stage confirms no regressions |
| SKILL.md scope | Update only where `claude-config` appears as the project name or in path examples | Update all SKILL.md files unconditionally | Many SKILL.md files have no such reference; applying changes only where needed reduces review surface and error risk |
| GitHub repo rename | Out of scope (separate admin action) | Do it simultaneously | Repo rename affects remote URLs, CI configs, and collaborator workflows — it requires coordination outside this code change |
| `~/.claude/` path references | Preserve as-is | Replace with `~/.agent-config/` | `~/.claude/` is controlled by Claude Code itself and is immutable from this repo's perspective |
| install.sh / sync.sh | No changes required | Update hardcoded paths | Both scripts use `$HOME/.claude` (runtime) and relative paths (repo) — neither references the project name `claude-config` |

## Data Flow

This is a documentation/identity change with no data flow. The replacement flow is:

```
sdd-apply sub-agent
    │
    ├── Stage 1: Critical config files
    │       README.md                   (title, description, install path examples)
    │       CLAUDE.md                   (architecture diagram, step descriptions)
    │       openspec/config.yaml        (name field, root field)
    │
    ├── Stage 2: AI context / memory layer
    │       ai-context/stack.md         (project title, directory tree heading)
    │       ai-context/architecture.md  (project title, diagram labels)
    │       ai-context/conventions.md   (project title heading)
    │       ai-context/known-issues.md  (project title, if present)
    │       ai-context/changelog-ai.md  (project title, if present)
    │
    ├── Stage 3: Skill documentation (49 SKILL.md files)
    │       Scan all skills/*/SKILL.md for occurrences of "claude-config"
    │       Replace only project-name occurrences (clone paths, context lines)
    │       Preserve occurrences in `~/.claude/` path references
    │
    ├── Stage 4: Documentation files
    │       docs/adr/README.md          (intro sentence referencing the project name)
    │       docs/*.md (other files)     (scan and replace where applicable)
    │       .github/copilot-instructions.md (if present)
    │
    └── Stage 5: Verification
            grep -r "claude-config" across repo
            Confirm <5 matches (only ~\.claude/, historical ADRs, or URLs)
            Run bash install.sh — must succeed
            Run bash sync.sh — must succeed (unchanged)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `README.md` | Modify | Project title and description heading (`claude-config` → `agent-config`) |
| `CLAUDE.md` | Modify | Architecture diagram label, step description text (8 occurrences) |
| `openspec/config.yaml` | Modify | `name: "agent-config"`, `root: "~/agent-config"` |
| `ai-context/stack.md` | Modify | H1 title, directory tree heading (`claude-config/`) |
| `ai-context/architecture.md` | Modify | H1 title, diagram labels referencing the project |
| `ai-context/conventions.md` | Modify | H1 title |
| `ai-context/known-issues.md` | Modify | H1 title (if references project name) |
| `ai-context/changelog-ai.md` | Modify | H1 title (if references project name) |
| `skills/*/SKILL.md` (up to 49) | Modify | Targeted replacement of `claude-config` in project-name contexts |
| `docs/adr/README.md` | Modify | Intro sentence referencing `claude-config system` |
| `docs/*.md` (scan) | Modify | Any file with direct project-name references |
| `.github/copilot-instructions.md` | Modify (if exists) | Project name in description section |

**Files explicitly NOT modified:**
| File | Reason |
|------|--------|
| `install.sh` | Uses `$HOME/.claude` (runtime path) and relative repo paths — no `claude-config` reference |
| `sync.sh` | Same as install.sh |
| `docs/adr/NNN-*.md` (individual ADRs) | Historical record — preserve verbatim per proposal exclusions |
| Any file referencing `~/.claude/` | Runtime path is immutable, controlled by Claude Code |
| GitHub remote URL | Out of scope — separate admin action |

## Interfaces and Contracts

No interface changes. This is a text-identity change. The following fields change value but retain the same semantics:

```yaml
# openspec/config.yaml — before
project:
  name: "claude-config"
  root: "~/claude-config"

# openspec/config.yaml — after
project:
  name: "agent-config"
  root: "~/agent-config"
```

The `root` field change in `openspec/config.yaml` reflects the intended future state where the local directory clone is named `agent-config`. The `~/.claude/` runtime path is unchanged and independent of this field.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Verification grep | `grep -r "claude-config" <repo>` returns <5 matches | Bash |
| Install script | `bash install.sh` exits 0 with no errors | Bash |
| Sync script | `bash sync.sh` exits 0 with no errors | Bash |
| Manual spot-check | Sample 5 SKILL.md files and confirm correct replacement without corruption | Manual review |
| audit | `/project-audit` score >= previous score | Claude Code |

No automated unit tests exist for this project (expected — it is a Markdown/YAML/Bash meta-system). Verification is via grep count + script execution + project-audit.

## Migration Plan

No data migration required. This is a text-identity rename with no schema or data changes.

The replacement is fully reversible via `git revert` (see Rollback Plan in proposal.md).

## Open Questions

None. The proposal scope and exclusions are clearly defined and no architectural ambiguities remain.
