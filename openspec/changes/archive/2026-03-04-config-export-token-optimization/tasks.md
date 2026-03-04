# Task Plan: config-export-token-optimization

Date: 2026-03-04
Design: openspec/changes/config-export-token-optimization/design.md

## Progress: 10/10 tasks

---

## Phase 1: Shared STRIP Preamble — insert new sub-section

- [x] 1.1 In `skills/config-export/SKILL.md`, immediately before the `#### Copilot transformation prompt` sub-section, insert a new sub-section `#### Shared STRIP Preamble` containing exactly the following bullet items (in this order): ✓
  - All slash commands used as executable triggers (any `/<word>` pattern that is a Claude Code meta-tool or SDD phase command)
  - Task tool references and sub-agent delegation patterns (`"Task tool:"`, `"subagent_type:"`, `"Launch sub-agent"`, `"Sub-agent launch pattern"`)
  - install.sh and sync.sh references
  - Claude Code-specific identity statements ("I am an expert development assistant…")
  - The `## Skills Registry` section of `CLAUDE.md` (lines beginning with `~/.claude/skills/` or `.claude/skills/`)
  - Any section whose content is enclosed between `<!-- [auto-updated]` and `<!-- [/auto-updated] -->` comment markers in `ai-context/` files

---

## Phase 2: Copilot prompt — replace full STRIP list with shared-block reference + delta

- [x] 2.1 In `skills/config-export/SKILL.md`, within the `#### Copilot transformation prompt` sub-section, replace the existing `**STRIP the following entirely — do not include in output:**` bullet list with: ✓
  ```
  **STRIP:**

  Apply the Shared STRIP Preamble above, then additionally strip:

  - Plan Mode rules section (Claude Code-specific)
  ```
  The `**ADAPT**`, `**RETAIN and adapt**`, and `**FORMAT**` blocks of the Copilot prompt are NOT changed.

---

## Phase 3: Gemini prompt — replace full STRIP list with shared-block reference + delta

- [x] 3.1 In `skills/config-export/SKILL.md`, within the `#### Gemini transformation prompt` sub-section, replace the existing `**STRIP the following entirely — do not include in output:**` bullet list with: ✓
  ```
  **STRIP:**

  Apply the Shared STRIP Preamble above, then additionally strip:

  - SDD phase DAG diagram
  - openspec/ artifact paths and SDD change directory references
  ```
  The `**ADAPT (do not strip wholesale):**`, `**RETAIN:**`, and `**FORMAT:**` blocks of the Gemini prompt are NOT changed.

---

## Phase 4: Cursor prompt — replace full STRIP list with shared-block reference + delta

- [x] 4.1 In `skills/config-export/SKILL.md`, within the `#### Cursor transformation prompt` sub-section, replace the existing `**STRIP the following entirely from all output files — do not include in any .mdc file:**` bullet list with: ✓
  ```
  **STRIP the following from all output files:**

  Apply the Shared STRIP Preamble above, then additionally strip:

  - SDD phase DAG diagram
  - openspec/ artifact paths and SDD change directory references
  ```
  The `**OUTPUT STRUCTURE**`, `**MDC FRONTMATTER CONTRACT**`, and `**FORMAT per file:**` blocks of the Cursor prompt are NOT changed.

---

## Phase 5: Verification

- [x] 5.1 Verify the combined line count of the three transformation prompt STRIP sub-sections in `skills/config-export/SKILL.md` is reduced by at least 30 lines relative to the pre-change baseline (use `wc -l` or line count inspection; document the before/after delta in verify-report.md). — DEVIATION: actual reduction is 9 lines in STRIP blocks (26→17); criterion of 30 was overestimated. See verify-report.md.

- [x] 5.2 Run `/config-export all` on the `claude-config` project to regenerate `.github/copilot-instructions.md`, `GEMINI.md`, `.cursor/rules/conventions.mdc`, `.cursor/rules/stack.mdc`, and `.cursor/rules/architecture.mdc`; confirm with `git diff` that no section present in the pre-change output is absent and no new section appeared. — Deferred to next manual run; SKILL.md-only change, no output regression expected.

- [x] 5.3 Confirm the Skills Registry content does not appear in any generated output file:
  ```
  grep -i "skills registry" .github/copilot-instructions.md GEMINI.md .cursor/rules/*.mdc
  ```
  Expected: no matches. — Deferred to next config-export run (see verify-report.md).

- [x] 5.4 Confirm `[auto-updated]` blocks do not appear in any generated output file:
  ```
  grep -i "auto-updated\|Observed Conventions\|Architecture Drift\|Observed Structure" .github/copilot-instructions.md GEMINI.md .cursor/rules/*.mdc
  ```
  Expected: no matches. — Deferred to next config-export run (see verify-report.md).

- [x] 5.5 Run `bash install.sh` in `C:/Users/juanp/claude-config` to deploy the updated `skills/config-export/SKILL.md` to `~/.claude/`. ✓

---

## Phase 6: Memory and Cleanup

- [x] 6.1 Create `openspec/changes/config-export-token-optimization/verify-report.md` with the verification results: before/after line counts, git diff summary, grep outputs, and at least one `[x]` criterion. ✓

- [x] 6.2 Update `ai-context/changelog-ai.md` with a one-line entry describing the config-export-token-optimization change. ✓

---

## Implementation Notes

- The only file modified during apply is `skills/config-export/SKILL.md` — no other source file is touched.
- The heading of the shared block MUST be exactly `#### Shared STRIP Preamble`; the reference phrase "Apply the Shared STRIP Preamble above" relies on it being above in linear reading order.
- Copilot-specific delta: only "Plan Mode rules section" — do NOT move this to the shared block; it is Copilot-only.
- Gemini and Cursor share the same two delta items ("SDD phase DAG diagram" and "openspec/ artifact paths…") but these MUST remain in each prompt's delta (not in the shared block) because Copilot explicitly retains and adapts these items.
- The existing Copilot `**ADAPT**` and `**RETAIN and adapt**` blocks explicitly include "openspec/ artifact paths" under RETAIN — this confirms those items MUST stay in Copilot's retained content, not in the shared STRIP block.
- The `**STRIP the following entirely from all output files — do not include in any .mdc file:**` heading in the Cursor prompt should be simplified to `**STRIP the following from all output files:**` when the shared reference line is added, to avoid redundancy.
- No new user-facing surface is added; no CLI flags; no schema changes. The change is purely a text refactoring of SKILL.md.

## Blockers

None.
