#!/usr/bin/env bash
# Extract every unique wikilink target from a note and report which ones
# don't resolve to an existing file anywhere in the vault.
#
# Usage: audit-wikilinks.sh <vault_root> <note_path>
#
# Prints one "MISSING: <term>" line per dangling wikilink. A link is
# considered resolved if "<vault_root>/**/<term>.md" exists anywhere
# outside .Trash/ and Clippings/.
#
# The regex excludes "|" (alias), "#" (heading ref), and "^" (block ref)
# so [[Target|Alias]], [[Page#Heading]], and [[Page^block]] all resolve
# to the canonical note name (Target / Page).
#
# This is the single shared implementation used by both
# skills/summarize/SKILL.md (Steps 5a/5c) and
# skills/summarize-call/SKILL.md (Step 6) — previously each skill had
# its own inline copy, and summarize-call's copy referenced
# $REFERENCES_DIR without that variable ever being declared in its
# Configuration block, so the audit silently checked an empty path.
# Centralizing it here means there is exactly one place left to get it
# right.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: audit-wikilinks.sh <vault_root> <note_path>" >&2
  exit 2
fi

vault_root="$1"
note_path="$2"

if [ ! -f "$note_path" ]; then
  echo "no such file: $note_path" >&2
  exit 2
fi

terms=$(grep -oE '\[\[[^]|#^]+' "$note_path" | sed 's/\[\[//' | sort -u || true)

if [ -z "$terms" ]; then
  exit 0
fi

while IFS= read -r term; do
  [ -z "$term" ] && continue
  found=$(find "$vault_root" -name "$term.md" \
    -not -path "*/.Trash/*" -not -path "*/Clippings/*" 2>/dev/null | head -1)
  if [ -z "$found" ]; then
    printf 'MISSING: %s\n' "$term"
  fi
done <<< "$terms"
