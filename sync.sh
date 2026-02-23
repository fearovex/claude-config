#!/usr/bin/env bash
# sync.sh — Copia los archivos actuales de ~/.claude/ al repo para poder hacer commit.
# Usar antes de: git add . && git commit

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Syncing ~/.claude/ → $REPO_DIR ..."

cp "$CLAUDE_DIR/CLAUDE.md"    "$REPO_DIR/CLAUDE.md"
cp "$CLAUDE_DIR/settings.json" "$REPO_DIR/settings.json"

rsync -a --delete "$CLAUDE_DIR/memory/"  "$REPO_DIR/memory/"
rsync -a --delete "$CLAUDE_DIR/skills/"  "$REPO_DIR/skills/"
rsync -a --delete "$CLAUDE_DIR/hooks/"   "$REPO_DIR/hooks/"

echo "Done. Review changes with: git diff"
echo "Then commit with: git add -A && git commit -m 'chore: sync claude config'"
