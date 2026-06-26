#!/usr/bin/env bash
set -euo pipefail

# One-time setup for PAT-backed git sync of the hosted llm-wiki.
# Safe to rerun; it is intentionally idempotent.

WIKI_PATH="${WIKI_PATH:-/data/.hermes/home/wiki}"
GIT_SYNC_REMOTE="${GIT_SYNC_REMOTE:-origin}"
GIT_SYNC_BRANCH="${GIT_SYNC_BRANCH:-main}"
GIT_SYNC_REPO_URL="${GIT_SYNC_REPO_URL:-}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_PAT="${GITHUB_PAT:-}"
GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Hermes Agent}"
GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-hermes-agent@users.noreply.github.com}"

require() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "ERROR: Required env var '$name' is not set." >&2
    exit 1
  fi
}

require GIT_SYNC_REPO_URL
require GITHUB_USERNAME
require GITHUB_PAT

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is not installed." >&2
  exit 1
fi

mkdir -p "$WIKI_PATH"
cd "$WIKI_PATH"

if [ ! -d .git ]; then
  git init
fi

# Set branch name predictably.
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ -z "$current_branch" ]; then
  git checkout -B "$GIT_SYNC_BRANCH"
elif [ "$current_branch" != "$GIT_SYNC_BRANCH" ]; then
  git branch -M "$GIT_SYNC_BRANCH"
fi

# Ensure author identity exists for future commits.
git config user.name "$GIT_AUTHOR_NAME"
git config user.email "$GIT_AUTHOR_EMAIL"

# Set or update the remote without embedding the PAT in .git/config.
if git remote get-url "$GIT_SYNC_REMOTE" >/dev/null 2>&1; then
  git remote set-url "$GIT_SYNC_REMOTE" "$GIT_SYNC_REPO_URL"
else
  git remote add "$GIT_SYNC_REMOTE" "$GIT_SYNC_REPO_URL"
fi

# Create the first commit if needed.
git add -A
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  if git diff --cached --quiet; then
    echo "No staged changes for initial commit."
  else
    git commit -m "wiki: initial hosted snapshot"
  fi
else
  git commit -m "wiki: initial hosted snapshot"
fi

auth_b64="$(printf '%s:%s' "$GITHUB_USERNAME" "$GITHUB_PAT" | base64 -w0)"

git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $auth_b64" \
  push -u "$GIT_SYNC_REMOTE" "$GIT_SYNC_BRANCH"

echo "Wiki git sync setup complete: $WIKI_PATH -> $GIT_SYNC_REPO_URL ($GIT_SYNC_BRANCH)"
