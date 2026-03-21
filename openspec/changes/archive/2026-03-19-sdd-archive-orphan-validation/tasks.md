# Task Plan: 2026-03-19-sdd-archive-orphan-validation

Date: 2026-03-19
Design: openspec/changes/2026-03-19-sdd-archive-orphan-validation/design.md

## Progress: 7/7 tasks

## Phase 1: Delta Spec Update

- [x] 1.1 Modify `openspec/specs/sdd-archive-execution/spec.md` — merge the delta spec from `openspec/changes/2026-03-19-sdd-archive-orphan-validation/specs/sdd-archive-execution/spec.md` by appending the full "Completeness validation runs before verify-report check" and "CLOSURE.md records skipped phases" requirement sections (including all scenarios) and the "exploration.md and prd.md are never checked" requirement; preserve all existing spec content ✓

## Phase 2: Skill — Completeness Check Block

- [x] 2.1 Modify `skills/sdd-archive/SKILL.md` — insert a new "Completeness Check" sub-block at the top of Step 1, before the existing `verify-report.md` read, using the exact CRITICAL and WARNING output templates from `design.md` > Interfaces and Contracts; the block must: (a) list CRITICAL artifacts (`proposal.md`, `tasks.md`), halt with no proceed option if any are absent; (b) after CRITICAL passes, list WARNING artifacts (`design.md`, `specs/` non-empty), present the two-option prompt if any are absent; (c) CRITICAL takes precedence — WARNING is only evaluated when CRITICAL passes; (d) happy path produces no output ✓

- [x] 2.2 Modify `skills/sdd-archive/SKILL.md` — update Step 5 (Create closure note) CLOSURE.md template to include an optional `Skipped phases:` field that appears only when option 2 was selected during a WARNING-level check; add a conditional note in Step 5 instructions explaining when to include the field and how to derive the phase names from the missing artifacts (`design.md` → `design`, `specs/` → `spec`) ✓

- [x] 2.3 Modify `skills/sdd-archive/SKILL.md` — add two Rules entries to the `## Rules` section: (a) "CRITICAL artifacts (proposal.md, tasks.md) MUST block with no proceed option — the completeness check MUST run before verify-report.md is read"; (b) "WARNING artifacts (design.md, non-empty specs/) MUST always offer option 2 (acknowledge and proceed) — they MUST NOT silently block" ✓

## Phase 3: Verification Artifact

- [x] 3.1 Create `openspec/changes/2026-03-19-sdd-archive-orphan-validation/verify-report.md` — scaffold the verify-report referencing the success criteria from `proposal.md` (8 criteria), with each criterion as an unchecked `[ ]` item ready for manual scenario testing; include the standard User Documentation checkbox per the Step 5b template in sdd-archive SKILL.md ✓

## Phase 4: Cleanup

- [x] 4.1 Run `install.sh` to deploy updated `skills/sdd-archive/SKILL.md` to `~/.claude/skills/sdd-archive/SKILL.md` — verify the deployed file contains the completeness check block ✓

- [x] 4.2 Update `ai-context/changelog-ai.md` — record this session: change name, date, affected files (`skills/sdd-archive/SKILL.md`, `openspec/specs/sdd-archive-execution/spec.md`), and summary of what was added ✓

---

## Implementation Notes

- The completeness check block in Step 1 must be inserted BEFORE the existing `verify-report.md` read (line "I read `openspec/changes/<change-name>/verify-report.md` if it exists.")
- The CRITICAL output format and WARNING output format must match the design's Interfaces and Contracts section exactly — do not paraphrase
- The `Skipped phases:` field in CLOSURE.md is conditional: only written when option 2 was selected; never written on happy-path archives
- `exploration.md` and `prd.md` are explicitly excluded from both CRITICAL and WARNING checks — do not add them
- This is a Markdown + YAML skill file; no code compilation or test runner is used — verification is manual scenario-based

## Blockers

None.
