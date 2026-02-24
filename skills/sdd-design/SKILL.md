# sdd-design

> Produces the technical design with architecture decisions, data flow, and a file change plan.

**Triggers**: sdd:design, technical design, change architecture, technical design, sdd design

---

## Purpose

The design defines **HOW to implement** what the specs say the system MUST do. It is the bridge between requirements and code. It documents technical decisions and their justification.

---

## Process

### Step 1 — Read prior artifacts

I must read:
- `openspec/changes/<change-name>/proposal.md`
- `openspec/changes/<change-name>/specs/` (all spec.md files)
- `docs/ai-context/architecture.md` if it exists
- `docs/ai-context/conventions.md` if it exists

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

### Step 3 — Create design.md

I create `openspec/changes/<change-name>/design.md`:

```markdown
# Technical Design: [change-name]

Date: [YYYY-MM-DD]
Proposal: openspec/changes/[name]/proposal.md

## General Approach
[High-level description of the technical solution in 3-5 lines]

## Technical Decisions
| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
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
```

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
```

## Testing Strategy
| Layer | What to test | Tool |
|-------|-------------|------|
| Unit | [service/function] | [jest/vitest/pytest] |
| Integration | [endpoint/module] | [supertest/httpx] |
| E2E | [full flow if applicable] | [playwright/cypress] |

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
```

---

## Examples of well-documented decisions

### Well documented
```markdown
| Input validation | Zod at controller layer | Class-validator, manual |
The project already uses Zod for DB schemas (Drizzle).
Maintaining consistency avoids two validation systems. |
```

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

---

## Output to Orchestrator

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Design for [change-name]: [N] affected files, approach [brief description], risk [level].",
  "artefactos": ["openspec/changes/<name>/design.md"],
  "next_recommended": ["sdd-tasks (requires spec + design completed)"],
  "riesgos": ["[technical risk if found]"]
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
