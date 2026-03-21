# Spec: Spec Garbage Collection Skill

Change: 2026-03-19-feedback-sdd-cycle-context-gaps-p6
Date: 2026-03-19

## Requirements

### Requirement: Spec GC skill discovers stale requirements

The skill MUST scan master specs and identify requirements that are obsolete, provisional, contradictory, or orphaned.

#### Scenario: Scan single domain for stale requirements

- **GIVEN** a user runs `/sdd-spec-gc [domain]` on a project with `openspec/specs/index.yaml`
- **AND** the domain exists in the index and has a `spec.md` file
- **WHEN** the skill executes Step 2 (Candidate detection)
- **THEN** it MUST scan the spec's requirements and scenarios for patterns indicating staleness:
  - **PROVISIONAL**: text contains keywords "provisional", "temporary", "will be replaced", "pending X", "when X is ready", "TODO", "scaffold", "placeholder"
  - **ORPHANED_REF**: requirement references a file, function, type, or component that no longer exists in the codebase (verified via best-effort search)
  - **CONTRADICTORY**: two requirements in the same spec express constraints that cannot both be satisfied
  - **SUPERSEDED**: a later requirement in the same spec or different spec explicitly replaces this one
  - **DUPLICATE**: two requirements express the same constraint with different wording
- **AND** it MUST flag each match with its category and detection reason

#### Scenario: Scan all domains at once

- **GIVEN** a user runs `/sdd-spec-gc --all` on a project with `openspec/specs/index.yaml`
- **WHEN** the skill executes Step 1 (Discovery)
- **THEN** it MUST read the index to list all domains
- **AND** it MUST apply candidate detection to each domain's spec
- **AND** it MUST aggregate results into a single report

#### Scenario: No stale requirements found

- **GIVEN** a domain's spec contains no PROVISIONAL, ORPHANED_REF, CONTRADICTORY, SUPERSEDED, or DUPLICATE patterns
- **WHEN** the skill completes candidate detection
- **THEN** it MUST report "0 candidates found" without error

---

### Requirement: Spec GC skill presents candidates as a dry-run report

The skill MUST produce a human-readable dry-run report before any modifications are made.

#### Scenario: Report structure and content

- **GIVEN** the skill has completed candidate detection for one or more specs
- **WHEN** the skill enters Step 3 (Present candidates)
- **THEN** it MUST produce a report with these sections:
  - Heading: `## Spec GC Report — openspec/specs/<domain>/spec.md`
  - For each category (PROVISIONAL, ORPHANED_REF, CONTRADICTORY, SUPERSEDED, DUPLICATE):
    - Subsection with count: `### CATEGORY_NAME (N found)`
    - For each matched requirement:
      - Requirement ID or name
      - Text excerpt or description of the requirement
      - Detection reason (e.g., "File not found in codebase", "Contradicts REQ-X")
      - Suggestion (e.g., "REMOVE", "UPDATE to reflect current state")
  - Summary line: `Total: [N] candidates for removal, [M] candidates for update`
- **AND** the report MUST include file paths in absolute or project-relative form (e.g., `openspec/specs/fy-video-wiring/spec.md`)
- **AND** the report MUST be presented in Markdown format for clarity

#### Scenario: ORPHANED_REF search is best-effort

- **GIVEN** a requirement references a file or function name (e.g., `usePeriodicMembershipRefresh.ts`)
- **WHEN** the skill attempts to verify the reference exists in the codebase
- **THEN** if the search fails (reference not found, search times out, search is inconclusive):
  - It MUST flag the requirement as UNCERTAIN (not automatically remove)
  - It MUST include the search result in the report (e.g., "Codebase search did not find 'usePeriodicMembershipRefresh.ts'")
  - The suggestion MUST be "REVIEW for removal" rather than "REMOVE" outright

---

### Requirement: Spec GC skill requires user confirmation before write

The skill MUST NOT modify any spec file until the user confirms the removals/updates.

#### Scenario: User confirms removals

- **GIVEN** the skill has presented a dry-run report with N candidates
- **WHEN** the skill enters Step 4 (User confirmation)
- **THEN** it MUST present options:
  ```
  What would you like to do?
    1. Remove all candidates (N items)
    2. Review each candidate individually
    3. Cancel — make no changes
  ```
- **AND** if the user selects option 1 or 2, the skill MUST proceed to Step 5 (Apply)
- **AND** if the user selects option 3 or provides no response, the skill MUST exit without modifying the spec

#### Scenario: User reviews candidates individually

- **GIVEN** the user selects option 2 (Review each candidate individually)
- **WHEN** the skill enters Step 5 (Apply)
- **THEN** for each candidate requirement:
  - It MUST present the requirement ID, text, detection category, and suggestion
  - It MUST ask: "Remove this requirement? (yes/no/skip)"
  - It MUST honor the user's response and proceed to the next candidate
- **AND** it MUST accumulate confirmed removals
- **AND** it MUST only write the spec after all candidates have been reviewed

---

### Requirement: Spec GC skill applies removals and records changes

The skill MUST rewrite the spec file with confirmed requirements removed, preserving format and structure.

#### Scenario: Rewrite spec with removals

- **GIVEN** the user has confirmed one or more requirements for removal
- **WHEN** the skill enters Step 5 (Apply)
- **THEN** it MUST read the original spec file
- **AND** it MUST remove the confirmed requirement(s) from the file (including title, description, scenarios, and any associated annotations)
- **AND** it MUST preserve:
  - Spec header (title, Change, Date, Base metadata)
  - All other requirements, scenarios, and sections
  - Markdown formatting and structure
  - Line spacing and organization
- **AND** it MUST write the modified spec back to the original file path
- **AND** it MUST NOT attempt to rewrite, consolidate, or reword requirements (only remove)

#### Scenario: Record GC metadata in spec and changelog

- **GIVEN** the skill has rewritten the spec file with removals
- **WHEN** the skill enters Step 6 (Record)
- **THEN** it MUST add a comment at the top of the spec file (after the header):
  ```markdown
  <!-- Last GC: YYYY-MM-DD — N requirements removed (provisional/orphaned/contradictory) -->
  ```
- **AND** it MUST update `ai-context/changelog-ai.md` with an entry like:
  ```
  - 2026-03-19: Spec GC cleanup — removed N stale requirements from openspec/specs/<domain>/spec.md (categories: provisional/orphaned/contradictory)
  ```
- **AND** the entry MUST record what was removed and when (for audit trail)

---

### Requirement: Spec GC skill works on any project with openspec/specs/

The skill MUST be project-agnostic and work on any project that has the SDD structure.

#### Scenario: Single-domain mode

- **GIVEN** a user runs `/sdd-spec-gc [domain]` in any project with `openspec/specs/` directory
- **WHEN** the skill attempts to find the domain
- **THEN** if the domain subdirectory exists:
  - It MUST read `openspec/specs/<domain>/spec.md`
  - It MUST proceed with candidate detection and reporting
- **AND** if the domain does not exist:
  - It MUST surface an error: "Domain '[domain]' not found in openspec/specs/"
  - It MUST list available domains from `openspec/specs/index.yaml` (if present) or directory listing
  - It MUST exit without error

#### Scenario: All-domains mode

- **GIVEN** a user runs `/sdd-spec-gc --all` in any project
- **WHEN** the skill attempts to list all domains
- **THEN** if `openspec/specs/index.yaml` exists:
  - It MUST read the index to get the canonical domain list
  - It MUST scan each domain in order
- **AND** if the index does not exist:
  - It MUST list domains by scanning the `openspec/specs/` directory
  - It MUST process each subdirectory as a domain

---

### Requirement: Spec GC skill reads project context before execution

The skill MUST load project governance and context before scanning specs.

#### Scenario: Load project context

- **GIVEN** the skill is launched on a project with `CLAUDE.md`
- **WHEN** the skill enters Step 0a (Load project context)
- **THEN** it MUST read:
  - `ai-context/stack.md` (project tech stack)
  - `ai-context/architecture.md` (architectural decisions)
  - `ai-context/conventions.md` (naming and code conventions)
  - Project `CLAUDE.md` (governance, unbreakable rules, intent classification status)
- **AND** it MUST log context load status (e.g., "Governance loaded: 7 unbreakable rules, tech stack: Markdown + YAML + Bash, intent classification: enabled")
- **AND** if any context file is missing or unreadable, it MUST log a note and continue (non-blocking)

---

## Examples

### Example: PROVISIONAL requirement detected and removed

**Input spec requirement:**
```markdown
### Requirement: Welcome video completion tracking

Video completion is stored in localStorage as a temporary measure pending SP persistence integration.
This will be replaced when SP persistence is available (estimated Q2).

#### Scenario: Mark video complete
- **GIVEN** a video is playing
- **WHEN** the user clicks "Mark Complete"
- **THEN** completion status is stored in localStorage
```

**GC report:**
```
### PROVISIONAL (1 found)
- REQ-7: "Mark Complete button is provisional pending SP persistence"
  Text: "stored in localStorage as a temporary measure..."
  → Suggestion: REMOVE (SP persistence now implemented)
```

**After removal:**
```
(Requirement removed entirely from spec)
```

### Example: ORPHANED_REF requirement detected

**Input spec requirement:**
```markdown
### Requirement: Periodic membership refresh

The system MUST call `usePeriodicMembershipRefresh` hook on component mount to refresh membership status.
```

**GC report:**
```
### ORPHANED_REF (1 found)
- REQ-4: references `usePeriodicMembershipRefresh`
  Search result: File not found in codebase
  → Suggestion: REVIEW for removal (UNCERTAIN — function may be named differently)
```

**User option:**
- If user confirms: requirement is removed
- If user skips: requirement remains (no automatic removal of UNCERTAIN candidates)

---
