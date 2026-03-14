# Spec Context Loading — Convention Reference

> This document is the canonical reference for the spec context preload sub-step added to SDD phase skills in the `specs-as-subagent-background` change.

---

## Purpose

SDD phase skills need access to the behavioral contracts already established for the project's domains. Without this access, sub-agents may produce proposals, specs, and designs that contradict or duplicate existing requirements.

**Spec context preload** solves this by loading relevant master spec files from `openspec/specs/` at the start of each phase skill execution. Loaded spec files are treated as **authoritative behavioral contracts**; they take precedence over `ai-context/` for behavioral questions while `ai-context/` remains supplementary for architecture and naming context.

---

## Selection Algorithm (stem-based matching)

The same stem-based matching heuristic used for `ai-context/features/` preload in `sdd-propose` and `sdd-spec` Step 0b.

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

If the companion `specs-search-optimization` proposal is implemented (indexed full-text search), the selection quality may improve without increasing the cap.

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

## Relationship to Companion Proposal (specs-search-optimization)

The stem-based matching heuristic used here is deterministic but vocabulary-constrained: it only matches when change slug stems share lexical overlap with spec domain directory names. A change named `add-resilience-layer` may not match the `retry-policy` spec domain even if the two are semantically related.

The companion proposal `specs-search-optimization` addresses this gap by building a richer index (full-text or keyword-based) over `openspec/specs/`. When that change is implemented:

- The selection algorithm in this convention doc will be updated to reference the index
- Skills will gain higher-recall spec loading without increasing the load cap
- This document is the single source of truth for the loading contract; skill authors should not implement domain-specific selection logic in SKILL.md files

Until `specs-search-optimization` is implemented, the stem-based fallback is the authoritative algorithm.

---

## When to Override (cross-cutting changes with no domain match)

For changes that intentionally span multiple domains or whose vocabulary does not overlap with any spec domain name:

1. The spec context preload will produce zero matches and skip silently — this is correct behavior
2. `ai-context/architecture.md` and `ai-context/conventions.md` (loaded in Step 0a) remain the behavioral context source
3. If a specific spec file is known to be relevant despite no vocabulary match, a skill author may add a hard-coded read for that file within the phase skill's Step 1 (not Step 0) — Step 0 preloading remains generic and slug-driven only
4. The `specs-search-optimization` companion proposal is the long-term solution for cross-cutting cases
