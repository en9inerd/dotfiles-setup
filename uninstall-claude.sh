#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

PATHS=(
    "${HOME}/.local/bin/claude"
    "${HOME}/.local/share/claude"
    "${HOME}/.local/state/claude"
    "${HOME}/.claude"
    "${HOME}/.claude.json"
    "${HOME}"/.claude.json.backup*
    "${HOME}/Library/Caches/claude-cli-nodejs"
    "${HOME}/.cache/claude"
)
KEYCHAIN_SERVICE="Claude Code-credentials"

echo "=== Claude Code Uninstaller ==="
echo
echo "Will delete:"
for p in "${PATHS[@]}"; do
    echo "  $p"
done
[[ "$(uname)" == "Darwin" ]] && echo "  Keychain item: $KEYCHAIN_SERVICE"
command -v npm >/dev/null && echo "  npm package: @anthropic-ai/claude-code (if installed)"
command -v brew >/dev/null && echo "  Homebrew cask: claude-code (if installed)"
echo
read -r -p "Proceed? [y/N] " confirm
[[ "${confirm}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

removed=0

remove_path() {
    local p="$1"
    if [[ -L "$p" || -e "$p" ]]; then
        rm -rf "$p"
        echo "Removed: $p"
        removed=1
    fi
}

for p in "${PATHS[@]}"; do
    remove_path "$p"
done

if [[ "$(uname)" == "Darwin" ]] && security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1; then
    echo "Removed: Keychain item $KEYCHAIN_SERVICE"
    removed=1
fi

if command -v npm >/dev/null && npm ls -g --depth=0 @anthropic-ai/claude-code >/dev/null 2>&1; then
    npm uninstall -g @anthropic-ai/claude-code
    echo "Removed: npm package @anthropic-ai/claude-code"
    removed=1
fi

if command -v brew >/dev/null && brew list --cask claude-code >/dev/null 2>&1; then
    brew uninstall --cask claude-code
    echo "Removed: Homebrew cask claude-code"
    removed=1
fi

if (( removed == 0 )); then
    echo "Nothing found to remove."
else
    echo
    echo "Done. Claude Code fully uninstalled."
fi
