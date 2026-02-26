---
name: skill-creator
description: >
  Creates new skills, either generic for the global catalog or specific to the current project.
  Trigger: /skill-create <name>, create skill, new skill, generate skill, add skill to project.
---

# skill-creator

> Creates new skills, either generic for the global catalog or specific to the current project.

**Triggers**: skill:create, skill:add, create skill, new skill, generate skill, add skill to project

---

## Two modes of operation

### Mode `/skill-create <name>`
Creates a **new** skill that does not exist anywhere. Asks whether it is:
- **Generic** → goes to `~/.claude/skills/<name>/SKILL.md` (available in all projects)
- **Project-specific** → goes to `.claude/skills/<name>/SKILL.md` (only in this project)

### Mode `/skill-add <name>`
Adds an **existing skill from the global catalog** to the current project. Copies or creates a reference.

---

## Process: /skill-create

### Step 1 — Gather information

Ask the necessary questions to create a useful skill:

```
Is this skill for this specific project or for all your projects?
  1. This project only → .claude/skills/
  2. Global catalog → ~/.claude/skills/

What does this skill do? (one-sentence description)

When should it activate? (what situations trigger its use?)

Are there specific code patterns, commands, or processes it should know about?
```

If the user has already provided enough context in the command, skip obvious questions.

### Step 2 — If project skill: analyze the code

Read the existing project code to:
- Detect real patterns to document
- Find real examples to include in the skill
- Identify existing anti-patterns that must be avoided

### Step 3 — Generate the skill

**Standard SKILL.md format:**

```markdown
# [skill-name]

> [One-line description. What it does and what it is for.]

**Triggers**: [word1, word2, situation1, situation2]

---

## When to use this skill

[Explanation of the contexts where it applies]
[Specific conditions that activate it]

## Main Patterns

### [Pattern 1]: [Descriptive name]
[Explanation of the pattern]

```[language]
[real example code]
```

### [Pattern 2]: [Descriptive name]
[Explanation]

```[language]
[example code]
```

### [Pattern 3]: [Descriptive name]
[Explanation]

```[language]
[example code]
```

## Complete Examples

### [Scenario 1]
[Complete, executable code]

### [Scenario 2]
[Complete, executable code]

## Anti-Patterns — What to Avoid

### ❌ [Thing to avoid]
[Why it is problematic]

```[language]
// ❌ Bad
[bad code]
```

```[language]
// ✅ Good
[correct code]
```

## Quick Reference

| Task | Pattern/Command |
|------|----------------|
| [common task] | [solution] |
| [common task] | [solution] |
```

### Step 4 — Preview and confirm

Show the content to be created and confirm with the user before writing.

### Step 5 — Create and register

1. Create the file at the corresponding path
2. If it is a project skill, suggest adding it to the project `CLAUDE.md` in the skills section
3. If it is a generic skill, add it to the registry in `~/.claude/CLAUDE.md`

---

## Process: /skill-add

When the user runs `/skill-add <name>`:

### Verify it exists in the global catalog
```
~/.claude/skills/<name>/SKILL.md
```

If it does not exist:
```
The skill "<name>" is not in the global catalog.
Similar available skills: [list of similar skills]

Do you want to create a new one with /skill-create <name>?
```

### Verify the project has `.claude/skills/`
If it does not exist, create it.

### Addition strategy

**Option A — Conceptual symbolic reference:**
Add the skill to the project `CLAUDE.md` in the active skills section, indicating it is in the global catalog.

```markdown
## Active Skills
- `~/.claude/skills/typescript/SKILL.md` — TypeScript patterns
- `~/.claude/skills/nextjs-15/SKILL.md` — Next.js 15 patterns
```

**Option B — Local copy** (if the user wants to customize):
Copy the file to `.claude/skills/<name>/SKILL.md` and add an origin note.

### Update project CLAUDE.md

Add the skill to the project registry so it is visible.

---

## Global Catalog Skills

Current catalog available in `~/.claude/skills/`:

### Meta-tools and SDD

| Skill | Purpose |
|-------|---------|
| `project-setup` | Project setup with SDD |
| `project-audit` | Configuration audit |
| `project-update` | Configuration updates |
| `skill-creator` | Skill creation |
| `memory-manager` | Project memory management |
| `sdd-explore` | SDD exploration phase |
| `sdd-propose` | SDD proposal phase |
| `sdd-spec` | SDD specifications phase |
| `sdd-design` | SDD technical design phase |
| `sdd-tasks` | SDD task plan phase |
| `sdd-apply` | SDD implementation phase |
| `sdd-verify` | SDD verification phase |
| `sdd-archive` | SDD archive phase |

### Frontend / Full-stack

| Skill | Purpose |
|-------|---------|
| `react-19` | React 19 with React Compiler, Server Components, use() hook |
| `nextjs-15` | Next.js 15 App Router, Server Actions, data fetching |
| `typescript` | TypeScript strict mode, utility types, advanced patterns |
| `zustand-5` | State management with Zustand 5, slices, persistence |
| `zod-4` | Schema validation with Zod 4, breaking changes from v3 |
| `tailwind-4` | Tailwind CSS 4, cn() utility, dynamic styles |
| `ai-sdk-5` | Vercel AI SDK 5, useChat, streaming, tool integration |
| `react-native` | React Native with Expo, navigation, NativeWind |
| `electron` | Electron desktop apps, IPC, auto-updater |

### Backend

| Skill | Purpose |
|-------|---------|
| `django-drf` | Django REST Framework, ViewSets, Serializers |
| `spring-boot-3` | Spring Boot 3.3+, constructor injection, @ConfigurationProperties |
| `hexagonal-architecture-java` | Hexagonal architecture in Java, Ports & Adapters |
| `java-21` | Java 21, records, sealed types, virtual threads |

### Testing

| Skill | Purpose |
|-------|---------|
| `playwright` | E2E testing with Playwright, Page Object Model |
| `pytest` | Python testing with pytest, fixtures, mocking, async |

### Tooling / Process

| Skill | Purpose |
|-------|---------|
| `github-pr` | Pull Requests with conventional commits and gh CLI |
| `jira-task` | Create Jira tasks with standard structure and Wiki markup |
| `jira-epic` | Create Jira epics with overview, requirements, and decomposition |

### Languages / Frameworks

| Skill | Purpose |
|-------|---------|
| `elixir-antipatterns` | Elixir/Phoenix anti-patterns: error handling, Ecto, testing |

> **Note**: `angular` is not available (404 in the source repo). It can be created with `/skill-create angular`.

---

## Rules

- Always use real project code as examples when it is a project skill
- Never invent patterns — extract them from existing code
- Minimum 3 code examples per skill
- Always include anti-patterns
- Preview and confirm before writing
- Register the new skill in the corresponding CLAUDE.md
