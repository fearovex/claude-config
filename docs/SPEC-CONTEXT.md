# Spec Context Loading — Convention Reference

> This document is the canonical reference for the spec context preload sub-step added to SDD phase skills in the `specs-as-subagent-background` change.

---

## Purpose

SDD phase skills need access to the behavioral contracts already established for the project's domains. Without this access, sub-agents may produce proposals, specs, and designs that contradict or duplicate existing requirements.

**Spec context preload** solves this by loading relevant master spec files from `openspec/specs/` at the start of each phase skill execution. Loaded spec files are treated as **authoritative behavioral contracts**; they take precedence over `ai-context/` for behavioral questions while `ai-context/` remains supplementary for architecture and naming context.

---

## Using the spec index (preferred mechanism)

When `openspec/specs/index.yaml` is present, phase skills use a two-step index-driven lookup as the **primary** selection mechanism. This provides higher recall than stem matching because keyword sets explicitly cover change-slug vocabulary that may not share lexical overlap with domain directory names.

**Algorithm:**

```
Step 1: Read openspec/specs/index.yaml (single read, if present)
Step 2: For each entry in domains:
          if entry.domain in change_name → match
          OR for any keyword in entry.keywords: if keyword in change_name → match
Step 3: matches = matches[:3]   ← hard cap at 3
Step 4: If index absent → fall back to stem-based name scan (see next section)
```

**Examples:**

| Change name | Matched via index | Matched domains |
|---|---|---|
| `add-resilience-layer` | keyword `retry` in `sdd-warning-classification` | `sdd-warning-classification` |
| `fix-project-audit-score` | domain `project-audit-core` in slug | `project-audit-core`, `audit-scoring` |
| `update-sdd-archive-flow` | domain `sdd-archive-execution` in slug | `sdd-archive-execution` |
| `add-new-widget` | no domain or keyword match | none → silent skip → stem fallback |

**Maintenance:** `openspec/specs/index.yaml` is maintained by `sdd-archive` (Step 3a) — one entry is appended per new spec domain created during archiving. Hand-editing is permitted for keyword corrections or additions.

---

## Selection Algorithm — Stem-based matching (fallback)

Used when `openspec/specs/index.yaml` is absent. The stem-based algorithm is the **fallback** mechanism; the index-driven lookup above is preferred when the index exists.

```
stems = change_name.split("-").filter(s => s.length > 1)
candidates = list(openspec/specs/) → subdirectory names
matches = []
for domain in candidates:
  if domain in change_name OR any stem in domain:
    matches.append(domain)
matches = matches[:3]   ← hard cap at 3
```

**Examples:**

| Change name | Stems | Matching domains |
|---|---|---|
| `fix-auth-token-refresh` | `[fix, auth, token, refresh]` | `auth`, `token-validation` |
| `add-payment-gateway` | `[add, payment, gateway]` | `payment`, `payment-processing` |
| `improve-project-audit` | `[improve, project, audit]` | `project-audit` (if domain exists) |
| `add-new-feature` | `[add, new, feature]` | none → silent skip |

---

## Load Cap (3 files maximum)

A hard cap of **3 spec files** per phase invocation applies. The cap bounds token cost reliably. For broader cross-cutting changes where more than 3 domains match, the fallback to `ai-context/` (which summarizes all domains) is the appropriate mechanism.

The index-driven lookup (see above) improves selection quality without increasing the cap — a single YAML read replaces exhaustive directory scanning.

---

## Non-Blocking Contract

This sub-step is **non-blocking** in all five phase skills it applies to:

- Missing `openspec/specs/` directory → INFO note, skip silently
- No matching domains → skip silently, proceed to next step
- Unreadable spec file → INFO note, skip that file, continue with remaining matches
- This sub-step MUST NOT produce `status: blocked` or `status: failed` under any circumstance

---

## Precedence Rule (spec files > ai-context/ for behavioral contracts)

When a master spec file is loaded via this sub-step:

- **Behavioral contracts** (requirements, Given/When/Then scenarios, RFC 2119 MUST/MUST NOT rules): spec file content takes precedence
- **Architecture and naming context** (tech stack, conventions, naming patterns): `ai-context/` files remain authoritative

The loaded spec files do NOT override explicit content in a `proposal.md` or `design.md` already written for the change — they enrich the sub-agent's understanding before new artifacts are authored.

---

## Fallback Behavior (no match → ai-context/ only)

When no spec domains match the change slug:

1. Skip spec context preload silently (no error, no warning)
2. Proceed with `ai-context/` enrichment from Step 0a as the sole behavioral context source
3. Phase work continues normally

This fallback is the expected path for cross-cutting changes or changes whose domain vocabulary does not yet exist in `openspec/specs/`.

---

## Skills This Applies To

| Skill | Placement |
|---|---|
| `sdd-explore` | New sub-step within Step 0 (after existing context load) |
| `sdd-propose` | Step 0c — after existing Step 0a (global context) and Step 0b (features preload) |
| `sdd-spec` | Step 0c — after existing Step 0a (global context) and Step 0b (features preload) |
| `sdd-design` | New sub-step within Step 0 (after existing context load) |
| `sdd-tasks` | New sub-step within Step 0 (after existing context load) |

**Explicitly excluded:**

- `sdd-apply` — already operates against `openspec/changes/<change>/specs/` delta files (the change's own spec output). Adding master spec loading at apply time would introduce a second authoritative spec source with undefined conflict resolution.

---

## Relationship to specs-search-optimization

The `specs-search-optimization` change (2026-03-14) introduced `openspec/specs/index.yaml` and the index-driven lookup described above. The stem-based algorithm is now the fallback, not the primary mechanism.

This document is the single source of truth for the loading contract. Skill authors MUST NOT implement domain-specific selection logic inside SKILL.md files — all spec selection is driven by the algorithm documented here (index-first, stem-based fallback).

For the architecture decision behind this change, see `docs/adr/034-specs-search-optimization-architecture.md`.

---

## When to Override (cross-cutting changes with no domain match)

For changes that intentionally span multiple domains or whose vocabulary does not overlap with any spec domain name:

1. The spec context preload will produce zero matches and skip silently — this is correct behavior
2. `ai-context/architecture.md` and `ai-context/conventions.md` (loaded in Step 0a) remain the behavioral context source
3. If a specific spec file is known to be relevant despite no vocabulary match, a skill author may add a hard-coded read for that file within the phase skill's Step 1 (not Step 0) — Step 0 preloading remains generic and slug-driven only
4. Expanding the keyword set in `openspec/specs/index.yaml` for the relevant domain is the recommended fix for persistent vocabulary-mismatch cases

---

## Orchestrator Spec-first Q&A (Question Routing — Step 8)

In addition to the SDD phase skills above, the **orchestrator itself** applies spec context preload when answering user Questions. This is implemented as Step 8 in the Classification Decision Table's `ELSE` (Question) branch.

### When it applies

**Only for the Question intent class.** Change Requests and Explorations are NOT affected.

### Matching algorithm (Question routing)

The Question routing algorithm matches question tokens against domain stems and keywords in `openspec/specs/index.yaml`:

```
1. Tokenize the user's question: lowercase, split on spaces and punctuation
2. For each domain in index.yaml:
   a. Split domain name on "-" to get stems (length > 1)
   b. Check explicit keywords[] array entries
   c. If any stem or keyword appears in question tokens → candidate
3. Cap at top 3 matching domains
4. Load openspec/specs/<domain>/spec.md for each candidate
5. Use spec as authoritative source for the answer
6. Surface contradiction warning if code diverges from spec:
   "⚠️ Note: The current code does [X], but the spec requires [Y]
   (openspec/specs/<domain>/spec.md REQ-N). This may indicate spec drift or
   an incomplete implementation."
```

### Fallback behavior

| Condition | Behavior |
|---|---|
| `openspec/specs/index.yaml` does not exist | Answer from code — no spec preload |
| No domain keywords/stems match question | Answer from code — no specs loaded |
| Matched spec file unreadable | Log INFO note; skip that domain; use available specs |

### Examples

| Question | Matched domain | Why |
|---|---|---|
| "What happens when the welcome video completes?" | `fy-video-wiring` | Stem `"video"` matches token `"video"` |
| "How does the orchestrator classify intent?" | `orchestrator-behavior` | Stem `"orchestrator"` matches token `"orchestrator"` |
| "Why is the retry logic failing?" | none (graceful fallback) | No domain with stem `"retry"` in index |

### Contradiction surfacing

The orchestrator surfaces spec-code contradictions inline as ⚠️ warnings. This is informational — it does not auto-route to a Change Request. The user decides whether to initiate a fix.

### Relationship to sdd-explore spec preload

Both mechanisms use the same 3-domain cap and keyword-based matching. The difference is context: `sdd-explore` loads specs to inform a research artifact (`exploration.md`); the orchestrator Q&A step loads specs to inform a direct inline answer.

See `openspec/specs/orchestrator-behavior/spec.md` for the formal behavioral spec of this feature.
