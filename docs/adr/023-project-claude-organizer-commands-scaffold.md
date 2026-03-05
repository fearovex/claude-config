# ADR-023: Project Claude Organizer Commands Scaffold Pattern — Active SKILL.md Generation and Skills Audit Sub-Step

## Status

Proposed

## Context

The `project-claude-organizer` skill contains a `commands/` legacy directory pattern whose strategy was `delegate` (advisory-only): qualifying `.md` files in `.claude/commands/` received a console advisory telling the user to run `/skill-create <stem>`, but the organizer wrote nothing itself. This forced a manual follow-up step for every qualifying file, defeating the purpose of an automated organizer.

Separately, the organizer had no awareness of the `.claude/skills/` directory. It did not detect skills that duplicate a global catalog entry (scope-tier overlap per ADR-008), skill directories with no `SKILL.md` (broken shells), or skill directories with suspicious names. Drift in the project-local skills tier accumulated silently.

The `scaffold` strategy already exists in the LEGACY_PATTERN_TABLE for the `requirements/` pattern and produces idempotent file output. The 4-signal qualifying-marker heuristic already existed in Step 5.7.1 for detecting which `commands/` files merit attention — it was only used to gate advisory output, not to drive file generation.

## Decision

We will replace the `delegate` strategy for the `commands/` pattern with an active `scaffold` strategy. For each qualifying `.md` file in `.claude/commands/`, the organizer will generate a minimal but valid `SKILL.md` under `.claude/skills/<stem>/SKILL.md`, inferring format type from the source file's content using the existing 4-signal heuristic extended with anti-pattern and reference detection. If `.claude/skills/<stem>/SKILL.md` already exists, the operation is skipped and recorded as `[already exists]` — the additive invariant is preserved.

We will also add a new Step 3c immediately after Step 3b that enumerates all immediate subdirectories of `.claude/skills/`, applies three detection rules (scope-tier overlap against the CLAUDE.md Skills Registry, broken shell, suspicious name), and populates a `SKILL_AUDIT_FINDINGS` list consumed by the report. The report gains a new `### Skills audit` subsection presenting findings as a severity-annotated table. All findings are advisory; no files are deleted or moved by the audit step.

## Consequences

**Positive:**

- Users no longer need to issue one `/skill-create` command per qualifying `commands/` file — the organizer handles the scaffold in one invocation.
- Generated `SKILL.md` files satisfy the section contract for their inferred format, making them immediately valid for `project-audit` D4b checking.
- Scope-overlap and broken-shell findings in `.claude/skills/` are surfaced on every organizer run, reducing silent drift in the project-local skills tier.
- The `scaffold` strategy reuse is consistent with `requirements/` — no new strategy concept is introduced.

**Negative:**

- The organizer SKILL.md grows further in line count; the skills audit step adds a new conceptual phase that must be understood by contributors modifying the skill.
- Inferred format type may be incorrect for some source files — users must review generated skeletons before running `/project-audit`.
- Source files in `commands/` are not deleted by the scaffold strategy (additive invariant) and also not eligible for the cleanup prompt (exempt from cleanup like `delegate` was) — users must manually clean up `commands/` after scaffold if desired.
