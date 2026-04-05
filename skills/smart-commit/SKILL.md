---
name: smart-commit
description: >
  Analyzes staged and unstaged files from the full working tree, groups them into functional clusters (test, docs,
  chore, directory prefix), generates a conventional commit message per group,
  detects common issues (secrets, debug statements, large files), and executes
  one commit per group sequentially after presenting a multi-commit plan for
  confirmation. Falls through to a single-commit flow when all detected files
  resolve to one group.
  Trigger: When the user says "commit", "smart commit", or /commit.
license: Apache-2.0
metadata:
  version: "1.1"
format: procedural
---

**Triggers**: When the user says "commit", "smart commit", or /commit.

## When to Use

**Triggers**: When the user says "commit", "smart commit", or /commit.

- Committing staged changes in any git repository
- When you want a well-structured conventional commit message
- When you want automatic detection of common commit issues before pushing

---

## Process

### Step 1 — Read working-tree state

Run these commands and collect their output:

```bash
git status --porcelain          # full working-tree state: staged, unstaged, untracked
git diff --cached               # full diff for content analysis (staged changes)
```

Also check:
```bash
git log --oneline -5            # recent commits to match message style
```

Parse the `git status --porcelain` output and assign a **staging-status** tag to each file:

- Lines where `XY = "??"` → tag `untracked`
- Lines where X is `A`, `M`, `R`, `D`, or `C` (index column non-space) → tag `staged`
  - If X = `R` (rename), split the entry on `" -> "` and include both the old path and the new path; both receive tag `staged`
- Lines where X = `" "` and Y is `M`, `D`, or `T` (worktree column non-space) → tag `unstaged`
- When both X and Y are non-space (staged change also has worktree modifications), the index change takes precedence: tag `staged`

If `git status --porcelain` returns empty output, report:
> Nothing to commit. Working tree is clean.

And stop — do not proceed.

### Step 1b — Group detected files

Using the file paths collected in Step 1, apply the following grouping heuristic in priority order. Each detected file is assigned to exactly one group — the first rule that matches wins, and the file is not reconsidered by later rules. Each file's `staging-status` tag (assigned in Step 1) travels unchanged through the grouping step and is preserved in the group record.

**Rule 1 — Test files** (highest priority, applied before any directory check):
- Paths matching `*.test.*`, `*.spec.*`, `_test.*`, or `*_test.*` → group `test`
- This rule applies regardless of which directory the file lives in.

**Rule 2 — Config/infra files**:
- Root-level files (no subdirectory) matching `*.json`, `*.yaml`, `*.yml`, `*.toml`, `*.sh`, or `*.env*` → group `chore`

**Rule 3 — Docs files**:
- Paths under `docs/` → group `docs`
- Root-level files matching `*.md` or `README*` → group `docs`

**Rule 4 — Directory prefix**:
- Remaining files are grouped by their first path segment (e.g., `skills/smart-commit/SKILL.md` → group `skills`; `hooks/smart-commit-context.js` → group `hooks`)

**Fallback**:
- Files that match none of the rules above (e.g., a root-level `foo.rb` with no subdirectory and no recognized extension) → group `misc`

No detected file may appear in more than one group. Every detected file must appear in exactly one group.

**Single-group fast-path**: If grouping produces exactly one group → skip the multi-commit plan and fall through to Step 2 unchanged. Behavior is identical to the pre-grouping version of this skill. If the single group contains any files tagged `unstaged` or `untracked`, print `Auto-staging N file(s): <list of those files>` then issue `git add <unstaged/untracked files>` before proceeding to Step 2.

**Multi-group branch**: If grouping produces two or more groups → proceed to Step 1c (multi-commit plan) before executing any commit.

### Step 1c — Present multi-commit plan

For each group identified in Step 1b, run Steps 2 and 3 independently using a scoped diff limited to that group's files:

```bash
git diff --cached -- <file-1> <file-2> ...   # scoped to this group's file list only
```

Use this scoped diff (not the full `git diff --cached`) as the input for both the commit message generation (Step 2) and the issue detection (Step 3) for that group.

**ERROR collection before display**: Collect all ERROR-severity findings across every group before printing anything to the user. If any group yields one or more ERRORs:
- Print all ERRORs found across all groups.
- Print: `Commit plan blocked. Fix the errors above before committing.`
- Stop — do not display the plan, do not proceed to any `git commit`.

**Display the full plan** (only when no ERRORs are present):

This annotation MUST appear before any `git add` or `git commit` is issued, so the user can review the exact staging-status of every file before confirming.

```
## Smart Commit Plan (N commits)

────────────────────────────────────
Commit 1 of N — [label]
Files: file-a.md [staged], file-b.md [unstaged]
Proposed message:
  type(scope): short description
────────────────────────────────────
Commit 2 of N — [label]
Files: skills/smart-commit/SKILL.md [untracked]
Proposed message:
  type(scope): short description
────────────────────────────────────

Issues detected across all groups:
  ⚠️  WARNING in commit 1: <message>
```

Each file in the `Files:` line is annotated with its staging-status marker: `[staged]`, `[unstaged]`, or `[untracked]`.

Display any WARNING-severity findings in the plan summary (non-blocking). If there are no issues, omit the "Issues detected" section.

**Plan-level confirmation prompt**:

```
Proceed with all commits? [commit all / step-by-step / abort]
```

- `commit all` → proceed to Step 5, multi-group "commit all" path
- `step-by-step` → proceed to Step 5, multi-group "step-by-step" path
- `abort` → print `Commit plan aborted. No files were staged. Working tree is unchanged.` and stop; no `git add` or `git commit` is executed

### Step 2 — Analyze changes

From the diff output, determine:

| Signal | Derivation |
|--------|-----------|
| **type** | `feat` new files/features; `fix` bug fixes; `refactor` restructure; `chore` config/deps; `docs` docs only; `test` tests only; `style` formatting only |
| **scope** | The primary directory or domain that changed (e.g. `auth`, `payment`, `player`). Omit if changes span many unrelated domains. |
| **summary** | One-line description of WHAT changed and WHY (present tense, lowercase, no period) |
| **body** | Bullet list of key changes if more than one file is affected |

### Step 3 — Detect issues

Scan `git diff --cached` output for these patterns. Report as **ERROR** (blocking) or **WARNING** (non-blocking):

| Severity | Condition | Message |
|----------|-----------|---------|
| ERROR | Any file matching `*.env`, `.env`, `.env.*`, `.env.local` is staged | `.env file staged — unstage with: git restore --staged <file>` |
| ERROR | Added lines (`+` prefix) match `password\s*=\s*\S+`, `api_key\s*=\s*\S+`, `secret\s*=\s*\S+`, `token\s*=\s*\S+` (case-insensitive, value present) | `Possible credential in <file>:<line> — verify before committing` |
| WARNING | Added lines contain `console.log`, `debugger`, `print(`, `puts ` | `Debug statement in <file> (N occurrences)` |
| WARNING | Added lines contain `TODO:` or `FIXME:` | `Unresolved TODO/FIXME in <file>` |
| WARNING | Any staged file is a known binary and exceeds 1 MB | `Large file staged: <file> (<size>MB)` |
| WARNING | Any staged path starts with `node_modules/` or contains `/dist/` | `Build artifact staged: <file>` |

### Step 4 — Present summary

Output a structured report before committing:

```
## Smart Commit Summary

**Staged:** N files  +X −Y lines

**Proposed commit message:**
──────────────────────────────
type(scope): short description

- bullet change 1
- bullet change 2
──────────────────────────────

**Issues detected:**
⛔ ERROR: .env.local is staged — unstage with: git restore --staged .env.local
⚠️  WARNING: console.log in pages/api/auth.js (2 occurrences)
⚠️  WARNING: TODO: left in domain/payment/PaymentService.js
```

Then, based on severity:

- **ERRORs present** → Print: `Commit blocked. Fix the errors above before committing.` Do NOT proceed.
- **Warnings only** → Ask: `Proceed with commit? [y / edit message / abort]`
- **No issues** → Ask: `Proceed with commit? [y / edit message / abort]`

If the user chooses **edit message**: ask them to provide the new message, then use it verbatim.
If the user chooses **abort**: stop, print `Commit aborted.`

### Step 5 — Execute commit

After confirmation, execute:

```bash
git commit -m "$(cat <<'EOF'
type(scope): short description

- bullet change 1
- bullet change 2
EOF
)"
```

On success, report:
```
✅ Committed: <hash> — type(scope): short description
```

On failure, report the full git error and suggest remediation.

**Multi-group "commit all" path** (when user chose `commit all` at Step 1c):

Iterate through every group in the order shown in the plan. For each group:
0. For each file in this group tagged `unstaged` or `untracked`, issue `git add <file>`; skip files already tagged `staged`.
1. Execute `git commit` with the group's proposed message.
2. Print the resulting commit hash immediately after each commit fires.
3. Do not present any intermediate prompt between groups.

After all groups have been committed, print the full-execution summary (see below).

**Multi-group "step-by-step" path** (when user chose `step-by-step` at Step 1c):

Before each group's commit, print the per-commit confirmation block:

```
## Commit N of M — [label]

**Files:** file-a.md, file-b.md
**Proposed message:**
──────────────────────────────
type(scope): short description
- bullet 1
──────────────────────────────

Proceed? [y / edit message / skip / abort remaining]
```

Apply the user's choice before moving to the next group:
- `y` → for each file in this group tagged `unstaged` or `untracked`, issue `git add <file>`; skip files already tagged `staged`; then execute `git commit` with the proposed message; print the resulting hash; continue to the next group.
- `edit message` → prompt: `Enter replacement message:` — use the provided text verbatim for this commit only; for each file in this group tagged `unstaged` or `untracked`, issue `git add <file>`; skip files already tagged `staged`; then execute and print the hash; continue to the next group.
- `skip` → no `git add` is issued for this group; leave this group's files in their original state without committing; move to the next group.
- `abort remaining` → no `git add` is issued for remaining groups; stop processing after the current group (do not commit any subsequent groups); print the partial-execution summary.

**Partial-execution summary** (triggered when all groups complete or when `abort remaining` is chosen mid-sequence):

When **all groups succeeded** (or were skipped without aborting):
```
N of N commits executed.
  ✅ <hash-1> — type(scope): description (commit 1)
  ✅ <hash-2> — type(scope): description (commit 2)
  ...
```

When **execution was aborted mid-sequence** (M commits executed, remaining groups not committed):
```
M of N commits executed.
  ✅ <hash-1> — type(scope): description (commit 1)
  ✅ <hash-2> — type(scope): description (commit 2)

Not committed — files remain in original state:
  Commit <next> of N — [label]
    Files: file-x.md [staged], file-y.md [unstaged]
    Proposed message: type(scope): description
  Commit <next+1> of N — [label]
    Files: file-z.md [untracked]
    Proposed message: type(scope): description
```

Do NOT attempt to undo or roll back any commits that have already been executed.

---

## Anti-Patterns

### Don't generate vague messages

```
# Bad
git commit -m "update"
git commit -m "fix stuff"
git commit -m "changes"

# Good
git commit -m "fix(auth): prevent session expiry on page reload"
git commit -m "feat(player): add shuffle mode to playlist"
```

### Don't bypass ERRORs

If a `.env` file or credential pattern is detected, **stop unconditionally**. Do not commit even if the user asks to skip.

### Don't stage files that were not confirmed

Issue `git add` only for groups the user explicitly confirmed; never batch-stage all detected files upfront before the plan confirmation.

---

## Quick Reference

| Situation | Commit format |
|-----------|--------------|
| Single file changed | `type(scope): description` (no body) |
| Multiple files, same domain | `type(scope): description` + bullet body |
| Multiple unrelated domains | `type: description` (no scope) + bullet body |
| Only documentation | `docs(scope): update ...` |
| Only dependency changes | `chore(deps): update X to Y.Z` |
| Only formatting/whitespace | `style(scope): format ...` |
| Only test additions | `test(scope): add tests for ...` |

## Rules

- Never commit without first presenting the generated message summary and waiting for explicit user confirmation
- Detect and block commits that contain secrets (API keys, tokens, passwords) found by pattern matching in the diff
- Detect and warn on `console.log`, `debugger`, `TODO`, and large binary files in the staged diff before committing
- Commit messages must follow conventional commits format (`type(scope): description`); generated messages that cannot be classified must default to `chore:` with a descriptive subject
- Detect files from the full working tree via `git status --porcelain`; assign each file a staging-status tag (`staged`, `unstaged`, `untracked`) during Step 1
- Auto-stage only the files of a confirmed group — issue `git add <files>` for files tagged `unstaged` or `untracked` immediately before that group's `git commit`; never re-add already-staged files
- For skipped or aborted groups, issue no `git add` — their files must remain in the exact state they were in when the skill was invoked
- When detected files span two or more functional groups, present the full multi-commit plan before executing any commit
- ERROR conditions in any group block the entire multi-commit plan — no partial execution allowed when ERRORs are present
- Every commit in a multi-commit sequence uses the proposed message without additional trailers
- The grouping heuristic is applied in priority order: test → config/infra → docs → directory prefix → misc fallback; no file may appear in more than one group
- The single-group fast-path preserves exact backward compatibility — no behavior change when all staged files resolve to one group
