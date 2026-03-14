# SDD Change Slug Algorithm

> Canonical reference for the slug generation algorithm used by `/sdd-ff` and `/sdd-new`.

## Overview

When a user invokes `/sdd-ff <description>` or `/sdd-new <description>`, the orchestrator
infers a short slug from the description using a deterministic algorithm. The slug becomes
the directory name in `openspec/changes/[slug]/` and the identifier for all related artifacts.

## Algorithm

1. **Input normalization**: Convert input string to lowercase, strip leading/trailing whitespace.

2. **Stop word removal**: Remove the following words (case-insensitive):
   - Articles: `a`, `an`, `the`
   - Prepositions: `to`, `for`, `with`, `in`, `of`, `by`, `on`, `at`, `from`
   - Conjunctions: `and`, `or`, `but`
   - Auxiliaries: `is`, `are`, `was`, `be`
   - Other: `this`, `that`, `fix`, `add`, `update`, `showing`, `wrong`, `year`, `users`, `user`

3. **Split on whitespace and non-alphanumeric characters**: Tokenize the remaining string.
   Keep only tokens that start with a letter or digit.

4. **Take first 5 meaningful tokens** (after stop-word removal): These become the slug base.

5. **Prefix with today's date**: Prepend `YYYY-MM-DD-` to the joined tokens.

6. **Hyphenate**: Join tokens with `-`.

7. **Truncate**: Truncate to 50 characters if needed.

8. **Collision avoidance**: If a slug already exists in `openspec/changes/`, append `-2`,
   then `-3`, etc., until the slug is unique.

## Examples

- Input: `fix the authentication bug in login flow`
  → Stop words removed: `authentication`, `bug`, `login`, `flow`
  → Slug: `YYYY-MM-DD-authentication-bug-login-flow`

- Input: `add payment feature`
  → Stop words removed: `payment`, `feature`
  → Slug: `YYYY-MM-DD-payment-feature`

- Input: `improve project audit dimension D4b for reference format skills`
  → Stop words removed: `improve`, `project`, `audit`, `dimension`, `d4b`, `reference`, `format`, `skills`
  → First 5: `improve`, `project`, `audit`, `dimension`, `d4b`
  → Slug: `YYYY-MM-DD-improve-project-audit-dimension-d4b`

## Used by

- `/sdd-ff` — Step 0: infer slug from description, launch explore with the inferred slug
- `/sdd-new` — Step 0: same algorithm, collision detection, then launch propose

## Notes

- The algorithm is deterministic: same input always produces the same slug (barring collision suffix).
- Collision avoidance is transparent to the user — the suffix is appended automatically.
- Slugs are human-readable but automatically generated — users cannot override them at invocation time.
- The STOP_WORDS set is intentionally small to preserve meaningful tokens. Words like `improve` and `refactor` are included because they rarely add semantic value to a slug identifier.
