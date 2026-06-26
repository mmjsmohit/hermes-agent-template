#!/usr/bin/env bash
set -euo pipefail

# Start continuous Obsidian Sync for Hermes llm-wiki.
# Intended to be launched by start.sh after the initial setup has succeeded once.

WIKI_PATH="${WIKI_PATH:-/data/.hermes/home/wiki}"
LOG_DIR="${HERMES_HOME:-/data/.hermes}/logs"
mkdir -p "$LOG_DIR"

if ! command -v ob >/dev/null 2>&1; then
  echo "[obsidian-sync] ob CLI missing; skipping continuous sync" >&2
  exit 0
fi

if [ ! -d "$WIKI_PATH/.obsidian" ]; then
  echo "[obsidian-sync] $WIKI_PATH is not configured for Obsidian Sync yet; run setup once first" >&2
  exit 0
fi

cd "$WIKI_PATH"
exec ob sync --path "$WIKI_PATH" --continuous >> "$LOG_DIR/obsidian-sync.log" 2>&1
