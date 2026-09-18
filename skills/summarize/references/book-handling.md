# Book / EPUB handling — chapter splitting and depth requirements

Loaded from `skills/summarize/SKILL.md` Step 1 (EPUB section) when the source is a book.

## Extraction

```bash
# Extract full text as markdown (preserves chapter structure)
pandoc "<path>" -t markdown --wrap=none -o /tmp/summarize/book.md

# If you need chapter boundaries, extract the TOC:
pandoc "<path>" -t json | python3 -c "
import json, sys
doc = json.load(sys.stdin)
for block in doc['blocks']:
    if block['t'] == 'Header':
        level = block['c'][0]
        text = ''.join(
            item['c'] if item['t'] == 'Str' else ' ' if item['t'] == 'Space' else ''
            for item in block['c'][2]
        )
        print(f'L{level}: {text}')
"
```

## Chapter splitting strategy

1. Extract full text with `pandoc` → markdown
2. Identify chapter boundaries from headers (epubs have built-in TOC structure that pandoc preserves as `#`/`##` headers)
3. Split into one chunk per chapter
4. Dispatch parallel Opus subagents — **one per chapter** — same as any other long content
5. A typical book (60-100k words, 15-30 chapters) produces chapters of ~3-5k words each — well within subagent context limits

**For very long books (>30 chapters):** batch chapters into groups of ~5 per subagent to keep the number of parallel agents manageable. Each subagent summarizes its batch and returns section summaries.

## CRITICAL — Book summary depth requirement

- Each chapter MUST get its own dedicated `## Chapter N: Title` section with a **substantial** summary (300-600 words per chapter depending on chapter length)
- Do NOT batch multiple chapters into a single brief paragraph — every chapter gets its own detailed treatment
- Include key arguments, data points, examples, and quotes from each chapter
- A 10-chapter book should produce ~3000-6000 words of summary content (excluding frontmatter/tldr)
- A 30-chapter book should produce ~5000-10000 words
- Think of each chapter summary as a standalone mini-essay that captures the chapter's core contribution
- The goal is that someone reading the summary should understand what each chapter argues, not just what the book is "about" at a high level

## Output structure for books

- Location: `08 Summaries/<Book Title>.md` (or `08 Summaries/<Author>/<Book Title>.md` if summarizing multiple books by one author)
- Frontmatter tag: `book`
- Extra fields: `creator` (author wikilink), `published` (year), `isbn` (if known), `source` (wikilink to the epub file if it's in the vault, e.g. `"[[Book Title.epub]]"`)
- Each chapter gets its own `## Chapter N: Title` section in the summary
- Add a `## Chapter Navigation` callout at the top if the book has many chapters

**In `PROFILE=learning`:** ignore the `<Author>/` subfolder option — output always lands flat at `$SUMMARIES_DIR/<Book Title>.md` per the Step 2 override.
