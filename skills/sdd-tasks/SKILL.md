---
name: sdd-tasks
description: >
  Breaks down the design into an atomic, ordered, and verifiable task plan stored in tasks.md.
  Trigger: /sdd-tasks <change-name>, task plan, break down implementation, task breakdown.
format: procedural
model: sonnet
---

# sdd-tasks

> Breaks down the design into an atomic, ordered, and verifiable task plan.

**Triggers**: `/sdd-tasks <change-name>`, task plan, break down implementation, task breakdown, sdd tasks

---

## Purpose

The task plan converts the design into an **executable work list**. Each task is atomic (one single thing), concrete (has a file path), and verifiable (can be marked as done).

It is the input for `sdd-apply`. Without an approved tasks file, nothing gets implemented.

---

## Process

### Skill Resolution

When the orchestrator launches this sub-agent, it resolves the skill path using:

```
1. .claude/skills/sdd-tasks/SKILL.md     (project-local — highest priority)
2. openspec/config.yaml skill_overrides  (explicit redirect)
3. ~/.claude/skills/sdd-tasks/SKILL.md   (global catalog — fallback)
```

Project-local skills override the global catalog. See `docs/SKILL-RESOLUTION.md` for the full algorithm.

---

### Step 0 — Load project context

This step is **non-blocking**: any failure (missing file, unreadable file) MUST produce
at most an INFO-level note. This step MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the full project `CLAUDE.md` (at project root). Extract and log:
   - Count of items listed under `## Unbreakable Rules`
   - Value of the primary language from `## Tech Stack`
   - Whether `intent_classification:` is `disabled` (check for Override section)
   Output a single governance log line:
   `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`
   If CLAUDE.md is absent: log `INFO: project CLAUDE.md not found — governance falls back to global defaults.`

For each file:
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-update or /project-analyze.`

Loaded context is used as enrichment throughout all subsequent steps. It informs architectural
coherence, naming consistency, and skill alignment checks—but does NOT override explicit
content in the proposal or design.

### Step 0 sub-step — Spec context preload

This sub-step is **non-blocking**: any failure (missing directory, unreadable file, no match) MUST produce at most an INFO-level note. This sub-step MUST NOT produce `status: blocked` or `status: failed`.

1. **List candidates**: list subdirectory names in `openspec/specs/`. If the directory does not exist, log `INFO: openspec/specs/ not found — skipping spec context preload` and skip this sub-step.

2. **Apply stem matching**:
   ```
   stems = change_name.split("-").filter(s => s.length > 1)
   matches = []
   for domain in candidates:
     if domain in change_name OR any stem in domain:
       matches.append(domain)
   matches = matches[:3]   ← hard cap at 3
   ```

3. **Load matches**: for each matched domain, read `openspec/specs/<domain>/spec.md` and treat its content as an **authoritative behavioral contract** (precedence over `ai-context/` for behavioral questions; `ai-context/` remains supplementary for architecture and naming context). If a file cannot be read, log an INFO note and skip that file.

4. **If no match**: skip silently — proceed to Step 1 without error or warning.

5. **When files are loaded**: emit the log line `Spec context loaded from: [domain/spec.md, ...]` and include the loaded paths in the artifacts list (read, not written).

See `docs/SPEC-CONTEXT.md` for the full convention reference, load cap rationale, and fallback behavior.

---

### Step 1 — Read prior artifacts

I must read:

- `openspec/changes/<change-name>/design.md` (the file matrix and approach)
- `openspec/changes/<change-name>/specs/` (the success criteria)
- `openspec/config.yaml` if it exists (project rules)
- `openspec/changes/<change-name>/proposal.md` — specifically the `## Supersedes` section

### Step 2 — Analyze dependencies between tasks

I identify the natural implementation order:

- Types/interfaces before their usage
- Providers/services before their consumers
- Schema/migration before the code that uses them
- Unit tests alongside the code (not at the end)
- **Removals and replacements BEFORE additions** (see Step 3 below)

### Step 3 — Generate removal tasks from Supersedes section

#### Step 3a — Check Supersedes

1. Read `## Supersedes` from proposal.md.
2. **If section is absent** (older archived change): log `INFO: no Supersedes section in proposal.md — skipping removal task generation` and proceed to Step 4 with standard phase organization.
3. **If section states "None — purely additive change"**: skip removal task generation; proceed to Step 4.
4. **If section has REMOVED or REPLACED items**: proceed to Step 3b.

#### Step 3b — Generate removal/replacement tasks

For each **REMOVED** item in Supersedes:
- Generate one task titled `Remove: [feature name]` with:
  - File paths to delete or modify
  - Acceptance criterion: "File deleted AND no runtime errors in related flows"
  - Spec reference: linked spec requirement name (if spec exists for this removal)

For each **REPLACED** item in Supersedes:
- Generate two tasks in dependency order:
  1. `Remove old: [old feature name]` — delete/unregister the old implementation
  2. `Implement new: [new feature name]` — add the replacement (link to spec requirement)
- Note explicit dependency: task 2 cannot start until task 1 is complete.

#### Step 3c — Phase 1 organization

All removal and replacement tasks (from Step 3b) MUST be grouped into **Phase 1: Removals and Replacements**. Standard addition/implementation tasks start from Phase 2 or later. Phase 2 MUST NOT begin until Phase 1 is complete — enforce this with an explicit sequencing note in tasks.md.

**Removal task format:**
```markdown
### Phase 1: Removals and Replacements

- [ ] 1.1 Remove: [feature name] from `path/to/file`
  Linked spec: [Requirement name from spec, or "N/A — no spec for this removal"]
  Files: `path/to/file` (DELETE), `path/to/other.ts` (remove registration/import)
  Acceptance: File deleted AND related flows continue without runtime errors

- [ ] 1.2 Remove old: [old feature name] from `path/to/old-file`
  Linked spec: [Requirement: Replacement requirement name]
  Files: `path/to/old-file` (DELETE or MODIFY)
  Acceptance: Old implementation fully removed; no lingering imports or references

- [ ] 1.3 Implement new: [new feature name] in `path/to/new-file`
  Linked spec: [Requirement: new feature requirement]
  Depends on: 1.2
  Files: `path/to/new-file` (CREATE or MODIFY)
  Acceptance: New implementation active; spec scenarios pass

---
⚠️ Phase 2 MUST NOT begin until all Phase 1 tasks are complete.
---
```

### Step 4 — Organize addition tasks into phases

I group addition/implementation tasks into logical phases after Phase 1 (or Phase 1 if no removals):

```
Phase 1 — Removals and Replacements [if Supersedes has items] OR Foundation [if purely additive]
Phase 2 — Foundation: types, interfaces, schemas, configuration [if Phase 1 is Removals]
Phase N — Core: main business logic
Phase N+1 — Integration: connect with the rest of the system
Phase N+2 — Testing: tests for previous phases
Phase N+3 — Cleanup: remove temporary code, update docs
```

(I adapt phase names to the context of the change)

### Step 5 — Create tasks.md

#### Step 4a — Warning Classification Rules

While analyzing each task, I MUST identify ambiguities, risks, or open decisions that could affect implementation. For each one found, I classify it as one of:

- **`MUST_RESOLVE`** — A warning that blocks implementation until the user provides an explicit answer. Use this when:
  - The task involves a business rule decision that has multiple valid interpretations
  - The task depends on an external system behavior that is ambiguous (e.g., which field to use in an API response)
  - The task cannot be implemented correctly without knowing the user's intent
  - Example reason: `"business rule decision — external system behavior is ambiguous"`

- **`ADVISORY`** — A warning that is logged for awareness but does not block implementation. Use this when:
  - The concern is a performance consideration that does not affect functional correctness
  - The concern is a style or naming preference with no impact on task completion
  - The concern is informational and the implementer can safely proceed without further input
  - Example reason: `"performance consideration — does not affect correctness"`
  - Example reason: `"style or naming preference — no impact on current task"`

Each warning classification MUST include a reason statement explaining why it belongs in its category.

#### Step 4b — Record warnings in tasks.md

Every warning identified in Step 4a MUST be recorded inline with the affected task in `tasks.md`, using the following formats:

**MUST_RESOLVE format:**

```markdown
- [ ] X.Y Task description [WARNING: MUST_RESOLVE]
  Warning: [human-readable warning text]
  Reason: [classification reason, e.g., "business rule decision — external system field ambiguous"]
  Question: [clarifying question derived from the warning]
```

**ADVISORY format:**

```markdown
- [ ] X.Y Task description [WARNING: ADVISORY]
  Warning: [human-readable warning text]
  Reason: [classification reason, e.g., "performance consideration — does not affect correctness"]
```

Placement rules:
- Warnings appear immediately below their task entry, indented with two spaces
- A task may have at most one warning entry (combine multiple concerns into one if needed)
- Tasks without warnings have no indented block below them

**Example task with MUST_RESOLVE warning:**

```markdown
- [ ] 2.1 Create `src/services/payment.service.ts` with method `processPayment(dto: PaymentDto): Promise<PaymentResult>` [WARNING: MUST_RESOLVE]
  Warning: Stripe invoice field for failure date is ambiguous — `status_transitions.marked_uncollectible_at` vs `status_transitions.voided_at` may both apply depending on invoice state.
  Reason: business rule decision — external system behavior is ambiguous
  Question: Which Stripe invoice field should be used to record the payment failure date?
```

I create `openspec/changes/<change-name>/tasks.md`:

```markdown
# Task Plan: [change-name]

Date: [YYYY-MM-DD]
Design: openspec/changes/[name]/design.md

## Progress: 0/[total] tasks

## Phase 1: [Phase Name]

- [ ] 1.1 Create `src/types/auth.types.ts` with interfaces `LoginRequest`, `LoginResponse`, `JwtPayload`
- [ ] 1.2 Create `src/schemas/auth.schema.ts` with Zod schemas for login validation
- [ ] 1.3 Modify `src/config/jwt.config.ts` — add `refreshSecret` and `refreshExpiresIn`

## Phase 2: [Phase Name]

- [ ] 2.1 Create `src/services/auth.service.ts` with methods `login()`, `logout()`, `refreshToken()`
- [ ] 2.2 Modify `src/repositories/user.repository.ts` — add `findByEmail()` method
- [ ] 2.3 Create `src/middleware/auth.middleware.ts` for JWT validation on protected routes

## Phase 3: [Phase Name]

- [ ] 3.1 Create `src/controllers/auth.controller.ts` with endpoints POST /login, POST /logout, POST /refresh
- [ ] 3.2 Modify `src/routes/index.ts` — register auth routes
- [ ] 3.3 Modify `src/app.ts` — integrate auth middleware on protected routes

## Phase 4: Testing

- [ ] 4.1 Create `tests/unit/auth.service.spec.ts` — unit tests for AuthService
- [ ] 4.2 Create `tests/integration/auth.controller.spec.ts` — endpoint tests
- [ ] 4.3 Verify scenario coverage from spec (review openspec/changes/[name]/specs/)

## Phase 5: Cleanup

- [ ] 5.1 Update `README.md` — document new endpoints
- [ ] 5.2 Update `ai-context/architecture.md` if there were structural changes

---

## Implementation Notes

[Design decisions the implementer must keep in mind:]

- [important note 1]
- [important note 2]

## Blockers

[Tasks that cannot start until something external is ready:]

- [blocker]: [what resolves it]

[If none: "None."]
```

---

## Format of a well-written task

### Well written

```
- [ ] 2.1 Create `src/services/payment.service.ts` with method `processPayment(dto: PaymentDto): Promise<PaymentResult>`
```

### Poorly written

```
- [ ] Add payment logic
```

**Rule**: Each task must answer "which file and what specific change?"

---

## Output to Orchestrator

Return ONLY this JSON block. Do NOT add free-form text, command suggestions, or implementation steps after it.

```json
{
  "status": "ok|warning|blocked",
  "summary": "Plan for [change-name]: [N] phases, [M] total tasks. Estimate: [Low/Medium/High].",
  "artifacts": ["openspec/changes/<name>/tasks.md"],
  "next_recommended": ["sdd-apply"],
  "risks": ["[blocker if any]"]
}
```

The orchestrator will present `next_recommended` to the user as `/sdd-apply` (hyphen-separated, with slash prefix). Do not format it yourself.

---

## Rules

- **HARD STOP**: My only output is `tasks.md` + the JSON block. I NEVER implement any task, write code, or modify project files beyond creating tasks.md
- Each task MUST have a concrete file path
- Each task MUST be atomic (single responsibility)
- Each task MUST be verifiable (can be marked done with certainty)
- Tests go with their code, not all at the end
- Phase order respects technical dependencies
- Documentation and memory tasks (ai-context) go in the last phase
- I do NOT include tasks that go beyond the proposal's scope
- If I detect that the design is incomplete to generate tasks, I report it as a blocker
