#!/usr/bin/env bash
# install.sh — Restaura la configuración de Claude Code desde el repo a ~/.claude/
# Usar al configurar una máquina nueva o restaurar después de un reset.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing claude-config → $CLAUDE_DIR ..."

mkdir -p "$CLAUDE_DIR"

cp "$REPO_DIR/CLAUDE.md"     "$CLAUDE_DIR/CLAUDE.md"
cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"

rsync -a --delete "$REPO_DIR/memory/"  "$CLAUDE_DIR/memory/"
rsync -a --delete "$REPO_DIR/skills/"  "$CLAUDE_DIR/skills/"
rsync -a --delete "$REPO_DIR/hooks/"   "$CLAUDE_DIR/hooks/"

echo ""
echo "Done! Claude Code está listo con:"
echo "  - CLAUDE.md (orquestador SDD)"
echo "  - $(ls "$CLAUDE_DIR/skills/" | wc -l) skills cargadas"
echo "  - Memoria en $CLAUDE_DIR/memory/"
echo ""
echo "Nota: settings.local.json NO se restaura — Claude Code lo genera automáticamente."
