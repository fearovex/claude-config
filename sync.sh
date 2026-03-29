#!/usr/bin/env bash
# sync.sh — Captures global user memory from ~/.claude/memory/ into the repo.
#
# Direction : ~/.claude/memory/  →  repo/memory/
# Scope     : memory/ ONLY
# Excluded  : skills/, hooks/, ai-context/, CLAUDE.md, settings.json
#             (all of those are repo-authoritative — edit in repo, deploy via install.sh)
#
# When to run:
#   Workflow B (memory capture): bash sync.sh → git add memory/ && git commit
#   For config changes use install.sh instead (Workflow A).

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Guard: nothing to do if ~/.claude/memory/ does not exist
if [ ! -d "$CLAUDE_DIR/memory" ]; then
  echo "~/.claude/memory/ not found — nothing to sync."
  exit 0
fi

echo "Syncing $CLAUDE_DIR/memory → $REPO_DIR/memory ..."

mkdir -p "$REPO_DIR/memory"
rm -rf "${REPO_DIR}/memory/"* 2>/dev/null || true
cp -r "$CLAUDE_DIR/memory/." "$REPO_DIR/memory/"

echo ""
echo "Done. memory/ synced from ~/.claude/memory/"
echo "Review with  : git diff memory/"
echo "Commit with  : git add memory/ && git commit -m 'chore: sync user memory'"
