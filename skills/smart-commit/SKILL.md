---
name: smart-commit
description: >
  Analyzes staged files, generates a conventional commit message, detects
  common issues (secrets, debug statements, large files), and executes the
  commit after presenting a summary for confirmation.
  Trigger: When the user says "commit", "smart commit", or /commit.
license: Apache-2.0
metadata:
  author: audiio
  version: "1.0"
format: procedural
---

## When to Use

**Triggers**: When the user says "commit", "smart commit", or /commit.

- Committing staged changes in any git repository
- When you want a well-structured conventional commit message
- When you want automatic detection of common commit issues before pushing

---

## Process

### Step 1 — Read staged state

Run these commands and collect their output:

```bash
git status --porcelain          # staged vs. unstaged overview
git diff --cached --stat        # files changed + lines added/removed
git diff --cached               # full diff for content analysis
```

Also check:
```bash
git log --oneline -5            # recent commits to match message style
```

If `git diff --cached --stat` returns empty output, report:
> No staged files found. Stage your changes with `git add` before committing.

And stop — do not proceed.

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

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

On success, report:
```
✅ Committed: <hash> — type(scope): short description
```

On failure, report the full git error and suggest remediation.

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

### Don't commit when nothing is staged

Always verify `git diff --cached --stat` before generating a message.

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
- Only staged files (`git diff --cached`) are in scope — never auto-stage unstaged files or untracked files
