# OpenClaw Assistant

> Expert guide for installing, configuring, and developing with OpenClaw - the open-source personal AI assistant.

## Description

This skill provides comprehensive knowledge about OpenClaw (formerly Clawdbot/Moltbot), the open-source autonomous AI agent created by Peter Steinberger. Covers installation, configuration, skills development, tool management, messaging integrations, and automation workflows.

**Triggers**: openclaw, clawdbot, moltbot, openclaw setup, openclaw skills, openclaw config, openclaw tools, clawhub, openclaw.json, openclaw channels, openclaw automation, personal AI assistant, openclaw install

---

## What is OpenClaw?

OpenClaw is a free, open-source, self-hosted AI agent runtime that:
- Runs as a long-running Node.js service on your machine
- Connects to messaging platforms (WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Teams)
- Executes real-world tasks via LLMs (Claude, GPT, DeepSeek, local models)
- Has persistent memory across conversations
- Supports browser automation, cron jobs, file management, and more
- 145,000+ GitHub stars, 20,000+ forks

## Installation

### Prerequisites
- Node.js 22 or newer

### Install Commands

**macOS/Linux:**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

### Initial Setup
```bash
# Run onboarding wizard (configures auth, gateway, channels)
openclaw onboard --install-daemon

# Verify gateway is running
openclaw gateway status

# Open Control UI in browser
openclaw dashboard
# Access at http://127.0.0.1:18789/
```

## Configuration

### Main Config File: `~/.openclaw/openclaw.json`

```json5
{
  // LLM Provider
  "providers": {
    "anthropic": { "apiKey": "sk-ant-..." },
    "openai": { "apiKey": "sk-..." }
  },

  // Tool access control
  "tools": {
    "profile": "full",  // minimal | coding | messaging | full
    "allow": ["group:fs", "browser"],
    "deny": ["group:runtime"]
  },

  // Skills configuration
  "skills": {
    "entries": {
      "skill-name": {
        "enabled": true,
        "apiKey": "SECRET_KEY",
        "env": { "API_KEY": "value" }
      }
    },
    "load": {
      "watch": true,
      "watchDebounceMs": 250
    }
  },

  // Browser automation
  "browser": { "enabled": true }
}
```

### Environment Variables
- `OPENCLAW_HOME` - Home directory
- `OPENCLAW_STATE_DIR` - State directory override
- `OPENCLAW_CONFIG_PATH` - Config file path override

## Core Tools

| Tool | Description |
|------|-------------|
| `exec` | Run shell commands in workspace |
| `process` | Manage background sessions (list, poll, kill) |
| `read`/`write`/`edit` | File system operations |
| `web_search` | Search web via Brave API |
| `web_fetch` | Fetch and extract URL content |
| `browser` | Control dedicated Chromium instance |
| `canvas` | Drive node Canvas for presentations |
| `message` | Send messages across all platforms |
| `cron` | Schedule recurring jobs and wakeups |
| `gateway` | Restart/configure the gateway |
| `nodes` | Discover paired devices, capture data |
| `sessions_*` | Inter-session communication, sub-agents |
| `image` | Analyze images with vision models |

### Tool Groups
- `group:runtime` - exec, bash, process
- `group:fs` - read, write, edit, apply_patch
- `group:sessions` - Session management tools
- `group:web` - web_search, web_fetch
- `group:ui` - browser, canvas
- `group:automation` - cron, gateway
- `group:messaging` - message
- `group:openclaw` - All built-in tools

### Tool Profiles
- `minimal` - session_status only
- `coding` - File system, runtime, sessions, memory, image
- `messaging` - Messaging + session tools
- `full` - No restrictions (default)

## Skills System

### What are Skills?
Skills teach OpenClaw HOW to combine tools to accomplish tasks. They are defined in `SKILL.md` files with YAML frontmatter.

### Skill File Format
```markdown
---
name: my-skill
description: What this skill does
user-invocable: true
metadata: {"openclaw":{"requires":{"env":["MY_API_KEY"]}}}
---

## Instructions for the agent

Detailed instructions on how to use this skill...
```

### Skill Locations (Priority Order)
1. `<workspace>/skills/` - Highest priority
2. `~/.openclaw/skills/` - Shared across agents
3. Bundled skills - Shipped with install
4. Extra dirs via `skills.load.extraDirs`

### Installing Skills from ClawHub
```bash
# Install a skill
npx clawhub@latest install <skill-slug>

# Update all skills
clawhub update --all

# Browse at https://clawhub.com
```

### Skill Categories (3,000+ community skills)
- AI & LLMs (287)
- Search & Research (253)
- Web & Frontend Dev (202)
- DevOps & Cloud (212)
- Browser & Automation (139)
- Communication (132)
- CLI Utilities (129)
- Marketing & Sales (143)
- Productivity & Tasks (135)
- Notes & PKM (100)
- Git & GitHub (66)

## Messaging Channels

### Supported Platforms
WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Microsoft Teams, Google Chat, WebChat, Matrix, BlueBubbles, Zalo

### Setup Examples

**WhatsApp:** During `openclaw onboard`, scan QR code with your phone.

**Telegram:** Create a bot via @BotFather, paste token during onboard.

**Discord:** Create a bot in Discord Developer Portal, add token to config.

## Common Use Cases

1. **Email/Inbox Management** - Triage, respond, summarize emails
2. **Calendar Management** - Schedule meetings, check availability
3. **Code Assistant** - Write, review, debug code from any chat app
4. **Browser Automation** - Fill forms, scrape data, navigate web
5. **Smart Home Control** - Manage IoT devices, lights (Hue)
6. **Social Media** - Post, monitor, respond on Twitter/X
7. **Note Taking** - Integration with Obsidian, Notion
8. **DevOps** - Monitor servers, deploy, manage containers
9. **Scheduled Tasks** - Cron-based recurring automations
10. **Multi-device** - Paired nodes for camera, screen, location

## CLI Commands

```bash
openclaw onboard         # Initial setup wizard
openclaw dashboard       # Open Control UI
openclaw gateway status  # Check gateway health
openclaw gateway restart # Restart gateway
openclaw chat            # Quick chat in terminal
openclaw config          # View/edit configuration
```

## Security Best Practices

1. Treat third-party skills as untrusted code - read before enabling
2. Use tool profiles to restrict agent access (`coding` vs `full`)
3. Use `tools.deny` to block dangerous tools for untrusted agents
4. Separate secrets from prompts and logs
5. Use sandbox mode for restricted agents
6. Enable `tools.byProvider` restrictions for less-trusted models

## Official Resources

- Docs: https://docs.openclaw.ai
- GitHub: https://github.com/openclaw/openclaw
- Skills Registry: https://clawhub.com
- Website: https://openclaw.ai
