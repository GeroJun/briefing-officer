#!/usr/bin/env bash
# Install the person-note template into a vault's templates folder, if missing.
#
# Usage: install-person-template.sh <vault_root> <templates_dir> <variant> <repo_templates_dir>
#   variant             "minimal" or "full"
#   repo_templates_dir  path to this repo's templates/ folder
#
# Leaves an existing "<templates_dir>/new person template.md" untouched —
# the user may have customized it. Prints one of:
#   INSTALLED: <target path>
#   SKIPPED: already exists
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: install-person-template.sh <vault_root> <templates_dir> <minimal|full> <repo_templates_dir>" >&2
  exit 2
fi

vault_root="$1"
templates_dir="$2"
variant="$3"
repo_templates_dir="$4"

target="$vault_root/$templates_dir/new person template.md"

if [ -f "$target" ]; then
  echo "SKIPPED: already exists"
  exit 0
fi

case "$variant" in
  minimal)
    src="$repo_templates_dir/new person template (minimal).md"
    ;;
  full)
    src="$repo_templates_dir/new person template.md"
    ;;
  *)
    echo "unknown variant: $variant (expected minimal or full)" >&2
    exit 2
    ;;
esac

mkdir -p "$vault_root/$templates_dir"
cp "$src" "$target"
echo "INSTALLED: $target"
