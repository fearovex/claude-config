# Exploration: Rename Project from `claude-config` to `agent-config`

## Current State

The project is currently named `claude-config` across multiple locations:

1. **GitHub repository** — named `claude-config` (not verified by this scan, but mentioned in proposal)
2. **Local directory** — `~/claude-config/` on developers' machines
3. **Internal references** — 405 occurrences of "claude-config" across the codebase (counted via grep)
4. **Project metadata** — references in config files, scripts, and documentation

### Project Structure Overview

The project is a Markdown + YAML + Bash-based meta-system for Specification-Driven Development (SDD) in Claude Code. It is deployed to `~/.claude/` (the Claude Code runtime) via `install.sh`, while memory is captured back via `sync.sh`.

**Key directories:**
- `skills/` — 49 skill directories with SKILL.md entry points
- `openspec/` — SDD configuration and change artifacts
- `ai-context/` — Project memory layer (stack, architecture, conventions, known-issues, changelog)
- `docs/` — Documentation including ADRs (23 ADRs)
- `hooks/` — Claude Code event hooks (Node.js)

## Affected Areas

| File/Module | Impact | Reference Type | Scope |
|-------------|--------|-----------------|-------|
| `README.md` | Title, description, references in setup instructions | Hardcoded strings | 3–5 occurrences |
| `CLAUDE.md` | Architecture diagram, install/sync descriptions | Hardcoded strings, path examples | ~8 occurrences |
| `openspec/config.yaml` | Project name, project root path | Structured config | 2 occurrences (`name` field, `root` field) |
| `install.sh` | None currently — uses relative paths (`$(dirname "$0")`) | Relative paths (safe) | 0 direct impact |
| `sync.sh` | None currently — uses `$HOME/.claude` | Relative paths (safe) | 0 direct impact |
| `ai-context/*.md` | 5 files with references (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md) | Descriptive references | ~30 occurrences |
| `docs/adr/*.md` | 23 ADR files with references to project context | Contextual references | ~20 occurrences |
| `.github/copilot-instructions.md` | Project description | Hardcoded strings | ~5 occurrences |
| `docs/*.md` (other) | Bootstrap, architecture definition, workflows | Contextual and path references | ~20 occurrences |
| SKILL.md files | References in step descriptions, examples | Contextual references | ~280 occurrences (distributed across 49 skills) |
| Various .md artifacts | Project context, examples | Contextual references | ~40 occurrences |

## Analyzed Approaches

### Approach A: Manual Find-and-Replace Across All Files

**Description**: Use `find` + `sed` or similar tools to replace all hardcoded occurrences of "claude-config" with "agent-config" across the entire codebase.

**Pros**:
- Simple, straightforward approach
- Complete coverage guaranteed if regex is correct
- No special handling needed

**Cons**:
- Risk of replacing unintended occurrences (e.g., inside comments, inline code examples)
- Requires careful handling of case-sensitivity
- Some files (especially examples in skills) may reference the old name intentionally for documentation
- No semantic understanding — replaces all matches regardless of context

**Estimated effort**: Low to Medium
**Risk**: Medium (unintended replacements in examples or inline docs)

### Approach B: Targeted File Replacement with Semantic Understanding

**Description**: Categorize files into groups and replace strategically:
1. Config/metadata files (README, CLAUDE.md, openspec/config.yaml) — direct replacement
2. Core memory files (ai-context/*.md) — targeted replacement of project description
3. Documentation files (docs/*.md, SKILL.md) — selective replacement of "claude-config" when it refers to the project name, NOT examples
4. ADRs and architectural docs — minimal changes (context only)

**Pros**:
- Semantic awareness — distinguishes between project references and incidental mentions
- Lower risk of breaking examples or contextual references
- Allows for controlled updates to specific sections

**Cons**:
- More labor-intensive
- Requires careful review of each file
- Risk of human error in selective replacement

**Estimated effort**: Medium to High
**Risk**: Low (with careful review)

### Approach C: Staged Replacement with Review Gates

**Description**: Execute a systematic three-stage approach:
1. Stage 1: Update critical config files (README, CLAUDE.md, openspec/config.yaml, ai-context/stack.md)
2. Stage 2: Update memory and documentation files (ai-context/*.md, docs/*.md)
3. Stage 3: Update SKILL.md files and distributed references
4. Each stage includes a verification step

**Pros**:
- Clear ordering and checkpoint system
- Allows incremental validation
- Reduces risk of cascading errors
- Clear rollback points between stages

**Cons**:
- Slower execution
- Requires multiple verification passes
- More complex process

**Estimated effort**: High (due to verification overhead)
**Risk**: Low to Medium (structured approach reduces errors)

## Recommendation

**Approach B (Targeted File Replacement)** is recommended because:

1. The project name is context-specific and not a functional component — changing it does not break functionality, only external references
2. The codebase is well-organized with clear categories of files (config, memory, skills, docs)
3. The `install.sh` and `sync.sh` scripts already use relative paths, so they are resistant to directory name changes
4. Selective replacement allows us to preserve example code and documentation that may reference the old name for clarity

### Execution Strategy (not final — for proposal phase)

1. Replace project name in **config metadata** (README, CLAUDE.md, openspec/config.yaml)
2. Update **AI context** files to reflect new project name (ai-context/stack.md primarily)
3. Systematically update **skill descriptions** and **documentation** where they reference the project name
4. Verify `install.sh` + `sync.sh` functionality (they should work unchanged)
5. Spot-check SKILL.md files for incidental references that should remain (examples, historical context)

## Identified Risks

1. **Scattered references across 49 skill files**: The skills directory contains distributed references. Incorrect global replacement could break inline documentation. *Mitigation:* Use targeted replacement with manual review of skill files.

2. **ADRs reference historical project context**: The 23 ADRs document decisions made in the context of "claude-config". Changing these may lose historical context. *Mitigation:* Preserve ADR content verbatim; only update the wrapper documentation like `docs/adr/README.md` if it has project-name references.

3. **User documentation assumes specific paths**: References to `~/claude-config/` in onboarding docs, scenarios, and quick-reference guides need updating. *Mitigation:* Update `ai-context/onboarding.md`, `ai-context/scenarios.md`, `ai-context/quick-reference.md` to reflect new paths.

4. **Runtime directory name (`~/.claude/`) is immutable**: The proposal correctly identifies that `~/.claude/` is controlled by Claude Code and should NOT be renamed. No action needed.

5. **GitHub repository rename is out-of-scope for code changes**: This exploration focuses on the codebase; the actual GitHub rename is a separate administrative step.

## Open Questions

1. **Should example code in SKILL.md files be updated?** Example: If a skill shows a command like `cd ~/claude-config/openspec`, should it become `cd ~/agent-config/openspec`? 
   - Recommendation: YES — for consistency and to prevent user confusion.

2. **Should ADRs be updated?** ADRs document historical decisions. Updating them could lose original context.
   - Recommendation: Update `docs/adr/README.md` (index) to reference the new project name, but preserve ADR file content verbatim to maintain historical accuracy.

3. **Should the change include a commit message explaining the rename?** This helps with git history tracking.
   - Recommendation: YES — use conventional commit `docs(config): rename project from claude-config to agent-config`.

4. **What is the rollout sequence?** Should the GitHub repo be renamed first (breaking change) or should the code be ready first?
   - Recommendation: Code changes should be ready first (on a branch), then GitHub rename, then merge. This allows users to pull the updated code on the new repo name.

## Ready for Proposal

**YES** — The exploration reveals a clear, low-risk change. The codebase is well-structured and the project name is a documentation/configuration concern, not a functional change. The only operational consideration is ensuring `install.sh` and `sync.sh` work correctly, which they should (they use relative paths).

**Confidence level**: High — This is a straightforward rename operation with well-defined scope and minimal functional risk.
