<!-- Note: "ADR" in this filename stands for "Architecture Definition Report", not "Architecture Decision Record". For architectural decision records, see docs/adr/. -->
# Architecture Definition Report (ADR)
# claude-config — SDD Meta-System

> **Version**: 1.0
> **Date**: 2026-02-28
> **Status**: Living document — updated as architecture evolves
> **Reference**: Based on [agent-teams-lite](https://github.com/Gentleman-Programming/agent-teams-lite) v2.0

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Identity and Purpose](#2-system-identity-and-purpose)
3. [Architecture Overview](#3-architecture-overview)
4. [Layer 1: Orchestrator](#4-layer-1-orchestrator)
5. [Layer 2: Skills Catalog](#5-layer-2-skills-catalog)
6. [Layer 3: Memory](#6-layer-3-memory)
7. [SDD Lifecycle — Complete Flow](#7-sdd-lifecycle--complete-flow)
8. [Meta-Tools — Project Management Lifecycle](#8-meta-tools--project-management-lifecycle)
9. [Artifact Storage (OpenSpec)](#9-artifact-storage-openspec)
10. [Deployment Model](#10-deployment-model)
11. [Boundary Definitions](#11-boundary-definitions)
12. [Gap Analysis vs Reference (agent-teams-lite)](#12-gap-analysis-vs-reference-agent-teams-lite)
13. [OpenCode Replication Strategy](#13-opencode-replication-strategy)
14. [Glossary](#14-glossary)

---

## 1. Executive Summary

`claude-config` is a **zero-dependency, Markdown-based meta-system** that implements Specification-Driven Development (SDD) for AI-assisted coding. It extends the original `agent-teams-lite` framework with:

- **Meta-tools** for project lifecycle management (audit, analyze, fix, setup, onboard, update)
- **Persistent memory layer** (`ai-context/`) replacing the engram dependency
- **Technology skills catalog** (26 tech skills) for framework-specific guidance
- **Self-dogfooding architecture** — the repo itself uses SDD to evolve

The system solves four fundamental problems with AI-assisted development:

| Problem | Solution |
|---------|----------|
| Context overload (long conversations lose detail) | Sub-agent delegation — each phase gets fresh context |
| Lack of structure (vague requests → unpredictable results) | SDD phases enforce structured artifacts at each step |
| No approval gates (code written before specs agreed) | Confirmation gates between phases |
| Missing persistence (specs vanish into chat history) | OpenSpec file-based artifacts + ai-context/ memory |

---

## 2. System Identity and Purpose

### 2.1 What It Is

A **configuration repository** that deploys to `~/.claude/` and provides:

1. **SDD Orchestrator** — coordinates development cycles via sub-agent delegation
2. **Meta-tools** — manage project health, onboarding, auditing, and memory
3. **Skills Catalog** — technology-specific coding guides (React, Django, etc.)

### 2.2 What It Is NOT

- NOT a code framework or library (zero runtime dependencies)
- NOT a VS Code extension or CLI tool (pure Markdown + YAML + Bash)
- NOT tied to Claude Code forever (designed for portability — see Section 13)
- NOT a replacement for testing tools (it orchestrates, the user's stack tests)

### 2.3 Two Roles

| Role | When Active | Behavior |
|------|-------------|----------|
| **Meta-tool** | `/project-*` and `/memory-*` commands | Creates, audits, and maintains SDD architecture in target projects |
| **SDD Orchestrator** | `/sdd-*` commands | Executes development cycles by delegating to sub-agents |

---

## 3. Architecture Overview

### 3.1 Three-Layer Structure

```
┌─────────────────────────────────────────────────┐
│              Layer 1: ORCHESTRATOR               │
│  CLAUDE.md — routing, delegation, state tracking │
├─────────────────────────────────────────────────┤
│              Layer 2: SKILLS CATALOG             │
│  skills/sdd-* (8) + skills/project-* (7) +      │
│  skills/tech-* (26) + skills/tool-* (2)          │
├─────────────────────────────────────────────────┤
│              Layer 3: MEMORY                     │
│  ai-context/ (5 core files) + openspec/ (specs)  │
└─────────────────────────────────────────────────┘
```

### 3.2 Deployment Model

```
claude-config (repo)  ──install.sh──►  ~/.claude/ (runtime)
                       ◄──sync.sh────  (memory/ only)
```

- **Config-authoritative**: `install.sh` copies repo → `~/.claude/`
- **Memory-authoritative**: `sync.sh` copies `~/.claude/memory/` → repo (memory only)
- **Never edit `~/.claude/` directly** — always edit repo, deploy via `install.sh`

### 3.3 Component Count

| Category | Count | Description |
|----------|-------|-------------|
| SDD Phase Skills | 8 | explore, propose, spec, design, tasks, apply, verify, archive |
| SDD Orchestrator Skills | 3 | sdd-new, sdd-ff, sdd-status |
| Meta-tool Skills | 7 | project-setup, project-onboard, project-audit, project-analyze, project-fix, project-update, memory-manager |
| Skill Management | 2 | skill-creator, skill-add |
| Technology Skills | 26 | Frontend (9), Backend (4), Testing (2), Tooling (5), Languages (1), Platforms (3), Process (2) |
| Scripts | 2 | install.sh, sync.sh |
| Config Files | 3 | CLAUDE.md, openspec/config.yaml, settings.json |
| Memory Files | 5 core + 3 docs | stack, architecture, conventions, known-issues, changelog-ai + onboarding, scenarios, quick-reference |

**Total: 46 skills + 2 scripts + 3 configs + 8 memory files**

---

## 4. Layer 1: Orchestrator

### 4.1 Core Principle: Delegate-Only

The orchestrator (defined in CLAUDE.md) follows a strict delegation pattern:

```
┌──────────────────────────────────────────────┐
│               ORCHESTRATOR                    │
│                                              │
│  ✗ Never reads source code                    │
│  ✗ Never writes implementation code           │
│  ✗ Never writes specs, proposals, or designs  │
│  ✗ Never executes phase work in own context   │
│                                              │
│  ✓ Launches sub-agents via Task tool          │
│  ✓ Tracks minimal state (file paths only)     │
│  ✓ Presents summaries to user                 │
│  ✓ Asks for approval before next phase        │
└──────────────────────────────────────────────┘
```

### 4.2 Sub-Agent Launch Pattern

Every SDD phase is delegated via:

```
Task tool:
  subagent_type: "general-purpose"
  prompt: |
    STEP 1: Read ~/.claude/skills/sdd-{phase}/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: {absolute path}
    - Change: {change-name}
    - Previous artifacts: {list of paths}

    Return: { status, summary, artifacts, next_recommended, risks }
```

### 4.3 Why Delegate-Only Matters

| Without Delegation | With Delegation |
|-------------------|-----------------|
| Context grows unbounded | Each sub-agent starts fresh |
| Orchestrator gets confused after 5+ phases | Orchestrator maintains minimal state |
| User can't audit what happened | Each phase produces reviewable artifacts |
| No approval gates | Explicit gates between phases |

### 4.4 State Tracking

The orchestrator tracks ONLY:
- Change name
- Which artifacts exist (file paths, not content)
- Current phase in the DAG
- Issues from previous phases (summary only)

---

## 5. Layer 2: Skills Catalog

### 5.1 Skill Structure (Unbreakable Rule)

Every skill MUST be:

```
skills/{skill-name}/
└── SKILL.md          ← single entry point
```

Every SKILL.md MUST contain:
1. **YAML frontmatter** — name, description, metadata
2. **Trigger definition** — when the skill activates
3. **Process steps** — numbered, sequential steps
4. **Rules section** — constraints and invariants

### 5.2 Skill Categories

#### A. SDD Phase Skills (8)

These are the atomic units of the SDD lifecycle. Each is invoked ONLY by the orchestrator as a sub-agent.

| Skill | Input | Output | Invoked By |
|-------|-------|--------|------------|
| `sdd-explore` | Topic/question | `exploration.md` | User or sdd-new |
| `sdd-propose` | Change description | `proposal.md` | sdd-ff, sdd-new |
| `sdd-spec` | proposal.md | `specs/{domain}/spec.md` | sdd-ff, sdd-new (parallel with design) |
| `sdd-design` | proposal.md | `design.md` | sdd-ff, sdd-new (parallel with spec) |
| `sdd-tasks` | spec + design | `tasks.md` | sdd-ff, sdd-new |
| `sdd-apply` | All artifacts | Modified source files | User via `/sdd-apply` |
| `sdd-verify` | All artifacts + code | `verify-report.md` | User via `/sdd-verify` |
| `sdd-archive` | verify-report + all | Archived folder + merged specs | User via `/sdd-archive` |

#### B. SDD Orchestrator Skills (3)

These ARE the orchestrator — they coordinate phase execution.

| Skill | Behavior | User Interaction |
|-------|----------|-----------------|
| `sdd-new` | Full cycle: optional explore → propose → [gate] → spec+design parallel → [gate] → tasks | 2 confirmation gates + optional explore |
| `sdd-ff` | Fast-forward: propose → spec+design parallel → tasks | No gates until end |
| `sdd-status` | Read openspec/changes/ and report what exists | Display only |

**When to use which:**

| Situation | Command |
|-----------|---------|
| Requirements are unclear, need to explore first | `/sdd-new` |
| Requirements are clear, want to review at each step | `/sdd-new` (skip explore) |
| Requirements are clear, want to go fast | `/sdd-ff` |
| Want to see what's in progress | `/sdd-status` |

#### C. Meta-tool Skills (7)

These manage project health and lifecycle. They are NOT sub-agents — they execute directly.

| Skill | Purpose | Input | Output |
|-------|---------|-------|--------|
| `project-setup` | Bootstrap SDD in a new project | Project filesystem | CLAUDE.md + ai-context/ + openspec/ |
| `project-onboard` | Diagnose project state, recommend commands | Project filesystem | Case diagnosis (1-6) + command sequence |
| `project-audit` | Deep diagnostic (11 dimensions) | Project filesystem | `.claude/audit-report.md` with FIX_MANIFEST |
| `project-analyze` | Framework-agnostic codebase observation | Project source code | `analysis-report.md` + ai-context/ updates |
| `project-fix` | Apply corrections from audit | `audit-report.md` | Fixed files + changelog entry |
| `project-update` | Sync config with user-level state | Global config + project deps | Updated CLAUDE.md + stack.md |
| `memory-manager` | Initialize or update ai-context/ | Project filesystem or session context | ai-context/ files |

#### D. Technology Skills (26)

These are passive knowledge bases — activated when the user works with a specific technology. They do NOT participate in SDD flow.

**Frontend (9):** react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native, electron
**Backend (4):** django-drf, spring-boot-3, hexagonal-architecture-java, java-21
**Testing (2):** playwright, pytest
**Tooling (5):** github-pr, jira-task, jira-epic, smart-commit, elixir-antipatterns
**Platforms (3):** claude-code-expert, excel-expert, image-ocr

### 5.3 Skill Interaction Map

```
User Command
     │
     ▼
┌─────────────┐     ┌──────────────────┐
│ Orchestrator │────►│ SDD Phase Skills │ (via Task tool)
│ Skills (3)   │     │ (8 skills)       │
└──────┬──────┘     └──────────────────┘
       │
       │ (user invokes directly)
       ▼
┌─────────────┐     ┌──────────────────┐
│ Meta-tool   │     │ Tech Skills      │
│ Skills (7)  │     │ (26 skills)      │ ← activated by context, not commands
└─────────────┘     └──────────────────┘
```

---

## 6. Layer 3: Memory

### 6.1 Two Memory Systems

| System | Location | Purpose | Managed By |
|--------|----------|---------|------------|
| **ai-context/** | Project root | Living project knowledge | memory-manager, project-analyze |
| **openspec/** | Project root | SDD artifacts and specs | SDD phase skills |

### 6.2 ai-context/ — The 5 Core Files

| File | Content | Updated By |
|------|---------|------------|
| `stack.md` | Tech stack, versions, dependencies | project-setup, project-update, memory-manager, project-analyze |
| `architecture.md` | Patterns, decisions, folder structure | project-setup, memory-manager, project-analyze |
| `conventions.md` | Naming, imports, code patterns | project-setup, memory-manager, project-analyze |
| `known-issues.md` | Bugs, gotchas, tech debt | memory-manager |
| `changelog-ai.md` | AI session log (newest first) | memory-manager, project-fix |

**Merge Strategy:**
- `[auto-updated]` markers delimit sections managed by project-analyze
- memory-manager respects these boundaries during incremental updates
- project-setup generates from scratch (never overwrites existing without asking)
- Resolved items are MOVED (to a Resolved section), never deleted

### 6.3 openspec/ — SDD Artifact Store

```
openspec/
├── config.yaml                    ← project rules + SDD configuration
├── specs/
│   └── {domain}/spec.md           ← MASTER specs (merged from deltas)
└── changes/
    ├── {change-name}/             ← active change
    │   ├── exploration.md         (optional)
    │   ├── proposal.md            (required)
    │   ├── specs/{domain}/spec.md (delta specs)
    │   ├── design.md
    │   ├── tasks.md
    │   └── verify-report.md
    └── archive/
        └── YYYY-MM-DD-{name}/     ← immutable audit trail
            └── CLOSURE.md         (generated by archive)
```

### 6.4 Memory Update Lifecycle

```
Session Start ──► Read ai-context/ files
      │
      ▼
  Work happens (SDD cycles, bug fixes, etc.)
      │
      ▼
Session End ──► /memory-update records decisions
      │
      ▼
  sync.sh ──► Persists ~/.claude/memory/ → repo
```

---

## 7. SDD Lifecycle — Complete Flow

### 7.1 Phase DAG (Dependency Graph)

```
  explore (optional)
        │
        ▼
    propose
        │
     ┌──┴──┐
     ▼     ▼
   spec  design     ← PARALLEL (two Task tool calls)
     └──┬──┘
        ▼
     tasks
        │
        ▼
     apply          ← user must explicitly invoke
        │
        ▼
    verify          ← recommended, not required
        │
        ▼
    archive         ← irreversible, requires confirmation
```

### 7.2 Phase Details

#### Phase: Explore (Optional)
- **Purpose**: Investigate codebase before committing to a change
- **Constraint**: Read-only — creates NO files, modifies NO code
- **Output**: `exploration.md` with findings and recommendations
- **When to skip**: Requirements are already clear

#### Phase: Propose
- **Purpose**: Define intent, scope, and approach for a change
- **Output**: `proposal.md` with:
  - Problem statement
  - Proposed solution
  - Scope (in/out)
  - Success criteria (verifiable)
  - Rollback plan
- **Gate**: User can stop here if proposal is rejected

#### Phase: Spec (parallel with Design)
- **Purpose**: Write delta specifications with Given/When/Then scenarios
- **Output**: `specs/{domain}/spec.md` (delta, not full)
- **Uses**: RFC 2119 keywords (MUST, SHALL, SHOULD, MAY)
- **Depends on**: proposal.md only

#### Phase: Design (parallel with Spec)
- **Purpose**: Document architecture decisions and file change plan
- **Output**: `design.md` with:
  - Architecture decisions with rationale
  - Data flow diagrams
  - File change table (path, action, description)
  - Rejected alternatives
- **Depends on**: proposal.md only

#### Phase: Tasks
- **Purpose**: Break work into phased, numbered, verifiable tasks
- **Output**: `tasks.md` with checkbox format
- **Depends on**: BOTH spec and design completed
- **Format**: `Phase N: {title}` → `- [ ] N.M: {task description}`

#### Phase: Apply
- **Purpose**: Implement code following specs and design
- **Invocation**: User must explicitly run `/sdd-apply`
- **Batching**: Orchestrator sends 3-4 tasks per sub-agent, asks before next batch
- **Rules**:
  - Read specs BEFORE writing code (they are acceptance criteria)
  - Follow design decisions — do not ignore or silently improve
  - Follow existing project patterns
  - Report DEVIATION when design has a problem (don't fix silently)
  - Do not implement tasks outside assigned scope

#### Phase: Verify
- **Purpose**: Quality gate — validates completeness, correctness, coherence
- **Output**: `verify-report.md` with:
  - Completeness check (tasks done vs total)
  - Correctness check (spec requirements met)
  - Coherence check (design decisions followed)
  - Testing check (tests exist and pass)
- **Verdict**: PASS | PASS WITH WARNINGS | FAIL
- **Severity**: CRITICAL (blocks archive) | WARNING (doesn't block) | SUGGESTION (optional)
- **Key rule**: Reports only — never fixes anything

#### Phase: Archive
- **Purpose**: Close the change cycle permanently
- **Process**:
  1. Verify archivability (no unresolved CRITICAL issues)
  2. Confirm with user (irreversible)
  3. **Merge delta specs into master specs** (ADDED/MODIFIED/REMOVED)
  4. Move folder to `archive/YYYY-MM-DD-{name}/`
  5. Generate CLOSURE.md
  6. Suggest `/memory-update`
- **Immutable**: Archived changes are NEVER modified or deleted

### 7.3 Fast-Forward vs Full Cycle

| Aspect | `/sdd-ff` | `/sdd-new` |
|--------|-----------|------------|
| Explore phase | Skipped | Optional (asks user) |
| Confirmation gates | Only at end | After propose + after spec+design |
| Speed | Fast (4 sub-agents) | Slower (4-5 sub-agents + gates) |
| Best for | Clear requirements | Unclear requirements or high-risk changes |
| Parallel execution | spec + design in parallel | Same |
| Auto-apply | Never | Never |

---

## 8. Meta-Tools — Project Management Lifecycle

### 8.1 Project Lifecycle Flow

```
New Project ──► /project-setup ──► /project-audit ──► /project-fix
                     │                    │                  │
                     ▼                    ▼                  ▼
              CLAUDE.md +          audit-report.md     Fixed files
              ai-context/ +
              openspec/

Existing Project ──► /project-onboard ──► (detects case) ──► recommended commands

Routine Maintenance:
  /project-audit ──► /project-fix        (fix problems)
  /project-analyze ──► updates ai-context (observe codebase)
  /project-update                        (sync with global config)
  /memory-update                         (record session work)
```

### 8.2 When to Use Which Meta-Tool

| Situation | Command | What It Does |
|-----------|---------|-------------|
| Brand new project, no Claude config | `/project-setup` | Creates CLAUDE.md, ai-context/, openspec/ |
| Existing project, unsure what to run | `/project-onboard` | Diagnoses state, recommends command sequence |
| Want to check project health | `/project-audit` | Scores 11 dimensions, produces FIX_MANIFEST |
| Audit found problems | `/project-fix` | Applies corrections from audit-report.md |
| Want to understand the codebase | `/project-analyze` | Observes code, updates ai-context/ auto-sections |
| Added/removed skills or updated global config | `/project-update` | Syncs CLAUDE.md and stack.md |
| First time setting up memory | `/memory-init` | Generates all 5 ai-context/ files from scratch |
| End of work session | `/memory-update` | Records session decisions into ai-context/ |

### 8.3 Meta-Tool Boundaries (Clear Separation)

```
┌─────────────────────────────────────────────────────────┐
│                  WHAT EACH TOOL TOUCHES                  │
├─────────────┬─────────┬──────────┬───────┬──────────────┤
│  Tool       │CLAUDE.md│ai-context│openspec│ Source code  │
├─────────────┼─────────┼──────────┼───────┼──────────────┤
│ setup       │ CREATE  │ CREATE   │CREATE │   reads      │
│ onboard     │ reads   │ reads    │ reads │   —          │
│ audit       │ reads   │ reads    │ reads │   reads      │
│ analyze     │ —       │ UPDATES  │  —    │   reads      │
│ fix         │ UPDATES │ UPDATES  │UPDATES│   —          │
│ update      │ UPDATES │ UPDATES  │  —    │   reads      │
│ memory-init │ —       │ CREATE   │  —    │   reads      │
│ memory-upd  │ —       │ UPDATES  │  —    │   —          │
└─────────────┴─────────┴──────────┴───────┴──────────────┘

 CREATE = generates from scratch
 UPDATES = modifies existing content
 reads = reads but never modifies
 — = does not interact
```

### 8.4 project-update vs project-fix — The Key Distinction

| | `/project-update` | `/project-fix` |
|-|-------------------|----------------|
| **Trigger** | After changing global config or adding skills | After `/project-audit` finds problems |
| **Input** | Global CLAUDE.md + project dependencies | `audit-report.md` FIX_MANIFEST |
| **Purpose** | "Bring this project up to date" | "Fix what the audit said is wrong" |
| **Scope** | Additive — syncs new skills, updates versions | Corrective — fixes broken references, missing files |
| **Analogy** | `apt update` (refresh catalog) | `apt fix-broken` (repair packages) |

### 8.5 Onboarding Cases (6 Scenarios)

| Case | Condition | Recommended Sequence |
|------|-----------|---------------------|
| 1 | No CLAUDE.md | `/project-setup` → `/memory-init` → `/project-audit` → `/project-fix` |
| 2 | CLAUDE.md present, no openspec/ | `/project-audit` → `/project-fix` → `/memory-init` |
| 3 | Partial SDD, sparse ai-context/ | `/memory-init` → `/project-audit` → `/project-fix` |
| 4 | Local skills present | Warning (non-blocking) — suggest audit D9 |
| 5 | Orphaned SDD changes | `/sdd-status` → resolve each change |
| 6 | Fully configured | `/sdd-ff` or `/sdd-new` — ready to develop |

---

## 9. Artifact Storage (OpenSpec)

### 9.1 config.yaml — The Project Contract

```yaml
project:
  name: "project-name"
  stack:
    language: "typescript"
    framework: "next.js 15"
    testing: "jest + playwright"

artifact_store:
  mode: openspec
  changes_dir: openspec/changes
  archive_dir: openspec/changes/archive

rules:
  proposal:  [...]
  specs:     [...]
  design:    [...]
  tasks:     [...]
  apply:     [...]
  verify:    [...]

testing:
  strategy: "audit-as-integration-test"
  minimum_score_to_archive: 75
  required_artifacts_per_change:
    - proposal.md
    - tasks.md
    - verify-report.md
```

### 9.2 Delta Spec Merge (Archive Phase)

When archiving, delta specs are merged into master specs:

```
BEFORE:
  openspec/specs/auth/spec.md          (master, 50 requirements)
  openspec/changes/add-2fa/specs/auth/spec.md  (delta, 3 new + 1 modified)

AFTER archive:
  openspec/specs/auth/spec.md          (master, 53 requirements, 1 updated)
  openspec/changes/archive/2026-02-28-add-2fa/  (immutable)
```

Merge operations:
- **ADDED** → appended to master
- **MODIFIED** → replaced in master (with audit trail comment)
- **REMOVED** → deleted from master (with audit trail comment)
- **Unmentioned** → preserved as-is

---

## 10. Deployment Model

### 10.1 install.sh — Repo → Runtime

```
Source (repo)              Destination (~/.claude/)
─────────────              ────────────────────────
CLAUDE.md          ──►     CLAUDE.md
settings.json      ──►     settings.json
skills/            ──►     skills/
hooks/             ──►     hooks/
openspec/          ──►     openspec/
ai-context/        ──►     ai-context/
memory/            ──►     memory/
```

**Environment detection**: WSL → Git Bash → native Unix (with graceful fallback)

### 10.2 sync.sh — Memory Persistence

```
~/.claude/memory/  ──►  repo/memory/
(ONLY memory, never skills or config)
```

### 10.3 Deployment Workflow

```
1. Edit files in claude-config repo
2. Run install.sh (deploy to ~/.claude/)
3. Test in a target project
4. Git commit in claude-config
5. Periodically run sync.sh to capture memory changes
```

---

## 11. Boundary Definitions

### 11.1 What the System Controls vs What It Doesn't

| System Controls | System Does NOT Control |
|----------------|----------------------|
| SDD phase orchestration | Actual code implementation details |
| Artifact structure and naming | Test framework choice (detects, doesn't mandate) |
| Audit dimensions and scoring | CI/CD pipeline configuration |
| Memory file format and lifecycle | Git workflow (branches, PRs) beyond suggestions |
| Skill structure requirements | IDE or editor configuration |
| Config deployment flow | Runtime environment setup |

### 11.2 Invariants (Things That Must ALWAYS Be True)

1. **Language**: ALL content in English — no exceptions
2. **Skill structure**: One directory, one SKILL.md entry point
3. **SDD compliance**: Every skill modification uses at minimum `/sdd-ff`
4. **Sync discipline**: Config flows repo→runtime (install.sh), memory flows runtime→repo (sync.sh)
5. **Orchestrator purity**: The orchestrator NEVER executes phase work directly
6. **Archive immutability**: Archived changes are NEVER modified or deleted
7. **Sub-agent isolation**: Each sub-agent starts with fresh context + reads its SKILL.md first
8. **Artifact prerequisites**: `tasks` requires both `spec` and `design`; `archive` requires no CRITICAL issues
9. **No silent changes**: All significant modifications require user confirmation

### 11.3 Design Decisions and Their Rationale

| Decision | Rationale | Alternative Considered |
|----------|-----------|----------------------|
| OpenSpec-only persistence (no engram) | Simpler, file-based, portable, inspectable | Engram (external dependency, harder to debug) |
| ai-context/ instead of engram memory | Self-contained, version-controlled, readable | Engram memory system |
| Parallel spec+design | Independent phases — no reason to serialize | Sequential (reference's OpenCode does this) |
| Meta-tools as direct execution (not sub-agents) | They need access to the full project state | Sub-agent delegation (too restrictive for auditing) |
| Tech skills as passive knowledge | They don't participate in SDD flow | Active skills (over-engineering) |
| Audit score as quality gate | Objective, repeatable, comparable over time | Manual review (subjective) |
| 11 audit dimensions | Comprehensive coverage without excessive granularity | Fewer dimensions (misses edge cases) |
| FIX_MANIFEST as YAML | Machine-parseable by project-fix | Free-text recommendations (harder to automate) |

---

## 12. Gap Analysis vs Reference (agent-teams-lite)

### 12.1 Features Present in Reference, Missing Here

| Feature | Reference Behavior | Impact | Recommendation |
|---------|-------------------|--------|----------------|
| **TDD mode in sdd-apply** | Auto-detects TDD (RED→GREEN→REFACTOR) from config, installed skills, or test patterns | MEDIUM — misses test-first workflow | **Add TDD detection** to sdd-apply |
| **sdd-continue** | Auto-detects next phase from existing artifacts | LOW — users can invoke phases manually | Consider adding for convenience |
| **sdd-init** (standalone) | Dedicated stack detection + persistence bootstrap | LOW — covered by project-setup | Not needed (project-setup is more comprehensive) |
| **Persistence mode selection** | engram / openspec / none with runtime resolution | LOW — openspec is sufficient | Not needed (simplification by design) |
| **Build & type-check in verify** | sdd-verify runs build command and type-checker | MEDIUM — verify only checks code statically | **Add build/typecheck execution** to sdd-verify |
| **Coverage validation in verify** | Optional coverage threshold check via config | LOW — nice-to-have | Consider if demand arises |
| **Spec compliance matrix** | Cross-references every spec scenario against test results with COMPLIANT/FAILING/UNTESTED/PARTIAL | MEDIUM — more granular than current verify | **Enhance verify** with compliance matrix |

### 12.2 Features Present Here, Missing in Reference

| Feature | Our Behavior | Value |
|---------|-------------|-------|
| **project-audit (11 dimensions)** | Comprehensive health check with scoring | HIGH — enables objective quality tracking |
| **project-analyze** | Framework-agnostic codebase observation | HIGH — keeps memory accurate |
| **project-fix** | Automated correction from audit findings | HIGH — closes the audit loop |
| **project-setup** | Full project bootstrapping | HIGH — faster than manual sdd-init |
| **project-onboard** | Case detection with command recommendations | HIGH — eliminates guesswork |
| **project-update** | Config sync with global state | MEDIUM — keeps projects current |
| **memory-manager** | Structured memory lifecycle | HIGH — persistent project knowledge |
| **26 tech skills** | Technology-specific coding guides | MEDIUM — improves code quality |
| **Audit trail (17 archived changes)** | Self-dogfooding proof | HIGH — demonstrates SDD works |
| **CLOSURE.md in archive** | Lessons learned capture | MEDIUM — knowledge retention |

### 12.3 Differences in Behavior

| Aspect | Reference | Ours | Assessment |
|--------|-----------|------|------------|
| **sdd-apply TDD** | Auto-detect TDD mode → RED/GREEN/REFACTOR | No TDD support | **Gap — should add** |
| **sdd-verify testing** | Runs tests + build + type-check + coverage | Reports test existence, may run tests | **Gap — should enhance** |
| **sdd-archive merge** | Merges delta specs into master | Same ✓ | Aligned |
| **Orchestrator delegation** | Sub-agents via Task tool | Same ✓ | Aligned |
| **Phase DAG** | Same dependency graph | Same ✓ | Aligned |
| **Spec format (RFC 2119)** | Mandates MUST/SHALL/SHOULD/MAY | Same ✓ | Aligned |
| **Archive immutability** | Never modify archive | Same ✓ | Aligned |
| **Deviation reporting** | In apply phase | Same ✓ | Aligned |

### 12.4 Priority Fixes

| # | Gap | Effort | Impact | Priority |
|---|-----|--------|--------|----------|
| 1 | Add TDD mode detection to sdd-apply | Medium | High | **P1** |
| 2 | Add build/typecheck execution to sdd-verify | Medium | High | **P1** |
| 3 | Add spec compliance matrix to sdd-verify | Medium | Medium | **P2** |
| 4 | Add coverage threshold support to sdd-verify | Low | Low | **P3** |
| 5 | Add `/sdd-continue` command | Medium | Low | **P3** |

---

## 13. OpenCode Replication Strategy

### 13.1 What Changes for OpenCode

| Aspect | Claude Code | OpenCode |
|--------|-------------|----------|
| Config file | `CLAUDE.md` (Markdown) | `opencode.json` (JSON) |
| Skill path | `~/.claude/skills/` | `~/.config/opencode/skill/` |
| Command format | Skills as SKILL.md in directories | Commands as flat `.md` files in `commands/` |
| Task delegation | Task tool with subagent_type | OpenCode's Task() function |
| Settings | `settings.json` | `opencode.json` agents section |
| Install target | `~/.claude/` | `~/.config/opencode/` |

### 13.2 What Does NOT Change

- **All 8 SDD phase SKILL.md files** — identical content
- **OpenSpec structure** — same directory layout and config.yaml
- **ai-context/ memory files** — same format
- **Phase DAG and dependency rules** — identical
- **Sub-agent delegation principle** — same pattern, different API
- **Audit dimensions and scoring** — same 11 dimensions

### 13.3 Replication Plan (High-Level)

```
Phase 1: Core SDD (minimum viable)
├── Translate CLAUDE.md orchestrator → opencode.json agent config
├── Copy 8 SDD phase skills → ~/.config/opencode/skill/
├── Create command .md files for: sdd-new, sdd-ff, sdd-apply, sdd-verify, sdd-archive
├── Create install-opencode.sh
└── Test on a real project

Phase 2: Meta-tools
├── Adapt project-setup for OpenCode paths
├── Adapt project-audit for OpenCode config format
├── Adapt project-fix for OpenCode
├── Create project-onboard for OpenCode
└── Test full lifecycle

Phase 3: Feature parity
├── Port all 7 meta-tools
├── Port skill management (skill-creator, skill-add)
├── Add memory-manager
├── Port tech skills (selective — based on demand)
└── Comprehensive testing
```

### 13.4 Shared Skill Strategy

Since SKILL.md files are tool-agnostic (they describe behavior, not tool-specific APIs), the strategy is:

```
claude-config/skills/           ← source of truth
    │
    ├── install.sh ──► ~/.claude/skills/         (Claude Code)
    └── install-opencode.sh ──► ~/.config/opencode/skill/  (OpenCode)
```

Only the orchestrator configuration and install scripts differ. The skills themselves are shared.

---

## 14. Glossary

| Term | Definition |
|------|-----------|
| **SDD** | Specification-Driven Development — write specs before code |
| **Phase** | One step in the SDD lifecycle (explore, propose, spec, design, tasks, apply, verify, archive) |
| **Phase DAG** | Directed Acyclic Graph defining phase dependencies |
| **Sub-agent** | A fresh AI context launched via Task tool to execute one phase |
| **Orchestrator** | The lead AI that coordinates phases but never executes them |
| **Delta spec** | Specifications for a single change (merged into master on archive) |
| **Master spec** | The accumulated specification for a domain (in openspec/specs/) |
| **OpenSpec** | File-based artifact storage mode (vs engram or none) |
| **FIX_MANIFEST** | YAML block in audit-report.md listing required corrections |
| **Gate** | A user confirmation point between SDD phases |
| **Meta-tool** | A skill that manages project configuration, not code |
| **ai-context/** | The persistent memory layer with 5 core files |
| **config.yaml** | Per-project SDD rules and conventions (in openspec/) |
| **SKILL.md** | The single entry point file for any skill |
| **Engagement** | The reference repo's term for engram's external persistence |
| **CLOSURE.md** | Summary document generated when archiving a change |
