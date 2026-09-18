# Install

## Easy mode

Open Claude Code in any directory and paste this:

```
Install the Briefing Officer pack from https://github.com/GeroJun/briefing-officer. Clone the repo to ~/src/briefing-officer, ask me where I want the new Obsidian vault to live, create the vault folder with the full folder structure the skills expect, symlink every skill in the repo into ~/.claude/skills/, copy vault/CLAUDE.md from the repo to the new vault's root, copy the daily-brief and daily-news prompt-callout templates from vault/01 Updates/ into the vault's 01 Updates/ folder, and ask me whether to also install the bundled unread-dot Obsidian plugin into the vault's .obsidian/plugins/ folder.
```

Claude will:
1. Clone the repo
2. Ask where to put the vault (default: `~/ai-vault`)
3. Create the vault folder with the expected structure (see [vault-structure.md](./vault-structure.md))
4. Symlink `summarize` and `summarize-call` (from `skills/`) into `~/.claude/skills/`
5. Copy the person-note template into your vault's `_Templates/` folder
6. Copy `vault/CLAUDE.md` to your vault root (so AI agents know your vault's conventions)
7. Copy `📌 Daily Brief.md` and `📰 Daily News.md` into your vault's `01 Updates/` folder
8. Optionally install the `unread-dot` Obsidian plugin into your vault's `.obsidian/plugins/`

Restart Claude Code so it picks up the new skills. Then run `/summarize` or `/summarize-call`.

Or run [`install.sh`](../install.sh) directly for the non-interactive parts of the same flow:

```bash
./install.sh --vault ~/ai-vault --profile full
```

> **Recommended: use a new, dedicated Obsidian vault** for these skills rather than your existing personal vault. The skills create and modify many notes/folders automatically, and keeping it separate avoids polluting notes you've written yourself.

### If you already have an Obsidian vault

You can point the skills at an existing vault if you want — tell Claude the path instead of creating a new one and it'll only create any missing folders. Just note the recommendation above about a dedicated vault. If your vault has its own structure and conventions, see [`PROFILE=learning`](./configuration.md#profilelearning---already-have-a-vault) in the configuration docs instead of the full install flow.

## Install — individual skill only

If you just want one skill and already have a vault:

```bash
mkdir -p ~/src
git clone https://github.com/GeroJun/briefing-officer ~/src/briefing-officer
ln -s ~/src/briefing-officer/skills/summarize ~/.claude/skills/summarize
# or:
ln -s ~/src/briefing-officer/skills/summarize-call ~/.claude/skills/summarize-call
```

The skills share a `templates/` folder and a `scripts/lib/` helper-script folder at the repo root — leave both where they are; the skills reference them relative to the repo root.

> If you're upgrading from before this repo's restructure (skills used to live at `summarize/` and `summarize-call/` directly in the repo root), re-create your symlinks pointing at the new `skills/` paths above.

## Requirements

- `summarize` uses `yt-dlp`, `defuddle`, `pdftotext`, and `pandoc`
- `summarize-call` uses `ffmpeg` (always), plus either `mlx_whisper` + `pyannote.audio` (local path) or an `ELEVENLABS_API_KEY` (cloud path)

Each skill checks what's missing on first run and asks before installing anything.

## Tested on

- macOS 15 (Darwin 25) on Apple Silicon, Python 3.11+, Claude Code CLI
- Local transcription path assumes a Mac with MPS; the skill auto-detects CUDA / MPS / CPU and falls back to CPU on unsupported devices (slower but functional)
- ElevenLabs Scribe path works on any OS with Python + `requests`
