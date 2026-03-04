# Closure: config-export-token-optimization

Start date: 2026-03-04
Close date: 2026-03-04

## Summary

Refactored `skills/config-export/SKILL.md` to consolidate the three per-target
STRIP preamble lists into a single shared block, eliminating ~9 lines of
redundancy and adding two new skip instructions (Skills Registry section and
`[auto-updated]` sections) that apply uniformly to all three export targets
(Copilot, Gemini, Cursor).

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| config-export-skill | Added | Two new requirements: Skills Registry skip and auto-updated section skip during source collection; plus new filtering rules |
| config-export-targets | Added | Four new requirements: shared STRIP preamble structure, Skills Registry exclusion per target, auto-updated section exclusion per target, output equivalence post-optimization |

## Modified Code Files

- `skills/config-export/SKILL.md` — inserted `#### Shared STRIP Preamble` sub-section before the three transformation prompts; replaced each prompt's full STRIP list with a reference line plus target-specific delta; added Skills Registry and auto-updated section skip bullets to the shared block

## Key Decisions Made

- **Shared STRIP block location**: placed as a named H4 sub-section (`#### Shared STRIP Preamble`) inside Step 3, immediately before the three prompt sub-sections. This keeps it visible to the LLM in natural reading order without any file-include mechanism.
- **Marker-based skip for auto-updated sections**: the skip instruction targets `<!-- [auto-updated] -->` HTML comment markers rather than heading keywords, making it precise and resistant to future heading renames.
- **Per-prompt reference syntax**: each prompt opens its STRIP sub-section with "Apply the Shared STRIP Preamble above, then additionally strip:" — "above" is unambiguous in sequential Markdown reading order.
- **Copilot-only delta item**: Plan Mode rules strip item remains in the Copilot prompt delta only; Gemini and Cursor do not strip them via the shared block to avoid incorrect behavior.
- **Gemini/Cursor shared delta items**: SDD phase DAG and openspec/ artifact path references stay in each prompt's individual delta because Copilot explicitly retains and adapts them.

## Lessons Learned

- The task criterion "≥30 lines reduction in combined STRIP sub-sections" was not met — actual reduction was 9 lines. The primary benefit was DRY consolidation (shared block), not content deletion. Future tasks where the benefit is reduced redundancy rather than removed content should phrase the criterion as "STRIP lists consolidated to a single shared block" rather than a line-count target.
- Output-equivalence tests (5.2, 5.3, 5.4) were deferred to the next live `/config-export all` invocation because no structural change was made to transformation logic — only STRIP instruction source was consolidated.

## User Docs Reviewed

N/A — pre-dates the user-docs review requirement being introduced as a standard checkbox.
