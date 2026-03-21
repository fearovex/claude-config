# Exploration: sdd-archive-move-incomplete

## Current State

The `sdd-archive` skill at `skills/sdd-archive/SKILL.md` is responsible for archiving completed SDD changes. Its Step 4 ("Move to archive") contains the core bug.

**HEAD version of Step 4** (committed, `git show HEAD:skills/sdd-archive/SKILL.md`):

```
### Step 4 — Move to archive

I move the change folder:

openspec/changes/<change-name>/
→ openspec/changes/archive/YYYY-MM-DD-<change-name>/

I create `openspec/changes/archive/` if it does not exist.
```

**Working copy version of Step 4** (current, after recent modifications):

```
### Step 4 — Move to archive

**Pre-flight: strip embedded date from slug**
[...date stripping logic...]

Then construct the archive destination using today's archive date:

openspec/changes/<change-name>/
→ openspec/changes/archive/YYYY-MM-DD-<archive_slug>/

I create `openspec/changes/archive/` if it does not exist.
```

### Root Cause Analysis

**The HEAD version** has one vestigial mitigation: "I move the change folder:" is a prose sentence with a weak semantic anchor. However, the phrase is followed only by a code block showing `→` arrow notation — which is a visual hint, not a deletion instruction. LLM sub-agents interpret "move" ambiguously: they may copy files to the destination and stop, interpreting "move" as "put files there."

**The working copy version** is worse: the `I move the change folder:` sentence was removed entirely when the date-stripping pre-flight logic was inserted during a prior change (`sdd-archive-orphan-validation`). The current instructions only say:
1. Strip date from slug
2. Construct destination path
3. Create `archive/` directory if absent

There is no explicit instruction to delete `openspec/changes/<change-name>/` after copying. The sub-agent LLM silently ends Step 4 after creating the destination folder and writing files there, leaving the source intact.

### Evidence of the Bug in Practice

The current git status shows staged renames (R) for files like:
- `openspec/changes/spec-hygiene/exploration.md → openspec/changes/archive/2026-03-14-spec-hygiene/exploration.md`

These `R` (renamed) git statuses indicate human-assisted archives where git tracked file moves properly. But LLM-executed archives (via sdd-archive sub-agent) do not run `git mv` — they write files to the destination then stop. Without an explicit delete instruction, the source remains as an untracked or modified folder.

### Confirmed Code Path

File: `C:/Users/juanp/claude-config/skills/sdd-archive/SKILL.md`
Step 4 (working copy, lines 222–246): Creates destination folder, never deletes source.

The master spec at `openspec/specs/sdd-archive-execution/spec.md` does NOT contain a requirement about source deletion. The spec refers to Step 7 (memory update), index maintenance, and completeness checks — but the core "move" semantics (copy + delete source) are absent from the spec entirely.

---

## Branch Diff

Files modified in current branch relevant to this change:

- `skills/sdd-archive/SKILL.md` (modified — working copy has date-stripping pre-flight added to Step 4; source deletion instruction was lost)
- `openspec/specs/sdd-archive-execution/spec.md` (modified — recent additions for orphan precondition and completeness check; no move-semantics requirement present)
- `openspec/specs/index.yaml` (modified — index updates; not directly relevant)

---

## Prior Attempts

Prior archived changes related to this topic:

- `2026-03-19-sdd-archive-orphan-validation`: COMPLETED (verify-report present, all 8 criteria [x])
  - Relevant: this change modified Step 4 (date-stripping pre-flight) and is the change where the `I move the change folder:` sentence was lost.
  - The prior change focused on completeness checks and orphan detection — not move semantics.

No prior attempt specifically targeting source-folder deletion found in archive.

---

## Contradiction Analysis

- Item: "Move" semantics in Step 4 vs. LLM execution behavior
  Status: CERTAIN — The step title says "Move to archive" and the confirmation prompt says "IRREVERSIBLE actions: Move openspec/changes/[name]/ → openspec/changes/archive/[date]-[name]/". However, the step body only contains copy/create instructions. No LLM instruction says "delete the source folder."
  Severity: WARNING
  Resolution: Add an explicit instruction in Step 4: after writing all files to the destination, delete `openspec/changes/<change-name>/` entirely.

- Item: master spec (sdd-archive-execution) has no requirement for source deletion
  Status: CERTAIN — The spec is silent on this behavior. The "move" is a ghost: the spec documents Step 4 outcomes (archive folder creation) but not source cleanup.
  Severity: WARNING
  Resolution: Add a new requirement to the master spec (or a delta spec for this change) stating: "After copying all files from source to destination, the source directory MUST be deleted."

---

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `skills/sdd-archive/SKILL.md` | HIGH — primary fix target | Step 4 needs explicit source-delete instruction |
| `openspec/specs/sdd-archive-execution/spec.md` | MEDIUM — spec gap | Needs a new requirement for source deletion as part of the move operation |
| `openspec/changes/archive/` | LOW — artifact location | No change needed to how archive/ is populated |
| `openspec/changes/<active>/` | HIGH — operational impact | Ghost duplicates accumulate in active changes/ after each archive |

---

## Analyzed Approaches

### Approach A: Add explicit delete instruction to Step 4 in SKILL.md only

**Description**: Append a clear prose instruction to Step 4: "After all files have been written to the destination, I delete the source directory `openspec/changes/<change-name>/` and all its contents." Also add a verification sentence: "I confirm the source directory no longer exists before reporting success."

**Pros**:
- Minimal change — one SKILL.md edit
- Immediately fixes the LLM behavior gap
- No spec ceremony required for a fix this targeted

**Cons**:
- The master spec remains silent on source deletion — spec drift continues
- Does not formally document the move semantics contract for future changes

**Estimated effort**: Low
**Risk**: Low

---

### Approach B: Fix SKILL.md + add delta spec requirement for source deletion

**Description**: Same SKILL.md fix as Approach A, plus a delta spec for `sdd-archive-execution` adding a new requirement: "Step 4 MUST delete the source directory after successfully copying all files to the destination. The source directory MUST NOT exist after Step 4 completes."

**Pros**:
- Fixes both the behavior gap (SKILL.md) and the spec gap (master spec)
- Future spec GC and verify passes will have a contract to check against
- Consistent with SDD discipline: every behavioral requirement should be in a spec

**Cons**:
- Slightly more artifacts (delta spec + SKILL.md edit)
- Requires sdd-archive to merge the delta back on archive

**Estimated effort**: Low-Medium
**Risk**: Low

---

### Approach C: Restore the lost "I move the change folder:" sentence only

**Description**: The working copy lost the sentence "I move the change folder:" when date-stripping was added. Restoring this sentence may partially fix the bug (as it was the original weak mitigation in HEAD).

**Pros**:
- One-line change

**Cons**:
- "I move the change folder:" is still ambiguous — LLMs may interpret "move" as "copy" without explicit delete semantics
- The ghost-duplicate problem was reportedly present even with that sentence, so this is insufficient
- Does not fix the spec gap

**Estimated effort**: Very Low
**Risk**: Medium (incomplete fix)

---

## Recommendation

**Approach B** — Fix SKILL.md + add delta spec requirement.

The SKILL.md fix is critical for immediate correctness. The spec addition is the right SDD-discipline choice: the `sdd-archive-execution` master spec already documents Step 4 outcomes elsewhere; the move semantics requirement is a genuine gap that should be formally captured. Approach A is acceptable if time is short, but B is preferred.

**Specific fix for Step 4** — add after the archive directory creation instruction:

```
I copy all files from `openspec/changes/<change-name>/` to `openspec/changes/archive/YYYY-MM-DD-<archive_slug>/`, then I delete the source directory `openspec/changes/<change-name>/` and all its contents. The source directory MUST NOT exist after this step completes. I verify the source is gone before continuing to Step 5.
```

The `I move the change folder:` sentence from HEAD should also be restored to make the semantic intent unmistakable.

---

## Identified Risks

- **Over-deletion risk**: If the sub-agent deletes the wrong folder (e.g., matches partial path), data loss occurs. Mitigation: the instruction must name the exact path `openspec/changes/<change-name>/` and require confirmation that the destination was successfully created before deleting the source.
- **Partial copy risk**: If the copy fails midway and then the delete succeeds, files are lost. Mitigation: the SKILL.md should say "only delete source after ALL files are confirmed at the destination." This is a defensive step that the instruction should explicitly require.
- **Git tracking**: The LLM sub-agent uses Claude Code tools to create/write files. A plain delete removes files without `git rm`, meaning git will show them as "deleted" in the working tree rather than as a tracked rename. This is acceptable (git history is preserved; a commit after archive will capture the deletions). No risk if the user runs `git add -A` or `git rm` after archive.

---

## Open Questions

None — the change scope is clear: add an explicit source-deletion instruction to Step 4, add a delta spec requirement, and confirm the master spec is updated at archive time.

---

## Ready for Proposal

Yes — the root cause is confirmed, the fix is well-scoped, and both the SKILL.md and spec gap are identified.
