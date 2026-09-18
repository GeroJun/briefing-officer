# Briefing Officer

> Fork of [reysu/ai-life-skills](https://github.com/reysu/ai-life-skills), restructured and extended — see [NOTICE.md](./NOTICE.md).

A collection of skills I use with Claude Code to improve my life in various ways. Designed to pair with an AI-managed Obsidian vault — the skills read from and write to the vault.

## Skills

- [`skills/summarize/`](./skills/summarize) — drop in a YouTube video, article, PDF, EPUB, or podcast and it writes a summary note into your vault with wikilinks to every person and concept mentioned. Asks detailed vs minimal mode on each run — detailed creates reference notes for every wikilink, minimal leaves them dangling and saves ~85% tokens.
- [`skills/summarize-call/`](./skills/summarize-call) — drop in a call recording (video or audio) and it transcribes with speaker labels, summarizes, and writes a call note + transcript + person notes for the participants. Same detailed / minimal mode as `summarize`.

## Quickstart

```bash
mkdir -p ~/src
git clone https://github.com/GeroJun/briefing-officer ~/src/briefing-officer
ln -s ~/src/briefing-officer/skills/summarize ~/.claude/skills/summarize
ln -s ~/src/briefing-officer/skills/summarize-call ~/.claude/skills/summarize-call
```

Restart Claude Code, then:

```
/summarize https://youtube.com/watch?v=...
/summarize-call ~/Downloads/call-with-alex.mp4
```

See [`docs/install.md`](./docs/install.md) for the full easy-mode install flow (creates a vault, installs templates and plugins), [`docs/configuration.md`](./docs/configuration.md) for depth flags and `PROFILE` (including dropping this into a vault you already maintain), and [`docs/vault-structure.md`](./docs/vault-structure.md) for the expected folder layout.

## Daily Briefs

Two prompt-callout templates land in your vault under `01 Updates/` after install:

- **`📌 Daily Brief.md`** — your day's calendar, email, messages, tasks, weather. Sections + sources are configurable in the prompt callout.
- **`📰 Daily News.md`** — one-page news digest, top story per topic. Topics + languages configurable in the prompt callout.

These aren't skills — they're files with `> [!prompt]` callouts that contain the agent instructions. The agent reads the callout and follows it. Customize by editing the callout in Obsidian.

To run an update, paste either of these into Claude Code:

```
update my daily brief — read the prompt callout in "01 Updates/📌 Daily Brief.md" and follow it

update my daily news — read the prompt callout in "01 Updates/📰 Daily News.md" and follow it
```

For an automatic daily run, set up a recurring task:
- **`/loop`** — runs locally on your machine (machine has to be on at the scheduled time)
- **`/schedule`** — runs in the cloud (works while your machine is off on their servers)

## Optional Obsidian plugins

See [`obsidian-plugins/`](./obsidian-plugins) for details:

- **unread-dot** (vendored in this repo) — blue dot next to notes with `unread: true` in frontmatter. The summarize skills set this flag on every new note, so this plugin gives you a visual "you have new stuff" indicator in the file explorer.
- **flashcards-obsidian** — turn `==highlighted==` text, `Question::Answer` syntax, or `#card` tags into Anki cards. Not vendored here (see `obsidian-plugins/README.md` for why) — install from [reuseman/flashcards-obsidian](https://github.com/reuseman/flashcards-obsidian). Requires Anki + AnkiConnect.

## Development

Shared logic used by both skills lives in `scripts/lib/`, tested with [bats](https://github.com/bats-core/bats-core):

```bash
shellcheck scripts/lib/*.sh
bats tests/lib/
```

Both run in CI on every push/PR — see `.github/workflows/ci.yml`.

## License

MIT — see [`LICENSE`](./LICENSE) and [`NOTICE.md`](./NOTICE.md) for fork attribution.
