---
name: sdd-design
description: >
  Produces the technical design with architecture decisions, data flow, and a file change plan.
  Trigger: /sdd-design <change-name>, technical design, change architecture, how to implement.
format: procedural
model: sonnet
thinking: enabled
---

# sdd-design

> Produces the technical design with architecture decisions, data flow, and a file change plan.

**Triggers**: `/sdd-design <change-name>`, technical design, change architecture, sdd design

---

## Purpose

The design defines **HOW to implement** what the specs say the system MUST do. It is the bridge between requirements and code. It documents technical decisions and their justification.

---

## Process

### Skill Resolution

When the orchestrator launches this sub-agent, it resolves the skill path using:

```
1. .claude/skills/sdd-design/SKILL.md     (project-local — highest priority)
2. openspec/config.yaml skill_overrides   (explicit redirect)
3. ~/.claude/skills/sdd-design/SKILL.md   (global catalog — fallback)
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

- `openspec/changes/<change-name>/proposal.md`
- `openspec/changes/<change-name>/specs/` (all spec.md files)
- `ai-context/architecture.md` if it exists
- `ai-context/conventions.md` if it exists

Then I read real code:

- Relevant entry points
- Files that will be affected according to the proposal
- Existing patterns to follow (not reinvent)
- Existing tests (they reveal current contracts)

### Step 2 — Design the technical solution

I evaluate the solution considering:

- Patterns already used in the project (prefer consistency)
- Minimal impact on existing code
- Testability
- Reversibility (rollback plan from the proposal)

#### Skills Registry cross-reference

When recommending a skill, library, or technology pattern in the design, I MUST check the project Skills Registry extracted in Step 0 and follow these rules:

- **Registered skill**: reference it by its exact registered name (e.g., `typescript`, `react-19`).
- **Global catalog skill, not registered in project**: mark it as optional with a note, e.g. `[optional — not registered in project; add via /skill-add <name>]`.
- **Skill not in the global catalog**: state it as a new dependency and flag it for review.

This check applies to the Technical Decisions table, the Testing Strategy table, and any inline recommendations in the design narrative. It ensures design output stays aligned with the project's declared toolset.

### Step 3 — Create design.md

I create `openspec/changes/<change-name>/design.md`:

```markdown
# Technical Design: [change-name]

Date: [YYYY-MM-DD]
Proposal: openspec/changes/[name]/proposal.md

## General Approach

[High-level description of the technical solution in 3-5 lines]

## Technical Decisions

| Decision   | Choice           | Discarded Alternatives         | Justification     |
| ---------- | ---------------- | ------------------------------ | ----------------- |
| [decision] | [what is chosen] | [alternative A, alternative B] | [why this choice] |

## Data Flow

[ASCII diagram or description of the flow]

Example:
```

Request → Middleware → Controller → Service → Repository → DB
↓
Validator (Zod)
↓
Response DTO

````

## File Change Matrix
| File | Action | What is added/modified |
|------|--------|------------------------|
| `src/modules/auth/auth.service.ts` | Modify | Add `refreshToken()` method |
| `src/modules/auth/auth.controller.ts` | Modify | New endpoint POST /auth/refresh |
| `src/modules/auth/dto/refresh.dto.ts` | Create | DTO for refresh request |
| `src/modules/auth/auth.module.ts` | Modify | Register new provider |
| `tests/auth/refresh-token.spec.ts` | Create | Tests for the new endpoint |

## Interfaces and Contracts
[Type definitions, interfaces, DTOs, schemas to be created]

```typescript
// Example
interface RefreshTokenRequest {
  refreshToken: string;
}

interface RefreshTokenResponse {
  accessToken: string;
  expiresIn: number;
}
````

## Testing Strategy

| Layer       | What to test              | Tool                 |
| ----------- | ------------------------- | -------------------- |
| Unit        | [service/function]        | [jest/vitest/pytest] |
| Integration | [endpoint/module]         | [supertest/httpx]    |
| E2E         | [full flow if applicable] | [playwright/cypress] |

## Migration Plan

[If there are changes to DB, schema, or existing data:]

- Step 1: [migration script]
- Step 2: [gradual rollout if applicable]
- Step 3: [post-cleanup]

[If no migration: "No data migration required."]

## Open Questions

[Aspects that need clarification before implementing]

- [question]: [impact if not resolved]

[If none: "None."]

````

### Step 4 — ADR Detection and Generation

This step is **non-blocking**: any failure produces a warning in the output, never `status: blocked` or `status: failed`.

1. **Scan for significant decisions**: read the Technical Decisions table in the newly created `design.md`. For each row, check whether the text (across all columns) contains any of the following keywords (case-insensitive):
   `pattern`, `convention`, `cross-cutting`, `replaces`, `introduces`, `architecture`, `global`, `system-wide`, `breaking`

2. **No match → skip silently**: if no row matches any keyword, do nothing and produce no output for this step.

3. **Match found → generate ADR**:
   a. **Prerequisite check**: if `docs/templates/adr-template.md` does not exist OR `docs/adr/README.md` does not exist, log the warning `"ADR infrastructure not found (docs/templates/adr-template.md or docs/adr/README.md missing) — skipping ADR generation"` and stop this step.
   b. **Determine next ADR number**: count existing files matching `docs/adr/[0-9][0-9][0-9]-*.md`. The next number is `count + 1`, zero-padded to 3 digits (e.g., `001`, `012`, `100`).
   c. **Derive slug**: `<NNN>-<change-name>[-<first-matched-keyword>]`, all lowercase, spaces replaced with hyphens, non-alphanumeric characters (except hyphens) removed, truncated to 50 characters.
   d. **Copy template**: copy `docs/templates/adr-template.md` to `docs/adr/<slug>.md`.
   e. **Pre-fill content** in the new ADR file:
      - Title (H1): derived from the slug (replace hyphens with spaces, title-case)
      - Status: `Proposed`
      - Context section: content from the **Justification** column of the first matched row
      - Decision section: content from the **Choice** column of the first matched row
   f. **Update index**: append a new row to the ADR index table in `docs/adr/README.md`:
      `| [NNN] | [Title] | Proposed | [YYYY-MM-DD] | [brief one-line context] |`
   g. **Artifacts**: add `docs/adr/<slug>.md` to the artifacts list.

---

## Examples of well-documented decisions

### Well documented
```markdown
| Input validation | Zod at controller layer | Class-validator, manual |
The project already uses Zod for DB schemas (Drizzle).
Maintaining consistency avoids two validation systems. |
````

### Poorly documented

```markdown
| Validation | Zod | others | It's better |
```

---

## Useful ASCII diagrams

```
# Authentication flow
Client → POST /auth/login
            ↓
        AuthController
            ↓
        AuthService.validateCredentials()
            ↓
        UserRepository.findByEmail()
            ↓
        bcrypt.compare(password, hash)
            ↓ (success)
        JwtService.sign(payload)
            ↓
        Response { token, refreshToken }

# Module structure
auth/
├── auth.module.ts
├── auth.controller.ts
├── auth.service.ts
├── strategies/
│   ├── jwt.strategy.ts
│   └── local.strategy.ts
└── dto/
    ├── login.dto.ts
    └── refresh.dto.ts
```

### Step 5 — Summary to orchestrator

I return a clear executive summary to the orchestrator with all artifacts produced (design.md and any ADR file created in Step 4).

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "summary": "Design for [change-name]: [N] affected files, approach [brief description], risk [level].",
  "artifacts": ["openspec/changes/<name>/design.md"],
  "next_recommended": ["sdd-tasks (requires spec + design completed)"],
  "risks": ["[technical risk if found]"]
}
```

---

## Rules

- ALWAYS read real code before designing — never assume the structure
- Every decision MUST have justification (the "why", not just the "what")
- Follow existing project patterns unless the change explicitly corrects them
- The file matrix must be concrete (real paths, not "some auth file")
- ASCII diagrams are preferable to long descriptions
- If I detect that the proposal is incompatible with the current architecture, I report it as a blocker
- I do NOT write implementation code — that is `sdd-apply`
