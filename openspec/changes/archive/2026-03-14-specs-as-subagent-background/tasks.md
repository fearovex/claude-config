# Task Plan: specs-as-subagent-background

Date: 2026-03-14
Design: openspec/changes/2026-03-14-specs-as-subagent-background/design.md

## Progress: 11/11 tasks

## Phase 1: Convention Document

- [x] 1.1 Create `docs/SPEC-CONTEXT.md` with sections: Purpose, Selection Algorithm (stem-based matching), Load Cap (3 files maximum), Non-Blocking Contract, Precedence Rule, Fallback Behavior, Skills This Applies To, Relationship to Companion Proposal (specs-search-optimization), When to Override

## Phase 2: Master Spec Update

- [x] 2.1 Modify `openspec/specs/sdd-context-loading/spec.md` — add new Requirement: "spec context preload" with acceptance scenarios covering match found (≤ 3 files loaded, log line emitted), no match (silent skip), and directory absent (INFO note, no failure)

## Phase 3: Skill Edits — Spec Context Preload Sub-Step

- [x] 3.1 Modify `skills/sdd-explore/SKILL.md` — add spec context preload sub-step to Step 0; sub-step must implement the stem-matching algorithm (split slug on hyphens, discard single-char stems, match domain in change_name OR stem in domain), hard cap at 3 files, non-blocking (INFO on failure only), log line format: `Spec context loaded from: [domain/spec.md, ...]`
- [x] 3.2 Modify `skills/sdd-propose/SKILL.md` — add Step 0c (spec context preload) after existing Step 0b (features preload); same algorithm and contract as 3.1
- [x] 3.3 Modify `skills/sdd-spec/SKILL.md` — add Step 0c (spec context preload) after existing Step 0b (features preload); same algorithm and contract as 3.1
- [x] 3.4 Modify `skills/sdd-design/SKILL.md` — add spec context preload sub-step to Step 0; same algorithm and contract as 3.1
- [x] 3.5 Modify `skills/sdd-tasks/SKILL.md` — add spec context preload sub-step to Step 0; same algorithm and contract as 3.1

## Phase 4: Cross-Reference Update

- [x] 4.1 Modify `docs/sdd-context-injection.md` — add cross-reference section pointing to `docs/SPEC-CONTEXT.md` for spec loading convention; do not alter existing Step 0 reference content

## Phase 5: Verification and Documentation

- [x] 5.1 Verify all five modified SKILL.md files declare valid `format:` in YAML frontmatter and satisfy their section contract (`procedural`: Triggers + Process + Rules present) — manual inspection
- [x] 5.2 Run `bash install.sh` to deploy updated skills to `~/.claude/` runtime
- [x] 5.3 Update `ai-context/changelog-ai.md` — record change: specs-as-subagent-background applied, files modified, date

---

## Implementation Notes

- The spec context preload sub-step is **non-blocking** in all five skills: any failure (missing directory, unreadable file, no match) produces at most an INFO-level note — never `status: blocked` or `status: failed`.
- For `sdd-propose` and `sdd-spec`, the new step is labeled **Step 0c** (these skills already have Steps 0a and 0b); for `sdd-explore`, `sdd-design`, and `sdd-tasks`, the sub-step is added within the existing Step 0 block with an appropriate sub-step label.
- Spec files loaded via this step are treated as **authoritative behavioral contracts**; `ai-context/` files remain supplementary for architecture and naming context.
- `sdd-apply` is explicitly excluded — it already operates against `openspec/changes/<change>/specs/` delta files injected by `sdd-spec`.
- The stem-matching algorithm: `stems = change_name.split("-").filter(s => s.length > 1)`; match when `domain in change_name OR any stem in domain`; hard cap at 3 results.
- Task 3.1–3.5 all implement the same algorithm; copy from the canonical contract in `docs/SPEC-CONTEXT.md` (created in Phase 1) to avoid divergence.

## Blockers

None.
