# SDD Bootstrap Guide — GitHub Copilot (No Claude Code Required)

> How to set up Specification-Driven Development (SDD) in any project using only GitHub Copilot in VS Code.

---

## Prerequisites

- VS Code with the GitHub Copilot extension installed and authenticated
- Git repository initialized in the target project
- This `agent-config` repo cloned locally (you need one file from it)

---

## Part 1 — One-time setup per project

### Step 1 — Copy the Copilot instructions file

Copy `.github/copilot-instructions.md` from this repo to the target project:

```
# From the agent-config repo root:
cp .github/copilot-instructions.md <path-to-your-project>/.github/copilot-instructions.md
```

> **Why this works**: VS Code automatically loads `.github/copilot-instructions.md` as system-level context for Copilot in that workspace. Copilot will read it at the start of every session — no configuration needed.

This single file gives Copilot:
- The full SDD workflow (phases, artifacts, paths)
- Active coaching instructions (it will guide you through SDD proactively)
- The project memory layer structure (`ai-context/`)
- **A built-in init skill** — see Step 2 below

---

### Step 2 — Run the SDD init skill

Open Copilot Chat in the target project and type exactly:

```
initialize sdd
```

Copilot will execute the full initialization automatically:
1. Ask for the project name
2. Detect what already exists
3. Create `openspec/config.yaml`, `openspec/changes/archive/`, `docs/adr/README.md`
4. Scan the codebase and generate all `ai-context/` files (`stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`)
5. Customize the `## Tech Stack`, `## Architecture`, and `## Conventions` sections based on the actual project
6. Print a summary of everything created

> Other accepted trigger phrases: `sdd init`, `setup sdd`, `bootstrap sdd`

---

### Step 3 — Review and commit

Review the generated files — especially `ai-context/stack.md` and `ai-context/conventions.md` — and correct any inaccuracies. Then commit:

```bash
git add openspec/ ai-context/ docs/adr/ .github/copilot-instructions.md
git commit -m "chore: initialize SDD structure"
```

**Setup complete.** The project is now SDD-ready with Copilot as the AI assistant.

---

## Part 2 — Daily workflow

### Starting a new feature or fix

When you want to implement something, tell Copilot in Chat:

```
I want to implement [describe the feature/fix]. Follow the SDD workflow.
```

Copilot will guide you step by step:

1. **Propose** → writes `openspec/changes/<change-name>/proposal.md`
2. **Design** → writes `openspec/changes/<change-name>/design.md`  
   *(for small changes, propose + design can be done together)*
3. **Tasks** → writes `openspec/changes/<change-name>/tasks.md`
4. **Confirm** → Copilot asks you to review before writing any code
5. **Apply** → implements phase by phase, asks before each phase
6. **Verify** → writes `openspec/changes/<change-name>/verify-report.md`
7. **Archive** → moves the folder to `openspec/changes/archive/YYYY-MM-DD-<name>/`

### What each artifact is for

| File | When created | Purpose |
|------|-------------|---------|
| `proposal.md` | Phase 1 | Defines the problem, solution, and success criteria — the change contract |
| `design.md` | Phase 2 | Technical design: components affected, data flow, edge cases |
| `tasks.md` | Phase 3 | Phased implementation plan — the only thing that triggers `apply` |
| `verify-report.md` | Phase 6 | Checklist proving the implementation matches the proposal |

### Rules to follow during apply

- **Never start apply without `tasks.md`** — unstructured implementation is the primary source of SDD failures.
- **Never skip the proposal** for non-trivial changes — what gets written in `proposal.md` directly determines the quality of the implementation.
- Apply happens **phase by phase** — Copilot will ask before starting each batch of tasks. This is intentional; review before confirming.

### After significant changes

Run this prompt to keep the memory layer current:

```
Update the relevant sections in ai-context/ to reflect the changes made in this session.
Also update .github/copilot-instructions.md if the stack, architecture, or conventions changed.
```

---

## Part 3 — Keeping the instructions in sync

### When to update `.github/copilot-instructions.md`

Update after:
- Adding or removing major dependencies
- Establishing new team conventions
- Significant architecture changes
- Onboarding new developers (add gotchas and known issues)

Prompt:

```
Update the relevant sections in .github/copilot-instructions.md to reflect
the changes made in this session. Do not modify the SDD workflow sections.
```

### When to update `ai-context/`

Update `ai-context/changelog-ai.md` at the end of every AI-assisted session:

```
Append a changelog entry to ai-context/changelog-ai.md summarizing what was
implemented in this session, what decisions were made, and any risks or known issues
discovered.
```

---

## Part 4 — Reference

### SDD phase quick reference

```
explore (optional)
      │
      ▼
  propose  →  proposal.md
      │
   ┌──┴──────────────┐
   ▼                 ▼
  spec             design       ← run in parallel for large changes
   └──┬──────────────┘
      ▼
   tasks  →  tasks.md
      │
      ▼
   apply
      │
      ▼
  verify  →  verify-report.md
      │
      ▼
 archive  →  openspec/changes/archive/YYYY-MM-DD-<name>/
```

### Artifact paths cheat sheet

| Artifact | Path |
|----------|------|
| Proposal | `openspec/changes/<name>/proposal.md` |
| Design | `openspec/changes/<name>/design.md` |
| Tasks | `openspec/changes/<name>/tasks.md` |
| Verify report | `openspec/changes/<name>/verify-report.md` |
| Archived change | `openspec/changes/archive/YYYY-MM-DD-<name>/` |
| ADR | `docs/adr/NNN-short-title.md` |
| ADR index | `docs/adr/README.md` |
| Stack memory | `ai-context/stack.md` |
| Architecture memory | `ai-context/architecture.md` |
| Conventions memory | `ai-context/conventions.md` |
| Known issues memory | `ai-context/known-issues.md` |
| AI changelog | `ai-context/changelog-ai.md` |

### Useful Copilot prompts

| Situation | Prompt |
|-----------|--------|
| **Initialize SDD in a new project** | `initialize sdd` |
| Start a change | `I want to implement X. Follow the SDD workflow.` |
| Only propose | `Write a proposal for X — create openspec/changes/<name>/proposal.md` |
| Only design | `Write a technical design for <name> — create openspec/changes/<name>/design.md` |
| Only tasks | `Break down the implementation for <name> into a tasks.md` |
| Check status | `List the SDD changes in openspec/changes/ and tell me which artifacts each one has` |
| Update memory | `Update ai-context/ to reflect the work done in this session` |
| Update instructions | `Update the Tech Stack and Conventions sections in .github/copilot-instructions.md` |

---

## Troubleshooting

### Copilot doesn't follow the SDD workflow

Check that `.github/copilot-instructions.md` exists at the project root level and that the `## Active SDD Coaching Instructions` section is present. Reopen VS Code after adding it for the first time.

### Copilot skips directly to writing code

Explicitly prompt: `Before writing any code, create proposal.md and tasks.md under openspec/changes/<name>/`

### The proposal is too vague

Ask Copilot to tighten it: `Review proposal.md and add explicit, verifiable success criteria — each criterion must be a checkbox that can be marked done or not done.`

### A change was partially implemented without artifacts

Run: `Create a retroactive proposal.md and tasks.md for the work already done on <name>, then create a verify-report.md checking what was completed.`
