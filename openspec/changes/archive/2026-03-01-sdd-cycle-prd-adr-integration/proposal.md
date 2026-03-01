# Proposal: sdd-cycle-prd-adr-integration

Date: 2026-03-01
Status: Draft

## Intent

Integrate PRD and ADR as optional auto-generated artifacts into the SDD cycle so that product requirements and architectural decisions are captured consistently without blocking the workflow.

## Motivation

The SDD cycle currently captures technical implementation context well (proposal, specs, design, tasks) but lacks first-class support for two artifact types that already exist as templates in the repo:

1. **PRD (Product Requirements Document)** — `docs/templates/prd-template.md` exists but is never auto-populated. When a change starts without a pre-existing PRD, product context is embedded informally inside `proposal.md`, making it harder to trace user stories and acceptance criteria back to a dedicated artifact.

2. **ADR (Architecture Decision Record)** — `docs/templates/adr-template.md` and a full `docs/adr/` index exist. However, `sdd-design` never triggers ADR creation even when it identifies a significant architectural decision. Decisions get buried inside `design.md` and are never promoted to the versioned ADR log.

Both templates and the ADR index are already referenced in `ai-context/architecture.md` as expected artifacts of the `sdd-cycle-prd-adr-integration` cycle — confirming the intent exists but the skill-level integration is missing.

## Scope

### Included

- Add a PRD auto-generation step to `skills/sdd-propose/SKILL.md`: if no PRD file is found for the change, create a pre-filled shell at `openspec/changes/<change-name>/prd.md` using `docs/templates/prd-template.md`
- Add an ADR auto-generation step to `skills/sdd-design/SKILL.md`: if the design phase identifies a significant architectural decision, create a numbered ADR file in `docs/adr/` using `docs/templates/adr-template.md` and update `docs/adr/README.md`
- Update `openspec/config.yaml` to document the two new optional artifacts in the `required_artifacts_per_change` section (annotated as optional)
- Update the SDD artifact storage section of `CLAUDE.md` to list `prd.md` and ADR files as optional outputs of the cycle

### Excluded (explicitly out of scope)

- Automated PRD generation from scratch using LLM inference — the step creates a shell from the template; the user fills in the content
- Making PRD or ADR mandatory blocking artifacts — both remain optional and non-blocking; the cycle proceeds even if skipped
- Changes to any skill other than `sdd-propose` and `sdd-design`
- Changes to the `docs/templates/` files themselves — templates are already correct
- Retroactive ADR generation for existing archived changes

## Proposed Approach

### PRD integration in sdd-propose

After `proposal.md` is written (current Step 4), a new Step 5 is added:

1. Check if a PRD already exists at `openspec/changes/<change-name>/prd.md`
2. If not, copy `docs/templates/prd-template.md` to that path and fill in the frontmatter (title from change-name, date, related-change pointer)
3. Inform the user that a PRD shell was created and is optional to complete
4. The existing "Summary to orchestrator" step becomes Step 6

### ADR integration in sdd-design

After `design.md` is written (current Step 3), a new Step 4 is added:

1. Scan the Technical Decisions table in `design.md` for decisions flagged as architecturally significant (heuristic: affects cross-cutting concerns, introduces a new pattern, or changes a previously documented convention)
2. If at least one such decision is found:
   a. Determine the next sequential ADR number from `docs/adr/README.md`
   b. Create `docs/adr/NNN-<slug>.md` from `docs/templates/adr-template.md` pre-filled with the decision context
   c. Append the new ADR entry to `docs/adr/README.md`
3. If no significant decision is found, skip silently
4. Report any created ADR files in the output artifact list

### Documentation updates

- `openspec/config.yaml`: add `prd.md` and ADR entries under a new `optional_artifacts` key alongside the existing `required_artifacts_per_change`
- `CLAUDE.md`: update the SDD Artifact Storage section to show `prd.md` (optional) under the change directory and `docs/adr/NNN-*.md` (optional, produced by design) in the overall artifact tree

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-propose/SKILL.md` | Modified | Medium — adds a new step to an existing skill |
| `skills/sdd-design/SKILL.md` | Modified | Medium — adds a new step with ADR detection logic |
| `openspec/config.yaml` | Modified | Low — documentation-only addition of optional artifact keys |
| `CLAUDE.md` | Modified | Low — artifact storage section update |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PRD shell creation fails if `docs/templates/prd-template.md` is absent | Low | Medium | sdd-propose checks for template existence; if missing, logs a warning and skips — does not block proposal |
| ADR detection heuristic produces false positives (creates ADRs for minor decisions) | Medium | Low | The heuristic is conservative; the user can delete a spurious ADR file; no downstream process depends on ADR count |
| ADR numbering collision if two parallel changes both try to create ADRs | Low | Low | sdd-design reads the current README.md count at runtime; parallel runs are unlikely in this single-user config repo |
| `docs/adr/README.md` gets out of sync with actual ADR files | Low | Low | sdd-design always appends to README.md when it creates an ADR; the index stays accurate |

## Rollback Plan

1. Revert `skills/sdd-propose/SKILL.md` to the previous version via `git revert` or manual restoration from git history
2. Revert `skills/sdd-design/SKILL.md` to the previous version via `git revert` or manual restoration from git history
3. Remove the `optional_artifacts` key added to `openspec/config.yaml`
4. Revert the CLAUDE.md artifact storage section to remove the `prd.md` and ADR references
5. Run `install.sh` to redeploy the reverted skills to `~/.claude/`
6. Any `prd.md` files or ADR files already created by the new skill versions are inert — they can be left in place or deleted manually

No data migrations required. All changes are additive file modifications.

## Dependencies

- `docs/templates/prd-template.md` must exist (confirmed: present)
- `docs/templates/adr-template.md` must exist (confirmed: present)
- `docs/adr/README.md` must exist (confirmed: present)
- No external tool or package dependencies

## Success Criteria

- [ ] Running `/sdd-propose <change>` on a change with no pre-existing PRD creates `openspec/changes/<change>/prd.md` pre-filled from the template
- [ ] Running `/sdd-propose <change>` on a change that already has a `prd.md` does NOT overwrite it
- [ ] Running `/sdd-design <change>` on a change whose design contains a significant architectural decision creates a new `docs/adr/NNN-<slug>.md` and appends an entry to `docs/adr/README.md`
- [ ] Running `/sdd-design <change>` on a change with no significant architectural decision creates no ADR files
- [ ] The SDD cycle completes normally when PRD generation is skipped (template absent) — no hard failure
- [ ] `openspec/config.yaml` documents `prd.md` and ADR files as optional artifacts
- [ ] `CLAUDE.md` artifact storage section reflects the two new optional outputs

## Effort Estimate

Low (hours) — all changes are additions to existing SKILL.md files and documentation updates; no new infrastructure or dependencies required
