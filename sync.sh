#!/usr/bin/env bash
# sync.sh — Captures current ~/.claude/ state into the repo for committing.
# Run before: git add -A && git commit

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Syncing $CLAUDE_DIR → $REPO_DIR ..."

# Copy single files
cp "$CLAUDE_DIR/CLAUDE.md"    "$REPO_DIR/CLAUDE.md"
cp "$CLAUDE_DIR/settings.json" "$REPO_DIR/settings.json"

# Copy directories (cross-platform: no rsync required)
sync_dir() {
  local src="$1"
  local dst="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    # Remove destination contents first to mirror --delete behavior
    rm -rf "${dst:?}/"*  2>/dev/null || true
    cp -r "$src/." "$dst/"
    echo "  synced: $src → $dst"
  else
    echo "  skipped (not found): $src"
  fi
}

sync_dir "$CLAUDE_DIR/memory"     "$REPO_DIR/memory"
sync_dir "$CLAUDE_DIR/skills"     "$REPO_DIR/skills"
sync_dir "$CLAUDE_DIR/hooks"      "$REPO_DIR/hooks"
sync_dir "$CLAUDE_DIR/openspec"   "$REPO_DIR/openspec"
sync_dir "$CLAUDE_DIR/ai-context" "$REPO_DIR/ai-context"

echo ""
echo "Done. Review changes with: git diff"
echo "Then commit with: git add -A && git commit -m 'chore: sync claude config'"
