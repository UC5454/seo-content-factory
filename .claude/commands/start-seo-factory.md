---
description: Launch the SEO Content Factory - full pipeline from keyword to published article
---

Launch the SEO Content Factory. Runs a 7-phase pipeline that takes a target keyword
and produces a fully SEO/AIO-optimized article with thumbnail, reviews, and storage.

Works on **any terminal** (iTerm2, Antigravity, Terminal.app, Warp, Linux terminals).

## Usage

```
/start-seo-factory target keyword
/start-seo-factory target keyword --memo "additional instructions"
/start-seo-factory --visual target keyword
```

## Options

- `--visual`: Open each phase in a new terminal window (macOS only, auto-detects terminal)
- Without `--visual`: Runs headless — works everywhere, any terminal, any OS

## Execution

Parse $ARGUMENTS:
- If starts with `--visual`, extract flag and remaining as KW + memo
- If contains `--memo`, split on it: before = KW, after = memo
- Otherwise: all = KW, no memo

```bash
# Headless (default - works on any terminal)
bash "tools/start-seo-factory.sh" "KEYWORD" "MEMO"

# Visual (opens new windows)
bash "tools/start-seo-factory.sh" --visual "KEYWORD" "MEMO"
```

## Pipeline

| Phase | Agent | Mode |
|---|---|---|
| 0 | SEO Analyst | Sequential |
| 1 | Researcher | Sequential |
| 2 | Writer | Sequential |
| 3a | Designer | Parallel |
| 3b | QA | Parallel |
| 3c | SEO Analyst | Parallel |
| 4 | Publisher | Sequential |

## Scoring & Quality Gate

- SEO/AIO/E-E-A-T triple scoring (100 pts each)
- 85+: Auto-approve
- 70-84: Conditional approve
- ≤69: Auto-reject → Writer revision loop

User input: $ARGUMENTS
