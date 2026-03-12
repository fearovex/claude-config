#!/usr/bin/env bash
# install.sh — Deploys repo configuration to ~/.claude/ (the Claude Code runtime).
#
# Direction : repo/  →  ~/.claude/
# Scope     : ALL directories (CLAUDE.md, settings.json, skills/, hooks/, openspec/, ai-context/, memory/)
# Note      : memory/ flows the REVERSE direction via sync.sh — run sync.sh periodically
#             to capture Claude's automatic memory updates back into the repo.
#
# Compatible with: Git Bash (MINGW64), WSL, macOS, Linux
#
# When to run:
#   Workflow A (config changes): edit repo → bash install.sh → git commit
#   New machine setup          : git clone → bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Detect the Windows user profile path, working across Git Bash, WSL, Linux
# ---------------------------------------------------------------------------
_win_home_to_unix() {
  # Convert a Windows-style path (C:\Users\foo) to a Unix path usable in the
  # current shell.  Uses cygpath when available (Git Bash / MINGW), otherwise
  # applies a manual sed conversion suited for WSL (/mnt/c/...).
  local win_path="$1"
  if command -v cygpath &>/dev/null; then
    cygpath -u "$win_path"
  else
    echo "$win_path" | sed 's|\\|/|g; s|^\([A-Za-z]\):|/mnt/\L\1|'
  fi
}

_is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

detect_claude_dir() {
  local win_home=""

  # Priority 1 — WSL: Windows env vars are already inherited from the host shell.
  # Skip powershell.exe entirely — calling it from WSL interop can hang.
  if _is_wsl; then
    if [ -n "$USERPROFILE" ]; then
      win_home="$USERPROFILE"
    elif [ -n "$HOMEDRIVE" ] && [ -n "$HOMEPATH" ]; then
      win_home="${HOMEDRIVE}${HOMEPATH}"
    else
      local win_user
      win_user=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r' || true)
      [ -n "$win_user" ] && [ -d "/mnt/c/Users/$win_user" ] && \
        win_home="C:\\Users\\$win_user"
    fi
  fi

  # Priority 2 — Git Bash (MINGW64): use PowerShell for reliable resolution
  if [ -z "$win_home" ] && command -v powershell.exe &>/dev/null; then
    win_home=$(powershell.exe -NoProfile -Command \
      "[Environment]::GetFolderPath('UserProfile')" 2>/dev/null | tr -d '\r\n')
  fi

  # Priority 3 — HOMEDRIVE + HOMEPATH (Git Bash fallback)
  if [ -z "$win_home" ] && [ -n "$HOMEDRIVE" ] && [ -n "$HOMEPATH" ]; then
    win_home="${HOMEDRIVE}${HOMEPATH}"
  fi

  # Priority 4 — USERPROFILE (Git Bash fallback)
  if [ -z "$win_home" ] && [ -n "$USERPROFILE" ]; then
    win_home="$USERPROFILE"
  fi

  if [ -n "$win_home" ]; then
    echo "$(_win_home_to_unix "$win_home")/.claude"
  else
    # Native Linux / macOS
    echo "$HOME/.claude"
  fi
}

CLAUDE_DIR="$(detect_claude_dir)"

echo "Installing agent-config → $CLAUDE_DIR ..."

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

# ---------------------------------------------------------------------------
# Find the claude CLI — needed for MCP registration
# ---------------------------------------------------------------------------
_find_claude_cmd() {
  # Fast path: already in PATH
  if command -v claude &>/dev/null; then
    echo "claude"
    return
  fi

  # Resolve unix_home without calling powershell.exe in WSL (it can hang).
  local unix_home=""
  if _is_wsl; then
    # WSL: Windows env vars are inherited from the host shell
    if [ -n "$USERPROFILE" ]; then
      unix_home="$(_win_home_to_unix "$USERPROFILE")"
    elif [ -n "$HOMEDRIVE" ] && [ -n "$HOMEPATH" ]; then
      unix_home="$(_win_home_to_unix "${HOMEDRIVE}${HOMEPATH}")"
    fi
  elif command -v powershell.exe &>/dev/null; then
    # Git Bash (MINGW64): PowerShell is safe to call
    local win_home
    win_home=$(powershell.exe -NoProfile -Command \
      "[Environment]::GetFolderPath('UserProfile')" 2>/dev/null | tr -d '\r\n')
    [ -n "$win_home" ] && unix_home="$(_win_home_to_unix "$win_home")"
  elif [ -n "$HOMEDRIVE" ] && [ -n "$HOMEPATH" ]; then
    unix_home="$(_win_home_to_unix "${HOMEDRIVE}${HOMEPATH}")"
  elif [ -n "$USERPROFILE" ]; then
    unix_home="$(_win_home_to_unix "$USERPROFILE")"
  fi

  if [ -n "$unix_home" ] && [ -f "$unix_home/.local/bin/claude" ]; then
    echo "$unix_home/.local/bin/claude"
    return
  fi

  # Native Linux / macOS fallback
  if [ -n "$HOME" ] && [ -f "$HOME/.local/bin/claude" ]; then
    echo "$HOME/.local/bin/claude"
    return
  fi

  echo ""  # not found
}

# ---------------------------------------------------------------------------
# Register MCP servers
# ---------------------------------------------------------------------------
echo ""
echo "Registering MCP servers at user level..."

CLAUDE_CMD="$(_find_claude_cmd)"

# Detect the correct npx command for the current environment.
# On Windows (Git Bash / MINGW64), `npx` resolves to npx.cmd via PATH — no
# `cmd /c` wrapper needed (and `cmd /c` causes path mangling in Git Bash where
# `/c` is rewritten to the C:\ root, producing an invalid command).
# On WSL, use plain `npx`.  On Linux/macOS, use plain `npx`.
if command -v npx.cmd &>/dev/null; then
  NPX_RUNNER="npx.cmd -y"
else
  NPX_RUNNER="npx -y"
fi

if [ -n "$CLAUDE_CMD" ]; then
  "$CLAUDE_CMD" mcp remove github     2>/dev/null || true
  "$CLAUDE_CMD" mcp remove filesystem 2>/dev/null || true
  "$CLAUDE_CMD" mcp add -s user github \
    -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
    -- $NPX_RUNNER @modelcontextprotocol/server-github
  "$CLAUDE_CMD" mcp add -s user filesystem \
    -- $NPX_RUNNER @modelcontextprotocol/server-filesystem .
else
  echo "WARNING: 'claude' CLI not found in PATH. MCP servers not registered."
  echo "  Run these manually after installing Claude Code:"
  echo "    claude mcp add -s user github -e GITHUB_TOKEN=\$GITHUB_TOKEN -- npx -y @modelcontextprotocol/server-github"
  echo "    claude mcp add -s user filesystem -- npx -y @modelcontextprotocol/server-filesystem ."
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
