# sdd-tasks

> Breaks down the design into an atomic, ordered, and verifiable task plan.

**Triggers**: sdd:tasks, task plan, break down implementation, task breakdown, sdd tasks

---

## Purpose

The task plan converts the design into an **executable work list**. Each task is atomic (one single thing), concrete (has a file path), and verifiable (can be marked as done).

It is the input for `sdd-apply`. Without an approved tasks file, nothing gets implemented.

---

## Process

### Step 1 — Read prior artifacts

I must read:
- `openspec/changes/<change-name>/design.md` (the file matrix and approach)
- `openspec/changes/<change-name>/specs/` (the success criteria)
- `openspec/config.yaml` if it exists (project rules)

### Step 2 — Analyze dependencies between tasks

I identify the natural implementation order:
- Types/interfaces before their usage
- Providers/services before their consumers
- Schema/migration before the code that uses them
- Unit tests alongside the code (not at the end)

### Step 3 — Organize into phases

I group tasks into logical phases:

```
Phase 1 — Foundation: types, interfaces, schemas, configuration
Phase 2 — Core: main business logic
Phase 3 — Integration: connect with the rest of the system
Phase 4 — Testing: tests for previous phases
Phase 5 — Cleanup: remove temporary code, update docs
```

(I adapt phase names to the context of the change)

### Step 4 — Create tasks.md

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
- [ ] 5.2 Update `docs/ai-context/architecture.md` if there were structural changes

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

```json
{
  "status": "ok|warning|blocked",
  "resumen": "Plan for [change-name]: [N] phases, [M] total tasks. Estimate: [Low/Medium/High].",
  "artefactos": ["openspec/changes/<name>/tasks.md"],
  "next_recommended": ["sdd-apply"],
  "riesgos": ["[blocker if any]"]
}
```

---

## Rules

- Each task MUST have a concrete file path
- Each task MUST be atomic (single responsibility)
- Each task MUST be verifiable (can be marked done with certainty)
- Tests go with their code, not all at the end
- Phase order respects technical dependencies
- Documentation and memory tasks (ai-context) go in the last phase
- I do NOT include tasks that go beyond the proposal's scope
- If I detect that the design is incomplete to generate tasks, I report it as a blocker
