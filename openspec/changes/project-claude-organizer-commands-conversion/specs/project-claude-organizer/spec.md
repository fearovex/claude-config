# Delta Spec: project-claude-organizer

Change: project-claude-organizer-commands-conversion
Date: 2026-03-04
Base: openspec/specs/project-claude-organizer/spec.md

---

## ADDED — New requirements

### Requirement: Active scaffold strategy for qualifying commands/ files (Step 3b replacement)

The skill MUST replace the advisory-only `delegate` strategy for `commands/` with an active
`scaffold` strategy. For each `.md` file in `.claude/commands/` that passes the existing
three-signal qualification test, the skill MUST generate a minimal but valid `SKILL.md` under
`.claude/skills/<stem>/SKILL.md` without requiring any additional user commands.

**Qualification signals (unchanged from current advisory logic):**
- Signal 1 — Step-numbered sections: the source file contains at least one heading matching
  `### Step N` or `## Step N` (where N is a digit) → infer format `procedural`.
- Signal 2 — Patterns/Examples headings: the source file contains a heading starting with
  `## Patterns` or `## Examples` → infer format `reference`.
- Signal 3 — Anti-pattern headings: the source file contains a heading starting with
  `## Anti-patterns` or `# Anti-patterns` → infer format `anti-pattern`.
- Default (no signal matches): infer format `procedural`.

**Scaffold generation rules:**
1. Derive the skill name from the filename stem using kebab-case normalization.
2. Infer the format type from the signals above (first match wins; Signal 1 before Signal 2
   before Signal 3; default `procedural` if no match).
3. Generate a SKILL.md that: (a) includes a valid YAML frontmatter block with `name:`,
   `description:`, and `format:` fields; (b) includes `**Triggers**` and `## Rules` sections;
   (c) includes the format-required main section (`## Process` for procedural, `## Patterns`
   or `## Examples` for reference, `## Anti-patterns` for anti-pattern); (d) copies all
   recognizable content from the source `.md` file into the appropriate section.
4. Write the skeleton to `.claude/skills/<stem>/SKILL.md`.

**Idempotency invariant:** If `.claude/skills/<stem>/SKILL.md` already exists, the skill MUST
skip generation and record the outcome as `[already exists — not overwritten]`. The source file
MUST NOT be modified or deleted in any case.

**Non-qualifying files:** Files that do not pass any qualification signal MUST continue to be
listed as advisory notes in the report (unchanged behavior). They are NOT scaffolded.

#### Scenario: Qualifying file is scaffolded as a procedural skill

- **GIVEN** `.claude/commands/deploy-review.md` exists and contains a `### Step 1` heading
- **WHEN** Step 3b scaffold strategy runs
- **THEN** `.claude/skills/deploy-review/SKILL.md` is created
- **AND** the generated SKILL.md contains a YAML frontmatter block with `format: procedural`
- **AND** the SKILL.md contains a `**Triggers**` section, a `## Process` section, and a `## Rules` section
- **AND** the content of `deploy-review.md` is copied into the `## Process` section
- **AND** the report lists `deploy-review` as `scaffolded → .claude/skills/deploy-review/SKILL.md`

#### Scenario: Qualifying file is scaffolded as a reference skill

- **GIVEN** `.claude/commands/api-patterns.md` exists and contains a `## Patterns` heading (no Step N heading)
- **WHEN** Step 3b scaffold strategy runs
- **THEN** `.claude/skills/api-patterns/SKILL.md` is created
- **AND** the generated SKILL.md contains `format: reference` in frontmatter
- **AND** the SKILL.md contains `**Triggers**`, `## Patterns`, and `## Rules` sections

#### Scenario: Qualifying file is scaffolded as an anti-pattern skill

- **GIVEN** `.claude/commands/react-antipatterns.md` exists and contains a `## Anti-patterns` heading
- **WHEN** Step 3b scaffold strategy runs
- **THEN** `.claude/skills/react-antipatterns/SKILL.md` is created
- **AND** the generated SKILL.md contains `format: anti-pattern` in frontmatter
- **AND** the SKILL.md contains `**Triggers**`, `## Anti-patterns`, and `## Rules` sections

#### Scenario: Non-qualifying file is not scaffolded — remains advisory

- **GIVEN** `.claude/commands/notes.md` exists and contains no Step N, Patterns/Examples, or Anti-patterns headings
- **WHEN** Step 3b scaffold strategy runs
- **THEN** `.claude/skills/notes/SKILL.md` is NOT created
- **AND** the report lists `notes.md` as an advisory note only

#### Scenario: Idempotency — existing SKILL.md is not overwritten

- **GIVEN** `.claude/commands/deploy-review.md` qualifies for scaffolding
- **AND** `.claude/skills/deploy-review/SKILL.md` already exists (e.g., hand-authored)
- **WHEN** Step 3b scaffold strategy runs
- **THEN** `.claude/skills/deploy-review/SKILL.md` is NOT modified
- **AND** the report records `deploy-review — [already exists — not overwritten]`
- **AND** the source file `.claude/commands/deploy-review.md` is not modified or deleted

#### Scenario: Scaffold produces section-contract-valid SKILL.md for procedural format

- **GIVEN** a qualifying procedural source file is scaffolded
- **WHEN** the generated `.claude/skills/<stem>/SKILL.md` is evaluated against the procedural section contract
- **THEN** the file has a `---` frontmatter block containing `format: procedural`
- **AND** the file contains `**Triggers**` (or `## Triggers`)
- **AND** the file contains `## Process` or at least one `### Step N` heading
- **AND** the file contains `## Rules`

#### Scenario: Scaffold proceeds for each qualifying file independently

- **GIVEN** `.claude/commands/` contains `tool-a.md` (qualifying) and `tool-b.md` (qualifying) and `notes.md` (non-qualifying)
- **WHEN** Step 3b scaffold strategy runs
- **THEN** `.claude/skills/tool-a/SKILL.md` and `.claude/skills/tool-b/SKILL.md` are created
- **AND** `.claude/skills/notes/SKILL.md` is NOT created
- **AND** the report lists all three with their respective outcomes

#### Scenario: commands/ directory absent — no scaffold step runs

- **GIVEN** the project `.claude/` folder has no `commands/` directory
- **WHEN** Step 3b scaffold strategy runs
- **THEN** no scaffold operations are attempted
- **AND** no entry for `commands/` appears in the scaffold section of the report

#### Scenario: Source file preserved after scaffold — delegate invariant

- **GIVEN** a qualifying `.claude/commands/deploy-review.md` is scaffolded to `.claude/skills/deploy-review/SKILL.md`
- **WHEN** the scaffold operation completes
- **THEN** `.claude/commands/deploy-review.md` still exists at its original path
- **AND** NO deletion prompt is issued for the `commands/` category (delegate invariant preserved)

---

### Requirement: Skills audit — Step 3c (new step after Step 3b)

The skill MUST execute a new Step 3c immediately after Step 3b. Step 3c scans all immediate
subdirectories of `.claude/skills/` in the project, applies three detection rules to each, and
collects findings into a `SKILL_AUDIT_FINDINGS` list.

**Detection Rule 1 — Scope-tier overlap (severity: HIGH):** A skill directory name matches a
global catalog entry when the same name appears in the CLAUDE.md Skills Registry under a
`~/.claude/skills/<name>/SKILL.md` path reference. A match is case-sensitive and based on the
directory name stem only.

**Detection Rule 2 — Broken shell (severity: MEDIUM):** A skill directory exists under
`.claude/skills/` but contains no `SKILL.md` file.

**Detection Rule 3 — Suspicious name (severity: LOW):** A skill directory name begins with an
underscore (`_`), or starts with the prefix `test-`, or starts with the prefix `draft-`.

Each finding MUST record: skill name, rule triggered, severity, and a short human-readable
reason.

**If `.claude/skills/` does not exist** in the project, Step 3c is skipped entirely and
`SKILL_AUDIT_FINDINGS` is an empty list.

**Multiple rules may fire for the same skill directory**; each matching rule produces a
separate finding entry.

#### Scenario: Scope-tier overlap detected — HIGH finding

- **GIVEN** the project has `.claude/skills/react-19/SKILL.md`
- **AND** the project CLAUDE.md Skills Registry contains a reference to `~/.claude/skills/react-19/SKILL.md`
- **WHEN** Step 3c runs
- **THEN** `SKILL_AUDIT_FINDINGS` contains an entry for `react-19` with severity HIGH and rule "scope-tier overlap"
- **AND** the finding reason states that the skill is also registered globally

#### Scenario: Broken shell detected — MEDIUM finding

- **GIVEN** the project has `.claude/skills/my-tool/` but no `SKILL.md` inside it
- **WHEN** Step 3c runs
- **THEN** `SKILL_AUDIT_FINDINGS` contains an entry for `my-tool` with severity MEDIUM and rule "broken shell"

#### Scenario: Suspicious name detected — LOW finding (underscore prefix)

- **GIVEN** the project has `.claude/skills/_draft-feature/SKILL.md`
- **WHEN** Step 3c runs
- **THEN** `SKILL_AUDIT_FINDINGS` contains an entry for `_draft-feature` with severity LOW and rule "suspicious name"

#### Scenario: Suspicious name detected — LOW finding (test- prefix)

- **GIVEN** the project has `.claude/skills/test-util/SKILL.md`
- **WHEN** Step 3c runs
- **THEN** `SKILL_AUDIT_FINDINGS` contains an entry for `test-util` with severity LOW and rule "suspicious name"

#### Scenario: Suspicious name detected — LOW finding (draft- prefix)

- **GIVEN** the project has `.claude/skills/draft-payments/SKILL.md`
- **WHEN** Step 3c runs
- **THEN** `SKILL_AUDIT_FINDINGS` contains an entry for `draft-payments` with severity LOW and rule "suspicious name"

#### Scenario: Multiple rules fire on same directory — multiple findings

- **GIVEN** the project has `.claude/skills/test-react-19/` (no SKILL.md inside)
- **AND** CLAUDE.md references `~/.claude/skills/test-react-19/SKILL.md`
- **WHEN** Step 3c runs
- **THEN** two findings are recorded for `test-react-19`: one HIGH (scope overlap) and one MEDIUM (broken shell) and one LOW (suspicious name `test-` prefix)

#### Scenario: Clean skills directory — no findings

- **GIVEN** the project has `.claude/skills/custom-ci/SKILL.md` only
- **AND** CLAUDE.md does NOT reference `~/.claude/skills/custom-ci/SKILL.md`
- **AND** the directory name does not start with `_`, `test-`, or `draft-`
- **WHEN** Step 3c runs
- **THEN** `SKILL_AUDIT_FINDINGS` is empty

#### Scenario: No .claude/skills/ directory — Step 3c skipped

- **GIVEN** the project `.claude/` folder has no `skills/` subdirectory
- **WHEN** Step 3c is reached
- **THEN** Step 3c is skipped entirely
- **AND** `SKILL_AUDIT_FINDINGS` is empty
- **AND** no error or warning is surfaced

#### Scenario: Step 3c detects only immediate subdirectories (no recursion)

- **GIVEN** `.claude/skills/tool-a/sub-tool/` exists but `.claude/skills/tool-a/` itself is the only immediate subdirectory
- **WHEN** Step 3c runs
- **THEN** only `tool-a` is evaluated for findings
- **AND** `sub-tool` is NOT evaluated as a separate skill candidate

---

### Requirement: Skills audit section in report (Step 6 extension)

The `claude-organizer-report.md` MUST include a `### Skills audit` section when Step 3c ran
(i.e., `.claude/skills/` exists in the project).

When `SKILL_AUDIT_FINDINGS` is non-empty, the section MUST list each finding with:
- Skill name
- Severity label (HIGH / MEDIUM / LOW)
- Rule triggered
- Human-readable reason

When `SKILL_AUDIT_FINDINGS` is empty, the section MUST appear with the message:
`No issues detected in .claude/skills/.`

When Step 3c was skipped (no `.claude/skills/` directory), the `### Skills audit` section
MUST be omitted entirely from the report.

#### Scenario: Report includes Skills audit section with findings

- **GIVEN** `SKILL_AUDIT_FINDINGS` contains findings for `react-19` (HIGH) and `test-util` (LOW)
- **WHEN** the report is written in Step 6
- **THEN** the report contains a `### Skills audit` section
- **AND** it lists `react-19 — HIGH — scope-tier overlap — ...reason...`
- **AND** it lists `test-util — LOW — suspicious name — ...reason...`

#### Scenario: Report includes Skills audit section with no findings

- **GIVEN** `.claude/skills/` exists but `SKILL_AUDIT_FINDINGS` is empty
- **WHEN** the report is written in Step 6
- **THEN** the report contains a `### Skills audit` section
- **AND** it contains the message `No issues detected in .claude/skills/.`

#### Scenario: Report omits Skills audit section when skills/ directory absent

- **GIVEN** the project has no `.claude/skills/` directory
- **WHEN** the report is written
- **THEN** the `### Skills audit` section is absent from the report

---

### Requirement: Scaffold outcomes included in the report (Step 6 extension)

When Step 3b scaffold strategy ran (i.e., `.claude/commands/` existed), the report MUST
include a `### Commands scaffolded` section listing every processed source file with its
outcome:

- `<filename>.md → .claude/skills/<stem>/SKILL.md — scaffolded (format: <format>)` for successful scaffolds
- `<filename>.md — [already exists — not overwritten]` for skipped duplicates
- `<filename>.md — advisory only (no qualifying signals)` for non-qualifying files

When `.claude/commands/` was absent, the `### Commands scaffolded` section MUST be omitted.

#### Scenario: Report lists scaffold outcomes per file

- **GIVEN** `.claude/commands/` contained `deploy-review.md` (scaffolded), `notes.md` (advisory only), and `ci-helper.md` (already exists)
- **WHEN** the report is written in Step 6
- **THEN** the report contains `### Commands scaffolded`
- **AND** it lists `deploy-review.md → .claude/skills/deploy-review/SKILL.md — scaffolded (format: procedural)`
- **AND** it lists `notes.md — advisory only (no qualifying signals)`
- **AND** it lists `ci-helper.md — [already exists — not overwritten]`

#### Scenario: Commands scaffolded section omitted when commands/ absent

- **GIVEN** no `.claude/commands/` directory exists in the project
- **WHEN** the report is written
- **THEN** `### Commands scaffolded` is absent from the report

---

## MODIFIED — Modified requirements

### Requirement: Source file preservation invariant — commands/ (delegate invariant extension)

*(Before: The "never delete" invariant applied to the `delegate` strategy for `commands/`.)*

The "never delete" invariant MUST continue to apply to the `commands/` category regardless
of whether the scaffold strategy produced output. Scaffolding a qualifying file from `commands/`
MUST NOT trigger any deletion prompt or source modification for the `commands/` directory.
This invariant is unconditional — it cannot be overridden by any user input.

The only behavioral change is the active scaffold operation itself; the source preservation
rule is unchanged.

#### Scenario: commands/ source files preserved after active scaffold (regression)

- **GIVEN** qualifying files in `.claude/commands/` were scaffolded to `.claude/skills/`
- **WHEN** the scaffold operations complete
- **THEN** all source files in `.claude/commands/` still exist at their original paths
- **AND** NO deletion prompt is issued for the `commands/` category
- **AND** this invariant holds even if the user would otherwise be offered cleanup prompts for other categories in the same run

---

### Requirement 6 — Emoji-normalized heading matching in section-distribute strategy

The `section-distribute` strategy used for `project.md` and `readme.md` files MUST normalize
heading text before matching against any signal list. The normalization consists of stripping
leading and trailing emoji characters and surrounding whitespace from the heading text. The
normalized form is used exclusively for signal-list comparisons; the original heading text in
the source file is never modified.

If after normalization a heading matches a signal, it MUST be routed exactly as if the heading
had never contained any emoji prefix. The original heading text (including emoji) MUST be
displayed to the user in any per-section confirmation prompt, preserving the source
representation.

If a file has zero routable headings even after applying emoji normalization to all headings,
the organizer MUST output a clear advisory:
`<filename> — no routeable headings found (even after emoji normalization). Recommend manual migration.`

#### Scenario 1: Emoji-prefixed heading matching stack signal

- **GIVEN** a `project.md` containing a heading `## 🎯 Tech Stack`
- **WHEN** the section-distribute strategy runs
- **THEN** the heading is normalized to `Tech Stack`
- **AND** the normalized heading matches the stack signal list
- **AND** the section is routed to `ai-context/stack.md`

#### Scenario 2: Emoji-prefixed heading matching architecture signal

- **GIVEN** a `project.md` containing a heading `## 🏗️ Architecture`
- **WHEN** the section-distribute strategy runs
- **THEN** the heading is normalized to `Architecture`
- **AND** the normalized heading matches the architecture signal list
- **AND** the section is routed to `ai-context/architecture.md`

#### Scenario 3: Non-emoji heading continues to match as before

- **GIVEN** a `project.md` containing a heading `## Known Issues`
- **WHEN** the section-distribute strategy runs
- **THEN** the heading matches the known-issues signal list without normalization
- **AND** the section is routed to `ai-context/known-issues.md`

#### Scenario 4: All headings have emojis but none match after normalization

- **GIVEN** a `project.md` where every heading contains an emoji prefix
- **AND** none of the normalized heading texts match any signal in any signal list
- **WHEN** the section-distribute strategy runs
- **THEN** the organizer outputs the advisory: `project.md — no routeable headings found (even after emoji normalization). Recommend manual migration.`

#### Scenario 5: Original heading text preserved in per-section confirmation prompt

- **GIVEN** a `project.md` containing a heading `## 🎯 Tech Stack`
- **WHEN** the section-distribute strategy presents the routing confirmation prompt to the user
- **THEN** the prompt displays the original heading text `## 🎯 Tech Stack` (with emoji)
- **AND** the source file is not modified

---

### Requirement 7 — readme.md as an explicit legacy migration category

`readme.md` (case-insensitive) found at the immediate `.claude/` level MUST be recognized as
a `LEGACY_MIGRATION` candidate with strategy `user-choice` rather than being classified as
`UNEXPECTED`. Two migration options MUST be presented to the user:

- **Option A**: Integrate the file's content into the project's `CLAUDE.md` by appending it
  as a commented navigation section marked with `<!-- .claude/readme.md -->`.
- **Option B**: Move the file to `docs/README-claude.md`, preserving it as a standalone
  reference outside `.claude/`.

If the user skips the category (chooses neither option), the organizer MUST record:
`readme.md — skipped by user. Recommend manual review.`

The source `readme.md` file MUST NOT be deleted as part of this strategy. Deletion follows
the standard cleanup prompt flow only after Option A or Option B has been successfully applied
AND the user explicitly confirms cleanup.

If `readme.md` content is already present in `CLAUDE.md` (detected by the presence of the
`<!-- .claude/readme.md -->` marker), the organizer MUST skip the advisory and record:
`readme.md — already integrated (skipped)`.

#### Scenario 1: readme.md classified as LEGACY_MIGRATION instead of UNEXPECTED

- **GIVEN** `.claude/readme.md` exists at the immediate `.claude/` level
- **WHEN** the organizer runs its classification pass
- **THEN** `readme.md` is classified as `LEGACY_MIGRATION`
- **AND** it is NOT classified as `UNEXPECTED`

#### Scenario 2: Plan presents Option A and Option B for readme.md

- **GIVEN** `.claude/readme.md` is classified as `LEGACY_MIGRATION`
- **WHEN** the organizer presents the migration plan to the user
- **THEN** both Option A (integrate into CLAUDE.md) and Option B (move to docs/README-claude.md) are shown

#### Scenario 3: Option A appends content with marker to CLAUDE.md

- **GIVEN** `.claude/readme.md` is classified as `LEGACY_MIGRATION`
- **AND** the user selects Option A
- **WHEN** the migration is applied
- **THEN** the content of `readme.md` is appended to `CLAUDE.md`
- **AND** the appended block is preceded by the marker `<!-- .claude/readme.md -->`

#### Scenario 4: Option B copies file to docs/README-claude.md

- **GIVEN** `.claude/readme.md` is classified as `LEGACY_MIGRATION`
- **AND** the user selects Option B
- **WHEN** the migration is applied
- **THEN** `readme.md` is copied to `docs/README-claude.md`

#### Scenario 5: User skips category — source file preserved and skip recorded

- **GIVEN** `.claude/readme.md` is classified as `LEGACY_MIGRATION`
- **AND** the user skips the category (selects neither Option A nor Option B)
- **WHEN** the organizer finishes
- **THEN** `.claude/readme.md` still exists at its original path
- **AND** the report records: `readme.md — skipped by user. Recommend manual review.`

#### Scenario 6: Already-integrated readme.md is silently skipped

- **GIVEN** `.claude/readme.md` exists
- **AND** `CLAUDE.md` already contains the marker `<!-- .claude/readme.md -->`
- **WHEN** the organizer runs
- **THEN** no migration options are presented for `readme.md`
- **AND** the report records: `readme.md — already integrated (skipped)`

---
