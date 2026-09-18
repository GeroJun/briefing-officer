# Vault structure

```
your vault/
├── 01 Updates/
├── 02 Daily/YYYY/MM/   # daily notes, named MM-DD-YY ddd.md
├── 03 Meetings/        # call notes + transcripts
├── 04 People/
├── 05 Projects/
├── 06 Research/
├── 07 References/
├── 08 Summaries/
├── _Templates/
├── _Attachments/       # drop ebooks/PDFs here before telling claude to summarize them
└── _Bases/             # optional, only if you use Obsidian Bases
```

Easy-mode install creates this structure for you. If you're using an existing vault, the skills prompt before creating any missing folders on first run. You can also rename any of them in the Configuration block at the top of each SKILL.md.

If your vault already has a different structure entirely, see [`PROFILE=learning`](./configuration.md#profilelearning---already-have-a-vault) instead of trying to make it match this layout.
