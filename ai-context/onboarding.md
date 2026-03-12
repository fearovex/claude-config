# Onboarding — External Projects

> Canonical workflow for onboarding an existing project to SDD and Claude Code best practices.
> Last verified: 2026-02-26

---

## Prerequisites

Before starting, verify all four of the following:

1. **Claude Code installed** — `claude --version` returns a version string without error
2. **Global SDD skills present** — the following files exist:
   ```
   ~/.claude/skills/sdd-explore/SKILL.md
   ~/.claude/skills/sdd-propose/SKILL.md
   ~/.claude/skills/sdd-spec/SKILL.md
   ~/.claude/skills/sdd-design/SKILL.md
   ~/.claude/skills/sdd-tasks/SKILL.md
   ~/.claude/skills/sdd-apply/SKILL.md
   ~/.claude/skills/sdd-verify/SKILL.md
   ~/.claude/skills/sdd-archive/SKILL.md
   ```
3. **Target project accessible** — you can `cd` into the project root and it has a recognizable structure (any language/framework)
4. **install.sh run at least once** — `~/.claude/` contains the latest skills from `agent-config`. If in doubt, run `bash ~/agent-config/install.sh` before proceeding.

If any prerequisite fails, resolve it before running the onboarding sequence.

---

## Onboarding Sequence

### Step 1 — `/project-setup`

**What it does**: Bootstraps the SDD + memory architecture in the project:
- Creates `.claude/CLAUDE.md` (or updates it) with SDD section and stack references
- Creates `openspec/` directory with `config.yaml` initialized for the project
- Creates `ai-context/` directory with skeleton files

**Success criterion**: `.claude/CLAUDE.md`, `openspec/config.yaml`, and `ai-context/` all exist in the project root after running.

**Common failure modes**:
- `CLAUDE.md` already exists with content → `project-setup` merges conservatively. Review the result manually for duplicated sections.
- `openspec/config.yaml` is created with placeholder stack → proceed to Step 2, which will populate real content.

---

### Step 2 — `/memory-init`

**What it does**: Reads the project from scratch and generates substantive `ai-context/` files:
- `stack.md` — detects language, framework, key dependencies with real versions from `package.json`, `pyproject.toml`, etc.
- `architecture.md` — reads folder structure and config files, documents the detected architectural pattern
- `conventions.md` — samples 3-5 code files, infers and documents naming conventions
- `known-issues.md` — starts with a production safety section; leave content to be filled as issues are discovered
- `changelog-ai.md` — creates with an initial entry documenting this onboarding

**Success criterion**: All 5 `ai-context/` files exist and have more than the minimum line count (stack.md > 30, architecture.md > 40, conventions.md > 30, known-issues.md > 10, changelog-ai.md > 5 lines with at least one dated entry).

**Common failure modes**:
- No `package.json` or `pyproject.toml` found → `stack.md` will contain placeholder data. Edit it manually with the real stack.
- Project has very few code files → `conventions.md` inference will be sparse. Supplement manually.

---

### Step 3 — `/project-audit`

**What it does**: Runs 9 diagnostic dimensions across the project's Claude configuration:
- D1: CLAUDE.md completeness and accuracy
- D2: Memory layer existence and content quality
- D3: SDD orchestrator operational status
- D4: Skills registry coherence and quality
- D5: Commands registry coherence
- D6: Cross-reference integrity
- D7: Architecture compliance sampling
- D8: Testing and verification integrity
- D9: Project-specific skills quality (if `.claude/skills/` exists)

Produces `.claude/audit-report.md` with a score (/100), a `FIX_MANIFEST` block, and itemized findings.

**Success criterion**: `.claude/audit-report.md` is created with a valid YAML `FIX_MANIFEST` block. Score is readable.

**Common failure modes**:
- `audit-report.md` is created but score is very low (< 50) → expected for a project just onboarded. Run Step 4 to apply corrections.
- Audit errors on a dimension (e.g. "cannot read file") → check file permissions or path issues.

---

### Step 4 — `/project-fix`

**What it does**: Reads `audit-report.md` as a spec and implements the corrections found:
- Phase 1 (Critical): creates missing `openspec/config.yaml`, initializes SDD sections in CLAUDE.md, installs missing global skills
- Phase 2 (High): creates missing `ai-context/` files, updates stack in CLAUDE.md, fixes Skills/Commands registry
- Phase 3 (Medium): adds missing CLAUDE.md sections, fixes broken cross-references
- Phase 4 (Low/optional): recommends global tech skills to add, surfaces architecture violations
- Phase 5 (D9): handles project-specific skill quality actions (if any)

**Success criterion**: After running, re-run `/project-audit`. The new score should be ≥ the score before Step 4. SDD Readiness should be `FULL` or `PARTIAL` (not `NOT CONFIGURED`).

**Common failure modes**:
- `audit-report.md` is more than 7 days old → `project-fix` warns and asks before proceeding. Re-run `/project-audit` to get a fresh report.
- A critical action fails (e.g. can't create `openspec/config.yaml`) → `project-fix` stops and reports. Resolve the blocker manually then re-run.
- Score does not improve after Step 4 → run `/project-audit` again. Some findings may require manual action (architecture violations, language corrections). Check the Required Actions section of the new report.

---

## After Onboarding

Once the sequence is complete:

```bash
# Verify with a final audit
/project-audit   # target: score ≥ 75, SDD Readiness = FULL or PARTIAL

# Start a new feature with SDD
/sdd-new add-my-feature   # launches full SDD cycle

# Or fast-forward (for well-understood changes)
/sdd-ff add-my-feature
```

For projects with existing `.claude/skills/` that need review, Dimension 9 of `/project-audit` will surface:
- Skills that duplicate the global catalog → candidates for deletion or promotion
- Skills with missing structural sections → auto-fixable by `/project-fix` Phase 5
- Skills with non-English content → flagged for manual translation

---

## Maintenance

- Run `/project-audit` periodically (after major feature additions or stack upgrades) to catch drift
- Run `/memory-update` after significant AI-assisted work to keep `ai-context/` current
- Update `ai-context/known-issues.md` manually as production issues are discovered
