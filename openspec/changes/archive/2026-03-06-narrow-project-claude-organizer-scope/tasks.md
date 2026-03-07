# Task Plan: narrow-project-claude-organizer-scope

Date: 2026-03-06
Design: openspec/changes/narrow-project-claude-organizer-scope/design.md

## Progress: 6/6 tasks

## Phase 1: Contract Artifacts

- [x] 1.1 Create `openspec/changes/narrow-project-claude-organizer-scope/proposal.md` with explicit scope, rollback plan, and measurable success criteria
- [x] 1.2 Create `openspec/changes/narrow-project-claude-organizer-scope/specs/project-claude-organizer/spec.md` as the delta contract for the organizer scope rewrite
- [x] 1.3 Create `openspec/changes/narrow-project-claude-organizer-scope/design.md` with rewrite strategy and concrete file matrix

## Phase 2: Scope Rewrite

- [x] 2.1 Modify `skills/project-claude-organizer/SKILL.md` — add an explicit `## Organizer Kernel` section describing detect, classify, propose, and apply additive migrations
- [x] 2.2 Modify `skills/project-claude-organizer/SKILL.md` — add an explicit `## Scope Boundaries` section separating core additive behavior, explicit opt-in operations, and advisory-only outcomes
- [x] 2.3 Modify `skills/project-claude-organizer/SKILL.md` — add an explicit `## Compatibility Policy` section and tighten `## Rules` so skills audit and ambiguous structures remain advisory-first concerns

## Phase 3: Verification and Closure

- [x] 3.1 Create `openspec/changes/narrow-project-claude-organizer-scope/verify-report.md` verifying that the narrowed contract sections exist and existing handlers remain present

---

## Implementation Notes

- Keep the rewrite additive and local near the top and bottom of `skills/project-claude-organizer/SKILL.md`
- Do not remove or rewrite the detailed legacy migration handlers in this change
- Preserve the current report artifact path and strategy-specific report sections

## Blockers

None.