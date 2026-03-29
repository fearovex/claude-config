---
name: feature-domain-expert
description: >
  Authors and consumes feature-level domain knowledge files in ai-context/features/.
  Reference guide for bounded-context business rules, invariants, integration points, and known gotchas.
format: reference
---

# feature-domain-expert

> Authoritative guide for authoring and consuming feature knowledge files in `ai-context/features/`.

**Triggers**: feature file, domain knowledge, ai-context/features, bounded context, business rules,
feature-domain-expert, domain invariants, domain context, feature doc

---

## Patterns

### Pattern 1: Feature file vs. SDD spec — the critical distinction

These two file types serve fundamentally different purposes and MUST NOT duplicate each other's
content:

| Aspect | `ai-context/features/<domain>.md` | SDD spec (engram artifact) |
|--------|----------------------------------|----------------------------------|
| **Purpose** | Permanent business domain knowledge | Behavioral delta spec for a specific change |
| **Lifetime** | Lives forever — updated but never deleted | Created per change — eventually archived |
| **Content** | Business rules, invariants, data model, integration contracts, history | GIVEN/WHEN/THEN scenarios describing observable behavior for one change |
| **When written** | Once per bounded context; updated via `/memory-update` | Once per SDD change; archived with the change |
| **Who reads it** | `sdd-propose` Step 0, `sdd-spec` Step 0, human developers | `sdd-apply` (acceptance criteria), `sdd-verify` |
| **Cross-change value** | High — encodes knowledge that predates and outlasts any single change | Low — describes behavior introduced or modified by one specific change |

**Rule**: if you are writing GIVEN/WHEN/THEN scenarios, it belongs in a SDD spec artifact. If you
are writing a business rule that will still be true five SDD cycles from now, it belongs in
`ai-context/features/`.

---

### Pattern 2: When to create a feature file

Create a new `ai-context/features/<domain>.md` when ALL of the following are true:

1. A bounded context (a coherent area of business logic with its own vocabulary) has been
   identified — either by working in it during an SDD cycle or during `memory-init`.
2. The domain has at least one business rule or invariant that is not captured in any spec file and
   that future SDD phases should know about.
3. The domain is likely to be touched again in future SDD cycles (i.e., it is not a one-off
   technical implementation detail).

Do NOT create a feature file for:
- Pure infrastructure concerns with no business rules (e.g., CI pipeline configuration).
- A domain whose knowledge is already fully expressed in a small, stable spec file that will never
  be archived.
- Domains that have not yet been explored — create a stub via `memory-init` and leave sections
  empty until knowledge is acquired.

---

### Pattern 3: What belongs in each of the six sections

The canonical six sections in order — every feature file must contain all six:

**1. Domain Overview**
Write 2–4 sentences describing what the bounded context does, who owns it, and what core
responsibility it holds in the system. Focus on purpose and scope, not implementation details.

**2. Business Rules and Invariants**
List the always-true constraints the domain enforces regardless of code path. Each item is a
declarative statement that would still hold even if the implementation were rewritten from scratch.
Examples: "A refund cannot exceed the original payment amount." "A user must have a verified email
before making a purchase."

**3. Data Model Summary**
Describe key entities, their relationships, and critical field constraints in plain prose or a
small table. This is not a full schema — orient the reader to the most important entities and their
constraints. Relationships between entities belong here.

**4. Integration Points**
Document every external system, service, or domain this bounded context depends on or exposes an
interface to. Use a table with columns: System/Service, Direction (inbound/outbound), Contract.
Include async contracts (events, queues) and third-party dependencies.

**5. Decision Log**
A chronological record of significant design or implementation decisions made for this domain.
Each entry must state: what was decided, the rationale, and what it constrains going forward.
Entries are NEVER deleted — they provide historical context for future developers.

**6. Known Gotchas**
Unexpected behaviors, operational hazards, historical defects, or non-obvious constraints that a
developer working in this domain must be aware of. Include things that caused bugs in the past,
edge cases that are easy to miss, and anything that tripped up previous contributors.

---

### Pattern 4: Domain slug matching heuristic (used by sdd-propose Step 0 and sdd-spec Step 0)

When an SDD phase runs for `<change-name>`, it determines which feature files to preload using
this algorithm:

```
Input:  change-name (kebab-case string)
Output: list of matching ai-context/features/<domain>.md paths (may be empty)

Algorithm:
  1. If ai-context/features/ does not exist → return [] (skip silently)
  2. List all .md files in ai-context/features/
  3. Exclude any file whose name starts with underscore (e.g. _template.md)
  4. Extract stems: split change-name on "-", discard single-char stems
  5. For each remaining file f:
       domain = filename stem of f (without .md extension)
       if domain appears in change-name
         OR any stem from step 4 appears in domain:
         add f to matches
  6. Return all matches (may be multiple files)
  7. If matches is empty → skip preload silently (no error, no warning)
```

Examples:

| Change name | Stems (after filtering) | Matches |
|-------------|------------------------|---------|
| `add-payments-gateway` | `[add, payments, gateway]` | `features/payments.md` — "payments" stem appears in domain |
| `auth-token-refresh` | `[auth, token, refresh]` | `features/auth.md` — "auth" stem appears in domain |
| `feature-domain-knowledge-layer` | `[feature, domain, knowledge, layer]` | No match against `sdd-meta-system.md` — none of the stems appear in "sdd-meta-system" and "sdd-meta-system" does not appear in the change name |
| `improve-project-audit` | `[improve, project, audit]` | No match — stems do not appear in any domain slug |

Key behaviors:
- `_template.md` is ALWAYS excluded — it is never a preload candidate.
- The match is bidirectional: domain-in-change-name OR change-stem-in-domain.
- Multiple files may match — all are loaded as enrichment context.
- A non-match is NOT an error: the phase proceeds normally without domain context.

---

### Pattern 5: Updating a feature file via /memory-update

Feature files follow an **append-only** update discipline. When `/memory-update` runs after a
session that involved a domain with an existing feature file:

1. **Business Rules and Invariants**: append newly discovered rules as new list items. Never
   remove or reword existing rules unless they are factually wrong (in which case add a correction
   note below the original rule instead of deleting it).
2. **Decision Log**: append a new dated entry for any domain decision made during the session.
   Entries are never deleted or reordered.
3. **Known Gotchas**: append new gotchas discovered during the session. Never remove a gotcha
   — even if the underlying bug was fixed, a note about the former behavior is useful history.
4. **Other sections**: update Data Model Summary and Integration Points if new entities or
   integrations were introduced. Domain Overview may be updated if the scope of the domain changed
   significantly.

`/memory-update` MUST NOT create new feature files — it only updates existing ones. New feature
files are created manually or scaffolded by `memory-init`.

Respect `[auto-updated]` section boundaries if present (same convention as in other ai-context
files).

---

### Pattern 6: Worked example — the sdd-meta-system domain

The canonical worked example for this skill is `ai-context/features/sdd-meta-system.md` in the
`agent-config` repository. It demonstrates all six sections with realistic content for the SDD
meta-system bounded context.

Below is an abbreviated illustration of the pattern each section should follow:

**Domain Overview** (2–4 sentences of purpose and scope):
> "The SDD meta-system is the Claude Code configuration and skill orchestration framework...
> It provides two primary capabilities: a library of reusable skills and an SDD phase pipeline...
> The system is self-hosting: changes to its own skills must follow the same SDD cycle."

**Business Rules and Invariants** (declarative always-true statements):
```
- Every skill modification MUST go through the SDD planning cycle (at minimum /sdd-propose) before /sdd-apply.
- sync.sh MUST only move memory/ from ~/.claude/ to the repo.
- Developers MUST NOT edit files under ~/.claude/ directly.
```

**Data Model Summary** (table of key entities with constraints):
```
| Entity        | Key Fields                         | Constraints                               |
|---------------|------------------------------------|--------------------------------------------|
| Skill         | directory name, SKILL.md, format   | format must be procedural|reference|anti-pattern |
| SDD Change    | proposal, design, tasks             | stored in engram as sdd/<name>/* artifacts |
```

**Integration Points** (table of systems with direction and contract):
```
| System      | Direction | Contract                                              |
|-------------|-----------|-------------------------------------------------------|
| install.sh  | outbound  | Deploys repo to ~/.claude/ — run after any config change |
| sync.sh     | inbound   | Copies ~/.claude/memory/ to repo — memory only         |
```

**Decision Log** (chronological, with rationale and impact):
```
### 2026-03-03 — Add ai-context/features/ as Tier 1 domain knowledge layer
Decision: Introduce ai-context/features/<domain>.md as a permanent sub-layer...
Rationale: SDD phase skills lack access to stable business context between cycles...
Impact: sdd-propose and sdd-spec gain a non-blocking Step 0 that preloads matching feature files.
```

**Known Gotchas** (operational hazards and non-obvious behaviors):
```
- sync.sh does NOT deploy skills. Running it after a skill edit does nothing — run install.sh.
- Direct edits to ~/.claude/ are silently lost on the next install.sh run.
```

For the full worked example, read `ai-context/features/sdd-meta-system.md`.

---

## Rules

- A feature file MUST follow the canonical six-section structure defined in
  `ai-context/features/_template.md`. Sections must appear in this exact order: Domain Overview,
  Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas.
- Feature files MUST be named `<domain-slug>.md` where the slug is lowercase and hyphen-separated.
  No subdirectories are allowed inside `ai-context/features/`.
- `_template.md` and any file with a leading underscore are excluded from the domain preload
  heuristic. They MUST NOT be loaded by SDD phases.
- Feature files encode permanent domain knowledge — they are updated but NEVER deleted or archived.
  Do not confuse them with SDD spec artifacts (stored in engram as `sdd/<change>/spec`), which are
  created per change and eventually archived.
- The domain preload step in `sdd-propose` and `sdd-spec` is non-blocking. A missing
  `ai-context/features/` directory or a non-matching slug MUST NOT produce a warning or failure.
  The phase always proceeds normally.
- `/memory-update` appends to feature files — it MUST NOT overwrite or delete existing content.
  `/memory-update` MUST NOT create new feature files; only scaffold them via `memory-init` or
  manual authoring.
- `project-analyze` does NOT write to `ai-context/features/`. Feature files require domain expert
  judgment; they must not be auto-overwritten by a structural scan.
- The `feature_docs:` block in project config is reserved for V2 audit integration. Do not
  activate it in V1.
