# Task Plan: sdd-new-improvements

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-new-improvements/design.md
Spec: openspec/changes/2026-03-10-sdd-new-improvements/specs/sdd-orchestration/spec.md

## Progress: 8/9 tasks

---

## Phase 1: Slug Inference Algorithm

Foundation: implement the slug inference logic, stop-word list, and collision detection.

- [x] 1.1 Design and document the slug inference algorithm in `sdd-new` SKILL.md (Step 0) ✓
  - Extract up to 5 meaningful words from description
  - Strip stop words: fix, add, update, the, a, an, for, of, in, with, showing, wrong, year, users, user
  - Lowercase, hyphenate
  - Prefix with YYYY-MM-DD
  - Max 50 characters
  - Collision detection: append -2, -3 if needed

- [x] 1.2 Implement slug inference in `sdd-new` SKILL.md (Step 0 — Infer slug from description) ✓
  - Add instructions for string manipulation logic
  - Output inferred slug to user without asking for confirmation
  - Stop here if argument is empty (existing validation maintained)

- [x] 1.3 Copy slug inference logic to `sdd-ff` SKILL.md (Step 0) ✓
  - Identical algorithm to sdd-new
  - Integrate with exploration launch (same step)

---

## Phase 2: Mandatory Exploration in sdd-new

Transform exploration from optional to mandatory in `sdd-new`.

- [x] 2.1 Modify `sdd-new` SKILL.md: Step 1 runs sdd-explore unconditionally ✓
  - Remove Step 2 prompt "Do you want exploration?"
  - Renamed Step 0 (slug inference), Step 1 (explore), Step 2 (propose), etc.
  - Pass inferred slug from Step 0 to Step 1 (sdd-explore)

- [x] 2.2 Verify sdd-new Step 2 (propose) reads exploration.md if it exists ✓
  - Updated the propose sub-agent launch to reference exploration.md in "Previous artifacts"

- [x] 2.3 Update sdd-new description and triggers in frontmatter ✓
  - Changed description: now mentions "mandatory exploration as first phase"
  - Updated trigger keywords

---

## Phase 3: Mandatory Exploration in sdd-ff

Add exploration as Step 0 in `sdd-ff` before proposal.

- [x] 3.1 Modify `sdd-ff` SKILL.md: Insert Step 0 (slug inference + exploration) ✓
  - Inserted new Step 0: Infer slug AND launch sdd-explore (combined)
  - Renumbered: propose → Step 1, spec+design → Step 2, tasks → Step 3, summary → Step 4

- [x] 3.2 Update sdd-ff description and triggers ✓
  - Changed description: mentions "mandatory exploration as Step 0"
  - Removed "skip explore phase" from triggers

- [x] 3.3 Verify sdd-ff summary output includes exploration phase ✓
  - Step 4 (final summary) now shows: explore, propose, spec, design, tasks phases

---

## Phase 4: CLAUDE.md Update

Update the global configuration to reflect the new fast-forward flow.

- [x] 4.1 Update CLAUDE.md "## Fast-Forward (/sdd-ff)" section ✓
  - Updated flow description to mention Step 0: sdd-explore (mandatory)
  - Shows new step sequence: explore → propose → spec+design (parallel) → tasks
  - Notes that exploration is mandatory

- [x] 4.2 Verify CLAUDE.md reflects both sdd-ff and sdd-new changes ✓
  - sdd-ff section updated with mandatory exploration
  - No conflicting information between the two sections

---

## Phase 5: Validation and Testing

Verify the changes work as specified.

- [x] 5.1 Syntax check: ensure all SKILL.md files are valid Markdown ✓
  - No broken links to sections
  - All step numbers consistent (sdd-new: 0–5; sdd-ff: 0–4)
  - All code blocks properly fenced (sdd-new: 22 fences even; sdd-ff: 18 fences even)

- [ ] 5.2 Manual test: run `/sdd-ff "Fix authentication bug in login"` in a test project
  - Verify slug is inferred (should be something like `2026-03-10-fix-authentication-login`)
  - Verify exploration runs as Step 0 without user gate
  - Verify subsequent phases (propose, spec, design, tasks) complete

- [ ] 5.3 Manual test: run `/sdd-new "Add payment processing"` in a test project
  - Verify slug is inferred
  - Verify exploration runs as Step 1 without user gate
  - Verify no prompt asking "do you want exploration?"

- [ ] 5.4 Collision test: verify slug collision detection
  - Manually create a directory `openspec/changes/2026-03-10-test-feature/`
  - Run `/sdd-ff "Test feature"`
  - Verify generated slug is `2026-03-10-test-feature-2`

---

## Phase 6: Deploy and Commit

Final phase: deploy to runtime and commit changes.

- [ ] 6.1 Run `bash install.sh` to deploy changes to ~/.claude/
  - Verify no errors during deployment
  - Confirm skills are copied to ~/.claude/skills/

- [ ] 6.2 Git commit with appropriate message
  - Message format: `feat(sdd-new/sdd-ff): auto-infer slug and make exploration mandatory`
  - Include summary of changes in commit body

---

## Dependencies and Order

- Phase 1 must complete before Phases 2 and 3
- Phases 2 and 3 can run in parallel (they modify different files)
- Phase 4 can begin once Phases 2 and 3 are drafted (final review of wording)
- Phase 5 (validation) requires all prior phases complete
- Phase 6 (deploy) is last

---

## Quality Criteria

- All step numbers in SKILL.md files are sequential and correct
- No references to removed steps
- All Task tool invocations pass correct `change-name` parameter (the inferred slug)
- Exploration.md is correctly referenced by sdd-propose in both orchestrators
- CLAUDE.md matches the new flow exactly
- Manual tests pass without user errors or confusing prompts
