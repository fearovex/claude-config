# Technical Design: 2026-03-14-spec-headers-domain-consolidation

Date: 2026-03-14
Proposal: openspec/changes/2026-03-14-spec-headers-domain-consolidation/proposal.md

## General Approach

This is a pure documentation maintenance change — no skill logic is modified. The approach
is sequential file edits: (1) replace legacy header blocks in 4 spec files with the canonical
`Change: / Date:` two-line block, (2) backfill the header for `sdd-apply-execution/spec.md`
then append its full content into `sdd-apply/spec.md` as `## Part 2: TDD Mode and Output`,
(3) delete the now-retired `sdd-apply-execution/` directory, and (4) update two `architecture.md`
reference strings. All changes are git-tracked, making rollback trivial.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Consolidation strategy | Merge `sdd-apply-execution` into `sdd-apply` as a delimited `## Part 2` section | A: header-only backfill (no merge); C: cross-reference comments without merge | Approach B eliminates the discoverability gap — one skill = one spec domain. Content is purely additive; no requirements conflict. The resulting ~760-line file is manageable. Approach A leaves the split intact; Approach C is informal and unenforced. |
| Header format | Canonical two-line block: `Change: <slug>\nDate: <date>` immediately after the H1 title | Keep italic prose (*Created:*); keep bare key lines + `---` | The canonical format is machine-parseable and consistent with all 50 already-canonical spec domains. The `# Spec:` H1 title is retained as-is. |
| smart-commit header source format | Replace the two bare key lines + `---` separator entirely with the two-line canonical block | Patch only the `---` line | The bare key lines + `---` together form the legacy header; replacing the entire block produces a clean result. The prose content after the `---` is preserved unchanged. |
| Directory retirement | Delete `openspec/specs/sdd-apply-execution/` after merge | Keep as redirect stub | An empty or stub directory causes D13 to scan it and find no valid spec, producing a MEDIUM audit finding. Deletion is cleaner and is the correct outcome for a retired domain. |
| architecture.md update | String replacement of path references only | Rewriting the full key decision paragraphs | The two references are path strings embedded in prose. A targeted find-and-replace of `openspec/specs/sdd-apply-execution/spec.md` → `openspec/specs/sdd-apply/spec.md` preserves all surrounding context. |

## Data Flow

```
sdd-apply Step (apply agent)
      │
      ├─ Read sdd-apply/spec.md (current 589 lines)
      ├─ Read sdd-apply-execution/spec.md (172 lines)
      │
      ├─ Task 1: Backfill headers — 4 files (sdd-verify-execution, smart-commit, solid-ddd-skill, sdd-apply)
      │         Replace legacy header block with canonical 2-line block
      │         Verify: title H1 preserved, first content line is "Change: ..."
      │
      ├─ Task 2: Merge sdd-apply-execution into sdd-apply
      │         a. Append divider + "## Part 2: TDD Mode and Output" heading
      │         b. Append full body of sdd-apply-execution/spec.md (all content, unmodified)
      │         c. Verify: merged file line count >= 589 + 172 = 761
      │
      ├─ Task 3: Delete openspec/specs/sdd-apply-execution/ directory
      │         Verify: path no longer exists on disk
      │
      └─ Task 4: Update architecture.md references
                Find: "openspec/specs/sdd-apply-execution/spec.md"
                Replace: "openspec/specs/sdd-apply/spec.md"
                Verify: no remaining occurrences of the old path
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `openspec/specs/sdd-apply/spec.md` | Modify | Replace legacy `*Created: ...*` header with `Change: 2026-03-03-tech-skill-auto-activation\nDate: 2026-03-03`; append `---\n\n## Part 2: TDD Mode and Output\n\n` followed by full content of `sdd-apply-execution/spec.md` |
| `openspec/specs/sdd-apply-execution/spec.md` | Delete (via directory removal) | Retired after merge into `sdd-apply/spec.md`; directory `openspec/specs/sdd-apply-execution/` deleted |
| `openspec/specs/sdd-verify-execution/spec.md` | Modify | Replace `*Created: 2026-02-28 by change "close-p1-gaps-sdd-apply-verify"*` with `Change: 2026-02-28-close-p1-gaps-sdd-apply-verify\nDate: 2026-02-28` |
| `openspec/specs/smart-commit/spec.md` | Modify | Replace bare key lines (`Last updated: 2026-03-03\nCreated by change: smart-commit-functional-split\n\n---`) with `Change: 2026-03-03-smart-commit-functional-split\nDate: 2026-03-03` |
| `openspec/specs/solid-ddd-skill/spec.md` | Modify | Replace `*Created: 2026-03-04 by change "solid-ddd-quality-enforcement"*` with `Change: 2026-03-04-solid-ddd-quality-enforcement\nDate: 2026-03-04` |
| `ai-context/architecture.md` | Modify | Replace 2 occurrences of `openspec/specs/sdd-apply-execution/spec.md` with `openspec/specs/sdd-apply/spec.md` (in key decisions 19 and the D13 artifact table row) |

## Interfaces and Contracts

No code interfaces are involved. The canonical spec header format is:

```markdown
# Spec: <domain-title>

Change: YYYY-MM-DD-<originating-change-slug>
Date: YYYY-MM-DD

## Overview
(or directly to ## Requirements)
```

The `## Part 2` section divider in the merged `sdd-apply/spec.md`:

```markdown
---

## Part 2: TDD Mode and Output

# Spec: sdd-apply-execution

Change: 2026-02-28-close-p1-gaps-sdd-apply-verify
Date: 2026-02-28

## Overview
...
```

The `# Spec: sdd-apply-execution` H1 title is retained inside Part 2 as provenance — it
clarifies where the content originated. The `## Part 2` heading is the structural divider that
`sdd-apply` readers will navigate to; the inner H1 is informational only.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual inspection | Verify canonical `Change: / Date:` header present in all 5 modified spec files | Read tool (post-apply) |
| Manual inspection | Verify `sdd-apply/spec.md` contains `## Part 2: TDD Mode and Output` section with TDD content | Read tool (post-apply) |
| Manual inspection | Verify `openspec/specs/sdd-apply-execution/` directory does not exist | Glob/Bash (post-apply) |
| Manual inspection | Verify `ai-context/architecture.md` contains no remaining `sdd-apply-execution/spec.md` references | Grep (post-apply) |
| Line count check | `sdd-apply/spec.md` line count >= 761 (sum of both source files) | wc -l or Read tool |

No automated test runner is applicable — this repo has no test framework configured
(`openspec/config.yaml` does not set `tdd: true` and there are no test files).
Verification is `/sdd-verify` with manual evidence.

## Migration Plan

No data migration required. All changes are to text files tracked in git. The only
structural change is the deletion of `openspec/specs/sdd-apply-execution/` — since git
tracks individual files, the directory is restored by `git checkout` of the spec file
(see rollback in proposal.md).

## Open Questions

None. All source files have been read and confirmed in exploration.md. Originating slugs
are taken directly from the legacy header text in each file — no inference required.
