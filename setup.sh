#!/bin/bash
# ============================================================
# SEO Content Factory - Quick Setup
# ============================================================
# Run this after cloning to set up your environment.
# Usage: ./setup.sh
# ============================================================

set -euo pipefail

echo "==================================================="
echo "  SEO Content Factory - Setup"
echo "==================================================="
echo ""

# 1. Check Claude Code CLI
echo "1. Checking Claude Code CLI..."
if command -v claude &>/dev/null; then
    echo "   Claude Code CLI found: $(which claude)"
else
    echo "   ERROR: Claude Code CLI not found."
    echo "   Install it from: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

# 2. Create config files
echo ""
echo "2. Creating config files..."

if [ ! -f .env ]; then
    cp .env.example .env
    echo "   Created .env (edit this to add your API key)"
else
    echo "   .env already exists, skipping"
fi

if [ ! -f config.yaml ]; then
    cp config.example.yaml config.yaml
    echo "   Created config.yaml (edit this to set your paths)"
else
    echo "   config.yaml already exists, skipping"
fi

# 3. Set permissions
echo ""
echo "3. Setting file permissions..."
chmod +x tools/*.sh
echo "   Done"

# 4. Create output directories
echo ""
echo "4. Ensuring output directories exist..."
for agent in seo-analyst researcher writer designer qa publisher; do
    mkdir -p "example-team/${agent}/outputs" "example-team/${agent}/daily-logs"
done
echo "   Done"

# 5. Verify
echo ""
echo "==================================================="
echo "  Setup Complete!"
echo "==================================================="
echo ""
echo "  Next steps:"
echo ""
echo "  1. Edit .env:"
echo "     ANTHROPIC_API_KEY=sk-ant-xxxxx"
echo ""
echo "  2. Edit config.yaml:"
echo "     - Set your company info"
echo "     - Set primary_source_db.spreadsheet_id"
echo "       (Create from template: https://docs.google.com/spreadsheets/d/1AxYyEM0_Y7HPx0qjvx9rh5qARwE3WYhl5-dqhryr2bI/copy)"
echo ""
echo "  3. Run your first factory:"
echo "     ./tools/start-seo-factory.sh \"your target keyword\""
echo ""
echo "  4. (Optional) Register as Claude Code slash command:"
echo "     cp .claude/commands/start-seo-factory.md /path/to/your/project/.claude/commands/"
echo ""
