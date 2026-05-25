#!/usr/bin/env bash
set -euo pipefail

CLAUDE_BIN="${HOME}/.local/bin/claude"
CLAUDE_SHARE="${HOME}/.local/share/claude"
CLAUDE_STATE="${HOME}/.local/state/claude"
CLAUDE_CONFIG="${HOME}/.claude"
CLAUDE_CREDS="${HOME}/.claude.json"
CLAUDE_CACHE="${HOME}/Library/Caches/claude-cli-nodejs"
CLAUDE_XDG_CACHE="${HOME}/.cache/claude"

echo "=== Claude Code Uninstaller ==="
echo
echo "Will delete:"
echo "  $CLAUDE_BIN"
echo "  $CLAUDE_SHARE"
echo "  $CLAUDE_STATE"
echo "  $CLAUDE_CONFIG"
echo "  $CLAUDE_CREDS"
echo "  $CLAUDE_CACHE"
echo "  $CLAUDE_XDG_CACHE"
echo
read -r -p "Proceed? [y/N] " confirm
[[ "${confirm}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

removed=0

remove_path() {
    local p="$1"
    if [[ -L "$p" || -f "$p" ]]; then
        rm -f "$p"
        echo "Removed: $p"
        removed=1
    elif [[ -d "$p" ]]; then
        rm -rf "$p"
        echo "Removed: $p"
        removed=1
    fi
}

remove_path "$CLAUDE_BIN"
remove_path "$CLAUDE_SHARE"
remove_path "$CLAUDE_STATE"
remove_path "$CLAUDE_CONFIG"
remove_path "$CLAUDE_CREDS"
remove_path "$CLAUDE_CACHE"
remove_path "$CLAUDE_XDG_CACHE"

if (( removed == 0 )); then
    echo "Nothing found to remove."
else
    echo
    echo "Done. Claude Code fully uninstalled."
fi
