# Technical Design: audit-improvements

Date: 2026-03-01
Proposal: openspec/changes/audit-improvements/proposal.md

## General Approach

All improvements are implemented as **additive check blocks** inside `skills/project-audit/SKILL.md`. Each new check follows the exact same file-reading pattern already used by the skill: read a file with the Read tool, apply a conditional rule, emit a finding. The two new dimensions (D12 ADR Coverage, D13 Spec Coverage) are appended after D11 and added to the scoring table as informational rows (no impact on the existing 100-point total). The Phase A Bash discovery script is extended with new exported variables to keep total Bash calls ≤ 3.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| New dimensions use informational scoring (N/A), not scored points | Informational-only (same pattern as D9, D10, D11) | Add to 100-point pool; create a separate bonus pool | Adding to 100-point pool shifts all existing baselines — a HIGH-impact risk from the proposal. Informational dimensions are the established pattern for new audit coverage that is not yet stable. |
| D7 staleness penalty: existing `analysis-report.md` older than 30 days reduces score by 1 point (not 1–2, concrete single value) | -1 point from D7 score when file age > 30 days | No penalty; -2 points; separate dimension | Proposal says 1–2 points; single concrete value avoids ambiguity. Max D7 is 5 pts; a 1-pt penalty is meaningful without collapsing the score. The check is already gated on file existence so absence has no penalty. |
| ADR validation limited to README.md existence + individual file `## Status` field presence | Check README.md exists + each `docs/adr/NNN-*.md` has a Status field | Parse status value for validity; check for "orphaned" archived changes | Parsing valid status values risks false positives for custom statuses. Checking orphaned changes requires cross-referencing design.md files — too complex for an additive check; belongs in a future dedicated pass. |
| D3 hook script check reads `settings.json` and `settings.local.json` hook paths | Check each hook path in `hooks:` object for file existence on disk | Parse all JSON fields; validate bash syntax | Hook script existence is the minimal viable check. Bash syntax validation is out of scope (it would require a Bash call per hook). |
| D3 conflict detection: normalize paths before comparing across active `design.md` files | Lowercase + remove leading `./` before set intersection | Exact string match; regex normalization | Exact match misses `./skills/foo` vs `skills/foo`. Regex over-normalizes. A simple lowercase + strip-prefix rule catches the most common inconsistency. |
| D1 template path verification: only check paths that match `docs/templates/*.md` pattern in CLAUDE.md | Extract markdown link targets and inline code paths from the Documentation Conventions section | Scan entire CLAUDE.md for any path-like string | Full-file path scan produces too many false positives from example paths in code blocks. Scoping to the Documentation Conventions section and template path patterns is surgical and safe. |
| D2 placeholder detection: search for the exact phrases listed in proposal (`[To be filled]`, `TODO`, `[empty]`, case-insensitive) in each ai-context file body | Grep-like scan using Read + string matching in the content check step | Regex list; external grep Bash call | The skill already reads each ai-context file for line counts; adding a phrase scan to that same read is zero additional Bash calls. |
| D2 stack.md technology count: require ≥ 3 lines that contain a version-like string (`x.y`, `x.y.z`, or `vX`) | Count lines in stack.md matching version pattern | Require a specific section header; count bullet points | Version-like strings are the strongest signal that a stack entry is concrete. Header and bullet count can pass with placeholder content. |
| Phase A script extension: add `SETTINGS_JSON_EXISTS`, `SETTINGS_LOCAL_JSON_EXISTS` variables | Add to existing Phase A script block | New Phase B Bash call | Keeps total Bash calls ≤ 3 (the hard constraint in Rule 8). |
| Spec Coverage (D13) activated only when `openspec/specs/` directory is non-empty | Conditional: skip with N/A if directory absent or empty | Always run; error if missing | Prevents penalty on projects that have not yet created specs. Consistent with D12 and D10 conditional patterns. |

## Data Flow

```
Phase A (Bash — single call)
  └─ Outputs new variables:
       SETTINGS_JSON_EXISTS
       SETTINGS_LOCAL_JSON_EXISTS
       ADR_DIR_EXISTS
       ADR_README_EXISTS
       OPENSPEC_SPECS_EXISTS

Phase B (Read-tool dimension passes)
  │
  ├─ D1 enhancement
  │    Read CLAUDE.md → extract Documentation Conventions section
  │    → for each docs/templates/ path → check file exists on disk
  │    → emit HIGH finding per missing template file
  │
  ├─ D2 enhancement
  │    Read each ai-context/*.md → scan for placeholder phrases
  │    → emit MEDIUM finding if placeholder found
  │    Read ai-context/stack.md → count version-pattern lines
  │    → emit MEDIUM finding if count < 3
  │
  ├─ D3 enhancement — hook script existence
  │    If SETTINGS_JSON_EXISTS=1 → Read settings.json
  │    If SETTINGS_LOCAL_JSON_EXISTS=1 → Read settings.local.json
  │    → extract hooks: {...} values (script paths)
  │    → for each path: check exists on disk
  │    → emit HIGH finding per missing script
  │
  ├─ D3 enhancement — active changes conflict detection
  │    For each non-archived change with design.md → Read its File Change Matrix
  │    → extract file paths from the matrix
  │    → normalize: lowercase, strip leading ./
  │    → intersect sets across all active changes
  │    → emit MEDIUM finding per conflicting path pair
  │
  ├─ D7 enhancement — staleness score impact
  │    Uses ANALYSIS_REPORT_DATE (already in Phase A)
  │    → if file exists AND age > 30 days → deduct 1 pt from D7 score
  │    → report as "Staleness penalty applied (-1 pt)"
  │
  ├─ D12 — ADR Coverage (new, informational)
  │    Condition: CLAUDE.md contains "docs/adr/"
  │    If condition false → skip (N/A)
  │    If ADR_README_EXISTS=0 → FAIL finding
  │    For each docs/adr/NNN-*.md → Read file → check "## Status" section present
  │    → emit INFO per ADR missing Status section
  │
  └─ D13 — Spec Coverage (new, informational)
       Condition: OPENSPEC_SPECS_EXISTS=1 AND specs/ non-empty
       If condition false → skip (N/A)
       For each domain in openspec/specs/ → check spec.md exists
       → For each found spec.md: scan for path references → verify paths exist
       → emit INFO per stale path reference
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | Add 7 check blocks (D1, D2×2, D3×2, D7 staleness, D12, D13); extend Phase A script; add D12+D13 to score table; add D12+D13 report format sections |
| `ai-context/changelog-ai.md` | Modify | Add changelog entry for this change |
| `ai-context/architecture.md` | Modify | Document D12 and D13 as new audit dimensions in the artifact communication table |

## Interfaces and Contracts

### Phase A script additions

The following variables are appended to the existing Phase A Bash script block in SKILL.md:

```bash
echo "SETTINGS_JSON_EXISTS=$(f .claude/settings.json)$(f settings.json | tail -c 1)"
# Simplified: check both root settings.json and .claude/settings.json
echo "ROOT_SETTINGS_JSON_EXISTS=$(f settings.json)"
echo "DOTCLAUDE_SETTINGS_JSON_EXISTS=$(f .claude/settings.json)"
echo "SETTINGS_LOCAL_JSON_EXISTS=$(f settings.local.json)"
echo "ADR_DIR_EXISTS=$(d docs/adr)"
echo "ADR_README_EXISTS=$(f docs/adr/README.md)"
echo "OPENSPEC_SPECS_EXISTS=$(d openspec/specs)"
```

### D12 output format (appended to report)

```markdown
## Dimension 12 — ADR Coverage [OK|INFO|SKIPPED]

**Condition**: CLAUDE.md references docs/adr/ — YES/NO
**ADR README exists**: ✅/❌
**ADRs scanned**: [N]

| ADR | Status field present | Finding |
|-----|---------------------|---------|
| 001-skills-as-directories.md | ✅ | clean |
| [name] | ❌ | Missing ## Status section |

*D12 findings are informational only — no score impact.*
```

### D13 output format (appended to report)

```markdown
## Dimension 13 — Spec Coverage [OK|INFO|SKIPPED]

**Condition**: openspec/specs/ exists and is non-empty — YES/NO
**Domains detected**: [list]

| Domain | spec.md exists | Stale paths | Status |
|--------|---------------|-------------|--------|
| [name] | ✅/❌ | [N] | ✅/⚠️/❌ |

*D13 findings are informational only — no score impact.*
```

### D3 hook check output block (added to D3 section)

```markdown
**Hook script existence:**
| Hook event | Script path | Exists |
|-----------|-------------|--------|
| [event] | [path] | ✅/❌ |
```

### D3 conflict detection output block (added to D3 section)

```markdown
**Active changes — file conflict detection:**
| File | Change A | Change B |
|------|----------|----------|
| [path] | [change-name] | [change-name] |
[or: "No conflicts detected"]
```

### D2 enhancement output block (added to D2 section)

```markdown
**Placeholder phrase detection:**
| File | Phrase found | Severity |
|------|-------------|----------|
| stack.md | "[To be filled]" | ⚠️ MEDIUM |
[or: "No placeholder phrases detected"]

**stack.md technology count**: [N] version entries detected (minimum: 3) — ✅/⚠️
```

### D1 template path check output block (added to D1 section)

```markdown
**Template path verification:**
| Template path | Exists |
|--------------|--------|
| docs/templates/prd-template.md | ✅/❌ |
| docs/templates/adr-template.md | ✅/❌ |
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — D2 placeholder | Run `/project-audit` on a project where `known-issues.md` contains `[To be filled]` | Manual audit run |
| Manual — D3 hook existence | Add a fake hook path to `settings.json`, run audit | Manual audit run |
| Manual — D7 staleness | Copy `analysis-report.md`, edit `Last analyzed:` to 31+ days ago, run audit | Manual audit run |
| Manual — D12 ADR | Remove `docs/adr/README.md` temporarily, run audit | Manual audit run |
| Manual — D1 template | Point a template reference in CLAUDE.md to a non-existent path, run audit | Manual audit run |
| Regression | Run `/project-audit` on Audiio V3 — score must be >= prior baseline | Manual audit run |
| Regression | Run `/project-audit` on `claude-config` itself — all new checks should pass | Manual audit run |

## Migration Plan

No data migration required. All changes are additive to SKILL.md. No schema changes to openspec/config.yaml.

## Open Questions

- **D7 penalty when analysis-report.md is absent**: the proposal states the penalty only applies when the file exists but is stale. The current D7 scoring already assigns 0/5 when the file is absent (CRITICAL). Confirm: the staleness penalty (-1) applies ONLY when `ANALYSIS_REPORT_EXISTS=1 AND age > 30 days`, reducing the score from the drift-based value by 1 (floor: 0). This is the interpretation used in this design — no additional clarification needed unless the specs say otherwise.
- **D3 conflict detection and `tasks.md` vs `design.md`**: the proposal mentions "design.md file change plans." This design scopes the check to `design.md` File Change Matrix sections only, not `tasks.md`. If specs specify `tasks.md` as well, the file matrix must include an additional read step.
