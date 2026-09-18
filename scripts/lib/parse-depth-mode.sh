#!/usr/bin/env bash
# Scan an invocation string for a depth-mode token.
#
# Usage: parse-depth-mode.sh "<invocation text>"
#
# Prints "minimal", "detailed", or nothing (if no token is present) to
# stdout and exits 0. Printing nothing means the caller should prompt
# the user interactively — there is no default.
#
# Token lists (must stay in sync with skills/summarize/SKILL.md Step 0.5
# and skills/summarize-call/SKILL.md Step 0.5):
#   minimal:  minimal fast quick --minimal -m
#   detailed: detailed deep full --detailed -d
set -euo pipefail

text="${1:-}"

shopt -s nocasematch 2>/dev/null || true

for token in minimal fast quick '--minimal' '-m'; do
  if [[ " $text " == *" $token "* ]]; then
    echo "minimal"
    exit 0
  fi
done

for token in detailed deep full '--detailed' '-d'; do
  if [[ " $text " == *" $token "* ]]; then
    echo "detailed"
    exit 0
  fi
done

exit 0
