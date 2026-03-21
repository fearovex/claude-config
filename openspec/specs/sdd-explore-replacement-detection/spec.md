# Delta Spec: sdd-explore — Replacement and Contradiction Detection

Change: 2026-03-19-feedback-sdd-cycle-context-gaps
Date: 2026-03-19
Base: (no base spec — this domain is new)

## ADDED — New sections and behavior in exploration.md

### Requirement: Exploration output includes Branch Diff section

When exploration is run for a change, the exploration.md artifact MUST include a new section: `## Branch Diff`.

The Branch Diff section MUST:
1. Scan the current git branch for uncommitted changes and staged files that relate to the domain being explored
2. List any files in the current branch that may provide context for the change (e.g., prior attempts, related implementations)
3. Use git commands to detect local edits: `git status --short`, `git diff HEAD -- <files>`
4. Report findings in a structured summary: "N files modified, M files staged, K files untracked"

#### Scenario: Branch has modified files in the affected domain

- **GIVEN** the user is exploring a change to the auth module
- **AND** there are 2 modified files in `src/auth/` and 1 staged file in `tests/auth/`
- **WHEN** `sdd-explore` executes the Branch Diff step
- **THEN** the exploration.md `## Branch Diff` section MUST report: "2 modified, 1 staged in auth-related paths"
- **AND** the section MUST list the file paths

#### Scenario: Branch is clean — no local changes

- **GIVEN** the user's working directory is clean (no unstaged changes)
- **WHEN** `sdd-explore` scans for branch diffs
- **THEN** the `## Branch Diff` section MUST state: "Branch is clean — no uncommitted changes detected"
- **AND** no file list is needed

### Requirement: Exploration output includes Prior Attempts section

The exploration.md MUST include a new section: `## Prior Attempts`. This section searches the `openspec/changes/archive/` directory for previous failed or abandoned attempts on the same domain or feature.

The Prior Attempts section MUST:
1. List all archived change directories with a date prefix matching the pattern `YYYY-MM-DD-*`
2. For each archive entry, read the `proposal.md` or `exploration.md` to extract the change intent
3. Check if the intent overlaps with the current change (fuzzy domain or keyword match)
4. Report any detected prior attempts with their outcome (archived, not completed, reason if stated)

#### Scenario: Prior attempt exists for the same feature

- **GIVEN** the archive contains `2026-03-01-auth-session-refresh/` with a prior exploration and proposal
- **AND** the current change is `auth-session-refresh-fix`
- **WHEN** `sdd-explore` scans the archive
- **THEN** the `## Prior Attempts` section MUST list: "Found prior attempt: 2026-03-01-auth-session-refresh (exploration complete, proposal created, archived on 2026-03-05)"
- **AND** the section MUST note any stated reason for abandonment (e.g., "blocked by external API changes")

#### Scenario: No prior attempts found

- **GIVEN** the archive is empty or contains no matching entries
- **WHEN** `sdd-explore` scans the archive
- **THEN** the `## Prior Attempts` section MUST state: "No prior attempts found"

### Requirement: Exploration output includes Contradiction Analysis section

The exploration.md MUST include a new section: `## Contradiction Analysis`. This section identifies gaps or contradictions between the user's stated intent (from conversation or the request) and documented system state (specs, architecture, prior decisions).

The Contradiction Analysis section MUST:
1. Compare the change description with content from loaded specs and ai-context/
2. Detect cases where the user's intent contradicts documented constraints or architectural decisions
3. Classify each contradiction as `CERTAIN` (clearly stated) or `UNCERTAIN` (ambiguous wording)
4. Report all findings with severity level (INFO, WARNING, CRITICAL)

#### Scenario: User intent contradicts documented constraint

- **GIVEN** the proposal states "remove the periodic membership refresh hook"
- **AND** the existing spec or architecture.md states "membership refresh is guaranteed by contract to run every 4 hours"
- **WHEN** `sdd-explore` runs contradiction analysis
- **THEN** the `## Contradiction Analysis` section MUST report:
  - Contradiction: "User requests REMOVAL of hook; contract GUARANTEES hook presence"
  - Classification: CERTAIN (explicit contradiction)
  - Severity: CRITICAL
- **AND** the section MUST NOT block exploration (status remains `ok`)

#### Scenario: User mentions a mobile-specific constraint that is missing from proposal

- **GIVEN** the conversation includes "mobile must not make this request" (stated by user)
- **AND** the proposal does not mention mobile constraints
- **WHEN** `sdd-explore` detects the gap
- **THEN** the `## Contradiction Analysis` section MUST report:
  - Contradiction: "Mobile constraint mentioned in conversation; missing from proposal"
  - Classification: UNCERTAIN (user intent is clear, but proposal omits it)
  - Severity: WARNING

#### Scenario: No contradictions detected

- **GIVEN** the proposal aligns with all loaded specs and ai-context/ content
- **WHEN** `sdd-explore` runs contradiction analysis
- **THEN** the `## Contradiction Analysis` section MUST state: "No contradictions detected"

---

## Rules

- All three new sections (Branch Diff, Prior Attempts, Contradiction Analysis) MUST be included in every exploration.md output
- The Branch Diff step MUST NOT fail if git commands are unavailable — it SHALL emit an INFO note and skip the step gracefully
- Prior Attempts scanning MUST read `openspec/changes/archive/` directory; if absent or empty, section MUST state "No prior attempts found"
- Contradiction Analysis MUST treat uncertain contradictions as informational (not blocking) — they inform the gate in sdd-ff, not exploration itself
- If contradictions are found, exploration.md MUST still complete with `status: ok` or `status: warning` (NEVER `blocked` due to contradictions alone)
- Loaded specs (from Step 0c) inform all three new sections — particularly Contradiction Analysis
