#!/usr/bin/env bash
# Non-interactive install helper for Briefing Officer.
#
# Handles the scriptable parts of the "easy mode" install flow described
# in docs/install.md: creating the vault folder structure and symlinking
# the skills into ~/.claude/skills/. It does not touch Obsidian plugins
# or copy the daily-brief/daily-news templates — those steps are easier
# to walk through interactively in Claude Code (see docs/install.md).
#
# Usage:
#   ./install.sh --vault <path> [--profile full|learning] [--skills-dir <path>]
#
# --vault         Path to the Obsidian vault (created if it doesn't exist).
# --profile       "full" (default) creates the full folder set this repo's
#                 skills expect. "learning" only ensures the vault directory
#                 itself exists — see docs/configuration.md for how
#                 PROFILE=learning works at runtime.
# --skills-dir    Where to symlink skills into. Defaults to ~/.claude/skills.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="full"
SKILLS_DIR="$HOME/.claude/skills"
VAULT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --vault) VAULT="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --skills-dir) SKILLS_DIR="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^#//; s/^ //'
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$VAULT" ]; then
  echo "error: --vault <path> is required" >&2
  exit 2
fi

case "$PROFILE" in
  full|learning) ;;
  *) echo "error: --profile must be 'full' or 'learning'" >&2; exit 2 ;;
esac

echo "==> Creating vault at: $VAULT"
mkdir -p "$VAULT/.obsidian"

if [ "$PROFILE" = "full" ]; then
  for d in "01 Updates" "02 Daily" "03 Meetings" "04 People" "05 Projects" \
           "06 Research" "07 References" "08 Summaries" "_Templates" \
           "_Attachments" "_Bases"; do
    mkdir -p "$VAULT/$d"
  done
  echo "==> Created full vault folder structure"

  "$REPO_ROOT/scripts/lib/install-person-template.sh" "$VAULT" "_Templates" minimal "$REPO_ROOT/templates"

  if [ ! -f "$VAULT/CLAUDE.md" ]; then
    cp "$REPO_ROOT/vault/CLAUDE.md" "$VAULT/CLAUDE.md"
    echo "==> Copied vault/CLAUDE.md"
  fi

  mkdir -p "$VAULT/01 Updates"
  for f in "$REPO_ROOT/vault/01 Updates"/*.md; do
    base="$(basename "$f")"
    target="$VAULT/01 Updates/$base"
    if [ ! -f "$target" ]; then
      cp "$f" "$target"
      echo "==> Copied 01 Updates/$base"
    fi
  done
else
  echo "==> PROFILE=learning: leaving vault structure as-is (skill only writes to \$SUMMARIES_DIR)"
  echo "    Set VAULT_ROOT, PROFILE=learning, and SUMMARIES_DIR in ~/.claude/settings.json — see docs/configuration.md"
fi

echo "==> Symlinking skills into $SKILLS_DIR"
mkdir -p "$SKILLS_DIR"
ln -sf "$REPO_ROOT/skills/summarize" "$SKILLS_DIR/summarize"
ln -sf "$REPO_ROOT/skills/summarize-call" "$SKILLS_DIR/summarize-call"

cat <<EOF

Done.

Next steps:
  1. Set VAULT_ROOT="$VAULT" (in your shell profile, or in ~/.claude/settings.json's "env" block)
  2. Restart Claude Code so it picks up the new skills
  3. Run /summarize or /summarize-call

Not handled by this script (see docs/install.md):
  - Installing the unread-dot / flashcards-obsidian Obsidian plugins
  - Setting up /loop or /schedule for automated daily briefs
EOF
