---
name: summarize-call
description: Transcribe a call recording with speaker diarization, summarize it, and create Obsidian vault notes (call note, transcript, person notes for participants). Works with video or audio files. Supports local transcription (mlx_whisper + pyannote) or ElevenLabs Scribe.
user_invocable: true
---

# Summarize Call

Takes a call recording (video or audio), transcribes it with speaker labels, summarizes it, and writes structured notes into your Obsidian vault.

## Requirements

**Vault structure** — the skill expects these folders inside your Obsidian vault. Folder names are defaults; override them in the Configuration block below if your vault uses different names.

| Folder | Purpose |
|---|---|
| `03 Meetings/` | Where call notes and transcripts land |
| `04 People/` | Person notes for participants |
| `02 Daily/YYYY/MM/` | Daily notes, named `MM-DD-YY ddd.md` |
| `_Templates/` | Note templates — skill installs `new person template.md` here on first run |

**CLI tools** — install these before first use, or let Step 0 walk you through it:

| Tool | Purpose | Install |
|---|---|---|
| `ffmpeg` | Extract audio from video files | macOS: `brew install ffmpeg` · Linux: `apt install ffmpeg` or `dnf install ffmpeg` · Windows: [ffmpeg.org/download.html](https://ffmpeg.org/download.html) |
| `mlx_whisper` (local path) | Local transcription | `pip install mlx-whisper` |
| `pyannote.audio` (local path) | Local speaker diarization | see Step 1 walkthrough |

**Alternative to local**: set `ELEVENLABS_API_KEY` to use ElevenLabs Scribe for transcription + diarization in one call (paid, faster, no setup).

## Configuration

The skill reads these variables at runtime. Override any of them via environment variables, or edit the defaults here:

```
PROFILE          = full               # full | learning — see below
VAULT_ROOT       = $VAULT_ROOT        # auto-detected if not set (see Step 0a)
MEETINGS_DIR     = 03 Meetings
PEOPLE_DIR       = 04 People
REFERENCES_DIR   = 07 References
DAILY_DIR        = 02 Daily
TEMPLATES_DIR    = _Templates
SKIP_REFERENCES  = false   # if true, never create notes for mid-call name-drops (Step 6) — wikilinks stay dangling
SKIP_DAILY       = false   # if true, never update the daily note
```

All paths below are relative to `$VAULT_ROOT`. Steps in this skill call helper scripts under `scripts/lib/` — those paths are relative to this repo's root (`ai-life-skills/`, cloned or symlinked at install time via `~/.claude/skills/summarize-call`), **not** to `$VAULT_ROOT` or `$PWD`. Resolve the repo root once at the start of a run: `dirname "$(dirname "$(readlink -f "$0")")"` from this file's real location if invoked directly, or `~/.claude/skills/summarize-call` (following the symlink) if installed the standard way — then reference `$REPO_ROOT/scripts/lib/<name>.sh`.

### `PROFILE`

For a vault this skill doesn't own outright, `PROFILE=learning` is equivalent to `SKIP_REFERENCES=true` and `SKIP_DAILY=true`. Unlike `summarize`, the call note, transcript, and participant person notes are **not** suppressed by `learning` — they're the actual output of this skill, not side-effect notes. Only the two things `PROFILE=learning` targets are: notes for people/companies/concepts *name-dropped mid-call* (Step 6, same as minimal depth mode) and the daily-note edit. `PROFILE=full` (default) keeps today's behavior.

## Trigger

When the user provides a call recording (MP4, MOV, WAV, MP3, M4A, etc.) and wants it transcribed, summarized, and documented.

## Inputs

- **Recording**: file path to the recording
- **Participants**: names of the people on the call
- **Date/time**: extract from filename if possible, otherwise ask
- **Speaker count**: default 2, ask if ambiguous

## Step 0: Bootstrap check (first run)

Before doing any work, verify the environment is ready. **Skip any check that already passes** — only prompt the user when something is actually missing.

### 0a. Resolve the vault root

```bash
scripts/lib/resolve-vault.sh
```

Prints `$VAULT_ROOT` if it's set, otherwise walks up from `$PWD` looking for a directory containing `.obsidian/`. Exits 1 with no output if nothing is found.

If no vault is found, ask the user:

> **What's the absolute path to your Obsidian vault?**
> Recommended: use a **new, dedicated Obsidian vault** for this skill — not your existing personal vault. The skill creates and modifies many notes and folders, and a clean vault avoids polluting your existing notes. If you don't have one yet, create an empty folder, open it in Obsidian (File → Open vault as folder), and paste that path here.

After they answer, validate that `<answer>/.obsidian/` exists before using it — if not, warn that the path doesn't look like an Obsidian vault (they may need to open it in Obsidian first) and ask them to confirm or re-enter. Use the validated answer as `$VAULT_ROOT` for the session (and suggest they set it permanently in their shell profile).

### 0b. Check required folders

```bash
dirs=("$MEETINGS_DIR" "$PEOPLE_DIR" "$TEMPLATES_DIR")
[ "$SKIP_REFERENCES" = "true" ] || dirs+=("$REFERENCES_DIR")
[ "$SKIP_DAILY" = "true" ] || dirs+=("$DAILY_DIR")
scripts/lib/check-folders.sh "$VAULT_ROOT" "${dirs[@]}"
```

For each missing folder, ask the user: **"Create `<folder>` in your vault? [y/N]"** — if yes, `mkdir -p "$VAULT_ROOT/<folder>"`.

### 0c. Check required CLI tools

```bash
command -v ffmpeg >/dev/null 2>&1 || echo "MISSING: ffmpeg"
```

If ffmpeg is missing, ask the user before installing. Install command depends on the platform:
- macOS: `brew install ffmpeg`
- Linux (Debian/Ubuntu): `sudo apt install ffmpeg`
- Linux (Fedora/RHEL): `sudo dnf install ffmpeg`
- Windows: download from https://ffmpeg.org/download.html

### 0d. Install the person template if missing

Ask the user which version to install:

> **Install person template — which version?**
> 1. **Minimal** (default, works in any vault)
> 2. **Full** (requires Dataview plugin + Obsidian Bases)

Then install it:

```bash
scripts/lib/install-person-template.sh "$VAULT_ROOT" "$TEMPLATES_DIR" minimal templates
# or, if the user picked full:
scripts/lib/install-person-template.sh "$VAULT_ROOT" "$TEMPLATES_DIR" full templates
```

(`templates` is this repo's shared `templates/` folder, relative to the repo root — the same one `summarize` uses.) The script leaves an existing template untouched and prints `SKIPPED: already exists` in that case.

Once Step 0 passes, proceed to Step 0.5.

## Step 0.5: Determine depth mode

Before transcribing, establish which depth the user wants:

1. **Scan the invocation first.** Run:
   ```bash
   scripts/lib/parse-depth-mode.sh "<the user's full invocation text>"
   ```
   Prints `minimal`, `detailed`, or nothing. If it prints a mode, use it and skip the prompt below.
2. **Otherwise, prompt.** No default — if unspecified, ask every time:

> **Depth?**
> 1. **Detailed** (best results) — person notes for every person mentioned, including third parties name-dropped mid-call (celebrities, YouTubers, mutual friends). Public figures get researched biographies.
> 2. **Minimal** (fast) — person notes for call participants only. Name-drops mid-call stay as dangling wikilinks.

This keeps interactive runs explicit while letting scheduled tasks / cron / `/loop` pass the mode in the invocation (e.g. `/summarize-call ~/call.mp4 minimal`) without blocking on input.

The chosen mode determines how Step 6 runs. `SKIP_REFERENCES=true` (including via `PROFILE=learning`) forces minimal-mode Step 6 behavior regardless of depth mode — see the `PROFILE` section above.

## Step 1: Choose transcription method

Ask the user:

> **Transcription method?**
> 1. **Local** (mlx_whisper + pyannote — free, private, slower, requires setup)
> 2. **ElevenLabs Scribe** (paid, faster, handles transcription + diarization in one call)

### Option A: Local — walkthrough if not set up

If the user picks local, verify each component and walk them through any missing piece:

**1. mlx_whisper**
```bash
command -v mlx_whisper >/dev/null 2>&1 || echo "MISSING: mlx_whisper"
```
If missing, ask before installing: `pip install mlx-whisper`

**2. pyannote.audio environment**

Check for the venv at `~/.local/share/summarize-call/pyannote-env` (persists across reboots, XDG-compliant):
```bash
PYANNOTE_ENV="${XDG_DATA_HOME:-$HOME/.local/share}/summarize-call/pyannote-env"
[ -d "$PYANNOTE_ENV" ] || echo "MISSING: pyannote venv"
```

If missing, walk through setup:
```bash
mkdir -p "$(dirname "$PYANNOTE_ENV")"
# Create venv with uv (or python3 -m venv if uv not installed)
uv venv "$PYANNOTE_ENV"
source "$PYANNOTE_ENV/bin/activate"
uv pip install pyannote.audio torch torchaudio
```

**3. HuggingFace token**

Check for `HF_TOKEN`:
```bash
[ -n "$HF_TOKEN" ] || echo "MISSING: HF_TOKEN"
```

If missing, tell the user:
> You need a HuggingFace token with access to the pyannote gated repos.
> 1. Create a token at https://huggingface.co/settings/tokens (choose "Read" scope)
> 2. Accept the terms for all three repos while logged in:
>    - https://huggingface.co/pyannote/speaker-diarization-3.1
>    - https://huggingface.co/pyannote/segmentation-3.0
>    - https://huggingface.co/pyannote/speaker-diarization-community-1
> 3. Export for this session: `export HF_TOKEN="hf_..."`
> 4. To persist, add that line to your `~/.zshrc` (or `~/.bashrc`)

Wait for the user to confirm before continuing.

### Option B: ElevenLabs Scribe — walkthrough if not set up

If the user picks ElevenLabs, check for the API key:
```bash
[ -n "$ELEVENLABS_API_KEY" ] || echo "MISSING: ELEVENLABS_API_KEY"
```

If missing, tell the user:
> You need an ElevenLabs API key.
> 1. Grab one at https://elevenlabs.io/app/settings/api-keys
> 2. Export for this session: `export ELEVENLABS_API_KEY="..."`
> 3. To persist, add that line to your `~/.zshrc` (or `~/.bashrc`)

Wait for the user to confirm before continuing.

**Before calling Scribe**, always print the recording duration and a pricing heads-up so the user can confirm:

> This recording is `<HH:MM:SS>` (`<minutes>` min). Check ElevenLabs pricing at https://elevenlabs.io/pricing for the current per-minute rate on the Scribe model. Continue? [y/N]

## Step 2: Extract audio

```bash
ffmpeg -v quiet -i "<input>" -vn -acodec pcm_s16le -ar 16000 -ac 1 /tmp/<name>.wav -y
```

## Step 3: Transcribe + diarize

### Option A: Local (mlx_whisper + pyannote)

**Transcribe:**
```bash
mlx_whisper --model mlx-community/whisper-large-v3-turbo --language en \
  --output-dir /tmp --output-format json \
  --condition-on-previous-text False /tmp/<name>.wav
```
- Use `--language en` for English calls
- For Japanese: `--language ja` (or use a `kotoba-whisper` model for better accuracy)
- `--condition-on-previous-text False` prevents whisper hallucination loops
- Start processing partial results while transcription is still running — don't block

**Diarize with pyannote:**
```python
from pyannote.audio import Pipeline
import torch, os

pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1",
    use_auth_token=os.environ["HF_TOKEN"]
)
device = "cuda" if torch.cuda.is_available() else ("mps" if torch.backends.mps.is_available() else "cpu")
pipeline.to(torch.device(device))  # GPU if available, CPU otherwise

output = pipeline("/tmp/<name>.wav", num_speakers=<N>)
annotation = output.speaker_diarization
for turn, _, speaker in annotation.itertracks(yield_label=True):
    # save turn.start, turn.end, speaker
```

Note: use `output.speaker_diarization.itertracks(yield_label=True)` (not `output.itertracks`).

**Merge transcript + diarization:**
- Map whisper segments to speaker turns by matching timestamps
- Merge consecutive same-speaker segments into paragraphs
- Format: `[H:MM:SS] **Speaker**: text`

### Option B: ElevenLabs Scribe

```python
import requests, os

url = "https://api.elevenlabs.io/v1/speech-to-text"
headers = {"xi-api-key": os.environ["ELEVENLABS_API_KEY"]}

with open("/tmp/<name>.wav", "rb") as f:
    response = requests.post(
        url,
        headers=headers,
        files={"file": f},
        data={
            "model_id": "scribe_v1",
            "language_code": "<lang>",  # e.g. "eng", "jpn"
            "diarize": "true",
            "timestamps_granularity": "word",
            "num_speakers": <N>
        }
    )

result = response.json()
```

Scribe handles both transcription AND diarization in one call — no pyannote needed. Format the result the same way: `[H:MM:SS] **Speaker**: text`.

## Step 4: Summarize

- Model choice depends on depth mode:
  - **Detailed**: use the highest-quality model available (Opus if the user has access, otherwise Sonnet)
  - **Minimal**: Sonnet — good enough for conversational content at ~5x lower cost
- For long transcripts (>3000 words), split into chunks and summarize each in parallel, then combine
- Extract: key topics, decisions, action items, notable quotes (with speaker attribution)

## Step 5: Create vault notes

### Transcript file
- Location: `$MEETINGS_DIR/<MM-DD-YY Day Participant1 x Participant2> Transcript.md`
- Content: the merged, speaker-labeled transcript with timestamps
- Frontmatter:
  ```yaml
  ---
  date: YYYY-MM-DD
  duration: <seconds>
  meeting: "[[<Call Note Title>]]"
  unread: true
  ---
  ```

### Call note
- Location: `$MEETINGS_DIR/<MM-DD-YY Day Participant1 x Participant2>.md`
- Frontmatter:
  ```yaml
  ---
  created: YYYY-MM-DDTHH:MM
  updated: YYYY-MM-DDTHH:MM
  tags: [call]
  date: YYYY-MM-DD
  start: HH:MM
  end: HH:MM
  duration: <seconds>
  people: ["[[Participant 1]]", "[[Participant 2]]"]
  summary: "1-line description of call topics"
  transcript: "[[<Call Note Title> Transcript]]"
  unread: true
  ---
  ```
- No `# Title` heading — filename is the title
- Body structure:
  ```markdown
  > [!tldr]
  > [2-3 sentence overview]

  ## Key Topics
  - ...

  ## Decisions
  - ...

  ## Action Items
  - [ ] ...

  ## Notable Quotes
  > [!quote] [[Participant 1]]
  > "..."

  ## People Mentioned
  - [[Person Name]] — brief context
  ```
- `summary` frontmatter field is **mandatory** — never omit it
- **Wikilink everything** — people, companies, products, concepts, places

### Person notes
- For each participant: create at `$PEOPLE_DIR/<Full Name>.md` using the template at `$VAULT_ROOT/$TEMPLATES_DIR/new person template.md`
- Extract ALL biographical details mentioned in the call (location, career, family, background)
- For mid-call name-drops: behavior depends on depth mode (see Step 6)

### Daily note
Skip this entire subsection if `SKIP_DAILY=true` (including via `PROFILE=learning`).
- Update `$VAULT_ROOT/$DAILY_DIR/YYYY/MM/MM-DD-YY ddd.md` (create `YYYY/MM/` if missing)
- No `# Title` heading — filename is the title
- Set `unread: true` in frontmatter
- Add under a `## calls/meetings` section:
  ```markdown
  - [[<Call Note Title>]] — brief description
  ```

## Step 6: Handle mid-call name-drops

Skip the reference-note half of this step entirely if `SKIP_REFERENCES=true` (including via `PROFILE=learning`) — see below.

### Detailed mode (or `SKIP_REFERENCES=false`)
For every person, company, product, or concept wikilinked in the call note (that isn't already a note), create a reference or person note:
- **People**: research public figures (birthday, career, links); private individuals get minimal notes based only on what was said
- **Concepts / companies / products**: create in `$REFERENCES_DIR` with a 2-4 sentence explanation
- For large numbers of notes (>10 missing), dispatch parallel subagents (highest available model) in batches of ~20

After all notes are created, audit for dangling links using the shared script:
```bash
scripts/lib/audit-wikilinks.sh "$VAULT_ROOT" "<call_note_path>"
```
It resolves `[[Target|Alias]]`, `[[Page#Heading]]`, and `[[Page^block]]` to their canonical note name and prints one `MISSING: <term>` line per dangling link. Re-create any missed notes. The call is not done until zero dangling links remain.

### Minimal mode (or `SKIP_REFERENCES=true`)
Create person notes only for call participants (those in the `people` frontmatter). All other wikilinks — mid-call name-drops, concepts, companies — stay dangling. Skip the audit.

## Key rules

1. **Wikilink everything** in the call note — every person, company, concept, place
2. **No `# Title` headings** — Obsidian shows filename as title
3. **Never repeat frontmatter in body**
4. **`summary` frontmatter is mandatory** on call notes
5. **`unread: true`** on every note created
6. **Model choice**: detailed uses the highest available model (Opus if accessible, else Sonnet); minimal uses Sonnet. Never Haiku.
7. **Always `--condition-on-previous-text False`** on mlx_whisper to prevent hallucination loops
8. **Auto-detect device** for pyannote (CUDA → MPS → CPU) so it works on any platform
9. **Person note `## updates` links to the call note**, never the daily note
