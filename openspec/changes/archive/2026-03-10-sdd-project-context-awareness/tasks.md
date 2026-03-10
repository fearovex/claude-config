# Task Plan: sdd-project-context-awareness

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-project-context-awareness/design.md
Specs:
- openspec/changes/2026-03-10-sdd-project-context-awareness/specs/sdd-phase-context-loading/spec.md
- openspec/changes/2026-03-10-sdd-project-context-awareness/specs/skill-authoring-conventions/spec.md

## Progress: 13/13 tasks

## Phase 1: Documentation Foundation

- [x] 1.1 Create `docs/sdd-context-injection.md` with Step 0 template, purpose section, graceful degradation rules, and staleness warning threshold (7 days) ✓

## Phase 2: Orchestrator Skills (sdd-ff and sdd-new)

No modifications required to sdd-ff and sdd-new in this scope. (The proposal mentions context capsule generation, but the design and specs focus on context **consumption** by phase skills via Step 0 blocks. Orchestrator modifications are out of scope for tasks phase.)

## Phase 3: SDD Phase Skills — Context Loading (Part A)

Add Step 0 — Load project context block to four phase skills (non-propose/spec):

- [x] 3.1 Modify `~/.claude/skills/sdd-explore/SKILL.md` — add Step 0 block before existing Step 1; reads stack.md, architecture.md, conventions.md, and project CLAUDE.md Skills Registry ✓
- [x] 3.2 Modify `~/.claude/skills/sdd-design/SKILL.md` — add Step 0 block before existing Step 1 (same pattern as sdd-explore) ✓
- [x] 3.3 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — add Step 0 block before existing Step 1 (same pattern as sdd-explore) ✓
- [x] 3.4 Modify `~/.claude/skills/sdd-apply/SKILL.md` — add Step 0a — Load project context sub-step inside existing Step 0, before the scope guard; includes staleness check ✓

## Phase 4: SDD Phase Skills — Context Loading (Part B) — Domain Preload

Handle sdd-propose and sdd-spec with dual-step structure (Steps 0a + 0b):

- [x] 4.1 Modify `~/.claude/skills/sdd-propose/SKILL.md` — rename current Step 0 to "Step 0b — Domain context preload"; add new "Step 0a — Load project context" before it ✓
- [x] 4.2 Modify `~/.claude/skills/sdd-spec/SKILL.md` — rename current Step 0 (inside Step 1) to "Step 0b — Domain context preload"; add "Step 0a — Load project context" before Step 1; ensure Step 1 title is updated accordingly ✓

## Phase 5: SDD Design Skills — Registry Cross-Reference

- [x] 5.1 Modify `~/.claude/skills/sdd-design/SKILL.md` — add requirement that design recommendations check and reference the project Skills Registry loaded in Step 0; include guidance on marking unregistered skills as optional ✓

## Phase 6: Verification and Integration

- [x] 6.1 Run `/project-audit` — verify score >= 98/100 (baseline before change) ✓
- [x] 6.2 Create `openspec/changes/2026-03-10-sdd-project-context-awareness/verify-report.md` with at least three [x] success criteria verified ✓

---

## Implementation Notes

**Step 0 Template (to be inserted into each skill):**

All six phase skills must include a Step 0 block with this structure:

```markdown
### Step 0 — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the project's `CLAUDE.md` (at project root) and extract the `## Skills Registry` section.

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`

Loaded context is used as enrichment throughout all subsequent steps. It informs architectural
coherence, naming consistency, and skill alignment checks—but does NOT override explicit
content in the proposal or design.
```

**For sdd-propose and sdd-spec:** Use dual-step structure:
- Step 0a: Load project context (above template)
- Step 0b: Domain context preload (existing logic, unchanged)

**For sdd-apply:** Insert Step 0a as a labeled sub-section within the existing Step 0 (Technology Skill Preload), before the scope guard.

**sdd-design skill requirement:**
When recommending a skill or technology pattern, sdd-design MUST check the project Skills Registry (loaded in Step 0) and reference registered skills by name. If a relevant skill exists in the global catalog but is NOT registered in the project, mark it as optional (e.g., "[optional — not registered in project]").

**Context staleness threshold:** 7 days (files last updated before today - 7 days trigger a NOTE).

## Blockers

None.
