# Design: clean-skill-template-noise

## Overview

This is a documentation-hygiene change for active skill content. The safest implementation is to
edit the existing examples in place, preserving their structure and intent while removing the two
remaining noise sources:

1. unbalanced nested fences in `project-audit`
2. raw `TODO` placeholder language in active scaffold examples

## Decisions

### 1. Keep the cleanup inside the existing skills

The repo already uses inline examples inside these skills. Moving the templates into dedicated
files would enlarge the surface area and create unnecessary routing work for a low-priority pass.
This change keeps the content in place and improves its hygiene.

### 2. Use explicit scaffold wording instead of generic TODO markers

The replacement text should say that it is scaffold content and should be replaced, without using
the generic `TODO` token that placeholder scans often flag.

### 3. Preserve behavior and public contract

No command flow, step ordering, or allowed side effects change. Only example wording and fence
balance are updated.

## File Changes

- `skills/project-audit/SKILL.md`
  - rebalance the nested fenced example in `## Report Format`
- `skills/project-fix/SKILL.md`
  - replace raw `TODO` stub text in the example templates with explicit scaffold wording
- `skills/project-claude-organizer/SKILL.md`
  - replace raw `TODO` scaffold text in generated-skill examples with explicit scaffold wording

## Verification

- Search the edited active examples for remaining raw `TODO` markers.
- Inspect the `project-audit` report example to confirm balanced nested fences.
- Run `bash install.sh` because active skill files changed.