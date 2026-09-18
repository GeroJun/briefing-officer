#!/usr/bin/env bash
# Resolve the Obsidian vault root.
#
# Usage: resolve-vault.sh [start_dir]
#   start_dir defaults to $PWD, used only when $VAULT_ROOT is unset.
#
# Behavior:
#   - If $VAULT_ROOT is set (even to a path that doesn't exist yet), print it and exit 0.
#   - Otherwise walk up from start_dir looking for a directory containing ".obsidian".
#     Print the first match and exit 0.
#   - If nothing is found by the time we reach "/", print nothing and exit 1.
set -euo pipefail

start_dir="${1:-$PWD}"

if [ -n "${VAULT_ROOT:-}" ]; then
  printf '%s\n' "$VAULT_ROOT"
  exit 0
fi

dir="$start_dir"
while [ "$dir" != "/" ]; do
  if [ -d "$dir/.obsidian" ]; then
    printf '%s\n' "$dir"
    exit 0
  fi
  dir="$(dirname "$dir")"
done

exit 1
