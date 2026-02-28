---
name: project-audit
description: >
  Deep diagnostic of Claude/SDD configuration. Read-only. Produces audit-report.md consumed by /project-fix.
  Trigger: /project-audit, audit project, review claude config, project health check.
---

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

## Audit Process — 10 Dimensions

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

**Additional sub-checks — User documentation freshness:**

For each of the following files, apply identical logic:
- `ai-context/scenarios.md`
- `ai-context/quick-reference.md`

Logic per file:
1. If the file does NOT exist → emit LOW finding: `"[filename] missing — create via /project-onboard or manually following the template in ai-context/"`
2. If the file exists → read first 10 lines and search for `^> Last verified: (\d{4}-\d{2}-\d{2})$`
   - Field absent or malformed → emit LOW: `"Last verified field not found or malformed in [filename]"`
   - Field present and date ≤ 90 days from today → no finding
   - Field present and date > 90 days from today → emit LOW: `"[filename] stale ([N] days since last verification) — run /project-update to refresh"`

**Severity note**: All findings for these sub-checks are LOW (informational). They do NOT deduct from the D2 numeric score.

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

#### 4c. Relevant global tech skills coverage (scored: 0–10 pts)
I read the project stack (package.json) and identify which global technology skills in `~/.claude/skills/` are applicable but not yet installed in the project:

| If project uses | Available global skill |
|-----------------|------------------------|
| React 18+ | `react-19/SKILL.md` |
| Next.js 14+ | `nextjs-15/SKILL.md` |
| TypeScript | `typescript/SKILL.md` |
| Zustand | `zustand-5/SKILL.md` |
| Tailwind | `tailwind-4/SKILL.md` |
| Zod | `zod-4/SKILL.md` |
| Playwright | `playwright/SKILL.md` |

**Scoring rubric:**

| Coverage | Points |
|----------|--------|
| No relevant global skills detected in stack, OR all applicable ones already added | 10 |
| ≥ 75% of applicable global skills installed | 8 |
| 50–74% installed | 5 |
| 25–49% installed | 2 |
| < 25% installed (relevant skills exist but none added) | 0 |

"Applicable" means: the project stack uses the technology AND a matching global skill exists in `~/.claude/skills/`. Projects with no matching global skills get full credit automatically.

**D4 maximum: 20 points** (4a+4b registry and content = 10 pts; 4c global skills coverage = 10 pts)

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

### Dimension 7 — Architecture Compliance

**Objective**: Verify whether the project's architecture matches its documented baseline by reading the output of `/project-analyze`.

**Input**: `analysis-report.md` at the project root (produced by the `project-analyze` skill).

**Scoring table:**

| Condition | Score | Severity | Message |
|-----------|-------|----------|---------|
| `analysis-report.md` absent | 0/5 | CRITICAL | "Run /project-analyze first, then re-run /project-audit." |
| Present + `ai-context/architecture.md` absent | 2/5 | HIGH | "No architecture baseline to compare against." |
| Drift summary = `none` | 5/5 | OK | |
| Drift summary = `minor` | 3/5 | MEDIUM | List drift entries from `analysis-report.md` |
| Drift summary = `significant` | 0/5 | HIGH | List drift entries from `analysis-report.md` |

**Staleness check** (no score deduction):
- Read the `Last analyzed:` date from `analysis-report.md`
- If the date is more than 7 days before the current audit date → emit a warning: "analysis-report.md is [N] days old — consider re-running /project-analyze for up-to-date results."
- The score is still computed from the existing report regardless of staleness.

**Drift entries**: When drift summary is `minor` or `significant`, read the `## Architecture Drift` section of `analysis-report.md` and list each entry in the D7 output block.

**FIX_MANIFEST rule**: D7 violations go in `violations[]` only — NOT in `required_actions`. The `/project-fix` skill does not auto-fix architecture drift.

---

### Dimension 9 — Project Skills Quality

**Objective**: Audit the project's local skills directory against quality criteria and the global skill catalog.

**D9-1. Skip condition**

Read `$LOCAL_SKILLS_DIR` from the Phase A output. Check whether `$LOCAL_SKILLS_DIR` exists in the target project.

If it does NOT exist:
```
No [value of $LOCAL_SKILLS_DIR] directory found — Dimension 9 skipped.
```
No score deduction. Do not add `skill_quality_actions` to FIX_MANIFEST.

If it exists, proceed with D9-2 through D9-5 for each subdirectory found.

**Note — global-config circular detection**: When auditing the global-config repo itself, `$LOCAL_SKILLS_DIR` resolves to `"skills"` (root level). In this case every subdirectory under `skills/` will have a matching counterpart in `~/.claude/skills/` because they are the same files deployed by `install.sh`. D9-2 duplicate detection will assign disposition `keep` for all of them — this is correct and expected behavior (they are the source of truth, not duplicates).

**D9-2. Duplicate detection**

For each subdirectory `<name>` under `.claude/skills/`:
- Check whether `~/.claude/skills/<name>/` exists (exact directory name match)
- If it exists → candidate disposition: `move-to-global` (if local differs from global) or `delete` (if identical)
- If the global catalog is unreadable → emit `Global catalog unreadable — duplicate check skipped` at INFO level; assign disposition `keep`

**D9-3. Structural completeness**

Read each local `.claude/skills/<name>/SKILL.md`. Search for:
- `**Triggers**` or `## Triggers` — trigger definition
- `## Process` or `### Step` — process section
- `## Rules` or `## Execution rules` — rules section

If any section is absent:
- Record missing sections per skill
- Assign disposition: `update`
- Action: `add_missing_section`

If no `SKILL.md` exists in the directory:
- Record as `SKILL.md missing`
- Assign disposition: `update`
- Action: `add_missing_section`

**D9-4. Language compliance**

Apply the D4e language-compliance heuristic (defined in Dimension 4) to the body text of each local `SKILL.md` outside fenced code blocks.

If non-English prose is found:
- Disposition: `update`
- Action: `flag_language_violation`
- Severity: INFO only — no score deduction

**D9-5. Stack relevance**

Extract technology references from the trigger line and title of each local `SKILL.md`.

If a technology name is absent from BOTH `ai-context/stack.md` AND `package.json`/`pyproject.toml`:
- Disposition: `update`
- Action: `flag_irrelevant`
- Severity: INFO only

If neither stack source (`stack.md` nor `package.json`/`pyproject.toml`) is found:
```
Stack relevance check skipped — no stack source found
```

---

### Dimension 10 — Feature Docs Coverage

**Objective**: Detect feature/skill documentation gaps across the project using either config-driven or heuristic discovery, and report coverage per feature. Informational only — no score impact.

**Skip condition**: If no features are detected (neither config-driven nor heuristic) → emit INFO: 'No feature directories detected — Dimension 10 skipped.' No score impact.

**Phase A discovery extension**: This dimension reads the `FEATURE_DOCS_CONFIG_EXISTS` variable produced by the Phase A bash script (see Rule 8). If `FEATURE_DOCS_CONFIG_EXISTS=1`, use config-driven detection. If `0`, fall back to heuristic detection.

#### Config-driven detection

If `openspec/config.yaml` contains a `feature_docs:` key:
- Read the `convention` field (`skill` | `markdown` | `mixed`)
- Read the `paths` list (directories to scan for feature docs)
- Read the `feature_detection` block: `strategy` (`directory` | `prefix` | `explicit`), `root` (root directory whose subdirs are treated as features), and `exclude` list

Use this configuration as the source of truth for feature names and doc locations.

#### Heuristic detection fallback

If no `feature_docs:` key is present in `openspec/config.yaml`, run the following heuristic algorithm:

```
heuristic_sources = []

# Source 1: non-SDD skills in $LOCAL_SKILLS_DIR
if $LOCAL_SKILLS_DIR exists:
    for each subdirectory name in $LOCAL_SKILLS_DIR:
        if name does NOT start with: sdd-, project-, memory-, skill-:
            add to heuristic_sources as type=skill

# Source 2: markdown files in docs/features/ or docs/modules/
if docs/features/ exists:
    add each *.md file as type=markdown, feature_name = filename without extension
if docs/modules/ exists:
    add each *.md file as type=markdown, feature_name = filename without extension

# Source 3: subdirs of src/features/, src/modules/, app/ with README.md
for each candidate_root in [src/features/, src/modules/, app/]:
    if candidate_root exists:
        for each subdirectory:
            if subdirectory/README.md exists:
                add as type=markdown, feature_name = subdirectory name

# Exclusion list — always skip these directory/feature names:
EXCLUDE = [shared, utils, common, lib, types, hooks, components]

if heuristic_sources is empty (after exclusions):
    emit INFO: "No feature directories detected — Dimension 10 skipped."
    skip all four checks
```

#### D10 checks (run per detected feature)

**D10-a Coverage**: Verify that each detected feature has a corresponding documentation file.
- If `convention=skill`: PASS (✅) if `$LOCAL_SKILLS_DIR/<feature_name>/SKILL.md` exists; FAIL (⚠️) otherwise
- If `convention=markdown`: PASS (✅) if at least one `.md` file in the configured paths references `feature_name`; FAIL (⚠️) otherwise
- If `convention=mixed`: PASS (✅) if either a skill or a markdown doc is found; FAIL (⚠️) otherwise

**D10-b Structural Quality**: Verify that the found documentation has proper structure.
- If doc is a `SKILL.md`: PASS (✅) if frontmatter (`---` block) present AND `**Triggers**`/`## Triggers` defined AND `## Process`/`### Step` section AND `## Rules`/`## Execution rules` section; WARN (⚠️) if any of the above is missing
- If doc is a `.md` file (not SKILL.md): PASS (✅) if has `# title` (H1) AND at least one `## section` (H2); WARN (⚠️) if missing either; N/A if doc not found

**D10-c Code Freshness**: Scan the doc file for file path references and verify they still exist on disk.
- Read the doc file content
- Extract all path-like strings matching: `/src/[^\s]+`, `/lib/[^\s]+`, `/app/[^\s]+`
- For each extracted path: check if `[project_root][path]` exists on disk; if NOT found → flag as stale (⚠️)
- PASS (✅) if no stale paths found or no paths found in doc; N/A if doc not found

**D10-d Registry Alignment**: If doc is a SKILL.md in `.claude/skills/` → verify it appears in the CLAUDE.md Skills Registry section.
- Read CLAUDE.md (or `.claude/CLAUDE.md`)
- Check if `feature_name` appears in the Skills Registry section
- PASS (✅) if found; INFO (ℹ️) if not found (not a warning — projects may have features without skill entries by design); N/A if doc is not a SKILL.md

#### Output format

Emit a per-feature coverage table:

| Feature | Doc found | Structure OK | Fresh | In Registry | Status |
|---------|-----------|--------------|-------|-------------|--------|
| [name]  | ✅/❌     | ✅/⚠️/N/A  | ✅/⚠️/N/A | ✅/ℹ️/N/A | ✅/⚠️/❌ |

**Status column logic**: ✅ if all applicable checks pass; ⚠️ if any check warns; ❌ if D10-a (coverage) fails.

**FIX_MANIFEST rule**: D10 findings MUST NOT appear in `required_actions` or `skill_quality_actions` in the FIX_MANIFEST. /project-fix does not act on D10 findings.

---

### Dimension 11 — Internal Coherence

**Objective**: Validate that individual skill files and CLAUDE.md are internally self-consistent — numeric claims in headings match actual section counts, numbered sequences have no gaps or duplicates, and frontmatter descriptions agree with the body. Informational only — no score impact.

**Skip condition**: If `$LOCAL_SKILLS_DIR` does not exist as a directory AND no root `CLAUDE.md` exists → emit INFO: `'No auditable files found — Dimension 11 skipped.'` No score impact.

**Scope**: All `SKILL.md` files under `$LOCAL_SKILLS_DIR` (emitted by the Phase A script) plus the root `CLAUDE.md` (if it exists).

**Tool constraint**: D11 uses only Read, Glob, and Grep tools for file analysis. No Bash calls.

#### D11-a Count Consistency

Extract numeric claims from headings (lines starting with `#`) and blockquote lines (lines starting with `>`) using the pattern:

```
CLAIM_PATTERN = /(\d+)\s+(Dimensions?|Steps?|Rules?|Phases?|Checks?|Sub-checks?)/i
```

For each claim found:
- Identify the keyword (e.g., "Dimensions", "Steps")
- Count matching sections in the body: heading lines containing the same keyword (case-insensitive)
- If declared count ≠ actual count → finding with severity INFO

Do NOT match numeric references inside code blocks, examples, or body prose — only headings and blockquote lines.

#### D11-b Section Numbering Continuity

Match numbered section patterns in H2/H3/H4 headings:

```
SEQUENCE_PATTERNS:
  - /^#{2,3}\s+.*Step\s+(\d+)/im     → Step sequences
  - /^#{2,3}\s+.*Dimension\s+(\d+)/im → Dimension sequences
  - /^#{2,3}\s+.*Phase\s+(\d+)/im     → Phase sequences
  - /^#{2,4}\s+.*D(\d+)/m             → D-prefixed sequences (D1, D2, ...)
```

For each pattern:
- Collect all matched numbers, sort ascending
- **Gap**: a number N is missing where min..max is not contiguous
- **Duplicate**: a number appears more than once
- Report only if the sequence has ≥ 2 members (single item = no sequence to validate)
- Finding severity: INFO

#### D11-c Frontmatter-Body Alignment

- Parse YAML frontmatter (between first pair of `---` markers)
- Extract the `description` field
- If `description` contains a numeric claim (reuse `CLAIM_PATTERN`) → verify that claim against the body using the same logic as D11-a
- If mismatch → finding with severity INFO
- If no frontmatter or no `description` field → skip this check for that file

**FIX_MANIFEST rule**: D11 findings go in `violations[]` only with severity `info`. Rule names: `D11-count-consistency`, `D11-numbering-continuity`, `D11-frontmatter-body`. D11 findings MUST NOT appear in `required_actions` or `skill_quality_actions`. /project-fix does not act on D11 findings.

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

skill_quality_actions:
  - id: "D9-<skill-name>-<action-type>"
    skill_name: "<name>"
    local_path: ".claude/skills/<name>/SKILL.md"
    global_counterpart: "~/.claude/skills/<name>/SKILL.md"  # only for duplicates
    action_type: "delete_duplicate|add_missing_section|flag_irrelevant|flag_language"
    disposition: "delete|move-to-global|update|keep"
    missing_sections: ["## Rules", "## Process"]  # only for add_missing_section
    detail: "<human-readable reason>"
    severity: "info|warning"
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
| Skills registry complete and functional | [X] | 20 | ✅/⚠️/❌ |
| Cross-references valid | [X] | 5 | ✅/⚠️/❌ |
| Architecture compliance | [X] | 5 | ✅/⚠️/❌ |
| Testing & Verification integrity | [X] | 5 | ✅/⚠️/❌ |
| Project Skills Quality | N/A | N/A | ✅/ℹ️/— |
| Feature Docs Coverage | N/A | N/A | ✅/ℹ️/— |
| Internal Coherence | N/A | N/A | ✅/ℹ️/— |
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

---

## Dimension 6 — Cross-references [OK|WARNING|CRITICAL]

**Broken references:**
| Source file | Reference | Problem |
|----------------|-----------|---------|
[list or "none"]

---

## Dimension 7 — Architecture Compliance [OK|WARNING|CRITICAL]
Analysis report found: YES/NO
Last analyzed: [date or N/A]
Architecture drift status: [none|minor|significant|N/A]

Drift entries: (when drift is present)
| File/Pattern | Expected | Found |
|---|---|---|
| [entry] | [expected] | [found] |

---

## Dimension 8 — Testing & Verification [OK|WARNING|CRITICAL]

**openspec/config.yaml has testing block:** ✅/❌

**Archived changes without verify-report.md:**
[list or "none"]

**Archived changes with empty verify-report.md (without [x]):**
[list or "none"]

**Verify rules are executable:** ✅/⚠️/❌

---

## Dimension 9 — Project Skills Quality [OK|INFO|SKIPPED]

**Local skills directory**: [value of $LOCAL_SKILLS_DIR] — [N skills found | not found — skipped]

| Skill | Duplicate of global | Structural complete | Language OK | Stack relevant | Disposition |
|-------|--------------------|--------------------|-------------|----------------|-------------|
| [skill-name] | ⚠️ YES / ❌ NO | ✅ / ⚠️ (missing: list) | ✅ / ℹ️ violation | ✅ / ℹ️ flag / ℹ️ UNKNOWN | keep/update/delete/move-to-global |

**Skills with missing structural sections:**
[list or "none"]

**Language violations (INFO — manual fix required):**
[list or "none"]

**Stack relevance issues (INFO):**
[list or "none"]

*Note: Dimension 9 does not affect the score in this iteration. Findings are informational unless action_type is `delete_duplicate`.*

---

## Dimension 10 — Feature Docs Coverage [OK|INFO|SKIPPED]

**Detection mode**: configured | heuristic | skipped
**Features detected**: [N] ([list of names])

| Feature | Doc found | Structure OK | Fresh | In Registry | Status |
|---------|-----------|--------------|-------|-------------|--------|
| [name]  | ✅/❌     | ✅/⚠️/N/A  | ✅/⚠️/N/A | ✅/ℹ️/N/A | ✅/⚠️/❌ |

*D10 findings are informational only — they do not affect the score and are not auto-fixed by /project-fix.*

---

## Dimension 11 — Internal Coherence [OK|INFO|SKIPPED]

**Skills scanned**: [N] from $LOCAL_SKILLS_DIR

| Skill | Count OK | Numbering OK | Frontmatter OK | Findings |
|-------|----------|-------------|----------------|----------|
| [skill-name] | ✅/⚠️ | ✅/⚠️ | ✅/⚠️/N/A | [detail or "clean"] |

**Inconsistencies found**: [N] across [M] skills (or "None — all skills internally coherent")

*D11 findings are informational only — they do not affect the score and are not auto-fixed by /project-fix.*

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
| **Skills** | Registry accuracy + content depth = 10 pts; global tech skills coverage (D4c) = 10 pts | 20 |
| **Cross-references** | No broken references | 5 |
| **Architecture** | No critical violations in samples | 5 |
| **Testing & Verification** | config.yaml has testing block + archived changes have verify-report.md | 5 |
| **Project Skills Quality** | Informational only — no score deduction in iteration 1. Flags duplicates, structural gaps, language violations, stack relevance issues. | N/A |
| **Feature Docs Coverage** | Informational only — no score deduction. Detects feature/skill documentation gaps. | N/A |
| **Internal Coherence** | Informational only — no score deduction. Validates count claims, section numbering, and frontmatter consistency within individual skill files. | N/A |

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
8. **All shell-based discovery MUST be consolidated into a single Bash script call (Phase A). Maximum 3 Bash calls per audit run. Never issue individual `ls`, `grep`, `wc -l`, or `find` calls per dimension.**

   Use the following reference script template for Phase A discovery:

   ```sh
   #!/usr/bin/env bash
   # project-audit discovery — Phase A
   # Usage: bash <(echo "$SCRIPT") [project_root]
   PROJECT="${1:-.}"
   f() { [ -f "$PROJECT/$1" ] && echo 1 || echo 0; }
   d() { [ -d "$PROJECT/$1" ] && echo 1 || echo 0; }
   lc() { [ -f "$PROJECT/$1" ] && wc -l < "$PROJECT/$1" || echo 0; }

   echo "CLAUDE_MD_EXISTS=$(f .claude/CLAUDE.md)"
   echo "ROOT_CLAUDE_MD_EXISTS=$(f CLAUDE.md)"
   echo "OPENSPEC_EXISTS=$(d openspec)"
   echo "CONFIG_YAML_EXISTS=$(f openspec/config.yaml)"
   echo "INSTALL_SH_EXISTS=$(f install.sh)"
   echo "SYNC_SH_EXISTS=$(f sync.sh)"

   # Global-config detection for LOCAL_SKILLS_DIR
   if [ "$INSTALL_SH_EXISTS" = "1" ] && [ "$SYNC_SH_EXISTS" = "1" ]; then
     LOCAL_SKILLS_DIR="skills"
   elif grep -q 'Claude Code SDD meta-system' "$PROJECT/openspec/config.yaml" 2>/dev/null; then
     LOCAL_SKILLS_DIR="skills"
   else
     LOCAL_SKILLS_DIR=".claude/skills"
   fi
   echo "LOCAL_SKILLS_DIR=$LOCAL_SKILLS_DIR"

   echo "STACK_MD_EXISTS=$(f ai-context/stack.md)"
   echo "ARCH_MD_EXISTS=$(f ai-context/architecture.md)"
   echo "CONV_MD_EXISTS=$(f ai-context/conventions.md)"
   echo "ISSUES_MD_EXISTS=$(f ai-context/known-issues.md)"
   echo "CHANGELOG_MD_EXISTS=$(f ai-context/changelog-ai.md)"
   echo "CLAUDE_MD_LINES=$(lc CLAUDE.md)"
   echo "STACK_MD_LINES=$(lc ai-context/stack.md)"

   # Orphaned changes (dirs in changes/ not in archive/, modified >14 days ago)
   ORPHANED=""
   if [ -d "$PROJECT/openspec/changes" ]; then
     for dir in "$PROJECT/openspec/changes"/*/; do
       name=$(basename "$dir")
       [ "$name" = "archive" ] && continue
       [ -z "$(find "$dir" -maxdepth 0 -not -newer "$PROJECT/openspec/changes" -mtime +14 2>/dev/null)" ] || \
         ORPHANED="${ORPHANED:+$ORPHANED,}$name"
     done
   fi
   echo "ORPHANED_CHANGES=${ORPHANED:-NONE}"

   # SDD phase skills present
   SDD_COUNT=0
   for phase in explore propose spec design tasks apply verify archive; do
     [ -f "$HOME/.claude/skills/sdd-$phase/SKILL.md" ] && SDD_COUNT=$((SDD_COUNT+1))
   done
   echo "SDD_SKILLS_PRESENT=$SDD_COUNT"
   echo "FEATURE_DOCS_CONFIG_EXISTS=$(grep -l "feature_docs:" "$PROJECT/openspec/config.yaml" 2>/dev/null | wc -l | tr -d ' ')"
   echo "ANALYSIS_REPORT_EXISTS=$(f analysis-report.md)"
   echo "ANALYSIS_REPORT_DATE=$(head -5 "$PROJECT/analysis-report.md" 2>/dev/null | grep 'Last analyzed:' | awk '{print $3}' || echo '')"
   ```

   **Output key schema** (each key is a `key=value` line in stdout):

   - `CLAUDE_MD_EXISTS` — 1 if `.claude/CLAUDE.md` exists, 0 if absent
   - `ROOT_CLAUDE_MD_EXISTS` — 1 if root `CLAUDE.md` exists, 0 if absent
   - `OPENSPEC_EXISTS` — 1 if `openspec/` directory exists, 0 if absent
   - `CONFIG_YAML_EXISTS` — 1 if `openspec/config.yaml` exists, 0 if absent
   - `INSTALL_SH_EXISTS` — 1 if `install.sh` exists at project root, 0 if absent
   - `SYNC_SH_EXISTS` — 1 if `sync.sh` exists at project root, 0 if absent
   - `LOCAL_SKILLS_DIR` — string: `"skills"` (global-config detected via Condition A or B) or `".claude/skills"` (standard project)
   - `STACK_MD_EXISTS` — 1 if `ai-context/stack.md` exists, 0 if absent
   - `ARCH_MD_EXISTS` — 1 if `ai-context/architecture.md` exists, 0 if absent
   - `CONV_MD_EXISTS` — 1 if `ai-context/conventions.md` exists, 0 if absent
   - `ISSUES_MD_EXISTS` — 1 if `ai-context/known-issues.md` exists, 0 if absent
   - `CHANGELOG_MD_EXISTS` — 1 if `ai-context/changelog-ai.md` exists, 0 if absent
   - `CLAUDE_MD_LINES` — integer line count of root `CLAUDE.md` (0 if absent)
   - `STACK_MD_LINES` — integer line count of `ai-context/stack.md` (0 if absent)
   - `ORPHANED_CHANGES` — comma-separated names of orphaned change dirs, or `NONE`
   - `SDD_SKILLS_PRESENT` — integer count of present `~/.claude/skills/sdd-*/SKILL.md` files (0–8)
   - `FEATURE_DOCS_CONFIG_EXISTS` — 1 if `openspec/config.yaml` contains a `feature_docs:` key, 0 if absent or config not found
   - `ANALYSIS_REPORT_EXISTS` — 1 if `analysis-report.md` exists at project root, 0 if absent
   - `ANALYSIS_REPORT_DATE` — ISO date string from the `Last analyzed:` field of `analysis-report.md`, or empty string if absent

   **Legacy commands/ detection (Phase A post-script check):**

   After running the Phase A script, check whether `.claude/commands/` exists in the project root:

   ```
   if [ -d "$PROJECT/.claude/commands" ]; then
     emit LOW finding: "Legacy .claude/commands/ directory detected — migrate to .claude/skills/ following the official Claude Code standard."
   fi
   ```

   - Severity: LOW (informational)
   - Score penalty: none
   - FIX_MANIFEST entry: none (do NOT add a `required_actions` entry for this finding)

### Phase A extension — analysis-report.md check

After the Phase A Bash batch completes, the following two variables are available for use by Dimension 7 in Phase B:

- `ANALYSIS_REPORT_EXISTS` — 1 if `analysis-report.md` exists at the project root, 0 if absent
- `ANALYSIS_REPORT_DATE` — ISO date string from the `Last analyzed:` field, or empty string if absent

**Important constraints:**

- `project-audit` does NOT invoke `project-analyze` automatically. `analysis-report.md` is treated as external input produced by a prior `/project-analyze` run.
- D7 in Phase B reads `ANALYSIS_REPORT_EXISTS` and `ANALYSIS_REPORT_DATE` to compute its score and staleness warning.
- These two variables are added to the existing Phase A Bash script template — no additional Bash call is introduced. Total Bash calls per audit run remain ≤ 3.
