#!/usr/bin/env bash
set -euo pipefail

# Script to install/update Ghostty terminal emulator

TMP_DIR=""
cleanup() {
    [[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
    if [[ -d "/Volumes/Ghostty" ]]; then
        hdiutil detach "/Volumes/Ghostty" -quiet 2>/dev/null || true
    fi
}

PLATFORM=$(uname -s)
if [ "$PLATFORM" != "Darwin" ]; then
    echo "This script only supports macOS. For Linux, please build from source."
    echo "See: https://github.com/ghostty-org/ghostty"
    exit 1
fi

ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" && "$ARCH" != "x86_64" ]]; then
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Fetching latest Ghostty release..."
LATEST_VERSION=$(curl -sf "https://ghostty.org/download" | grep -oE 'release\.files\.ghostty\.org/[0-9]+\.[0-9]+\.[0-9]+' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [[ -z "$LATEST_VERSION" ]]; then
    echo "Error: Failed to fetch Ghostty version from ghostty.org"
    exit 1
fi

echo "Latest Ghostty version: $LATEST_VERSION"

INSTALL_PATH="/Applications/Ghostty.app"
if [ -d "$INSTALL_PATH" ]; then
    CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown")
    if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
        echo "Ghostty $CURRENT_VERSION is already installed and up to date."
        exit 0
    fi
    echo "Updating Ghostty from $CURRENT_VERSION to $LATEST_VERSION..."
else
    echo "Installing Ghostty..."
fi

TMP_DIR=$(mktemp -d)
trap cleanup EXIT

DOWNLOAD_URL="https://release.files.ghostty.org/${LATEST_VERSION}/Ghostty.dmg"

echo "Downloading Ghostty from $DOWNLOAD_URL..."
if ! curl -fL "$DOWNLOAD_URL" -o "$TMP_DIR/Ghostty.dmg"; then
    echo "Error downloading Ghostty. Please check the URL and try again."
    exit 1
fi

echo "Mounting DMG..."
if ! hdiutil attach "$TMP_DIR/Ghostty.dmg" -quiet -nobrowse -mountpoint "/Volumes/Ghostty"; then
    echo "Error mounting DMG."
    exit 1
fi

echo "Installing Ghostty to /Applications..."
if [ -d "$INSTALL_PATH" ]; then
    rm -rf "$INSTALL_PATH"
fi

if ! cp -R "/Volumes/Ghostty/Ghostty.app" "/Applications/"; then
    echo "Error copying Ghostty.app to /Applications."
    hdiutil detach "/Volumes/Ghostty" -quiet
    exit 1
fi

echo "Detaching DMG..."
hdiutil detach "/Volumes/Ghostty" -quiet

echo "Ghostty installed successfully at $INSTALL_PATH"
echo "You can launch it from /Applications or with: open -a Ghostty"
