# Technical Design: sdd-new-improvements

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-new-improvements/proposal.md

## General Approach

Modify `sdd-new` and `sdd-ff` orchestrator skills to automatically infer the change slug from the user's description, eliminating the name-input gate. Make exploration mandatory as the first step in both skills: `sdd-new` runs it as Step 1, `sdd-ff` as Step 0. Update CLAUDE.md to document the new flow.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|----------------|
| Slug inference location | Implement in both `sdd-new` and `sdd-ff` SKILL.md files (duplicated logic) | Move slug inference to a separate utility skill; expose via Task tool | Slug inference is simple (string manipulation). Separation would add overhead (Task launch) for minimal benefit. Duplication is acceptable for this leaf operation. |
| Stop word list | Hardcode curated list: fix, add, update, the, a, an, for, of, in, with, showing, wrong, year, users, user | Load from external file; user-configurable list | Stop words are stable and rarely change. Hardcoding keeps the logic self-contained. External config adds complexity without clear value. |
| Slug extraction algorithm | Extract 4–5 most meaningful words (non-stop-words) from description | Use first N words; use NLP-based keyword extraction | First N words may include stop words; NLP is overkill. Position-independent extraction of non-stop-words is simple and predictable. |
| Collision handling | Append numeric suffix: `-2`, `-3`, etc. until unique | User asked to rename; use UUID suffix | Numeric suffix is human-readable and minimal. UUID would obscure the slug's semantic meaning. |
| Exploration in sdd-new | Unconditional Step 1 (remove optional gate) | Keep optional but change default to "yes" | Mandatory exploration ensures code-grounded proposals. Removing the gate eliminates decision fatigue. |
| Exploration in sdd-ff | Add as new Step 0 before propose | Add after propose (explore → propose → explore again) | Exploration informs proposal quality. Step 0 (before anything) is the logical place. Double-exploration is wasteful. |
| CLAUDE.md update scope | Update only the Fast-Forward section + update description of sdd-ff trigger | Full rewrite of all SDD flow documentation | Minimal change to keep the scope tight. Existing documentation for sdd-new remains — it will be updated by the apply phase when the SKILL.md file itself changes. |

---

## Data Flow

```
User invokes: /sdd-new "Add email system"  OR  /sdd-ff "Add email system"
                      ↓
          sdd-ff / sdd-new SKILL.md
                      ↓
          Infer slug from description:
            1. Lowercase and tokenize
            2. Strip stop words
            3. Extract 4–5 meaningful words
            4. Join with hyphens
            5. Prefix with YYYY-MM-DD
            6. Check for collisions in openspec/changes/
            7. Append -N if collision detected
                      ↓
          Slug: 2026-03-10-add-email-system (or with -2, -3 if needed)
                      ↓
          Step 0 (sdd-ff) / Step 1 (sdd-new): Run sdd-explore
                      ↓
          Task tool → sdd-explore sub-agent
                      ↓
          Create: openspec/changes/[slug]/exploration.md
                      ↓
          Remaining phases: propose → spec + design (parallel) → tasks
                      ↓
          Output: Phase summaries + ready for /sdd-apply
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-new/SKILL.md` | Modify | Step 0 added: slug inference logic; Step 1: mandatory sdd-explore (gate removed); subsequent steps unchanged |
| `skills/sdd-ff/SKILL.md` | Modify | Step 0 added: slug inference logic + mandatory sdd-explore (no separate step count change, just prepended); Step 2 → Step 1 (propose); triggers updated |
| `CLAUDE.md` | Modify | Fast-Forward section: updated flow description + diagram showing Step 0: sdd-explore |

---

## Slug Inference Algorithm

```
Input: user_description (string)

1. STOP_WORDS = {
     "fix", "add", "update", "the", "a", "an", "for", "of", "in", "with",
     "showing", "wrong", "year", "users", "user"
   }

2. tokens = user_description.lower().split()
   words = [w for w in tokens if w.strip() not in STOP_WORDS]

3. meaningful_words = words[0:5]  // Take up to 5 words

4. slug_candidate = "-".join(meaningful_words)

5. slug = f"{today_date}-{slug_candidate}"  // e.g., "2026-03-10-add-email-system"

6. if len(slug) > 50:
     slug = slug[0:50]

7. // Collision detection
   counter = 0
   base_slug = slug
   while openspec/changes/[slug]/ exists:
     counter += 1
     slug = f"{base_slug}-{counter}"

8. return slug
```

---

## Code Examples

### sdd-new SKILL.md: Step 0 — Infer slug

```
### Step 0 — Infer slug from description

The description is passed as `$ARGUMENTS`. Apply the slug inference algorithm:

1. Extract up to 5 meaningful words from the description (discard stop words)
2. Lowercase, hyphenate
3. Prefix with today's date: YYYY-MM-DD
4. Check for collisions with existing directories in openspec/changes/
5. Append -2, -3, etc. if collision detected

Result: a unique slug for this change.

Output to user:
```
Inferred change name: [slug]
```

Do NOT ask the user to confirm or rename the slug.
```

### sdd-ff SKILL.md: Step 0 — Infer slug + explore

```
### Step 0 — Infer slug and run exploration

Infer the slug from $ARGUMENTS using the same algorithm as sdd-new.

Then immediately launch sdd-explore:

Task tool:
  subagent_type: "general-purpose"
  model: haiku
  prompt: |
    STEP 1: Read ~/.claude/skills/sdd-explore/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path]
    - Change: [inferred-slug]
    - Previous artifacts: none

    TASK: Execute exploration for "[slug]"

    Return:
    - status: ok|warning|blocked|failed
    - summary, artifacts, risks
```

Wait for result. If blocked/failed, stop and report.
```

---

## Testing Strategy

| Layer | What to test | Method |
|-------|--------------|--------|
| Unit | Slug inference algorithm (tokenization, stop-word filtering, collision detection) | Manual test with hardcoded test descriptions; verify slug format and collision handling |
| Integration | sdd-new and sdd-ff with exploration | Run `/sdd-ff "test description"` in a test project; verify exploration.md is created and proposal reads it |
| End-to-end | Full cycle with inferred slug | Run `/sdd-ff` on a real change description; verify all phases complete and artifacts are in correct directory |

---

## Open Questions

None.

---

## Migration / Deployment Notes

- **Backwards compatibility**: The change removes user-facing prompts (names, exploration gate). Existing scripts that rely on these prompts will break. This is acceptable as the new behavior is superior.
- **Rollback plan**: If slug inference proves problematic, users can manually rename `openspec/changes/[inferred-slug]/` directories to their preferred names.
- **No database migration**: All changes are to SKILL.md files and CLAUDE.md. No data migrations needed.
