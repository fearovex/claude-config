#!/usr/bin/env bash
# install.sh — Deploys repo configuration to ~/.claude/ (the Claude Code runtime).
#
# Direction : repo/  →  ~/.claude/
# Scope     : ALL directories (CLAUDE.md, settings.json, skills/, hooks/, openspec/, ai-context/, memory/)
# Note      : memory/ flows the REVERSE direction via sync.sh — run sync.sh periodically
#             to capture Claude's automatic memory updates back into the repo.
#
# When to run:
#   Workflow A (config changes): edit repo → bash install.sh → git commit
#   New machine setup          : git clone → bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect environment: WSL vs Git Bash vs native
# In WSL, $HOME points to /home/<user> which is not the Windows home.
# We need the Windows user profile for ~/.claude/ to be accessible by Claude Code.
detect_claude_dir() {
  if [ -n "$USERPROFILE" ]; then
    # Git Bash on Windows: USERPROFILE is set
    # Convert Windows path to unix-style if needed
    echo "$(cd "$USERPROFILE" 2>/dev/null && pwd)/.claude"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL: read the Windows username and build the path
    local win_user
    win_user=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r' || true)
    if [ -n "$win_user" ] && [ -d "/mnt/c/Users/$win_user" ]; then
      echo "/mnt/c/Users/$win_user/.claude"
    else
      echo "$HOME/.claude"
    fi
  else
    # Native Linux/macOS
    echo "$HOME/.claude"
  fi
}

CLAUDE_DIR="$(detect_claude_dir)"

echo "Installing claude-config → $CLAUDE_DIR ..."

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/memory"
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/openspec"
mkdir -p "$CLAUDE_DIR/ai-context"

# Copy single files
cp "$REPO_DIR/CLAUDE.md"      "$CLAUDE_DIR/CLAUDE.md"
cp "$REPO_DIR/settings.json"  "$CLAUDE_DIR/settings.json"

# Copy directories (cross-platform: no rsync required)
copy_dir() {
  local src="$1"
  local dst="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    cp -r "$src/." "$dst/"
  fi
}

copy_dir "$REPO_DIR/memory"     "$CLAUDE_DIR/memory"
copy_dir "$REPO_DIR/skills"     "$CLAUDE_DIR/skills"
copy_dir "$REPO_DIR/hooks"      "$CLAUDE_DIR/hooks"
copy_dir "$REPO_DIR/openspec"   "$CLAUDE_DIR/openspec"
copy_dir "$REPO_DIR/ai-context" "$CLAUDE_DIR/ai-context"

# Register MCP servers (requires claude CLI in PATH)
echo ""
echo "Registering MCP servers at user level..."

CLAUDE_CMD=""
if command -v claude &>/dev/null; then
  CLAUDE_CMD="claude"
elif [ -f "$HOME/.local/bin/claude" ]; then
  CLAUDE_CMD="$HOME/.local/bin/claude"
elif [ -n "$USERPROFILE" ] && [ -f "$USERPROFILE/.local/bin/claude" ]; then
  CLAUDE_CMD="$USERPROFILE/.local/bin/claude"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  # WSL: try to find claude.exe on Windows side
  win_user=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r' || true)
  if [ -n "$win_user" ] && [ -f "/mnt/c/Users/$win_user/.local/bin/claude" ]; then
    CLAUDE_CMD="/mnt/c/Users/$win_user/.local/bin/claude"
  fi
fi

if [ -n "$CLAUDE_CMD" ]; then
  "$CLAUDE_CMD" mcp remove github     2>/dev/null || true
  "$CLAUDE_CMD" mcp remove filesystem 2>/dev/null || true
  "$CLAUDE_CMD" mcp add -s user github \
    -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
    -- cmd /c npx -y @modelcontextprotocol/server-github
  "$CLAUDE_CMD" mcp add -s user filesystem \
    -- cmd /c npx -y @modelcontextprotocol/server-filesystem .
else
  echo "WARNING: 'claude' CLI not found in PATH. MCP servers not registered."
  echo "  Run these manually after installing Claude Code:"
  echo "    claude mcp add -s user github -e GITHUB_TOKEN=\$GITHUB_TOKEN -- cmd /c npx -y @modelcontextprotocol/server-github"
  echo "    claude mcp add -s user filesystem -- cmd /c npx -y @modelcontextprotocol/server-filesystem ."
fi

echo ""
echo "Done! Claude Code is ready with:"
echo "  - CLAUDE.md (SDD orchestrator)"
echo "  - $(ls "$CLAUDE_DIR/skills/" | wc -l) skills loaded"
echo "  - Memory at $CLAUDE_DIR/memory/"
echo "  - SDD config at $CLAUDE_DIR/openspec/"
echo "  - AI context at $CLAUDE_DIR/ai-context/"
if [ -n "$CLAUDE_CMD" ]; then
  echo "  - MCP: github + filesystem"
else
  echo "  - MCP: NOT registered (claude CLI not found — see warning above)"
fi
echo ""
echo "Note: settings.local.json is NOT restored — Claude Code generates it automatically."
echo "Note: ensure GITHUB_TOKEN is defined as a system environment variable."
