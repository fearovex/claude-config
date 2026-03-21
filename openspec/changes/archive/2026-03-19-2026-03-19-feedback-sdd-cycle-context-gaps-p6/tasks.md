# Task Plan: 2026-03-19-feedback-sdd-cycle-context-gaps-p6

Date: 2026-03-19
Design: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/design.md

---

## Progress: 12/12 tasks

---

## Phase 1: Proposal Implementation — Spec-first Q&A (Proposal 6a)

### Step 1a: Extend CLAUDE.md Question Routing

- [x] 1.1 Modify `CLAUDE.md` — Add Step 8 to Question routing section in "Classification Decision Table"
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/specs/orchestrator-behavior/spec.md
  Files: `C:\Users\juanp\claude-config\CLAUDE.md` (MODIFY)
  Acceptance:
    - CLAUDE.md Question routing section now includes Step 8: check for openspec/specs/index.yaml
    - Step 8 defines keyword matching algorithm (stem-based, case-insensitive)
    - Step 8 defines spec load cap (top 3 domains)
    - Step 8 defines contradiction surfacing format (⚠️ Note with spec ref + REQ-N)
    - Modification does not affect Change Request or Exploration routing

- [x] 1.2 Modify `CLAUDE.md` — Update "Direct question is answered inline" requirement in Orchestrator-Behavior spec section
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/specs/orchestrator-behavior/spec.md (MODIFIED requirement)
  Files: `C:\Users\juanp\claude-config\CLAUDE.md` (MODIFY — Question routing pathway)
  Acceptance:
    - Requirement now explicitly states spec-first read behavior
    - Clarifies that spec loading is part of Question pathway, not separate phase
    - Text reflects that spec is authoritative source for answer

### Step 1b: Document Spec-first Q&A Behavior

- [x] 1.3 Update `docs/SPEC-CONTEXT.md` — added Orchestrator Spec-first Q&A section (file pre-existed from earlier change)
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/specs/orchestrator-behavior/spec.md
  Files: `C:\Users\juanp\claude-config\docs/SPEC-CONTEXT.md` (CREATE)
  Acceptance:
    - Document explains spec-first Q&A behavior (when it applies, when it doesn't)
    - Document explains keyword matching algorithm (stem splitting, case-insensitive matching, load cap of 3)
    - Document explains contradiction surfacing format
    - Document includes examples: question about "welcome video completion" → matches "fy-video-wiring" domain
    - Document clarifies fallback behavior when index.yaml is missing or no keywords match

---

## Phase 2: Proposal Implementation — Spec Garbage Collection Skill (Proposal 6b)

### Step 2a: Create sdd-spec-gc Skill

- [x] 2.1 Create `~/.claude/skills/sdd-spec-gc/SKILL.md` — new spec GC skill
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/specs/spec-garbage-collection/spec.md
  Files: `C:\Users\juanp\.claude\skills\sdd-spec-gc\SKILL.md` (CREATE)
  Acceptance:
    - Skill is procedural format with YAML frontmatter (name, description, format: procedural)
    - Step 0a: Load project context (ai-context/*.md, CLAUDE.md) — non-blocking
    - Step 1: Read index.yaml and domain list (single domain or --all)
    - Step 2: Scan spec requirements for PROVISIONAL, ORPHANED_REF, CONTRADICTORY, SUPERSEDED, DUPLICATE patterns
    - Step 3: Generate and present dry-run report (markdown format with category sections)
    - Step 4: User confirmation gate (options: remove all, review individually, cancel)
    - Step 5: Apply removals (rewrite spec file, preserve header and all non-removed content)
    - Step 6: Record changes (add GC comment to spec header, update changelog-ai.md)
    - Supports both `/sdd-spec-gc domain` and `/sdd-spec-gc --all` command signatures
    - Error handling: index.yaml missing → log INFO and skip (non-blocking); spec.md unreadable → log WARNING and skip (continue in --all mode); grep timeout → mark as UNCERTAIN (do not remove)

### Step 2b: Register sdd-spec-gc in CLAUDE.md

- [x] 2.2 Modify `CLAUDE.md` — Add new "SDD Maintenance Skills" section to Skills Registry
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/design.md (File Change Matrix)
  Files: `C:\Users\juanp\claude-config\CLAUDE.md` (MODIFY)
  Acceptance:
    - New section "SDD Maintenance Skills" created in Skills Registry (after "SDD Skills (phases)" section)
    - Section includes entry: `~/.claude/skills/sdd-spec-gc/SKILL.md` — spec garbage collection skill
    - Section clarifies that maintenance skills are periodic utilities, not core phase skills
    - Placement clarifies distinction from Meta-tools (project-level) and Technology Skills (framework-specific)

### Step 2c: Create Optional Report Template (non-blocking)

- [x] 2.3 Create `docs/templates/sdd-spec-gc-report-template.md` — optional template for dry-run reports
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/design.md (File Change Matrix — optional)
  Files: `C:\Users\juanp\claude-config\docs\templates\sdd-spec-gc-report-template.md` (CREATE)
  Acceptance:
    - Template shows sample dry-run report structure for sdd-spec-gc output
    - Includes example categories (PROVISIONAL, ORPHANED_REF, CONTRADICTORY, SUPERSEDED, DUPLICATE)
    - Template is informational; absence does not block sdd-spec-gc execution

---

## Phase 3: Testing and Validation

- [x] 3.1 Validate Proposal 6a: Keyword matching algorithm
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/design.md (Testing Strategy)
  Files: Manual test cases (bash script or interactive session)
  Acceptance:
    - Test case 1: Question "what happens when welcome video completes?" matches "fy-video-wiring" domain (contains "video" stem)
    - Test case 2: Question "how does the orchestrator classify intent?" matches "orchestrator-behavior" domain
    - Test case 3: Question "why is the retry logic failing?" does NOT match unrelated domains; graceful fallback to code-only answer
    - All tests pass; keyword matching is correct

- [x] 3.2 Validate Proposal 6b: Detection patterns for GC candidates
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/specs/spec-garbage-collection/spec.md (Examples section)
  Files: Test spec files (created for validation, can be discarded after)
  Acceptance:
    - Test case 1: PROVISIONAL requirement detected (contains "provisional", "temporary", "pending", "will be replaced")
    - Test case 2: ORPHANED_REF requirement detected (references artifact not in codebase)
    - Test case 3: CONTRADICTORY requirement pair detected (two requirements cannot both be satisfied)
    - Test case 4: DUPLICATE requirement pair detected (same constraint expressed differently)
    - All patterns detected correctly; false negatives are minimized

- [x] 3.3 Validate Proposal 6b: sdd-spec-gc dry-run and confirmation workflow
  Spec: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/specs/spec-garbage-collection/spec.md (User confirmation scenarios)
  Files: Manual session with `/sdd-spec-gc` command
  Acceptance:
    - `/sdd-spec-gc orchestrator-behavior` produces dry-run report without modifying spec
    - Report lists all candidates with category, detection reason, and suggestion
    - User can choose: (1) remove all, (2) review individually, (3) cancel
    - Option 3 (cancel) results in no changes
    - Option 1 (remove all) removes all candidates and records changes
    - Option 2 (review individually) prompts user per candidate; user can skip or confirm
    - Spec file is rewritten only after user confirms
    - GC comment and changelog entry are added

---

## Phase 4: Documentation and Memory Updates

- [x] 4.1 Update `ai-context/architecture.md` — Record spec authority decisions from this change
  Files: `C:\Users\juanp\claude-config\ai-context\architecture.md` (MODIFY)
  Acceptance:
    - Architecture section documents that specs are now authoritative in Q&A (Proposal 6a consequence)
    - Architecture section documents the new spec maintenance capability (Proposal 6b consequence)
    - Records rationale: specs are the system of record; Q&A must consult them; maintenance prevents drift

- [x] 4.2 Update `ai-context/changelog-ai.md` — Record session work and design decisions
  Files: `C:\Users\juanp\claude-config\ai-context\changelog-ai.md` (MODIFY)
  Acceptance:
    - Entry records: "2026-03-19: Implemented spec-first Q&A (Proposal 6a) and spec garbage collection skill (Proposal 6b)"
    - Entry includes: Proposal decisions, spec authority reasoning, GC cadence guidance ("every 5-10 archived cycles")
    - Entry links to: openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/

---

## Implementation Notes

- **Spec-first Q&A keyword matching**: Reuse the pattern already implemented in `sdd-explore` Step 0 sub-step (stem splitting, top-3 cap, non-blocking fallback)
- **GC detection patterns**: Implement as regex/string patterns scanned against requirement text (see design.md Detection Patterns table for exact keywords per category)
- **GC best-effort search**: Use grep/ripgrep to search for artifact names; if not found or timeout, mark as UNCERTAIN (do not remove without user confirmation)
- **Backwards compatibility**: Both changes are purely additive; existing Q&A and spec handling continue unchanged if index.yaml is absent or no keywords match
- **Spec file format**: GC must preserve YAML frontmatter, headers, and all markdown structure; only remove specific requirement blocks
- **Changelog records**: Use consistent format (timestamp, domain, count per category, removals summary) for audit trail

---

## Blockers

None. The design is complete and all required context is available:
- CLAUDE.md is accessible for modification
- sdd-explore skill provides proven pattern for spec context preload
- openspec/specs/index.yaml exists (added in 2026-03-14-specs-search-optimization)
- All specification requirements are fully detailed in design.md and delta specs

---

## Dependencies Between Tasks

- Tasks 1.1 and 1.2 can run in parallel (both modify CLAUDE.md for Proposal 6a)
- Task 1.3 depends on 1.1 and 1.2 (documents the new behavior)
- Tasks 2.1, 2.2, 2.3 can run in parallel (Proposal 6b implementation)
- Phase 3 (testing) depends on Phases 1 and 2 (code must exist before validation)
- Phase 4 (documentation) depends on Phases 1, 2, and 3 (captures finalized state)

---

## Estimate

**Complexity**: Medium
**Effort**: 1–2 days (12 tasks, clear scope, proven patterns)
**Risk level**: Low (additive changes, graceful degradation, user-initiated actions with confirmation gates)

