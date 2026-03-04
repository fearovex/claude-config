# Technical Design: config-export-token-optimization

Date: 2026-03-04
Proposal: openspec/changes/config-export-token-optimization/proposal.md

## General Approach

All changes are confined to `skills/config-export/SKILL.md`. A new "Shared STRIP Preamble" sub-section is inserted immediately before the three transformation prompt sub-sections. Each prompt's existing STRIP list is replaced by a reference line plus a short target-specific delta. Two additive skip instructions (Skills Registry and auto-updated sections) are appended to the shared block, ensuring they apply consistently to all three targets without per-prompt repetition.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Shared STRIP block location | New `#### Shared STRIP Preamble` sub-section inside `### Step 3`, immediately before the three prompt sub-sections | Inline comment in each prompt; separate include file | Placing it as a named H4 sub-section keeps it within the same logical step, visible to the LLM in natural reading order, and avoids any file-include mechanism that does not exist in SKILL.md conventions |
| Skip instruction for Skills Registry | Bullet in shared block: "The `## Skills Registry` section of `CLAUDE.md` (lines beginning with `~/.claude/skills/` or `.claude/skills/`)" | Truncating CLAUDE.md before loading (out of scope); adding a CLI flag (out of scope) | Prompt-level instruction requires zero structural change to Step 1 and is fully reversible; aligns with the proposal's Approach B |
| Skip instruction for auto-updated sections | Bullet in shared block: "Any section whose content is enclosed between `<!-- [auto-updated]` and `<!-- [/auto-updated] -->` comment markers" | Keyword-based heading match ("Observed Conventions", "Architecture Drift") | Marker-based skip is precise and resistant to heading renames; proposal explicitly recommended marker-based targeting over heading keywords to avoid false positives |
| Per-prompt reference syntax | Each prompt opens its STRIP sub-section with: "Apply the Shared STRIP Preamble above, then additionally strip:" | Replacing the block with a forward reference or footnote | "Above" is unambiguous in a linear Markdown reading order; no numbering scheme needed; consistent with how LLMs process context sequentially |
| Copilot-specific delta items | Keep Plan Mode rules strip item in the Copilot prompt delta only | Moving to shared block | Plan Mode rules are Copilot-only; Gemini and Cursor do not strip them because they already exclude that content via other strip items — placing it in the shared block would be incorrect |
| Gemini/Cursor shared delta items | SDD phase DAG diagram and openspec/ artifact path references remain in each prompt's delta | Moving to shared block | These two items are correctly stripped by Gemini and Cursor but explicitly RETAINED and adapted by Copilot — they cannot be in the shared block |

## Data Flow

```
/config-export invoked
        │
        ▼
Step 1 — source collection
   Read: CLAUDE.md (all sections including Skills Registry)
   Read: ai-context/stack.md, architecture.md, conventions.md, known-issues.md
        │
        ▼
Step 2 — target selection (unchanged)
        │
        ▼
Step 3 — dry-run generation
   ┌─────────────────────────────────────────────────────┐
   │  Shared STRIP Preamble (new — applied to all three) │
   │  - slash commands                                   │
   │  - Task tool / sub-agent patterns                   │
   │  - install.sh / sync.sh references                  │
   │  - ## Skills Registry section of CLAUDE.md          │  ← NEW
   │  - Claude Code identity statements                  │
   │  - [auto-updated] ... [/auto-updated] sections      │  ← NEW
   └─────────────────────────────────────────────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
   Copilot prompt      Gemini prompt       Cursor prompt
   delta: Plan Mode    delta: SDD DAG,     delta: SDD DAG,
   rules               openspec/ paths     openspec/ paths
        │                   │                   │
        ▼                   ▼                   ▼
   .github/            GEMINI.md           .cursor/rules/
   copilot-            (single file)       conventions.mdc
   instructions.md                         stack.mdc
                                           architecture.mdc
        │
        ▼
Step 4 — file writing (unchanged)
        │
        ▼
Step 5 — summary (unchanged)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/config-export/SKILL.md` | Modify | (1) Insert `#### Shared STRIP Preamble` sub-section before Copilot prompt; (2) Replace each prompt's full STRIP list with a reference line + target-specific delta; (3) Add Skills Registry skip bullet; (4) Add auto-updated section skip bullet |

No other files are modified by the implementation. Generated output files (.github/copilot-instructions.md, GEMINI.md, .cursor/rules/*.mdc) are regenerated at verify time to confirm behavioural equivalence.

## Interfaces and Contracts

This change is entirely within SKILL.md text — no typed interfaces or data schemas are involved. The relevant textual contract is the reference syntax each prompt uses to invoke the shared block:

```
#### Copilot transformation prompt (after change)

...
**STRIP:**

Apply the Shared STRIP Preamble above, then additionally strip:

- Plan Mode rules section (Claude Code-specific)
```

```
#### Gemini transformation prompt (after change)

...
**STRIP:**

Apply the Shared STRIP Preamble above, then additionally strip:

- SDD phase DAG diagram
- openspec/ artifact paths and SDD change directory references
```

```
#### Cursor transformation prompt (after change)

...
**STRIP the following from all output files:**

Apply the Shared STRIP Preamble above, then additionally strip:

- SDD phase DAG diagram
- openspec/ artifact paths and SDD change directory references
```

The shared block heading must remain exactly `#### Shared STRIP Preamble` so the reference phrase "above" is unambiguous in sequential reading order.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual diff | Count lines in the three transformation prompt STRIP sub-sections before and after; verify combined reduction >= 30 lines | `wc -l` on the SKILL.md, manual inspection |
| Manual diff | Confirm the Shared STRIP Preamble contains exactly: slash commands, Task tool refs, install.sh/sync.sh, Skills Registry skip, identity statements, auto-updated section skip | Read SKILL.md after apply |
| Functional | Run `/config-export all` on `claude-config`; diff generated files against the pre-change committed versions (.github/copilot-instructions.md, GEMINI.md, .cursor/rules/*.mdc); confirm no new sections dropped or added | Git diff of output files |
| Functional | Confirm `## Skills Registry` content does not appear in any generated output file | `grep -i "skills registry" .github/copilot-instructions.md GEMINI.md .cursor/rules/*.mdc` |
| Functional | Confirm `[auto-updated]` blocks do not appear in any generated output file | `grep -i "auto-updated\|Observed Conventions\|Architecture Drift\|Observed Structure" .github/copilot-instructions.md GEMINI.md .cursor/rules/*.mdc` |
| Audit | Run `/project-audit` on `claude-config`; confirm score >= pre-change score | `/project-audit` output |

## Migration Plan

No data migration required. The change is a text edit to a single SKILL.md. The generated output files are snapshots that are regenerated on demand; no migration of those files is needed.

## Open Questions

None.
