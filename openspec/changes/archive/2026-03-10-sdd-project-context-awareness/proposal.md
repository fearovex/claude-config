# Proposal: sdd-project-context-awareness

Date: 2026-03-10
Status: Draft

## Intent

Enable SDD sub-agents to receive rich project context (ai-context/ files, project metadata, configuration rules) when launched, improving decision quality and consistency across all SDD phases.

## Motivation

Currently, each SDD sub-agent (sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive) is launched with minimal context: only the project path, change name, and list of prior artifacts. Sub-agents must re-read the same files (CLAUDE.md, openspec/config.yaml, ai-context/architecture.md, etc.) independently, creating duplication and increasing latency.

More importantly, sub-agents have no direct access to:
- Project memory (conventions.md, known-issues.md, changelog-ai.md)
- Feature domain knowledge (ai-context/features/ files — especially the domain preload from Step 0)
- Stack metadata (ai-context/stack.md)
- Project-specific SDD rules (openspec/config.yaml rules/ section)

This context gap forces sub-agents to make generic decisions instead of project-aligned ones. The orchestrator also has no visibility into what context each sub-agent received, making debugging and audit trails harder.

## Scope

### Included

- Define a **Context Capsule** schema (YAML/JSON) containing project metadata, memory files, feature knowledge, and SDD rules
- Modify the sub-agent launch pattern in CLAUDE.md (How I Execute Commands → SDD Orchestrator → Sub-agent launch pattern section) to include the Context Capsule in the Task tool prompt
- Implement Context Capsule generation in the orchestrator (via a non-blocking Step 0 in sdd-ff and sdd-new)
- Update sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify to read and consume the capsule in their Step 0 (or equivalent early step)
- Document the Context Capsule schema in ai-context/architecture.md or a new docs/context-capsule.md reference

### Excluded (explicitly out of scope)

- Retroactive context push to existing projects (projects manage their own context via ai-context/)
- Modification of openspec/config.yaml format or structure (context is derived from existing config, not new data)
- Changes to the Task tool itself or Claude Code runtime (we work within current Skill.md / Task tool constraints)
- Automated context caching or memoization (context is re-generated per sub-agent launch for freshness)
- Context versioning or conflict resolution (context is point-in-time read; no merge logic needed)

## Proposed Approach

1. **Context Capsule Schema**: A structured object containing:
   - `project_path`: Absolute path to the project root
   - `project_name`: Name from openspec/config.yaml
   - `timestamp`: ISO 8601 timestamp of capsule generation
   - `memory_layer`: Inlined contents of ai-context/{stack, architecture, conventions, known-issues, changelog-ai}.md
   - `feature_knowledge`: Indexed object of ai-context/features/<domain>.md files (keyed by domain slug)
   - `sdd_rules`: Project-specific rules extracted from openspec/config.yaml (proposal, specs, design, tasks, apply, verify rules)
   - `change_context`: Change name, prior artifact paths, exploration summary (if exists)

2. **Orchestrator integration** (sdd-ff, sdd-new):
   - After STEP 1 (read prior context), add a non-blocking STEP 2 that generates the Context Capsule
   - Pass the capsule as a structured YAML block in the Task tool prompt (clearly delimited with markers like `<<CONTEXT_CAPSULE_BEGIN>>` and `<<CONTEXT_CAPSULE_END>>`)
   - Document the capsule location and format in sub-agent instructions

3. **Sub-agent consumption** (sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify):
   - Add a non-blocking Step 0 (or Step 0a) that reads the Context Capsule from the Task tool prompt
   - Extract memory_layer and feature_knowledge sections for use in domain preload and architectural coherence checks
   - Use sdd_rules to validate proposal / spec / design / tasks against project conventions
   - Log capsule version and loaded memory files in the orchestrator-facing summary

4. **Documentation**:
   - Update CLAUDE.md sub-agent launch pattern section with capsule format (inline example)
   - Add a reference document describing the capsule schema, generation, and consumption workflow

## Affected Areas

| Area/Module | Type of Change | Impact |
|------------|---|---|
| CLAUDE.md (How I Execute Commands section) | Modified | Sub-agent launch pattern now includes Context Capsule block |
| sdd-ff SKILL.md | Modified | New Step 2 (capsule generation) after Step 1 |
| sdd-new SKILL.md | Modified | New Step 2 (capsule generation) after Step 1 |
| sdd-propose SKILL.md | Modified | New Step 0 (capsule read) before existing Step 0 (domain preload) |
| sdd-spec SKILL.md | Modified | New Step 0 (capsule read) before existing Step 0 (domain preload) |
| sdd-design SKILL.md | Modified | New Step 0 (capsule read) before existing Step 0 |
| sdd-tasks SKILL.md | Modified | New Step 0 (capsule read) |
| sdd-apply SKILL.md | Modified | New Step 0 (capsule read) |
| sdd-verify SKILL.md | Modified | New Step 0 (capsule read) |
| ai-context/architecture.md | New section | Context Capsule schema and workflow documentation |
| Orchestrator decision quality | New | Project-aware phase decisions (medium impact) |

## Risks

| Risk | Probability | Impact | Mitigation |
|-----|---|---|---|
| Capsule read failure (missing ai-context/ files) | Medium | Sub-agents fall back to project-generic decisions; non-blocking | Context Capsule generation is non-blocking; sub-agents already handle missing files gracefully in Step 0 |
| Capsule payload size exceeds Task tool limits | Low | Sub-agent launch fails silently | Set a reasonable capsule size ceiling (memory_layer + feature_knowledge max 50KB); compress if needed; document ceiling in schema |
| Sub-agents ignore or misuse capsule | Medium | No improvement in decision quality | Sub-agent SKILL.md updates explicitly require capsule consumption in Step 0; audit-report.md D7 (sub-agent quality) can detect non-compliance |
| Orchestrator → sub-agent communication lag (prompt size) | Low | Longer prompt tokens per launch | Capsule is structured data (YAML), not prose; typically <5KB for small projects |
| Drift between capsule and reality (stale memory files) | Low | Sub-agents use outdated conventions | Capsule is generated fresh per sub-agent launch; no caching; memory files are updated via memory-update |

## Rollback Plan

1. Remove Context Capsule generation Step 2 from sdd-ff and sdd-new SKILL.md
2. Remove Context Capsule read Step 0 from all SDD phase skills (sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify)
3. Revert CLAUDE.md sub-agent launch pattern to prior version (without capsule block)
4. Delete ai-context/architecture.md Context Capsule schema section (or revert to prior version)
5. Confirm `/project-audit` score >= baseline (should remain stable or improve)
6. Run `/sdd-status` to verify no active changes are affected
7. Git commit revert with message: "Revert: remove sdd-project-context-awareness (reason: <reason>)"

## Dependencies

- All SDD phase skills (sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify) must exist and be deployable
- ai-context/ directory and ai-context/{stack, architecture, conventions, known-issues, changelog-ai}.md files must exist (non-blocking if missing; capsule skips them)
- openspec/config.yaml must exist and be parseable (non-blocking; defaults to empty rules if missing)
- Task tool must support passing structured YAML blocks in the prompt (already used in sdd-ff and sdd-new)

## Success Criteria

- [ ] Context Capsule schema is documented and accessible to all SDD phase skills
- [ ] sdd-ff and sdd-new generate Context Capsule and pass it to sub-agent launches (verifiable by inspecting Task tool output in a test project)
- [ ] Each SDD phase skill (sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify) reads and logs capsule consumption in its summary
- [ ] Sub-agents use capsule memory_layer and feature_knowledge to improve decisions (verifiable by comparing proposals/specs/designs before/after on a real project)
- [ ] `/project-audit` score on claude-config >= 98/100 (prior score before this change)
- [ ] No regression in sub-agent launch latency (capsule generation + read should be <2s combined)
- [ ] Feedback from test project (e.g., Audiio V3) shows at least one observable improvement in SDD decision quality (e.g., spec references project conventions, proposal references feature domain knowledge)

## Effort Estimate

Medium (1–2 days)

- Day 1: Schema definition, sdd-ff/sdd-new integration, sub-agent Step 0 updates (4–5 hours)
- Day 2: Documentation, testing on Audiio V3 project, /project-audit verification, rollback plan validation (3–4 hours)
