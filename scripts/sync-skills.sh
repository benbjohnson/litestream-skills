#!/bin/bash
# Sync skills from skills/litestream to .codex/skills/litestream and .gemini/skills/litestream
# Codex and Gemini ignore symlinks, so we need to copy files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SOURCE_DIR="$REPO_ROOT/skills/litestream"
CODEX_DIR="$REPO_ROOT/.codex/skills/litestream"
GEMINI_DIR="$REPO_ROOT/.gemini/skills/litestream"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

echo "Syncing skills from $SOURCE_DIR..."

# Sync to Codex
echo "  -> Codex: $CODEX_DIR"
rm -rf "$CODEX_DIR"
mkdir -p "$(dirname "$CODEX_DIR")"
cp -r "$SOURCE_DIR" "$CODEX_DIR"

# Sync to Gemini
echo "  -> Gemini: $GEMINI_DIR"
rm -rf "$GEMINI_DIR"
mkdir -p "$(dirname "$GEMINI_DIR")"
cp -r "$SOURCE_DIR" "$GEMINI_DIR"

FILE_COUNT=$(find "$SOURCE_DIR" -type f | wc -l | tr -d ' ')
echo "Done. Synced $FILE_COUNT files to each destination."
