# Exploration: improve-project-analysis

Date: 2026-02-27
Status: Complete

---

## Current State

### What project-audit currently does

`project-audit` is a 10-dimension diagnostic skill that currently audits:

| Dimension | Focus |
|-----------|-------|
| D1 — CLAUDE.md | Completeness, accuracy, SDD references |
| D2 — Memory (ai-context/) | Existence, line count, content coherence, freshness of user docs |
| D3 — SDD Orchestrator | Global skills presence, openspec/ structure, orphaned changes |
| D4 — Skills Quality | Registry accuracy, content depth, global tech skill coverage |
| D6 — Cross-reference Integrity | Broken path references in CLAUDE.md, skills, ai-context/ |
| D7 — Architecture Compliance | Code samples compared to documented architecture (API routes, services, components) |
| D8 — Testing & Verification | verify-report.md presence in archives, config.yaml testing block |
| D9 — Project Skills Quality | Local .claude/skills/ quality: duplicates, structure, language, stack relevance |
| D10 — Feature Docs Coverage | Per-feature documentation gap detection (informational only) |

**Key characteristics of the current design:**
- Read-only skill — never modifies files
- Produces `audit-report.md` with a structured `FIX_MANIFEST` block consumed by `/project-fix`
- Scores on 100 points (D9 and D10 are informational, no score impact)
- Phase A batches all bash discovery into a single script call (Rule 8: max 3 Bash calls per audit)
- Architecture compliance (D7) is very shallow: samples 3 API routes, 3 domain services, 2 components — only looks for specific framework patterns (PrismaClient, withSegmentAPI, etc.)
- Memory coherence (D2) reads files but only checks if documented paths in architecture.md exist — it does not analyze whether the actual architecture described matches reality

### What memory-manager does

`memory-manager` generates and updates the `ai-context/` layer. It:
- `/memory-init`: reads project deeply (config files, folder structure, README, representative code, tests, CI/CD) and produces all 5 memory files
- `/memory-update`: updates specific files based on work done in the current session

The memory files produced (`stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`) are intended to capture architectural decisions, naming conventions, patterns, and tech debt. However, `memory-manager` is primarily a **write** skill that generates content from what it reads — it is not a re-analysis or audit tool.

### What project-fix does

`project-fix` is the apply phase of the meta-SDD: it reads the `FIX_MANIFEST` from `audit-report.md` and executes each required action. It does not perform analysis — it implements corrections identified by `project-audit`. It has no awareness of architecture, patterns, or naming conventions beyond what the FIX_MANIFEST explicitly instructs.

### What the skill ecosystem is missing

After reading all relevant skills and architecture documentation, the following gaps are identified:

#### Gap 1 — No deep project understanding skill

There is no skill that answers the question: "What is this project? How is it structured? What patterns does it follow?" for a new Claude session or for context injection. `memory-manager` creates `ai-context/` once but does not re-analyze an established project to answer open-ended questions about it.

#### Gap 2 — project-audit's architecture analysis (D7) is cosmetic

D7 checks 3 API routes, 3 domain services, 2 components for very specific indicators (PrismaClient imports, specific wrappers). It does not:
- Analyze naming conventions across the codebase
- Detect actual file organization patterns (feature-based vs layer-based)
- Verify that the structure documented in `architecture.md` matches the real folder tree
- Detect architectural drift (when the code has evolved away from the documented architecture)
- Analyze module boundaries or coupling between layers
- Assess consistency of patterns across the codebase (e.g., is error handling uniform?)

#### Gap 3 — No convention verification

`conventions.md` documents naming, file organization, and code patterns — but no skill verifies that the code actually follows these documented conventions. `project-audit` does a shallow check (D2 coherence) that only verifies if documented paths in `architecture.md` still exist on disk.

#### Gap 4 — No skill quality depth analysis

`project-audit` D9 checks local `.claude/skills/` for structural completeness (presence of Triggers/Process/Rules sections) but does not assess:
- Quality of the content within those sections (is the Process section meaningful?)
- Whether the skill's trigger definition is specific enough to be actionable
- Whether the skill's rules are verifiable or vague
- Whether the skill's output format is defined

#### Gap 5 — project-audit has compounding responsibilities

Currently `project-audit` is responsible for:
1. Claude/SDD config layer health (its core purpose — D1, D3, D4, D6, D8)
2. Memory layer health (D2)
3. Code architecture compliance (D7 — requires reading source code)
4. Local skill quality (D9 — requires reading and evaluating skill files)
5. Feature documentation coverage (D10 — heuristic + config-driven feature detection)

Responsibilities 3, 4, and 5 each require different domain knowledge and different read depths. D7 in particular requires understanding the project's source code language and framework — something that varies wildly between projects. The current implementation handles this by hardcoding Next.js/Prisma-specific patterns, making D7 effectively useless for Django, Spring Boot, or pure Markdown projects.

---

## Affected Areas

| File/Module | Current role | Gap it has |
|-------------|--------------|-----------|
| `skills/project-audit/SKILL.md` | Diagnostic hub | D7 is cosmetic, too many responsibilities, no convention verification |
| `skills/memory-manager/SKILL.md` | Memory writer | Init-only, no re-analysis mode for established projects |
| `skills/project-fix/SKILL.md` | Correction applier | Follows FIX_MANIFEST, no analysis capability |
| `ai-context/architecture.md` | Architectural memory | Documents decisions, but no tool verifies drift from these decisions |
| `ai-context/conventions.md` | Convention memory | Documents patterns, but no tool verifies code compliance |
| `openspec/config.yaml` | SDD config | Could declare analysis targets (patterns to verify) but currently doesn't |

---

## Analyzed Approaches

### Approach A: Add a Dedicated `/project-analyze` Skill

**Description**: Create a new `project-analyze` skill (or `/project-understand`) that performs deep project analysis as a standalone operation, separate from auditing. This skill would:
1. Read the project folder structure and map it against `architecture.md`
2. Sample code files to identify actual patterns (naming conventions, module boundaries, import styles)
3. Compare observed patterns against `conventions.md`
4. Detect architectural drift (code that diverges from documented decisions)
5. Produce a structured `analysis-report.md` that can be consumed by the user or by `memory-manager` to update `ai-context/`

**Pros**:
- Clean separation of concerns: audit = config health, analyze = code health
- Reusable: analysis can be run independently of audit, more frequently
- Project-agnostic: can be designed without hardcoded framework assumptions
- Enables a richer analysis without breaking the 100-point audit score contract
- The analysis report could feed into `memory-update` for fresh documentation
- Future: could become an input to `project-audit` (analysis runs first, D7 reads its output)

**Cons**:
- New skill = new surface area to maintain
- Users must learn another command
- Risk of duplication with `project-audit` D7 if boundaries are not clear
- Does not solve the D7 cosmetic problem — D7 would still exist but do less
- Risk: the analysis report could become stale if not re-run regularly

**Estimated effort**: Medium-High (2-3 days for full implementation)
**Risk**: Medium — boundary with project-audit D7 must be very explicitly defined to avoid overlap

---

### Approach B: Enhance project-audit D7 — Make Architecture Analysis Framework-Agnostic

**Description**: Replace the current hardcoded D7 checks with a config-driven or heuristic approach that:
1. Reads `openspec/config.yaml` for declared architecture patterns (similar to D10's `feature_docs` key)
2. Falls back to heuristic detection based on what stack is detected
3. Samples files more intelligently (using the documented folder structure as the guide, not hardcoded paths)
4. Reports convention violations found during sampling

**Pros**:
- No new skill — fewer commands to learn
- Fixes the immediate D7 cosmetic problem
- Config-driven approach already proven by D10's `feature_docs` design
- Lower cognitive load for users

**Cons**:
- project-audit continues to grow in size and responsibilities
- D7 enhanced still runs inside a read-only skill — any deep analysis creates report bloat
- Adding convention checking to D7 would require reading many more source files, potentially violating the "max 3 Bash calls" Rule 8 of project-audit
- The skill is already 824 lines (SKILL.md); adding framework-agnostic architecture analysis would push it toward 1000+ lines
- Still conflates "config health" with "code quality analysis"

**Estimated effort**: Medium (1-2 days)
**Risk**: Medium — Rule 8 (max 3 Bash calls) becomes very hard to satisfy with deeper analysis

---

### Approach C: Split project-audit Responsibilities Explicitly

**Description**: Keep `project-audit` focused strictly on Claude/SDD config health (D1, D2, D3, D4, D6, D8). Extract D7 into a dedicated `project-analyze` skill. Redesign D9 and D10 as optional invocations from within project-audit (with a "run sub-skill" step) rather than embedded dimensions.

**Pros**:
- Clear responsibility boundary: project-audit = config health, project-analyze = code health
- Reduces project-audit complexity
- D9 and D10 can evolve independently without touching project-audit
- project-analyze can be designed from scratch without backward-compatibility concerns
- Better named: "audit" implies compliance checking, "analyze" implies understanding

**Cons**:
- Most disruptive to existing workflow — changes the user's mental model
- D9 and D10 are already embedded and validated — extracting them adds SDD cycle overhead
- Two commands where one exists today
- FIX_MANIFEST format changes (D7 findings must still reach project-fix somehow)

**Estimated effort**: High (3-4 days for clean extraction + new skill)
**Risk**: High — breaks the audit → fix pipeline if not designed carefully

---

### Approach D: Add a Lightweight `/project-understand` Skill (Exploration + Context Only)

**Description**: Create a new `project-understand` skill focused only on **reading and summarizing** a project for context — not producing a compliance report. It would:
1. Read the project structure, stack, conventions, and key code files
2. Produce a structured summary of: what the project does, how it is organized, what patterns it uses, what architectural decisions have been made
3. Save to `ai-context/understanding.md` or output directly to the user
4. Be useful at the start of a new session, before `/sdd-ff`, or when onboarding a new contributor

This skill would NOT check compliance or produce FIX_MANIFEST entries. It is purely informational — like `/sdd-explore` but for the whole project rather than a specific change.

**Pros**:
- Minimal — does exactly one thing: understand the project
- No interference with audit → fix pipeline
- Addresses the "missing deep project understanding" gap without touching existing skills
- Useful in many contexts (new session, new contributor, pre-SDD analysis)
- Low risk — additive only, no score or report format changes

**Cons**:
- Does not fix D7's cosmetic architecture compliance
- Does not address the "too many responsibilities" concern for project-audit
- The output (`understanding.md`) needs a freshness strategy or it becomes stale
- Partially overlaps with what a good `ai-context/architecture.md` should already contain

**Estimated effort**: Low-Medium (0.5-1 day)
**Risk**: Low

---

## Recommendation

**Recommended approach: Approach D first, then A in a separate cycle.**

The user's core concern has two distinct parts:

1. **"Many things are missing from project-analysis"** — architecture, patterns, file organization, naming conventions. This is best solved by a dedicated `/project-understand` or `/project-analyze` skill (Approach D as the first iteration, evolving toward A).

2. **"Does project-audit have too many responsibilities?"** — Yes, it does. But the current architecture is working and tested. The responsibility split (Approach C) carries high disruption risk and should be a separate, explicitly scoped change.

**Why not Approach B (enhance D7)?** Adding more analysis inside project-audit will push the skill toward unmaintainability. Rule 8 (max 3 Bash calls) will break under the weight of deeper code sampling. The right direction is to move analysis *out*, not to expand what's already there.

**Recommended sequence:**
1. `/sdd-ff analyze-project-understand` — design and create a new `project-understand` (or `project-analyze`) skill that does deep project understanding. This fills Gap 1 immediately.
2. In a later cycle, `/sdd-ff split-audit-analysis` — explicitly redesign D7 to delegate to `project-analyze` and strip project-audit down to config-only. This is a breaking change and needs its own SDD cycle.

The new skill's design should answer:
- What triggers it (when is "project understanding" needed vs "project auditing")?
- What does it produce (a report? updates to ai-context/? both?)
- How does it handle framework-agnostic code analysis?
- Does it replace `memory-init` for established projects, or complement it?

---

## Identified Risks

- **Scope creep**: A "project analyzer" skill risks becoming a second project-audit. The scope must be strictly: "read and understand the project" — not "check compliance."
- **Freshness**: Any analysis artifact (`understanding.md`) will become stale as the project evolves. A `Last verified` date field and integration with `project-update` or `memory-update` is necessary.
- **D7 limbo**: If a new analysis skill is created but D7 is not updated to reference it, D7 remains cosmetic. The two skills must have a clear handoff or D7 must be explicitly deprecated.
- **Over-analysis**: Deep codebase analysis by Claude reads many files and consumes significant context window. The skill must be designed with sampling and scope controls.
- **project-audit size**: `project-audit/SKILL.md` is already long (824+ lines). Any additional dimensions should be resisted. The right fix is to stop adding to it, not to add another dimension.

---

## Open Questions

1. **Output target**: Should a new analysis skill update `ai-context/` files directly (replacing/augmenting what `memory-manager` produced), or produce a separate `analysis-report.md`? Updating `ai-context/` directly is more useful but risks overwriting human edits.

2. **Trigger point**: Is this skill run once per project setup? Per session? On demand? The answer affects how stale its output can get.

3. **Relationship to `/sdd-explore`**: `sdd-explore` analyzes a specific topic before a change. `project-understand` would analyze the whole project. Are these the same skill with different scope, or genuinely different?

4. **Convention verification depth**: Should the new skill verify that code follows `conventions.md`, or only describe what conventions it observes? Verification requires reading many files; description requires reading fewer.

5. **Framework detection**: Should the skill auto-detect the framework and apply framework-specific analysis heuristics (like D7 currently does for Next.js/Prisma)? Or should it be config-driven (user declares in `openspec/config.yaml` what patterns to look for)?

6. **project-audit D7 fate**: If a `project-analyze` skill is created, should D7 be deprecated immediately, refactored to call `project-analyze`, or left as-is until the second cycle?

---

## Ready for Proposal

Yes — the exploration is complete. The recommendation is clear enough to move to proposal:

**Change name**: `improve-project-analysis`
**Core proposal**: Create a new `project-analyze` (or `project-understand`) skill for deep, framework-agnostic project analysis. Leave `project-audit` unchanged in this cycle. Address the D7 responsibility overlap in a follow-on change.

The proposal phase should resolve Open Questions 1, 2, and 5 (output target, trigger point, framework detection approach) before moving to spec+design.
