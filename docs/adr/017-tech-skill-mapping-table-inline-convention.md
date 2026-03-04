# ADR-017: Tech Skill Mapping Table — Inline Convention in sdd-apply

## Status

Proposed

## Context

The claude-config skill catalog contains 21 technology skills (react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native, electron, django-drf, spring-boot-3, hexagonal-architecture-java, java-21, playwright, pytest, github-pr, jira-task, jira-epic, elixir-antipatterns, excel-expert, image-ocr). These skills encode technology-specific best practices and patterns. The `sdd-apply` skill is responsible for implementation and is the natural consumer of technology knowledge.

Before this change, `sdd-apply` contained a single vague paragraph instructing sub-agents to load "TypeScript → typescript skill, React → react-19 skill, etc." The "etc." was never defined, leading to inconsistent skill loading across apply invocations.

Two candidate locations existed for a formal mapping:
1. **`openspec/config.yaml`** — project-specific SDD config, already present in all openspec projects
2. **Inline in `sdd-apply/SKILL.md`** — self-contained within the skill itself

A shared mapping in `openspec/config.yaml` would require every project to maintain or copy the table, creating divergence risk. It would also make `sdd-apply` dependent on an external file for core behavior.

The inline approach is consistent with ADR-002 (artifacts over shared mutable state) and the existing pattern of embedding detection logic directly in skills (e.g., `sdd-apply` Step 2 TDD detection, `sdd-propose` Step 0 domain context preload).

## Decision

The Stack-to-Skill Mapping Table lives exclusively in `skills/sdd-apply/SKILL.md` as an inline Markdown table within Step 0 — Technology Skill Preload. Any new technology skill added to the catalog MUST include a new keyword row in this table as part of its own SDD cycle. This is a system-wide convention enforced by the SDD process, not by automation.

## Consequences

**Positive:**

- `sdd-apply` is self-contained and portable — it can be deployed to any `~/.claude/` installation and work correctly without project-level configuration
- The mapping is co-located with the detection logic, making it easy to audit: one file shows both the table and the algorithm
- Consistent with the existing pattern of embedding heuristics directly in skills (TDD detection, domain context preload)
- Adding a new technology skill has a clear, documented update path: add one row to the table in `sdd-apply`

**Negative:**

- The mapping table requires manual maintenance: every new technology skill addition must also update `sdd-apply/SKILL.md`
- No project-level override mechanism exists (e.g., to disable a specific skill for a project that does not want it loaded) — overrides are deferred to future work
- The mapping is not machine-readable in a structured format (YAML/JSON) — it cannot be queried programmatically by other skills without parsing Markdown
