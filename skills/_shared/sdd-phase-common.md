# SDD Phase — Common Protocol

Boilerplate identical across all SDD phase skills. Sub-agents MUST load this alongside their phase-specific SKILL.md.

Executor boundary: every SDD phase agent is an EXECUTOR, not an orchestrator. Do the phase work yourself. Do NOT launch sub-agents, do NOT call `delegate`/`task`, and do NOT bounce work back unless the phase skill explicitly says to stop and report a blocker.

## A. Skill Loading

1. Check if the orchestrator injected a `## Project Standards (auto-resolved)` block in your launch prompt. If yes, follow those rules — they are pre-digested compact rules from the skill registry. **Do NOT read any SKILL.md files.**
2. If no Project Standards block was provided, check for `SKILL: Load` instructions. If present, load those exact skill files.
3. If neither was provided, search for the skill registry as a fallback:
   a. `mem_search(query: "skill-registry", project: "{project}")` — if found, `mem_get_observation(id)` for full content
   b. Fallback: read `.atl/skill-registry.md` from the project root if it exists
   c. From the registry's **Compact Rules** section, apply rules whose triggers match your current task.
4. If no registry exists, proceed with your phase skill only.

NOTE: the preferred path is (1) — compact rules pre-injected by the orchestrator. Paths (2) and (3) are fallbacks for backwards compatibility. Searching the registry is SKILL LOADING, not delegation. If `## Project Standards` is present, IGNORE any `SKILL: Load` instructions — they are redundant.

## B. Artifact Retrieval (Engram Mode)

**CRITICAL**: `mem_search` returns 300-char PREVIEWS, not full content. You MUST call `mem_get_observation(id)` for EVERY artifact. **Skipping this produces wrong output.**

**Run all searches in parallel** — do NOT search sequentially.

```
mem_search(query: "sdd/{change-name}/{artifact-type}", project: "{project}") → save ID
```

Then **run all retrievals in parallel**:

```
mem_get_observation(id: {saved_id}) → full content (REQUIRED)
```

Do NOT use search previews as source material.

## C. Artifact Persistence

Every phase that produces an artifact MUST persist it. Skipping this BREAKS the pipeline — downstream phases will not find your output.

### Engram mode

```
mem_save(
  title: "sdd/{change-name}/{artifact-type}",
  topic_key: "sdd/{change-name}/{artifact-type}",
  type: "architecture",
  project: "{project}",
  content: "{your full artifact markdown}"
)
```

`topic_key` enables upserts — saving again updates, not duplicates.

### OpenSpec mode

File was already written during the phase's main step. No additional action needed.

### Hybrid mode

Do BOTH: write the file to the filesystem AND call `mem_save` as above.

### None mode

Return result inline only. Do not write any files or call `mem_save`.

## D. Return Envelope

Every phase MUST return a structured envelope to the orchestrator:

- `status`: `success`, `partial`, or `blocked`
- `executive_summary`: 1-3 sentence summary of what was done
- `detailed_report`: (optional) full phase output, or omit if already inline
- `artifacts`: list of artifact keys/paths written
- `next_recommended`: the next SDD phase to run, or "none"
- `risks`: risks discovered, or "None"
- `skill_resolution`: how skills were loaded — `injected` (received Project Standards from orchestrator), `fallback-registry` (self-loaded from registry), `fallback-path` (loaded via SKILL: Load path), or `none` (no skills loaded)

Example:

```markdown
**Status**: success
**Summary**: Proposal created for `{change-name}`. Defined scope, approach, and rollback plan.
**Artifacts**: Engram `sdd/{change-name}/proposal` | `openspec/changes/{change-name}/proposal.md`
**Next**: sdd-spec or sdd-design
**Risks**: None
**Skill Resolution**: injected — 3 skills (react-19, typescript, tailwind-4)
(other values: `fallback-registry`, `fallback-path`, or `none — no registry found`)
```

## E. Slug Generation Algorithm

When the orchestrator infers a change name from a user description:

1. Lowercase, strip whitespace
2. Remove stop words: `a, an, the, to, for, with, in, of, by, on, at, from, and, or, but, is, are, was, be, this, that, fix, add, update, showing, wrong, year, users, user`
3. Tokenize on whitespace/non-alphanumeric, keep first 5 meaningful tokens
4. Prefix with `YYYY-MM-DD-`, join with hyphens, truncate to 50 chars
5. Collision avoidance: if slug exists (in engram via `mem_search` or in `openspec/changes/`), append `-2`, `-3`, etc.

The slug becomes the artifact identifier in ALL modes:
- **engram**: topic_key `sdd/{slug}/proposal`, `sdd/{slug}/spec`, etc.
- **openspec**: directory `openspec/changes/{slug}/`

## F. Project Context Load (Step 0)

This step is **non-blocking**: any failure MUST produce at most an INFO-level note. MUST NOT produce `status: blocked` or `status: failed`.

1. Read `ai-context/stack.md` — tech stack, versions, key tools.
2. Read `ai-context/architecture.md` — architectural decisions and their rationale.
3. Read `ai-context/conventions.md` — naming patterns, code conventions.
4. Read the full project `CLAUDE.md` (at project root). Extract and log:
   - Count of items listed under `## Unbreakable Rules`
   - Value of the primary language from `## Tech Stack`
   - Whether `intent_classification:` is `disabled`
   Output: `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`
   If CLAUDE.md is absent: `INFO: project CLAUDE.md not found — governance falls back to global defaults.`

For each file:
- If absent: `INFO: [filename] not found — proceeding without it.`
- If present and `Last updated:` date is older than 7 days: `NOTE: [filename] last updated [date] — context may be stale.`

Loaded context is enrichment — it does NOT override explicit content in the proposal or design.

## G. Spec Context Preload (Step 0 sub-step)

This sub-step is **non-blocking**: any failure MUST produce at most an INFO-level note.

If `openspec/specs/` directory does not exist: `INFO: openspec/specs/ not found — skipping` and skip.

**Index-first lookup algorithm:**

```
STEP 1: Try index-first lookup
  IF openspec/specs/index.yaml exists:
    a) Parse index.yaml → read domains[] array
    b) For each domain: score EXACT (1.0) keyword match or STEM (0.5) substring match
    c) Collect scoring > 0, sort by (score desc, domain asc), cap at 3
    d) Load openspec/specs/<domain>/spec.md for each matched domain
    e) Log: "Spec context loaded from index: [domain/spec.md, ...]"
    f) Return (do not fall through)

  [If index present but no domain matched OR index absent]: fall through to STEP 2

STEP 2: Stem-based directory matching (fallback)
  a) List subdirs in openspec/specs/
  b) Split change_name on "-" → stems; match if any stem (len > 1) appears in subdir name
  c) Cap at 3 matches, load spec.md for each
  d) Log fallback note

[If no match]: INFO note, proceed without loaded specs.
```

Loaded specs are **authoritative behavioral contracts** (precedence over `ai-context/` for behavioral questions). Include loaded spec paths in artifacts list (read, not written).

The full algorithm is documented above — cap at 3 domains, index-first then stem fallback.
