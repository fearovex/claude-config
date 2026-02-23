# Claude Code Expert

> Expert in Claude Code configuration, architecture, and best practices for development projects.

## Description

This skill provides specialized knowledge about:
- CLAUDE.md file configuration
- Creating custom skills
- Slash commands and hooks
- AI file architecture for projects
- MCP server integration
- Optimized workflows

**Triggers**: claude code, CLAUDE.md, configure claude, skills, hooks, mcp, claude commands, AI architecture, setup project claude, claude config, claude setup

---

## File Structure for Claude Code

```
project/
├── CLAUDE.md                    # Main project memory (root)
├── .claude/
│   ├── CLAUDE.md               # Alternative for project memory
│   ├── settings.json           # Hooks and configuration
│   ├── settings.local.json     # Local config (don't commit)
│   ├── skills/                 # Custom skills
│   │   └── my-skill/
│   │       └── SKILL.md
│   ├── commands/               # Custom slash commands
│   │   └── my-command.md
│   └── agents/                 # Specialized agents
│       └── my-agent.md
├── .mcp.json                    # MCP servers configuration
└── docs/
    └── architecture/           # Architecture documentation
```

### CLAUDE.md Hierarchy

Files are loaded in this priority order:
1. `~/.claude/CLAUDE.md` - Global (applies to all sessions)
2. `./CLAUDE.md` - Project root (shared with team)
3. `./.claude/CLAUDE.md` - Alternative in .claude folder
4. `./subdirectory/CLAUDE.md` - Folder-specific (loaded on demand)

---

## CLAUDE.md Configuration

The CLAUDE.md is the most important file for Claude Code. It's the agent's "constitution".

### Recommended Template

```markdown
# Project Name

## Description
[Brief description of the project and its purpose]

## Tech Stack
- **Frontend**: [React/Vue/Angular/etc.]
- **Backend**: [Node/Python/Go/etc.]
- **Database**: [PostgreSQL/MongoDB/etc.]
- **Infrastructure**: [AWS/GCP/Docker/etc.]

## Main Commands

### Development
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run test` - Run tests
- `npm run lint` - Check code

### Database
- `npm run db:migrate` - Run migrations
- `npm run db:seed` - Seed test data

## Project Structure

src/
├── components/     # Reusable components
├── pages/          # Main pages/views
├── services/       # Business logic and APIs
├── hooks/          # Custom hooks
├── utils/          # Utilities and helpers
├── types/          # Type definitions
└── stores/         # Global state (Zustand/Redux)

## Code Conventions

### Naming
- Components: PascalCase (`UserProfile.tsx`)
- Functions/variables: camelCase (`getUserData`)
- Constants: UPPER_SNAKE_CASE (`API_BASE_URL`)
- Utility files: kebab-case (`date-utils.ts`)

### Style
- Use ES Modules (import/export), NOT CommonJS (require)
- Prefer arrow functions for components
- Destructure props in components
- Use TypeScript strict mode

## Architectural Patterns

### State Management
[Describe how state is managed: Context, Zustand, Redux, etc.]

### Data Fetching
[Describe pattern: React Query, SWR, custom hooks, etc.]

### Error Handling
[Describe error boundaries strategy, try-catch, etc.]

## Testing

### Conventions
- Test files alongside code: `Component.test.tsx`
- Use `describe` to group related tests
- Name tests descriptively: "should render user name when logged in"

### Running Tests
- `npm test` - All tests
- `npm test -- --watch` - Watch mode
- `npm test -- path/to/file` - Specific test

## Important Rules

1. **DO NOT** modify files in `/core` without review
2. **ALWAYS** add tests for new functionality
3. **NEVER** commit credentials or .env files
4. **PREFER** composition over inheritance
5. **AVOID** any in TypeScript - use specific types

## Common Mistakes to Avoid

- Don't use `console.log` in production (use logger)
- Don't fetch directly in components (use hooks/services)
- Don't mutate state directly in React
- Don't ignore TypeScript errors with @ts-ignore
```

---

## Creating Skills

Skills extend Claude's knowledge with domain-specific information.

### Skill Structure

```markdown
# Skill Name

> Brief one-line description

## Description

Detailed description of the skill's purpose.
Include keywords users would naturally mention.

**Triggers**: keyword1, keyword2, trigger phrase, etc.

---

## Skill Content

[Information, patterns, examples, best practices]

### Good vs Bad Examples

#### Bad
```code
// Code you should NOT write
```

#### Good
```code
// Correct code
```
```

### Skills Location

```
.claude/skills/
├── react-patterns/
│   └── SKILL.md
├── api-design/
│   └── SKILL.md
├── testing-strategies/
│   └── SKILL.md
└── database-patterns/
    └── SKILL.md
```

### Best Practices for Skills

1. **Keep focused**: Less than 500 lines per skill
2. **Rich trigger descriptions**: Claude uses semantic matching
3. **Include examples**: Show good and bad code
4. **Be specific**: Avoid generic info Claude already knows
5. **Update frequently**: Reflect project changes

---

## Custom Commands

Commands are prompt templates accessible via `/command-name`.

### Creating a Command

File: `.claude/commands/review-code.md`

```markdown
# Code Review

Perform a thorough code review of $ARGUMENTS considering:

## Review Checklist

### Code Quality
- [ ] Clear and descriptive naming
- [ ] Small functions with single responsibility
- [ ] No duplicated code
- [ ] Appropriate error handling

### Security
- [ ] No injection vulnerabilities
- [ ] Input validation
- [ ] No hardcoded credentials
- [ ] User data sanitization

### Performance
- [ ] No obvious memory leaks
- [ ] Optimized queries
- [ ] Lazy loading where applicable

### Testing
- [ ] Unit tests for business logic
- [ ] Integration tests for critical flows
- [ ] Edge cases covered

## Expected Output

Provide:
1. List of issues found (critical, warnings, suggestions)
2. Corrected code for each critical issue
3. Executive summary of overall quality
```

### Variables in Commands

- `$ARGUMENTS` - Arguments passed to command
- `$FILE` - Current selected file
- `$SELECTION` - Selected text

### Recommended Commands

| Command | Purpose |
|---------|---------|
| `/review` | Review code |
| `/test` | Generate tests |
| `/refactor` | Refactor code |
| `/docs` | Generate documentation |
| `/debug` | Analyze and debug |
| `/optimize` | Optimize performance |
| `/security` | Security audit |

---

## Hooks (Automation)

Hooks execute scripts in response to Claude Code events.

### Configuration in settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "node .claude/hooks/pre-edit.js"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "npm run lint:fix -- $FILE"
      }
    ],
    "UserPromptSubmit": [
      {
        "command": "node .claude/hooks/check-context.js"
      }
    ],
    "Stop": [
      {
        "command": "node .claude/hooks/on-complete.js"
      }
    ]
  }
}
```

### Hook Types

| Event | When it runs | Common use |
|-------|--------------|------------|
| `PreToolUse` | Before tool execution | Validate, block actions |
| `PostToolUse` | After tool execution | Format, lint, tests |
| `UserPromptSubmit` | On prompt submit | Enrich context |
| `Stop` | On task completion | Notifications, cleanup |

### Example: Protect main branch

```javascript
// .claude/hooks/pre-edit.js
const { execSync } = require('child_process');

const branch = execSync('git branch --show-current').toString().trim();

if (branch === 'main' || branch === 'master') {
  console.log(JSON.stringify({
    block: true,
    message: 'Cannot edit directly on main branch. Create a branch first.'
  }));
  process.exit(0);
}

console.log(JSON.stringify({ block: false }));
```

### Example: Auto-format after editing

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "npx prettier --write $FILE && npx eslint --fix $FILE"
      }
    ]
  }
}
```

---

## MCP Servers

Model Context Protocol connects Claude with external services.

### .mcp.json Configuration

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    },
    "puppeteer": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    },
    "slack": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}"
      }
    }
  }
}
```

### Popular MCP Servers

| Server | Purpose |
|--------|---------|
| `server-github` | GitHub integration (PRs, issues) |
| `server-postgres` | PostgreSQL queries |
| `server-puppeteer` | Browser automation |
| `server-filesystem` | Controlled file access |
| `server-slack` | Slack integration |
| `server-notion` | Notion access |
| `server-linear` | Issue management with Linear |

---

## Advanced Workflows

### Git Worktrees for Parallel Development

Run multiple Claude sessions simultaneously:

```bash
# Create worktrees
git worktree add ../project-feature-auth feature/auth
git worktree add ../project-feature-ui feature/ui
git worktree add ../project-refactor refactor/database

# Each worktree can have its own Claude session
cd ../project-feature-auth && claude
cd ../project-feature-ui && claude
```

### Planning + Review Pattern

1. **Claude A**: Writes the implementation plan
2. **Claude B**: Reviews the plan as senior engineer (fresh context)
3. After corrections: "Update your CLAUDE.md so you don't repeat this mistake"

### Inspection Checkpoints

Configure points where Claude must stop and show work:

```markdown
## Required Checkpoints

Before implementing, ALWAYS show:
1. Proposed architecture with diagram
2. Files that will be modified
3. Tests that will be added
4. Potential breaking changes

WAIT for approval before writing code.
```

---

## Useful Claude Code Commands

| Command | Description |
|---------|-------------|
| `/init` | Generate initial CLAUDE.md based on project |
| `/help` | View help and available commands |
| `/clear` | Clear conversation context |
| `/compact` | Summarize conversation to save context |
| `/config` | View/modify configuration |
| `/mcp` | Manage MCP servers |
| `/permissions` | Manage permissions |

---

## Initial Setup Checklist

- [ ] Run `/init` to generate base CLAUDE.md
- [ ] Review and customize CLAUDE.md with team conventions
- [ ] Create `.claude/skills/` folder with relevant skills
- [ ] Configure frequent commands in `.claude/commands/`
- [ ] Configure hooks in `settings.json` for automation
- [ ] Add necessary MCP servers in `.mcp.json`
- [ ] Document project architecture
- [ ] Add `.claude/settings.local.json` to `.gitignore`
- [ ] Commit shared configuration to repository

---

## Troubleshooting

### Claude doesn't find files
- Verify CLAUDE.md has correct structure
- Use relative paths from project root

### Skills don't activate
- Check that triggers in description are relevant
- Verify location at `.claude/skills/name/SKILL.md`

### Hooks don't execute
- Verify script execution permissions
- Check Claude Code logs for errors
- Ensure matcher matches the tool

### MCP servers don't connect
- Verify environment variables
- Run command manually to see errors
- Check configuration in `.mcp.json`
