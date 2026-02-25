# project-audit

> Deep diagnostic of Claude/SDD configuration. Read-only. Produces a structured report that /project:fix consumes as its spec.

**Triggers**: `/project:audit`, audit project, review claude config, sdd diagnostic, project health check

---

## Role in SDD meta-config flow

This skill is the **equivalent of the SPEC phase** of the SDD cycle, applied to the project configuration:

```
/project-audit  →  audit-report.md  →  /project-fix  →  /project-audit (verify)
     (spec)           (artifact)          (apply)           (verify)
```

The generated report IS the specification that `/project-fix` implements. Without audit, there is no fix.

**Absolute rule**: This skill NEVER modifies files. It only reads and reports.

---

## Output artifact

When finished, save the report at:
```
[project_root]/.claude/audit-report.md
```

This file persists between sessions and is the input for `/project-fix`.

---

## Audit Process — 7 Dimensions

I run all dimensions systematically, reading real files. Never assume.

---

### Dimension 1 — CLAUDE.md

**Objective**: Verify that the project's CLAUDE.md is complete, accurate, and enables SDD.

**Project type detection (run before checks):**

Check if the project is a `global-config` repo:
- Condition A: `install.sh` + `sync.sh` exist at project root, OR
- Condition B: `openspec/config.yaml` contains `framework: "Claude Code SDD meta-system"`

If detected as global-config:
- Accept `CLAUDE.md` at root as equivalent to `.claude/CLAUDE.md`
- Note in report header: `Project Type: global-config`
- The CLAUDE.md path check passes without penalty

**Checks to run:**

| Check | How I verify | Severity if fails |
|-------|--------------|-------------------|
| Exists `.claude/CLAUDE.md` (or root `CLAUDE.md` for global-config repos) | Attempt to read it | ❌ CRITICAL |
| Not empty (>50 lines) | Count lines | ❌ CRITICAL |
| Has Stack section | Search for `## Tech Stack` or `## Stack` | ⚠️ HIGH |
| Stack matches package.json/pyproject.toml | Read both, compare key versions | ⚠️ HIGH |
| Has Architecture section | Search for `## Architecture` | ⚠️ HIGH |
| Has Skills registry | Search for skills table | ⚠️ HIGH |
| Has Commands registry | Search for commands table | ⚠️ MEDIUM |
| Has Unbreakable Rules | Search for `## Unbreakable Rules` or similar | ⚠️ MEDIUM |
| Has Plan Mode Rules | Search for `## Plan Mode` | ℹ️ LOW |
| Mentions SDD (`/sdd:new` or `/sdd:ff`) | Search for text `/sdd:` | ⚠️ HIGH |
| References to ai-context/ are correct | Verify that mentioned paths exist | ⚠️ MEDIUM |

**For the stack**: I read `package.json` (or equivalent), extract the 5-10 most important dependencies, and compare with what is declared in CLAUDE.md. I report specific discrepancies with declared version vs real version.

---

### Dimension 2 — Memory (ai-context/)

**Objective**: Verify that the memory layer exists, has substantial content, and is coherent with the real code.

**Existence checks:**

| File | Minimum acceptable lines |
|---------|--------------------------|
| `ai-context/stack.md` | > 30 lines |
| `ai-context/architecture.md` | > 40 lines |
| `ai-context/conventions.md` | > 30 lines |
| `ai-context/known-issues.md` | > 10 lines (can be brief if the project is new) |
| `ai-context/changelog-ai.md` | > 5 lines (at least one entry) |

**Content checks** (for each file that exists):

- **stack.md**: Does it mention the same versions as package.json? I look for the top-5 project dependencies and verify they are documented.
- **architecture.md**: Does it mention directories that actually exist in the project? I read the folder tree and cross-check.
- **conventions.md**: Do the documented conventions mention patterns used in the real code? I take 2-3 sample files and verify.
- **known-issues.md**: Does it have real content or is it an empty template? I search for phrases like "[To confirm]" or "[Empty]".
- **changelog-ai.md**: Does it have at least one entry with a date? I verify the format `## YYYY-MM-DD`.

**Note on location**: The path can be `ai-context/` (without docs/) or `docs/ai-context/`. I check both.

---

### Dimension 3 — SDD Orchestrator

**Objective**: Verify that the SDD cycle is fully operational in this project.

**Sub-checks:**

#### 3a. Global SDD skills (prerequisite for everything else)
I read whether the 8 files exist in `~/.claude/skills/`:
- `sdd-explore/SKILL.md`
- `sdd-propose/SKILL.md`
- `sdd-spec/SKILL.md`
- `sdd-design/SKILL.md`
- `sdd-tasks/SKILL.md`
- `sdd-apply/SKILL.md`
- `sdd-verify/SKILL.md`
- `sdd-archive/SKILL.md`

If any is missing → ❌ CRITICAL (SDD cannot function without the phases).

#### 3b. openspec/ in the project
| Check | Severity |
|-------|-----------|
| `openspec/` exists | ❌ CRITICAL (SDD has nowhere to store artifacts) |
| `openspec/config.yaml` exists | ❌ CRITICAL (orchestrator cannot start) |
| `config.yaml` has `artifact_store.mode: openspec` | ⚠️ HIGH |
| `config.yaml` has project name and stack | ℹ️ LOW |

#### 3c. CLAUDE.md mentions SDD
| Check | Severity |
|-------|-----------|
| Contains `/sdd:new` or `/sdd:ff` | ⚠️ HIGH |
| Has section explaining the SDD flow | ℹ️ LOW |

#### 3d. Orphaned changes
I read `openspec/changes/` (if it exists). An orphaned change is a folder in `changes/` that is NOT in `changes/archive/` and whose last modification was >14 days ago.

I list:
```
Orphaned changes detected:
  - change-name: last completed phase "tasks" (X days inactive)
```

#### 3e. Active change completeness

Enumerate all directories in `openspec/changes/` excluding `archive/`.
If `openspec/changes/` does not exist: skip with "not applicable".
For each active change directory:
- Missing `proposal.md`: HIGH severity
- `proposal.md` present but missing `tasks.md`: MEDIUM severity
- Both present: PASS

#### 3f. Archive completeness

Enumerate all directories in `openspec/changes/archive/`.
If `openspec/changes/archive/` does not exist or is empty: skip.
For each archived change directory:
- Missing `verify-report.md`: MEDIUM severity
- `verify-report.md` present but contains no line matching `- [x]`: WARNING severity
- `verify-report.md` present with at least one `- [x]` line: PASS

FIX_MANIFEST schemas for D3e and D3f:
```yaml
- id: D3e-[change-name]-missing-proposal
  severity: high
  type: create_file
  target: openspec/changes/[change-name]/proposal.md
  reason: "Active SDD change missing required proposal.md"
  action: "Run /sdd-propose [change-name] to create the proposal"

- id: D3e-[change-name]-missing-tasks
  severity: medium
  type: create_file
  target: openspec/changes/[change-name]/tasks.md
  reason: "Active SDD change has proposal but missing tasks.md"
  action: "Run /sdd-tasks [change-name] to create the task breakdown"

- id: D3f-[change-name]-missing-verify-report
  severity: medium
  type: create_file
  target: openspec/changes/archive/[change-name]/verify-report.md
  reason: "Archived change missing verify-report.md"
  action: "Create verify-report.md with at least one [x] criterion confirming the change was verified"

- id: D3f-[change-name]-no-checked-criteria
  severity: warning
  type: update_file
  target: openspec/changes/archive/[change-name]/verify-report.md
  reason: "verify-report.md exists but has no checked [x] criteria"
  action: "Add at least one - [x] criterion to the verify-report.md"
```

---

### Dimension 4 — Skills Quality

**Objective**: Verify that skills are substantial and that the registry in CLAUDE.md is accurate.

**Checks:**

#### 4a. Registry vs disk (bidirectional)
- For each skill listed in CLAUDE.md → I verify that the file/directory exists in `.claude/skills/`
- For each file in `.claude/skills/` → I verify that it is listed in CLAUDE.md
- I report: skills in registry but not on disk / skills on disk but not in registry

#### 4b. Minimum content
For each skill file (`.md` or directory with `SKILL.md`):
- Does it have more than 30 lines? → If not, it is probably a stub
- Does it have some process/instructions section? → If not, it is not functional

#### 4c. Relevant global tech skills not installed
I read the project stack (package.json) and check whether relevant technology skills exist in `~/.claude/skills/` that are not in the project:

| If project uses | Available global skill |
|-----------------|------------------------|
| React 18+ | `react-19/SKILL.md` |
| Next.js 14+ | `nextjs-15/SKILL.md` |
| TypeScript | `typescript/SKILL.md` |
| Zustand | `zustand-5/SKILL.md` |
| Tailwind | `tailwind-4/SKILL.md` |
| Zod | `zod-4/SKILL.md` |
| Playwright | `playwright/SKILL.md` |

#### 4d. Structural section completeness by skill type

Claude Code requires SKILL.md files to have specific sections depending on their type.
Classify each skill by directory name:
- **SDD-phase skills** (`sdd-*`): must contain `## Rules` section — missing = HIGH finding
- **Meta-tool skills** (`project-*`, `skill-creator`, `memory-manager`): must contain `## Rules` or equivalent constraints section — missing = HIGH finding
- **Tech/tool skills** (all others): must contain trigger line AND either YAML frontmatter (`---`) OR `## Rules` section — missing both = MEDIUM finding; trigger line alone = PASS

Report all violations in the D4 report table.

FIX_MANIFEST schemas for D4d:
```yaml
- id: D4d-[skill-name]-missing-rules
  severity: high
  type: update_file
  target: skills/[skill-name]/SKILL.md
  reason: "SDD/meta-tool skill missing required ## Rules section"
  action: "Add ## Rules section with constraints specific to this skill type"

- id: D4d-[skill-name]-no-format
  severity: medium
  type: update_file
  target: skills/[skill-name]/SKILL.md
  reason: "Tech skill missing both YAML frontmatter and ## Rules section"
  action: "Add either YAML frontmatter or ## Rules section"
```

#### 4e. Language compliance check

Unbreakable Rule #1 requires ALL content to be in English.
For each SKILL.md file:
1. Strip code blocks (triple-backtick fences) from the content
2. Scan remaining prose for Spanish accented characters: á é í ó ú ñ ü Á É Í Ó Ú Ñ Ü
3. If found: report as WARNING (non-blocking, does NOT deduct from score)
4. Report up to 5 example occurrences per skill in the violations table
5. No skill type is exempt from this check

FIX_MANIFEST schema for D4e:
```yaml
- id: D4e-[skill-name]-language
  severity: warning
  type: update_file
  target: skills/[skill-name]/SKILL.md
  reason: "Skill contains non-English (Spanish) prose content — violates Unbreakable Rule #1"
  action: "Translate prose headings and narrative text to English; code comments may remain"
```

#### 4f. Skill directory naming (kebab-case)

Scan all entries in `skills/`. For each directory:
- Name must match regex `^[a-z][a-z0-9-]*$` (lowercase, hyphens only, no underscores or uppercase)
- Violation: MEDIUM severity

#### 4g. Skill directory contents

For each skill directory in `skills/`:
- List all files present
- Any file that is NOT `SKILL.md` is a finding:
  - `.js`, `.yaml`, `.json`, `.sh` extra files: INFO (no score deduction, no FIX_MANIFEST entry)
  - Extra `.md` files: WARNING severity

#### 4h. No orphaned files in skills/ root

Check for any FILES (not directories) directly under `skills/` root.
- Any file found directly in `skills/` (not inside a subdirectory): WARNING severity

FIX_MANIFEST schemas for D4f, D4g, D4h:
```yaml
- id: D4f-[skill-name]-naming
  severity: medium
  type: rename_dir
  target: skills/[skill-name]
  reason: "Skill directory name does not follow kebab-case convention"
  action: "Rename directory to kebab-case equivalent"

- id: D4g-[skill-name]-extra-md-[filename]
  severity: warning
  type: update_file
  target: skills/[skill-name]/[filename]
  reason: "Unexpected .md file in skill directory (only SKILL.md is allowed)"
  action: "Remove or integrate into SKILL.md; delete if not needed"

- id: D4h-orphaned-[filename]
  severity: warning
  type: update_file
  target: skills/[filename]
  reason: "Orphaned file found directly in skills/ root"
  action: "Move into appropriate skill directory or delete"
```

---

### Dimension 5 — Commands Quality

**Objective**: Verify that commands are functional and the registry is accurate.

**Checks:**

#### 5a. Registry vs disk (bidirectional)
- For each command listed in CLAUDE.md → I verify that the file exists in `.claude/commands/`
- For each file in `.claude/commands/` → I verify that it is listed in CLAUDE.md
- I report discrepancies in both directions

#### 5b. Minimum content
For each command file:
- Does it have more than 20 lines?
- Does it have a steps or defined process section? (I search for "##", "Step", numbered list)
- If it is a stub without a defined process → mark it as ⚠️ NOT FUNCTIONAL

---

### Dimension 6 — Cross-reference Integrity

**Objective**: Everything referenced in the Claude configuration must exist on disk.

**Checks:**

| What I verify | Where I search for references |
|-------------|------------------------|
| Docs referenced in CLAUDE.md | Section `## Documentation` → `.claude/docs/` |
| Templates referenced in CLAUDE.md | Templates section → `.claude/templates/` |
| Paths mentioned in skills | Scan of skills searching for paths (`/lib/`, `/domain/`, `pages/api/`) |
| Paths mentioned in ai-context/ | Verify that dirs documented in architecture.md exist |
| Skill files mentioned in commands | If a command imports or references a skill |

For each broken reference: I report the source file, approximate line, and the path that does not exist.

#### D6d. Legacy path pattern: docs/ai-context references

Scan ALL files in `skills/` for the literal string `docs/ai-context`.
The canonical path is `ai-context/` (no `docs/` prefix).
For each occurrence found:
- In `sdd-*` or meta-tool skills (`project-*`, `skill-creator`, `memory-manager`): HIGH severity
- In tech/tool skills: MEDIUM severity
Report the file path and occurrence count.

FIX_MANIFEST schema for D6d:
```yaml
- id: D6d-[skill-name]-path-docs-ai-context
  severity: high  # or medium for tech skills
  type: update_file
  target: skills/[skill-name]/SKILL.md
  reason: "Skill references legacy 'docs/ai-context' path — canonical path is 'ai-context/'"
  action: "Replace all occurrences of 'docs/ai-context' with 'ai-context' throughout the file"
```

---

### Dimension 8 — Testing & Verification Integrity

**Objective**: Verify that the project requires and evidences real tests before archiving SDD changes.

**Checks:**

#### 8a. openspec/config.yaml has testing section
| Check | Severity |
|-------|-----------|
| `config.yaml` has `testing:` block | ⚠️ HIGH |
| Defines `minimum_score_to_archive` | ⚠️ HIGH |
| Defines `required_artifacts_per_change` | ⚠️ MEDIUM |
| Defines `verify_report_requirements` | ⚠️ MEDIUM |
| Has `test_project` or documented testing strategy | ℹ️ LOW |

#### 8b. Archived changes have verify-report.md
For each folder in `openspec/changes/archive/`:
- Does `verify-report.md` exist? If not → ⚠️ HIGH
- Does it have at least one `[x]` item in its checklist? If not → ⚠️ HIGH
- Does it mention what project/context was used to verify? If not → ℹ️ LOW

I report:
```
Archived changes without verify-report.md: [list]
Changes with empty verify-report.md or without [x]: [list]
```

#### 8c. Active changes have verification criteria defined
For each active folder in `openspec/changes/` (not archived):
- If it has `tasks.md` → does it include a verification criteria section?
- If it has `design.md` → does it define how the change will be tested?

#### 8d. Verify rules in config.yaml are executable
I read the `rules.verify` block of `openspec/config.yaml` and evaluate:
- Are they objectively verifiable or empty phrases like "make sure it works"?
- Does at least one rule mention `/project-audit` or a concrete metric?

---

### Dimension 7 — Architecture Compliance (sampling)

**Objective**: Verify with real samples that the code follows the documented architecture.

**Methodology**: I do not analyze all the code. I take representative samples.

**Sample checks:**

#### 7a. API routes (I review 3 at random)
- Do they use the observability wrapper (`withSegmentAPI` or equivalent)?
- Do they contain business logic directly? (signal: direct ORM/DB imports)
- Do they have more than 50 lines of logic? (possible "thin handler" violation)

#### 7b. Domain services (I review 3 at random)
- Do they import the ORM from the correct path (`lib/prisma` or equivalent)?
- Do the functions follow the documented naming convention (`*Fn`, `*Service`, etc.)?

#### 7c. Components (I review 2 at random)
- Do they import services directly instead of using hooks?
- Do they have inline business logic?

#### 7d. Critical violations (I search the entire codebase)
```
I search for signs of serious violations:
- new PrismaClient() outside lib/
- import { PrismaClient } outside lib/
- font-weight (if the project has SCSS and the convention prohibits it)
- console.log in production files (not in tests)
```

For each violation: I report file, line, and the violated rule.

---

## Report Format

The report is saved in `.claude/audit-report.md` with this exact structure:

```markdown
# Audit Report — [Project Name]
Generated: [YYYY-MM-DD HH:MM]
Score: [XX/100]
SDD Ready: [YES|NO|PARTIAL]

---

## FIX_MANIFEST
<!-- This block is consumed by /project-fix — DO NOT modify manually -->
```yaml
score: [XX]
sdd_ready: [true|false|partial]
generated_at: "[timestamp]"
project_root: "[absolute path]"

required_actions:
  critical:
    - id: "[unique-id]"
      type: "[create_file|update_file|create_dir|add_registry_entry|install_skill]"
      target: "[path or element]"
      reason: "[why it is necessary]"
      template: "[template_name if applicable]"
  high:
    - id: "[unique-id]"
      type: "..."
      target: "..."
      reason: "..."
  medium:
    - ...
  low:
    - ...

missing_global_skills:
  - "[skill-name]"

orphaned_changes:
  - name: "[name]"
    last_phase: "[phase]"
    days_inactive: [N]

violations:
  - file: "[path]"
    line: [N]
    rule: "[violated rule]"
    severity: "[critical|high|medium]"
```​
---

## Executive Summary
[3-5 lines describing the general state of the project from the Claude/SDD perspective]

---

## Score: [XX]/100

| Dimension | Points | Max | Status |
|-----------|--------|-----|--------|
| CLAUDE.md complete and accurate | [X] | 20 | ✅/⚠️/❌ |
| Memory initialized | [X] | 15 | ✅/⚠️/❌ |
| Memory with substantial content | [X] | 10 | ✅/⚠️/❌ |
| SDD Orchestrator operational | [X] | 20 | ✅/⚠️/❌ |
| Skills registry complete and functional | [X] | 10 | ✅/⚠️/❌ |
| Commands registry complete and functional | [X] | 10 | ✅/⚠️/❌ |
| Cross-references valid | [X] | 5 | ✅/⚠️/❌ |
| Architecture compliance | [X] | 5 | ✅/⚠️/❌ |
| Testing & Verification integrity | [X] | 5 | ✅/⚠️/❌ |
| **TOTAL** | **[X]** | **100** | |

**SDD Readiness**: [FULL / PARTIAL / NOT CONFIGURED]
- FULL: openspec/ exists, config.yaml valid, CLAUDE.md mentions /sdd:*, global skills present
- PARTIAL: Some SDD elements present but incomplete
- NOT CONFIGURED: openspec/ does not exist

---

## Dimension 1 — CLAUDE.md [OK|WARNING|CRITICAL]

| Check | Status | Detail |
|-------|--------|---------|
| Exists `.claude/CLAUDE.md` (or root `CLAUDE.md` for global-config repos) | ✅/❌ | |
| Has >50 lines | ✅/❌ | [X] lines |
| Stack documented | ✅/⚠️/❌ | |
| Stack vs package.json | ✅/⚠️/❌ | [specific discrepancies] |
| Has Architecture section | ✅/⚠️/❌ | |
| Skills registry present | ✅/⚠️/❌ | |
| Commands registry present | ✅/⚠️/❌ | |
| Mentions SDD (/sdd:*) | ✅/⚠️/❌ | |

**Stack Discrepancies:**
[List each discrepancy: "Declares React 18, actual ^19.0.0"]

---

## Dimension 2 — Memory [OK|WARNING|CRITICAL]

| File | Exists | Lines | Content | Coherence |
|---------|--------|--------|-----------|------------|
| stack.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| architecture.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| conventions.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| known-issues.md | ✅/❌ | [N] | ✅/⚠️/❌ | ✅/⚠️/❌ |
| changelog-ai.md | ✅/❌ | [N] | ✅/⚠️/❌ | N/A |

**Coherence issues detected:**
[List specific issues with file + what is outdated]

---

## Dimension 3 — SDD Orchestrator [OK|WARNING|CRITICAL]

**Global SDD Skills:**
| Skill | Exists |
|-------|--------|
| sdd-explore | ✅/❌ |
| sdd-propose | ✅/❌ |
| sdd-spec | ✅/❌ |
| sdd-design | ✅/❌ |
| sdd-tasks | ✅/❌ |
| sdd-apply | ✅/❌ |
| sdd-verify | ✅/❌ |
| sdd-archive | ✅/❌ |

**openspec/ in project:**
| Check | Status |
|-------|--------|
| `openspec/` exists | ✅/❌ |
| `openspec/config.yaml` exists | ✅/❌ |
| Config valid | ✅/⚠️/❌ |

**CLAUDE.md mentions SDD:** ✅/❌

**Orphaned changes:** [none | list]

**Active change completeness (3e):**
| Change | proposal.md | tasks.md | Status |
|--------|-------------|----------|--------|
| [name] | ✅/❌ | ✅/❌ | PASS/HIGH/MEDIUM |
[list or "not applicable"]

**Archive completeness (3f):**
| Archived change | verify-report.md | Has [x] | Status |
|----------------|------------------|---------|--------|
| [name] | ✅/❌ | ✅/❌ | PASS/MEDIUM/WARNING |
[list or "not applicable"]

---

## Dimension 4 — Skills [OK|WARNING|CRITICAL]

**Skills in registry but not on disk:**
[list or "none"]

**Skills on disk but not in registry:**
[list or "none"]

**Skills with insufficient content (<30 lines):**
[list or "none"]

**Recommended global tech skills not installed:**
[list with install command: /skill:add name]

**Structural section completeness (4d):**
| Skill | Type | Has ## Rules | Status |
|-------|------|-------------|--------|
| [skill-name] | sdd-phase/meta-tool/tech | ✅/❌ | PASS/HIGH/MEDIUM |
[list or "all pass"]

**Language compliance (4e):**
| Skill | Spanish chars found | Examples | Status |
|-------|--------------------|---------|----|
| [skill-name] | [N] | [up to 5 examples] | WARNING/PASS |
[list or "all pass"]

**Skill directory naming (4f):**
| Directory | Valid kebab-case | Status |
|-----------|-----------------|--------|
| [skill-name] | ✅/❌ | PASS/MEDIUM |
[list or "all pass"]

**Skill directory contents (4g):**
| Skill | Extra files | Status |
|-------|-------------|--------|
| [skill-name] | [filename] | INFO/WARNING/PASS |
[list or "all clean"]

**Orphaned files in skills/ root (4h):**
[list or "none"]

---

## Dimension 5 — Commands [OK|WARNING|CRITICAL]

**Commands in registry but not on disk:**
[list or "none"]

**Commands on disk but not in registry:**
[list or "none"]

**Commands without defined process (stubs):**
[list or "none"]

---

## Dimension 6 — Cross-references [OK|WARNING|CRITICAL]

**Broken references:**
| Source file | Reference | Problem |
|----------------|-----------|---------|
[list or "none"]

**Legacy docs/ai-context path references (D6d):**
| Skill file | Occurrences | Severity |
|------------|-------------|----------|
| [skill-name]/SKILL.md | [N] | HIGH/MEDIUM |
[list or "none"]

---

## Dimension 7 — Architecture Compliance [OK|WARNING|CRITICAL]

**Sample files analyzed:** [list]

**Violations found:**
| File | Line | Violated rule | Severity |
|---------|-------|--------------|-----------|
[list or "none"]

---

## Dimension 8 — Testing & Verification [OK|WARNING|CRITICAL]

**openspec/config.yaml has testing block:** ✅/❌

**Archived changes without verify-report.md:**
[list or "none"]

**Archived changes with empty verify-report.md (without [x]):**
[list or "none"]

**Verify rules are executable:** ✅/⚠️/❌

---

## Required Actions

### Critical (block SDD):
1. [concrete action] → run `/project-fix` or manually: [instruction]

### High (degrade quality):
1. [concrete action]

### Medium:
1. [concrete action]

### Low (optional improvements):
1. [concrete action]

---

*To implement these corrections: run `/project-fix`*
*This report was generated by `/project-audit` — do not modify the FIX_MANIFEST block manually*
```

---

## Detailed Scoring

| Dimension | Criterion | Max points |
|-----------|---------|------------|
| **CLAUDE.md** | Exists + complete structure + accurate stack + SDD refs | 20 |
| **Memory — existence** | All 5 files exist | 15 |
| **Memory — quality** | Substantial content + coherent with code | 10 |
| **SDD Orchestrator** | Global skills + openspec/ + config.yaml + CLAUDE.md refs | 20 |
| **Skills** | Exact registry + minimum content + no missing global skills | 10 |
| **Commands** | Exact registry + functional commands | 10 |
| **Cross-references** | No broken references | 5 |
| **Architecture** | No critical violations in samples | 5 |
| **Testing & Verification** | config.yaml has testing block + archived changes have verify-report.md | 5 |

**Interpretation:**
- 90-100: SDD fully operational, excellent maintenance
- 75-89: Ready to use SDD, minor improvements pending
- 50-74: SDD partially configured, needs `/project-fix`
- <50: Requires complete setup

---

## Execution Rules

1. **I always read real files** — I never assume the content of a file
2. **I run in a subagent** with read tools — never in main context
3. **I always save the report** in `.claude/audit-report.md` before presenting to the user
4. **The FIX_MANIFEST is valid YAML** — I verify that the block is parseable
5. **I never modify anything** — this skill is 100% read-only
6. **If I cannot read a file**, I report it as ❌ with the exact error, I do not assume it does not exist
7. **When finished**, I notify the user: "Report saved in `.claude/audit-report.md`. To implement the corrections: `/project-fix`"
