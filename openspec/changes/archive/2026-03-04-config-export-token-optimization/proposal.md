# Proposal: config-export-token-optimization

Date: 2026-03-04
Status: Draft

## Intent

Reduce the token load of the `config-export` skill execution by eliminating redundant content reads and consolidating shared transformation instructions, lowering per-invocation cost by approximately 130–200 lines without changing the skill's observable behaviour.

## Motivation

Every `/config-export` invocation currently loads approximately 1,397 lines of context. Three structural inefficiencies cause unnecessary token consumption:

1. **Duplicated STRIP preamble** — each of the three transformation prompts (Copilot, Gemini, Cursor) repeats an almost-identical STRIP list of ~25 lines, totalling ~75 lines where ~25 are sufficient with a shared definition.
2. **Skills Registry always read then stripped** — `CLAUDE.md` is read in its entirety including the ~60-line Skills Registry block, which all three target transformations immediately discard. This wastes tokens on content that never reaches any output.
3. **Non-essential ai-context/ sections loaded whole** — `conventions.md` and `architecture.md` contain auto-generated or low-value sections (Communication Matrix, Observed Conventions, Architecture Drift) that are consumed but contribute nothing to the generated output.

These inefficiencies compound on every single invocation. As the Skills Registry and ai-context/ files grow, the waste grows proportionally.

## Scope

### Included

- Refactor the three transformation prompts (Copilot, Gemini, Cursor) to reference a single shared STRIP definition instead of repeating it in each prompt
- Add explicit instructions to transformation prompts to skip or summarise the `## Skills Registry` section of `CLAUDE.md` rather than processing it in full
- Add instructions to transformation prompts to skip auto-generated sections in `conventions.md` and `architecture.md` (sections marked `[auto-updated]` or bearing headings such as "Observed Conventions", "Communication Matrix", "Architecture Drift")
- Measure and document the before/after line-count delta in the verify report

### Excluded (explicitly out of scope)

- Changing the list of source files read in Step 1 — `CLAUDE.md` continues to be loaded as a single unit (splitting CLAUDE.md is a separate, higher-risk change)
- Modifying any ai-context/ file structure or content
- Adding a CLI flag or runtime option to skip sections (no new user-facing surface)
- Changes to the Copilot, Gemini, or Cursor output formats or section ordering
- Changes to any SDD phase skill other than `config-export`

## Proposed Approach

The optimisation is applied entirely within the SKILL.md of `config-export`. No source files or project structure are modified.

**Approach A — Shared STRIP block (primary deliverable):** Extract the common strip items into a named "Shared STRIP Preamble" sub-section immediately before the three transformation prompts. Each prompt references this block by name (`Apply the Shared STRIP Preamble above, then additionally strip:`) and lists only its own target-specific strip items. This eliminates ~50 lines of repetition.

**Approach B — Registry skip instruction (additive):** Add a single bullet to each transformation prompt's STRIP list (or to the shared block): `The Skills Registry section of CLAUDE.md (lines starting with ~/.claude/skills/ or .claude/skills/)`. This ensures the LLM processing the transformation does not spend tokens re-reading and then ignoring the registry.

**Approach C — Auto-updated section skip instruction (additive):** Add a bullet to each transformation prompt instructing the LLM to skip sections whose heading contains `(auto-detected)` or whose content is bracketed by `<!-- [auto-updated]` ... `<!-- [/auto-updated] -->`. These sections (Observed Conventions, Architecture Drift, Observed Structure) never contribute content to any export target.

All three approaches are SKILL.md-only text changes. They are reversible by reverting `config-export/SKILL.md`.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/config-export/SKILL.md` | Modified | Medium — core skill logic |
| `.github/copilot-instructions.md` (generated) | Unchanged (output content same) | Low |
| `GEMINI.md` (generated) | Unchanged (output content same) | Low |
| `.cursor/rules/*.mdc` (generated) | Unchanged (output content same) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Shared STRIP block is misinterpreted by LLM and some strip items are missed in one target | Low | Medium | Verify each target output against a known CLAUDE.md fixture after apply; include in success criteria |
| Skip instructions for auto-updated sections cause the LLM to omit valid architecture content that appears near an auto-updated block | Low | Low | Craft skip instructions to target the explicit `<!-- [auto-updated] -->` comment markers rather than heading keywords alone |
| Token savings are smaller than estimated because LLM still processes the skipped sections contextually | Low | Low | Measure actual context window usage before and after; document delta in verify report |

## Rollback Plan

The entire change is confined to `skills/config-export/SKILL.md`. Rollback procedure:

1. `git revert HEAD` (if committed) — or restore the file from the last known-good commit: `git checkout <last-good-sha> -- skills/config-export/SKILL.md`
2. Run `bash install.sh` to redeploy the reverted skill to `~/.claude/`
3. Re-run `/config-export all` on a test project to confirm original behaviour is restored

No data is lost. Generated output files (copilot-instructions.md, GEMINI.md, .cursor/rules/) are regenerated on demand and are not source-of-truth.

## Dependencies

- `config-export/SKILL.md` must be the currently deployed version (confirmed: last changed in the `config-export` archived cycle, 2026-03-03)
- No changes to any other skill are required before starting

## Success Criteria

- [ ] `skills/config-export/SKILL.md` contains exactly one shared STRIP preamble block and each of the three transformation prompts references it rather than repeating the full list
- [ ] Running `/config-export all` on the `claude-config` project produces output files whose content is substantively identical to the pre-change output (no new sections removed or added from any generated file)
- [ ] The SKILL.md line count for the three transformation prompts combined is reduced by at least 30 lines relative to the pre-change baseline
- [ ] The Skills Registry content does not appear in any generated output (already true; the new instruction makes this explicit and LLM-enforced)
- [ ] Auto-generated sections (`[auto-updated]` blocks in architecture.md and conventions.md) do not appear in any generated output
- [ ] `/project-audit` on `claude-config` scores >= the pre-change score

## Effort Estimate

Low (hours) — all changes are confined to SKILL.md text; no code is written; verification is a diff comparison.
