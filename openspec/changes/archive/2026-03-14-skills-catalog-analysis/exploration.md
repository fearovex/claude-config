# Exploration: skills-catalog-analysis

Date: 2026-03-13
Explorer: sdd-explore

Governance loaded: 5 unbreakable rules, tech stack: Markdown + YAML + Bash, intent classification: enabled

---

## Current State

The skills catalog contains **51 directories** under `skills/` (same in both `agent-config/skills/` and `~/.claude/skills/` — perfectly mirrored). Skills are grouped into:

| Category | Count | Skills |
|---|---|---|
| SDD orchestrators | 2 | sdd-ff, sdd-new |
| SDD phases | 9 | sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-status |
| Meta-tools | 11 | project-setup, project-onboard, project-audit, project-analyze, project-fix, project-update, memory-init, memory-update, skill-creator, skill-add, project-claude-organizer |
| System audits | 2 | claude-folder-audit, config-export |
| Design principles | 1 | solid-ddd |
| Domain knowledge | 1 | feature-domain-expert |
| Commit tooling | 1 | smart-commit |
| AI/Meta tooling | 1 | codebase-teach |
| Tech — Frontend | 8 | react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native |
| Tech — Backend | 4 | django-drf, spring-boot-3, hexagonal-architecture-java, java-21 |
| Tech — Testing | 2 | playwright, pytest |
| Tech — Tooling | 3 | github-pr, jira-task, jira-epic |
| Tech — Desktop | 1 | electron |
| Tech — Languages | 1 | elixir-antipatterns |
| Tech — Misc | 3 | excel-expert, image-ocr, claude-code-expert |

---

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `skills/sdd-*/SKILL.md` (8 files) | High | Repeated verbatim blocks across 8 phase skills |
| `skills/sdd-ff/SKILL.md` + `skills/sdd-new/SKILL.md` | Medium | Identical slug inference algorithm duplicated |
| `skills/react-19/` through `skills/ai-sdk-5/` and others | Medium | Format contract non-compliance (missing `## Patterns` or `## Examples`) |
| `skills/elixir-antipatterns/SKILL.md` | Low | Format contract non-compliance (missing `## Anti-patterns`) |
| `skills/claude-code-expert/SKILL.md` | Low | Structural issues: duplicate `## Description`, duplicate `**Triggers**` |
| `skills/codebase-teach/SKILL.md` | Low | Overlaps with `memory-update` and `project-analyze` |
| `skills/sdd-status/SKILL.md` | Low | Lightweight utility — consider consolidation |

---

## Analyzed Approaches

### Approach A: Document-only (No Changes)

**Description**: Accept current state as-is; note findings for future SDD cycles.
**Pros**: Zero risk; no migration needed; catalog is functional as-is.
**Cons**: Technical debt compounds; repeated blocks add 150-200 lines of maintenance burden; audit violations persist.
**Estimated effort**: None
**Risk**: Low (short-term), Medium (long-term)

### Approach B: Incremental Fix — Structural/Compliance Issues Only

**Description**: Fix format contract violations (missing `## Patterns`, `## Anti-patterns` sections), fix `claude-code-expert` duplicate sections. Do NOT touch the verbatim duplication or merge skills.
**Pros**: Addresses audit compliance findings; minimal surface area; can be applied per skill with low risk.
**Cons**: Does not address root cause of verbatim duplication; maintenance burden unchanged.
**Estimated effort**: Low
**Risk**: Low

### Approach C: Full Refactor — Extract Shared Blocks + Structural Fixes

**Description**: Extract the verbatim Step 0 governance block and Skill Resolution block into a `SHARED_CONTEXT.md` referenced by all 9 SDD phase skills. Fix format compliance across all non-compliant skills. Resolve the slug duplication between `sdd-ff` and `sdd-new`.
**Pros**: Eliminates ~220 lines of duplicated instructions; consistent updates; fixes all audit violations.
**Cons**: Highest effort; requires coordinated changes across 9 phase skills; Claude cannot natively "include" external files — sub-agents would need to read `SHARED_CONTEXT.md` explicitly, which requires prompting changes.
**Estimated effort**: High
**Risk**: Medium (if shared-file reference fails, phase skills degrade silently)

### Approach D: Targeted Fix — Only Slug Duplication + Compliance

**Description**: Fix format contract violations and the duplicate slug algorithm in `sdd-ff`/`sdd-new` by extracting it to a shared doc or consolidating in `sdd-ff` (referenced by `sdd-new`). Accept verbatim Step 0 duplication as intentional (resilience-by-repetition pattern).
**Pros**: Addresses highest-impact duplication (slug algorithm); fixes audit compliance; respects that verbatim repetition in prompting contexts has value (no hidden dependencies).
**Cons**: Does not eliminate the Step 0 verbatim duplication; maintenance of the 6-skill governance block still requires 6 parallel edits.
**Estimated effort**: Medium
**Risk**: Low

---

## Key Findings

### Finding 1 — FORMAT CONTRACT VIOLATIONS (HIGH — Audit impact)

**Severity**: HIGH (triggers `project-audit` D4b and D9-3 findings)

The format contract (documented in `docs/format-types.md` and enforced by `project-audit`) requires:
- `reference` format: `## Patterns` OR `## Examples` section
- `anti-pattern` format: `## Anti-patterns` section

**Violations found:**

| Skill | Declared Format | Missing Section | Actual Sections Used |
|---|---|---|---|
| `react-19` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `nextjs-15` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `typescript` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `zustand-5` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `zod-4` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `tailwind-4` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `ai-sdk-5` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `react-native` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `electron` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `spring-boot-3` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `hexagonal-architecture-java` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `java-21` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `playwright` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `pytest` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Code Examples` |
| `github-pr` | reference | `## Patterns` or `## Examples` | `## Critical Patterns` |
| `jira-task` | reference | `## Patterns` or `## Examples` | `## Critical Patterns`, `## Templates` |
| `jira-epic` | reference | `## Patterns` or `## Examples` | No `## Patterns`/`## Examples` |
| `django-drf` | reference | `## Patterns` or `## Examples` | `## ViewSet Pattern`, `## Serializer Patterns` |
| `excel-expert` | reference | `## Patterns` or `## Examples` | `## Common Patterns` (not `## Patterns`) |
| `image-ocr` | reference | `## Patterns` or `## Examples` | `## Python Implementations` |
| `claude-code-expert` | reference | `## Patterns` or `## Examples` | `## CLAUDE.md Configuration` |
| `elixir-antipatterns` | anti-pattern | `## Anti-patterns` | `## Critical Patterns` (misnamed) |

**Note**: `solid-ddd` and `feature-domain-expert` are compliant (both have `## Patterns`).

**Root cause**: The 18 Gentleman-Skills-extracted tech skills and several internally-created reference skills use `## Critical Patterns` and `## Code Examples` instead of the canonical `## Patterns` or `## Examples`. The audit check requires exact prefix match `## Patterns` or `## Examples`. The skills work correctly in practice — this is a naming convention mismatch, not a content issue.

**Options to resolve**:
- **Option A** (lower effort): Update the format contract in `docs/format-types.md` to also accept `## Critical Patterns` and `## Code Examples` as valid — and update `project-audit` to match.
- **Option B** (higher effort): Rename the sections in all 21 non-compliant skills to `## Patterns` and `## Examples`.

---

### Finding 2 — VERBATIM DUPLICATION OF STEP 0 GOVERNANCE BLOCK (MEDIUM — Maintenance burden)

**Severity**: MEDIUM (no audit impact; high maintenance cost)

The governance context injection block (Step 0a) is duplicated verbatim in 6 SDD phase skills:
- `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`

The duplicated block (~22 lines each) instructs the sub-agent to:
1. Read `ai-context/stack.md`, `architecture.md`, `conventions.md`
2. Read project `CLAUDE.md` and log a governance summary line

Total duplicated lines: ~132 lines across 6 files. Any change to the governance loading protocol requires editing all 6 files in sync.

Similarly, the **Skill Resolution block** (~12 lines each) is duplicated verbatim across all 9 SDD phase/orchestrator skills (sdd-explore through sdd-archive + sdd-ff + sdd-new). Total: ~108 lines.

**Architecture note**: This is not a bug — in the prompting context, repetition is intentional resilience. Sub-agents cannot "import" from other files without an explicit read step. However, when any of these blocks requires a change (as happened recently with the governance injection ADR), all 6 (or 9) files must be updated simultaneously. The recent `fix-subagent-project-context` change required touching 6+ skills simultaneously, confirming the maintenance risk.

---

### Finding 3 — SLUG ALGORITHM DUPLICATION (LOW — Minor maintenance burden)

**Severity**: LOW

The slug inference algorithm (STOP_WORDS list + 7-step algorithm) is duplicated verbatim in both:
- `sdd-ff/SKILL.md` (lines 52-63)
- `sdd-new/SKILL.md` (lines 52-63)

The content is functionally identical. The diff between the two shows only the surrounding prose differs. Since `sdd-ff` is the most commonly used orchestrator and `sdd-new` adds confirmation gates on top, the slug logic could canonically live in one place. However, given the prompting context, this duplication is low-risk.

---

### Finding 4 — CLAUDE-CODE-EXPERT STRUCTURAL ISSUES (LOW)

**Severity**: LOW

`skills/claude-code-expert/SKILL.md` has:
- Two `## Description` sections (duplicate heading)
- Two `**Triggers**` occurrences (only one is required)
- No `## Patterns` or `## Examples` section (format contract violation — already counted in Finding 1)

The duplicate `## Description` creates ambiguity and would cause `project-audit` to flag the section detection.

---

### Finding 5 — SEMISTRUCTURED SKILLS WITHOUT CANONICAL HEADINGS (LOW — Audit risk)

**Severity**: LOW

Several tech skills use non-canonical section headings that would pass `project-audit` only by the `## Critical Patterns` exception gap:

- `django-drf`: uses `## ViewSet Pattern`, `## Serializer Patterns`, `## Filters`, etc. — no `## Patterns`
- `jira-epic`: uses `## Epic Title Format`, `## Epic Template`, `## Task Decomposition` — no `## Patterns` or `## Examples`
- `jira-task`: uses `## Templates`, `## Jira MCP Fields` — no canonical main section

These are not operationally broken but would be found MEDIUM findings in a `project-audit` D4b scan.

---

### Finding 6 — ELIXIR-ANTIPATTERNS MISNAMED MAIN SECTION (MEDIUM)

**Severity**: MEDIUM

`skills/elixir-antipatterns/SKILL.md` is declared `format: anti-pattern` but uses `## Critical Patterns` as its main section heading instead of `## Anti-patterns`. The format contract requires `## Anti-patterns` for this format type. This is a direct contract violation for the anti-pattern format.

Content is appropriate (it does catalog anti-patterns), but the section heading does not match.

---

### Finding 7 — SKILL OVERLAP: CODEBASE-TEACH vs MEMORY-UPDATE vs PROJECT-ANALYZE (LOW — Conceptual)

**Severity**: LOW (informational)

There is meaningful conceptual overlap between three skills:

| Skill | What it writes | When |
|---|---|---|
| `project-analyze` | Updates `[auto-updated]` sections in `ai-context/` | Deep re-scan of codebase structure |
| `memory-update` | Updates `ai-context/` with session decisions; updates `features/<domain>.md` | End-of-session capture |
| `codebase-teach` | Writes `ai-context/features/<context>.md` per bounded context | Deep domain extraction pass |

All three can write to `ai-context/features/`. The division is documented in CLAUDE.md's "Skill Overlap" table and in `ai-context/stack.md`. However, new users frequently confuse which to use. The overlap is intentional (each skill has a distinct trigger scenario) but the boundary is subtle.

**No change recommended** — the overlap is documented and the distinction is valid. This is a documentation/UX concern rather than a structural issue.

---

### Finding 8 — SDD-VERIFY DOES NOT LOAD PROJECT GOVERNANCE CONTEXT (LOW)

**Severity**: LOW

`sdd-verify` (format: procedural) is the only SDD phase skill that does NOT have a Step 0 governance loading block. It jumps directly to Step 1 — Load all artifacts. This inconsistency means:
- Verify does not log the `Governance loaded:` line
- Verify does not read `ai-context/stack.md` or `architecture.md` for context enrichment

Operationally, verify is read-only and its enrichment context (project stack) is less critical than for sdd-spec/sdd-design/sdd-apply. However, for consistency with the governance injection standard established in `fix-subagent-project-context`, this is a gap.

---

## Recommendation

**Recommended approach: Two-phase targeted remediation**

**Phase 1 (High priority — compliance):**
- Fix format contract violations in `elixir-antipatterns` (rename `## Critical Patterns` → `## Anti-patterns`) — this is the only true anti-pattern format violation.
- Fix `claude-code-expert` duplicate sections.
- For the 19 `reference` format skills using `## Critical Patterns`/`## Code Examples`: choose **Option A** from Finding 1 — update `docs/format-types.md` and `project-audit` to accept `## Critical Patterns` and `## Code Examples` as valid `reference` format section alternatives. This is lower-risk than renaming sections in 19 externally-sourced skills.

**Phase 2 (Medium priority — consistency):**
- Add Step 0 governance block to `sdd-verify` for consistency with all other phase skills.
- Document the STOP_WORDS algorithm canonically in one place (e.g., `docs/sdd-slug-algorithm.md`) and reference it from both `sdd-ff` and `sdd-new`. (Does not require code changes — documentation only.)

**Not recommended now:**
- Extracting Step 0 / Skill Resolution blocks to a shared file — the prompting context benefits from self-contained instructions per skill. The maintenance cost is real but the resilience benefit is also real.
- Renaming `## Critical Patterns` to `## Patterns` across 19 externally-sourced skills — high effort, low benefit, risks breaking the visual structure users see.

---

## Identified Risks

- **Format contract violations are audit-visible**: Running `/project-audit` on this repo will produce MEDIUM findings for all 21 non-compliant skills. This affects the audit score.
- **Verbatim duplication creates change propagation risk**: The next change that modifies the Step 0 governance protocol must touch 6 skills simultaneously. Missing one creates inconsistency.
- **elixir-antipatterns anti-pattern section is misnamed**: A sub-agent reading the format contract and validating `elixir-antipatterns` would report a hard violation.

---

## Open Questions

1. Should the format contract be updated to accept `## Critical Patterns` and `## Code Examples` (Option A from Finding 1), or should all 19 tech skills be renamed (Option B)? This decision determines whether the fix is in the audit tooling or in the skill content.
2. Is `sdd-verify` intentionally excluded from governance loading, or was it missed during the `fix-subagent-project-context` change?

---

## Ready for Proposal

Yes — the findings are clear, the scope is bounded, and the options are well-defined. The most impactful change is resolving Finding 1 (format contract violations) via the audit tooling update (Option A), since it addresses 21 skills at once without touching externally-sourced content.
