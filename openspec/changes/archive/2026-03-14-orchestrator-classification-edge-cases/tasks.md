# Task Plan: 2026-03-14-orchestrator-classification-edge-cases

Date: 2026-03-14
Design: openspec/changes/2026-03-14-orchestrator-classification-edge-cases/design.md

## Progress: 5/5 tasks

## Phase 1: Edit — Extend the Classification Decision Table

- [x] 1.1 Modify `CLAUDE.md` — in the `Classification Decision Table` fenced code block under `## Always-On Orchestrator — Intent Classification`, append the following edge-case example lines distributed across the three non-default branches:

  **Under the Change Request branch** (after the existing `✗ "explain the payment module"` line):
  ```
  ✓ "the login is broken"             → Change Request (implicit fix intent — broken state description)
  ✓ "the retry logic is missing"      → Change Request (implicit add intent — absence statement)
  ✓ "tests are failing after my last change" → Change Request (implicit fix — broken behavior)
  ✓ "the payment flow is completely wrong"   → Change Request (implicit fix — correctness complaint)
  ✗ "why does the login break?"       → Question (interrogative form — not a directive)
  ```

  **Under the Exploration branch** (after the existing `✗ "fix the auth bug"` line):
  ```
  ✓ "check the auth module"           → Exploration (inspect intent — not mutating)
  ✓ "look at the payment flow"        → Exploration (examine intent)
  ✓ "go through the retry logic"      → Exploration (walk-me-through intent)
  ✗ "fix what you find in the auth module" → Change Request (explicit fix directive)
  ```

  **Under the Question / default branch** (after the existing `✓ "how does X work?"` line):
  ```
  ✓ "why does login fail?"            → Question (interrogative + ends with ?)
  ✓ "what's wrong with the retry logic?" → Question (what-is pattern)
  ✓ "is the payment system broken?"   → Question (interrogative — not a directive)
  ✓ "login"                           → Question/Default (single ambiguous noun — no intent signal)
  ✓ "auth"                            → Question/Default (single ambiguous label)
  ✓ "refactor"                        → Question/Default (change verb without target — ask clarification)
  ```

  Total new examples: ≥12, covering all four edge case categories (implicit change, investigative-resembling-change, question-about-broken-behavior, ambiguous single-word).

- [x] 1.2 Modify `CLAUDE.md` — in the same `Classification Decision Table` fenced block, extend the comment annotations under the `ELSE IF change intent keywords` branch to include implicit signals. Add the following note immediately after the current list of explicit verbs:

  ```
  # also: state descriptions of breakage directed at a named component
  #   ("is broken", "doesn't work", "is wrong", "is missing")
  ```

- [x] 1.3 Modify `CLAUDE.md` — in the `## Always-On Orchestrator — Intent Classification` section, in the `### Intent Classes and Routing` table row for **Change Request**, extend the `Trigger Pattern` cell to read:

  > Action verbs directed at codebase: *fix, add, implement, create, build, update, refactor, remove, delete, migrate, deploy* — **also**: state descriptions of breakage directed at a named component (*is broken, doesn't work, is missing, is wrong*)

## Phase 2: Deploy and Verify

- [x] 2.1 Run `bash install.sh` from the repo root (`C:/Users/juanp/claude-config`) to deploy the updated `CLAUDE.md` to `~/.claude/CLAUDE.md`.

- [x] 2.2 Verify the deployed file: confirm that `~/.claude/CLAUDE.md` contains the new edge-case example lines by searching for at least one of the new lines (e.g. `"the login is broken"`).

---

## Implementation Notes

- This is a documentation-only change. No skill files, no scripts, and no YAML config are modified.
- All new example lines MUST follow the exact format `✓ "<message>"   → <Class> (<reason note>)` or `✗ "<message>"   → <Class> (<contrast note>)` — no deviation from the existing format.
- Tasks 1.1, 1.2, and 1.3 are all edits to the same file (`CLAUDE.md`). They MUST be applied as a single coherent edit or sequentially — do not interleave with other file writes.
- Task 2.1 (install.sh) MUST run after all Phase 1 edits are complete.
- The repo `CLAUDE.md` is authoritative. `~/.claude/CLAUDE.md` is the runtime copy. Never edit the runtime copy directly.
- Compound-intent edge case (e.g. "fix and explain"): not added to the table as an explicit example row — the spec covers it via the existing priority rule (Change Request > Exploration > Question). This is already handled by the table structure; adding rows for it would be redundant.

## Blockers

None.
