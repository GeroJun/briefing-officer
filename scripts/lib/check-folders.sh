#!/usr/bin/env bash
# Check that a set of folders exist under a vault root.
#
# Usage: check-folders.sh <vault_root> <dir> [dir ...]
#
# Prints one "MISSING: <dir>" line per folder that doesn't exist under
# <vault_root>. Each <dir> is passed as its own argument (never a
# space-joined string) so folder names containing spaces — e.g.
# "400 Learning  🌱/08 Summaries" — are checked correctly instead of
# being word-split into broken paths.
#
# The caller (a SKILL.md step) decides which dirs belong in the list
# based on the active PROFILE/SKIP_* flags — this script only checks
# existence.
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: check-folders.sh <vault_root> <dir> [dir ...]" >&2
  exit 2
fi

vault_root="$1"
shift

for d in "$@"; do
  if [ ! -d "$vault_root/$d" ]; then
    printf 'MISSING: %s\n' "$d"
  fi
done

exit 0
