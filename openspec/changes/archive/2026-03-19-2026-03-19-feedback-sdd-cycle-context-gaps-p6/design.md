# Technical Design: feedback-sdd-cycle-context-gaps-p6

Date: 2026-03-19
Proposals:
- openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/proposal-6a-orchestrator-reads-specs-before-answering.md
- openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/proposal-6b-sdd-spec-gc-skill.md

---

## General Approach

Two complementary improvements to specification handling in the SDD system:

1. **Spec-first Q&A in Orchestrator** (Proposal 6a): Add a Question routing rule that reads `openspec/specs/index.yaml` to find domain keywords matching the user's question, loads matching master specs (authoritative behavior source), and surfaces contradictions between code and spec explicitly.

2. **Spec Garbage Collection Skill** (Proposal 6b): Create a new maintenance skill (`sdd-spec-gc`) that audits master specs for PROVISIONAL/ORPHANED_REF/CONTRADICTORY/DUPLICATE/SUPERSEDED requirements, reports candidates in a dry-run, and removes confirmed items. Integrates into the orchestrator as a new maintenance-category skill alongside `project-audit` and `project-fix`.

The two changes work together: 6a makes specs visible as authoritative answers; 6b provides users a tool to keep specs clean and current. Together they complete the SDD philosophy: "specs are authority AND maintainable."

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| **Spec-matching algorithm (Proposal 6a)** | Keyword array matching in `index.yaml` — read index, check if any domain's keywords array has terms matching user question terms (case-insensitive stem matching) | Full-text search in all specs; heuristic domain name matching | Keyword arrays are fast, explicit, and editable by humans. Keyword array is already populated in index.yaml (added in 2026-03-14 change: specs-search-optimization). Heuristic domain matching is imprecise. Full-text search is expensive. |
| **Spec loading cap** | Top 3 matching domains maximum | Load all matches; configurable cap | 3 is the cap already established by `sdd-explore` Step 0 sub-step (spec context preload). Using same value ensures consistency across orchestrator and explore. Prevents user from seeing 20+ tangentially related specs. |
| **Spec integration point** | New rule in CLAUDE.md Question routing path, not in a separate skill | Create a new "spec-qa" skill; modify sdd-explore to handle Q&A | Questions are answered inline by the orchestrator — adding a skill would introduce unnecessary delegation delay. Q&A is orchestrator responsibility (direct response path, no Task delegation). sdd-explore is for investigative context, not Q&A. |
| **Contradiction surfacing format** | Inline warning with spec reference: `⚠️ Note: Code does X, spec requires Y (openspec/specs/domain/spec.md REQ-N). This may indicate spec drift or incomplete implementation.` | Silent resolution (pick one); separate contradiction report; user asks for contradiction check | Explicit surfacing respects spec as authority and flags implementation-spec gap. Ref includes specific requirement number for user to review. Format is consistent with other warnings in SDD output. |
| **GC skill scope (Proposal 6b)** | New standalone skill: `~/.claude/skills/sdd-spec-gc/SKILL.md` (global placement) | Integrate into `sdd-archive` as a post-merge hook; add as config-driven step in `sdd-apply` | GC is a periodic maintenance activity, not a merge-time decision. Users run it independently ("every 5-10 cycles" per proposal). Standalone skill is cleaner (no hidden side effects in archive). Archive should not auto-clean; user decides when. |
| **GC detection categories** | Five categories: PROVISIONAL, SUPERSEDED, ORPHANED_REF, DUPLICATE, CONTRADICTORY | Six categories (add INCOMPLETE); only three categories | Five captures the core cases. INCOMPLETE is subjective (opinion-based); excluded. CONTRADICTORY is necessary (blocks forward progress). |
| **GC codebase search strategy (ORPHANED_REF)** | Grep/ripgrep search for referenced artifact name in project root; if no match, mark as UNCERTAIN (do not remove) | Rely on file listing + existence check only; ask user each time | Grep finds references in code and comments. UNCERTAIN flag prevents false positives (best-effort, not all-or-nothing). This aligns with proposal 6b rule: "Codebase search is best-effort... flag as UNCERTAIN rather than removing." |
| **GC write mode** | Interactive: dry-run report → user options → individual confirmations (if chosen) → write | Batch auto-write with confirmation; fully interactive per requirement | Proposal 6b Step 4 shows user options: (1) remove all, (2) review individually, (3) cancel. This supports both batch and interactive. Batch first (default), with option to drill down. Aligns with proposal 6b rules. |
| **GC record method** | Comment inserted at top of spec file + changelog-ai.md entry | Separate metadata file; only changelog entry | Proposal 6b Step 6 specifies comment + changelog. Comment is readable alongside the spec. Changelog captures session-level context. Two-place record is standard SDD pattern (code + changelog). |
| **GC domain mode vs --all mode** | Both modes: `/sdd-spec-gc domain` (one spec) and `/sdd-spec-gc --all` (all specs from index.yaml) | Only --all mode; require explicit --all to avoid accidental runs | Proposal 6b explicitly shows both modes. Single domain is faster for focused cleanup; --all is comprehensive. Users can choose based on need. |
| **GC registration in CLAUDE.md** | Register in Skills Registry under new section: "SDD Maintenance Skills" (alongside project-audit, project-fix) | Add to SDD Skills (phases) section; add to Meta-tools section | GC is not a phase skill (not part of the SDD cycle DAG). GC is not strictly a meta-tool (not project-level operation). New "SDD Maintenance Skills" category clarifies that GC is a periodic utility, not a core skill. Aligns with existing categorization (SDD Skills / Meta-tools / Technology Skills). |

---

## Data Flow

### Proposal 6a: Spec-first Q&A

```
User asks Question
        ↓
Orchestrator (CLAUDE.md Question routing)
        ↓
Does project have openspec/specs/index.yaml?
  NO → Answer from code as today
  YES ↓
Read index.yaml
        ↓
Extract question terms (keywords)
        ↓
Match terms against domain.keywords arrays
        ↓
Top 3 matching domains found?
  NO → Answer from code (no spec coverage)
  YES ↓
Load openspec/specs/[domain]/spec.md for each match
        ↓
Answer using specs as authoritative source
        ↓
Code contradicts spec?
  YES → Surface contradiction warning (⚠️ + spec ref + REQ-N)
  NO → Answer cleanly
        ↓
Return answer to user
```

### Proposal 6b: Spec Garbage Collection

```
User runs /sdd-spec-gc [domain] or /sdd-spec-gc --all
        ↓
sdd-spec-gc SKILL reads openspec/specs/index.yaml
        ↓
For each domain (single or all):
        ↓
  Read openspec/specs/[domain]/spec.md
        ↓
  Scan requirements for detection patterns:
    - "provisional", "temporary", "will be replaced", etc. → PROVISIONAL
    - References contradictory or superseded behavior → SUPERSEDED
    - References artifact not in codebase (grep search) → ORPHANED_REF
    - Same constraint repeated differently → DUPLICATE
    - Two requirements that can't both be true → CONTRADICTORY
        ↓
  Present dry-run report to user
        ↓
User chooses: (1) remove all, (2) review individually, (3) cancel
        ↓
If cancel → exit (no changes)
If (2) → show each candidate, user confirms/skips per item
If (1) → confirm all candidates
        ↓
Rewrite spec file, removing confirmed items
        ↓
Add comment to top of spec: "<!-- Last GC: YYYY-MM-DD — N items removed -->"
        ↓
Update changelog-ai.md with removal summary
        ↓
Return summary to user
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` (global) | Modify | Add Step 8 to Question routing (spec-first preload); register sdd-spec-gc in Skills Registry under new "SDD Maintenance Skills" section |
| `openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/proposal-6a-orchestrator-reads-specs-before-answering.md` | Create (by sdd-propose) | Proposal document (already exists) |
| `openspec/changes/2026-03-19-feedback-sdd-cycle-context-gaps-p6/proposal-6b-sdd-spec-gc-skill.md` | Create (by sdd-propose) | Proposal document (already exists) |
| `~/.claude/skills/sdd-spec-gc/SKILL.md` | Create | New skill: spec garbage collection procedural skill |
| `docs/templates/sdd-spec-gc-report-template.md` (optional) | Create | Template for dry-run report output; non-blocking if absent |

---

## Interfaces and Contracts

### Proposal 6a: Orchestrator Question Routing Rule

**Input:** User question referencing a project domain/feature/behavior

**Processing:**
1. Check for `openspec/specs/index.yaml` in project root
2. If exists: read index, extract domains with keywords matching question terms
3. Load top 3 matches: `openspec/specs/<domain>/spec.md` per domain
4. Use spec requirements as authoritative source for answer
5. If code behavior contradicts spec → surface warning

**Output:**
- Answer to user (string)
- Optional contradiction warning (markdown blockquote with spec reference)

**Error handling:**
- index.yaml missing → proceed with code-only answer (no error)
- spec.md unreadable → log INFO note, answer from available specs
- No domain keywords match → answer from code (no specs to contradict)

### Proposal 6b: sdd-spec-gc Skill

**Command signatures:**
```bash
/sdd-spec-gc domain                    # GC one domain
/sdd-spec-gc --all                     # GC all domains in index.yaml
```

**Input:** Domain name string OR `--all` flag

**Processing:** (See Data Flow above)

**Output:** Dry-run report (markdown)

**Report structure:**
```markdown
## Spec GC Report — openspec/specs/[domain]/spec.md

### PROVISIONAL ([N] found)
- REQ-X: "[text]"
  → Suggestion: [REMOVE|UPDATE]

### SUPERSEDED ([N] found)
...

### ORPHANED_REF ([N] found)
...

### DUPLICATE ([N] found)
...

### CONTRADICTORY ([N] found)
...

Total: [N] candidates for removal, [M] for update
```

**Detection patterns:**

| Category | Pattern | Example |
|----------|---------|---------|
| PROVISIONAL | Contains: "provisional", "temporary", "will be replaced", "pending X", "when X is ready", "TODO", "scaffold", "placeholder" | "Mark Complete button is provisional pending EWP" |
| SUPERSEDED | Requirement explicitly contradicts/replaces another in same or different spec | REQ-3: "use direct lookup", REQ-9: "use mapping function" |
| ORPHANED_REF | References file/function/type not found in codebase (verified via grep) | REQ-4 references `usePeriodicMembershipRefresh.ts` → file not found |
| DUPLICATE | Same constraint expressed with different wording in same spec | REQ-2: "no mapper layer", REQ-8: "data flows directly without transformation" |
| CONTRADICTORY | Two requirements in same spec cannot both be satisfied | REQ-3: "must use FYStepView", REQ-9: "must use toItemType()" |

**Confirmation options:**
```
1. Remove all candidates ([N] items)
2. Review each candidate individually
3. Cancel — make no changes
```

**If option 2:** User reviews each candidate individually:
```
REQ-7: "Provisional pending EWP" [PROVISIONAL]
Remove? (y/n/skip):
```

**Apply phase (on confirmation):**
- Rewrite spec file, removing selected requirements
- Preserve all other content, headers, section order
- Add top-of-file comment: `<!-- Last GC: YYYY-MM-DD — [X] provisional, [Y] orphaned, [Z] contradictory removed -->`
- Update `changelog-ai.md` with entry: `- GC sdd-spec-gc [domain]: removed [X] provisional/orphaned/contradictory requirements`

**Error handling:**
- index.yaml missing → log INFO, skip (non-blocking)
- spec.md unreadable → log WARNING, skip that domain (continue with others in --all mode)
- Grep timeout/error → mark ORPHANED_REF candidates as UNCERTAIN (do not remove)
- User cancels → no writes, return early

---

## Testing Strategy

| Layer | What to test | Tool | Approach |
|-------|--------------|------|----------|
| Unit (Proposal 6a) | Keyword matching algorithm (given question terms + index.yaml, return top 3 domains) | Manual test cases / bash script | Define test cases with known domain keywords, verify matching logic |
| Unit (Proposal 6b) | Detection patterns (scan spec text, identify PROVISIONAL/ORPHANED_REF/etc.) | Manual test cases / regex validation | Write test specs with known patterns, verify each category is detected |
| Integration (Proposal 6a) | End-to-end Q&A with spec load (user asks question → orchestrator reads spec → answers with contradiction warning if applicable) | Manual session + verify log | Ask question that matches known spec, verify spec was loaded and answer reflects spec requirements |
| Integration (Proposal 6b) | End-to-end GC workflow (read spec → detect candidates → dry-run report → user confirms → spec rewritten) | Manual session + file inspection | Run `/sdd-spec-gc [test-domain]` on a domain with known candidates, verify report is accurate, confirm removals, verify spec is cleaned |
| E2E (Proposal 6b) | GC on real agent-config specs (run on 2–3 real domains, verify no unintended removal) | Manual run on staging branch | Run against actual specs, inspect results, ensure no data loss |

---

## Migration Plan

No data migration required. Both changes are additive and non-destructive:

1. **Proposal 6a** adds a new rule to Question routing; existing code-only Q&A continues if index.yaml is absent
2. **Proposal 6b** is a new optional skill; running it is opt-in via `/sdd-spec-gc` command

---

## Open Questions

1. **Keyword matching precision (Proposal 6a)**: Should the matching algorithm require all question terms to be in a domain's keywords, or just one term? Proposal 6a says "any stem in domain" but doesn't define how many matches trigger a load. **Impact**: Too loose → irrelevant specs loaded; too strict → correct specs missed. **Resolution needed before sdd-tasks**: Define matching threshold (e.g., "load domain if at least 1 keyword matches").

2. **Batch vs. interactive GC (Proposal 6b)**: When running `/sdd-spec-gc --all` on 50+ domains, should the skill batch-confirm all domains with a single "remove all" option, or show confirmations per-domain? **Impact**: UX difference; batch is fast but less granular; per-domain is thorough but tedious. **Resolution needed before sdd-tasks**: Define default UX (recommend batch for --all, option to review).

3. **GC cadence and automation (Proposal 6b)**: Proposal says "every 5-10 archived cycles" but doesn't define how to track cycle count or enforce cadence. **Impact**: Users may forget to run GC; specs accumulate again. **Resolution needed for design/tasks**: Document recommended cadence in CLAUDE.md or ai-context/conventions.md; consider future automation (e.g., `sdd-archive` emits GC reminder).

4. **Spec matching for multi-word domains (Proposal 6a)**: If a domain name is "fy-video-wiring" and user asks about "video completion", should the matching algorithm check both "fy", "video", and "wiring" as separate stems, or treat the full name as one unit? **Impact**: Matching precision and consistency across projects with different naming. **Resolution needed before sdd-tasks**: Clarify stem-splitting rules (likely: split on "-", match each stem independently).

---

## Assumptions and Constraints

**Assumptions:**
- `openspec/specs/index.yaml` exists and is well-formed (schema validated elsewhere)
- `openspec/specs/<domain>/spec.md` files are readable and in consistent format (e.g., requirements marked with "REQ-N")
- User can interact with confirmation prompts (not in a batch/automation context)
- Grep/ripgrep is available in the environment for ORPHANED_REF detection

**Constraints:**
- Spec-first Q&A must not slow down Q&A response (keyword matching is fast; spec loading is ~100ms per spec)
- GC must not modify specs that are part of active SDD changes (detect via openspec/changes/ check)
- GC must preserve spec file format and all non-removed content exactly

---

## Risks

1. **Spec keyword false positives (Proposal 6a)**: User asks "how does video compression work?" and orchestrator loads "fy-video-wiring" spec (because "video" matches) — spec is not relevant. **Mitigation**: Define matching threshold (e.g., require 2+ keywords to match); document keyword arrays in index.yaml as human-curated (not auto-generated).

2. **ORPHANED_REF false negatives (Proposal 6b)**: Grep search for artifact name misses references in string literals, comments, or dynamically constructed names. GC does not remove truly stale requirements. **Mitigation**: Proposal 6b already addresses this — mark as UNCERTAIN (do not remove); user reviews manually.

3. **Over-cleaning (Proposal 6b)**: User confirms removal of CONTRADICTORY requirement but it turns out to be correct (user misunderstood requirement text). Data loss. **Mitigation**: GC creates comment with timestamp + item count in spec file (allows recovery if needed); changelog-ai.md records what was removed (audit trail).

4. **Codebase search performance (Proposal 6b, large projects)**: Running `grep` on 100+ artifact references across a 10MB+ codebase could timeout. GC appears to hang. **Mitigation**: Proposal 6b supports both `domain` mode (fast, single spec) and `--all` mode (comprehensive but slower); users can choose. Future optimization: add timeout handling, caching, or parallel search.

---

## ADR Detection

Scanning Technical Decisions table for keywords: `pattern`, `convention`, `cross-cutting`, `replaces`, `introduces`, `architecture`, `global`, `system-wide`, `breaking`.

Matches found:
- "cross-cutting" in Proposal 6a decision (Q&A enhancement affects all questions system-wide)
- "introduces" in Proposal 6b decision (new skill, new maintenance category)
- "architecture" in Proposal 6b decision (spec handling architecture)

**Recommendation**: Create ADR for Proposal 6b (new maintenance skill + spec GC architecture) — significant enough to warrant a decision record. Proposal 6a (spec-first Q&A) is an orchestrator enhancement, less architecture-level — can be documented inline in CLAUDE.md without separate ADR.

**Tentative ADR title**: "041-spec-maintenance-and-garbage-collection-skill" (status: Proposed)

---
