#!/usr/bin/env bash
set -euo pipefail

# Script to install/update neovim in ~/.nvim

TMP_DIR=""
cleanup() {
    [[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}

PLATFORM=$(uname -s)
if [ "$PLATFORM" == "Darwin" ]; then
    echo "Detected macOS"
    PLATFORM="macos"
elif [ "$PLATFORM" == "Linux" ]; then
    echo "Detected Linux"
    PLATFORM="linux"
else
    echo "Unsupported platform"
    exit 1
fi

ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

NEOVIM_VERSION="nightly"
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/nvim-${PLATFORM}-${ARCH}.tar.gz"
INSTALL_DIR="$HOME/.nvim"
TMP_DIR=$(mktemp -d)
trap cleanup EXIT

echo "Temporary directory: $TMP_DIR"

if [ -d "$INSTALL_DIR" ]; then
    echo "Updating neovim"
    rm -rf "$INSTALL_DIR"
else
    echo "Installing neovim"
fi

echo "Downloading neovim from $DOWNLOAD_URL"
if ! curl -fL "$DOWNLOAD_URL" -o "$TMP_DIR/nvim-${PLATFORM}-${ARCH}.tar.gz"; then
    echo "Error downloading Neovim. Please check the URL and try again."
    exit 1
fi

mkdir -p "$INSTALL_DIR"
echo "Extracting archive..."
if ! tar xzf "$TMP_DIR/nvim-${PLATFORM}-${ARCH}.tar.gz" -C "$INSTALL_DIR" --strip-components=1; then
    echo "Error extracting Neovim archive."
    exit 1
fi

echo "Neovim installed at $INSTALL_DIR"
echo "You can run Neovim using: $INSTALL_DIR/bin/nvim"
