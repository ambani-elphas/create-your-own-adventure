#!/usr/bin/env bash
set -euo pipefail

# Simple script to assist in finding leaves - pages of the story with no options yet.
#
# Usage:
#   find-leafs.sh [--mode auto|url|path] [--remote <name>] [directory ...]
#
# Prints files with no markdown links ("leaf" pages). Output mode:
#   auto (default): GitHub URLs when possible, otherwise repository-relative paths
#   url:            GitHub URLs only (errors if a usable GitHub remote is unavailable)
#   path:           repository-relative file paths

usage() {
  cat <<'USAGE'
Usage:
  find-leafs.sh [--mode auto|url|path] [--remote <name>] [directory ...]

Options:
  --mode <mode>    Output mode: auto, url, or path. Default: auto.
  --remote <name>  Remote name to use for URL generation. Default: origin, then first remote.
  -h, --help       Show this help message.
USAGE
}

MODE="auto"
REMOTE_NAME="origin"
declare -a DIRS=()

while (($# > 0)); do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || {
        echo "Error: --mode requires a value." >&2
        usage
        exit 1
      }
      MODE="$2"
      shift 2
      ;;
    --remote)
      [[ $# -ge 2 ]] || {
        echo "Error: --remote requires a value." >&2
        usage
        exit 1
      }
      REMOTE_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while (($# > 0)); do
        DIRS+=("$1")
        shift
      done
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      DIRS+=("$1")
      shift
      ;;
  esac
done

case "$MODE" in
  auto|url|path) ;;
  *)
    echo "Error: unsupported mode '$MODE'. Use auto, url, or path." >&2
    usage
    exit 1
    ;;
esac

if ((${#DIRS[@]} == 0)); then
  DIRS=("./")
fi

resolve_remote_url() {
  local requested_remote="$1"
  local resolved_url=""

  resolved_url=$(git remote get-url "$requested_remote" 2>/dev/null || true)
  if [[ -n "$resolved_url" ]]; then
    echo "$resolved_url"
    return
  fi

  local first_remote
  first_remote=$(git remote | head -n 1 || true)
  if [[ -n "$first_remote" ]]; then
    git remote get-url "$first_remote"
  fi
}

build_github_base_url() {
  local remote_url="$1"
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)

  if [[ "$remote_url" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    local owner repo
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    echo "https://github.com/$owner/$repo/blob/$branch"
  fi
}

REMOTE_URL=""
GITHUB_BASE_URL=""
if [[ "$MODE" != "path" ]]; then
  REMOTE_URL=$(resolve_remote_url "$REMOTE_NAME" || true)
  GITHUB_BASE_URL=$(build_github_base_url "$REMOTE_URL" || true)
fi

if [[ "$MODE" == "url" && -z "$GITHUB_BASE_URL" ]]; then
  echo "Error: unable to build GitHub URL base from configured remotes." >&2
  exit 1
fi

if [[ "$MODE" == "auto" ]]; then
  if [[ -n "$REMOTE_URL" && -z "$GITHUB_BASE_URL" ]]; then
    echo "Warning: remote is not a GitHub URL, printing file paths instead." >&2
  elif [[ -z "$REMOTE_URL" ]]; then
    echo "Warning: no git remote configured, printing file paths instead." >&2
  fi
fi

for dir in "${DIRS[@]}"; do
  find "$dir" -name '*.md' -print0 |
    while IFS= read -r -d '' file; do
      if ! grep -Eq '\[[^]]+\]\([^)]*\)' "$file"; then
        clean_path=${file#./}
        if [[ -n "$GITHUB_BASE_URL" && "$MODE" != "path" ]]; then
          echo "$GITHUB_BASE_URL/$clean_path"
        else
          echo "$clean_path"
        fi
      fi
    done
done
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
