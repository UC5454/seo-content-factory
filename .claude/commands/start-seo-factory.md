---
description: Launch the SEO Content Factory - full pipeline from keyword to published article
---

Launch the SEO Content Factory. This runs a 7-phase pipeline that takes a target keyword
and produces a fully SEO/AIO-optimized article with thumbnail, reviews, and Drive storage.

## Usage

```
/start-seo-factory target keyword
/start-seo-factory target keyword --memo "additional instructions"
```

## Execution

Parse $ARGUMENTS to extract keyword and optional memo (split on --memo), then launch:

```bash
osascript -e 'tell application "iTerm2"
    activate
    create window with default profile
    tell current session of current window
        write text "bash \"tools/start-seo-factory.sh\" \"KEYWORD\" \"MEMO\" 2>&1 | tee \"tools/seo-factory-output.log\""
    end tell
end tell'
```

## Pipeline

- Phase 0: SEO Analyst (competitive analysis → brief + outline)
- Phase 1: Researcher (SEO-focused deep research)
- Phase 2: Writer (SEO-optimized article)
- Phase 3a/3b/3c: Designer + QA + SEO Analyst (3 parallel reviews)
- Phase 4: Publisher (Drive storage + notification)

## Features

- SEO/AIO/E-E-A-T triple scoring (100 pts each)
- Auto-reject below score 69 with improvement loop
- Citability blocks for AI search citation
- Schema.org markup recommendations

User input: $ARGUMENTS
