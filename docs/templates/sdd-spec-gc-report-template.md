# Spec GC Report — openspec/specs/<domain>/spec.md

> **Template**: this is the canonical dry-run report format for `/sdd-spec-gc`.
> Replace `<domain>` with the actual domain name and fill in each section.
> Remove sections with 0 found. This template is informational — sdd-spec-gc generates this output automatically.

Date: YYYY-MM-DD
Command: `/sdd-spec-gc <domain>` | `/sdd-spec-gc --all`

---

## Summary

| Category | Found | Action |
|---|---|---|
| PROVISIONAL | N | REMOVE |
| ORPHANED_REF | N | REVIEW (UNCERTAIN) |
| SUPERSEDED | N | REMOVE |
| DUPLICATE | N | REMOVE |
| CONTRADICTORY | N | REVIEW |
| **Total** | **N** | **X removals, Y reviews** |

---

### PROVISIONAL ([N] found)

> Requirements containing provisional markers: "provisional", "temporary", "will be replaced", "pending X", "TODO", "scaffold", "placeholder".

- **[Requirement title or REQ-N]**: "[text excerpt — first 100 characters]"
  Detection: contains "provisional" (or other keyword)
  → Suggestion: REMOVE

---

### ORPHANED_REF ([N] found)

> Requirements referencing artifacts not found in the codebase (best-effort search).
> Status: UNCERTAIN — search is heuristic, not authoritative. User must confirm.

- **[Requirement title or REQ-N]**: references `` `[artifact-name]` ``
  Detection: Codebase search did not find `[artifact-name]` in project root
  Search result: No matches via ripgrep/grep
  Status: UNCERTAIN
  → Suggestion: REVIEW for removal (confirm artifact is truly gone before removing)

---

### SUPERSEDED ([N] found)

> Requirements explicitly replaced by a later requirement in the same spec.

- **[Requirement title or REQ-N]**: "[text excerpt]"
  Detection: Conflicts with / is replaced by [later requirement title]
  → Suggestion: REMOVE

---

### DUPLICATE ([N] found)

> Requirements expressing the same constraint with different wording.

- **[Requirement title A]**: "[text excerpt A]"
  Duplicate of: **[Requirement title B]** — same constraint expressed differently
  → Suggestion: REMOVE title A (keep title B as authoritative)

---

### CONTRADICTORY ([N] found)

> Two requirements in the same spec that cannot both be satisfied.

- **[Requirement title A]** vs **[Requirement title B]**:
  Conflict: A requires [X], B requires [NOT X / incompatible Y]
  → Suggestion: REVIEW — determine which requirement reflects current intent

---

## Confirmation

```
What would you like to do?
  1. Remove all candidates ([N] items)
  2. Review each candidate individually
  3. Cancel — make no changes
```

---

## After Removal

After confirmed removals are applied, the skill records:

**In spec file header:**
```markdown
<!-- Last GC: YYYY-MM-DD — [N] requirements removed (provisional/orphaned/etc.) -->
```

**In `ai-context/changelog-ai.md`:**
```markdown
- YYYY-MM-DD: Spec GC cleanup — removed [N] stale requirements from openspec/specs/<domain>/spec.md
  Categories: [provisional: X, orphaned: Y, contradictory: Z]
  Run by: /sdd-spec-gc [domain|--all]
```
