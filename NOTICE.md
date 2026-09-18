# Notice

This repository is a fork of [`reysu/ai-life-skills`](https://github.com/reysu/ai-life-skills) by Eric Su, published under the MIT License (see `LICENSE`). The original `summarize` and `summarize-call` skills, the vault conventions, and the vendored `unread-dot` plugin all originate there.

## What changed in this fork (2026-09)

- Renamed the project to **Briefing Officer**
- Added a `PROFILE=learning` mode to both skills, for dropping them into a vault with its own existing structure rather than one the skill owns end to end — produces one note per source/call instead of the full set of side-effect notes (transcripts, archived audio, reference/person notes, Bases updates)
- Fixed a bug where `summarize-call`'s Step 6 referenced `$REFERENCES_DIR` without that variable ever being declared in its Configuration block
- Extracted the bash logic that was duplicated across both skills (vault resolution, folder checks, person-template install, depth-mode parsing, the dangling-wikilink audit) into shared, tested scripts under `scripts/lib/`, with a `bats` test suite in `tests/lib/` and a GitHub Actions CI workflow
- Split each `SKILL.md`'s rarely-needed detail (book chapter-splitting, audio archival mechanics) into `references/` files loaded on demand
- Split the README into `docs/install.md`, `docs/configuration.md`, `docs/vault-structure.md`
- Removed the vendored `flashcards-obsidian` compiled bundle (no source was included in this repo, so it couldn't be audited or rebuilt) — install instructions now point to the upstream project instead
- Added build tooling (`package.json`, esbuild) to `obsidian-plugins/unread-dot`, which was previously a hand-edited `main.js` with no build step

## A note on local install paths

The skill directories moved from repo-root `summarize/` and `summarize-call/` to `skills/summarize/` and `skills/summarize-call/`. If you have existing symlinks in `~/.claude/skills/` from before this restructure, re-create them pointing at the new paths — see `docs/install.md`.
