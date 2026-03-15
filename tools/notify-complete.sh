#!/bin/bash
# Task completion notification
# Usage: ./notify-complete.sh "message"

MESSAGE="${1:-Task completed}"

# macOS notification
if command -v osascript &>/dev/null; then
    afplay /System/Library/Sounds/Hero.aiff &
    osascript -e "display notification \"$MESSAGE\" with title \"SEO Factory\" sound name \"Hero\""
fi

echo "$MESSAGE"
