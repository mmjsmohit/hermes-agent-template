#!/usr/bin/env bash
set -euo pipefail

# Commit and push llm-wiki updates immediately after a mutation.
# Usage:
#   hermes-wiki-git-sync-push.sh "wiki: ingest anthropic safety article"

WIKI_PATH="${WIKI_PATH:-/data/.hermes/home/wiki}"
GIT_SYNC_REMOTE="${GIT_SYNC_REMOTE:-origin}"
GIT_SYNC_BRANCH="${GIT_SYNC_BRANCH:-main}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_PAT="${GITHUB_PAT:-}"
commit_message="${1:-}"

require() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "ERROR: Required env var '$name' is not set." >&2
    exit 1
  fi
}

require GITHUB_USERNAME
require GITHUB_PAT

if [ -z "$commit_message" ]; then
  echo "ERROR: Commit message argument is required." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is not installed." >&2
  exit 1
fi

cd "$WIKI_PATH"

if [ ! -d .git ]; then
  echo "ERROR: $WIKI_PATH is not a git repository. Run setup first." >&2
  exit 1
fi

git add -A
if git diff --cached --quiet; then
  echo "No wiki changes to commit."
  exit 0
fi

git commit -m "$commit_message"
auth_b64="$(printf '%s:%s' "$GITHUB_USERNAME" "$GITHUB_PAT" | base64 -w0)"
git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $auth_b64" \
  push "$GIT_SYNC_REMOTE" "$GIT_SYNC_BRANCH"

echo "Pushed wiki changes: $commit_message"
