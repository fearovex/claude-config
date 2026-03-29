# SDD Context Injection — Step 0 Reference

> This document is the canonical reference for skill authors adding project context loading to SDD phase skills.

---

## Purpose

SDD phase skills operate in sub-agent contexts that have no inherent awareness of the target project's stack, architecture decisions, or coding conventions. Without this awareness, phase outputs (proposals, designs, specs, tasks) may suggest patterns, tools, or naming styles that conflict with what the project has already established.

**Step 0 — Load project context** solves this by reading a small set of well-known files from the project root before any analysis or output begins. The loaded context enriches all subsequent steps within that execution — it does NOT override explicit content in proposals or designs, it informs them.

---

## Step 0 Block Template

Insert this block as the first `###`-level section of the `## Process` section in the SKILL.md. It must appear before any existing Step 1.

```markdown
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

For each file (items 1–3):
- If absent: log `INFO: [filename] not found — proceeding without it.`
- If present: extract `Last updated:` or `Last analyzed:` date. If date is older than 7 days:
  log `NOTE: [filename] last updated [date] — context may be stale. Consider running /memory-manage.`

Loaded context is used as enrichment throughout all subsequent steps. It informs architectural
coherence, naming consistency, and skill alignment checks — but does NOT override explicit
content in the proposal or design.
```

---

## Dual-Block Variant (sdd-propose and sdd-spec)

These two skills already have a domain context preload step (reading `ai-context/features/`). When adding Step 0 to them, use the dual-block structure:

```markdown
### Step 0a — Load project context

[global context block above — unchanged]

### Step 0b — Domain context preload

[existing feature file matching logic — unchanged]
```

The two sub-steps MUST NOT conflict. Sub-step B enrichment is additive to Sub-step A. A failure in Sub-step A does not affect Sub-step B.

---

## Placement Within sdd-apply

In `sdd-apply`, Step 0 is already named "Technology Skill Preload". The global context read is inserted as a labeled sub-section **before** the scope guard:

```markdown
### Step 0 — Context and Technology Skill Preload

#### Project context load (non-blocking)

[global context block above]

#### Scope guard

[existing scope guard logic — unchanged]

#### Stack detection

[existing logic — unchanged; may now also reference stack.md loaded above]
```

---

## Governance Logging

After reading `CLAUDE.md` in Step 0 item 4, the sub-agent outputs a single structured log line:

```
Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]
```

Where:
- `[N]` = count of items listed under `## Unbreakable Rules`
- `[language]` = primary language value from `## Tech Stack`
- `[enabled|disabled]` = `disabled` if an `intent_classification: disabled` override is present, otherwise `enabled`

**Fallback when CLAUDE.md is absent:**

```
INFO: project CLAUDE.md not found — governance falls back to global defaults.
```

This log line is non-blocking. Its absence does not affect subsequent steps.

---

## Graceful Degradation Rules

1. **Missing file** — log `INFO: [filename] not found — proceeding without it.` Continue immediately to the next file.
2. **All four sources absent** — log a single INFO note: `"ai-context/ not found — proceeding with global defaults."` Continue to Step 1.
3. **Missing project CLAUDE.md** — log `INFO: project CLAUDE.md not found — governance falls back to global defaults.` Subsequent steps treat governance as empty (no unbreakable rules loaded).
4. **Unreadable or malformed file** — treat as absent; log same INFO note as (1).
5. **This step MUST NOT produce `status: blocked` or `status: failed` under any circumstance.** All failure modes degrade to INFO or skip.

---

## Staleness Warning Threshold

The staleness threshold is **7 days**.

For each successfully read file, Step 0 extracts the first line matching either of these patterns:
- `Last updated: YYYY-MM-DD`
- `Last analyzed: YYYY-MM-DD`
- `> Last updated: YYYY-MM-DD` (blockquote variant)

If the extracted date is older than 7 days from the current date, emit:

```
NOTE: [filename] last updated [date] — context may be stale.
Consider running /memory-manage.
```

The skill MUST continue and use the stale data rather than aborting.

---

## How Loaded Context Is Used

| Context source | Informs |
|---|---|
| `ai-context/stack.md` | Technology choices in proposals, designs, tasks; skill preload in sdd-apply |
| `ai-context/architecture.md` | Architectural decisions referenced in design.md; layer separation checks in sdd-apply |
| `ai-context/conventions.md` | Naming, file structure, patterns in all output artifacts |
| Project `CLAUDE.md` (full) | Governance priming: unbreakable rules, tech stack language, intent classification status; logged in Step 0 governance line |

The loaded context enriches output — it does NOT replace explicit content in a `proposal.md` or `design.md` already written for the change.

---

## Scope of Application

Step 0 applies to the **project being changed**, not to `~/.claude/`.

When a sub-agent executes an SDD phase on a project at `/path/to/my-project`, Step 0 reads:
- `/path/to/my-project/ai-context/stack.md`
- `/path/to/my-project/ai-context/architecture.md`
- `/path/to/my-project/ai-context/conventions.md`
- `/path/to/my-project/CLAUDE.md`

It MUST NOT substitute `~/.claude/ai-context/` files if the project's own files are absent.

---

## Skills This Pattern Applies To

| Skill | Step 0 variant |
|---|---|
| `sdd-explore` | Standard Step 0 block + spec context preload sub-step |
| `sdd-propose` | Dual-block: Step 0a (global) + Step 0b (domain features) + Step 0c (spec context preload) |
| `sdd-spec` | Dual-block: Step 0a (global) + Step 0b (domain features) + Step 0c (spec context preload) |
| `sdd-design` | Standard Step 0 block + spec context preload sub-step |
| `sdd-tasks` | Standard Step 0 block + spec context preload sub-step |
| `sdd-apply` | Sub-section inside existing Step 0 (before scope guard) — spec context preload excluded (see below) |

---

## Spec Context Preload (Step 0c / sub-step)

In addition to loading `ai-context/` files, the five applicable phase skills include a spec context preload sub-step that loads relevant master spec files from `openspec/specs/`. This gives sub-agents direct access to the project's existing behavioral contracts before they author new artifacts.

**See `docs/SPEC-CONTEXT.md`** for the full convention reference:
- Selection algorithm (stem-based matching)
- Load cap (3 files maximum)
- Non-blocking contract
- Precedence rule (spec files > ai-context/ for behavioral contracts)
- Fallback behavior
- Skills this applies to (and `sdd-apply` exclusion rationale)
