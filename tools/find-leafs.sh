#!/usr/bin/env bash
set -euo pipefail

# Simple script to assist in finding leaves - pages of the story with no options yet.
#
# Usage:
#   find-leafs.sh [directory]
#
# Prints GitHub URLs for markdown files with no markdown links. If no usable GitHub
# remote is configured, prints repository-relative file paths instead.

BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)

if [[ -z "$REMOTE_URL" ]]; then
  FIRST_REMOTE=$(git remote | head -n 1 || true)
  if [[ -n "$FIRST_REMOTE" ]]; then
    REMOTE_URL=$(git remote get-url "$FIRST_REMOTE")
  fi
fi

GITHUB_BASE_URL=""
if [[ "$REMOTE_URL" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  GITHUB_BASE_URL="https://github.com/$OWNER/$REPO/blob/$BRANCH"
elif [[ -n "$REMOTE_URL" ]]; then
  echo "Warning: remote is not a GitHub URL, printing file paths instead." >&2
else
  echo "Warning: no git remote configured, printing file paths instead." >&2
fi

DIR=${1:-./}

find "$DIR" -name '*.md' -print0 |
  while IFS= read -r -d '' file; do
    if ! grep -Eq '\[[^]]+\]\([^)]*\)' "$file"; then
      clean_path=${file#./}
      if [[ -n "$GITHUB_BASE_URL" ]]; then
        echo "$GITHUB_BASE_URL/$clean_path"
      else
        echo "$clean_path"
      fi
    fi
  done
