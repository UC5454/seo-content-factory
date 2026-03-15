#!/bin/bash
# resolve-claude.sh
# Claude CLIのパスを動的に解決する共通モジュール
#
# Usage: source "$(dirname "$0")/resolve-claude.sh"
# Result: CLAUDE_CMD variable is set

_resolve_claude() {
    local candidates=(
        "/opt/homebrew/bin/claude"
        "/usr/local/bin/claude"
        "$HOME/.npm-global/bin/claude"
    )

    for c in "${candidates[@]}"; do
        if [ -x "$c" ]; then
            echo "$c"
            return 0
        fi
    done

    # npm global root fallback
    local npm_root
    npm_root=$(npm root -g 2>/dev/null) || true
    if [ -n "$npm_root" ]; then
        local npm_cli="$npm_root/@anthropic-ai/claude-code/cli.js"
        if [ -f "$npm_cli" ]; then
            echo "$npm_cli"
            return 0
        fi
    fi

    # which fallback
    local which_result
    which_result=$(which claude 2>/dev/null) || true
    if [ -n "$which_result" ] && [ -x "$which_result" ]; then
        echo "$which_result"
        return 0
    fi

    return 1
}

CLAUDE_CMD=$(_resolve_claude)
if [ -z "$CLAUDE_CMD" ]; then
    echo "ERROR: Claude CLI not found." >&2
    exit 1
fi
