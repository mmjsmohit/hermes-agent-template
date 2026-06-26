#!/usr/bin/env bash
set -euo pipefail

# One-time Obsidian Sync setup for Hermes llm-wiki on Railway.
# Run inside the Railway container after obsidian-headless is installed.

WIKI_PATH="${WIKI_PATH:-/data/.hermes/home/wiki}"
OBSIDIAN_REMOTE_VAULT_NAME="${OBSIDIAN_REMOTE_VAULT_NAME:-Hermes LLM Wiki}"
OBSIDIAN_DEVICE_NAME="${OBSIDIAN_DEVICE_NAME:-railway-hermes-agent}"
OBSIDIAN_SYNC_ENCRYPTION="${OBSIDIAN_SYNC_ENCRYPTION:-e2ee}"

if ! command -v ob >/dev/null 2>&1; then
  echo "ERROR: obsidian-headless CLI 'ob' is not installed." >&2
  exit 1
fi

mkdir -p "$WIKI_PATH"
cd "$WIKI_PATH"

: "${OBSIDIAN_SYNC_EMAIL:?Set OBSIDIAN_SYNC_EMAIL to your real Obsidian account email}"
: "${OBSIDIAN_SYNC_PASSWORD:?Set OBSIDIAN_SYNC_PASSWORD to your real Obsidian account password}"
: "${OBSIDIAN_E2EE_PASSWORD:?Set OBSIDIAN_E2EE_PASSWORD to your Obsidian Sync E2EE password}"

if [ -n "${OBSIDIAN_MFA:-}" ]; then
  ob login \
    --email "$OBSIDIAN_SYNC_EMAIL" \
    --password "$OBSIDIAN_SYNC_PASSWORD" \
    --mfa "$OBSIDIAN_MFA"
else
  ob login \
    --email "$OBSIDIAN_SYNC_EMAIL" \
    --password "$OBSIDIAN_SYNC_PASSWORD"
fi

# Create remote vault if it does not already exist by name.
if ! ob sync-list-remote | grep -Fq "$OBSIDIAN_REMOTE_VAULT_NAME"; then
  ob sync-create-remote \
    --name "$OBSIDIAN_REMOTE_VAULT_NAME" \
    --encryption "$OBSIDIAN_SYNC_ENCRYPTION" \
    --password "$OBSIDIAN_E2EE_PASSWORD"
fi

# Link local wiki folder to the remote vault.
ob sync-setup \
  --vault "$OBSIDIAN_REMOTE_VAULT_NAME" \
  --path "$WIKI_PATH" \
  --password "$OBSIDIAN_E2EE_PASSWORD" \
  --device-name "$OBSIDIAN_DEVICE_NAME"

# Bidirectional sync:
# - Hermes writes upload to Obsidian Sync.
# - Your Obsidian edits download to Railway.
ob sync-config \
  --path "$WIKI_PATH" \
  --mode bidirectional \
  --conflict-strategy merge \
  --file-types image,audio,video,pdf,unsupported \
  --configs app,appearance,core-plugin,community-plugin,community-plugin-data

# Initial sync.
ob sync --path "$WIKI_PATH"

echo "Obsidian Sync setup complete for $WIKI_PATH ↔ $OBSIDIAN_REMOTE_VAULT_NAME"
