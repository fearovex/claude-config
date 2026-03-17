# ADR-035: Verify Section Pattern — Grouped verify: Top-Level Key in openspec/config.yaml

## Status

Proposed

## Context

`openspec/config.yaml` already contains several top-level optional keys for controlling `sdd-verify` behavior: `verify_commands` (level 1 manual override) and `coverage:` (coverage threshold configuration). When adding support for project-detected test commands as a mid-priority fallback (level 2), two placement options existed: add flat top-level keys (`verify_test_commands`, `verify_build_command`, `verify_type_check_command`) or group them under a new `verify:` section. The existing `coverage:` section established the precedent of grouping related verification configuration under a semantic namespace. Flat keys would be simpler but would increase top-level key sprawl and make the priority model harder to reason about.

## Decision

We will add a `verify:` top-level section to `openspec/config.yaml` that groups all new verification-related sub-keys (`test_commands`, `build_command`, `type_check_command`) under a single namespace. This mirrors the existing `coverage:` grouping pattern and keeps the top-level config.yaml flat for cross-cutting keys while nesting skill-specific configuration.

## Consequences

**Positive:**

- Consistent with the existing `coverage:` section grouping convention — developers can predict where verification config lives
- Three-level priority model (`verify_commands` → `verify.test_commands` → auto-detection) is clearly navigable in the config file
- `verify:` absence is explicitly valid and documented — no behavioral change for existing projects

**Negative:**

- Introduces a second YAML namespace for verification config (`verify_commands` at top level + `verify.test_commands` nested) — minor inconsistency that could confuse new contributors unfamiliar with the priority history
- The `verify_commands` key cannot be moved under `verify:` without a breaking change; it remains a top-level key for backward compatibility
