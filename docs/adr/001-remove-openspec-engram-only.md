---
title: Remove OpenSpec, adopt Engram-only persistence
status: Accepted
date: 2026-03-29
---

# ADR-001: Remove OpenSpec, adopt Engram-only persistence

## Context

The SDD system originally used OpenSpec (filesystem-based artifacts under `openspec/`) as its only persistence backend. When Engram was adopted, a "dual-mode" approach was implemented where every SDD skill contained 4-branch conditional blocks (engram/openspec/hybrid/none) for every read and write operation.

This created several problems:
- **Confusing skills**: Every SKILL.md had interleaved instructions for two completely different persistence strategies, making them hard to read and maintain
- **Token waste**: Models had to process mode-conditional blocks even when only one mode was ever used
- **Inconsistent behavior**: Non-SDD skills (project-audit, project-setup, etc.) remained openspec-hardcoded, creating a two-class system
- **Accumulated noise**: 100k+ lines of openspec specs, archived changes, and documentation accumulated in the config repo

## Decision

Remove ALL OpenSpec references from the skill catalog. Engram is the sole persistence backend. Skills no longer contain mode-conditional blocks.

If OpenSpec support is needed in the future, it should be reimplemented as a separate, isolated skill package — not mixed into the core skills.

## Consequences

- Skills are simpler: one persistence path (engram), no conditionals
- `persistence-contract.md` simplifies to engram-only + none fallback
- `sdd-phase-common.md` removes all openspec branches
- `install.sh` no longer references openspec
- Users without Engram get `none` mode (inline results only) with a recommendation to install Engram
- OpenSpec can be reimplemented later as `skills/openspec-adapter/SKILL.md` that wraps the core skills

## Reimplementation path (future, not committed)

If OpenSpec is needed later:
1. Create `skills/openspec-adapter/SKILL.md` — a wrapper that intercepts SDD artifact writes and mirrors them to filesystem
2. Add an install.sh flag: `--with-openspec` that deploys the adapter
3. The adapter reads from engram and writes to `openspec/changes/` — skills themselves stay engram-only
