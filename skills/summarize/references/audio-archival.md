# Audio archival + click-to-play timestamps

Loaded from `skills/summarize/SKILL.md` Step 1c when `PROFILE=full` and the source has audio (YouTube video, podcast episode, lecture/talk recording).

If the user has the **[Media Extended](https://github.com/aidenlx/media-extended)** Obsidian plugin installed (assume YES unless proven otherwise — it's a common companion plugin for this workflow), move the downloaded source audio into the vault and wire up click-to-play timestamps throughout the summary.

## 1. Archive the audio

Copy (or move) the downloaded mp3/wav/mp4 into `$VAULT_ROOT/_Attachments/` with a descriptive, human-scannable filename that includes the date and — if cropped — the segment range.

```
<Creator> x <Guest> <YYYY-MM-DD>.mp3
<Creator> x <Guest> <YYYY-MM-DD> (HhMMm-HhMMm).mp3   # if cropped
```

**Add `audio: "[[<filename>.mp3]]"`** to the summary note's frontmatter so the attachment is a first-class property on the note (parallel to `transcript:`, `source:`, etc.).

## 2. Embed ONE pinned player at the top

Place a single full-length audio/video embed at the top of the summary, just above the `> [!tldr]` callout:

```markdown
> [!abstract] Audio — full interview (cropped H:MM:SS – H:MM:SS of the VOD)
> ![[<filename>.mp3]]
```

**Do not scatter multiple `![[audio.mp3#t=...]]` embeds through the note** — every embed spawns a fresh player. Media Extended's pattern is one pinned player + many text-link jump-points.

**Do NOT add:**
- A "Pin this player / Media Extended: right-click → Pin" instruction underneath the embed. The user knows how their plugin works. Don't narrate it.
- A "Key moments" / "Jump to" / "Chapters" callout listing timestamped highlights. The per-quote inline jumps (below) already give every notable moment a click-to-play entry point; a separate highlights list is redundant and repeats the same timestamps twice.

## 3. Add inline click-to-play links next to every quote

For every `> [!quote]` callout that embeds a transcript line (`![[...Transcript#^block-id]]`), add a sibling line inside the same callout:

```markdown
> [!quote] Who — what they said
> ![[<Transcript Note>#^block-id]]
> ▶ [[<filename>.mp3#t=<seconds>|jump player to H:MM:SS]]
```

- The `#t=<seconds>` fragment is **audio-local seconds**, not wall-clock VOD time. If the audio was cropped (e.g. starting at VOD 1:17:00), subtract the crop offset from the VOD timestamp before emitting.
- The `|jump player to H:MM:SS` alias is what the user reads — format it `H:MM:SS` when ≥1 hour, else `M:SS`.
- The leading `▶ ` (U+25B6) is a visual cue — keep it.
- These are **text links** (no `!` prefix), not embeds. Media Extended routes the click to the pinned player instead of creating a new one.

## 4. Math for audio-local offsets

```
audio_sec = (vod_h * 3600 + vod_m * 60 + vod_s) - crop_start_sec
```

If the transcript already uses block IDs of the form `^p1-H-MM-SS` (absolute VOD timestamps), this regex transformation converts every quote-embed into one with an audio-local jump link appended:

```python
import re
AUDIO = "<filename>.mp3"
CROP_OFFSET_SEC = <crop start seconds>   # 0 if audio starts at beginning of the source

pattern = re.compile(
    r'^(> !\[\[[^\]]*Transcript#\^p1-(\d+)-(\d+)-(\d+)(?:-\d+)?\]\])$',
    re.MULTILINE,
)

def repl(m):
    block_line = m.group(1)
    h, mm, ss = int(m.group(2)), int(m.group(3)), int(m.group(4))
    audio_sec = (h*3600 + mm*60 + ss) - CROP_OFFSET_SEC
    if audio_sec < 0:
        return block_line
    hh = audio_sec // 3600
    mm2 = (audio_sec % 3600) // 60
    ss2 = audio_sec % 60
    label = f"{hh}:{mm2:02d}:{ss2:02d}" if hh else f"{mm2}:{ss2:02d}"
    return f"{block_line}\n> ▶ [[{AUDIO}#t={audio_sec}|jump player to {label}]]"

text = pattern.sub(repl, text)
```

Run this after Step 4 assembles the summary — it's a pure string transform.

## 5. If the user does NOT have Media Extended

Fall back to native Obsidian syntax: one top-of-note `![[audio.mp3]]` embed only. Do **not** scatter `![[audio.mp3#t=N]]` embeds inline — they each spawn a separate player, which clutters the note. Inline timestamp references in that case should just be the VOD timestamp as plain text.
