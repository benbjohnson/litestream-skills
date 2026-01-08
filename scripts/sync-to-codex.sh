#!/bin/bash
# Sync skills from skills/litestream to .codex/skills/litestream
# Codex ignores symlinks, so we need to copy files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SOURCE_DIR="$REPO_ROOT/skills/litestream"
DEST_DIR="$REPO_ROOT/.codex/skills/litestream"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

echo "Syncing skills to Codex directory..."

# Remove existing codex skill directory
rm -rf "$DEST_DIR"

# Copy skills
cp -r "$SOURCE_DIR" "$DEST_DIR"

echo "Done. Synced $(find "$DEST_DIR" -type f | wc -l | tr -d ' ') files."
