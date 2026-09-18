# Configuration

## Depth flags (both skills)

Both skills ask "detailed or minimal?" on each run. To skip the prompt — useful for scheduled tasks, `/loop`, or just typing faster — pass the mode in the invocation:

```
/summarize https://youtube.com/... minimal
/summarize https://youtube.com/... detailed
/summarize-call ~/call.mp4 --minimal
/summarize-call ~/call.mp4 -d
```

Accepted tokens:
- **Minimal**: `minimal`, `fast`, `quick`, `--minimal`, `-m`
- **Detailed**: `detailed`, `deep`, `full`, `--detailed`, `-d`

If neither is present, the skill prompts interactively. There's no default — you either pass it or pick when asked.

**What the modes do**:
- **Detailed**: creates reference notes for every wikilink in the output, person notes for every person mentioned (researches public figures), uses the highest-quality model available
- **Minimal**: writes the summary/call note only, leaves wikilinks dangling, creates person notes for creators/guests (or call participants) only, uses Sonnet — saves ~85% on tokens for typical content

This is per-invocation. See `PROFILE` below for a persistent, global override.

## `VAULT_ROOT`

If you run Claude Code from outside your vault, set `VAULT_ROOT`:

```bash
export VAULT_ROOT="/path/to/vault"
```

Otherwise the skills walk up from your current directory looking for `.obsidian/`. Set it in your shell profile, or in `~/.claude/settings.json`'s `env` block, so it applies no matter what directory you run Claude Code from.

## `PROFILE=learning` — already have a vault?

If you're dropping `summarize` (or `summarize-call`) into a vault you already maintain — different folder layout, different conventions — set `PROFILE=learning`:

- **`summarize`**: get **one file per source and nothing else** — no transcript note, no archived audio, no person/reference notes, no daily-note edit, no Bases update. Concepts stay as dangling `[[wikilinks]]` instead of spawning new notes.
- **`summarize-call`**: the call note, transcript, and participant person notes are still created — those are the actual output of the skill, not side effects. `PROFILE=learning` suppresses notes for people/concepts *name-dropped mid-call* and the daily-note edit only.

Set it as an environment variable in your global Claude Code settings (`~/.claude/settings.json`) so it applies no matter what directory you run Claude Code from:

```json
{
  "env": {
    "VAULT_ROOT": "/path/to/your/vault",
    "PROFILE": "learning",
    "SUMMARIES_DIR": "path/to/your/summaries/folder"
  }
}
```

`SUMMARIES_DIR` is relative to `VAULT_ROOT` and can point anywhere — it doesn't need to be named `08 Summaries` or live at the vault root. `PROFILE=full` (the default) keeps today's behavior: transcripts, archived audio, person/reference notes, Bases, the works.

See the `PROFILE` section in each skill's `SKILL.md` Configuration block for the exact list of what each mode does, and the independent `SKIP_REFERENCES` / `SKIP_PEOPLE` / `SKIP_DAILY` flags if you want a custom mix instead of a whole profile.
