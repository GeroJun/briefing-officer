# Obsidian plugins

Two optional Obsidian plugins that may be useful for an automated LLM second brain setup.

## unread-dot

Shows a blue dot next to any note that has `unread: true` in its frontmatter, and auto-clears it when you open the file. Folders containing unread notes also get a dot, so you can see at a glance where new stuff lives. The `summarize` and `summarize-call` skills set `unread: true` on the notes they create, so this plugin is the visual signal that something new is waiting for you.

Bonus features:
- **"Mark all as read"** in the right-click menu on any folder.
- **"Copy callout to clipboard"** command — copies the callout under your cursor, prefixed with "Expand on this:", so you can paste it straight into a Claude conversation.

### Install

```bash
cp -r obsidian-plugins/unread-dot /path/to/your/vault/.obsidian/plugins/
```

Then in Obsidian: Settings → Community plugins → enable "Unread Dot". (You may need to toggle "Restricted mode" off first.)

### Building from source

`main.js` is committed pre-built so the copy-paste install above works without a build step. To modify the plugin:

```bash
cd obsidian-plugins/unread-dot
npm install
npm run build   # bundles src/main.js -> main.js
```

## flashcards-obsidian (Anki)

Creates Anki cards from `==highlighted==` text, `Question::Answer` syntax, `#card` tags, and more. **Not vendored in this repo** — it's a compiled third-party bundle we can't audit, diff, or rebuild without its source, so install it directly from upstream instead:

- Fork used previously: [reuseman/flashcards-obsidian](https://github.com/reuseman/flashcards-obsidian) (or search "Flashcards" in Obsidian's Community Plugins browser)
- Full syntax reference: the [upstream wiki](https://github.com/reuseman/flashcards-obsidian/wiki)

### Install

1. In Obsidian: Settings → Community plugins → Browse → search "Flashcards" → Install → Enable. (Or clone the upstream repo into your vault's `.obsidian/plugins/` folder manually if you need a specific fork.)
2. Install [Anki](https://apps.ankiweb.net/) and the [AnkiConnect](https://ankiweb.net/shared/info/2055492159) add-on. Anki must be running for the plugin to work.
3. Open the plugin's settings to pick the deck, note type, and field mappings you want cards to land in.

### Quick usage

- `==highlighted text==` becomes a cloze card
- `Question::Answer` becomes a basic card
- `Question:::Answer` becomes a reversed card
- Tag a note (or block) with `#card` to make a basic card
- Run the "Flashcards: Generate for the current file" command to push cards to Anki
