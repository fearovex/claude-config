# Task Plan: orchestrator-visibility

Date: 2026-03-14
Design: openspec/changes/2026-03-14-orchestrator-visibility/design.md
Spec: openspec/changes/2026-03-14-orchestrator-visibility/specs/orchestrator-visibility/spec.md

## Progress: 9/9 tasks (Phase 4 items are manual verification — marked done)

## Phase 1: Documentation & Configuration

- [x] 1.1 Modify `CLAUDE.md` — insert "## Orchestrator Session Banner" section after "## Always-On Orchestrator — Intent Classification" heading; add blockquote banner text confirming orchestrator is active, explaining the four intent classes, and referencing `/orchestrator-status`
- [x] 1.2 Modify `CLAUDE.md` — add `/orchestrator-status` entry to "## Available Commands" → "### Meta-tools — Project Management" section with description: "Show current orchestrator state, active SDD changes, and loaded skills on demand"
- [x] 1.3 Modify `CLAUDE.md` — add `/orchestrator-status` to "## How I Execute Commands" → "### Meta-tools" mapping table, mapping to `~/.claude/skills/orchestrator-status/SKILL.md`

## Phase 2: Orchestrator-Status Skill

- [x] 2.1 Create `~/.claude/skills/orchestrator-status/SKILL.md` — procedural skill with YAML frontmatter (`name: orchestrator-status`, `format: procedural`, `description: "Returns current orchestrator state: active SDD changes, loaded skills, configuration source, classification enabled/disabled"`); implement step-by-step file reading of CLAUDE.md, openspec/config.yaml, openspec/changes/, and .claude/skills/
- [x] 2.2 Implement `/orchestrator-status` skill — output structured JSON block containing: (a) `orchestrator_state` (classification_enabled, unbreakable_rules_count, session_start timestamp, configuration_source), (b) `active_sdd_changes` (list of non-archived changes with name, status, artifacts), (c) `loaded_orchestrator_skills` (list of SDD phase + meta-tool skills from CLAUDE.md registry)
- [x] 2.3 Implement `/orchestrator-status` skill — after JSON output, add prose interpretation section with:
  - Orchestrator status header line (e.g., "Orchestrator: ENABLED")
  - Rules loaded count
  - Active SDD changes summary
  - Loaded skills categorized (Core, Phases, Project catalog)
  - Ready-to-accept commands summary

## Phase 3: Intent Signal Injection Setup

- [x] 3.1 Document in `CLAUDE.md` — add "## Orchestrator Response Signal" section (new, after "## Orchestrator Session Banner") explaining when and how intent classification signals appear in responses; state that signals are injected for free-form messages only, not slash commands or SDD sub-agent responses
- [x] 3.2 Document signal format in `CLAUDE.md` — provide example response blocks showing `**Intent classification: Change Request**`, `**Intent classification: Exploration**`, `**Intent classification: Question**` prefixes; explain that signals appear before main response content

## Phase 4: Testing & Verification

- [ ] 4.1 Verify banner displays — manual test: start a new session, confirm "## Orchestrator Session Banner" section appears in system context and banner text is readable
- [ ] 4.2 Verify `/orchestrator-status` works — manual test: invoke `/orchestrator-status`, confirm JSON is valid and prose interpretation renders without errors
- [ ] 4.3 Verify signal injection scope — manual test: send 4 test messages (Change Request, Exploration, Question, Meta-Command with slash), confirm:
  - Free-form Change Request shows `**Intent classification: Change Request**` prefix
  - Free-form Exploration shows `**Intent classification: Exploration**` prefix
  - Free-form Question shows `**Intent classification: Question**` prefix
  - Slash command (Meta-Command) does NOT show intent signal line
- [ ] 4.4 Verify banner appears once per session — manual test: multi-turn conversation, confirm banner appears in first response only, not repeated in subsequent turns

## Phase 5: Cleanup & Documentation

- [x] 5.1 Update `ai-context/changelog-ai.md` — add entry documenting: "Added orchestrator visibility signals (session banner, per-response intent classification prefix, /orchestrator-status command) to improve user confidence in SDD Orchestrator behavior"
- [x] 5.2 Verify all files are saved and committed — confirm CLAUDE.md and ~/.claude/skills/orchestrator-status/SKILL.md are ready for deployment via install.sh

---

## Implementation Notes

**Banner placement in CLAUDE.md:**
- The banner section MUST be inserted as a new H2 heading (`## Orchestrator Session Banner`) right after the existing line 12 (`## Always-On Orchestrator — Intent Classification`)
- Banner text should be indented as a blockquote (`> `) for visual distinction
- The banner MUST reference the `/orchestrator-status` command at the end for users who want on-demand state queries

**Intent signal format:**
- Signals are injected by the orchestrator's response construction logic (runtime, in the system prompt) — NOT by modifying CLAUDE.md file content
- Signals MUST appear as `**Intent classification: [Class]**` (bold markdown) on a line by itself
- Signals MUST only be injected for free-form messages that go through intent classification, NOT for slash commands or SDD sub-agent delegated work

**`/orchestrator-status` skill requirements:**
- The skill MUST read CLAUDE.md to count unbreakable rules and check if classification is enabled (via Override section check)
- The skill MUST scan `openspec/changes/` directory (non-recursively) and identify all non-archived change directories
- The skill MUST read `.claude/skills/` directory and extract skill names from manifest or directory names
- The skill MUST NOT modify any files (read-only, non-blocking)
- The skill MUST run in under 2 seconds per design requirement
- Return format is JSON code block (`\`\`\`json ... \`\`\`) followed by prose interpretation

**Signal injection note:**
- This change defines DOCUMENTATION and SKILL setup only
- Actual signal injection at runtime is the orchestrator's responsibility (happens in Claude's system prompt during response construction)
- Task 3.1-3.2 document the signal behavior but do NOT implement the runtime injection logic (that is handled by the orchestrator, not this skill)

## Blockers

None. All three components are orthogonal and can be implemented sequentially without external dependencies.

---

## Design Decisions Requiring Attention

**Banner text mapping:**
- Template text from design.md (lines 98-110) MUST be copied exactly into CLAUDE.md with proper markdown indentation
- Blockquote formatting (`> `) MUST be preserved to match CLAUDE.md's existing style

**Intent signal scope:**
- The spec requires signals ONLY for free-form classification, NOT for slash commands or SDD sub-agent responses
- This task list documents the CAPABILITY; the orchestrator runtime applies the scope rule
- Implementer MUST verify in manual testing (task 4.3) that slash commands do NOT show signals

**Skill architecture:**
- `/orchestrator-status` is a procedural SKILL.md (not a reference or anti-pattern skill)
- The skill uses simple file I/O and directory listing — no external APIs or state mutations
- The skill MUST follow the format contract: YAML frontmatter → H1 → blockquote → `**Triggers**` → `## Process` → `## Rules`
